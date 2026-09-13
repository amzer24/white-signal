# WHITE SIGNAL: exploration, world design and progression

WHITE SIGNAL should become an exploration game about reconnecting a broken public network. Movement abilities should be permanent discoveries. Restoring machinery should change routes, leave visible traces and make previously visited places useful again. Optional equipment can be reconsidered after this foundation works; random drafts should not determine access to the world.

This is a proposed design direction, not a description of a completed campaign. The accompanying **[level atlas](maps/atlas.html)** contains eight district briefs, room connections, three Listening Field alternatives, sixteen reusable blocks and three puzzle state models. Its diagrams describe topology and design intent; they are not collision-ready levels or evidence of playtested reachability.

## 1. Existing foundation and the decision

The current build has three playable relays: the Flats tutorial, Listening Field and the Stand. It already supplies expressive movement, beacons, hit blocks, breakable bricks, conduits and a strong monochrome identity. The campaign proceeds between relays; its boundary save restores entry into the current relay. It does not yet implement freely revisitable districts with durable room-level world state.

The current economy contains ten glyphs. Normal capacity is three in the tutorial and four afterward; Dash and Air Jump each consume two normal slots. The first three relays contain 69 available shards, enough for thirteen five-shard threshold crossings if everything is collected. A filled deck can therefore turn anticipated rewards into unavailable choices. The observed all-locked draft is a symptom of this architecture, although actual pacing varies with collection and build choices.

There are two problems: acquiring everything exhausts the catalogue, while settling on a useful build exhausts meaningful configuration changes. Slower drafts and replacement controls could improve the current run mode. They do not make a discovery meaningful to exploration. The proposed campaign therefore makes the reward answer a spatial question: **what can now be reached, understood or changed?**

| Architecture | Value | Cost | Decision |
|---|---|---|---|
| Permanent toolkit and restored world | Reliable routes, remembered obstacles, lasting discoveries | Requires world-state saving and return connections | Lead the exploration prototype |
| Run-based random builds | Variation, repeated mastery, opt-in risk | Can conflict with reliable access and quiet investigation | Retain as a possible separate challenge mode |
| Permanent toolkit plus optional attunements | Expression without removing essential tools | Adds menus and balance work; may still offer weak choices | Test only after the toolkit-only slice |

The identity constraints remain useful: no HP economy, shops, dialogue trees, colour-only threats or upgrades whose only value is a small statistic. This does not require abolishing the glyph imagery. A protocol can be found in a specific workshop, engraved into the Spark and remembered forever. The discovery screen may resemble a card, but its role changes from repeated shopping to a significant acquisition.

## 2. Lessons from established games

### Geography and opportunity

In a direct interview, Team Cherry describes sketching world connections alongside abilities and later removing many hard gates. Spatial coherence mattered more than arranging interchangeable rooms. A later ACMI interview describes regional architecture as part of the world's relationships and history.[^1][^2] These accounts support purposeful geography; they do not establish a universal Hollow Knight room formula.

For WHITE SIGNAL, the implication is to connect places because their machinery once worked together: a receiver above its pump cellar, a freight lift below the Array and a service cable returning to an earlier district. A branch should lead somewhere with a distinct purpose. Two exits that merely rejoin after equivalent platforms are a route variant, not automatically a meaningful exploration choice.

Nintendo describes Metroid abilities as changing the player's understanding of earlier obstacles; Dread's map also supports markers and matching-icon highlights.[^3] The translation here is to show a roof, sealed maintenance route or inaccessible workshop before its solution arrives. Record discovered opportunities, but do not reveal every hidden room or prescribe a complete route.

### Teaching within exploration

Koichi Hayashida describes introducing a concept, developing it, adding a surprise and testing mastery. The same interview distinguishes Super Mario 3D Land's timed stages from leisurely exploration.[^4] Use that teaching sequence inside a branch or puzzle loop. Do not import a global countdown into a district whose purpose is investigation.

Mario-inspired hit blocks and tunnels can do more than distribute currency. A block can replay an Operator servicing a wall; breaking the marked brick below it can expose a maintenance passage under a familiar room. The route becomes a spatial discovery. Give ordinary bricks consistent responses, and use composition or wear to suggest unusual ones rather than requiring indiscriminate wall checking.

### Movement, builds and iteration

