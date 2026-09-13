# WHITE SIGNAL: lighting, darkness and remembered infrastructure

Research date: 12 September 2026. Scope: one-room art/mechanics experiment, informed by the live GDD v8 and `docs/BACKLOG.md`, both read without modification. Recommendations below are design hypotheses, not shipped behavior or measured results.

## Recommendation

Build **Afterlight** first: strike a memory block and a receiver room briefly remembers its working life. Three empty stations light up in sequence; a chair's former occupant appears only as an interrupted shape. The machinery returns to darkness, while one activated window remains. This makes the existing Mario-like interaction explain the Signal's relationship to coherence without dialogue.

Use **beacon islands** to make progress persistent and **one moving service lamp** to compare mobile illumination. Keep every required landing edge, hazard tell and conduit mouth readable throughout. Darkness should hide historical detail and optional discovery, not information needed to survive a committed jump.

The GDD's palette is `#0b0b0b`, `#3a3a3a`, `#8a8a8a`, `#f2f2f2`, at 480×270. Reserve the lightest value for the Spark, essential cues and small active components. Large bright background masses would compete with that grammar.

## Verified reference lessons

**Playdead / INSIDE.** The developers' GDC session describes separately authored diffuse, specular and bounce lighting, local shadowed volumetrics, artist-facing controls, and dithering against banding. This is evidence for deliberate art control within a restrained aesthetic; it is not a prescription for physically correct lighting. Our inference: author small pools and silhouettes independently rather than expecting one global darkness setting to compose every room. Do not copy its 3D rendering stack into this pixel game. [Playdead speakers, GDC Europe 2016](https://gdcvault.com/play/1023783/Low-Complexity-High-Fidelity-INSIDE).

**Nintendo / Super Mario Bros. Wonder.** Its developers describe recovering surprise from familiar blocks and pipes, prototyping transformation, and preserving trust in familiar surfaces. Our inference: a struck block can change the room's meaning while retaining its collision rules. Introduce any future light-dependent collision as an explicitly different object in a safe demonstration. This source is about Wonder; it does not establish a specific ghost-house lighting method. [Nintendo developer interview, part 1](https://www.nintendo.com/us/whatsnew/ask-the-developer-vol-11-super-mario-bros-wonder-part-1/).

LIMBO, Ori, Hollow Knight and Rain World remain visual reference candidates from the brief. This bounded pass does not attribute lighting intent or technical methods to their developers without a verified primary source. No third-party interpretation has been presented as developer testimony. No annotated reference stills were captured in this report.

## Three art directions to compare

| Direction | Composition and lore | Player consequence | Cost and main risk |
|---|---|---|---|
| **Beacon islands — The Connected Dark** | Small bright repeaters, connected window groups, dark cable trunks. Waking a beacon restores a visible circuit rather than flooding the whole scene. | The return path becomes recognisable; activated windows act as spatial memory. No new player verb required. | Low: authored window groups and state. Bright windows can look like pickups; distinguish tiny paired rectangles from shard diamonds. |
| **Memory afterlight — The Room That Was** | A dormant room reveals an occupied arrangement for a few seconds; broken contemporary shapes remain registered beneath it. | Strike a block, look, infer a maintenance route. First version reveals history only; the conduit chevron remains visible after fade. | Medium: two aligned environmental states and careful fading. Ghost furniture must never look like a newly solid platform. |
| **Moving lamp — The Last Shift** | An automated inspection carriage continues its route over abandoned workstations. Its light passes through existing braces. | A voluntary cadence: move with the lamp to inspect detail, or outrun it. Optional shards invite leaving the pool. | Medium: path, occluders or authored mask, readable off-light route. Mandatory waiting would fight the game's movement identity. |

These are original WHITE SIGNAL proposals. Suggested first-pass timings: afterlight rises over 0.25 seconds, holds 4 seconds, decays over 2 seconds; moving lamp takes 10–12 seconds per round trip. These are tuning seeds, not research findings. Avoid white-screen flashes. A reduced-effect option can reveal the old room steadily while the player remains nearby.

## Godot implementation choices

Godot's native recipe uses CanvasModulate for ambient darkness, PointLight2D for local light and LightOccluder2D polygons for shadows. Occluders need authored outlines. Hard shadow filtering is cheaper than soft PCF variants. Lighting is calculated at viewport resolution, so nearest texture filtering alone does not make light pixelated; the docs offer snapping LIGHT_VERTEX and SHADOW_VERTEX. Additive sprites cost less but cannot cast shadows or properly illuminate fully dark surfaces. [Godot 2D lights and shadows](https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html).

| Approach | Prototype use | Tradeoff to measure |
|---|---|---|
| **CanvasModulate + PointLight2D** | Fast authoring comparison: two fixed lights, one moving light, a few simple brace occluders. | Native shadows help explain depth, but smooth brightness and overlapping lights can expand the palette. Keep gameplay outlines independently readable. |
| **Quantized mask / material** | Preferred visual candidate: calculate a few light fields at logical resolution, map lit/dim regions into authored palette levels, and reveal a separate memory layer. | Exact art control and cheap bounded fields are plausible, but need testing. Does not gain arbitrary occlusion automatically. Use explicitly authored shadow shapes first. |

