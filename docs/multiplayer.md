# Multiplayer (source/net/)

Online co-op, desktop only. Pick ONLINE on the main menu. One player hosts on TCP port 7777 and forwards that port on their router. The friend joins by IP.

Port 7777 is a common default, and Terraria uses it among others. If it is busy, the host walks up through 7786 to the next free port. The lobby reports the port it took. The friend must then join with `IP:port` instead of a bare address. The joining side has always accepted that form.

The model is host-authoritative. The host runs the whole solo simulation unchanged: waves, enemy AI, pathfinding, boss and drops. The client never simulates an enemy.

## Puppets

The client runs its own full weapon stack against *puppets*. A puppet is a real `Enemies` instance flagged `puppet`. It skips its AI and plays animations. Its position streams from the host at about 15 Hz with interpolation.

Puppets live in a `PuppetDirector`. That `EnemyDirector` subclass swaps spawning and AI for snapshot application. It keeps the rigs, shadows, hitboxes and hit queries. Everything the client's weapons need therefore runs the same code as solo play. That covers `firstInCircle`, contact damage, and enemy shots hurting the player.

A landed client attack draws its own feedback at once, then sends a damage *claim*. That feedback is sparks, sound and a hit flash. The host applies the claim and owns the result. The death comes back in the next snapshot. The client takes the kill for the super meter if it claimed that enemy recently.

The shop round runs on four messages. The host's `lvl` opens every peer's shop. A player entering sends `lvlin`, which puts the LEVELING note over them on every other screen. Closing the menu, or a shop timing out unvisited, sends `lvldone`, and the host releases with `lvlgo` once everyone has reported. Nobody is pulled into a menu by someone else. The broadcast opens shops, not screens.

Each defeated boss kind sends `bossFall` with its position. Guests blast that point and drop five local scrap. The host health pickup reaches guests through the snapshot. `bossDead` remains the single encounter completion signal that restores the arena.

The host sends one `bossPack` message with every member ID after it spawns the encounter. The guest waits until every listed puppet exists before it creates one boss bar. The Domo and wyrm pair therefore includes Domo, the wyrm head and every segment in the same health total.

## What each side sees

Both players see each other as a `RemoteAvatar`: player sprite, held weapon and shadow. It streams alongside the snapshots. Waves, boss cinematics, enemy shots and pickups ride on top of the snapshot stream as small events. Each player picks up drops locally and confirms them with the host, so both sides agree. Death in co-op does not end the run. The player respawns after a few seconds with half health, and R-restart is off.

## Files

- `Net` - the transport: non-blocking TCP, newline-delimited JSON, host, join, poll and send. It marks itself dropped on error, and switches off `FlxG.autoPause` so an alt-tabbed host cannot freeze the session.
- `NetSync` - all replication logic, on both sides.
- `PuppetDirector` and `RemoteAvatar` - the client's enemies and the other players' bodies.
- `states/OnlineState` - the main menu online screen: host, join, name, color and weapon rows.

The save file keeps the last IP.

The main menu ONLINE row opens `OnlineState`. Its list uses the same `MenuSlash` confirm as the main menu. Every path that hands control back to the list runs one `releaseMenu()`. It restores the shattered row and re-enables input.

The walkable lobby has one ONLINE sign. It opens `OnlineSubState` before any host or join panel. The substate disables HOST for clients and JOIN for active hosts.

When a host chooses BACK TO LOBBY during a run, it sends `toLobby` before changing state. Every guest follows without closing the session or showing a connection error. The existing `go` message can start the same party again. A guest choosing the row still leaves the session. QUIT TO MENU still closes the session.

ESC resolves in one place and means the narrowest thing available. It cancels IP entry while typing. It stops hosting, or disconnects, when a session is open. It leaves the lobby only when idle at the list.

## Weapon choice

Each player picks a weapon in the lobby before the run starts. It is the card screen the solo game uses, opened from `OnlineState` before the run exists. TAB opens it again after hosting or joining, so a change does not cost you the connection. PlayState reads the choice once through `equip` as it builds. The choice rides the avatar packet as `wi`, so everyone draws everyone else's weapon correctly. Two players may hold the same weapon.

