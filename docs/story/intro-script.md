# White Signal: new game intro

Status: draft for Lee, 26 Sep 2026. Nothing is built. No code or level files were changed.

## Logline

A small spark of signal wakes when a line that has been dead for years starts ringing, and follows it, gate by gate, to find out who is still calling.

## How the intro plays

- It plays once, when the player picks New Game, and hands over to Last Relay with Old Mast standing over the Spark.
- Each beat is one card: an image, then up to two lines of text typed in the game font.
- Jump or Down skips to the next card. The pause button skips the whole intro. A skipped intro still lands the player in the same place.
- Each card shows for about 3 words a second, plus a second and a half of silence.
- Art rule for all ten cards: one clear subject per card. From card 5 on, the Spark is the only pure white thing on screen, so the eye always finds it.

## The beats

| # | Image | Text | Feeling | Seconds |
|---|---|---|---|---|
| 1 | One wire on poles runs across a flat, dark land. A small light sits at every station along it, all lit, and little Pips run along the wire. | ONE LINE RAN ACROSS THE WHOLE LAND<br>JOINING EVERY RELAY AND EVERY GATE | Calm, wide, a little old | 6 |
| 2 | A relay tower with a lit window. A tiny listener sits at its base, and a Pip, a tiny spark carrying a voice, runs along the cable past them. | PIPS OF SIGNAL CARRIED EVERY VOICE<br>SO NO ONE WAS EVER TOO FAR AWAY | Warm, safe | 6 |
| 3 | A scribble of white static crawls along the wire from the right. The station lights behind it go out one by one. | THEN A HOWLING NOISE FILLED THE LINE<br>AND SPREAD FROM STATION TO STATION | Unease | 6 |
| 4 | A listener in a crew coat pulls a big handle. The wire snaps apart in front of the static, which stops at the gap. | SO THE CREWS CUT THE LINE APART<br>ONE STATION AFTER ANOTHER | Sad, but a choice made for good reasons | 6 |
| 5 | The same wide land as card 1, now all dark. Poles lean. The wire hangs in pieces. No sound. As the second line types, Pips glow faintly in the glass insulators, trapped. | THE NOISE STOPPED . SO DID THE VOICES<br>AND THE PIPS WERE CAUGHT IN THE GLASS | Lonely. The low point. | 7 |
| 6 | Close up. A cut wire end lies in the grass. At its tip, a tiny white spark is curled up and barely glowing. | AT THE END OF ONE CUT WIRE<br>A TINY SPARK OF SIGNAL LAY SLEEPING | Tender, small | 6 |
| 7 | The same close up. Three rings of light travel down the dead wire toward the Spark, one per ring. A phone ring sound plays with each. | UNTIL ONE NIGHT THE DEAD LINE RANG<br>ONCE . TWICE . THREE TIMES | Surprise. Hold your breath. | 7 |
| 8 | The Spark flares bright and sits up. Its glow lights the wire for a few tiles in both directions. | NOTHING SHOULD RING ON A DEAD LINE<br>BUT SOMEONE IS STILL CALLING | Wonder. This echoes the title tagline. | 6 |
| 9 | Wide shot at night. The Spark, a small dot, follows the wire up a slope toward one lit window on a hill. A lantern comes down the path to meet it. | IT FOLLOWED THE WIRE TO THE LAST LIGHT<br>A HILLTOP STATION CALLED LAST RELAY | Relief, company | 6 |
| 10 | From Last Relay's window, the line runs east into the dark, past a gate on the horizon. Very far off, one tiny light blinks. | FREE THE PIPS AND LIGHT THE GATES<br>TO FIND WHO IS ON THE OTHER END | Hope, with a question left open | 7 |

Total: about 63 seconds. Every line is 38 characters or fewer.

What each beat is doing:
- Cards 1 and 2: what the line and the relays were.
- Cards 3 to 5: why everything went dark and quiet. It matches Brace, who says the crews cut the lines on purpose to stop the noise spreading.
- Card 6: what the Spark is. It's a living piece of signal, which is why it can travel the line when the listeners can't.
- Cards 7 and 8: why it wakes now. The ringing matches Old Mast's "three rings".
- Card 9: sets up Last Relay and the lantern of whoever finds it.
- Card 10: the goal. The far light keeps the caller a mystery.
- Why it matters: card 2 says no one was ever far away, and card 5 says every station is now alone. Relighting the line puts that back.

## Handover to gameplay

The last card fades into Last Relay. The Spark is lying by the signpost and Old Mast is standing over it with a lantern.

Old Mast's first two lines, from `levels/story/npcs.json` (rewritten 26 Sep 2026 with the rest of the dialogue, see `docs/story/story-arc.md`):
1. YOU ARRIVED ALONG THE WIRE LAST NIGHT, AFTER THE DEAD LINE RANG, AND YOU'VE BEEN ASLEEP EVER SINCE.
2. THIS IS LAST RELAY, THE ONLY STATION STILL HUMMING ANYWHERE ON THE LINE AFTER ALL THESE YEARS.

His next three lines add the three rings and a voice, the gates that only open for signal, and the goal.

## Story bible (150 words)

The line was one long wire that ran across the land, station to station. Relays passed voices along it, and gates marked each stretch. Small radio folk called listeners kept it running.

Then a noise came down the line. To stop it spreading, the crews cut the line one station at a time. It worked, but every station went silent. That time is called the Quiet. Dead Air is something else: a place deep under the old exchange where the line ends up, and nobody goes there.

A Spark is a living scrap of signal. It can travel the line past gates the listeners can't cross.

Last Relay is the last station that still hums. Old Mast, Tally and the others wait there.

The caller rings three times, then speaks. Its words become clear world by world. Who they are, and what "home" means, stay secret until World 4.

## The Pips (decided 29 Sep 2026)

Big shards became the Pips: tiny sparks that carried every voice, caught in the glass when the line was cut. Cards 1, 2, 5 and 10 introduce them. The full picture is in `docs/story/story-arc.md`, section 5.

## Canon problems found while writing

- The brief asked the intro to have the Spark relight the relays. In the game it doesn't do that. The World 2 relay is put to rest by blowing its fuses, and Hum thanks you for the quiet. So the intro says "light the gates" only.
- The world-1 design doc says the last world is where you find "the other spark", which sounds like one caller. Wren's last line says "WE. THERE'S MORE THAN ONE OF THEM". Both can be true, but World 4 needs to pick one.
- The saved project notes say the attack move is the World 3 reward and still undecided. The game gives the Arc at the World 1 clear, and Old Mast explains it there.
- `docs/levels/village.md` is behind the game. It lists only the World 1 and World 2 flags and doesn't mention Spire.
- The `humanizer` skill Lee wants used on docs isn't installed in this session, so this doc hasn't been through it.
