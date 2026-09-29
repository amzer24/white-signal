# White Signal: story arc

Status: draft for Lee, 26 Sep 2026. Worlds 1 to 3 match what is in the game now. World 4 and the ending are proposals, marked PROPOSAL, and need Lee's approval. They answer GDD questions Q2 to Q4. The Pips (section 5) were decided on 29 Sep 2026.

The players are aged 10 and up. The reading targets are in section 6.

## 1. Premise

One line once carried every voice across the land, until a howling noise came down it and the crews cut it apart, one station at a time, to stop the noise spreading. Years later, in the Quiet that followed, a tiny Spark of living signal wakes at the end of a cut wire when the dead line rings three times. It sets out from Last Relay, the last station that still hums, to follow the line gate by gate and find out who is still calling.

## 2. Want, need and stakes

- **Want.** The Spark wants to find out who is calling. From World 2 on, once the call says its name, it wants to go home.
- **Need.** It needs to learn that it belongs. Home is not one place. It is the people you are joined to, and by the end the Spark has two homes joined by one line.
- **Stakes.** The callers are the other Sparks. They have held the noise down in Dead Air since the line was cut, and they are getting weaker. If no one answers, their ring breaks, the noise rises up every cut wire, and Last Relay's hum, the last one on the line, goes out. As Old Mast says after World 3, there is nothing left to cut.
- **Theme.** Cutting yourself off can keep you safe, but it also keeps you alone. Every character has done a version of this. The crews cut the line. The relay swapped itself to pieces. Spire kept the masts standing alone. The Sparks held on in the dark, cut off from everyone.

## 3. Tone

Quiet, lonely and hopeful, as in GDD pillar P4. Small, warm people in a big, dark world. Danger is eerie, never gory. Nobody is a villain, and every hard choice in the backstory was made to protect someone. Tally and Dot bring the jokes. Sad moments are allowed, and each world ends a little brighter than it began.

## 4. The arc

### How the call becomes clearer

The call holds the story together. Wren tunes it in on her radio in the radio shack, and each lit Gate lets more of it through.

| When | What the player hears | What it tells them |
|---|---|---|
| The intro and Old Mast | Three rings, then a voice nobody can understand | Someone is calling |
| Meeting Wren in 1-2 | "It isn't random static. It's words!" | The call has a message |
| After World 1 | A name that starts with S-P | A puzzle the player can solve before Wren does |
| After World 2 | SPARK, COME HOME | The call is for the Spark |
| After World 3 | SPARK, COME HOME. WE KEPT YOUR PLACE | There are many callers, and they know the Spark |
| World 4 (PROPOSAL) | THE RING WON'T CLOSE WITHOUT YOU | Why they are calling, and why now |

### World 1: The Flats. Someone is calling

- **The player learns** to run, jump, stomp and dash, and to handle loose floors, presses, lift rings, droppers and the warden. The reward is the Arc.
- **Villager moments.** Wren, in 1-2, is sure the call is words, not static. Brace, in 1-4, admits the crews cut the lines on purpose and that Brace was one of those workers.
- **Mystery raised.** Who is calling? And what was the noise? Back at Last Relay, Brace says nobody ever found out where it came from.
- **Emotional turn.** The Quiet was a choice, not an accident. People gave up their voices to keep each other safe. Lighting the first Gate proves the line is not completely dead.

### World 2: The Switchyard. The call is for you

- **The player learns** hoppers, spiked walkers, the Arc, channel switches and a boss beaten by blowing its fuses.
- **Villager moments.** Dot goes home to run the switchboard again. Hum asks you to let the relay rest, because it is shaking itself apart trying to keep the noise out. Afterwards Brace says a machine that can't stop protecting itself isn't protecting anyone, and wonders if the crews were the same.
- **Mystery paid off.** The half name was SPARK.
- **Mystery raised.** Where is home, for something like the Spark?
- **Emotional turn.** A stranger's call becomes the Spark's own. The world also learns that holding on too hard to safety can do harm.

