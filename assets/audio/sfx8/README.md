# 8-bit sound set (sfx8)

93 sounds for the platformer rework: 53 for World 1, 10 for World 2, 6 for ambience, weather, lamps and menus, 14 for the Last Relay hub village, and 10 music loops for the levels (the last four groups are listed below). Every sound is made only from the four voices of the NES sound chip, so the set hangs together as one machine.

These files are not wired into the game yet. `scripts/sfx.gd` still plays its old beeps.

## The palette

| Voice | What it can do | What it is used for here |
|---|---|---|
| Pulse 1 | Square-style wave at 12.5, 25 or 50% width, 16 volume steps | Melody, jumps, pickups, most pitched effects |
| Pulse 2 | Same as pulse 1 | Harmony, and echoes (a delayed, quieter copy of pulse 1) |
| Triangle | Soft 32-step wave, no volume control, only on or off | Bass notes and the "thump" under impacts |
| Noise | Hiss from a 15-bit shift register, 16 pitches, long mode (hiss) or short mode (metallic buzz) | Impacts, cracks, rumbles, hi-hats, the dash whoosh |

Each voice plays one note at a time, as on the real chip. Volume, pitch and width change 240 times a second, and pitches are snapped to the exact values the NES could play. The mix is filtered the way a Famicom's output is (37 Hz and 14 kHz) so it sounds like the console rather than a raw computer square wave.

House rules, so new sounds fit in:

- Positive sounds are in D major and lean on D, A and the octave (shard, checkpoint bell, extra life, jingles).
- Losses fall towards D minor (death, charge lose, game over).
- Thin 12.5% pulses are for small, bright, quick things. 50% is for bold or musical things. 25% sits between.
- Heavy impacts are a falling triangle plus low noise (press, dropper, rubble, hard landing).

## Loudness

Every file is 44.1 kHz, 16-bit, mono WAV. It starts on its first sound and ends with a short fade, so there are no clicks.

Levels are matched by how loud each sound's loudest 50 ms is, aiming at -14.5 dBFS. No file goes above -3 dBFS peak. A few sounds that repeat a lot or should sit underneath (soft landing, menu move, warden steps, trap tells, the hopper, the relay boss's hum) are deliberately set 2 to 5 dB quieter. The three ambience loops are set 8 dB quieter, so they sit under the music. The six character voices repeat many times a second, so they sit a few dB under the menu sounds, and they're balanced by ear-weighted level to within about 2 dB of each other. `village_theme` is music for the Music bus, so it's set 3 dB louder than the effects. That puts it at about -14 dBFS overall, level with the World 1 music tracks. That setting is the `trim_db` value in the generator and the manifest.

The ten level music loops are matched to `village_theme` by overall level instead, since that's what a listener hears across a whole loop. Each one's `trim_db` (2.0 to 3.2) is set so it averages -14.2 to -14.5 dBFS. A few can't quite reach -14.2 without going over the -3 dBFS peak limit, so they stop at the limit, 0.3 dB short at most.

`manifest.json` lists every sound with its file, length, peak, overall RMS, loudest-50 ms RMS, trim and when it should play.

## Hearing them

Open `scenes/sfx8_board.tscn` in Godot and press F6 (Run Current Scene). Arrow keys pick a sound, Enter or Space plays it, Escape stops everything, and clicking a row plays it too. The board reads `manifest.json`, so a rebuilt set shows up by itself.

## Changing or rebuilding a sound

The sounds are written as code in `tools/audio/sfx8.py`, one short function per sound.

```
python tools/audio/sfx8.py              # rebuild every sound
python tools/audio/sfx8.py jump dash    # rebuild just these two
```

It needs Python 3 and numpy, and takes about two seconds. After a rebuild, Godot picks up the new files the next time the editor has focus.

The Godot import settings for these files are set to uncompressed so the sharp edges of the waves survive. Keep that if you add new files here (Import tab, Compress Mode: Disabled).

## Stomp chain

