# World 1 level design

Status: proven in simulation and playable in Godot (WORLD 1 on the title screen) as of 24 Sep 2026. Decided on 23 Sep 2026.

## The game in one line

Someone is still calling. Reach them. Each world ends at a Gate, and when you light it the call moves further down the line. The last world is where you find the other spark.

## Rules that change from Classic

| Area | New rule |
|---|---|
| Menu | Exploration mode is hidden from the menu. Its code stays in place. |
| Lives | Start with 5. You get an extra life at 100 shards and from 1UP blocks. At game over you restart the current world at level 1. |
| Timer | Each level counts down from 300. When it reaches zero you lose a life. Time left over is added to your score. |
| Dash | You have it from the first level. It refills when you touch the ground or a lift ring. The card draft is removed. |
| Power-up | CHARGE is the only one. It lets you survive one hit, and bumping a brick while charged breaks it. |
| Stomp | Landing on an enemy bounces you. Hold jump and you bounce as high as a normal jump. Each enemy you land on before touching the ground adds more height. |
| Checkpoint | Each level has one midway beacon. |
| Goal | A mast at the end of the level. The higher you touch it, the bigger the bonus. |
| Mastery | Every level has 3 big shards, a target time and a replay of your best run. |
| HUD | Shards, lives, world number and time. Nothing else. |

### Movement change (approved 24 Sep 2026, now in `scripts/player.gd`)

The simulator found that, with the current movement, the Spark can climb any single wall. It kicks off the wall, steers back and kicks again. This means a wall can never act as a barrier. The fix is the one Celeste uses: after a wall kick, your direction is locked away from the wall for 0.16 seconds. Climbing between two walls still works. The Classic and Exploration test suites still pass with it.

### Softer wall kick (24 Sep 2026, World 1 only)

After playtesting, the kick threw the Spark too far. If you let go of the stick after a kick, you flew about 8 tiles. Two changes, in `scripts/world1/w1_sim.gd` and `tools/levels/physics.py`:
- The kick is a little weaker: 1.0 × run speed instead of 1.15.
- In the air, with no direction held, the Spark now slows to a stop in about a quarter of a second. Before, it kept all its speed.

A kick with nothing held now carries about 2 tiles. Holding into the wall still carries about 2 tiles, because the 0.16 s lock is what stops a single wall being climbed. The simulator checked that every limit in the table below is unchanged. `scripts/player.gd` (Classic) is not changed.

## Climbs (added 25 Sep 2026)

Hold Down and press jump while standing on a thin girder to drop through it (added 26 Sep 2026). It only works in play. The level checker never presses Down, so no proof depends on it.

After playtesting, every level felt flat, so World 1 levels are now two screens tall (34 rows, ground at row 31). The back half of each level sits 8 rows higher, and a new climb screen joins the two:
- 1-1 C2: block steps up to the high road, with a girder and a big shard above.
- 1-2 D2: loose steps that crumble behind you, with a solid girder ladder as the slower way up.
- 1-3 E2: a girder that lifts you 8 rows.
- 1-4 D2: a wall-kick shaft between two walls, 10 rows high.

All coordinates in the `[objects]` sections were moved to match. The bonus room exit now goes to where the pipe comes out in the new layout.


Hidden shard blocks (tile `i`, 5 shards each) were added on 26 Sep 2026. There are two per level: 1-1 (4,27) behind the start and (166,17); 1-2 (63,25) and (233,19); 1-3 (94,27) at the end of a block row and (209,19); 1-4 (86,27) and (181,17). They sit off the proven route, and the level checker proves each one can be hit.

## Design rules, measured

These limits come from running the game's real movement numbers in the simulator (`tools/levels/envelope.py`). Tiles are 16 px.

| Move | Normal play | Limit |
|---|---|---|
| Jump up onto a ledge | 3 tiles | 3 tiles |
| Jump across a gap on level ground | 5 tiles comfortable | 7 tiles, needs perfect timing |
| Jump and dash across a gap | 8 to 9 tiles | 11 tiles |
| Climb between two walls | 2 to 4 tiles apart | 4 tiles apart |
| Single wall | stops you at 4 tiles | experts can wall-kick then dash over up to 6 tiles |
| A wall that must stop everyone | | 7 tiles, or a ceiling |
| A pit 4 or fewer tiles wide | you can kick back out of it | |
| Lift rings in a chain | 5 tiles apart | 5 tiles. At 6 apart the chain can't be completed |

## New interactions

Each one is introduced alone and safely before it's combined with anything else.