CanvasItem shaders support fragment and light functions, including unshaded materials and multiple blend modes. Our implementation inference is that a small palette mapping shader can preserve the four-value output, while a separate unshaded gameplay-cue layer avoids darkness hiding critical information. A mere translucent black rectangle does **not** preserve four grays: intermediate alpha blending creates new shades. Either accept that as a comparison or quantize the composed world before drawing HUD/cues. [Godot CanvasItem shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html).

Compatibility is a sensible baseline for a 2D experiment and supports web export. Godot cautions that switching renderers can alter appearance; the feature table distinguishes core 2D from advanced features. Avoid building this experiment around compute shaders or HDR 2D, which Compatibility lacks. Actual frame cost and behavior still require the installed Godot build and target device; this research has not benchmarked either. [Godot renderer overview](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).

## Parallax assets and pixel stability

Godot recommends Parallax2D. Each independently scrolling layer gets its own node; scroll_scale controls apparent depth. A repeating layer must cover the viewport, with content positioned from the origin rather than centered into negative coordinates. repeat_size must match the actual repeated span; scaling a child does not automatically update that span. [Godot 2D parallax](https://docs.godotengine.org/en/stable/tutorials/2d/2d_parallax.html).

Proposed image-generation brief: generate an original monochrome abandoned relay landscape with broad quiet masses and no foreground collision-looking ledges. Request separate far atmosphere, distant dish silhouettes and middle-distance receiver shells, without text, UI, characters or bright collectible-like marks. Generated imagery is source art until visual and seam checks pass; asking for seamless layers does not prove they tile.

Suggested layer contract: at least 960×270 logical coverage, horizontal repeat only, scale 1, far/middle scroll factors 0.12/0.28/0.48. Keep the unique landmark non-repeating. Nearest-filter the final low-resolution assets. Snap each rendered layer's final camera-relative translation, rather than altering physics positions. Use the same render grid for mask and image. These are engineering proposals, not engine guarantees. Check left and right camera travel, slow movement, stops and repeat boundaries; a beautiful still does not establish stable parallax.

## One-room experiment: The Receiver Annex

Build a separate 60–90 second annex with unchanged movement rules and three short spaces:

1. **Read:** a safe beacon, a plainly visible exit landmark and one low step. Wake the beacon; a cable's three windows stay lit.
2. **Remember:** strike the block from below; three stations return as an afterimage. One interrupted figure reaches toward a conduit. The conduit stays marked when the image fades and leads to an optional archive with a clear return.
3. **Cross:** a lamp crosses a short bridge. All landing tops and pit boundaries remain visible outside its pool. A shard pocket rewards observation; reaching the transmitter never requires waiting for the lamp.

Compare exactly the same room in ordinary illumination, authored darkness and readability assist. Start without NOISE, then add one existing walker only if basic navigation passes. Do not simultaneously test new enemy behavior, tide and darkness: failures would become hard to diagnose.

Accessibility recommendation: independently configurable background dimming and platform/player outlines, clear hazard shapes, steady substitute for pulsation, and a way to reduce parallax. Microsoft's guidance supports configurable contrast, outlines and separation of important elements from scenery; apply its 4.5:1 guidance to standard essential visual cues and measure their worst background, including the bright memory state. This is not a claim that a contrast number alone proves the game accessible. [Xbox Accessibility Guideline 102](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/102).

## Evaluation and decision gates

These are proposed acceptance gates. No participant results exist yet.

- **Navigation:** five first-time players can point to the next required landing and transmitter within two seconds of a pause at authored viewpoints. Log mistakes; do not average away a completely hidden edge.
- **Fairness:** after every death, ask what caused it. Any death due to unseen required collision or a hidden tell blocks campaign adoption.
- **Movement:** compare completion time and hesitation with ordinary illumination. Investigate repeated involuntary waits for the lamp or darkness-only delays exceeding roughly 20% of baseline.
- **Lore:** after leaving, ask what happened in the room without naming Operators or memory. Record whether the player mentions former inhabitants and whether the effect was noticed at all.
- **Visual stability:** inspect recorded slow pans and wraps at integer display scaling. Reject one-pixel holes, unstable dither crawl, halos around cutouts and landmark repetition.
- **Performance:** record frame-time median and 95th percentile for each mode with identical camera movement, resolution and hardware. Target 60 fps (16.7 ms total frame budget), record lighting's measured increment and test worst-case overlapping lights. This report makes no performance promise.
- **Assist parity:** repeat the required route with effects reduced. Goals, tells, conduit access and rewards must remain available.

Promote afterlight and persistent windows only after readability passes. If dynamic shadows add shimmer without useful spatial information, keep authored pools and silhouettes. Moving-light-dependent collision, listening-dark enemies and an inverted bright Gate remain separate backlog experiments.
