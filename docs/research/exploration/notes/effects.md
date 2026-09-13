# WHITE SIGNAL: effects that explain the world

WHITE SIGNAL should use effects to make its machinery, depth and restoration legible. The strongest starting combination is a local reconstruction dissolve, a restrained material-colour change and a stable beacon light. Fog, shafts and storms should give districts different atmospheres while leaving movement and mechanism cues intact.

This is a research shortlist and adaptation plan. No candidate has been imported, compiled, benchmarked or visually tested in the game. Compatibility labels below distinguish the author's stated target from an inference based on published code. A Godot 4 label is not verification against the project's Godot 4.7.2 executable or its renderer. The exploration design remains authoritative: permanent abilities, persistent routes and contextual machinery; no new Pulse or Anchor ability is assumed.

## Selection and evidence

GodotShaders is a community library. Its individual author posts and published code are primary evidence for those particular effects, but they are not official Godot documentation or assurances of production quality. Official engine documentation informs the integration constraints below. All pages were accessed on 13 September 2026.

Each source description is deliberately brief. Everything labelled **adaptation** is an original WHITE SIGNAL proposal. License entries record the page's stated code license, not a legal assessment of an entire derivative chain. Preview images, videos and depicted game assets are expressly outside the shader-code licenses. Preserve author, URL, access date, license notice and upstream references if a candidate is later adopted; create our own effect textures and masks.

## Candidate shortlist

| ID | Candidate | Stated code license | Compatibility evidence | Decision |
|---|---|---|---|---|
| FX01 | Pixel perfect dissolving | CC0 | CanvasItem; exact engine version unstated | First restoration experiment |
| FX02 | Palette Swap (Textureless) | CC0 | CanvasItem with Godot 4-style `source_color`; version unstated | First material-state experiment |
| FX03 | 2D fog overlay, HexagonNico | CC0 | CanvasItem; exact version unstated | Simple atmospheric baseline |
| FX04 | Pixelated God Rays+ | CC0 | Tagged Godot 4; no tested minor-version matrix | Selected interior vistas |
| FX05 | Transparent Lightning | CC0 | Tagged Godot 4 | Local storm prototype after cue design |
| FX06 | 2D Liquid Wave | MIT | CanvasItem with Godot 4-style `source_color`; version unstated | Drowned basin visual experiment |
| FX07 | Cloud Shadow Pixel Patches Overlay | CC0 | CanvasItem; exact version unstated | Optional distant weather layer |
| FX08 | Static Overlay Shader | CC0 | Author explicitly updated for Godot 4 | Reference for object-local static only |
| FX09 | Native PointLight2D and occluders | Engine capability, not a downloaded effect | Official stable Godot documentation | Compare with authored light masks |

### FX01 — Reconstruction that leaves a lasting result

Markolainen's [Pixel perfect dissolving](https://godotshaders.com/shader/pixel-perfect-dissolving/) (9 February 2023) snaps a threshold mask to texture pixels and exposes a sensitivity parameter. It is a compact sprite-local effect; the page does not state an exact engine target.

**Adaptation:** reverse the disappearance to assemble a dormant window pattern after a receiver is restored. Use a stable mask and a single progress value, then show the completed artwork normally. The same visual grammar can reconstruct a memory figure behind a wall or disperse defeated NOISE. Preserve the player's readable body through respawn; do not dissolve the only indication of a still-solid surface. Verify fully visible and fully hidden endpoints explicitly. Cost concerns are covered sprite area and many overlapping instances, not a required screen copy. A reduced-motion version can switch between two stable authored states.

### FX02 — Colour as recovered material

Neonsise's [Palette Swap (Textureless)](https://godotshaders.com/shader/palette-swap/) (15 May 2026) compares source colours with replacement colours, using up to twenty entries. Its published material is unshaded and reads the source texture directly.

**Adaptation:** restore a little amber enamel on the Listening workshop, slate ceramic at the Stand and oxidised green-gray on basin depth plates. Limit the initial mapping to the actual small art palette. Keep the bright gameplay outline unchanged. Use material state, rather than a global biome tint, so adjacent ruined and restored objects tell a story. Test import filtering and colour matching; the raw shader's handling of modulation and lighting must be adapted to the chosen layer contract. The comparison loop adds work per pixel, so a four-entry material is a better first experiment than a screen-wide twenty-colour search. Colour must accompany a changed latch pose, window pattern or map state.

### FX03 — Quiet depth between the terrain planes

HexagonNico's [2D fog overlay](https://godotshaders.com/shader/2d-fog-overlay-2/) (2 January 2024, updated 7 January) samples a repeating noise texture and varies transparency. Its setup describes older parallax nodes; that setup is not a requirement for WHITE SIGNAL.