| Tile | Name | Behaviour | Where it appears first |
|---|---|---|---|
| `L` | Loose floor | Shakes for 0.35 s after you land on it, then falls. Anything under it gets crushed, and it lands as rubble. | 1-2 A |
| `F` | Loose ceiling | Drops a chunk 0.4 s after you pass underneath. If you keep moving it misses you. | 1-2 D |
| `_` and `\|` | Plate and gate | A plate opens its gate. Rubble resting on a plate holds it down. Some gates close again after a set time. | 1-2 E |
| `X` | Press | Slams down on a 2 s cycle. It shakes for 0.3 s first as a warning. | 1-3 A |
| `m` | Moving girder | Moves back and forth on a fixed cycle, and you can jump up through it. A girder marked `start=ride` waits until you step on it, makes one trip and stops. Presses marked `sync` on it start their cycle at the same moment, so the ride plays out the same way every time. | 1-3 C |
| `T` | Spike vent | Spikes rise from the floor on a clock. The vents are offset so the spikes move along in a wave. | 1-3 G |
| `R` | Lift ring | Gives your dash back and pops you about 3 tiles upward. Letting go of jump doesn't cut the pop short. Chained rings let you cross a long drop. | 1-3 H |
| `D` | Dropper | Falls when you pass underneath, waits 1.5 s, then rises slowly. You can ride it up like a lift. It resets once it's back at the top. It always hangs one tile below the ceiling so a rider is never crushed. | 1-4 A |
| `W`, `K`, `Z` | Warden, lever, bridge | The warden paces the bridge and hops. You get past it and pull the lever, and the bridge collapses under it. | 1-4 F |

## The four levels

Each map image shows every tile, all moving parts with how far they travel and their timing, and the route the simulator proved. Screen letters match the map.

### 1-1 First Light (`levels/world1/1-1.png`)
Teaches running, jumping, bumping blocks, stomping and dash.
A: you meet your first bump block and first walker. B: pillars 2, 3 and 3 tiles tall with walkers between them. A pipe leads to a bonus room with 21 shards. Two ledges you can jump up through reach the high rows, and a block by the exit pipe holds the big shard. C: pits 3 and 5 wide, with a hidden 1UP block. D: a brick bridge with walkers on it, plus a high route up to a big shard. E: a 9-tile gap you can only cross with dash. Missing it drops you into a shallow trench, and you can climb back out to the left and try again. F: a real pit you have to dash over, then three walkers in a row. Stomping two or more in a row without landing bounces you up to a 1UP. G: the staircase and the mast. The big shard above the mast needs a jump with a dash at the top of the arc. The solver shows it's only just reachable.

### 1-2 Loose Ground (`levels/world1/1-2.png`)
Teaches loose floors, loose ceilings, and plates with gates.
A: loose floor over a shallow trench, so falling in is safe. B: a loose bridge over a pit, then floating loose steps. C: you have no choice but to drop through the floor into a low channel with walkers in it. D: a corridor with a loose ceiling where you have to keep moving, and a walker coming the other way. A chimney leads up to a big shard. E: the midway beacon, then a plate in plain sight that opens a short gate for 3 seconds. F: a gate you can't jump over. The floor over the pit falls, and the piece above the plate lands on it and holds the gate open. A spring throws you up onto the roof in screen G. G: a loose bridge with the roof dropping on it, and a high route along the top of the roof. H: the staircase and the mast.

### 1-3 The Presses (`levels/world1/1-3.png`)
One idea: machinery that moves in rhythm (presses, girders, spike vents). Lift rings are the finale. Hoppers were moved to World 2 so this level doesn't teach too much.
A: one press with a safe spot to watch it. B: four presses slamming in a wave. C: a sideways girder and a lifting girder over a pit. D: walkers under a row of blocks. E: the midway beacon, a CHARGE block, and the first lift ring over solid floor. F: you ride a long girder under two presses. The girder starts when you step on it. The first press always misses you, so you see what it does. The second only misses you if you stand on the back two-fifths of the girder. The press shakes before each slam as the warning. G: a run of spike vents in rhythm. H: three lift rings about 5 tiles apart across a 16-tile drop, then the mast. The first ring is low and easy to hit. Missing it drops you into a short trench you can climb out of. The drop can't be crossed without the rings. The big shard sits just above the second ring.

### 1-4 The Gate (`levels/world1/1-4.png`)
Teaches droppers, a timed gate and the warden. This level is indoors, with a ceiling throughout.
A: a dropper that falls behind you if you keep running. You then ride it up to a ledge with a big shard. B: a plate that opens a gate 21 tiles away for 4.5 seconds, so it's a race. Running there takes about 2.5 seconds. C: spike vents under a row of presses. D: the midway beacon. E: three droppers in a low corridor. F: the warden on the bridge. You run under it when it hops, or jump over it, then pull the lever. G: the Gate.

