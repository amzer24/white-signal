# Title screen and main menu research

26 September 2026. Research only. No code was changed.

## Summary

The best 2D platformer title screens do four things. They get the player to a working menu in a few seconds. They show a living scene from the game rather than a static card. They start the title music straight away and keep it running through every menu page. They make every input answer instantly with a short sound.

WHITE SIGNAL's current title misses the last three. Good foundations already exist: menu sounds (`menu_move`, `menu_confirm`, `menu_back`, used in World 1 menus but not on the title), saved settings, keyboard remapping, reduced flash and camera shake toggles, and a controls hint that follows the device in use.

The main recommendations are: a live night scene with the Spark resting on the signal wire, a pixel logo that the Spark "lights", a new D major title theme, five or fewer menu items with CONTINUE first, a start-game iris onto the Spark, and a game speed assist option.

Game descriptions without a linked source come from the shipped games as widely documented, not from developer statements.

## 1. The title scene

**What best-in-class games put on screen**

- **Hollow Knight** shows its logo over a moody animated backdrop with drifting particles. The menu sits directly under the logo. Players can pick from ten unlockable "menu styles" in Extras, each with its own background and ambient sound (rustling grass, fire, cave wind). Some unlock only after endings, so the title reflects progress.
- **Super Mario Bros. Wonder** changes its title background colour once the player reaches 100% completion.
- **Super Mario Bros. 3** opens with a stage curtain rising on a live scene where Mario and Luigi play out a little show. **Super Mario World** runs gameplay demos behind the logo.
- **Cuphead** shows Cuphead and Mugman animating beside the logo while a real barbershop quartet sings the title song.
- **Katana Zero** frames its whole menu as a VHS player, with tape-glitch shaders and levels presented as tapes.
- **Pizza Tower** puts its save select inside a dark room with Peppino on a stool.
- **Shovel Knight** keeps the title close to NES rules, a pixel logo and chiptune music, but breaks NES limits where they hurt the experience (for example no sprite flicker).

Pattern: a living scene that says what the game is about, the main character idling in it, a logo with its own small animation, and slow ambient motion. Several games change the title as the player progresses.

**"Press start" screen: yes or no**

The press start screen came from consoles, where it identifies which controller and user profile is playing, and gives the game a pause to load (GamesRadar). On a PC game that loads in a second, it is one more wait. That Game's UX argues title screens often just add "a forced break" and recommends loading everything before the title appears. The Game Accessibility Guidelines list "allow the game to be started without multiple levels of menus" as a basic guideline.

For a PC Godot game the better option is: no separate press start page. Show the logo animation, and reveal the menu when it finishes or on the first key press, whichever comes first. The first press also tells the game which device the player is using.

**Attract and idle behaviour**

Classic games ran gameplay demos after about 20 to 30 seconds of idle. Modern indies mostly keep a calm looping scene instead. A small idle event (the character does something) rewards players who leave the title open without hiding the menu. Pizza Tower's joke of making Peppino jump-scare idle players is a reminder that idle behaviour is noticed.

**The first five seconds of boot**

- Players dislike unskippable logos. Game Developer's "Splash screens are wrong" compares Dishonored (about 40 seconds to gameplay) with Volgarr the Viking (about 5 seconds). It recommends making every logo skippable, showing logos only while real loading happens, and moving credits to a menu option.
- Hollow Knight, Hades and Celeste show at most one short studio card before the title.
- Target: interactive menu within 3 seconds of launch, any studio card skippable by any input.

## 2. Main menu structure

**Item count and naming**

- Hades: Play, Options, Patch Notes, Quit. Four items, selected item in orange.
- Hollow Knight: Start Game, Options, Achievements, Extras, Quit Game.
- Celeste: Climb (its play button), Options, Credits, Exit, plus a PICO-8 item once unlocked.
- Shovel Knight: Start Game leads to a file list where you create or continue a file.

Pattern: four or five items. The play item is first. Settings second. Extras and credits lower. Quit last on PC.

**Continue versus Play**

