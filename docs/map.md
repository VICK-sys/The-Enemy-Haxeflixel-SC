# Source map

One line per file in `source/`. Use this to find the file before you read the
page that explains the behaviour.

The other pages in [DOCS.md](../DOCS.md) describe what the game does. This page
says where it lives. When a page and this map disagree, the code wins and both
are wrong.

Entry points list the public functions worth reading first, not every member.

## Root

| File | Owns | Entry points |
| --- | --- | --- |
| `Main.hx` | the OpenFL entry point, the game window and the first state | `new` |

## `source/data/` - JSON readers

Every file here is a typedef set plus a registry that caches one parse. The
fields are documented in [data-files.md](data-files.md).

| File | Owns | Entry points |
| --- | --- | --- |
| `DataLoader.hx` | the one JSON parse used by every registry | `load` |
| `ArenaData.hx` | arena size and tile size | `get`, `pixelWidth`, `pixelHeight` |
| `EditorData.hx` | editor view, palette, UI and brush settings | `get` |
| `EnemyData.hx` | enemy definitions, and the `WormData`, `DomoData`, `BossData` and `FlankData` blocks | `get`, `has` |
| `LevelData.hx` | level up costs and stat curves | `get` |
| `PlayerData.hx` | player speed, dash, health and hitbox | `get` |
| `PropData.hx` | prop definitions and placements | `all`, `get`, `byName` |
| `RunData.hx` | run value bounds and event ranges | `get`, `event`, `names` |
| `ThemeData.hx` | arena themes and their colours | `all`, `get`, `colorOf` |
| `TilesetData.hx` | tileset definitions | `all`, `get`, `byName`, `indexOf` |
| `WaveData.hx` | the wave table, boss roster, boss pairs and scaling ramps | `get` |
| `WeaponData.hx` | every weapon config block, one typedef per weapon | `get` |

## `source/entities/` - sprites the player and enemies are made of

| File | Owns | Entry points |
| --- | --- | --- |
| `Player.hx` | the player sprite, dash, skin, hue and `feetY` | `dash`, `setHue`, `applySkin`, `touches` |
| `HealthPickup.hx` | the heart pickup | `drop` |
| `ScrapPickup.hx` | the scrap pickup and its pull toward the player | `drop`, `pullTo` |

### `source/entities/enemy/`

| File | Owns | Entry points |
| --- | --- | --- |
| `Enemies.hx` | the enemy sprite, its data, damage, knockback, stun, brace and `gaitScale` | `takeHit`, `brace`, `interruptAttack`, `requestShot`, `unseize` |
| `EnemyBrain.hx` | wander, follow and attack states, and the walk pulse read | `update`, `interrupt` |
| `EnemyNav.hx` | pathing, line of sight and the per frame path budget | `tick`, `steer`, `notifyBlocked`, `usedBudget` |
| `AttackBehavior.hx` | the interface every attack style implements | `update`, `reset` |
| `ChargeAttack.hx` | the windup, charge, arc and recover attack, and `chargeLift` | `update`, `reset` |
| `FlankAttack.hx` | the circling attack style | `update`, `reset` |
| `DomoBoss.hx` | Domo's dash, shots and the `ramming` flag | `update`, `reset` |
| `WormPart.hx` | the stub attack for wyrm segments, which the flock drives instead | `update`, `reset` |
| `EnemyShot.hx` | the enemy bullet, its life from `range / speed`, and the deflect | `fire`, `deflect`, `seize`, `hurl` |
| `ShotSpec.hx` | one queued shot request, pooled on the enemy | `set`, `at` |

### `source/entities/weapon/`

| File | Owns | Entry points |
| --- | --- | --- |
| `Arrow.hx` | the bow arrow, piercing and crits | `fire`, `hasHit`, `markHit` |
| `Bullet.hx` | the revolver round | `fire`, `setSprite`, `hasStruck` |
| `HookShot.hx` | the hook head in flight | `fire` |
| `RainArrow.hx` | one arrow of the rain, its marker and its drop | `launchUp`, `drop` |
| `SlashEffect.hx` | the melee slash sprite | `fire` |
| `ThrownWeapon.hx` | the thrown hammer and its return | `throwAt`, `beginReturn` |

