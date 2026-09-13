# WHITE SIGNAL — places that remember the player

Research notes, 13 September 2026. Scope: exploration-first world art, environmental interactions, weather, accessibility and production needs. This develops the earlier lighting and parallax reports; it does not edit the game or claim the proposed campaign exists. GDD v8 §7d's eight timed relays are historical design input, not the current recommendation.

## 1. Make environmental change a discovery reward

The central proposal is a world of abandoned public infrastructure: receivers, maintenance passages, storm reservoirs, cable routes and a source machine. The Operators' absence appears in how these places were used. The player's growing ability to understand and operate them is progression. A newly acquired verb should reveal possibilities in remembered places and remain available after death; temporary deck variation must not revoke access to the explored world.

Restoration should leave specific traces: a lift now connects two known rooms, a drained basin exposes an earlier survey marker, and the beacon windows seen from the Flats correspond to a workshop reached much later. Prefer transformations that shorten revisits or reveal history to transformations that simply brighten everything. Darkness, colour and sound become evidence of state, not a replacement for state.

Team Cherry describes following the logic of a place rather than only sequencing ability locks. Their direct ACMI interview also explains how the Citadel's architecture appears in outposts and exploited regions, and how a calmer introductory space developed into a broader ecological relationship. Our translation is a consistent Operator construction language across places with different purposes, then visible regional adaptations. This is an inference, not a copied campaign structure. [ACMI, **From Ludum Dare to Pharloom**, Jini Maxwell interviewing Ari Gibson and William Pellen, 5 September 2025](https://www.acmi.net.au/stories-and-ideas/from-ludum-dare-to-pharloom/).

## 2. Separate atmosphere, evidence and mechanics

| Element | Atmosphere | Meaningful interaction | Required contract |
|---|---|---|---|
| Distant lightning | Reveals a huge broken receiver silhouette. | None; the effect can be disabled. | Never changes unseen collision or hides an enemy tell. |
| Storm conductor | Nearby rods bend and a gauge advances. | Player routes charge into a lift or discharge channel. | Predictable warning, safe observation point, repeatable attempt. |
| Memory illumination | Earlier furniture appears behind current ruin. | Points to a maintenance route. | Necessary route markings persist or memory can be replayed. |
| Colour returning | Old ceramic material becomes distinguishable. | Confirms a restored district. | Shape, mechanism position and map state also confirm it. |
| Thunder | Suggests open distance and approaching weather. | A machinery rhythm may forecast an event. | Sound-off cue conveys the same actionable timing. |

Do not make ordinary light imply safety while some other visually identical pool kills. A lamp illuminates; a shield protects. Give shielding a separate housing and stable boundary. Similarly, a lever that changes a route must visibly connect to that route through cable, shaft, pipe or a short view of the result. Mystery belongs in the world's history; interaction affordances should be dependable.

## 3. Eight places, revised as interconnected districts

These are original visual/mechanical proposals retaining familiar names. Timed sequences become local optional challenges or short authored climaxes, not the default state of an entire exploration district.

| District | Visual grammar / accent proposal | Lasting discovery and return value |
|---|---|---|
| **Flats Line** | Long horizontal salt plates; half-buried dishes; broad empty sky. Neutral gray, then a trace of ochre ceramic at the first restored station. | A hand-operated shutter reveals the route map carved into a receiver. Later, a cable ability opens its overhead maintenance loop. |
| **Listening Field** | Dish bowls, survey posts, three distinct receiver silhouettes. Deep negative space between clusters; quiet amber filaments. | Orient receivers to reconnect spokes. Each receiver lights a different recognisable window pattern. A fourth failed dish contains a personal archive rather than another mandatory switch. |
| **The Stand** | Braced diagonals, broken rim bridges and improvised barricades. Slate-blue storm atmosphere, achromatic playable edges. | Isolate a storm feed, lift a fallen brace and open a permanent sheltered return. Collapse trials occupy side rooms; reading an archive never accelerates district failure. |
| **Drowned Array** | Low horizontal bands, drowned masts, strong vertical depth markers. Muted green-gray substrate beneath black static. | Reroute sluices into a stable low-water state that exposes an old service street. A separate cycling basin teaches timing without repeatedly blocking the main return path. |
| **The Wire** | Huge emptiness, sagging cables, hand-numbered pylons. Cloud layers stay subdued; small pale copper clamps. | Restore a cable carriage and connect distant districts. Its first traversal has sheltered inspection platforms. A continuous momentum run is an optional high route. |
| **The Array** | Tall shafts, repeated ceramic ribs and counterweights. Warm internal instrument light against cold exterior slit windows. | A routing ability changes lift destinations and preserves a new vertical connection. Charged walls use moving clamp teeth, not brightness alone, to show whether they hold. |
| **The Approach** | Old structures compressed around the source; cables accumulate, not arbitrary spikes. Light leaks beneath heavy doors. | Reveal a short route back to the Listening Field, confirming the network's geography. Any swarm escape is bounded and replayable, with no forced chase during exploration. |
| **The Gate** | Sparse, oppressive symmetry; a single source aperture. Pale luminous background with dark readable figures in a carefully tested reversal. | Reconfigure the source using already learned interactions. Restored districts remain visitable. The meaning of restoration can stay ambiguous without removing the player's earned routes. |

