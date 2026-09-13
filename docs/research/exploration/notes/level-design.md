# WHITE SIGNAL: exploration and interactive level design

## Design position

WHITE SIGNAL should make restoring infrastructure change the places the player can reach and the way they understand those places. Treat REACH, WAKE, CROSS, RIDE, HOLD, CLIMB, OUTRUN and PLANT as regional identities or local dramatic events, rather than eight mandatory consecutive stages. Good movement becomes valuable when it opens possibilities: a remembered roof, an unexpected connection under the hub, or an abandoned machine with a comprehensible purpose.

The existing GDD §7d describes an eight-relay, approximately thirty-minute chain; R1 has three ears, R2 introduces increasing time pressure, and subsequent relays concentrate particular verbs. That remains useful encounter material, but its fixed sequence and run economy need reconsideration for lasting abilities and exploration. The source is the local [GDD, §7d](<E:/Godot games/white signal/js-original/GDD.md>), read as a design baseline rather than a record of every implemented behavior.

## Primary evidence and its limits

**Hollow Knight: plan connections and allow the plan to open up.** In Wes Fenlon’s direct interview, William Pellen describes initially ordering abilities alongside the world’s shape. Ari Gibson says they subsequently removed much hard gating, leaving many power-ups optional. Pellen describes placing Crossroads centrally and sketching movement through surrounding areas before interiors. Their earlier idea of rearranging prefab rooms was abandoned; the team valued locations making sense within the world. These statements support deliberate geography and revisable dependencies, not a claim that every Hollow Knight room follows a fixed formula. [1]

**Mario: teach a concept, develop it, surprise, then demonstrate mastery.** Koichi Hayashida explicitly describes that sequence and relates it to four-panel narrative structure. He also describes rough prototypes being discarded or polished and watching people play for useful feedback. The same interview explains that Super Mario 3D Land’s timed stages were not intended for slow exploration. Therefore its local teaching structure transfers better than its global pacing. [2]

**Zelda: access to tools can support choosing a destination.** Nintendo’s A Link Between Worlds launch article describes renting or buying tools, choosing dungeons, and using wall merging for exploration and puzzles. This establishes a concrete alternative to acquiring every dungeon’s key inside that dungeon. It does not establish that all Zelda dungeons have universally unrestricted order or that any particular puzzle grammar is Nintendo doctrine. The developer interview pages returned access errors, so claims here remain limited to the accessible first-party article. [3]

**Metroid: acquisition changes the interpretation of remembered places.** Nintendo’s Metroid Dread report describes new capabilities opening doors, destroying walls and enabling routes; its developers explicitly connect this to seeing previous barriers differently. Its map supports highlighting matching icon types, personal markers and hidden-item-area hints. These are useful precedents for helping players remember opportunities without drawing their entire future route. [4]

**Celeste: preserve demanding movement while favoring the player at the margins.** Maddy Thorson’s own article documents coyote time, buffered jumps, corner correction, stored lift momentum and generous wall-jump windows. The stated common purpose is widening timing or positioning allowances. The official GDC workshop listing confirms a talk about hundreds of stages, area-map arrangement and story integration; its accessible page does not expose a transcript. Consequently, this report does not attribute precise screen-length or checkpoint rules to that talk. The bounded-screen recommendations below are original applications. [5, 6]

**Ori: test the connected world before decorating it.** Thomas Mahler describes beginning with a paper concept, building simple polygon blockouts, repeatedly playtesting and seeking other designers’ criticism before art. He identifies physics-driven sequence breaks and the consequences one world change can have elsewhere, and says experienced speedrunners helped test the game. His discussion of shards emphasizes player-selected loadouts. This supports separating optional build expression from reliable traversal prerequisites, although WHITE SIGNAL’s specific separation is a recommendation. [7]

## Reusable patterns for an exploration-first campaign

The following are recommendations synthesized from that evidence, not descriptions of undocumented developer intent.

**Use two graphs.** Draw geography as rooms and connections; separately draw which permanent capabilities and world states unlock each connection. A visually branching map can still be functionally linear if all exits require the same next key. After the opening lesson, aim for two actionable leads with different prospective rewards. Distinguish ability gates, knowledge gates, switch-controlled shortcuts and high-skill optional traversals in the design document.

**Let acquisitions affect more than one place.** A permanent PULSE could energize a relay across a gap, restart a dormant lift, and interrupt a NOISE shell. Its first use should be obvious and safe. Before acquiring it, show one reachable-looking but inactive receiver elsewhere. After acquiring it, offer both a nearby continuation and a remembered optional route. A painted symbol on a locked door alone is weaker than hardware whose behavior the player can predict.

**Make a loop earn its return.** A useful loop contains a discovery, changes access, and reconnects somewhere recognizable. Return from an upper dish via its newly powered service lift, seeing the previously unreachable balcony descend into the hub. Avoid forcing the same empty corridor after every ear. Mandatory revisits should introduce changed geometry, a new decision, a new interaction or meaningful narrative context; otherwise shorten them through a permanently unlocked conduit.