### World 3: The Aerials. You are not the only one

- **The player learns** flyers, wind and updrafts, sweep arms and a climb three screens tall.
- **Villager moment.** Spire kept the masts standing alone through the Quiet. Spire says the call bounces off the top of the Spire, so the callers are below, not above. After World 3, Spire admits that having friends is better than standing alone.
- **Mystery paid off.** WE KEPT YOUR PLACE. There is more than one caller, and they know the Spark.
- **Mystery raised.** Who are they, why are they in Dead Air, and how do they know the Spark when it doesn't remember them?
- **Emotional turn.** The Spark is not one of a kind, and someone has been saving it a place. But the call comes from Dead Air, where nobody goes, and the static grows thicker every night. For the first time, Old Mast is afraid for it.

### World 4: Dead Air. Answer the call (PROPOSAL)

**Setting.** The deep exchange under the network, where every cut line ends. There is no wind and no light. The noise pooled here after the cut.

**What really happened.** This is the reveal, told across World 4.

1. The Sparks were the line's messengers. They carried voices from station to station, and at the heart of the exchange they formed a ring that kept every voice on its own path.
2. One night the heart cracked. The voices began echoing back on themselves, louder and louder, until they became the howling noise. It is the squeal a microphone makes next to a speaker, but as big as the whole land.
3. The Sparks dived down and held the noise inside their ring. The crews above cut the line so it couldn't spread. Both worked.
4. Our Spark was out on the line carrying a voice that night. When the crews cut its wire, it was stranded at the cut end and fell asleep. Its place in the ring has been empty ever since. That is why it doesn't remember the others, and why they say WE KEPT YOUR PLACE.
5. The ring has held for years with a gap in it. Now the Sparks are tired, the noise is rising, and they spent the last of their strength ringing the dead line three times.

**Levels.** These follow the plan in `docs/research/traps-enemies-2026-09-25.md`, each with a story reason.

| Level | Idea | Story reason |
|---|---|---|
| 4-1 | Relay turrets and line emitters | Old defences that still fire at any signal, because they think everything is the noise. The same mistake the World 2 relay made |
| 4-2 | Echoes in the dark | The research doc calls this enemy a "listener". Rename it "echo" so it doesn't clash with the listener villagers. Echoes are scraps of the noise that drift after you only while you look away |
| 4-3 | The rising static shaft | The noise climbing because the ring is weakening. The stakes, turned into a level |
| 4-4 | The last Gate | The ring itself |

**Villager beats.** Each needs a new entry in `levels/story/npcs.json` and a `w4` flag. Example lines, already written to the style guide:

- Brace waits at the top of Dead Air with the handle: MY CREW CUT THE WIRE YOU WERE LYING ON, SPARK. NOW I'M HERE TO HELP YOU JOIN IT BACK TOGETHER.
- Wren's radio, after 4-2: THE RING WON'T CLOSE WITHOUT YOU, SPARK. PLEASE HURRY, BECAUSE WE CAN'T HOLD THE NOISE MUCH LONGER.
- Old Mast, before 4-4: WHATEVER IS WAITING DOWN THERE, MAKE SURE YOU COME BACK UP. WE KEPT YOUR PLACE HERE TOO.

**Emotional turn.** The Spark has to go into the dark alone, and finds it isn't alone after all. Brace's handle, Wren's radio and Mast's lantern come with it, and the other Sparks are waiting.

### The ending (PROPOSAL)

1. At the bottom of Dead Air, the Spark finds the ring. A circle of small Sparks sits around the cracked heart of the line, holding the noise down. One place is empty.
2. The Spark takes its place. The ring closes and the last Gate lights.
3. Light runs up every cut wire at once and the static burns off. Across the land, stations light up one at a time. This is intro card 4 played backwards.
4. At Last Relay, Brace pulls the handle the other way and joins the line again. Wren's radio fills with voices from every station.
5. The line rings three times, and Old Mast picks up. This time the Sparks are calling, with our Spark among them: LAST RELAY, THIS IS THE LINE CALLING. EVERY STATION IS ANSWERING, AND WE'RE ALL COMING HOME.
6. A closed ring holds by itself, so the Sparks can travel the line again. The Spark comes back up to Last Relay, which is now busy with visitors. Wren answers her own question: SO THAT'S WHERE HOME IS, FOR SOMETHING LIKE YOU. IT'S EVERYWHERE THE LINE GOES.