Give neighbouring districts shared boundary rooms: a salt floor beneath a ruin roof, a receiver cellar at the basin's high-water line, a cable arriving at the Array's loading dock. These transitional rooms explain adjacency better than a full-screen biome tint applied at an invisible boundary.

## 4. Colour as recovered material

Keep the four-gray luminance hierarchy as the base. Introduce one subdued accent family per district, initially on small material patches: enamel, oxidised copper, faded survey cloth. Restoration reveals the original surfaces; it does not paint all interactables neon. Avoid globally equating green with safe or red with danger. A monochrome option should retain all puzzle information.

Initial art test: compare grayscale, tiny local accents and broad tinting in the same room. Ask players to identify district, exit, hazard and mechanism state. Keep accent only if identity improves without reducing those readings. A screen-area cap for colour can help art review, but it is an internal tuning choice, not an accessibility standard.

Microsoft recommends multiple sensory channels for important information and explicitly rejects colour as its sole carrier. It also cautions that colour-vision simulations do not replace testing with players. Apply that to coloured cables: give circuits distinct plugs, line patterns and instrument tones. The player must distinguish them in grayscale, with audio muted and with haptics unavailable. [Microsoft, **Xbox Accessibility Guideline 103: Additional channels for visual and audio cues**, updated 4 March 2026](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/103).

## 5. Levers and remembered lighting

A reusable interaction grammar can carry substantial variety:

- **Lever:** two deliberate positions, visible pivot and an audible mechanical latch. State persists; an open route stays open unless reversibility is the room's explicit puzzle.
- **Router:** a rotary selector with two or three labelled-by-shape destinations. Preview connected machinery before confirming. Prevent states that imprison the player.
- **Memory block:** strike from beneath to replay a local historical arrangement. A consumed reward must not make the lore permanently unviewable.
- **Conduit:** a recessed mouth with the established down chevron; always distinguish entrance, travel and return states.
- **Counterweight:** the player sees both the weight and the surface it raises. A newly learned anchoring ability holds it after leaving, creating a shortcut.

For the first memory puzzle, illuminate a former Operator reaching toward an apparently blank wall; after the image fades, a seam and service-handle silhouette remain. The memory offers interpretation and delight. It must not require remembering an invisible lethal jump. A later challenge can ask the player to route light, but stable socket shapes and an accessible schematic should carry its logic.

The earlier report supports comparing native Godot lights with an authored quantized mask. Retain that experiment: dynamic lighting can reveal artwork, while persistent gameplay state drives collision and traversability. Never derive logical state by sampling a displayed brightness value. This implementation recommendation also allows reduced-light effects without changing the puzzle.

## 6. Lightning and thunder without compulsory flashing

Microsoft's photosensitivity guidance prefers removing hazardous content over relying on warnings. It covers luminance changes, saturated red flashes and high-contrast spatial patterns, and calls for testing even without intentional flashing. Its approximate frequency/area examples are failure guidance, not a guarantee that falling just below a threshold is safe. [Microsoft, **Xbox Accessibility Guideline 118: Photosensitivity**, updated 4 March 2026](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/118).