Maddy Thorson's account of Celeste documents generous timing and positioning allowances, including buffered jumps and coyote time.[^5] Preserve WHITE SIGNAL's responsive base movement while testing new routes. Do not sell forgiveness back as mandatory equipment, and do not remove a learned traversal tool after death.

Thomas Mahler describes Ori's paper layouts, polygon blockouts, repeated critique and testing of physics-driven sequence breaks.[^6] Team Cherry's pre-release charm article and Xbox's Ori launch article document optional equipment configurations.[^7][^8] Those systems demonstrate a possible layer of expression, not evidence that WHITE SIGNAL needs one immediately. The first experiment should make exploration rewarding with no random offers at all.

These sources are developer accounts, official documentation or first-party descriptions. They are qualitative design evidence, not controlled evidence that a particular mechanic will improve this game. No commercial room map has been reverse-engineered here, and inaccessible GDC video contents have not been treated as observed evidence. A focused annotated playthrough remains useful before final room production.

## 3. Lore as the structure of the world

Retain the premise that the Signal is coherence: the force that lets a structure hold its form. NOISE occupies abandoned channels and adopts the shapes it consumes. Beacons retain a coherent copy of the Spark. Their restoration is therefore both a checkpoint function and a visible repair to the network.

The Operators built civic infrastructure before they built a defence. The campaign should move through that history. The Flats show patient observation; Listening Field shows maintenance and shared work; the Stand shows emergency alterations; Drowned Array shows resources diverted from civilian systems; the Gate shows intact machinery waiting for a carrier. Repeated connector shapes, numbered supports and service markings establish one civilisation across different biomes.

The central mystery is **why some connections were deliberately severed**. Avoid a final exposition explaining every ambiguity. An intact cable ending at an open isolation switch says something different from a cable torn apart by NOISE. A fourth dish aimed away from its neighbours complicates the objective without adding a fourth compulsory switch.

Each restored project should have three consequences: a functional route change, an identifiable visual or audible change, and evidence about the place. A powered window is strongest when it belongs to a workshop that can eventually be entered. Background architecture then becomes a promise rather than anonymous scenery.

### Story arc: a world that can answer

The [dedicated story study](notes/story-arc.md) recommends a clear emotional arc: **follow a call → understand the deliberate cuts → learn safe reconnection → leave places able to sustain themselves**. The Spark is a newly formed maintenance process, not a forgotten ruler. Its first beacon repair causes one distant workshop window to answer. Reaching that identifiable place gives the opening a concrete motivation.

In the workshop, a replay shows two Operators cooperating on an unfinished repair. The Spark finishes it alone. The room's isolation handle also shows that some silence was deliberate. Stand, Drowned and Wire provide independent evidence: protected shelter, flooded civilian infrastructure and improvised shared maintenance. Their story beats remain understandable in different visit orders.

The midpoint belongs at the first Array-core commissioning, whichever entrance is used. A safe, replayable model circuit demonstrates a branch fault being caught while a neighbouring lamp remains stable. The player routes a healthy feed around the isolated branch. The revelation is that the old distribution arrangement spread failures; reconnecting responsibly needs working local boundaries. Earlier repairs stay beneficial.

The Gate applies those known operations at full scale: latch the three regional feeders into local repeaters, isolate the faulty common return, send a test pulse and commit with a familiar catch. Premature tests identify the incomplete branch and consume nothing. Distinct district responses confirm success; earned routes and abilities remain, and the Spark can return to the workshop to find its repair holding without supervision.

Required understanding appears beside machinery and is confirmed at the Array and Gate. Optional archives add people, disagreement and history without becoming a hidden ending quota. Some restored places remain quiet and dim. The ending preserves useful differences and visible scars rather than washing the whole world white. This proposed arc uses the existing district topology; it adds memory, diagnostic and final-configuration states that still need a prototype.

## 4. Campaign topology

The eight existing relay names become districts. Their old goal verbs remain useful identities, but they no longer define eight consecutive obstacle strips. The atlas separates physical connections from their capability or world-state requirements.

The opening still runs from Flats into Listening Field. From the Listening hub, a workshop branch leads toward Dash and restoration, while a lower service route leads to Drowned Array before all three ears are awake. Drowned's pump project opens a freight lift to the Array and a sheltered connection to the Stand. The Stand offers the Wire route after Dash. These alternatives converge at the Array, then lead to the Approach and Gate.