**Adaptation:** place a low-opacity strip between the far terrain and middle ruins. In Drowned Array it hangs over the basin; in the Wire it separates distant pylons. Build the noise texture ourselves and validate its repetition with the existing three-copy seam procedure. Avoid foreground fog on the first slice. One texture sample is a useful implementation baseline, but full-screen transparent layers still consume fill work. Compare this with an ordinary slowly scrolling texture before choosing a shader. Disable ambient motion without removing the distant landmarks or route edges.

### FX04 — Light shafts with a physical source

Leo Volcano's [Pixelated God Rays+](https://godotshaders.com/shader/pixelated-god-rays-2/) (30 June 2025) uses an external seamless noise texture, aspect-aware pixelation and selectable blending. It requires a textured node and also samples the screen. Its code provenance links three earlier ray shaders.

**Adaptation:** one broken roof slit lights the West Workshop; later, narrow vertical shafts identify the Array's core. Anchor the source to architecture and mask the shaft at walls. A ray overlay is not automatically occluded light. Start without dithering, HDR-like intensity or negative/difference blending. Pixel steps must match the 480×270 logical view rather than the monitor's pixels. Screen sampling and overlapping blends complicate composition; compare a simple authored alpha shaft that does not read the screen. Reject any version that washes out the lever handle or invents a second apparent platform edge.

### FX05 — Storm energy inside an explicit channel

Beider's [Transparent Lightning](https://godotshaders.com/shader/transparent-lightning/) (6 June 2024) creates configurable arcs on a CanvasItem, with bolt count, thickness, colour and glow controls. The published code nests seven noise octaves inside its bolt loop and credits two upstream sources.

**Adaptation:** contain one arc between the Stand's rod and reservoir. A separate machine controller advances its gauge, signals discharge and commits the stored-charge state. The shader merely illustrates that event. Distant skyline lightning is another, optional atmospheric event. Use restrained achromatic intensity and a slow release; avoid constant crackling or full-screen inversion. A steady illuminated cable and gauge provide the reduced-flash alternative. Multiple bolts across a large rectangle are the obvious performance risk; an authored bolt sprite may give a better result at this resolution. No warning duration or flash intensity is approved by this research.

### FX06 — Static-water with a dependable surface

PWira's [2D Liquid Wave](https://godotshaders.com/shader/2d-liquid-wave/) (10 December 2025) exposes liquid level, waves, foam and optional bubbles. The page recommends duplicating materials when objects require independent settings.

**Adaptation:** render the Drowned basin as dark horizontal bands with a restrained broken surface line. Disable bubbles and central shine initially; quantize the decorative wave rather than introducing smooth realistic water into pixel architecture. Author a permanent readable hazard boundary and depth markers. The room's high/middle/low state sets both the visual baseline and collision state through game logic; decorative crests never define collision. Test empty/full levels and zero-width parameter cases, since the published formulas include divisions. Evaluate noise and transparent overdraw before adding reflection. Refraction that displaces platforms or warning lines is unnecessary for the first basin.

### FX07 — A weather system seen at a distance

thatisuday's [Animated Grassy Wind or Cloud Shadow Pixel Patches Overlay](https://godotshaders.com/shader/animated-grassy-wind-or-cloud-shadow-pixel-patches-overlay/) (4 January 2026) uses procedural bands, pixel snapping and configurable motion. Its code derives coordinates from the screen.

**Adaptation:** let an occasional broad shadow cross the distant salt plates in Flats or clouds beyond the Wire. Convert anchoring where necessary so the weather belongs to the world instead of sliding with the camera. Do not animate bands across small stepping stones or place high-contrast stripes behind enemies. Its default motion is a starting parameter, not an appropriate speed recommendation. Compare with one scrolling cloud mask: procedural noise and an additional transparent layer may not earn their cost. Keep this optional until the quieter baseline already gives enough depth.

### FX08 — NOISE belongs to objects and abandoned channels

Maaack's [Static Overlay Shader](https://godotshaders.com/shader/static-overlay-shader/) (1 December 2025, updated 10 May 2026) is a Godot 4 screen effect using additive noise and a screen texture. Its example includes mipmapped screen sampling and a periodically wrapped time expression.

**Adaptation:** use the visual idea inside a dead receiver display, a memory silhouette or a damaged cable housing. The published full-screen implementation is not recommended for normal traversal. A sprite-local texture mask avoids brightening the whole world, helps contain visual motion and simplifies composition. Check time wrapping for visible jumps. Keep an enemy's boundary and telegraph on a separate stable layer; apparent static fragmentation must not misrepresent its hitbox. This should be a rare sign of interrupted coherence, not permanent television noise competing with every room.

### FX09 — Native light as the comparison baseline

