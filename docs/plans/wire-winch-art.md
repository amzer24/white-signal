# Wire winch and controls

PixelLab housing at native 64x32 size (origin 93,30) gives the service lift a visible mechanism. A Godot-drawn three-spoke wheel rotates from lift displacement; cable marks follow that same displacement and remain still when paused or stopped. The release lever and brake jaws transition over one third of a second after a successful save. Reload/reset initializes their correct saved state directly. No flashing, camera effect, collision or timing changes.

The shaft now replaces generic plus-sign controls with directional recall/send buttons and a physical release lever. Climb marks sit outside wall geometry so they remain visible after platform drawing.

NVIDIA campaign capture inspected with the released mechanism. wire_shaft_campaign_test.gd again returned 0 missed observations for the climb, failed write, release, lift, pause, reverse return and reconstruction. Broader room art and authored ambience remain unfinished; this is one mechanism asset and its feedback, not a completed biome art pass.
