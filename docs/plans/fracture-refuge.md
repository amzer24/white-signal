# Fracture Trial: high route and lower recovery

The original optional room used three timed ribs in one arc. Waiting on the
middle rib caused a fall and reset to the left bank. A stable 66-pixel fallen
rib now sits below it at (207,224), creating a place to recover and a deliberate
lower route. The upper timing route and 0.9-second crumble rule remain intact.
The lower rib uses the normal solid-platform surface, support legs, and a faint
steady light. Cracked ribs keep their existing fracture marks.

The refuge does not grant the archive, reset crumbles, or bridge either remaining
gap. Players must still reach the right bank. Collecting the archive commits the
existing complete return walkway; failed saves keep that walkway absent.

Free OpenCode review session `ses_f660f2897ffegSKYMipIRzoh3S` identified the single
linear arc. Its proposed multiple crumble timers and nearest-bank respawn were
rejected: those add extra surface rules and could skip traversal through failure.
The chosen change uses the existing movement verbs and a stable lower rib.

Evidence: the input route reached the middle rib, then reproduced the original
reset at the left bank. With the refuge it passed recovery, onward jumps, actual
archive interaction, complete lower return, and exit to Reservoir Walk. Expanded
Stand save-failure and legacy-profile checks also passed. A rendered recovery
fixture was inspected. Human pacing/feel review remains open.