After the credits, the player is back in Last Relay and free to rescue any Pips they missed.

**Why this ending.** It pays off every thread already in the game: the three rings, WE KEPT YOUR PLACE, Brace's handle, Wren's question about home and the intro's "one station at a time". Nobody is defeated. The noise is mended, not fought, which fits the theme.

**A sadder alternative.** The Spark stays in the ring to hold it, and Last Relay hears it on the radio every night. I don't recommend it as the main ending for this age group.

### One caller or many? (PROPOSAL, GDD Q2)

Many. The callers are the Sparks of the line, speaking together, which is why the call says WE. There is no single "other spark". Once this is approved, that phrase should come out of `docs/levels/world-1.md` and the research doc.

Why many:
- The game already says it. Wren hears WE, and "kept your place" means a group with a gap in it.
- It makes the stakes bigger than one friend.
- It fits the theme. The Spark belongs to a group it didn't know it had.

## 5. The Pips (decided 29 Sep 2026, GDD Q1)

**Who they are.** Pips are tiny sparks of signal, small cousins of the Spark. Before the noise, every voice on the line was carried by a Pip. When the crews cut the line, the Pips were caught in the glass insulators on the poles, and they have been calling out from the glass ever since.

**Where the story shows them.**
- The intro: card 2 names them ("LITTLE PIPS OF SIGNAL CARRIED EVERY VOICE") and shows them running along the wire. Card 5 shows them caught in the glass of the dead poles ("AND THE PIPS WERE CAUGHT IN THE GLASS"). Card 10 sets the goal: "FREE THE PIPS AND LIGHT THE GATES".
- Old Mast's first talk ends by pointing the Spark to them and to Dot.
- Dot connected every call at Last Relay's switchboard. The Pips were her voices. She keeps every Pip the Spark frees, and they gather around her switchboard.

**How it plays.** Each Pip sits where a big shard used to be, so every one is already proven reachable. A trapped Pip calls when the Spark is near. Touching the glass breaks it and the Pip flies home. Dot gives a gift at 5, 10, 18 and 27 Pips, and at all 35 (see `docs/levels/village.md`).

**For the ending (PROPOSAL).** When the Spark reaches the caller, the Pips it brought home answer the call with it. With all 35 home, the answer is the whole switchboard at once: the line full of voices again, which is what card 2 said was lost.

## 6. Style guide for game text

### Reading level

- Lexile 750L to 880L, the level of Harry Potter 1 or Percy Jackson. Lexile needs a paid tool, so we check Flesch-Kincaid instead.
- Flesch-Kincaid grade 5.0 to 6.5.
- 10 to 14 words per sentence on average. Mix fuller sentences with the odd short one for punch.
- 1.3 to 1.4 syllables per word. Use common base words, plus clear describing words.

Check any new text with `python tools/writing/readability.py`. It measures the reading level and checks every villager line fits 3 rows and uses only characters the font can draw.

### The 3-line rule

- A speech bubble shows at most 3 rows of 40 characters. Aim for 60 to 100 characters per bubble. If someone has more to say, give them another bubble.
- Keep one idea per bubble.
- Intro cards have exactly 2 lines of 38 characters or fewer, and about 14 words at most, so they can be read while they are on screen.
- Level hints are about 30 characters or fewer, and must not run into another hint.

### Characters