`stomp_1`, `stomp_2` and `stomp_3` step up in pitch. Play `stomp_3` for the third enemy and every one after it in the same air chain. `walker_squish` can play at the same time for the enemy's side of the hit.

## Traps that need timing

Some trap events come as separate pieces so the game can place them on its own clock:

- Loose floor: `loose_floor_shake` (0.35 s, matches the shake), then `loose_floor_crack`, `loose_floor_fall` while it drops, `loose_floor_land` when it hits.
- Loose ceiling: `loose_ceiling_crack`, `loose_ceiling_fall`, `loose_ceiling_land`.
- Press: `press_shake` (0.3 s, matches the warning), then `press_slam`.
- Dropper: `dropper_tell` when it lets go, `dropper_slam`, then `dropper_rise`. The rise is 1.25 s. If the real rise is longer, play it again.

## World 2 sounds

| Sound | Length | When it plays |
|---|---|---|
| `channel_switch` | 0.20 s | Player bumps a channel switch block and the solid and outline blocks swap. Two dry clacks, with no thump, so it can't be mistaken for `bump_block`. |
| `channel_arm` | 0.30 s | The relay boss is about to swap the channels by itself. Start it when the boss's 0.3 s visual warning starts, not when the swap happens. It ends as the swap lands. |
| `channel_swap` | 0.28 s | The boss's swap lands and the blocks change. Plays as `channel_arm` ends. |
| `spiky_knock` | 0.27 s | A spiked walker is knocked out from below or crushed by a trap. |
| `spiky_hurt` | 0.13 s | The Spark touches a spiked walker's spikes. This is only the sting. `death` or `charge_lose` still plays as usual. |
| `fuse_blow` | 0.46 s | Player bumps a fuse socket and blows the fuse. |
| `relay_hum` | 1.50 s | The relay boss's idle hum. **This one loops.** See below. |
| `relay_overload` | 1.46 s | All three fuses are blown. An alarm climbs for 1 s, then a crash. |
| `relay_down` | 0.96 s | The relay boss powers down and dies. Plays after `relay_overload`. |
| `hopper_land` | 0.10 s | A hopper lands. Goes with `hopper_hop`. |

## Ambience, weather, lamps and menus

| Sound | Length | When it plays |
|---|---|---|
| `amb_w1` | 8.00 s | World 1 ambience under the music. Distant wind over dead wires, with one soft signal blip (and its faint answer) per pass. **This one loops.** |
| `amb_w2` | 7.00 s | World 2 ambience under the music, for the relay yard. A low transformer hum, three far-off metal clanks per pass, and faint rain. **This one loops.** |
| `lamp_on` | 0.36 s | A signal lamp sputters on. Crackles, then a warm note that climbs as the lamp catches. |
| `thunder` | 1.20 s | Lightning. A bright crack, then a low rumble that rolls away. |
| `menu_back` | 0.12 s | Pause menu "back" or cancel. It goes with `menu_move` and `menu_confirm`: the same voice as `menu_confirm`, but falling instead of rising, an octave lower and shorter. |
| `save_done` | 0.32 s | The game has saved. Two clear chime notes, F sharp then D. |

## Last Relay (the hub village)

Character voices. The game plays one blip every two letters and nudges its pitch a little each time. Each blip is short with no tail, so they don't pile up. Every speaker differs in waveform, pitch range and the shape of the blip, so they can be told apart without looking. Keep the game's pitch nudge within about 2 semitones either way. Wider than that, Tally and Wren start to meet in the middle.

| Sound | Length | Who | What it sounds like |
|---|---|---|---|
| `voice_hum` | 0.055 s | Hum, relay technician | Lowest voice (A2). A 50% pulse fluttering a semitone every tick, so it buzzes like a coil. |
| `voice_mast` | 0.05 s | Mast, old keeper | The triangle alone (F sharp 3), round and soft, sagging a tone like "mm". |
| `voice_brace` | 0.05 s | Brace, lineworker | Mid voice (D4). A 25% pulse that drops a third, with a little low hiss under it for grit. |
| `voice_dot` | 0.04 s | Dot, switch operator | A metallic relay click, then a clipped 50% pip (D5) that stops dead. |
| `voice_tally` | 0.04 s | Tally, trader | A thin 12.5% pulse (A5), hard attack, flat and quick. |
| `voice_wren` | 0.05 s | Wren, kid with headphones | Highest voice. A 25% chirp flicking up a fifth (E6 to B6), with a faint tinny octave above it. |