The Gate requires the three feeder projects—Field, Stand and Drowned—and the Array core. This provides campaign closure without prescribing the order of every visit. Air Jump is acquired along the Drowned restoration route, but its use is optional for the main district connections. It opens upper returns and discoveries; the graph does not require it at every later door. A service return from the Approach reconnects to the Stand, and a late roof route connects the Wire to the Flats.

| District | Main goal and spatial identity | Owned interaction | Persistent reward and return |
|---|---|---|---|
| R0 Flats Line | Reach the first receiver; shallow horizontal tutorial with one visible roof promise | Hit, break, enter a conduit, restore a beacon | First map fragment; later overhead maintenance loop |
| R1 Listening Field | Reconnect three distinct ears around a vertical hub | Selector, lift, mechanical latch; permanent Dash discovery | Hub lift, lit workshop windows, Stand exit; early Drowned lead |
| R2 The Stand | Isolate an unstable storm feed in a ruined defensive ring | Store charge, then discharge it into a bridge motor | Sheltered bridge and feeder; short local collapse trial remains optional |
| R3 Drowned Array | Recover an old service street beneath static-water | Stable water levels and guided floats; Air Jump discovery | Drained main street, freight lift, Stand sluice shortcut |
| R4 The Wire | Repair the carriage between two enormous pylons | Recallable transport and optional dash-refill chain | Fast cross-district travel; later Flats roof return |
| R5 The Array | Reconnect a vertical distribution core | Lift destinations, counterweight and known routing rules | Persistent vertical spine and Approach access |
| R6 The Approach | Trace the original service line to the source | Recombine familiar machinery; bounded optional pursuit | Return connection to Stand; complete feeder overview |
| R7 The Gate | Configure the source using the restored network | Final switchboard using established contracts | World restoration with districts still visitable |

Each district in the atlas has a small room graph and named reward spaces. Those graphs are an architectural starting point, not a target room count. Some nodes may become one room; some landmark vistas may need more space. Only Listening Field is developed to first-slice detail. Later regions should change when earlier playtests reveal better movement and navigation patterns.

### Repair objectives and recoverable parts

Some districts should require finding a specific missing component, but a component hunt should not be the universal stage formula. Alternate repair problems: misconfiguration, dangerous supply, missing hardware, blocked access and an incomplete understanding of the system. This gives exploration different purposes while preserving one coherent machinery language.

| District | Repair problem | Search and action |
|---|---|---|
| Listening Field | Intact but disconnected or misaligned equipment | Solve the catch, align the ear and clear the intake; no extra three-part collection quota |
| The Stand | Unsafe supply | Contain charge and route it into the bridge; no missing key |
| Drowned Array | Missing pump impeller | Use a manual bleed to lower water first, recover the impeller in the exposed street, fit it at the dry pump house, then operate the guided float |
| The Wire | Missing brake assembly | See its empty carriage mount, find a compatible spare in the inspection shelter, fit it and test recall |
| The Array | Misconfigured distribution | Recombine the established catches and selectors; diagnose before adding another item hunt |
| The Gate | An unsafe common return | Apply the restored network and learned isolation rule; no final arbitrary fetch quest |

Show the broken machine and its distinctive empty socket before the part where possible. A familiar silhouette or maker's mark makes recognition satisfying without a quest arrow. The part belongs in a plausible workshop, discarded mechanism or service street. Give its discovery a useful route or historical reveal as well as the object itself.

Recovered parts are unique persistent discoveries. Death does not drop them, inventory has no capacity tax, and they do not occupy ability or attunement slots. The matching machine offers a contextual fit action. Save installation and project state together so a crash cannot consume the part without repairing the machine. A small schematic records found versus fitted; no crafting grid, generic scrap grind or random drop is required.

Drowned's manual bleed is essential to avoid a circular dependency: the missing impeller powers the later lift/float operation, not the first drain needed to reach it. The impeller survives an unfinished basin's low-water reset. Wire's inspection shelter is reachable from either end without needing the broken carriage or an optional glyph. These are part-placement constraints for the graybox, not tested level geometry.

## 5. Listening Field: three alternatives and the recommended loop

