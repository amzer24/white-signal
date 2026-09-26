# 8-bit sound set (sfx8)

132 sounds for the platformer rework: 53 for World 1, 10 for World 2, 5 for World 3, 7 for ambience, weather, lamps and menus, 15 for the Last Relay hub village, 14 music loops for the levels, 10 for the title screen and its menus, 5 for the Arc, and 13 for the story intro (the last eight groups are listed below). Every sound is made only from the four voices of the NES sound chip, so the set hangs together as one machine.

The game, the title screen and the story intro all play these files.

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

Levels are matched by how loud each sound's loudest 50 ms is, aiming at -14.5 dBFS. No file goes above -3 dBFS peak. A few sounds that repeat a lot or should sit underneath (soft landing, warden steps, trap tells, the hopper, the flyer's flap, the relay boss's hum) are deliberately set 2 to 5 dB quieter, the sweep arm's whir 7 dB quieter, the menu cursor blips (`menu_move` and `menu_move_1` to `menu_move_5`) 8 dB quieter, and the intro's static crawl 3 dB quieter. The ambience loops are set 8 dB quieter, so they sit under the music. The seven character voices repeat many times a second, so they sit a few dB under the menu sounds, and they're balanced by ear-weighted level to within about 2 dB of each other. `village_theme` is music for the Music bus, so it's set 3 dB louder than the effects. That puts it at about -14 dBFS overall, level with the World 1 music tracks. That setting is the `trim_db` value in the generator and the manifest.

The fourteen level music loops, `title_theme` and the four story intro loops are matched to `village_theme` by overall level instead, since that's what a listener hears across a whole loop. Each one's `trim_db` (2.0 to 4.0) is set so it averages -14.2 to -14.5 dBFS. A few can't quite reach -14.2 without going over the -3 dBFS peak limit, so they stop at the limit, 0.3 dB short at most.

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

The Godot import settings for these files are set to uncompressed so the sharp edges of the waves survive. Keep that if you add new files here (Import tab, Compress Mode: Disabled). Godot imports a new file compressed the first time, so check it after adding one.

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

## World 3 sounds

| Sound | Length | When it plays |
|---|---|---|
| `flyer_flap` | 0.09 s | A flyer flaps. Play it now and then while one is on screen, not on every wingbeat. A soft puff of air with a small rising blip inside it. |
| `gust_tell` | 0.52 s | The warning that a gust is coming. Hiss that climbs and swells, with a thin whistle rising under it. Start it 0.5 s before the gust, so it ends as `gust` starts. |
| `gust` | 0.61 s | The gust itself. A whoosh that peaks early and falls away, with a faint falling whistle. |
| `arm_whir` | 1.00 s | A sweep arm is on screen. A faint electric whine that swings up and down four times a second over a metallic crackle. It doesn't need to match the arm's real speed. **This one loops.** |
| `updraft` | 0.41 s | The player enters an updraft. Hiss rising from mid to bright, with a soft whistle gliding up an octave and a fifth. |

## Ambience, weather, lamps and menus

| Sound | Length | When it plays |
|---|---|---|
| `amb_w1` | 8.00 s | World 1 ambience under the music. Distant wind over dead wires, with one soft signal blip (and its faint answer) per pass. **This one loops.** |
| `amb_w2` | 7.00 s | World 2 ambience under the music, for the relay yard. A low transformer hum, three far-off metal clanks per pass, and faint rain. **This one loops.** |
| `amb_w3` | 8.00 s | World 3 ambience under the music, for the Aerials. Bright high wind in three gusts per pass, two guy wires humming a hair apart so they beat about once a second and sing louder in the gusts, and one distant clank with its echo. **This one loops.** |
| `lamp_on` | 0.36 s | A signal lamp sputters on. Crackles, then a warm note that climbs as the lamp catches. |
| `thunder` | 1.20 s | Lightning. A bright crack, then a low rumble that rolls away. |
| `menu_back` | 0.12 s | Pause menu "back" or cancel. It goes with `menu_move` and `menu_confirm`: the same voice as `menu_confirm`, but falling instead of rising, an octave lower and shorter. |
| `save_done` | 0.32 s | The game has saved. Two clear chime notes, F sharp then D. |

