# World 3: The Aerials

World 3 is a set of broadcast masts high above the drowned city, at dawn. Wind carries the signal. It follows the plan in `docs/research/traps-enemies-2026-09-25.md`: one new thing in each of the first three levels, then a finale that mixes them.

## New things

| Tile | Thing | How it works |
|---|---|---|
| `f` | Wave flyer | A walker with wings. It swings `range` tiles out from where it starts and back, bobbing on a sine wave (`amp` px, every `period` s). You can stomp it or dash through it like a walker. With `range=0` it hovers in place, which makes it a stepping stone over a pit. |
| `>` `<` | Side wind | Pushes the Spark sideways, up to 190 px/s. It's stronger than your air control, so a headwind pushes you back mid-jump. On the ground you can still walk into it. |
| `u` | Updraft | Lifts the Spark at up to 210 px/s. You ride it up and drift off the top. |
| `A` | Sweep arm | A solid hub with a bar of static balls turning round it (`len` balls, `speed` degrees per second, negative turns the other way). Touching a ball hurts. |

Wind can blow all the time, or in gusts. The level header `gust: 3.0,2.0` means the wind blows for the first 2 seconds of every 3. The streaks bunch up and a hiss plays half a second before each gust. A dash cuts straight through the wind.

All four are pure functions of time, so the level checker proves them the same way as the World 1 and 2 machinery. The game's rules (`scripts/world1/w1_sim.gd`) and the checker's (`tools/levels/`) match, and the replay test covers World 3.

## The four levels

**3-1 Wave Flyers.** A flyer that hovers, then one that patrols. Next comes a gap crossed by stomping three hovering flyers in a chain, then a climb to the high road under a patrolling flyer. At midway, two flyers carry you over a gap, and a flyer bounce reaches a big shard on a girder. The level ends by dropping down to the mast.

**3-2 Carrier Wind.** Gusts blow two seconds in every three. You meet a tailwind on flat ground, and an updraft that lifts you to a ledge with shards. Then you ride an updraft out of a trench onto a high platform, and cross a catwalk against a headwind by jumping in the lulls. At midway, a tailwind carries a leap that's too long without it. An updraft beside the last tower takes you up to the mast. Spire, a mast rigger, stands at the start.

**3-3 Sweep Arms.** Two arms at ground height: walk under when the bar has passed. Next is a pillar in a pit with an arm over it, then block stairs with an arm between each step. At midway, a girder bridge runs under two arms turning opposite ways. The last stretch has an arm and a flyer together.

**3-4 The Spire.** It's three screens tall (51 rows). You climb from the foot of the mast to the top:
- up an updraft to a ledge, then girders past a flyer
- the midway beacon, then lift rings up to a platform with a sweep arm over it
- a flyer to bounce off, then a tailwind over to the top screen
- a final updraft and a sweep arm on the last platform before the mast

If you fall, you land on the ground at the foot and climb again, so falling never kills you.

## Story

Spire is the new villager. You meet them in 3-2, and after that they stand by the signpost in Last Relay. Spire says the call bounces off the top of the Spire, and that whoever is calling is below, not above. After World 3:
- Mast warns you about Dead Air.
- Wren hears the whole call: "SPARK. COME HOME. WE KEPT YOUR PLACE."

Clearing 3-4 sets `w3_clear`.

## Not done yet

- The Arc is now earned by clearing World 1 (see world-2.md). Each World 3 level has a stash behind a cracked wall.
- World 4 (Dead Air) is only a plan.