Games with a single campaign usually have one play button that leads to save files, or put CONTINUE first when a save exists. Either way, a returning player should reach gameplay with at most two confirms. Destructive choices (new game over an existing save) always need a confirmation step.

**Save slot cards**

- Hollow Knight: four profiles. Each card shows the area the player saved in as background art, masks, soul, geo, playtime and completion percentage.
- Celeste: postcard-style files with name, playtime, deaths and strawberries. Stamps mark files that used Assist Mode or Variant Mode.
- Hades: four slots side by side.
- Sonic Mania: eight slots plus a "No Save" slot for quick play.

What a card needs: where you are (place name and a small picture), progress (a count and a percentage), and time played.

**Settings and extras placement**

Settings is always on the title and also in the pause menu, with the same layout in both. Extras holds credits, galleries, modes and secrets. Celeste puts assist options on the save file itself, so they are tied to that save.

**Fastest path for returning players**

Focus starts on CONTINUE. One confirm starts the game. Hades and Hollow Knight both need two (play, then pick slot). With one save, one confirm is better.

## 3. Menu audio

**Title music**

- Hollow Knight's title theme starts with soft piano as soon as the title appears and continues through every menu page.
- Cuphead's title is a full vocal song, the strongest possible first impression.
- Hollow Knight adds an ambient bed under the title music that changes with the menu style.
- Common pattern: a short intro that plays once, then a loop. Music does not restart when moving between title, settings and extras. It fades out when the game starts, often under a start sting.

**Menu sound set**

Sound designers describe a clear hierarchy: moving the cursor is the smallest and lightest sound, selecting is a bit bigger, confirming is the biggest. The full set is move, confirm, back, error or deny, open submenu, slider tick and start game. Consistency matters because the player learns the sound language quickly. Chiptune convention is a short rising blip or two-note chirp for confirm and the same voice falling for back. WHITE SIGNAL already follows this.

**Loudness and length**

- UI sounds should be 100 to 300 ms. The existing set fits: move 50 ms, back 120 ms, confirm 218 ms.
- Move should be a few dB quieter than confirm. Today they measure almost the same (`menu_move` RMS -19.5 dBFS, `menu_confirm` -19.4).
- For the whole game mix, Sony's ASWG-R001 standard is -24 LUFS integrated for home consoles and -18 for handhelds. PC has no rule, but -24 to -20 LUFS is a sensible reference.

**Avoiding fatigue from repeated move sounds**

- Use variation. Godot 4's AudioStreamRandomizer can rotate through takes without repeats and can vary pitch in semitones.
- Random pitch sounds out of tune in chiptune. A more musical option is to pitch each menu row to a note of the D major scale, so moving up plays higher notes. Sound Horizons turns each menu focus change into a note in one scale, which keeps the menu musical rather than repetitive.
- Only play the move sound when focus actually changes. Let each new move sound cut the previous one (one voice, as on the NES). Play held-key repeats a little quieter.

## 4. Motion and feel

**Selection highlight**

- XAG 113 (Xbox Accessibility Guidelines): the focus marker must always be clearly visible, not just a subtle glow. Combine shape, fill and weight. Fallout 76 uses a solid bar plus an animated character beside it. Hollow Knight flanks the selected item with ornaments.
- WHITE SIGNAL's inverted white bar already meets this. Adding the Spark as a cursor gives it character.

**Timings**

- Nielsen Norman Group: about 100 ms for simple feedback, 200 to 300 ms for moderate screen changes, 300 to 400 ms for large moves, never over 500 ms. Enter with ease-out (fast start, gentle stop). Leave with ease-in.
- Input must respond on the frame it is pressed. Sound and highlight move on key down, not key up.

**Transitions into the game**

Classic Mario games use an iris that closes on the player. Celeste uses a quick wipe. Katana Zero uses a tape glitch. The best tie the transition to the game's theme and keep it around one second.

**Controller, keyboard and mouse**