## Last Relay (the hub village)

Character voices. The game plays one blip every two letters and nudges its pitch a little each time. Each blip is short with no tail, so they don't pile up. Every speaker differs in waveform, pitch range and the shape of the blip, so they can be told apart without looking. Keep the game's pitch nudge within about 2 semitones either way. Wider than that, Tally and Wren start to meet in the middle.

Spire and Mast are both the triangle, but Spire is more than an octave higher and jumps up where Mast sags. Spire was checked against the other six by comparing how each one's sound is spread across the frequency range, with every voice free to move 2 semitones. It's further from each of them than Tally and Wren, the closest pair, are from each other.

| Sound | Length | Who | What it sounds like |
|---|---|---|---|
| `voice_hum` | 0.055 s | Hum, relay technician | Lowest voice (A2). A 50% pulse fluttering a semitone every tick, so it buzzes like a coil. |
| `voice_mast` | 0.05 s | Mast, old keeper | The triangle alone (F sharp 3), round and soft, sagging a tone like "mm". |
| `voice_brace` | 0.05 s | Brace, lineworker | Mid voice (D4). A 25% pulse that drops a third, with a little low hiss under it for grit. |
| `voice_spire` | 0.045 s | Spire, mast rigger | A whistle on the triangle, G4 jumping cleanly up a fourth to C5, like a brisk "hup". |
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
| `village_theme` | 38.40 s | The village music, for the Music bus. Calm and warm, in D major at 100 BPM, 16 bars. A lullaby hook that leans over the beat, and FIRST LIGHT's hook in the middle. Lead melody on pulse 1, broken chords on pulse 2, bass on the triangle, soft drums on the noise. **This one loops.** |

The theme is written as note text in the generator (`VILLAGE_MELODY`, `VILLAGE_CHORDS`). `F#5:1.5` is a note and its length in beats, `-:1` is a rest, and `|` marks a bar. The generator stops with an error if a bar doesn't add up to 4 beats, so the loop can't drift out of time.

## Level music

One loop per level, for the Music bus. The game plays these, and falls back to the OGG tracks in `assets/audio/music/` only if a loop is missing. Every one uses all four voices and loops by itself.

Every loop is written to be catchy by the rules in `docs/research/music-2026-09-26.md`: a hook in the first bar that comes back at least three times a pass, repeats and answers, notes that lean over the beat, mostly steps, and a lead no wider than an octave and a fifth and no higher than E6. `python tools/audio/music_check.py` measures every loop against those rules.

World 1 shares FIRST LIGHT's hook (scale steps 5 1 1 2 3 1 in the rhythm short LONG short short LONG short). World 2 shares the Switchyard motif (5 b6 5 8 b7 5). World 3 shares the Aerials motif (1 5 9 8 10, two fifths up, a step down, a third up). The level clear, extra life and game over jingles are built from FIRST LIGHT's hook too: fast and bright for the first two, slow and in minor for game over.