**A. Hub and spokes:** retain three clear receiver branches around a central beacon. This is easy to understand and inexpensive to adapt from the current layout, but risks repeated identical returns. Use only if every spoke changes the hub and opens a shortcut.

**B. Braided service loops — recommended:** wrap a workshop loop above the hub and a pump loop below it. An upper lift reconnects the workshop; a lower passage leads into Drowned Array; the receiver causeway joins both loops. The player can form a plan, change it and arrive back at a landmark from another direction.

**C. Basin descent:** organise most rooms around a tall drained reservoir with upper and lower routes. It offers a strong reveal and water-state reinterpretation, but places new camera, water and save requirements on the first exploration experiment. Reserve this structure for Drowned Array.

The recommended Listening graph contains eleven named spaces. Arrival Bowl establishes the three-ear silhouette. Triangulation Hub offers a visible workshop stair and a pump descent. West Workshop introduces machinery in a safe room; Ballast Gallery develops its selector-and-latch puzzle; Upper Amplifier contains permanent Dash. Counterweight Return descends toward East Causeway and opens a direct lift back to the hub. Its causeway door and hub lift are initially closed from below and opened from the return side; the upper workshop route requires the completed west ear. This prevents reversing the return loop to bypass the first puzzle. Pump Cellar and Drain Lookout expose the lower service network. Transmitter Sump collects the completed ear feeds and leads toward the Stand. The Fourth Dish is a later optional archive reached with Air Jump.

The three ears should ask different questions. The west ear needs a mechanical catch so power can be rerouted. The east ear needs its physical receiver head aligned through a visible opening. The south ear needs a blocked intake cleared with the established brick interaction. These are provisional interactions sharing the same infrastructure language; avoid making each a new control tutorial.

The first build should include only the hub, workshop, ballast gallery, amplifier, return lift and a lower lookout. It can demonstrate two leads, one permanent ability, a meaningful puzzle, an archive and a recognisable return without constructing the entire campaign. The lower boundary can show the Drowned destination while clearly identifying it as beyond the slice. A 10–15 minute first visit is a playtest hypothesis, not a production estimate or enforced timer.

## 6. Puzzle contracts

All machinery uses a small vocabulary: **source → cable → selector → receiver → latch**. Power is temporary; a completed latch is durable. Conduits carry the player and have different mouths from power cables. A lamp illuminates; a shield protects and has a distinct housing and boundary.

### Borrowed Current — Listening Field

One selector supplies either a lift or an ear receiver. The lift can rise under power but initially falls back when power is diverted. The player rides it to a reachable manual safety catch, engages the catch, which also unfolds a permanent service stair, then returns by that stair to divert power. The stair is folded away initially so it cannot bypass the lift lesson. The lift stays latched while the receiver comes alive. The insight is the distinction between supplying motion and retaining a completed state.

The machine, both outputs and the catch are visible within the gallery. The player never needs a newly invented remote Pulse ability. Dash is found beyond the completed receiver route and used immediately on a safe upper bypass before being offered a remembered optional gap. Falling returns to the selector floor; no crushing volume is required. Resetting the selector must never erase a completed catch or refold its service stair. Before the catch is engaged, falling reaches the safe control floor; afterward, the unfolded stair gives access in both directions even while the lift is retained above. The permanent reward is both Dash and a lift back to the familiar hub.

### Stored Storm — The Stand

A conductor gathers charge into a visible reservoir. The player selects the reservoir output, waits in a protected observation bay, then diverts stored charge into a bridge motor. A gauge and rod movement communicate readiness. The reservoir holds its charge, so the puzzle asks for understanding rather than catching a brief lightning frame.

Ambient lightning is independent of machine timing. The discharge event has a deterministic advance cue and a marked channel; reduced-flash mode uses the same gauge and steady light. The bridge latches open permanently. Death resets an unfinished charge to neutral, but never closes a completed bridge. A nearby optional trial can later add pressure after the rule is understood.

### Street Beneath the Static — Drowned Array

The main basin has marked high, middle and low states. Fixed dry stairs and pump controls remain reachable at every level. The first drain uses a manual bleed, so it works before the missing pump impeller is recovered. Lowering the basin reveals the old service street, its recoverable impeller and the Air Jump gallery. Fit the impeller at the dry pump house before powering the guided float. A guided float in a separate chamber rises to an upper maintenance landing; opening its return conduit gives a new route to the rim.