- XAG 112: menus fully usable with keyboard alone and controller alone. Linear menus wrap from bottom to top. Back always returns to the previous page. Remember which item was focused when returning.
- XAG 107: all controls remappable in game, including controller buttons.
- Prompts should follow the last device used, not the one that happens to be plugged in. Show generic prompts for controllers the game cannot identify.
- Mouse hover moves focus. Click confirms. The menu must never have "no focus".

## 5. Accessibility expected on day one

From Game Accessibility Guidelines (basic list), Xbox Accessibility Guidelines, and what Celeste and Dead Cells ship:

- Separate music and effects volume. **Done.**
- Remappable controls on keyboard **(done)** and controller **(missing)**.
- Game speed option. Celeste offers 100% down to 50% in 10% steps. Its designer says the middle steps, such as 80% or 90%, matter most.
- Assist options: Celeste has infinite stamina, extra dashes, invincibility and skip chapter. Dead Cells has continues, slower traps and enemy damage sliders. Wording matters. Celeste changed "its difficulty is essential" to "intended to be a challenging and rewarding experience" after disabled players said the first version felt insulting.
- Reduced flashing **(done)**. XAG 118: no more than three flashes a second, no flash over about 20% of the screen, and take extra care with saturated red.
- Screen shake off **(done)**. Background motion off (XAG 117 asks for a way to stop moving backgrounds behind menu text).
- Readable default text. No information by colour alone. All settings saved **(done)**.
- Optional: offer the key accessibility settings on the very first launch, as Minecraft Dungeons does (XAG 112).

## 6. Common mistakes

1. Unskippable studio logos, or logos shown before loading starts.
2. A press start page on PC that adds a step and does nothing.
3. Silence on the title. The first seconds set the tone.
4. Music restarting each time the player enters or leaves Settings.
5. Every UI sound equally loud, or a cheerful confirm that gets annoying by the tenth press.
6. Move sounds firing when focus did not change, or stacking on held keys.
7. A menu with no focused item after using the mouse.
8. Prompts showing the wrong device.
9. New Game overwriting a save without confirmation.
10. Too many top-level items, or modes and help mixed in with the main actions.
11. A moving background behind menu text with no way to turn it off.
12. Full-screen white flashes as a transition effect.

## Recommended for WHITE SIGNAL

Codes are for reference in follow-up discussion.

**Boot (B)**

- **B1** Replace Godot's default boot splash with a plain background colour, no forced minimum time.
- **B2** No studio card for now. If one is added later: 1 second, skippable by any input.
- **B3** Target: title music playing and menu usable within 3 seconds of launch.

**Screen layout at 480x270 (L)**

- **L1** Background: a live night scene over the flats. Three parallax layers drift slowly left (about 2, 5 and 10 px per second). Telegraph poles carry the signal wire across the lower third, around y 190.
- **L2** The Spark rests on the wire near x 90, pulsing gently (brightness only, about a 2 second cycle). A tiny answering light blinks far off on the horizon, once every 3 to 4 seconds, in a few pixels only. That is the caller.
- **L3** Logo: a hand-made pixel wordmark "WHITE SIGNAL", about 240 x 44 px, centred at y 28 to 72. On boot the Spark runs along a line under the logo and lights each letter (1.2 seconds in total). Any input skips straight to the finished state.
- **L4** Menu: left-aligned column at x 56, first row at y 120, rows 18 px apart, text at scale 2. The highlight stays the inverted white bar, 160 px wide. The Spark sprite sits as a cursor 8 px left of the selected row.
- **L5** Detail line for the selected item at y 232 (for example "LAST RELAY . 5 LIVES . 42 SHARDS . 1H 12M"). Device-aware control hint at y 252.
- **L6** The scene tint follows progress: flats tint, relay tower tint after World 2 is reached, aerials at dawn after World 3 is reached. Players see how far they have come.
- **L7** Remove the 78% black overlay. Use a darker sky behind the menu column instead, so text contrast stays high.
- **L8** Idle: after 45 seconds, the Spark hops along the wire and back. The menu stays visible.