## Weapon effects

`RemoteFx` replicates your friend's weapon visuals. It spawns decoration only. Nothing it creates can damage anything, so it cannot desync the authoritative sim.

`Weapons` emits one `onAttack` callback from `primary` and `secondary`. The callback carries the fired mode, the aim and the charge power. The bow emits from its own input branch, because charging returns before the shared path. It emits from the hand rather than the body, since that is where its arrows leave.

The held weapon streams its placement as an offset from the player. The far side does not recompute it. Locally, `anchor()` pushes the bow toward the cursor and lifts it during an arrow rain. It also moves the sprite origin to centre. Re-deriving that invites the drift it once had.

The receiver rebuilds each effect from its own local classes. Those are a slash, an arrow, or a rain volley from a cosmetic `ArrowRain`.

The yoyo streams rather than replays. Its path follows the thrower's cursor for as long as they hold the button, so no single event describes it. It rides the avatar packet next to the grab, carrying position and spin, and the receiver lerps between snapshots and rebuilds the string against the interpolated body. The attack event still goes out, but only to play the throw sound. Only the owner's copy deals damage.

The grab, the yoyo, their strings and the thrown hammer stream as state on the avatar packet. They persist and follow the world instead of flying straight. Snapshots go out every fourth frame, far too coarse for a hammer at 1000 px/s. The thrown copy is dead-reckoned instead. The packet carries velocity rather than angle, and the sprite integrates that velocity at full framerate. The streamed position then acts as a weak correction that pulls out drift.

The thrown hammer spins and trails locally. The grab uses a plain position lerp. Both string ends interpolate, so the string does not jitter. A grab stuck in a victim keeps a stale velocity, so it cannot dead-reckon. Host hits also emit an impact event so the client sees sparks. The client draws its own hits already, so only the host's need sending.

A guest's grab crosses the wire as a seize message, and the drag itself streams behind it. The grabber owns the enemy while it holds it: its own mirror leaves the seized puppet alone, and it sends the enemy's position on the avatar cadence. The host steers the real enemy toward each sample instead of teleporting it, so everyone watching sees the enemy reeled in, held at the cursor and whipped around, rather than freezing in place until the throw. The release still hands the host the enemy's final spot. The super's arms speak the same seize and drag protocol, so an arm's grab reads the same as the hook's.

The big shot sends its own event, so the other machines draw the heavy shell rather than a normal round.

The ready gate runs the same quorum shape as the shop hold. It arms at the run's first wave, after shop waves and after bosses, rather than at every clear. The host arms every machine, each player's ready crosses the wire so every machine can raise that player's bubble, and the host counts them against the roster it snapshotted at arming time. A guest who drops is removed from the count rather than waited on. Solo runs the same gate without the wire: one ready releases it.

## Supers

An attack carries a perfect flag alongside its charge, since a sweet spot shot cannot be told from a merely full one by charge alone, and peers draw the perfect arrow from it.

The twin gun replicates as its shots and nothing else. Both rounds of every pull emit their own event, so the other machines draw the pair without knowing a super is on.

What a remote machine can reproduce decides how each other super replicates.

The arrow storm replays from its activation alone: the drops scatter at random, and nobody can tell the two machines picked different points. The hammer bounce rides the avatar packet, since the hop, the spin and the squash already stream with the body, and each slam arrives as a launch event that pops sparks where it landed. The yoyo spin streams through the same yoyo channel as ordinary flight, so the circling yoyo and its string appear on every machine, and the enemies it seizes are dragged host-authoritatively like any other grab.

Supers also lift, spin and squash the player's body. Those three ride along in the avatar packet, and no machine recomputes them. That is what keeps the decoration copies out of the body entirely.

The packet also carries the hue the player picked in the lobby. That hue is not a tint over the whole sprite, which would muddy the greys. Every machine bakes its own recolored copy of the character sheet, rotating only the pixels close to red, and keeps it cached under the hue's own key. Skin, bone and metal therefore hold their color while the red reads as whatever the player chose. The bake runs once per hue on a sheet of a few thousand pixels, so it costs nothing worth measuring.