**Reward curiosity in several currencies.** Spread permanent abilities, movement techniques, transport links, map information, optional glyphs and environmental discoveries across the world. Do not make every side room another shard cluster. An Operator’s chamber might reveal why a district was disconnected; another discovery might expose a new biome exit. A high-skill pocket can offer a loadout reward without becoming a prerequisite. State the expected reward category in every room sheet.

**Keep navigation uncertain and interactions legible.** Players can wonder what lies beyond a submerged stair; they should understand whether a lever moved the waterline. Establish consistent silhouettes for receivers, switches and transit conduits. In monochrome, encode state with shape, motion and pattern, not brightness alone: an open collar, a moving waveform and a connected cable tell more than a nearly imperceptible shade change.

**Separate exploration time from performance time.** Put escalating rain or an OUTRUN event inside a clearly entered sequence with a checkpoint and a completed-state bypass. A district-wide timer punishes inspecting lore, studying a map or trying an alternate path. Preserve the original pressure encounters as dramatic branches or events, while leaving the surrounding region available for investigation.

## Machinery and puzzle grammar

Build a small consistent vocabulary before inventing exceptional switches. A source produces coherence; a cable carries it; a selector chooses an output; a receiver acts while powered; a latch remembers a successful activation. Conduits transport the player, with an entrance shape distinct from power cables. Static-water is not ordinary water: establish explicitly whether its level threatens, supports or disables particular objects, and keep that behavior consistent.

| Element | Player-readable contract | Productive remix |
|---|---|---|
| Lever | Stable two-position selector; visible handle shows state | One output raises a lift, another extends a bridge |
| Receiver | Power enters through a recognizable face | Reach its far side or redirect the supply |
| Latch | A successful pulse persists, shown by locked-open geometry | Create a return shortcut before rerouting power |
| Pump | Changes one basin between marked levels | A route closes while another becomes available |
| Conduit | Clear linked transport mouths and safe arrivals | Opens a route beneath a previously understood room |
| Repeater | Extends a signal through a spatially readable chain | Requires placing the player where an interrupted link can be restored |

Introduce each contract with its control and effect on the same screen. Later, extend cables into adjacent rooms, retaining directional pulses and a small local status indicator. A brief camera reveal may confirm a distant effect, but should return control promptly. Do not require memorizing identical switches with invisible relationships. A puzzle should ask the player to infer and manipulate a relationship, rather than merely search until every switch is touched.

Reset behavior is part of the puzzle. Persist permanent abilities, collected unique rewards and completed latches. Reset unsolved transient machinery to a known state when using a local reset control; put that control on guaranteed safe ground. Death should not silently erase a district-scale discovery. Any movable carrier must have a recall point. Every reversible water state needs a reachable control or a safe escape; every irreversible state needs a route back to stable ground.

## Original blockout proposal: The Listening Field pump district

This is an alternative prototype, not the settled campaign baseline. The main atlas prioritizes permanent DASH in Listening Field and AIR JUMP in Drowned Array, with contextual machinery interactions. The PULSE proposal below explores a larger scope and should wait until a smaller slice proves exploration, levers and return shortcuts. For that first slice, replace remote PULSE receivers with reachable contextual controls and use DASH to access the upper workshop ledge. Permanent PULSE here is distinct from any random glyph using that name; production would need to resolve that collision. No new engine support is assumed.

The district once cooled and powered the three listening dishes. Its core discovery is that the Operators isolated one ear deliberately. The beacon hub remains a recognizable reference point. First visits offer the workshop and basin as independent leads; completing either is useful. Reawakening all ears can remain a completion objective, but opening the next region does not wait for all three.

```text
                         N: Dish crown ---- K: Wire entry
                         |    [PULSE]          [later tether]
                   D: Switch gallery
                   |             |
A: Flats <----> H: Beacon hub <--> W: Workshop [earn PULSE]
                   |             |            |
                   B: Basin rim--P: Pump room--+
                   |             |
              C: Service floor   S: Stand connection
                   | [low level]     [PULSE bypass or base route]
                   U: Underpass ------+
                   |         |
            E: Archive     F: Drowned Array overlook
         [optional puzzle]     [future insulation gate]

Completion links: N --> H via latched lift;
U <--> H via service conduit opened from U.
```

Use approximately nine playable rooms plus two boundary vistas, not eleven equally sized combat boxes. H and B may occupy two view widths; W and E are compact single-screen spaces; D and N form a vertical climb. The graph is topological: exact adjacency must be reconciled in a paper cross-section before collision placement. The displayed pump/workshop/hub loop must physically wrap a shared shaft, not teleport without explanation.

