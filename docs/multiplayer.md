# Multiplayer (source/net/)

Online co-op, desktop only. Pick ONLINE on the main menu. One player hosts on TCP port 7777 and forwards that port on their router. The friend joins by IP.

Port 7777 is a common default, and Terraria uses it among others. If it is busy, the host walks up through 7786 to the next free port. The lobby reports the port it took. The friend must then join with `IP:port` instead of a bare address. The joining side has always accepted that form.

The model is host-authoritative. The host runs the whole solo simulation unchanged: waves, enemy AI, pathfinding, boss and drops. The client never simulates an enemy.

## Puppets

The client runs its own full weapon stack against *puppets*. A puppet is a real `Enemies` instance flagged `puppet`. It skips its AI and plays animations. Its position streams from the host at about 15 Hz with interpolation.

Puppets live in a `PuppetDirector`. That `EnemyDirector` subclass swaps spawning and AI for snapshot application. It keeps the rigs, shadows, hitboxes and hit queries. Everything the client's weapons need therefore runs the same code as solo play. That covers `firstInCircle`, contact damage, and enemy shots hurting the player.

A landed client attack draws its own feedback at once, then sends a damage *claim*. That feedback is sparks, sound and a hit flash. The host applies the claim and owns the result. The death comes back in the next snapshot. The client takes the kill for the super meter if it claimed that enemy recently.

## What each side sees

Both players see each other as a `RemoteAvatar`: player sprite, held weapon and shadow. It streams alongside the snapshots. Waves, boss cinematics, enemy shots and pickups ride on top of the snapshot stream as small events. Each player picks up drops locally and confirms them with the host, so both sides agree. Death in co-op does not end the run. The player respawns after a few seconds with half health, and R-restart is off.

## Files

- `Net` - the transport: non-blocking TCP, newline-delimited JSON, host, join, poll and send. It marks itself dropped on error, and switches off `FlxG.autoPause` so an alt-tabbed host cannot freeze the session.
- `NetSync` - all replication logic, on both sides.
- `PuppetDirector` and `RemoteAvatar` - the client's enemies and the other players' bodies.
- `states/OnlineState` - the lobby: IP entry, name entry and the weapon pick.

The save file keeps the last IP.

The lobby menu uses the same `MenuSlash` confirm as the main menu. HOST and JOIN both stay on the lobby screen. Every path that hands control back to the list therefore runs one `releaseMenu()`. It restores the shattered row and re-enables input. Those paths are a failed host, a failed connection, a cancelled IP entry, and a lost peer.

ESC resolves in one place and means the narrowest thing available. It cancels IP entry while typing. It stops hosting, or disconnects, when a session is open. It leaves the lobby only when idle at the list.

## Weapon choice

Each player picks a weapon in the lobby before the run starts. It is the card screen the solo game uses, opened from `OnlineState` before the run exists. TAB opens it again after hosting or joining, so a change does not cost you the connection. PlayState reads the choice once through `equip` as it builds. The choice rides the avatar packet as `wi`, so everyone draws everyone else's weapon correctly. Two players may hold the same weapon.

## Weapon effects

`RemoteFx` replicates your friend's weapon visuals. It spawns decoration only. Nothing it creates can damage anything, so it cannot desync the authoritative sim.

`Weapons` emits one `onAttack` callback from `primary` and `secondary`. The callback carries the fired mode, the aim and the charge power. The bow emits from its own input branch, because charging returns before the shared path. It emits from the hand rather than the body, since that is where its arrows leave.

The held weapon streams its placement as an offset from the player. The far side does not recompute it. Locally, `anchor()` pushes the bow toward the cursor and lifts it during an arrow rain. It also moves the sprite origin to centre. Re-deriving that invites the drift it once had.

The receiver rebuilds each effect from its own local classes. Those are a slash, an arrow, or a rain volley from a cosmetic `ArrowRain`.

The hook, its rope and the thrown hammer stream as state on the avatar packet. They persist and follow the world instead of flying straight. Snapshots go out every fourth frame, far too coarse for a hammer at 1000 px/s. The thrown copy is dead-reckoned instead. The packet carries velocity rather than angle, and the sprite integrates that velocity at full framerate. The streamed position then acts as a weak correction that pulls out drift.

The thrown hammer spins and trails locally. The hook uses a plain position lerp. Both rope ends interpolate, so the rope does not jitter. A hook stuck in a victim keeps a stale velocity, so it cannot dead-reckon. Host hits also emit an impact event so the client sees sparks. The client draws its own hits already, so only the host's need sending.

