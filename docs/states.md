# States

How the game moves between screens. The editor has its own page: [editor.md](editor.md).

## TitleSequence

The intro logo. ENTER skips it. It applies the saved settings on boot, then switches to the main menu when done.

## MainMenuState

PLAY, OPTIONS and QUIT on a black background. QUIT is desktop only. Two pairs of scrolling `JaggedBand` teeth frame the screen. A dark, slow, coarse pair sits behind a bright accent pair, and the two drift opposite ways for depth. The title is the logo art rather than set type, drawn twice: a silhouette behind, offset down and right, then the logo itself. The whole assembly rides a slow sine, and the splash rides it too so it stays pinned to the logo's corner. The silhouette is tinted the dark band maroon rather than black, because black on a black background is not a shadow, it is nothing. A yellow splash line lies angled across the title's lower-right corner and throbs in and out. The best wave sits in the corner, over menu music.

Navigate with W/S or the arrows plus ENTER, or with mouse hover and click.

The online menu carries a COLOR row. Left and right walk the player's hue one degree at a time, and holding either repeats, slowly at first and then faster, so a full turn of the wheel takes a few seconds. The row prints the angle and wears the colour itself, and a live character stands beside the menu wearing it, holding whichever weapon the run is set to. That character keeps idling while the hue moves. The recolour repaints the bitmap the sprite already points at rather than handing it a new one, so the animation never restarts. Swapping the frames instead would reset the frame clock faster than a frame could elapse, which reads as a freeze. The hue rides into the run and across the wire.

Two throttles keep that cheap. The character rebake runs at most twenty times a second however fast the number climbs, so a full sweep costs about fifty bakes rather than three hundred and sixty. The save waits for the value to sit still for a moment before it writes, so a sweep is one write rather than one per degree. Both key on time rather than on the key being down, so anything that drives the row gets the same protection.

PLAY fades to black and switches to PlayState. Left and right on that row choose the map. The options are the stock arena, or any editor slot holding a save. The row always opens on the stock arena. It therefore reads PLAY, rather than naming a slot you edited last. OPTIONS opens `OptionsSubState`.

The editor has no row of its own. F7 opens it. It stays off the menu on purpose. The editor serves whoever builds the game, and is not something to offer a player.

QUIT collapses the OS window like a CRT switching off. Three chained `FlxTween.num` tweens drive the window size and opacity. The frame drops first, so the window can shrink freely. The height then squeezes to a horizontal sliver while the width holds. The width then pinches to a dot and the window fades out. When the last tween finishes, it shuts down Discord presence and exits.

Windows will not shrink a window past about 36 px. That is why the end of the vanish uses opacity rather than size. The collapse is desktop only. Other targets keep the plain fade-to-black exit.

## OptionsSubState

The options panel over the menu. It holds master, music and sound effect volumes, the display mode, V-Sync, the framerate, the aspect ratio, the camera lean, screenshake and freeze-frame sliders, the HUD toggle, the 3D sound toggle, an FPS counter toggle, the language, a CONTROLS row, and a reset-best-wave action. Adjust a row with A/D or the arrows, or click to step it. Reset-best-wave asks for a second press within a few seconds to confirm. Every setting applies at once and persists in the save file. ESC or BACK closes the panel.

The display mode picks windowed, borderless, or exclusive fullscreen. V-Sync cannot change on a live window, so the toggle instead caps the framerate to the display's refresh rate, which gives the same pacing. With V-Sync off, the framerate row picks the cap directly, and it drives the update rate too. The aspect ratio row constrains the display region to 4:3, 16:9, 16:10 or 21:9 through a custom scale mode. The whole 16:9 frame scales to fit inside that region, so nothing is ever covered or cut, and the space outside the frame fills with bars on the plain stage. The bars fill with `assets/images/ui/side_art.png` when that file exists, and a flat dark panel when it does not. AUTO fits the window itself, and any leftover margins still take the art.

The camera lean slider sets how far the cursor drags the view. At zero the camera sits on the player; at full it sits halfway between the player and the cursor, which puts the player at the screen edge when you aim that far out. It defaults to halfway between those, since playtesting split on how much movement reads well.

The screenshake slider scales every camera shake in the game, and the freeze-frame slider scales every hitstop, both from zero to full. The HUD toggle hides the whole screen HUD except the crosshair. The 3D sound toggle pans and fades world sounds by where they happen relative to the view: hits, enemy shots, charge roars, the boss blast and the shop door. Off plays everything flat and centred.