## `source/states/` - screens

Movement between screens is described in [states.md](states.md).

| File | Owns | Entry points |
| --- | --- | --- |
| `TitleSequence.hx` | the boot animation before the menu | |
| `MainMenuState.hx` | the main menu rows, the splash line and the map slots | |
| `LobbyState.hx` | the lobby room, its signs, peer avatars and the run start | |
| `PlayState.hx` | a run: director, combat, HUD, camera lean and the net wiring | `openPanel` |
| `EditorState.hx` | the map editor screen | |
| `LobbyPanel.hx` | the shared panel chrome, `label`, `well` and `hints` for lobby subscreens | `new` |
| `OnlineSubState.hx` | the lobby ONLINE panel that routes to host or join | `onHost`, `onJoin` |
| `HostSubState.hx` | the host panel, its address and guest count | `onStopped` |
| `JoinSubState.hx` | the join panel and its address entry | `onJoined` |
| `DressUpSubState.hx` | skin, gear and colour picking | `onDone` |
| `WeaponPickSubState.hx` | the weapon picker and its art | `nameOf`, `artOf`, `slots` |
| `StatsSubState.hx` | the lifetime stats panel | `onDone` |
| `OptionsSubState.hx` | every option row, its pages and its preview | `new` |
| `ControlsSubState.hx` | key and pad rebinding | `new` |
| `PauseSubState.hx` | pause, resume, options, quit and back to lobby | `new` |
| `LevelUpSubState.hx` | spending level up points | `onSpent` |
| `TutorialSubState.hx` | the tutorial pages | `shown` |
| `LobbyHelpSubState.hx` | the how to play online panel | `shown` |

### `source/states/play/` - pieces PlayState owns

| File | Owns | Entry points |
| --- | --- | --- |
| `RunIntro.hx` | the first tutorial prompt | `armForRun`, `openTutorialIfNew` |
| `ReadyGate.hx` | the between wave ready gate and its net wait | `arm`, `wire`, `peerLost` |
| `ShopRound.hx` | the shop round, its solids and its net wait | `wire`, `updateShop`, `onWaveCleared` |
| `BossShow.hx` | the boss intro, the warning and the loot drop | `begin`, `dropLoot`, `defeated` |

### `source/states/editor/`

The editor is described in [editor.md](editor.md).

| File | Owns | Entry points |
| --- | --- | --- |
| `EditorMap.hx` | the grid, walls, tiles, props, undo and the CSV | `setWall`, `wallAt`, `pushUndo`, `undo`, `wallCsv` |
| `EditorView.hx` | editor pan and zoom, and mouse to world | `mouseWorld`, `cellAt`, `setZoom` |
| `EditorChrome.hx` | the top bar buttons and their callbacks | `setMode`, `setSlot`, `setSheet` |
| `EditorHud.hx` | the editor hint line and modal flash | `setHint`, `flash`, `modal` |
| `PalettePanel.hx` | the shared palette panel frame | `show`, `contains`, `localX` |
| `TilePalette.hx` | tile selection, marquee and zoom | `pick`, `step`, `drag`, `indexAt` |
| `PropPalette.hx` | prop selection and scrolling | `pick`, `select`, `scroll` |
| `TileTool.hx` | painting tiles, copy and paste, and the solid flag | `update`, `copySelection`, `paste` |
| `WallTool.hx` | the collision grid and its drawing | `rebuild`, `setCell`, `setThemeColor` |
| `PropTool.hx` | placing props, their ghost, flip and hitboxes | `update`, `setHeld`, `toggleFlip` |
| `LibraryPanel.hx` | importing art and editing hitboxes | `toggle`, `openHitbox`, `onAdded` |
| `PreviewPane.hx` | the art preview and its box drag | `load`, `setBox`, `artBounds` |

### `source/states/tutorial/`

| File | Owns | Entry points |
| --- | --- | --- |
| `TutorialDemo.hx` | the base class for every animated demo page | `new` |
| `MoveDemo.hx` | the movement page | `new` |
| `AttackDemo.hx` | the attack page | `new` |
| `HealthDemo.hx` | the health page | `new` |
| `ScrapDemo.hx` | the scrap page | `new` |
| `SuperDemo.hx` | the super page | `new` |
| `ReadyDemo.hx` | the ready gate page | `new` |

