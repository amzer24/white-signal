# World 2 level design: The Switchyard

Status: built, proven and in the game as of 25 Sep 2026. Every level can be finished, and every shard and block has been reached in simulation (`levels/world2/<level>.proof.json`). World 2 follows the rules in `world-1.md`. This page covers only what's new.

## The idea

A dead relay yard where the broadcast line splits into two channels. World 2 introduces three things, one per level, and ends with a boss:
- **Hopper** (`k`): a walker that jumps on a steady beat. You can stomp it, or run under it while it's in the air.
- **Spiked walker** (`s`): spikes on top, so you can't stomp or dash it. You kill it by bumping the block it stands on, or by dropping something heavy on it, such as a loose floor, a press, a dropper or a ceiling chunk.
- **Channel switch** (`Y`) with channel blocks `1` and `2`. Only one channel is solid at a time. Bumping a switch swaps them, and the other channel shows as a dim outline.
- **The relay** (`E`, 3x3) is the World 2 boss. It swaps the channels by itself every 2.5 seconds, with a 0.3 second shake and warning sound first. Bumping all three fuses (`Q`) blows it, which freezes the channels and opens its gate (`gate#1 relay=1`).

## New rules that apply everywhere

- **Knock-outs:** any bump block (`? C U h B Y Q`) knocks out an enemy standing on it when you hit it from below, as in Mario.
- **Crushing:** presses, falling droppers, ceiling chunks and falling loose floors now kill any enemy they land on.
- **No getting stuck inside a block:** when a channel turns solid while the Spark is inside one of its blocks, that block stays open until the Spark leaves it.
- **Walkers ignore channel blocks.** Keep patrols on ground that never changes.
- **The Arc** (the attack, key X) is the reward for clearing World 1. 2-1 teaches it with a shed sealed by a cracked wall (`%`), and every World 2 and 3 level hides a stash behind one. It also knocks out spiked walkers from the side.

## Taller levels

World 2 levels are two screens tall (34 rows), with ground at row 31. Any multiple of 17 rows works. The camera settles on the height you're standing at, and only follows a jump when you leave the middle of the screen. One-screen levels never scroll up or down.

## The four levels

**2-1 Rail Hoppers:** hoppers, and height.
- A: a hopper in a pen.
- B: a girder ladder, with a hopper on one rung, up to a tower roof.
- C: across tower tops of different heights. If you fall, you land on the ground level below and climb a ladder back up.
- D: the midway beacon on the roof, and three hoppers to chain-stomp for a big shard. Before the roof there's a girder shaft. Hold Down and jump to drop to its floor, where a hidden block (tile `i`) gives 5 shards. Then climb back up the girders. Added 26 Sep 2026.
- E: drop to the ground, then knock a hopper off its blocks.
- F: the staircase and the mast.

**2-2 Spiked Line:** spiked walkers, from the roof down.
- A: a spiked walker on bump blocks. Bump it from below.
- B: two on the roof. Jump over them.
- C: the roof is loose floor. It falls under you and the pieces crush the spiked walkers on the floor below.
- D: the midway beacon, a CHARGE, and a raised row of bump blocks with a spiked walker on it, guarding a big shard.
- E: climb steps of bump blocks, knocking each spiked walker off from the step below.
- F: the mast on a roof.

**2-3 Channels:** the switch, used four ways.
- A: it opens a wall.
- B: cross the bridge, then swap it away to open the wall ahead.
- C: it raises a staircase up a tower.
- D: the midway beacon, and hoppers under a channel platform.
- E: three swaps in mid-air, high above a deadly drop.
- F: down to the mast.

**2-4 The Relay:** the boss level.
- A: learn the beat over a safe trench.
- B: climb platforms that appear and vanish on the beat.
- C: the midway beacon, spiked walkers and presses.
- D: platforms on the beat over a drop, with three fuses above them.
- E: the gate opens when the relay goes down, and the mast is behind it.


More hidden shard blocks (26 Sep 2026): 2-2 (62,17) and (145,16); 2-3 (7,27) behind the start and (150,12); 2-4 (22,27) and (50,15). All are proven hittable.

## Assets

- **Art** (in the shared pipeline, `assets/world1/`): `channel_block`, `channel_switch`, `spiky`, `fuse`, `relay`, `ground_w2`, `block_w2` and `backdrop_w2`.
- **Sounds** (`assets/audio/sfx8/`): `channel_switch`, `channel_arm`, `channel_swap`, `spiky_knock`, `spiky_hurt`, `fuse_blow`, `relay_hum`, `relay_overload`, `relay_down` and `hopper_land`.
- **Music:** World 2 borrows the World 1 tracks until it has its own.

## Atmosphere (both worlds, added 25 Sep 2026)

This is all look and sound, so the proofs ignore it.
- **Colour per world:** the art is still drawn in four greys, and a screen pass (`shaders/world1/world_fx.gdshader`) maps them onto each world's four colours. World 1 is cold blue-grey and World 2 is sodium amber. The test room stays grey.
- **Dark stretches:** a level header line `dark: 60-89` makes those columns dark except near a light. Lights are the Spark, lit lamps, live fuses, the relay and big shards. Lamps (`J`) light up when you pass them and stay lit. They're used in 1-4 (the shaft and the dropper hall), 2-2 (the building) and 2-4 (the relay hall).
- **Weather:** `weather: rain` or `weather: static` sets the weather, and `lightning: yes` adds lightning. Lightning follows the reduced-flashes setting, which is on by default.
- **Fog** drifts along the bottom of tall levels.
- **Ambience:** each world has its own background loop (`amb_w1` and `amb_w2`).

## Pause menu and saving

- **Pause** with Esc, P or Start. The menu has Resume, Restart Level, Level Select, Settings and Save and Quit.
  - Settings covers music and effects volume, the screen filter, screen shake, flashes and fullscreen.
  - Level Select lists the levels you've reached, with the big shards found in each.
  - The number keys 0 to 8 still jump to any level, for testing.
- **Saving:** the game saves automatically at the start of every level, and Save and Quit saves too. The title screen's PLAY opens Continue or New Game. A new game keeps big shards and best times.
- Progress lives in `user://w1_progress.json`. Captures and tests use their own file.

## Not done yet

- There is no bonus room in World 2.
