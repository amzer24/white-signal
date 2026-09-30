# World 4: Dead Air

World 4 is the deep exchange under the whole network, where every cut line ends. There's no wind and no daylight, only dead equipment, and the Howl lives down here. It follows the plan in `docs/research/traps-enemies-2026-09-25.md`: one new thing in each of the first three levels, then a finale that mixes them, with the Howl chasing you.

The levels are one screen tall with a ceiling of cables overhead, except 4-3, which is a shaft four screens tall. The tint is a cold sea green.

## New things

| Tile or header | Thing | How it works |
|---|---|---|
| `t` | Relay turret | A solid box that fires a bolt along its row on a clock (`t#k dir= period= phase= speed=`). Its eye lights up for 0.3 s before each shot. The bolt flies until it reaches the first solid tile in its row, so a block or pillar is a bolt stopper. You can stand on a turret, but it can't be destroyed. |
| `e` | Echo | A scrap of the Howl, like a Boo. It drifts toward the Spark only while the Spark faces away from it, and stops and hides its face when the Spark turns round (`e#k speed= wake=`). It passes through walls. Stomping does nothing. The Arc scatters it for good. |
| `static:` header | Wall of static | `static: up,24,3.0,8` rises from the bottom of the level at 24 px a second, starting 3 seconds in, and stops at row 8. `static: right,64,3.0,170` chases from the left edge instead and stops at column 170. It swallows the Spark whole, so a CHARGE doesn't save you. After a respawn at the midway beacon it starts again five tiles below the beacon (rising) or ten tiles behind it (chasing). The Howl's face shows in the front of the wall. |
| `goal: ring` header | The ring | The last level ends at the ring of Sparks instead of a mast. Touching it closes the ring and plays the ending. |

Turret bolts and the wall of static are pure functions of time, like the World 1 to 3 machinery. Echoes react to the Spark, so the checker carries their positions in its run state. The game's rules (`scripts/world1/w1_sim.gd`) and the checker's (`tools/levels/`) match, and the replay test covers every World 4 level.

Keep every turret in a level on the same period (2 s) and vary the phase instead. Mixed periods make the checker's search many times slower.

## The four levels

**4-1 Relay Turrets.** Brace waits at the start, having come down ahead of you.
- A: a turret fires along the ground toward a low wall, and you jump its bolts.
- B: a pit crossed under head-height bolts, with a girder bridge that the bolts pass beneath.
- C: a long corridor. Hop onto the shelves inside it and let the bolts pass underneath, or run along the roof, where a second turret sweeps the top, for a Pip.
- D: the midway beacon. One turret fires along the ground away from you while another fires back at head height. There's a CHARGE, and a stash behind a cracked wall.
- E: steps up to a high Pip, then a pit under head-height bolts and one last turret firing toward the mast.

**4-2 Echoes in the Dark.** Most of the level is dark except near lamps, and the echoes glow faintly.
- A: the first echo waits ahead and hides as you come close.
- B: wait at a pit for a moving girder, facing the echoes so they freeze.
- C: a tunnel with loose floor over a pit, an echo behind and another hanging ahead at head height. The tunnel roof hides a Pip, watched by an echo.
- D: the midway, a girder stair up to a Pip between two echoes, and a stash.
- E: two faster echoes and a spring up to the last Pip before the mast.

**4-3 The Rising Static.** A single shaft, four screens tall. The static starts rising three seconds in. You climb girders, a lift ring and a spring past two turrets to the mast at the top. The midway beacon is halfway up. Pips hang off to the sides of the climb, so each one is a risk against the rising static.

**4-4 The Last Gate.** Three seconds in, the Howl roars and a wall of static chases you from the left.
- A: small walls and a pit to get running.
- B: turrets firing at you along the ground and at head height, with a Pip up on a girder.
- C: echoes hanging over a girder bridge and the ground.
- D: the midway, then loose floor over a pit while a turret fires along it.
- E: a final mix of echoes and head-height bolts, with a Pip up a step.
- F: the static stops, and there's a stash, a Pip and the ring.

## Story

- Going into 4-1 for the first time plays cutscene C5: the line runs down into Dead Air, the Howl speaks, and under it the call is close.
- Brace waits at the start of 4-1: MY CREW CUT THE WIRE YOU WERE LYING ON, SPARK. NOW I'M HERE TO HELP YOU JOIN IT BACK TOGETHER.
- After 4-2, Wren hears the call change: THE RING WON'T CLOSE WITHOUT YOU.
- After 4-3, Old Mast asks the Spark to come back up.
- Reaching the ring closes it and plays the ending, cutscene C6. The ring closes, the Howl comes apart into every voice it swallowed, the stations light up one at a time, and the line rings three times at Last Relay. The Pips you brought home answer too. Wren says home is everywhere the line goes, and then the credits roll.
- Afterwards the game carries on in Last Relay. Sparks from all along the line visit, and everyone has something new to say. Clearing 4-4 sets `w4_clear`.

## Pips

Each World 4 level has 3 Pips, which brings the total to 47. Dot's last gift, her thank-you, now needs all 47.