## Transport shape

Up to eight players share a run. The transport is a star. Everyone connects to the host, and the host forwards each player's messages to the rest. No client needs another client's address.

Every message carries the id of the player it came from. The host stamps that id itself as it reads a socket. A client therefore cannot claim to be someone else, and nobody sees their own messages echoed back. The host is always id 0 and hands out the rest on connect. Hit claims and pickup grabs stop at the host, because they are its business alone.

## Package seams

The net package splits along the seams of that model. Transport lives in `Net`. The seam between the local game and the wire is `NetSync`. It covers outbound emission, inbound routing, and the shared run rules. Those rules are respawns, the everyone-down loss, and the broadcast restart.

Each other player is a `Peer`: their body, their effects, and whether they are down. A `PeerRoster` holds them. It creates one the first time a message arrives from an unfamiliar id. Peers pool rather than destroy, because building one wires its visuals into the display list. A player leaving hides them and frees the slot for the next arrival. A guest dropping is survivable for the host, and ends the session only for that guest.

One subtlety is worth knowing. The host never receives its own broadcasts. So when it notices a socket die, it queues the departure notice for itself as well. Otherwise the departed player would linger on the host's screen and still count as alive.

The client's copy of the host's world lives in `PuppetMirror`. The boss's held gun rides its snapshot row, image, place and angle, since the attack logic that drives it runs only on the host and a puppet's gun would otherwise stay a blank sprite. It holds puppet enemies and pickups, driven by snapshots and interpolated between them. It also holds the kill-credit window for this player's damage claims. Nothing in it decides anything. It only shows what the host said.

`RemoteArms` is the streamed grab-arms channel. It stays out of `RemoteFx`, because it is the one effect that lerps state every frame rather than replaying an event. One shared function builds the boss death blast, `Fx.bossBlast`, so the host's real death and a client's mirror cannot drift apart.

## Joining late

The host greets a latecomer with word that a run is already going. They skip the lobby and drop straight into it.

## Names

Chat is a fixed overlay in the top-left corner. Messages draw without a panel and wrap across 68 percent of the screen. Text uses a 2 px black outline. The idle log stays visible for five seconds after chat activity, then fades out over one second. Press T to restore the history and show the bare input line, emoji choices and message actions. Those controls hide when chat loses focus, so the idle log does not take mouse input. Chat scale lives on the visual options page and updates the overlay immediately.

Players set a name in the online menu. The save file keeps it, and it floats above their head for everyone else. A name announces once on entry rather than in every packet. That leaves a question. How does someone arriving late learn names sent before they connected? Everyone re-announces whenever a player joins, so the whole party greets a latecomer.

Avatar snapshots include AFK state. A remote player's name stays visible during AFK. The yellow `AFK` label stacks above the name.

The ready bubble stays above the compact label stack. Local and remote bubbles both clear an active `AFK` label.

Peer names use `5mikropix` at size 24 with a 2 px black outline. Each name takes a brighter version of that peer's character hue. Chat sender names use the same hue mapping. The face covers kana but not the full kanji set, so some Japanese player names show missing glyphs.

That is also why the host raises a join event for itself. It never receives its own broadcasts, so otherwise it alone would stay silent. Tags live above the depth sort rather than in it. A name sorted by its own feet would slide behind anyone standing further up the screen. Only other players get a tag, since your own would sit in the middle of your view.

## Targeting with several players

Enemy targeting is co-op aware. The director keeps a list of living co-op bodies. Those are remote avatar sprites carrying streamed positions. Each enemy chases whichever living player is nearest, and falls through to the survivors as players go down. The same choice drives spawn placement and the stuck-enemy rescue. A downed host therefore no longer strands the wave around their corpse.

Enemies go idle only when every player is down. That is also the loss condition. A solo death respawns you after a few seconds. Both players down ends the run and offers a restart, which broadcasts so the two machines reset together.

## Switched off online

Three features stay off online, because they fight the authority model.

1. Time stop. It freezes the whole world for one player.
3. R-restart. Respawns replace it.

---

Back to the [documentation index](../DOCS.md).