| Sound | Level | Length | Tempo and key | What it sounds like |
|---|---|---|---|---|
| `m_training` | Training yard | 32.00 s | 120 BPM, C major, 16 bars | Light and bouncy. A 25% lead over off-beat chords, with pulse 2 answering the tune in the gaps. |
| `m_1_1` | 1-1 FIRST LIGHT | 38.40 s | 150 BPM, G major, 24 bars | The main theme. Hopeful and driving, with a pumping octave bass. The hook plays four times a pass. The middle is a slower falling line on a rounder 50% lead. |
| `m_1_1_bonus` | 1-1 bonus room | 21.33 s | 180 BPM, E major, 16 bars | Short and playful. A hook that climbs to the fifth, repeated sparkle notes in the middle, and sixteenth-note sparkles high on pulse 2. |
| `m_1_2` | 1-2 LOOSE GROUND | 40.00 s | 144 BPM, E minor, 24 bars | Nervous. FIRST LIGHT's notes knocked loose into 3+3+2. Bass and drums group the beat the same way so it never sits still, pulse 2 skitters, and a flat-second chord makes it wobble. The middle drops away to short cries over crumbling noise. |
| `m_1_3` | 1-3 THE PRESSES | 42.67 s | 112.5 BPM, C minor, 20 bars | Machinery. A stamping repeated-note hook with a bar of silence after it, a heavy thud on every beat to move to, metal clanks and steam stabs off the beat, and the odd pop of static. FIRST LIGHT closes the loop in minor. |
| `m_1_4` | 1-4 THE GATE | 35.20 s | 163.6 BPM, D minor, 24 bars | The World 1 finale. FIRST LIGHT's hook in minor, then a march with a galloping bass and brass-like chords, then the hook climbs in major to a call to arms. |
| `m_2_1` | 2-1 RAIL HOPPERS | 36.00 s | 133.3 BPM, A minor, 20 bars | Bouncy minor. The Switchyard motif on each chord, answered by a hop down and a rest. Hopping bass, faint rain, and lightning crashes at bars 9 and 17. |
| `m_2_2` | 2-2 SPIKED LINE | 42.67 s | 90 BPM, B minor, 16 bars | Cautious and low. The triangle creeps through the World 2 motif at half speed while the lead tiptoes in off the beat, a heartbeat thuds, the lead has a faint echo, and it rains. |
| `m_2_3` | 2-3 CHANNELS | 38.67 s | 124.1 BPM, G minor, 20 bars | The two pulses call and answer: every call is the motif, every answer turns it upside down. At bar 9 the world flips: the thin voice becomes the bold one. At bar 15 they flip back and play the motif together. A burst of static marks each flip. |
| `m_2_4` | 2-4 THE RELAY | 38.40 s | 200 BPM, F minor, 32 bars | The World 2 boss. Fast and relentless. The motif comes back in every section, answered in FIRST LIGHT's rhythm, over driving octaves, sixteenth-note arpeggios and lightning every eight bars. It ends on an alarm of repeated top notes. |
| `m_3_1` | 3-1 WAVE FLYERS | 44.80 s | 12/8 at 85.7 beats a minute (each beat split in three), F major, 16 bars | Buoyant and lilting. The motif flies up and glides back down by step. The bass bobs, pulse 2 rocks up and down in broken fifths, and a soft breeze fills the gaps between the drums. |
| `m_3_2` | 3-2 CARRIER WIND | 41.60 s | 138.5 BPM, A major, 24 bars | Sweeping. Pulse 2 races up and down in sixteenths like gusts, and every fourth bar it holds at the top while a swell of wind peaks. A bright B major chord gives it lift. |
| `m_3_3` | 3-3 SWEEP ARMS | 44.80 s | 128.6 BPM, F sharp minor, 24 bars | Clockwork. Pulse 2 turns a 12-note pattern against the 16 steps of a bar, so it comes round a quarter-bar later each time, like an arm sweeping. Tick-tock drums, a crisp short-note lead, and a burst of static at the start of each section. |
| `m_3_4` | 3-4 THE SPIRE | 49.07 s | 156.5 BPM, C major lifting to D major, 32 bars | The World 3 finale. It starts thin over wind and adds more every 8 bars. At bar 17 the whole opening comes back a step higher, and the last section plays the motif at double length at the top. The final chord leads straight back to the start. |

The tracks share tunes so each world sounds like one piece:

- World 1 quotes the opening of FIRST LIGHT: the notes D G G A B G in `m_1_1`, in the rhythm short, short, short, short, long, long. It opens `m_training`. It appears at bars 5 and 6 of `m_1_1_bonus`, bars 5 and 17 of `m_1_3`, and bars 17 and 18 of `m_1_4` (there in a major key). In `m_1_2` it comes in half a beat late. `title_theme` plays it at half speed and moved into D (A D D E F# D) at bars 1 and 5.
- World 2 shares one motif: step up a semitone, back down, leap up to the octave, then fall back (E F E A G E in A minor), in the rhythm short, short, short, long, short, long. It's in every World 2 track and opens `m_2_1`, `m_2_3` and `m_2_4`.
- World 3 shares one motif built on open fifths: climb two fifths, step down to the octave, then leap up another fifth (F C G F C in `m_3_1`, which is in F major). The rhythm is short, short, long, short, long, turned into a long-short lilt in the 12/8 of `m_3_1`. It opens all four World 3 tracks and comes back on other chords inside them. In `m_3_4` it starts at the bottom of the lead's range and each return starts higher, until bars 25 and 26 play it at double length.

The tempos are all 3600 divided by a whole number, which is why some look odd (112.5, 124.1, 128.6, 133.3, 138.5, 156.5, 163.6). That keeps every note on the generator's 240-a-second clock, so every pass of a loop is identical.

The loops are written the same way as `village_theme`, as note text in the generator. Chord parts use a small shorthand that follows the chords (`R` root, `3` third, `5` fifth, `8` octave, and `2`, `4` and `9` for World 3's open chords), and drums are one letter per sixteenth note (see `KIT` in the generator).

Note lengths can also be fractions, so `C5:1/3` is a third of a beat. `m_3_1` uses that for its 12/8 feel: each beat is split in three, and its drum lines have 12 steps a bar instead of 16. Every one of those notes still starts exactly on the generator's clock.

## Title screen and menus

| Sound | Length | When it plays |
|---|---|---|
| `title_intro` | 5.73 s | The title music's 2-bar opening, with the logo. The line crackles awake and the 12.5% arpeggio starts alone, then the bass joins. Plays once, then `title_theme` straight after (see "Loops with an intro" below). |
| `title_theme` | 40.13 s | The title music, for the Music bus, and it keeps playing through Settings and Extras. D major, 83.7 BPM, 14 bars. Calm and hopeful, a little lonely. A thin 12.5% arpeggio, the triangle walking underneath, and a sparse lead that plays FIRST LIGHT's hook at half speed, twice in D and once in B minor. Twice a pass a faint two-note call goes out into the rests, the blip from `amb_w1`, and nothing answers it. **This one loops.** |
| `menu_move_1` to `menu_move_5` | 0.05 s | The title menu cursor lands on row 1 to 5. The same blip as `menu_move` on D, E, F sharp, A and B, so row 1 is lowest. Row 4 is `menu_move`'s own note. |
| `menu_deny` | 0.15 s | A menu choice isn't available. `shop_deny` at half the length: two low buzzes, the second a semitone lower. |
| `menu_tick` | 0.03 s | A settings slider moves a step. A tiny click and pip. Raise its pitch with the value, and play it at most once every 60 ms. |
| `title_start` | 0.80 s | New game or continue is chosen and the Spark leaves. Up D, F sharp and A to a bright held D, with a rising whoosh underneath as the Spark zips off. Plays over the 400 ms music fade. |

`menu_move` itself is unchanged apart from being 3 dB quieter, since the game uses it elsewhere. There's no separate title ambience. `amb_w1` already has the soft wind and the faint singing wire the title needs, so use that.

## The Arc

The Spark throws a short arc of static forward. It kills enemies, spiked walkers from the side included, and breaks cracked walls.

| Sound | Length | When it plays |
|---|---|---|
| `arc_swing` | 0.12 s | Every throw, hit or miss. A snap of metallic crackle over a quick falling zap. It plays a lot, so it's kept light and set 2 dB under the other effects. |
| `arc_hit` | 0.15 s | The arc hits an enemy. Play it with `arc_swing`. A bright crackle, a hard crack of hiss and a thump under a falling zap. |
| `wall_crack` | 0.15 s | A cracked wall is hit but doesn't break yet, for walls that take more than one hit. A dry stone crack with a small second split. |
| `wall_break` | 0.43 s | A cracked wall shatters. Like `brick_break` but stone: a lower, longer crumble that tumbles in lumps, a triangle that drops twice, and a low thud instead of the bright ping. |
| `arc_learn` | 1.79 s | The player learns the Arc. A crackle of static, then up the D major chord, up the A chord, and a ringing high D. In the family of `extra_life` and `big_shard`. |

## Story intro

Thirteen sounds for the new-game story intro, following the sound request in `docs/story/intro-shots.md`. The music runs at 80 BPM (3600 divided by 45), so one bar is exactly 3.0 s and each 6-second card is two bars. None of the shot list's timings had to change.

| Sound | Length | When it plays |
|---|---|---|
| `intro_line` | 12.00 s | Cards 1 and 2. D major, 4 bars, warm and a little old, like a music box. The 12.5% arpeggio rolls alone, pulse 1 sings the FIRST LIGHT motif high, pulse 2 passes it on an octave down and a beat late (after `amb_w1`'s two-note blip), and the triangle answers with its first three notes. **This one loops.** |
| `intro_noise` | 12.00 s | Cards 3 and 4. D minor, 4 bars, uneasy. The motif in minor, then static crackles in and pulse 2 sags a quarter-tone flat, then the motif skips on its first two notes while the whole line drops out, then a triangle pedal on A under swelling hiss. **This one loops.** |
| `intro_still` | 6.00 s | Card 6. D minor, 2 bars, tender and small. A slow heartbeat on the triangle, a very quiet high A on a 12.5% pulse, and pulse 2 holding F, then E. It fades out as card 7 starts. **This one loops.** |
| `intro_wake` | 3.20 s | Card 8, the flare. A 0.2 s crackle, then a D major downbeat, a quick run up to a held high D, and a last beat that leads into `intro_home`. Plays once, then `intro_home` straight after. |
| `intro_home` | 18.00 s | Cards 8 (second half), 9 and 10. D major, 6 bars, relief and company. The motif at half speed as `title_theme` plays it, then bars 3 and 4 of `village_theme` with its broken chords and walking bass, then `title_theme`'s call, answered for the first time two beats later, and an end on A. **This one loops.** |
| `line_pulse` | 0.45 s | Card 2. A voice passing down the wire: a 12.5% pulse gliding up from D5 to A5, with a quiet echo. The second pulse plays it 2 semitones up. |
| `static_crawl` | 1.00 s | Cards 3 and 4, while the noise crawls along the wire. A metallic buzz jumping pitch 30 times a second over an irregular tick. Pan it with the static. **This one loops.** |
| `lamp_off` | 0.28 s | Cards 3 and 4, as each lamp dies. `lamp_on` turned round: a warm note falling a fifth, then two small crackles. Play it at -10 dB and 0.8 pitch for distant lights. |
| `wire_snap` | 0.63 s | Card 4, as the line is cut. A heavy clack, an arc crackle, a fast falling whip, then the cut wire ringing down. |
| `static_die` | 0.50 s | Card 4, as the noise fizzles out at the gap. Crackle that thins and slows to single ticks. |
| `line_ring` | 0.89 s | Card 7, once per ring. An old phone bell heard down a long dead wire: two 50% pulses trilling 20 times a second between A5 and D6, a soft thump, then a fading tail. Three in a row are easy to count. |
| `spark_flare` | 0.60 s | Card 8, on `intro_wake`'s downbeat. Crackle swelling into a bright blip that rises from D6 to D7, an octave above the music's held note. |
| `caller_blip` | 0.34 s | Cards 8 and 10, as the far light blinks. The two-note call from `title_theme` and `amb_w1` (A5 then D6), with a softer copy replying. |

The four music loops sit at -14.3 dBFS overall, like the level music. `intro_still` is so sparse that it stops at the -3 dBFS peak limit, at -14.5 dBFS.

Card 4 cuts `intro_noise` dead when the line is cut, 7.25 s into the cue. Every voice drops out from 7.125 s to 7.5 s (the line skipping), so if no card was skipped the cut lands in silence and can't click. If the player skipped ahead in card 3, the cut lands somewhere else in the cue, so keep the shot list's 20 ms fade.

`intro_wake` and `intro_home` work like `title_intro` and `title_theme` (see "Loops with an intro"). The last beat of `intro_wake` is the same as the last beat of `intro_home`, so the join sounds exactly like the loop's own seam.

The last bar of `intro_home` is the last bar of `village_theme`: an A chord with the bass walking up A, E, A, C sharp. So when `village_theme` starts at the hand-off, its first D chord resolves it. The call in `intro_home` goes out on the first beat of bar 5 and the answer comes on its third beat, as the chord turns to A. If nobody skips, that is 3.2 s and 4.7 s into card 10.

## Looping sounds

`relay_hum`, `arm_whir`, `static_crawl`, the four ambience loops (`amb_w1`, `amb_w2`, `amb_w3`, `amb_village`), `village_theme`, the fourteen level music loops, `title_theme` and the four story intro loops (`intro_line`, `intro_noise`, `intro_still`, `intro_home`) are built to loop with no click where the end meets the start. Each file carries its own loop point, and Godot's import setting here (Loop Mode: Detect From WAV) reads it, so it loops on its own once imported. This was checked in Godot 4.7.2 for the first three: each one loads as a forward loop over the whole file. The village loops, the level music, `arm_whir` and `amb_w3` use the same loop point as those, but haven't been opened in Godot yet. `title_theme`, `static_crawl` and the four story intro loops were checked the same way and load as forward loops over the whole file. The manifest marks every loop except `relay_hum` with `"loop": true` (`relay_hum` was built before that flag existed).

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
| `arm_whir` | 44100 |
| `amb_w3` | 352800 |
| `m_3_1` | 1975680 |
| `m_3_2` | 1834560 |
| `m_3_3` | 1975680 |
| `m_3_4` | 2163840 |
| `title_theme` | 1769880 |
| `static_crawl` | 44100 |
| `intro_line` | 529200 |
| `intro_noise` | 529200 |
| `intro_still` | 264600 |
| `intro_home` | 793800 |

In the generator, a looping sound is marked `loop=True`. It's rendered with one extra pass as a run-in, and the part after the loop point is blended into the start over 80 ms. Every note and volume pattern in it repeats a whole number of times per pass. `amb_w1` is mostly wind noise at its seam, so it uses `power_seam=True`, a blend that keeps the noise at an even level. A plain blend of two different stretches of noise dips in the middle.

The two village loops, the level music, `title_theme`, `arm_whir`, `amb_w3`, `static_crawl` and the story intro loops also use `lock=True`. Without it, the notes repeat every pass but each voice's wave doesn't: a pass ends part-way through a cycle, so the next pass starts at a different point in the wave. The 80 ms blend then mixes two copies that are out of step, and the sound thins for a moment. That's easy to hear in tuned music. `lock=True` nudges each pulse and the triangle by a tiny fraction of a cent (under 0.3 cent in every loop so far, far too small to hear) so they finish every pass on a whole cycle. It also restarts the noise at every pass. Every pass then comes out the same, sample for sample, and the blend at the seam joins two identical pieces of audio. Use it for any new music loop.

## Loops with an intro

Every loop here loops the whole file, so a loop that needs a one-off opening gets it as a second file. There are two so far. The 2-bar intro to `title_theme` is `title_intro`, and the flare that opens `intro_home` is `intro_wake`. Each plays once. Play the loop the moment its intro ends, with no gap. `title_intro`'s last bar is the same A chord and bass walk as `title_theme`'s last bar, and `intro_wake`'s last beat is the same as `intro_home`'s, so each join sounds exactly like the loop's own seam. An intro and its loop are at the same gain.

In the generator this is `intro=` on the loop, and asking for either name rebuilds both. In the manifest, an intro has `"then_play"` naming its loop, and the loop has `"intro"` naming its intro, and `"loop_start_s": 0.0`.