Godot's official [2D lights and shadows](https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html) documentation describes PointLight2D, DirectionalLight2D, CanvasModulate and LightOccluder2D. This is engine functionality rather than a community shader asset.

**Adaptation:** compare one native lamp with a registered, quantized light-mask sprite in the same workshop. A lever opens a shutter and changes which wall receives light; the opened shutter pose remains sufficient evidence with lighting disabled. Keep player, HUD and critical affordances outside atmospheric darkening. Native shadows add occluder authoring and runtime cost; authored masks need explicit state variants. Neither technique should be selected from a screenshot alone. Evaluate moving-camera stability, wall leakage and restored-state reloads before expanding to many lamps.

## Composition and timing contracts

Use one clear draw order: far sky and distant weather; far terrain; depth atmosphere; middle ruins and registered memories; room architecture; mechanisms and actors; critical cues; HUD. Local exceptions must preserve cue readability. A new effect must declare its bounds, palette, anchor space, clock, trigger, persistent result and reduced-effect equivalent.

Official [screen-reading documentation](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html) explains that the first 2D screen reader triggers a back-buffer copy; later readers do not automatically see each other's output. BackBufferCopy can establish composition explicitly. Consequently, stacking the stock rays, static and other post-process materials is not a dependable integration strategy. Prefer local texture effects and ordinary blending where possible; inspect any necessary screen-copy order.

The official [CanvasItem shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html) states that shader `TIME` continues during pause and periodically rolls over. Use explicit event progress for restoration and an appropriate game-controlled clock for machinery. Cosmetic fog may use a separate clock, but pausing should not leave a dangerous-looking discharge advancing while the actual mechanism is frozen. Verify restart, room entry and accessibility-setting changes, not just continuous playback.

## Accessibility and performance acceptance

Microsoft's [XAG 103](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/103) supports multiple channels for important information. [XAG 118](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/118) addresses photosensitivity and recommends testing beyond intentional flashing. Neither a low-opacity preset nor a reduced-flash toggle proves safety.

For this game, require route and mechanism recognition in grayscale, with audio muted, ambient motion disabled and flash reduction enabled. Test combined lightning, NOISE, memory, dash and death events; isolated previews miss the resulting pattern. Give conductor charge a stable gauge, physical pose and distinct warning cue. Thunder conveys distance and atmosphere; it is never the sole hazard timer.

Measure baseline and candidate frame times in the actual renderer at the logical viewport and common output sizes. Record GPU, CPU, resolution, active rectangles, light count and screen copies. Check transitions and repeat visits as well as a stationary scene. The code observations here identify likely costs; they are not FPS predictions or evidence that a candidate is fast. Culling inactive rooms and reducing covered area should be compared before sacrificing readability.

## Prototype order and deferred options

1. **Listening restoration:** FX01 plus FX02 on one window/receiver, and FX09's native-versus-mask comparison. Test whether the completed state is recognised immediately and after reload.
2. **Listening depth:** compare FX03 with a scrolling texture, then add a single FX04 roof shaft only if it clarifies architecture. Review beside the current generated parallax at its intended brightness.
3. **Stand weather:** compare FX05 with an authored bolt, tied to Stored Storm's deterministic gauge. Test the steady-light alternative from the beginning.
4. **Drowned surface:** FX06 follows the basin state prototype; later evaluate FX07 and FX08 only where an otherwise clear room benefits.

Defer [Animated 2D Fog with Pixelation](https://godotshaders.com/shader/procedural-2d-fog-with-pixelation/) (Tennisson, May 2024; MIT, author targets Godot 4): its nested procedural noise is a more complex starting point than FX03. Defer [2D Vertical Pixel Dissolving Wave](https://godotshaders.com/shader/2d-vertical-pixel-dissolving-wave/) (greasy_mcbeef, 29 July 2025; CC0, exact version unstated): displaced pixels need padding and may confuse solid edges; try it later on non-colliding memories.

Do not adopt [Pixelated Dissolve with Block Size](https://godotshaders.com/shader/pixelated-dissolve-with-block-size/) (blivi0, 20 June 2025) as the initial code dependency: its page states GPL v3, while FX01 already supplies the simpler reference needed here. This is a dependency-selection decision, not a conclusion about this project's licensing obligations. Reject full-screen VHS distortion, constant chromatic aberration, repeated white inversions and realistic 3D water as the normal visual language. They add motion or rendering assumptions that do not serve the proposed exploration slice.

The production output should be a small coherent effects kit, not nine independent showcase materials. Each adopted effect needs an authored mask or texture, event anchors, persistent final state, reduced-effect variant, provenance record and captured readability/performance evidence. The first success is a workshop that visibly remembers being restored.
