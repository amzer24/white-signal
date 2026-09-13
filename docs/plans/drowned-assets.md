# Drowned asset production brief

Draft supplied by OpenCode `opencode/mimo-v2.5-free`, session `ses_f67b744b3ffeFrXw9OKLCGGbLV`, 13 September 2026. The process completed with reported cost 0. Primary review adjusted the float dimensions to the actual 62×8 collision, removed unnecessary full-screen overlays and broken-valve states, and kept critical tells visible without animation. These are production requirements, not generated assets.

| Asset | Logical pixels | Poses/frames | Anchor and grayscale tell |
|---|---|---|---|
| Manual bleed | 24×24 | Idle 1, available 1, operating 4, low 1 | Center-bottom; three visibly different handle angles correspond to HIGH/MID/LOW. Always usable before the impeller. |
| Impeller | 20×20 | Available 2, collected absent | Center; distinct three-blade silhouette, empty mounting outline after recovery. |
| Pump socket | 32×32 | Empty 1, ready 1, installing 3, running 4 | Center-bottom; matching impeller cavity and solid fitted hub. |
| Guided float | 64×16 | Still 1, operating 2, latched 1 | Top-center; flat bright 62px rideable edge aligned with the 62×8 collision. No bobbing of collision. |
| Return latch | 20×16 | Open 1, available 1, closing 2, held 1 | Center; separated versus joined hook silhouettes. |
| Air Jump protocol | 12×12 | Available 2, learned 1, ready/used HUD 2 | Center; paired upward strokes. No full-screen animation during movement. |
| Water ruler | 8×112 | Fixed 1 | Top-left; permanent high/middle/low notches and text, moving surface tracked separately. |

Use the existing pixel palette. A muted green-gray regional accent is decorative; safety, interaction and completion must be readable in grayscale. Keep asset generation to one reviewed representative kit before batching other districts.
