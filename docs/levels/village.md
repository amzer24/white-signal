# Last Relay: the village

Last Relay is the hub. A new game starts here, and you come back here after each world and after a game over. It's the last station on the line that still works. The people who kept it running are small radio folk called listeners.

There's no clock, no enemies and no way to lose a life in the village.

## What you can do

Press Down to use whatever you're standing next to. A small arrow appears over the Spark when something can be used.

- **Talk.** A speech bubble types out the line, and each person has their own voice blips. Jump or Down shows the whole line, then moves to the next one.
- **Doors.** Down at a door goes inside. The shop and the radio shack are open. The other houses are locked, and Old Mast's house has a short description.
- **Switchboard.** In the square. It lists every level you've reached, plus the training yard.
- **The signpost.** At the east end. It starts the first level you haven't cleared.

The pause menu in any level has RETURN TO LAST RELAY.

## Tally's shop

Prices are in shards.

| Item | Price | What it does |
|---|---|---|
| Extra life | 40 | One more life |
| Charged start | 25 | The next level starts with CHARGE on |
| Shard compass | 80 | Kept for good. A blinking diamond at the screen edge points to the nearest big shard you haven't found. |
| Lantern | 60 | Kept for good. Your light reaches much further in dark stretches. |

## The people and the story

The call comes from past the gates. Each listener you meet out on the line goes home to the radio shack, and what they say changes as you clear worlds.

| Who | Where you meet them | What they add |
|---|---|---|
| Old Mast | The village | Sets the goal: follow the line and bring back what you hear |
| Tally | The shop | The trader |
| Wren | 1-2 | The call isn't static, it's words. After World 2 she hears it: "SPARK. COME HOME." |
| Brace | 1-4 | Why the old crews cut the lines: to stop the noise spreading |
| Dot | 2-3 | Explains the channel switches, then runs the switchboard |
| Hum | 2-4 | Asks you to blow the relay's three fuses so it can rest |

All the lines are in `levels/story/npcs.json`. Each person has a `show` rule for each level they appear in and a list of `talk` entries. The game uses the first entry whose `when` rule holds. The rules use flags: `met_<id>` is set by talking to someone, and `w1_clear` and `w2_clear` are set by clearing a world. Flags, shop items and the charged start are saved in the progress file.

## Level files

The village files are in `levels/village/`: `village.txt`, `village-shop.txt` and `village-radio.txt`. They use the tiles N (a person), H (a door), V (the switchboard), and b, c, n and g for props. Doors take `door#k to=<level> house=<front> c= r=`. Here `house` picks the house front, `c`/`r` is where you come out, and `to=next` is the signpost. The village levels have `hub: yes` and aren't proven by the level checker. Story people also stand in 1-2, 1-4, 2-3 and 2-4, but they don't block anything, so those proofs are unchanged.

## Tests

- `scripts/world1/w1_village_test.gd` plays the village with real key presses.
- `scripts/world1/w1_village_capture.gd` writes screenshots to `test-user/w1-village/`.