## ControlsSubState

The rebind screen, opened from the CONTROLS row in options. A DEVICE row flips between the keyboard page and the controller page, and every action below it shows its current bind. Choosing an action waits for the next key, mouse button or pad button and takes it, ESC backs out of the wait, and a captured bind that another action already holds swaps with it rather than silently unbinding something. RESET DEFAULTS puts both devices back. Binds persist in the save file.

Two things are not rebindable, and the footer says so per device: the mouse always aims, and on a controller the left stick always moves and the right stick always aims. The mouse buttons are ordinary binds, attack and secondary by default. Menus likewise keep fixed navigation, arrows and ENTER and ESC on keyboard, the dpad and sticks with A and B on a pad, so no rebind can lock you out of the screen that fixes it.

## PlayState

It builds the systems in `create()`, calls them in order in `update()`, and handles the debug keys. It holds almost no gameplay logic of its own. What it does own is the wiring that needs two systems at once, plus the camera. The deflected-shot handler is one such piece, since it needs the director and the hit pipeline together.

The camera leans toward the cursor rather than sitting on the player. It feeds `targetOffset` a fraction of the cursor's offset from the view centre, so the player drifts under half the way to the edge at full reach instead of pinning against it. That offset comes from the view rather than from world space on purpose. The cursor's world position moves with the camera, so deriving the lean from it would feed back into itself.

`BASE_ZOOM` pulls the frame back so more of the arena is in shot, and `FOLLOW_LERP` sets how fast the camera closes on its target. Both live at the top of the state. How far the cursor drags the frame is a player setting rather than a constant, since playtesting split on it: see the camera lean row under OptionsSubState.

`BASE_ZOOM` is the one every other zoom multiplies. The boss pull-back and the quiet room are fractions of it rather than absolute numbers, and the boss tween returns to it. Pulling the base back therefore keeps both of those the same relative change.

## PauseSubState

ESC opens it. It freezes the game, pauses all audio, and dims the screen. ESC closes it again. The volume keys still work while it is open.

It holds audio through `Music.hold` rather than pausing the sound front end directly, because pausing what is playing is only half the job. Timers and tweens live on global plugins, so they keep running while a substate is open even though the state itself does not update. Both of the boss show's music changes start from inside a timer, a beat after the boss arrives and a beat after it dies, so pausing on either of those beats let the new track start after the pause had already silenced the old one, and it played over the menu. While the hold is up `Music.play` still loads and swaps the track, then pauses it, so the resume on close picks it up where the player expects. The hold clears on close, on quit, and in `destroy`, since a track left held would follow the player into the next state as silence.

A HELP row opens the same seven page popup the first run shows, so the controls are never more than a pause away. Opened from here its footer reads CLOSE rather than PLAY, since closing it lands back on the pause menu rather than into the game.

QUIT TO MENU returns to the editor instead when the run came from a playtest. The editor sets that flag itself. The state does not infer it from the map being custom. The menu can start a custom map too, and those runs belong back at the menu.

## OnlineHelpSubState

The co-op explainer, styled like the controls popup. It appears the first time the online lobby opens each session, and H reopens it. Three pages flip with A/D: what co-op is, how to host or join, and what behaves differently online. The hosting page covers the `IP:PORT` form for when the host has fallen back to another port.

The lobby keeps updating while a substate is open. The socket has to stay serviced, so a friend can still connect while you read. The lobby therefore hands input ownership to the popup and skips its own key handling. That also stops one ENTER or ESC from counting twice.

## TutorialSubState

The controls popup, shown the first time PlayState opens each session. Seven pages flip with A/D or the arrow keys: move, attack, weapons, super, scrap, health and ready. Each page carries a looping animated demo built from game sprites.

The scrap page runs the whole economy in one loop: an enemy falls, the pieces burst out, the player walks the line of them and a counter ticks up as each is crossed. The ready page shows a rest: the prompt throbs until the ready bubble pops over the player's head, and the next wave announces itself below them, clear of the bubble. The abilities page left with time stop when time stop was parked; if the ability comes back, its page comes back with it.

The popup fades in on open. ENTER or ESC freezes the demo and fades it back out before the game starts. The wave timer stays frozen while the popup is open.