## Supers

Dead Eye replicates as its shots and nothing else. `superActivate` ignores it. Each round it fires emits an ordinary `Shoot`, so the remote draws the bullet. Online it gives up the part that cannot survive co-op.

It does not stop the clock, and it does not root the player. The world is only one machine's to stop. Time stop and the totem are off online for that same reason. Dead Eye instead keeps everything except that one behaviour.

What a remote machine can reproduce decides how each other super replicates.

The blade ring and the arrow storm replay from their activation alone. A call to `SuperOrbit.decoration()` builds a copy with no player, arena, director or hit pipeline. That strips the damage and the writes to the body. Blade launches arrive as one event each. The storm scatters its drops at random, and nobody can tell the two machines picked different points.

Bounce strike does not replay at all. It moves the player itself, so the avatar's own position stream already shows it. Only the shockwave per slam needs sending.

The hook arms stream their claws, because they grab enemies. Which enemy is nearest can differ between machines. The grabbed enemy is host-authoritative already, so it gets dragged around correctly on its own. Rope curves rebuild locally from the streamed control points. They anchor to the interpolated body, so they stay attached while it moves.

Supers also lift, spin and squash the player's body. Those three ride along in the avatar packet, and no machine recomputes them. That is what keeps the decoration copies out of the body entirely.

## Transport shape

Up to eight players share a run. The transport is a star. Everyone connects to the host, and the host forwards each player's messages to the rest. No client needs another client's address.

Every message carries the id of the player it came from. The host stamps that id itself as it reads a socket. A client therefore cannot claim to be someone else, and nobody sees their own messages echoed back. The host is always id 0 and hands out the rest on connect. Hit claims and pickup grabs stop at the host, because they are its business alone.

## Package seams

The net package splits along the seams of that model. Transport lives in `Net`. The seam between the local game and the wire is `NetSync`. It covers outbound emission, inbound routing, and the shared run rules. Those rules are respawns, the everyone-down loss, and the broadcast restart.

Each other player is a `Peer`: their body, their effects, and whether they are down. A `PeerRoster` holds them. It creates one the first time a message arrives from an unfamiliar id. Peers pool rather than destroy, because building one wires its visuals into the display list. A player leaving hides them and frees the slot for the next arrival. A guest dropping is survivable for the host, and ends the session only for that guest.

One subtlety is worth knowing. The host never receives its own broadcasts. So when it notices a socket die, it queues the departure notice for itself as well. Otherwise the departed player would linger on the host's screen and still count as alive.

The client's copy of the host's world lives in `PuppetMirror`. It holds puppet enemies and pickups, driven by snapshots and interpolated between them. It also holds the kill-credit window for this player's damage claims. Nothing in it decides anything. It only shows what the host said.

`RemoteArms` is the streamed hook-arms channel. It stays out of `RemoteFx`, because it is the one effect that lerps state every frame rather than replaying an event. One shared function builds the boss death blast, `Fx.bossBlast`, so the host's real death and a client's mirror cannot drift apart.

## Joining late

The host greets a latecomer with word that a run is already going. They skip the lobby and drop straight into it.

## Names

Players set a name in the online menu. The save file keeps it, and it floats above their head for everyone else. A name announces once on entry rather than in every packet. That leaves a question. How does someone arriving late learn names sent before they connected? Everyone re-announces whenever a player joins, so the whole party greets a latecomer.

That is also why the host raises a join event for itself. It never receives its own broadcasts, so otherwise it alone would stay silent. Tags live above the depth sort rather than in it. A name sorted by its own feet would slide behind anyone standing further up the screen. Only other players get a tag, since your own would sit in the middle of your view.

## Targeting with several players

Enemy targeting is co-op aware. The director keeps a list of living co-op bodies. Those are remote avatar sprites carrying streamed positions. Each enemy chases whichever living player is nearest, and falls through to the survivors as players go down. The same choice drives spawn placement and the stuck-enemy rescue. A downed host therefore no longer strands the wave around their corpse.

Enemies go idle only when every player is down. That is also the loss condition. A solo death respawns you after a few seconds. Both players down ends the run and offers a restart, which broadcasts so the two machines reset together.

## Switched off online

Three features stay off online, because they fight the authority model.

1. Time stop. It freezes the whole world for one player.
2. The perspective totem. Its morph relocates every entity globally.
3. R-restart. Respawns replace it.

---

Back to the [documentation index](../DOCS.md).