**Menu items (M)**

- **M1** With a save: CONTINUE, NEW GAME, SETTINGS, EXTRAS, QUIT. Without a save: START, SETTINGS, EXTRAS, QUIT.
- **M2** Focus starts on CONTINUE or START. One confirm enters the game.
- **M3** NEW GAME over an existing save shows one confirm page with BACK focused first.
- **M4** Move CLASSIC RUN and HOW TO PLAY into EXTRAS. HOW TO PLAY could also live in the pause menu.
- **M5** Cut the separate PLAY sub-page (CONTINUE, NEW GAME, BACK). Its choices move to the top level.
- **M6** Settings adds: GAME SPEED (100% to 50% in 10% steps), ASSIST (extra hits, skip level), CONTROLLER remap, BACKGROUND MOTION on or off. Word assist neutrally. No "intended" or "cheat".
- **M7** One save file is fine for now. If slots are added, use three cards showing a world-tinted thumbnail, place name, shards, time played and an assist stamp.

**Sounds (S)** (levels are loudest-50 ms RMS, the measure the sfx8 set already uses)

| Code | Sound | Status | Length | Level | Notes |
|---|---|---|---|---|---|
| S1 | `title_theme` | New | 2-bar intro, then about 40 s loop | Music bus | D major, about 84 BPM. Triangle bass, thin 12.5% pulse arpeggio, sparse lead quoting the FIRST LIGHT motif (D G G A B G) slowly. Starts with the logo. Continues through Settings and Extras. |
| S2 | `menu_move` | Exists, retune | 50 ms | about -22.5 dBFS (3 dB below today) | One note per row from the D major scale, higher rows higher. Only when focus changes. Cuts the previous voice. Held repeats a further 3 dB down. |
| S3 | `menu_confirm` | Exists | 218 ms | -19.4 dBFS | Also used for opening a sub-page. |
| S4 | `menu_back` | Exists | 120 ms | -19 dBFS | Back, cancel, closing a page. |
| S5 | `menu_deny` | New | about 150 ms | -20 dBFS | Two short low buzzes, a semitone apart, like `shop_deny` but shorter. For unavailable items. |
| S6 | `menu_tick` | New | about 30 ms | about -24 dBFS | Slider steps. Pitch rises with the value. At most one every 60 ms. |
| S7 | `title_start` | New | about 0.8 s | about -17 dBFS | Rising D major arpeggio (D F# A D) ending on a bright held note as the Spark leaves. Plays over the music fade. |
| S8 | `amb_title` | Optional | loop | under music | Soft wind and a faint wire hum. `amb_w1` may do. |

**Timings (T)**

- **T1** Highlight: bar snaps to the new row on key down (0 ms). The Spark cursor slides in over 80 ms with ease-out.
- **T2** Hold to repeat: 400 ms first delay, then every 110 ms.
- **T3** Open a sub-page: 160 ms fade to the settings panel. Back: 120 ms.
- **T4** Start game: `title_start` and the music fade (400 ms) start on confirm. Menu text fades out in 150 ms. The Spark zips right along the wire (350 ms, ease-in). An iris closes on the Spark (350 ms). Black for 100 ms. Iris opens on the Spark in the level (350 ms). Total about 1.2 seconds.
- **T5** No white flash anywhere in these transitions. With Reduced Flash on, the iris becomes a plain 250 ms fade.
- **T6** With Background Motion off, parallax, idle hop and horizon blink stop. The Spark keeps its brightness pulse.

**Input (I)**

- **I1** Confirm: Enter, Space, Z and controller A. Back: Esc, Backspace, X and controller B. All act on press.
- **I2** Linear menus wrap from bottom to top.
- **I3** Mouse hover moves focus and plays `menu_move` only when focus changes. Click confirms. Focus never disappears.
- **I4** Prompts follow the last device used (already true on the home page). Use generic wording for unknown controllers.
- **I5** Returning from a sub-page restores the previous focus (already true).

**What to cut (C)**

- **C1** The PLAY sub-page.
- **C2** CLASSIC RUN and HOW TO PLAY as top-level items.
- **C3** The dim leftover backdrop and the heavy black overlay.
- **C4** The Godot boot splash.
- **C5** Silence. The title must never be silent once the logo appears.

Open decision for Lee: moving CLASSIC RUN into EXTRAS (M4) hides it from new players. If it is a main mode, keep it as a fourth top-level item instead.

## Sources

- Celeste Assist Mode options: https://celeste.ink/wiki/Assist_Mode
- Celeste Assist Mode wording change (Vice): https://www.vice.com/en/article/celeste-assist-mode-change-and-accessibility/
- Celeste photosensitive mode and screen shake (Steam discussion): https://steamcommunity.com/app/504230/discussions/0/1699416432407623292/
- Celeste file stamps: https://celestegame.fandom.com/wiki/File_Stamps
- Game UI Database, Celeste: https://www.gameuidatabase.com/gameData.php?id=53
- Game UI Database, Hollow Knight: https://www.gameuidatabase.com/gameData.php?id=113
- Hollow Knight menu styles and their sounds: https://hollowknight.wiki/w/Menu_Styles_(Hollow_Knight)
- Music of Hollow Knight: https://en.wikipedia.org/wiki/Music_of_Hollow_Knight
- Hades menu guide (Blind accessible walkthrough): http://www.blackscreengaming.com/hades/menus/
- Super Mario Bros. Wonder title changes with completion (Game Rant): https://gamerant.com/mario-wonder-how-save-load-game/
- Shovel Knight manual (Yacht Club Games): https://www.yachtclubgames.com/blog/shovel-knight-shovel-of-hope-instruction-manual/
- Breaking the NES for Shovel Knight (Game Developer): https://www.gamedeveloper.com/design/breaking-the-nes-for-shovel-knight
- Cuphead title song: https://cuphead.wiki.gg/wiki/Four_Mel_Arrangement
- Katana Zero tapes and VHS menu: https://katanazero.wiki.gg/wiki/Tapes
- Pizza Tower title and save select (TCRF): https://tcrf.net/Pizza_Tower/Unused_Rooms/Title_Screens_&_Cutscenes
- Dead Cells assist and accessibility options: https://deadcells.wiki.gg/wiki/Assist_Mode_and_Accessibility
- Splash screens are wrong (Game Developer): https://www.gamedeveloper.com/design/splash-screens-are-wrong
- Title screens (That Game's UX): https://www.thatgamesux.com/title-screens-because-you-arent-done-waiting-just-yet
- What are press start screens for (GamesRadar): https://www.gamesradar.com/ask-gr-anything-what-are-press-start-screens/
- In Octave devlog, press start: https://itooh.itch.io/in-octave/devlog/36815/in-octave-devlog-7-press-start-to-play
- Sound Horizons devlog, musical menu sounds: https://itooh.itch.io/sound-horizons/devlog/749469/devlog-11-menus-part-2
- Game UI sound best practices (SFX Engine): https://sfxengine.com/blog/best-practices-for-game-ui-sounds
- Godot AudioStreamRandomizer: https://docs.godotengine.org/en/stable/classes/class_audiostreamrandomizer.html
- ASWG-R001 loudness (Sony): http://gameaudiopodcast.com/ASWG-R001.pdf
- Animation duration (Nielsen Norman Group): https://www.nngroup.com/articles/animation-duration/
- Game Accessibility Guidelines, basic: https://gameaccessibilityguidelines.com/basic/
- Game Accessibility Guidelines, remapping: https://gameaccessibilityguidelines.com/allow-controls-to-be-remapped-reconfigured/
- XAG 107 Input: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/107
- XAG 112 UI navigation: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/112
- XAG 113 UI focus handling: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/113
- XAG 117 Visual distractions and motion: https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/117
- XAG 118 Photosensitivity: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118
- Input prompts showing the wrong device (Bugnet): https://bugnet.io/blog/how-to-fix-input-prompts-showing-the-wrong-device
