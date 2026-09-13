# Drowned skyline

Generated using the user's authorized PixelLab subscription, 13 September 2026.
Original Pixen job: `3f2f2f4c-77b6-4ad5-8204-45521dee8f7f`, seed 14273.
Revised accepted job: `a3a6ecec-94fb-49b6-b982-c4e422e407ba`, seed 14274.
Two generations. The accepted PNG is retained unchanged at 256 x 128 pixels.

Brief: a distant flooded industrial skyline in strict side elevation, with
pumping towers, tank, service pipes and antenna; sparse dark grey-green pixel
silhouettes, transparent background, no foreground or text. The first result
was rejected for bright smoke and inadequate margins. The revision removed
smoke and requested transparent side margins and simpler silhouettes.

Inspection: alpha bounds are (3,26)-(245,111); both outermost columns are fully
transparent. The requested 12-pixel margin was not met on the left, but the
actual transparent margins allow the modules to repeat through open sky.
Runtime repeats at a 256-pixel period, uses native pixels, an integer parallax
offset of 0.08 times player X, and a dark green tint. Lower foreground facades
retain the existing repaired-window response. Generic receiver arcs are omitted
in Drowned. No collision, water or progression changes are made.

`drowned_skyline_capture.gd` captures left, right, return and restored states.
Left/right and restored renders were inspected on the Windows NVIDIA renderer.
This is a district background layer, not a finished biome asset kit.
