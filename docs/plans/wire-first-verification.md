# Alternate progression verification

Fresh-profile wire_first_playthrough_test extends the shared opening journey. From surveyed Lookout it returns through the hub lift, takes Field into the Stand, restores the bridge, repairs Wire and commissions Array before Drowned. Logged Array restored with air_jump=false. Then it returns through the Field to repair Drowned, revisits the Stand/Wire, completes the remaining Field project and reaches the Gate ending, hub revisit and saved scene reconstruction.

Result: zero failures at fixed 60 Hz. Only the initial scene setup is direct; region traversal and interactions use player movement/jump and E events. No seeded progression flags. The two successful arrival orders are automated route evidence, not human-paced playtesting or exhaustive sequence-break coverage.

Route corrections: use the hub upper return lift rather than the nearby causeway exit; approach the solid return ledge from its left edge to avoid jumping into its underside. No game geometry or progression rules changed for this check.