## `source/systems/` - per run systems owned by PlayState

Behaviour is described in [systems.md](systems.md).

| File | Owns | Entry points |
| --- | --- | --- |
| `PlayerCombat.hx` | health, the super meter, invincibility, hurt lines and kill rewards | `hurtPlayer`, `heal`, `canSuper`, `spendSuper`, `rewardKill` |
| `RenderLayers.hx` | draw order, the shadow, entity and tag layers, and `sortKey` | `trackPart`, `addEnemy`, `adopt`, `keyOf` |
| `Fx.hx` | impacts, sparks, steam, dash lines, screen shake and the burst pool | `impactAt`, `sparksAt`, `breakAt`, `shake`, `steamAt` |
| `Shop.hx` | the shop stall, its reach and its open state | `setOpen`, `inReach`, `addTo`, `solid` |
| `Pickups.hx` | mounting and collecting drops | `mount`, `drop`, `findById` |
| `Scraps.hx` | scrap drops and the boss payout | `drop` |
| `DamageNumbers.hx` | floating hit, crit and heal numbers | `pop`, `clear`, `applyLanguage` |
| `DeathBurst.hx` | the enemy death burst | `burst`, `any`, `clear` |
| `DashGhost.hx` | the player dash trail and its hue | `paint`, `clear` |
| `CoopGhost.hx` | the downed player ghost | `show`, `track`, `hide` |
| `ReviveRitual.hx` | reviving a downed player | `begin`, `cancel` |
| `TimeStop.hx` | the time stop super, its phases and its overlay | `update`, `timerLabel`, `hudLabel` |
| `BossFinish.hx` | the boss kill camera and its cancel | `trigger`, `cancel` |
| `BackGear.hx` | the gear on the player's back and its lean | `paint`, `leanFor` |
| `AfkPilot.hx` | the bot that plays for an absent player | `set` |
| `HitboxView.hx` | the debug hitbox overlay | `toggle`, `box`, `ray`, `circle` |

### `source/systems/enemy/`

| File | Owns | Entry points |
| --- | --- | --- |
| `EnemyDirector.hx` | waves, boss encounters, spawning, separation, rigs and the shot pump | `update`, `summonBoss`, `bossAlive`, `bossRoster`, `isBossWave`, `firstInCircle` |
| `EnemySpawner.hx` | placing enemies at edges, near points, and the stuck rescue | `placeAtEdge`, `placeNear`, `checkStuck`, `rescue` |
| `EnemyRig.hx` | one enemy plus its shadow, hitbox and stuck timers | `new` |
| `EnemyShots.hx` | the enemy bullet pool, wall raycasts and the shield and friendly hooks | `emit`, `update` |
| `BossDeath.hx` | normal boss defeat timing, drops and completion | `watch`, `onDrops` |
| `DomoDeathFx.hx` | Domo's red shake and shard breakup | `new`, `update` |
| `WormFlock.hx` | the magma wyrm: chains, trail, lift, charges, volleys, dirt mounds and collapse | `adopt`, `update`, `retire`, `moundCount` |

### `source/systems/weapons/`

Each weapon is described in [weapons.md](weapons.md).

