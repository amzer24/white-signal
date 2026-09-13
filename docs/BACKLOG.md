# WHITE SIGNAL backlog

## Research: lighting, darkness and the readable world

Status: initial cited research and an optional Afterlight prototype delivered
13 September 2026. Enter with L from the title screen. See
[lighting findings](research/lighting-darkness.md),
[tile research](research/parallax-tiles.md) and
[prototype evidence](research/afterlight-results.md).
The brief below remains the evaluation target: participant playtesting, native
shadow comparison, strict four-gray finishing and campaign adoption are pending.

Question: how can light become a rule of the relay world, as well as its art direction,
while preserving the monochrome silhouettes and fair, fast platforming?

Investigate primary developer talks, breakdowns and footage from INSIDE/LIMBO,
Hollow Knight, Ori, Rain World, and Mario's ghost houses. Distinguish documented
developer intent from our interpretation. Study navigation, contrast, environmental
storytelling, moving light, occlusion, and the danger of hiding collision edges.

Experiments to compare:

- **The last lamp:** a moving service lamp reveals a safe crossing; leave its pool
  to collect optional shards. Required landing edges retain a faint outline.
- **Afterlight:** striking a memory block briefly restores the room's old lighting,
  revealing an abandoned workstation and a route. Does memory reveal history,
  collision, or both? Start with visual history only; test collision separately.
- **The listening dark:** footsteps wake luminous NOISE; standing still dims the
  Spark. Compare atmosphere against the cost of discouraging fluid movement.
- **Beacon islands:** restored repeaters light connected windows and guide the
  return journey. Darkness between them expresses distance from the network.
- **A shadow that remembers:** an inactive machine casts the shadow of its former,
  intact shape. The mismatch points toward a secret maintenance conduit.
- **Inverted source:** the Gate is overwhelmingly bright; NOISE reads as absence.
  Reserve this reversal for a legible, carefully tested late-game reveal.

Deliverables for the research session:

1. A cited reference board with annotated stills and a recommendation grounded in
   WHITE SIGNAL's existing four-gray palette, 480×270 canvas and dither materials.
2. Three distinct art-direction proposals with gameplay consequences and costs.
3. A Godot feasibility comparison: CanvasModulate + PointLight2D/occluders versus
   a quantized shader mask. Check pixel stability, moving-camera shimmer, shadows,
   renderer compatibility, and frame cost on target hardware.
4. One 60–90 second test room comparing ordinary illumination, authored darkness,
   and the readability assist. No campaign-wide lighting rewrite before evaluation.
5. An accessibility pass: no essential cue conveyed only by brightness, no hidden
   lethal geometry, adjustable darkness, reduced flashes, and clear player tracking.

Success: players can identify their next landing and the source of each death;
lighting makes the place and its history more memorable without becoming a visual
tax. Document failures as well as attractive screenshots.

## Campaign follow-through

### Priority research: exploration and deep level design

Status: developer-account research and original design atlas delivered 13 September
2026. Direction selected: exploration first, with lasting abilities, discoveries
and interconnected places. See [design report](research/exploration/EXPLORATION-DESIGN.md),
[level atlas](research/exploration/maps/atlas.html) and
[effects shortlist](research/exploration/notes/effects.md).
The atlas proposes eight districts, 55 named spaces, three Field alternatives,
sixteen reusable blocks and three puzzle models. These are design artifacts;
commercial map/playthrough annotation, a playable graybox and participant
validation remain pending. The current game and saves are unchanged.
Complete before expanding R3–R7 into finished campaign levels. The current strips
are mechanic prototypes; their straightforward routes are not the target quality.

Question: how do we make each relay a place the player learns, explores and changes,
with meaningful route decisions, rather than a longer sequence of obstacles?

Use Hollow Knight as the main exploration reference; compare relevant approaches
from Super Metroid, Ori, Rain World, Celeste and Mario's secret exits and sub-areas.
Research developer accounts and inspect actual room maps/playthroughs. Separate
documented design intent from our interpretation; the selected exploration direction requires a separate persistent-world prototype;
the current run-based deck is a legacy mode, not a constraint on every discovery.

Investigate:

- Room graphs with loops, intersecting paths, vertical shafts, hubs, one-way drops
  and shortcuts that reconnect somewhere recognisable. Give detours a purpose.
- Visible but initially unreachable destinations, foreshadowed secrets, alternate
  entrances and landmarks that let players form a mental map without constant UI.
- Distinct goals beyond reaching the right edge: restore a local circuit, find a
  missing protocol, reroute power, infiltrate a receiver, escape through a shortcut.
  Tie the goal and the room's former function to the Signal/coherence fiction.
- Ability gates, knowledge gates and skill routes. Compulsory progression must
  remain possible without a randomly drafted glyph; builds may change the route,
  risk or reward. Compare temporary repeaters with permanent traversal abilities.
- Reward placement and discovery: secrets, optional challenges, environmental
  stories and build opportunities. Avoid empty branches and mandatory backtracking
  that only adds travel time; returning should reveal or change something.
- Tension and recovery across rooms, checkpoint placement, failed-exploration cost,
  encounter sightlines, and how speed-focused movement coexists with curiosity.