The insight is that lowering a surface reveals one route while raising a carrier provides another. Opening the upper conduit is the project completion trigger: it leaves the main street drained, opens the shortcut and enables the freight lift. The dock does not contain a second conflicting completion trigger. Death or reload before completion resets the basin to low and respawns at a fixed dry anchor; Air Jump remains acquired. The dry control stair always provides an exit from the exposed gallery, even while the water level changes. Repeating timing challenges belong in a separate cycling basin, so returning through the district does not require replaying the full water puzzle. Until a controller test establishes otherwise, static-water is treated as a hazard with clear boundaries; no swimming system is assumed.

### Rules shared by every puzzle

Put the first control and its effect on the same screen. For later remote mechanisms, show connected cables or pipes, directional pulses and a local state indicator. Provide a reachable reset or recall control for every reversible machine. Do not consume a unique reward before its persistent completion flag is saved. Necessary clues must remain available or be replayable; historical images must not conceal lethal collision changes.

## 7. Blocks and movement geometry

The atlas supplies sixteen reusable blocks: reveal-and-loop, elevated promise, visible switch-result, counterweight loop, memory archive, power router, sluice pair, storm capacitor, dash repeater, freight shaft, return mastery, choice/convergence, wall-kick shaft, maintenance ladder, trip plate and actuator crossing. They are reusable relationships, not prefabs to scatter without regard to place. Each has a required capability, safe exit, reward purpose and a corresponding asset family.

Use the current 480×270 logical view as the planning unit. Current controller values include 135 px/s base run speed, 325 px/s initial jump velocity, 920 px/s² gravity and a 340 px/s dash lasting 0.13 seconds. Idealised jump height is approximately 57 px and nominal dash travel about 44 px. These calculations do not certify a gate: acceleration, collision, jump release, wall interactions and discrete updates change actual reach.

Start ordinary teaching steps around 28–40 px and provide generous landing surfaces, then measure them in the real controller. Do not mark a narrow gap “Dash required” because it looks large in an SVG. Every intended ability gate needs a minimum-tool playthrough and a sequence-break attempt. A topology can be reachable in a simulation and still be impossible in the game.

Vertical shafts also require camera and room-transition work. Do not simply stretch the existing horizontal strip. Give entry previews, safe camera settling points and landings visible before commitment. A checkpoint should precede a new hazardous rule, while a completed shortcut should shorten repeated travel after success.

### Climbing, traps and hazard progression

Climbing should be a substantial part of exploration. The current controller already has wall slide and wall kick; these can support vertical service shafts without inventing another upgrade. Start with a short safe shaft, add offset resting ledges, then let Air Jump reveal an optional roof return. Maintenance ladders are a proposed contextual interaction, not an implemented feature. Ledge grabbing and unrestricted surface climbing remain separate movement experiments: automatic grabbing can interrupt the existing dash and wall-kick feel.

Traps should express machinery and its failures. Establish the harmless rule before adding danger: a pressure plate first opens a shutter while its cable and destination are visible. A later plate can open an optional timed archive door, with an unconditional exit inside. Taking an archive may start a clearly signalled local escape, but never erase the reward on failure or make every discovery feel like a punishment.

| District / placement | Climbing route | Trap or hazard proposal | Teaching and recovery |
|---|---|---|---|
| Flats, Survey Shelf | Short wall-kick recess and roof visible above | Shallow fall with safe catch; later a single clearly marked crumble | Learn the warning without a lethal first surprise |
| Field, West Workshop / return shaft | Wall-kick service shaft; optional ladder trial | Harmless plate-shutter demonstration; optional closing-door remix | Catch floor, visible destination and unconditional exit |
| Stand, Conductor Bay / Fracture Trial | Braced climbing bays with rest shelves | Deterministic discharge channel and optional collapsing walkway | Watch from shelter; checkpoint and completed bypass |
| Drowned, Float Chamber / Cycling Basin | Guided carrier and Air Jump return | Marked static-water; optional bounded rising-water trial | Fixed dry control stair, recall and low-water reset |
| Wire, Inspection Shelf / Repeater Crown | Pylon rests and optional refill ascent | Exposed falls and visibly damaged optional cable platform | Intermediate catch shelves; carriage becomes safe return |
| Array, Instrument Loft side branch | Wall-kick shaft beside a visible counterweight | Piston sweep or closing brace, not an invisible crush check | Safe inspection recess; explicit warning, travel and dwell states |
| Approach, Swarm Bypass | Familiar shaft with a shorter mastered return | Optional bounded NOISE pursuit | Clearly entered trial; failure reset; permanent completion shortcut |
| Gate, Feeder Ring | Short familiar vertical transitions | Final remix of an established discharge rule if playtesting warrants it | No new hazard language or surprise finale ability |