Other village sounds:

| Sound | Length | When it plays |
|---|---|---|
| `talk_open` | 0.12 s | A speech bubble opens. Two soft ticks, A then D. |
| `talk_next` | 0.035 s | The player moves to the next line. One tiny tick, the second note of `talk_open`. |
| `door_open` | 0.44 s | A small house door opens. The latch clicks, then a dry hinge creaks. |
| `door_close` | 0.14 s | The door shuts. A dull knock, then the latch drops into place. |
| `shop_buy` | 0.43 s | A purchase. The till ticks, then a quick climb up the D major chord to a ringing top note. |
| `shop_deny` | 0.27 s | Not enough shards. Two low buzzes, the second a semitone lower. |
| `amb_village` | 8.00 s | Village ambience under the music. Soft wind, a distant wind chime in two little clusters, and a far-off radio murmuring. **This one loops.** |
| `village_theme` | 38.40 s | The village music, for the Music bus. Calm and warm, in D major at 100 BPM, 16 bars. Lead melody on pulse 1, broken chords on pulse 2, bass on the triangle, soft drums on the noise. **This one loops.** |

The theme is written as note text in the generator (`VILLAGE_MELODY`, `VILLAGE_CHORDS`). `F#5:1.5` is a note and its length in beats, `-:1` is a rest, and `|` marks a bar. The generator stops with an error if a bar doesn't add up to 4 beats, so the loop can't drift out of time.

## Level music

One loop per level, for the Music bus. They're meant to replace the OGG tracks in `assets/audio/music/` (World 2 currently borrows World 1's), but the game doesn't play them yet. Every one uses all four voices and loops by itself.

| Sound | Level | Length | Tempo and key | What it sounds like |
|---|---|---|---|---|
| `m_training` | Training yard | 32.00 s | 120 BPM, C major, 16 bars | Light and bouncy. A 25% lead over off-beat chords, with pulse 2 answering the tune in the gaps. |
| `m_1_1` | 1-1 FIRST LIGHT | 38.40 s | 150 BPM, G major, 24 bars | The main theme. Hopeful and driving, with a pumping octave bass. The middle eight is syncopated and moves to a rounder 50% lead. |
| `m_1_1_bonus` | 1-1 bonus room | 21.33 s | 180 BPM, E major, 16 bars | Short and playful, with sixteenth-note sparkles high on pulse 2. |
| `m_1_2` | 1-2 LOOSE GROUND | 40.00 s | 144 BPM, E minor, 24 bars | Nervous. Bass and drums group the beat 3+3+2 so it never sits still, pulse 2 skitters, and a flat-second chord makes it wobble. The middle drops away with crumbling noise. |
| `m_1_3` | 1-3 THE PRESSES | 42.67 s | 112.5 BPM, C minor, 20 bars | Machinery. A heavy thud on every beat to move to, metal clanks and steam stabs off the beat, and the odd pop of static. |
| `m_1_4` | 1-4 THE GATE | 35.20 s | 163.6 BPM, D minor, 24 bars | The World 1 finale. Tense at first, then a galloping bass and brass-like chords, and the main theme's opening turns into a major-key call to arms. |
| `m_2_1` | 2-1 RAIL HOPPERS | 36.00 s | 133.3 BPM, A minor, 20 bars | Bouncy minor with hopping bass, faint rain, and lightning crashes at bars 9 and 17. |
| `m_2_2` | 2-2 SPIKED LINE | 42.67 s | 90 BPM, B minor, 16 bars | Cautious and low. The triangle creeps through the World 2 motif at half speed, a heartbeat thuds, the lead has a faint echo, and it rains. |
| `m_2_3` | 2-3 CHANNELS | 38.67 s | 124.1 BPM, G minor, 20 bars | The two pulses call and answer. At bar 9 the world flips: the thin voice becomes the bold one. At bar 15 they flip back and play the motif together. A burst of static marks each flip. |
| `m_2_4` | 2-4 THE RELAY | 38.40 s | 200 BPM, F minor, 32 bars | The World 2 boss. Fast and relentless, with driving octaves, sixteenth-note arpeggios and lightning every eight bars. |