| File | Owns | Entry points |
| --- | --- | --- |
| `Weapons.hx` | the weapon coordinator, every attack instance and input routing | `update`, `equip`, `hasSuper`, `repaint` |
| `HeldWeapon.hx` | the weapon in hand, its pose, aim lock and recoil | `setKind`, `handX`, `beginSwing`, `impactPose` |
| `HitPipeline.hx` | applying damage, radial blasts and the net claim | `damage`, `damageSuper`, `blastRadial` |
| `SwingAttack.hx` | the hammer swing and bash, the guard window and the shot deflect | `fire`, `update`, `coolFor` |
| `GigaCharge.hx` | the charged giga swing and its shine window | `charge`, `tick`, `letGo` |
| `HammerFlurry.hx` | the hammer super, its sweeps and finisher | `activate`, `cancel` |
| `ThrowAttack.hx` | throwing the hammer and catching it | `launch`, `onCaught` |
| `RevolverAttack.hx` | firing, the big shot, the twin and reloading | `fire`, `fireBig`, `activateTwin`, `beginReload` |
| `BowAttack.hx` | the charge shot, its sweet window and the reload hush | `beginCharge`, `release`, `tickCharge` |
| `ArrowRain.hx` | the arrow rain drop pattern | `fire`, `rainAt` |
| `ArrowStorm.hx` | the bow super and its marking phase | `activate`, `beginAt`, `onMarked` |
| `HookAttack.hx` | the yoyo throw, the grab and the held enemy | `fire`, `throwHeld`, `drop`, `onGrab` |
| `HookFlight.hx` | riding the hook | `launch`, `stop`, `onRelease` |
| `YoyoFlight.hx` | the yoyo in flight, its string and homing | `fire`, `recall`, `bounce`, `drive` |
| `YoyoJab.hx` | the yoyo jab and its recovery | `fire`, `release` |
| `YoyoSpin.hx` | the yoyo super, its captives and its shot deflect | `activate`, `cancel`, `captives` |
| `Rope.hx` | drawing the rope and yoyo string | `line`, `curve`, `clear` |
| `WeaponMode.hx` | the weapon mode enum | |

### `source/systems/world/`

| File | Owns | Entry points |
| --- | --- | --- |
| `Arena.hx` | the room, its walls, pillars, boss transition and `floorColorAt` | `addPillars`, `beginBossTransition`, `floorColorAt`, `tileBackground` |
| `CircleCollide.hx` | circle against map and circle against circle | `resolve`, `separate` |
| `FootCollide.hx` | foot level collision against solids | `against` |
| `PropBlock.hx` | whether a point or a segment hits a prop | `at`, `between` |
| `PropWorld.hx` | prop sprites, their solids and their overlay | `named`, `setSolid`, `setDecorVisible` |
| `PropSprite.hx` | one prop sprite and its layer mode | |
| `Decor.hx` | decor placement, its solids and its sort value | `make`, `place`, `sortValue`, `build` |
| `DecorTiles.hx` | the decor tile grid and its CSV | `parse`, `toCsv`, `build`, `blankCsv` |
| `WallSkin.hx` | painting the wall art | `paint` |

### `source/systems/chat/`

| File | Owns | Entry points |
| --- | --- | --- |
| `ChatLog.hx` | the message list, `CAP` 60, `MAX_LEN` 120, send, edit, delete and receive | `send`, `edit`, `remove`, `receive`, `get` |

## `source/net/` - online co-op

The protocol is described in [multiplayer.md](multiplayer.md).

| File | Owns | Entry points |
| --- | --- | --- |
| `Net.hx` | the socket transport, host and client mode, send and poll | `host`, `join`, `stop`, `send`, `poll`, `localAddress` |
| `NetSync.hx` | the message switch, wave and boss events, ready and leveling state | `update`, `setReady`, `requestRestart`, `peersHurt` |
| `PuppetDirector.hx` | the guest side director that adds puppet enemies instead of spawning | `addPuppet` |
| `PuppetMirror.hx` | applying host enemy state onto puppets | `apply`, `noteClaim`, `expectBossPack` |
| `RemoteAvatar.hx` | one remote player sprite, its held weapon, name tag and hue | `setHue`, `setLook`, `setName`, `apply` |
| `RemoteFx.hx` | remote attacks, sparks, hook and yoyo visuals | `attack`, `spark`, `setHook`, `superLaunch` |
| `Peer.hx` | one connected player and its avatar | `claim`, `applyAvatar`, `hide` |
| `PeerRoster.hx` | every peer, their bodies and the everyone down check | `get`, `drop`, `fillBodies`, `everyoneDown` |
| `AckQuorum.hx` | waiting for enough guests to acknowledge | `arm`, `ack`, `satisfied`, `disarm` |

## `source/ui/`