- Mario-inspired hit blocks and conduits as spatial tools: entrances beneath a
  familiar room, concealed connections, alternate exits and routes that fold back.
- Lighting and parallax that communicate depth, destinations and history without
  making decorative architecture look like traversable or lethal geometry.

Deliverables:

1. A cited, annotated reference study of selected areas and their room graphs,
   explaining how route choices, reveals and shortcuts work in play.
2. A WHITE SIGNAL design grammar and an explicit decision on exploration within
   relays versus backtracking across relays, including persistence/save consequences.
3. Three alternative room graphs for one existing relay, with critical path,
   optional loops, vertical movement, secrets, gates, rewards and lore beats marked.
4. A playable graybox of the strongest graph, evaluated before committing final art.
   Record navigation confusion, discoveries, route diversity, deaths, revisit value
   and whether players understand their current goal.
5. Revised level sheets: each relay has its own spatial identity, player goal,
   mechanic progression and memorable reveal. Keep the tutorial deliberately simple.

Acceptance: players can choose and explain different useful routes, recognise a
shortcut when it reconnects, discover a worthwhile optional space and understand
why the place exists. More platforms, enemies or length alone do not qualify.

- Playtest R1's hub/spokes and R2's pressure pacing with unmodified and cursed builds.
- Introduce SKIP and CLING alone before adding them to authored combinations.
- Hold glyph replacement and slower-draft experiments. Prototype permanent Dash
  and Air Jump discoveries plus persistent routes before deciding whether optional
  attunements earn a place. No essential traversal should depend on random offers.
- Prototype R3 stable basin states, dry escape routes and saved completion before
  optional cycling-tide challenges. Do not apply a global exploration timer.
- Treat old R4–R7 strip sheets as encounter material. Use the exploration atlas
  for revised district goals, return links and world-state dependencies; test each
  graybox before final art. Pulse/Anchor and other new traversal verbs remain deferred.
- Investigate atomic boundary saves and version migrations before external release.


## Effects research and prototype backlog

Status: nine candidates researched, none imported or benchmarked. See
[effects study](research/exploration/notes/effects.md) for exact GodotShaders
references, licenses, compatibility evidence and adaptation constraints.

1. Listening restoration: pixel reconstruction, small recovered-material palette
   change, and native-light versus authored-mask comparison on one beacon/window.
2. Depth: compare a texture fog shader with a simple scrolling layer. Add one roof
   shaft only if it helps explain architecture and preserves mechanism cues.
3. Stand: local conductor lightning driven by the stored-charge state machine;
   independent distant thunder and a steady reduced-flash equivalent.
4. Drowned: restrained static-water visuals after basin collision and escape work.
5. Validate actual renderer compatibility, pause/reload clocks, combined effects,
   screen-copy order, seam motion, cue parity, frame cost and source provenance.

Do not adopt full-screen distortion or a batch of showcase shaders as the default
style. Generated Afterlight backgrounds still require deliberate campaign art
integration. Preserve completed routes and discoveries independently of effects.


## Traversal, traps and hazards

Planned explicitly in the exploration report and atlas. Reuse current wall slide
and kick for safe vertical service shafts. Test contextual ladders independently;
ledge grabbing and free climbing are not yet selected movement changes.

- First slice: wall-kick shaft, catch floor, rest ledges and harmless pressure plate
  connected visibly to a shutter. Later timed variants always have an exit.
- Stand: conductor discharge and bounded optional crumble trial.
- Drowned: guided floats, static-water marks and safe low-water resets.
- Wire: exposed optional route with catch shelves and permanent carriage bypass.
- Array: optional piston crossing with preview, warning and safe recess; test crush
  resolution before allowing it near a required route.
- Approach: bounded optional pursuit, saved completion shortcut and retry point.

Do not introduce a new hazard, new climb and darkness together. Completed repairs
may disable old traps to make returns safer. Weather visuals never set collision.


## Story arc and environmental narrative

Status: dedicated primary-source story study delivered; proposed arc integrated
into the atlas. See [story study](research/exploration/notes/story-arc.md).

- Opening: follow an unanswered maintenance call to an identifiable workshop.
- Regional discoveries: deliberate isolation, protected shelters, diverted water
  and shared maintenance; evidence works in alternate visit orders.
- Midpoint: first Array commissioning demonstrates containing a branch fault.
- Finale: connect restored local repeaters, isolate the faulty common return,
  test and commit. Repairs, abilities and the explorable aftermath persist.
- First slice: one window seen, reached, repaired and recognised on the return;
  replayable cooperation memory and an intentionally disconnected handle.
- Required next evidence: player motivation, clue recall, alternate entrance and
  skipped-memory tests; no hidden archive quota or mandatory sacrifice ending.


## Repair discoveries

Use specific recoverable parts in selected districts, not identical collection
quotas everywhere. Proposed: Drowned pump impeller in the manually drained street;
Wire brake assembly in an accessible inspection shelter. Field/Stand use
configuration/supply problems; Array/Gate use learned routing and isolation.

Show broken mount before part where possible. Parts persist through death, consume
no ability slots and use contextual fitting. Save consumption and installation
atomically. Audit that the first drain works without the impeller and the Wire
spare is reachable without the carriage or a random movement glyph.