The tracks share tunes so each world sounds like one piece:

- World 1 quotes the opening of FIRST LIGHT: the notes D G G A B G in `m_1_1`, in the rhythm short, short, short, short, long, long. It opens `m_training`. It appears at bars 5 and 6 of `m_1_1_bonus`, bars 5 and 17 of `m_1_3`, and bars 17 and 18 of `m_1_4` (there in a major key). In `m_1_2` it comes in half a beat late.
- World 2 shares one motif: step up a semitone, back down, leap up to the octave, then fall back (E F E A G E in A minor), in the rhythm short, short, short, long, short, long. It's in every World 2 track and opens `m_2_1`, `m_2_3` and `m_2_4`.

The tempos are all 3600 divided by a whole number, which is why some look odd (112.5, 124.1, 133.3, 163.6). That keeps every note on the generator's 240-a-second clock, so every pass of a loop is identical.

The loops are written the same way as `village_theme`, as note text in the generator. Chord parts use a small shorthand that follows the chords (`R` root, `3` third, `5` fifth, `8` octave), and drums are one letter per sixteenth note (see `KIT` in the generator).

## Looping sounds

`relay_hum`, `amb_w1`, `amb_w2`, `amb_village`, `village_theme` and the ten level music loops are built to loop with no click where the end meets the start. Each file carries its own loop point, and Godot's import setting here (Loop Mode: Detect From WAV) reads it, so it loops on its own once imported. This was checked in Godot 4.7.2 for the first three: each one loads as a forward loop over the whole file. The village loops and the level music use the same loop point as those, but haven't been opened in Godot yet. The manifest marks every loop except `relay_hum` with `"loop": true` (`relay_hum` was built before that flag existed).

If one ever plays only once, set Loop Mode to Forward on the file's Import tab and set Loop End to the file's length in samples, listed below. Leaving Loop End at -1 makes Godot stop one sample short of the end.

| Sound | Length in samples |
|---|---|
| `relay_hum` | 66090 |
| `amb_w1` | 352851 |
| `amb_w2` | 308725 |
| `amb_village` | 352800 |
| `village_theme` | 1693440 |
| `m_training` | 1411200 |
| `m_1_1` | 1693440 |
| `m_1_1_bonus` | 940800 |
| `m_1_2` | 1764000 |
| `m_1_3` | 1881600 |
| `m_1_4` | 1552320 |
| `m_2_1` | 1587600 |
| `m_2_2` | 1881600 |
| `m_2_3` | 1705200 |
| `m_2_4` | 1693440 |

In the generator, a looping sound is marked `loop=True`. It's rendered with one extra pass as a run-in, and the part after the loop point is blended into the start over 80 ms. Every note and volume pattern in it repeats a whole number of times per pass. `amb_w1` is mostly wind noise at its seam, so it uses `power_seam=True`, a blend that keeps the noise at an even level. A plain blend of two different stretches of noise dips in the middle.

The two village loops and the level music also use `lock=True`. Without it, the notes repeat every pass but each voice's wave doesn't: a pass ends part-way through a cycle, so the next pass starts at a different point in the wave. The 80 ms blend then mixes two copies that are out of step, and the sound thins for a moment. That's easy to hear in tuned music. `lock=True` nudges each pulse and the triangle by a tiny fraction of a cent (under 0.2 cent in every loop so far, far too small to hear) so they finish every pass on a whole cycle. It also restarts the noise at every pass. Every pass then comes out the same, sample for sample, and the blend at the seam joins two identical pieces of audio. Use it for any new music loop.