## Research behind the changes

A review on 24 Sep 2026 checked these levels against published design advice. It led to three rules:
- **One idea per level, taught in four steps.** Show it safely, make it harder, give it a twist, then a finale. Only 1-1 teaches several things, as Super Mario Bros 1-1 does. The source is Koichi Hayashida on Super Mario 3D Land ([Game Developer](https://www.gamedeveloper.com/design/the-structure-of-fun-learning-from-i-super-mario-3d-land-i-s-director)).
- **Show a trap working before it can hurt you.** Prince of Persia put its plates and loose floors where the player sees them work first ([secondary source on Mechner](https://awweide.substack.com/p/the-making-of-prince-of-persia)).
- **Don't punish players while you're teaching them.** A first-time player should finish a level in 1 to 2 minutes, and experts in 20 to 30 seconds. Super Mario Bros gave 160 seconds per level ([Mario Wiki](https://www.mariowiki.com/Time_Limit)). Also see [Super Meat Boy's McMillen](https://www.gamedeveloper.com/game-platforms/-i-super-meat-boy-i-s-mcmillen-explains-why-so-hard-) and [Celeste and forgiveness](https://www.maddymakesgames.com/articles/celeste_and_forgiveness/index.html).

## Music

The four tracks provided on 23 Sep 2026 are assigned by title and length. Nobody has listened to them against the levels yet, so treat this as a first pass.

| Level | Track | Length |
|---|---|---|
| 1-1 | WHITE SIGNAL - Dead Carrier (1) | 158 s |
| 1-2 | WHITE SIGNAL - Below the Carrier (2) | 90 s |
| 1-3 | WHITE SIGNAL - Dead Carrier (2) | 90 s |
| 1-4 | Haunted Forest Loop | 61 s |

## How the maps are proven

`python tools/levels/build_maps.py` reads each level file and searches for a route using a copy of the Spark's movement from `scripts/player.gd`. It steps every frame at 60 per second, with every moving part in the level running. A route it finds is a real sequence of button presses. It also searches for a route to every big shard. The results go to `levels/world1/<level>.proof.json`, and each map shows its route. Where a route needs you to go past something and come back, like riding a dropper, the level file lists waypoints (`route#1 via=` and `O#2 via=`) and the proof checks each leg in turn.

Limits of the proof:
- The proof shows a level can be finished, but not that it's fair. The route it finds is the fastest, which uses dash almost everywhere, so a first-time player will be much slower.
- Enemies follow their patrol paths. An enemy is lost when the floor under it falls, or when a falling loose floor lands on it. A falling loose floor that lands on the Spark kills it. All of this is simulated.
- Every small shard is checked as well as the big ones (`small_shards` in the proof file).
- If `player.gd` or `RunState.BASE` changes, `tools/levels/physics.py` has to change with it.

## Level file format

`levels/world1/*.txt`. Each level is a header, then screens of 17 rows each joined left to right, then an `[objects]` section for timings (for example `X#2 phase=0.25`, where objects are numbered from left to right). The legend is in `tools/levels/levelkit.py`. The Godot loader will read these same files, so the maps and the game can't drift apart.

## Playable build

Choose WORLD 1 on the title screen. It starts in the test room (`levels/world1/test-room.txt`), which has one labelled station per item, then runs 1-1 to 1-4.

- The rules live in `scripts/world1/w1_sim.gd`. It's a direct port of the simulator, so what you play is what was proven. `scripts/world1/w1_replay_test.gd` replays every proven route inside Godot. Each must reach the mast on the same frame as in Python.
- Drawing, HUD, sound, lives and level flow are in `scripts/world1/w1_game.gd`. The art is from `assets/world1/`, the sounds from `assets/audio/sfx8/` and the music from `assets/audio/music/`.
- Controls: arrows or A/D to move. Space, W or Up to jump. Shift to dash. Down or S to enter a pipe. Esc or P to pause. On the pause screen, 0 opens the test room, 1 to 4 open levels 1-1 to 1-4, R restarts and Q quits to the title. F toggles the screen filter.
- Exploration is hidden from the title (`show_exploration` in `scripts/menu_ui.gd`). Its code and saves are unchanged.

- The camera looks ahead only while you keep running one way, and it moves gently. Small moves don't shift it.
- Hidden blocks glint faintly every few seconds.
- Loose floor over a pit falls off the bottom of the screen. Over solid ground it lands as rubble.
- Down on the D-pad or the left stick enters a pipe.