- UPPERCASE only. The font draws A to Z, 0 to 9 and these marks: . : / - + = ? ! [ ] ( ) , ' > < ^ ~ % _ * # @ | \ and the space.
- No double quotes, no semicolons and no dashes as punctuation. Hyphens inside words are fine, as in SEE-THROUGH and MID-AIR.
- Asterisks are only for highlights.
- In level hints, underscores are spaces and `_._` reads as " . ". Never put = in a hint.

### Highlights

- Write `*WORD*` or `*SHORT PHRASE*`. The game draws it underlined and bright.
- Use at most 2 per bubble and 1 per hint, and none on intro cards.
- Only highlight what the player must act on or remember: places to go (LAST RELAY, RADIO SHACK, SIGNPOST), things to use (FUSES, SWITCH, THE ARC) and things to collect (SHARDS).
- Highlight a word the first time it matters, not every time.

### Voice and grammar

- Use active voice for anything the player does. BUMP THE SWITCH, not THE SWITCH MUST BE BUMPED.
- Made-up words are fine when the sentence explains them. For example, THE GATES ONLY OPEN FOR SIGNAL, NEVER FOR LISTENERS LIKE US tells you what a gate does and who the listeners are.
- Narration calls the Spark IT. Characters call it SPARK or LITTLE SPARK.
- Keep key phrases the same everywhere: THE LINE, THE CALL, THE QUIET, DEAD AIR, LAST RELAY.

### Words of this world

| Word | Meaning |
|---|---|
| The line | The one long wire that joined every station |
| Relay, station | A stop on the line. Relays pass voices along |
| Gate | A barrier at the end of each stretch of line. It opens only for signal |
| Listeners | The small radio folk who live at the stations |
| The Quiet | The years since the line was cut |
| The noise, static | What came down the line. Static is the part you can see |
| Spark | A living scrap of signal |
| Shards | Pieces of signal. Tally trades for them |
| Pips | Tiny sparks of signal that carried every voice along the line. Caught in the glass insulators when the line was cut. Dot keeps them |
| The Arc | The power the Spark throws, earned at the first Gate |
| Channels | The two halves of a split line. Only one is live at a time |
| Dead Air | The deep exchange where every cut line ends |
| The ring | PROPOSAL. The circle of Sparks holding the noise down |

### Voices

| Who | How they talk | Example lines |
|---|---|---|
| Old Mast | The keeper. Warm, steady and protective. Full, calm sentences. Worries more than he says | THE CALL COMES FROM PAST THE GATES, AND THE GATES ONLY OPEN FOR SIGNAL, NEVER FOR LISTENERS LIKE US.<br>THE STATIC GROWS THICKER EVERY NIGHT, AND IF THE NOISE RETURNS, THERE'S NOTHING LEFT TO CUT. |
| Tally | The trader. Quick and cheerful. Counts everything and talks in prices | WELL, A CUSTOMER AT LAST, AND A GENUINE SPARK! I'M TALLY, AND I KEEP COUNT OF EVERYTHING.<br>EVERYTHING IS PRICED IN SHARDS, SO HAVE A LOOK AROUND. SORRY, BUT THERE ARE NO DISCOUNTS FOR SPARKS! |
| Wren | The radio listener. Curious, fast and excited. Takes notes and asks questions | I'VE WRITTEN DOWN EVERY SOUND IT MAKES, AND NOW I'M CERTAIN IT ISN'T RANDOM STATIC. IT'S WORDS!<br>SO THE CALL WAS MEANT FOR YOU ALL ALONG. BUT WHERE EXACTLY IS HOME, FOR SOMETHING LIKE YOU? |
| Brace | Former line crew. Blunt and practical, safety first. Carries guilt about the cut | CAREFUL IN HERE, BECAUSE THE OLD CREWS CUT THESE LINES ON PURPOSE, AND I WAS ONE OF THOSE WORKERS.<br>A MACHINE THAT CAN'T STOP PROTECTING ITSELF ISN'T PROTECTING ANYONE AT ALL. |
| Dot | The switchboard operator. Bright and chatty. Opens with BLINK, BLINK and talks in connections | BLINK, BLINK! THAT'S HOW WE SAID HELLO ON THE SWITCHBOARD, BACK WHEN I CONNECTED EVERY CALL.<br>PICK ANY STRETCH OF LINE YOU'VE VISITED BEFORE, AND I'LL PATCH YOU STRAIGHT THROUGH. |
| Hum | Tired, gentle and polite. Slow sentences. Calls the Spark LITTLE SPARK | HELLO, LITTLE SPARK. FORGIVE ME, BUT I HAVEN'T SLEPT A WINK SINCE THE LINE WAS CUT.<br>CAN YOU HEAR THAT? ABSOLUTELY NOTHING, AND IT'S THE FIRST PEACEFUL NIGHT I'VE HAD IN YEARS. |
| Spire | The mast rigger. Loud, brave and outdoorsy. Gives practical tips. Proud of standing alone, and learning not to | HOLD ON TO SOMETHING! UP HERE, THE WIND NEVER ASKS PERMISSION BEFORE IT SHOVES YOU.<br>I KEPT THOSE MASTS STANDING ALONE FOR YEARS AND CALLED IT STRENGTH, BUT HAVING FRIENDS IS BETTER. |