The weapons page reads its line-up from the pick screen rather than listing the weapons itself, so the two cannot disagree about which weapon is number one. The super page animates the hammer's bounce, the leap and spin and the ring of the slam under it. It hangs the hammer off the same hand the held weapon uses and rotates that point with the player, so the two turn as one body rather than the weapon orbiting at arm's length. The bounce's own pivot is measured against a player whose sprite is being lifted by an offset, so read plainly it lands at the feet. The turn is taken about the point flixel actually rotates the sprite around, which is the graphic's origin less its draw offset, not the hitbox centre. Those sit 58 px apart on this character, which is the whole width of the gap the weapon used to leave. The scrap page puts its counter where the real one sits, low and to the left, so the page and the game agree on where to look. It also stands its enemy on the player's own line, and the health page floats its repair kit at the player's middle. Centring both on the same point is not enough, since that centres the collision box and every character carries a different one, which left the enemy standing thirty pixels lower than the player it shares the floor with.

The attack page hangs its hammer off `HeldWeapon`'s own hand offset rather than its own copy of one, so the demo grips the weapon exactly where the game does. It had been carrying the hammer bounce's pivot instead, which hung it off the body.

The move and attack pages name the keys the player actually holds. Their strings carry placeholders and the page fills them from the current binds, so rebinding the dash or putting attack on a different button rewrites the page rather than leaving it advertising a key that does nothing.

Each page's demo is its own class under `states/tutorial/`: MoveDemo, AttackDemo, WeaponsDemo, SuperDemo, ScrapDemo, HealthDemo and ReadyDemo. All of them extend `TutorialDemo`. That group base holds the shared sprite, text and player factories, the demo clock, and a per-frame `step()` hook. The substate itself owns only the panel, the page texts and page flipping. Flipping destroys the old demo instance and builds the next.

## WeaponPickSubState

The run's one weapon choice, opened as PlayState starts. Four cards: hammer, revolver, crossbow and yoyo. Choose with 1-4, A/D, the arrows or the mouse, then confirm with ENTER or a click. The pick locks for the whole run. There is no mid-run switching, only the chosen weapon's primary and secondary attacks.

Confirming reports where the chosen card's icon sat. The weapon then flies from that card into the player's hand. The throw belongs to `WeaponFlyIn`, which waits until every substate clears. The tutorial opens straight after the pick on a first run. The throw therefore waits on it, rather than playing behind the panel.

The screen remembers the last choice, so a repeat run or a map playtest is one keypress. It also ignores input for a moment after it opens. The keypress that started the run therefore cannot confirm it by accident.

Online, the lobby opens this screen instead. A substate over PlayState would freeze the sim while the network kept feeding it packets. The lobby runs the same card screen through `OnlineState`, while nobody is in the game yet. Both routes write the same `lastPick` that PlayState equips.

## LobbyState

The room you stand in before a run, reached from PLAY. It is a plain walled room built the way any custom map is, through `CustomArena`, so it gets collision, camera bounds and a background from the same code a real stage does. Its floor is a rock tile repeated over the room rather than the stage art, which `Arena.tileBackground` fills in: a stage background is one image stretched to the map, which on a room this size read as a blown up logo. The tile is scaled before it repeats, by the same four the rest of the art uses, so the rock sits at the size of everything else. Combat, waves and the HUD are simply absent rather than switched off, since nothing here builds them.

Four signs stand in it, START, HOST, JOIN and PLAYER, each a spot with a label. Walking within reach of one offers it on the interact key, the same key the shop uses. START begins the run. HOST opens the port and shows how many have joined. JOIN takes an address typed in and connects. PLAYER is where you dress: left and right walk the colour round, letters spell a name, and the interact key closes it. It recolours the character standing in front of the sign rather than a preview of one, since the lobby already has the real body on screen. Colour used to sit in the options menu behind a preview sprite; it lives here now and the menu no longer carries it.

Presence is its own small thing rather than the game's netcode. `NetSync` is built around a running fight and wants a director, a HUD and a weapon set, none of which exist here, so the lobby sends its own `lob` message a few times a second carrying position, facing, animation, colour and name, and renders whoever answers with `RemoteAvatar`, which is the same body the fight uses. A peer that stops speaking for five seconds is dropped, which is what a guest closing its window looks like from the host's side.

Starting is the host's call. It sends `go`, and every peer walks into `PlayState` with the connection still open, where the real netcode takes over. That is the same handover the old online screen did, moved into a room you can walk around.

## EditorState

The map editor's coordinator. See [editor.md](editor.md).

---

Back to the [documentation index](../DOCS.md).
