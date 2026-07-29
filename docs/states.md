# States

How the game moves between screens. The editor has its own page: [editor.md](editor.md).

## TitleSequence

The intro logo. ENTER skips it. It applies the saved settings on boot, then switches to the main menu when done.

## MainMenuState

PLAY, OPTIONS and QUIT on a black background. QUIT is desktop only. Two pairs of scrolling `JaggedBand` teeth frame the screen. A dark, slow, coarse pair sits behind a bright accent pair, and the two drift opposite ways for depth. A yellow splash line lies angled across the title's lower-right corner and throbs in and out. The best wave sits in the corner, over menu music.

Navigate with W/S or the arrows plus ENTER, or with mouse hover and click.

The online menu carries a COLOR row. Left and right walk the player's hue a step at a time, the row prints the angle and wears the colour itself, and a live character stands beside the menu wearing it. The hue rides into the run and across the wire.

PLAY fades to black and switches to PlayState. Left and right on that row choose the map. The options are the stock arena, or any editor slot holding a save. The row always opens on the stock arena. It therefore reads PLAY, rather than naming a slot you edited last. OPTIONS opens `OptionsSubState`.

The editor has no row of its own. F7 opens it. It stays off the menu on purpose. The editor serves whoever builds the game, and is not something to offer a player.

QUIT collapses the OS window like a CRT switching off. Three chained `FlxTween.num` tweens drive the window size and opacity. The frame drops first, so the window can shrink freely. The height then squeezes to a horizontal sliver while the width holds. The width then pinches to a dot and the window fades out. When the last tween finishes, it shuts down Discord presence and exits.

Windows will not shrink a window past about 36 px. That is why the end of the vanish uses opacity rather than size. The collapse is desktop only. Other targets keep the plain fade-to-black exit.

## OptionsSubState

The options panel over the menu. It holds master volume, the display mode, V-Sync, the framerate, the aspect ratio, the screenshake and freeze-frame sliders, the HUD toggle, the 3D sound toggle, an FPS counter toggle, the language, and a reset-best-wave action. Adjust a row with A/D or the arrows, or click to step it. Reset-best-wave asks for a second press within a few seconds to confirm. Every setting applies at once and persists in the save file. ESC or BACK closes the panel.

The display mode picks windowed, borderless, or exclusive fullscreen. V-Sync cannot change on a live window, so the toggle instead caps the framerate to the display's refresh rate, which gives the same pacing. With V-Sync off, the framerate row picks the cap directly, and it drives the update rate too. The aspect ratio row constrains the display region to 4:3, 16:9, 16:10 or 21:9 through a custom scale mode. The whole 16:9 frame scales to fit inside that region, so nothing is ever covered or cut, and the space outside the frame fills with bars on the plain stage. The bars fill with `assets/images/ui/side_art.png` when that file exists, and a flat dark panel when it does not. AUTO fits the window itself, and any leftover margins still take the art.

The screenshake slider scales every camera shake in the game, and the freeze-frame slider scales every hitstop, both from zero to full. The HUD toggle hides the whole screen HUD except the crosshair. The 3D sound toggle pans and fades world sounds by where they happen relative to the view: hits, enemy shots, charge roars, the boss blast and the shop door. Off plays everything flat and centred.

## PlayState

It builds the systems in `create()`, calls them in order in `update()`, and handles the debug keys. It holds almost no gameplay logic of its own. What it does own is the wiring that needs two systems at once, plus the camera. The deflected-shot handler is one such piece, since it needs the director and the hit pipeline together.

The camera sits at the midpoint between the player and the cursor. It feeds `targetOffset` the cursor's full offset from screen centre, which puts the camera centre exactly halfway between the two. That offset comes from screen space rather than world space on purpose. The cursor's world position moves with the camera, so deriving the lean from it would feed back into itself.

## PauseSubState

ESC opens it. It freezes the game, pauses all audio, and dims the screen. ESC closes it again. The volume keys still work while it is open.

QUIT TO MENU returns to the editor instead when the run came from a playtest. The editor sets that flag itself. The state does not infer it from the map being custom. The menu can start a custom map too, and those runs belong back at the menu.

## OnlineHelpSubState

The co-op explainer, styled like the controls popup. It appears the first time the online lobby opens each session, and H reopens it. Three pages flip with A/D: what co-op is, how to host or join, and what behaves differently online. The hosting page covers the `IP:PORT` form for when the host has fallen back to another port.

The lobby keeps updating while a substate is open. The socket has to stay serviced, so a friend can still connect while you read. The lobby therefore hands input ownership to the popup and skips its own key handling. That also stops one ENTER or ESC from counting twice.

## TutorialSubState

The controls popup, shown the first time PlayState opens each session. Six pages flip with A/D or the arrow keys: move, attack, weapons, super, abilities and health. Each page carries a looping animated demo built from game sprites.

The abilities page demos time stop. Four enemies close in around the player until the stop triggers. They freeze mid-stride, while the player keeps running laps around them with the blue afterimage trail. The player steers clear of every frozen body, and everything ramps back up on release.

The popup fades in on open. ENTER or ESC freezes the demo and fades it back out before the game starts. The wave timer stays frozen while the popup is open.

Each page's demo is its own class under `states/tutorial/`: MoveDemo, AttackDemo, WeaponsDemo, SuperDemo, AbilitiesDemo and HealthDemo. All of them extend `TutorialDemo`. That group base holds the shared sprite, text and player factories, the demo clock, and a per-frame `step()` hook. The substate itself owns only the panel, the page texts and page flipping. Flipping destroys the old demo instance and builds the next.

## WeaponPickSubState

The run's one weapon choice, opened as PlayState starts. Four cards: hammer, revolver, crossbow and hook. Choose with 1-4, A/D, the arrows or the mouse, then confirm with ENTER or a click. The pick locks for the whole run. There is no mid-run switching, only the chosen weapon's primary and secondary attacks.

Confirming reports where the chosen card's icon sat. The weapon then flies from that card into the player's hand. The throw belongs to `WeaponFlyIn`, which waits until every substate clears. The tutorial opens straight after the pick on a first run. The throw therefore waits on it, rather than playing behind the panel.

The screen remembers the last choice, so a repeat run or a map playtest is one keypress. It also ignores input for a moment after it opens. The keypress that started the run therefore cannot confirm it by accident.

Online, the lobby opens this screen instead. A substate over PlayState would freeze the sim while the network kept feeding it packets. The lobby runs the same card screen through `OnlineState`, while nobody is in the game yet. Both routes write the same `lastPick` that PlayState equips.

## EditorState

The map editor's coordinator. See [editor.md](editor.md).

---

Back to the [documentation index](../DOCS.md).