Recommended default: distant lightning is a localised sky shape with restrained luminance and a slow release, not repeated full-screen inversion. Avoid saturated red storm effects. Reduced-flash mode substitutes a steady cloud illumination and visible rod-charge gauge; fully disabled ambient lightning leaves the environment intelligible. Check combined storm, dash, enemy, death and memory effects, including repeated dithering patterns, with photosensitivity analysis and representative play captures before release. A toggle is additional support, not proof the default is acceptable.

Separate distant decorative thunder from mechanical warnings. Storm atmosphere can arrive after the light for a sense of distance. A dangerous discharge instead has its own clear rod animation, ground boundary and advance cue. Never ask a player to infer lethal timing solely by counting thunder delays. Provide descriptive optional captions such as “conductor charging — right” for meaningful off-screen sounds; a generic musical-note symbol is insufficient.

## 7. Godot audio feasibility

Godot provides bus routing and ordered effects, enabling independent ambience, weather, mechanisms, cues and music mixes. Its current docs note a web limitation: bus effects do not work with default Sample playback; Stream playback enables them with latency tradeoffs when threads are disabled. Plan essential cues to remain clear without effects rather than making reverb or filtering necessary for a puzzle. [Godot, **Audio buses**, stable documentation, accessed 13 September 2026; publication date not stated](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html).

AudioStreamPlayer2D supplies distance attenuation, maximum audible distance, panning and Area2D-based bus routing. It can support a receiver hum growing nearer, or a sheltered room changing the weather mix. These features do not automatically model wall occlusion; author room transitions and test spatial cues. [Godot, **AudioStreamPlayer2D**, stable class reference, accessed 13 September 2026; publication date not stated](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer2d.html).

Use a small deterministic mechanism event to trigger state animation, cue sound and optional caption together. Audio accessibility should include independent weather volume and reduced transient impact. Preserve warning audibility when rain rises; do not solve all dramatic moments by increasing loudness.

## 8. Asset production contract

Build one representative room per district before ordering complete sets. Each room package needs:

1. **Independent far/mid/near planes:** complete imagery behind occluders, horizontal seamlessness, documented native size, period, origin, scroll factor, palette and alpha policy. Each layer must pass a three-copy seam view and real bidirectional scrolling. Do not slice a flattened scene and call it parallax.
2. **Separate landmarks:** non-repeating hero receiver, dish rim or source aperture, with distant/middle/arrival treatments that preserve silhouette identity.
3. **Room kit:** playable surfaces, corners, backs, trims, conduit mouths, supports, ceilings and decorative masses with collision meaning explicitly documented. Include boundary variants connecting neighbouring districts.
4. **Mechanism states:** dormant, available, operating, completed and obstructed where applicable; aligned frames, pivots, effect anchors and a fallback pose. A lit texture alone is not an adequate operating-state set.
5. **Lighting assets:** authored pools, occluder outlines, memory-only artwork, cue exclusions and reduced-effect equivalents. Each memory layer shares registration with the current room.
6. **Audio stems:** base ambience, local machinery, weather bed, rare distant events, mechanism action/result and critical warnings. Record loop points, event names, bus destinations, caption keys, provenance and license.

Track source art separately from tested exports. Keep image-generation prompts and edit provenance, but judge assets at 480×270 in motion. Generated “seamless” claims do not replace seam tests. Prior reports provide the detailed tiling metrics and native-light comparison; no additional asset generation was performed here.

## 9. First exploration slice and limits

Prototype Listening Field → sheltered Stand room → an overlook into Drowned Array → a permanent return conduit. Earn one lasting interaction, use it immediately, then revisit a previously visible obstacle to open a shortcut. Include one replayable memory, one lever, a distant storm, local colour restoration and a non-repeating landmark visible from two places.

Evaluate route recall, voluntary revisits, mechanism-state comprehension, exploration interruptions and accessibility parity before increasing world size. Ask what changed after the player acted and whether the place's former use was understandable. This is a stronger success criterion than screenshots alone. All district grammars, timings and progression changes above are proposals; the sources support principles and engine capability, not measured feasibility or a final production budget.