With a 480×270 view, 135 px/s run speed and approximately 57 px base jump height, start ordinary teaching ledges around 28–40 px above takeoff and provide generous landings. These are provisional blockout values, not verified reachability guarantees. Horizontal reach needs the actual acceleration, airtime, collision bounds and wall-kick rules; never infer it from jump height alone. Label every edge with its tested minimum ability set.

### Puzzle 1: Borrowed power

At D, one selector powers either the lift to N or a bridge to W’s upper receiver. The bridge and lift are visible together. The player first uses the lift and sees that its upper safety latch is unpowered. After finding permanent PULSE in W, they can energize that latch from the upper workshop ledge; the lift now stays available when the selector is moved. Rerouting power to the bridge completes the circuit to the dish.

The insight is that temporary supply and persistent state are different. Reward: the crown view, a restored ear and a permanent hub lift. Resetting the selector cannot undo the latch. Before the latch is set, falling returns to the selector platform; no failure demands replaying W. A later optional receiver across a moving platform remixes this rule without adding another exception.

### Puzzle 2: Drain to discover, raise to return

At B, a window shows a maintenance stair beneath the static-water line. P lowers the basin to expose C and U. Safe fixed stairs connect P and B in both states. C contains a float platform tethered inside a guide rail; the player uses a lower pump lever to raise it and reach the underside of H. Opening the conduit there completes the return loop. Both pump levers control the same persistent two-state system.

The insight is that a hazard’s removal reveals a route, while restoring it changes a platform’s height. Reward: the underpass, a shortcut, and a view into the Drowned Array. Drain controls remain reachable at either height; water changes slowly enough to retreat, with marked limits. No mandatory waiting for every fourth tide. Future insulation permits a new route through F without invalidating the first puzzle’s achievement.

### Puzzle 3: The disconnected ear

E contains an intact cable that terminates at an open isolation switch. A sealed observation window shows an ear aimed away from the others, and an empty Operator chair faces a warning trace. First, the player learns in a safe alcove that two repeaters facing each other return a pulse to its origin. Then they rotate the archive’s two accessible repeaters so a pulse passes through the receiver behind the observation wall and returns to release the archive latch.

The insight is routing through space, not guessing a numeric code. Reward: a permanent map annotation for the Stand’s service entry, an optional glyph, and evidence that silence was intentional. Keep the complete circuit visible across at most two screens; use directional animated pulses. The reset handle restores both repeaters, and the exit stays open throughout. This puzzle is optional: no random glyph, optional lore interpretation or repeated trial-and-error circuit is required for campaign progress.

## Validation priorities

Before art, test the graph with minimum permanent abilities and without favorable glyphs. Walk every puzzle state after death, reload, leaving the room, changing water and opening shortcuts in an unusual order. Watch whether new players can name at least two current leads, predict a lever’s effect and remember one opportunity after PULSE. Record repeated empty traversal separately from productive revisits. Successful exploration means players form and revise plans; room count alone does not measure it.

## Sources

1. Wes Fenlon, direct interview with Ari Gibson and William Pellen, [How to design a great Metroidvania map](https://www.pcgamer.com/how-to-design-a-great-metroidvania-map/), PC Gamer, 2017 interview; page resurfaced in August 2025.
2. Christian Nutt, direct interview with Koichi Hayashida, [The Structure of Fun: Learning from Super Mario 3D Land’s Director](https://www.gamedeveloper.com/design/the-structure-of-fun-learning-from-i-super-mario-3d-land-i-s-director), April 13, 2012.
3. Nintendo, [Out now on Nintendo eShop: The Legend of Zelda: A Link Between Worlds](https://www.nintendo.com/en-za/News/2013/November/Out-now-on-Nintendo-eShop-The-Legend-of-Zelda-A-Link-Between-Worlds-836181.html), November 22, 2013.
4. Nintendo, [Metroid Dread Report Vol. 3: Seven points that define the 2D saga](https://www.nintendo.com/au/news-and-articles/metroid-dread-report-vol-3-seven-points-that-define-the-2d-saga/), 2021 pre-release report; exact date not established from retrieved text.
5. Maddy Thorson, [Celeste & Forgiveness](https://www.maddymakesgames.com/articles/celeste_and_forgiveness/index.html), undated developer article.
6. Maddy Thorson, [Level Design Workshop: Designing Celeste](https://www.gdcvault.com/play/1024307/Level-Design-Workshop-Designing-Celeste), GDC 2017; [official recording](https://www.youtube.com/watch?v=4RlpMhBKNr0) published February 27, 2018. Listing examined; detailed video contents not relied upon.
7. John Harris, direct interview with Thomas Mahler, [Q&A: Designing the gorgeous metroidvania Ori and the Will of the Wisps](https://www.gamedeveloper.com/design/q-a-designing-the-gorgeous-metroidvania-i-ori-and-the-will-of-the-wisps-i-), May 18, 2020.