## 7. Readability, before and after

| Text | Measure | Before | After | Target |
|---|---|---|---|---|
| Villager lines | Bubbles | 60 | 68 | |
| | Words per sentence | 5.5 | 13.5 | 10 to 14 |
| | Syllables per word | 1.19 | 1.31 | 1.3 to 1.4 |
| | Flesch-Kincaid grade | 0.6 | 5.1 | 5.0 to 6.5 |
| | Characters per bubble (average) | 57 | 89 | 60 to 100 |
| Intro cards | Words per sentence | 7.3 | 8.7 | |
| | Syllables per word | 1.17 | 1.28 | |
| | Flesch-Kincaid grade | 1.0 | 2.9 | |
| Level hints | Words per sentence | 3.0 | 4.0 | |
| | Syllables per word | 1.17 | 1.13 | |
| | Flesch-Kincaid grade | -0.6 | -0.7 | |

**What the numbers mean.**
- The villager lines are where the reading happens, 1,124 of the 1,254 words of story, and they now sit inside all three targets.
- The intro cards can't reach grade 5. Each card is 2 lines of 38 characters with about 14 words, and card 7 must end ONCE . TWICE . THREE TIMES, so sentences stay short. They moved from grade 1.0 to 2.9.
- Hints are 2 to 6 word instructions read mid-jump. Short is right there, so the grade formula doesn't apply. They now all tell the player what to do.

**Checks that pass.** Every villager line wraps to 3 rows or fewer at 40 characters, whether or not the asterisks are drawn. Every line uses only characters the font can draw. No bubble has more than 2 highlights. Cards are 38 characters or fewer per line, and card 7's second line is unchanged. Hints are 30 characters or fewer, with at most one highlight, and no two hints overlap on screen.

**How it was measured.** A Python script counted sentences, words and syllables. Flesch-Kincaid grade is 0.39 times words per sentence, plus 11.8 times syllables per word, minus 15.59. Syllables come from a rule of thumb plus a hand-checked list of about 300 words, so treat each grade as accurate to about 0.3. Sentences end at a full stop, question mark or exclamation mark. Where a card line ends with no full stop, I judged by hand whether the next line carries on the sentence. The same script measured before and after.

## 8. What changed in this pass

- `levels/story/npcs.json`: all 68 bubbles are new or rewritten (there were 60). Ids, flags, conditions and shop settings are unchanged.
- Intro cards in `scripts/intro/intro_scene.gd`: 8 of 10 cards reworded, 12 lines in all. Cards 5 and 8 are unchanged, and every card still matches its picture.
- Level hints: 47 of 52 rewritten as short instructions.
- Title screen and game menus: 24 text replacements are listed for whoever is editing `scripts/title/title_screen.gd` and `scripts/world1/w1_game.gd`. They haven't been applied.