Hazard state must be separate from weather and decoration. Define each as idle, warning, active and recovery, with the collision change attached to an explicit gameplay event. A piston needs a stable swept-area cue, predictable movement and a safe reset; detailed crush resolution is an implementation dependency. Do not make decorative cloud wind alter air control. If a mechanical gust is later tested, give it a visible duct, fixed cycle and independent wind-off assist evaluation.

Do not combine the first lesson in darkness, a new climb and an unfamiliar trap. Introduce one uncertainty at a time, then combine established rules in optional mastery spaces. Stable outlines, physical poses and sound-off equivalents must communicate danger. Check return travel too: an old trap can become inert after restoration, turning the player's success into a faster, safer route.

## 8. Light, colour and weather

Separate three functions. **Atmosphere** includes distant storms and subdued depth layers. **Evidence** includes restored windows, memory artwork and visible old construction. **Mechanics** includes a powered receiver, a shield or a conductor. A beautiful lighting effect must not silently change the rules of a visually identical object.

Retain the grayscale luminance hierarchy and test small accents as recovered material: ochre ceramic in the Flats, amber filaments in Listening, slate storm light in the Stand, green-gray substrate in Drowned and pale copper clamps on the Wire. Colour should express regional identity and restoration, not encode safety. Compare grayscale, local accents and broad tinting in the same room before selecting a direction.

Microsoft's accessibility guidance calls for additional channels for important visual and audio information.[^9] Encode circuits with plug shapes, line patterns and instrument motion. Confirm restoration through mechanism position and map state as well as light. Preserve player and landing readability with audio muted, colour removed and ambient effects disabled.

For lightning, use a restrained local sky reveal and slow release as a starting art hypothesis. Avoid repeated full-screen inversion. Reduced-flash mode substitutes a steady cloud glow; disabling decorative flashes does not affect the conductor puzzle. Photosensitivity guidance also covers high-contrast patterns and combined effects, so a toggle or a chosen flash frequency is not proof of safety.[^10] Review storm, dash, death, memory and NOISE effects together before release.

Thunder should establish distance and shelter. It must not be the only lethal countdown. A critical discharge has its own rod animation, gauge and optional descriptive caption. Godot supports separate audio buses and spatial attenuation; wall occlusion still needs authored treatment rather than being assumed automatic.[^11][^12] Keep weather, mechanisms and critical cues separately adjustable so increased rain does not bury instructions.

The current Afterlight prototype darkens background artwork with a shader; it does not establish native dynamic shadows. Compare native lights and occluders against an authored quantized mask in the same room. Keep collision, activation and save state independent of rendered brightness. The campaign can then support reduced effects without creating a different puzzle.

### Effects shortlist

The dedicated [effects study](notes/effects.md) examines nine specific community or native-engine candidates. It records author pages, stated code licenses, compatibility evidence, adaptation needs and an order for testing. None has been compiled or benchmarked in this project.

Start with a sprite-local reconstruction dissolve, a small material palette change and one beacon-light comparison. Together they can express a lasting restoration without adding a new traversal rule. Texture fog comes next; a roof shaft is justified only when it explains architecture. Conductor lightning follows a working charge puzzle, and static-water follows a working basin state model.

The shortlist also identifies integration traps: shader time may continue while gameplay is paused; screen-reading effects do not automatically compose with one another; a community Godot 4 label does not establish compatibility with this project's exact renderer.[^14][^15] Prefer bounded local effects with an explicit event progress, persistent final artwork and a reduced-effect equivalent. Full-screen VHS distortion, constant colour splitting and repeated white inversions are poor defaults for the movement and silhouette language.

## 9. Assets and parallax production

