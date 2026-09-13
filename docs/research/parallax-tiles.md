# WHITE SIGNAL: horizontally tileable parallax assets

12 September 2026. Focused follow-up to the user's correction: the images must actually tile. This is asset research and a proposed production contract, not verification of any generated image. Six primary sources are linked below. No reference packs were downloaded.

## Decision

Create **independent, horizontally seamless layer images**, each containing one complete depth plane. A landscape illustration split into strips is not a usable layered background: camera motion exposes whatever was hidden behind the nearer scenery. Build and test each plane on its own before approving the composite.

Use ordinary left-to-right repeat for WHITE SIGNAL's architecture. Keep the Gate, the fallen dish and other navigational landmarks outside the repeating images. A repeated hero landmark suggests multiple destinations and makes distance hard to read.

These are art/engineering recommendations. The source packs below establish practical examples of independently layered, loopable assets; they do not certify our future outputs.

## Real examples to study

| Original creator and asset | Verified offering / license | Useful study target |
|---|---|---|
| [Ansimuz — Mountain Dusk](https://ansimuz.itch.io/mountain-dusk-parallax-background) | Creator describes layered, seamlessly looped backgrounds; four variations; page lists CC0 and a Godot project archive. | Broad mountain contours across a wrap, separation of depth planes and a working engine example. The bundled project's API/version was not inspected. |
| [Vladimir Hovakimyan / Val_DeMar — Dark Forest](https://val-demar.itch.io/dark-forest) | Five separate pixel-art layers explicitly designed for horizontal looping; CC0 stated in description and metadata. | Silhouette density, negative space between trees and how near planes frame distant ones. |
| [Screaming Brain Studios — Seamless Sky Backgrounds](https://screamingbrainstudios.itch.io/seamless-sky-backgrounds) | Procedurally generated seamless PNG skies at 1024×512 and 512×512, CC0, commercial and non-commercial use permitted. | Continuous sky texture. This is a sky resource, not a ready-made multi-plane industrial scene. |

These are freely offered creator assets and reference candidates, not claims of adoption by a particular commercial game. Their source pages provide previews. Study composition and tiling structure without copying a signature scene into the WHITE SIGNAL art brief.

## What seamless must mean

The following is our acceptance contract, not a quotation from a source:

- **RGBA continuity:** the join must preserve visible color and alpha. Transparent margins cannot hide a cliff of opaque pixels at the opposite edge. Test composited over both black and light gray because transparent-pixel RGB and partial alpha can produce fringes.
- **Contour continuity:** silhouettes that leave the right edge must re-enter at the matching height on the left, with compatible slope and thickness. An equal final/first column alone cannot ensure this.
- **Material continuity:** dither phase, grain scale, cable thickness and horizon level must continue across the join. Lock dither to a periodic pixel grid.
- **Density continuity:** compare strips around the seam with strips elsewhere. A technically connected join can still advertise itself as a vertical empty corridor or a sudden mass of towers.
- **Depth completeness:** every layer fills its own intended visual mass behind nearer objects. Do not punch holes where another layer happened to cover it in the initial composition.
- **No baked framing:** no vignette, bright center spotlight, corner fade, text, border, central hero building or one-sided atmospheric gradient. Vertical sky gradients are fine; a horizontal gradient must return continuously at the wrap.

Adjacent sampled columns need not be numerically identical for a seamless image. A continuous slope can legitimately change by one pixel at the boundary. Judge the wrap as another ordinary adjacent-column transition, not as a requirement to duplicate a boundary column and create a flat stripe.

## Normal repeat, mirror, crossfade

Godot's CanvasItem distinguishes normal texture repetition from mirrored repetition, where alternate copies reverse. Nearest filtering selects the nearest pixel; repeat mode controls sampling outside the original texture. These texture-sampler settings are distinct from Parallax2D duplicating a child canvas item. A mirrored sampler will not magically flip independently duplicated sprites. [Godot CanvasItem reference](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html).

| Method | WHITE SIGNAL recommendation | Drawback / inference |
|---|---|---|
| **Normal repeat** | Default. Author a complete period that joins itself. | Requires actual seam repair. Repetition remains noticeable if the period contains a distinctive cluster. |
| **Mirrored repeat** | Only an explicit comparison for abstract mist or rock. | Avoids an abrupt value jump at an edge, but reverses dish directions and creates paired buildings or unnatural V-shaped ridges; derivative changes can still reveal the join. |
| **Runtime crossfade** | Avoid as the default architecture repair. | Overlap can show two silhouettes, soften sharp pixels, alter opacity and create extra grays. A hidden numerical seam can become a visible broad blend band. |
| **Authored periodic repair** | Preferred finishing method. Offset the tile so its boundary is central, repair the center, then inspect repeated copies. | Needs another full-wrap check after every resize/palette/alpha operation. Must not replace one obvious seam with a long empty band. |

## Godot setup that matches the asset

Godot recommends Parallax2D for new work. Its tutorial specifies coverage from `(0,0)` into positive coordinates and explains why centered sprites can partly fall outside the repeating canvas. Child scaling does not automatically adjust repeat_size or region_rect; size them together. Coverage must still hold at the widest supported camera view. [Godot 2D parallax tutorial](https://docs.godotengine.org/en/stable/tutorials/2d/2d_parallax.html).

Recommended initial contract, for a 480×270 logical viewport:

| Plane | Logical PNG period | Initial scroll factor | Content |
|---|---:|---:|---|
| Far | 960×270 | 0.12 | Quiet haze and low distant ridge |
| Middle | 1120×270 | 0.28 | Repeated receiver shells, dishes without a unique hero form |
| Near background | 1280×270 | 0.48 | Sparse braces and cable trunks; no collision-like ledges |
| Landmark | Separate non-repeating image | Authored per room | One fallen dish or transmitter |

Different periods and scroll factors can delay obvious shared patterns; they do not eliminate repetition. Approximate camera-travel repeat distance is period/scroll factor in a simple camera-relative model. Compare actual repeat distances, not merely different texture widths: proportional width and speed can still synchronise wraps.

Keep Parallax2D and Sprite2D at scale 1 initially. For a 960px-wide image, use `centered = false`, position `(0,0)`, and `repeat_size = Vector2(960, 0)`. If that sprite is deliberately scaled 2×, the child spans 1920 local units, so adjust the period to 1920; do not leave 960 and overlap halves. Avoid scaling the parallax parent until this simple setup is proven.

The class reference defines a zero repeat axis as disabled, repeat_times as extra copies useful when zoomed out, and scroll_offset as the intended adjustable offset. Direct changes to node position can be overridden by camera-following behavior. [Godot Parallax2D reference](https://docs.godotengine.org/en/stable/classes/class_parallax2d.html).

## Reliable image-generation and authoring workflow

1. Lock one layer's native size, silhouette purpose, palette, alpha policy and horizontal period before generation. Generate layers separately; never ask for a presentation sheet with labels to serve as the game texture.
2. Prompt for a horizontal looping depth plane with equal horizon elevation and matching edge material. Put landmark objects on a separate image. Treat the result as a candidate, because prompt compliance is not a guarantee.
3. Inspect a three-copy strip at intended logical size. Move the wrap to the center using a tiled/offset editing view, and repair the composition there. Image edits in this workflow should use the authorized image-editing tool; this report does not prescribe bypassing it with scripted image manipulation.
4. Complete obscured mass within each layer, resolve transparency, then enforce the final four-gray palette and pixel scale. Repeat seam inspection after these finishing operations.
5. Export the individual PNGs and metadata containing width, height, logical period, scroll factor, anchor, alpha policy and generation/edit provenance. Avoid calling assets production-ready until the next checks pass.

## Quantitative checks plus real scrolling

Proposed measurements, not completed test results:

- Let `P(x,y)` be premultiplied RGB and `A(x,y)` alpha. Measure `mean(abs(P(W-1,y)-P(0,y)))` and the equivalent alpha difference. Compare the wrap score to the distribution of all internal adjacent-column scores. Flag a wrap beyond the internal 95th percentile for inspection; do not automatically reject intentional natural contours or accept a blank tile.
- Check silhouette boundary heights at both edges and their nearby slope. Compare 16–32px edge bands for occupied-pixel proportion and average luminance. Record discontinuities individually; global means can hide one severed cable.
- Check palette count only among visible pixels and inspect alpha values separately. A nominally four-color PNG can still introduce many shades through partial alpha composition.
- Render the isolated layer repeated **three times** over dark, light and checker backgrounds. Inspect at logical resolution and an integer upscale; examine a strip around every join, not only the center of the image.
- Run the **actual Godot camera**, each layer isolated and then composited, through at least two full wraps in each direction. Include 1px/s motion, normal run speed, stops and reversals. Verify both the art seam and the node's position reset.
- Repeat at every supported zoom/display scale and with lighting off/on. Reject gaps, double-covered bands, sudden phase jumps, opaque rectangles and shimmering dither. If noninteger scaling is supported, document its quality separately.

Deliverable acceptance: each PNG passes independently, all layers remain complete as they separate, normal repeat works without mirror/crossfade concealment, the unique landmark appears only once, and a saved scrolling capture shows no visible join. Numerical edge equality without this motion evidence is insufficient.