| File | Owns | Entry points |
| --- | --- | --- |
| `Hud.hx` | health, scrap, wave, the cursor, the stop timer and boss tracking | `update`, `showWave`, `showBoss`, `setTimeStop`, `setExp` |
| `BossHud.hx` | tracked boss HP, boss names and the red warning flash | `track`, `bossName`, `fraction`, `startFlash` |
| `ChatWindow.hx` | the chat log, its rows, input, emoji, reply and edit, and the idle fade | `show`, `focusInput`, `refreshScale` |
| `MenuList.hx` | the shared menu row list, selection, skipping and adjust | `setLabel`, `rowAt`, `setSkip`, `settle` |
| `MenuCursor.hx` | the menu mouse cursor and hover marking | `init`, `markHover` |
| `Counter.hx` | the FPS and memory counter | `new` |
| `ReloadBar.hx` | the revolver reload bar | `update` |
| `SoundTray.hx` | the volume tray shown by the plus and minus keys | `showAnim` |

## `source/util/`

| File | Owns | Entry points |
| --- | --- | --- |
| `Controls.hx` | every binding, pad and key state, aim, `padMode` and the gyro offset | `init`, `bindKey`, `bindPad`, `aimX`, `aimY`, `aimViewX`, `setAimAnchor` |
| `Gyro.hx` | reading the controller gyro rates | `available`, `poll`, `pitchRate`, `yawRate` |
| `SaveData.hx` | every saved setting and the best wave | one getter and setter per setting |
| `Stats.hx` | lifetime totals and the per run clock | `beginRun`, `addKill`, `addWave`, `commit` |
| `Levels.hx` | level up points, costs, refunds and the four stats | `points`, `spend`, `refund`, `award`, `level` |
| `Lang.hx` | the language table, and the three faces with their fixed sizes | `t`, `bodyFont`, `bodySize`, `titleFont`, `titleSize`, `smallFont`, `smallSize` |
| `Paths.hx` | every asset path and the sparrow atlas load | `image`, `sound`, `json`, `font`, `sparrow` |
| `HuePalette.hx` | hue shifted art, the live repaint and the player name tint | `graphic`, `live`, `sparrow`, `nameTint` |
| `Skins.hx` | the skin and gear lists | `of`, `nameOf`, `gearOf` |
| `Outline.hx` | building an outlined copy of a graphic | `graphic` |
| `GhostTrail.hx` | the shared afterimage trail | `tick`, `stamp`, `stampFrame` |
| `Sfx.hx` | positional sound and pitch tuning | `at`, `tune`, `bowShot` |
| `Music.hx` | music playback, run track selection and holds | `play`, `rollRunTrack`, `getRunTrack`, `hold`, `release` |
| `MenuSfx.hx` | menu step, hover, click and cancel sounds | `step`, `hover`, `click`, `cancel` |
| `Muffle.hx` | the low pass filter used when a panel is open | `set`, `clear` |
| `SoundSweep.hx` | finishes sounds whose completion event never arrived, so channels do not leak | `init` |
| `MenuSlash.hx` | the slash animation on a chosen menu row | `play` |
| `IrisWipe.hx` | the iris open and close transition | `open`, `close` |
| `Veil.hx` | the flat colour overlay | `make`, `fit` |
| `JaggedBand.hx` | the jagged band graphic | `new` |
| `WarpShader.hx` | the warp shader | `advance` |
| `AspectBars.hx` | letterboxing and the boxed scale mode | `init`, `apply`, `ratioOf` |
| `DpiAware.hx` | claiming DPI awareness on Windows | |
| `WorldClock.hx` | the global time scale used by time stop and the super | `reset` |
| `Lobby.hx` | the lobby room size and entering or leaving it | `enter`, `leave`, `room` |
| `CustomArena.hx` | the arena loaded from a stored map or the editor | `set`, `fromStored`, `clear` |
| `MapStore.hx` | reading and writing map slots | `load`, `store` |
| `Library.hx` | imported tilesets, props and wall art, and their hitboxes | `ensure`, `rescan`, `addTileset`, `addProp`, `setHitbox` |
| `DiscordPresence.hx` | the Discord rich presence lines | `init`, `tick`, `playing`, `menu` |
| `PerfLog.hx` | the frame time log written to `perflog.txt` | `frame` |