The generated backgrounds currently belong to the optional Afterlight room. They are not integrated into ordinary campaign relays. Campaign adoption needs composition, contrast and landmark checks, not simply enabling those planes everywhere. The staged background and draft experiments are not part of this design baseline.

Produce independent complete far, middle and near planes. Do not slice a flattened image: moving the layers exposes missing artwork. Tile only texture families that can plausibly repeat, such as distant terrain, secondary ruin masses or cables. Keep the three-ear landmark, the broken defensive rim and the source aperture as separate, non-repeating assets.

Godot's parallax documentation explains repeat size and scroll relationships; it does not make imperfect image edges seamless.[^13] Every export needs a three-copy seam board, matching top/bottom placement where relevant, transparency checks on light and dark backgrounds, and bidirectional in-engine scrolling across at least two periods. Judge readability at 480×270 while the player moves. Generation prompts are provenance, not quality assurance.

| Package | Required deliverables | Completion evidence |
|---|---|---|
| Region planes | Far/mid/near images; dimensions, origin, repeat period, scroll factors, alpha policy | Seam board and moving-camera capture |
| Landmark | Distant silhouette, middle view and arrival treatment with matching identity | Recognisable from two routes without a label |
| Room kit | Floors, walls, ceilings, corners, supports, back walls and boundary variants | No decoration mistaken for a required platform |
| Mechanism kit | Dormant, available, operating, completed and blocked states as applicable; pivots and anchors | State readable in grayscale and without audio |
| Memory kit | Registered past/current artwork, persistent clue, replay trigger | Clue remains obtainable after reward collection |
| Lighting kit | Pools, masks or occluders, cue exclusions, reduced-effect equivalents | Landing and enemy-tell parity in all modes |
| Audio kit | Loopable region bed, shelter variant, mechanisms, weather, critical cues and caption keys | No clipped loops; critical cues survive loud ambience |

The first asset order should cover only Listening's representative room and its two boundary views. Finish all states of one lever and one lift before generating dozens of biome illustrations. Defer a full eight-biome image batch until the graybox establishes camera coverage, layer origins and actual room composition.

## 10. Persistence and implementation boundaries

Permanent abilities, unique discoveries, opened shortcuts, completed feeder projects and visited map rooms survive death and reload. NOISE and short combat encounters can reset. Unfinished temporary machine states reset to an explicitly safe configuration; completed latches do not. Recall controls recover lifts and floats regardless of which checkpoint the player returns from.

This needs stable district, room, object and spawn-anchor IDs; a versioned save schema; atomic save replacement; and restoration ordering that cannot respawn a player inside changed collision. Saving the old relay number plus deck is insufficient. Prototype exploration in a separate save/profile path so existing run saves remain available. Design migration only after the new state contracts and traversal graph are tested.

The atlas's world-state toggles are a dependency illustration. They deliberately allow arbitrary combinations for inspection, and are not a save implementation. Likewise, the puzzle step buttons enumerate authored states rather than proving physical escape from those states. Validate each in Godot after blockout.

## 11. Build sequence and acceptance

1. **World-state foundation:** a separate exploration profile, two-way room transitions, stable spawn anchors and one saved shortcut. Validate death and quit/reload on both sides of that shortcut.
2. **Listening graybox:** hub, two leads, Borrowed Current, permanent Dash, a remembered opportunity and return lift. Use existing art and controller; suppress random drafts only in this prototype mode.
3. **Navigation playtest:** observe players without route coaching. Record what they think their leads are, which reward they remember, whether they recognise the shortcut, and where camera or geometry causes confusion.
4. **Lighting and mechanism slice:** one memory, local restoration accent, sheltered thunder and reduced-flash parity. Compare readability with ordinary illumination before committing the art direction.
5. **Drowned and Stand trials:** prove water-state escape and stored-charge clarity independently. Only then connect them to the Field and consider later districts.
6. **Optional attunement experiment:** compare toolkit-only play with free beacon configuration. Keep it only if players express meaningful competing choices that do not compromise learned movement.

Acceptance is behavioural: players can identify two useful leads; predict the first lever's effect after its demonstration; use Dash on a remembered opportunity; recognise their return location; and recover after death or reload without lost discoveries or a trapped state. These are evaluation questions, not claims that testing has passed. Record hesitation and repeated empty traversal, not just completion times.

