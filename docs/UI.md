# Menu and settings UI

This records the incumbent Godot interface in `scripts/menu_ui.gd`; it is a local extension, not a replacement visual system. Coordinates below are logical pixels on the 480×270 canvas.

## Colors

The interface uses `DrawUtil`'s four grays: BG `#0b0b0b`, DARK `#3a3a3a`, GRAY `#8a8a8a`, and WHITE `#f2f2f2`. White carries actions and values; gray carries supporting copy. The world remains faintly visible beneath a black overlay: 78% opacity on the title and 96% on secondary pages.

## Typography

`DrawUtil.text` draws uppercase 3×5 bitmap glyphs with a one-pixel advance gap. Integer scaling supplies the hierarchy: 5× for WHITE SIGNAL, 4× for page headings, 2× for title actions and the How to Play Back action, and 1× for settings labels, values, descriptions, and control hints. This is custom rectangle-drawn lettering, not a system font.

## Layout

The title centers its heading and compact vertical action list. Home rows are 240×20 at x=120, beginning at y=116 with a 22-pixel step. Continue is conditional; the remaining actions are New Run, Settings, How to Play, and Afterlight. A selected-action description and keyboard/mouse hint sit below the list.

Settings uses a left-aligned heading and four rows: Music, Effects, Fullscreen, Back. Rows are 320×24 at x=80, beginning at y=84 with a 28-pixel step. Labels sit left; horizontal volume bars and right-aligned percentages sit right. Instructions and persistence status follow below. How to Play moves the gameplay reference to its own page.

## Shapes and focus

Rectangles have square corners and immediate state changes. The selected title action uses a solid white plate, dark text, and a small chevron. Settings selection uses a dark plate, a one-pixel gray outline, and an external white chevron. Both keyboard selection and mouse hover use the same selected-row state. Sliders have a four-pixel track and a rectangular thumb; fullscreen is expressed as ON/OFF text. Depth comes from the dimmed game scene rather than UI shadows.

## Interaction and persistence

Up/Down or W/S selects a row; Enter/Space activates it. Mouse hover selects, and clicking activates. Music/effects can be dragged or adjusted with Left/Right or A/D in five-percentage-point steps. Effects adjustments play a short preview beep. Enter toggles fullscreen; F11 is its shortcut. Escape or Back returns from a secondary page. O opens Settings from the title or pause screen, and leaving settings restores the previous menu selection or the paused context.

Volume changes apply immediately. Keyboard changes persist immediately; pointer changes persist on release or leaving the page. The footer normally reads SAVED AUTOMATICALLY and becomes COULD NOT SAVE SETTINGS on a save error. Preferences are independent of campaign saves; zero volume mutes its audio bus.

## Visual evidence

Recorded from the implementation and the reviewed 960×540 captures, preserved as [title menu](research/evidence/menu-continue-960.png) and [settings](research/evidence/settings-960.png). These show the title focus plate, settings focus outline, spacing, type hierarchy, muted world backdrop, and numeric audio values. The broader finish review accepted the menu/settings captures; this document records their existing treatment without adding new UI requirements.