Before final art, audit every required route without optional glyphs or shard collection. Exercise unusual region order, Air Jump acquired before Dash, death during each machine transition, leaving an unsolved room, reload after a latch, and returning from a later checkpoint. A successful sequence break may be welcomed; a one-way arrival without an exit is a defect.

## 12. Open decisions

The evidence supports testing exploration first; it does not settle the final campaign length, number of rooms, exact light renderer, optional loadout system or production budget. Permanent Dash and Air Jump are deliberately conservative proposals using existing movement. New light-routing abilities such as Pulse or Anchor should compete in later small prototypes rather than becoming assumed requirements across the map.

The highest-value next deliverable is a small playable place that remembers its restoration. Further source work should annotate a few complete commercial exploration loops and observe their returns in play. That remains distinct from the completed developer-account research and the original layouts in this report. Expand the campaign only when the first slice demonstrates that curiosity, machinery and movement reinforce one another.

## Sources

[^1]: Wes Fenlon, direct interview with Ari Gibson and William Pellen. [How to design a great Metroidvania map](https://www.pcgamer.com/how-to-design-a-great-metroidvania-map/). PC Gamer; 2017 interview, resurfaced August 2025.
[^2]: Jini Maxwell, direct interview with Team Cherry. [From Ludum Dare to Pharloom](https://www.acmi.net.au/stories-and-ideas/from-ludum-dare-to-pharloom/). ACMI, 5 September 2025.
[^3]: Nintendo. [Metroid Dread Report Vol. 3: Seven points that define the 2D saga](https://www.nintendo.com/au/news-and-articles/metroid-dread-report-vol-3-seven-points-that-define-the-2d-saga/). 2021 pre-release report; exact publication day not established.
[^4]: Christian Nutt, direct interview with Koichi Hayashida. [The Structure of Fun: Learning from Super Mario 3D Land's Director](https://www.gamedeveloper.com/design/the-structure-of-fun-learning-from-i-super-mario-3d-land-i-s-director). Game Developer, 13 April 2012.
[^5]: Maddy Thorson. [Celeste & Forgiveness](https://www.maddymakesgames.com/articles/celeste_and_forgiveness/index.html). Undated developer article.
[^6]: John Harris, direct interview with Thomas Mahler. [Q&A: Designing the gorgeous metroidvania Ori and the Will of the Wisps](https://www.gamedeveloper.com/design/q-a-designing-the-gorgeous-metroidvania-i-ori-and-the-will-of-the-wisps-i-). Game Developer, 18 May 2020.
[^7]: Team Cherry. [Revealing the Power of the Charms](https://www.teamcherry.com.au/blog/revealing-the-power-of-the-charms). Pre-release article; displays February 23 without an established year. Historical design evidence, not a current item database.
[^8]: Xbox Wire. [Ori and the Will of the Wisps Available Now](https://news.xbox.com/en-us/2020/03/11/ori-and-the-will-of-the-wisps-available-now/). 11 March 2020; launch-body equipment description used.
[^9]: Microsoft. [Xbox Accessibility Guideline 103: Additional channels for visual and audio cues](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/103). Updated 4 March 2026.
[^10]: Microsoft. [Xbox Accessibility Guideline 118: Photosensitivity](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/118). Updated 4 March 2026.
[^11]: Godot Engine. [Audio buses](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html). Stable documentation, accessed 13 September 2026; living reference.
[^12]: Godot Engine. [AudioStreamPlayer2D](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer2d.html). Stable class reference, accessed 13 September 2026; living reference.
[^13]: Godot Engine. [2D parallax](https://docs.godotengine.org/en/stable/tutorials/2d/2d_parallax.html). Stable documentation, accessed 13 September 2026; living reference.

[^14]: Godot Engine. [CanvasItem shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html). Stable documentation, accessed 13 September 2026.
[^15]: Godot Engine. [Screen-reading shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html). Stable documentation, accessed 13 September 2026.

Project evidence: current `js-original/GDD.md`, `docs/BACKLOG.md`, campaign data and controller constants; existing `docs/research/lighting-darkness.md`, `parallax-tiles.md` and `afterlight-results.md`. The accompanying topic notes retain additional alternatives and source limitations. Where a note differs from this synthesis, the concrete atlas and this report define the recommended prototype; alternatives remain unapproved experiments.
