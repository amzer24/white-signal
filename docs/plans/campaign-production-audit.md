# Campaign production audit

The current runtime registry contains 39 rooms. Every exit target is registered, and every registered room is reachable from Flats when gates and physical traversal are ignored. This is structural evidence only; the two input journeys and optional-route checks provide separate, narrower physical evidence. Raw inventory is campaign-inventory.json, generated directly through the Godot room registry.

## Source milestone: connected finale under polish

The three-space Source finale is integrated: gantry movement, common-return verification, and a commissioning walk. Both complete campaign input journeys and legacy-save reconstruction passed. Art, bridge deployment animation and human comprehension remain unfinished. The original design brief follows for comparison.

Prototype three functional spaces while retaining the existing approach/gate/aftermath save IDs or providing explicit migration:

- **Distribution gantry:** four previously repaired feeds visibly converge. The player uses Dash and Air Jump to cross two deliberate vertical/horizontal route changes, then secures a local bus. A visible dry lower return makes misses recoverable. Reuse held power and a latch; avoid four repeated mini-repairs.
- **Common-return chamber:** trace one shared failure path against an independently powered maintenance path. Isolating the common return leaves the local path lit. The consequence must be visible across traversable space, not expressed only by a success message. The safe retreat remains available through either state; no timed escape or compulsory damage.
- **Commissioning walk:** physically follow the independent circuit back to the final commit point. Earlier traversal becomes shorter after the local route holds. Restoration reveals the route home and the existing aftermath revisit. No new ability or arbitrary boss is needed to validate this theme.

Before art: measure actual jumps, identify one readable landmark per space, prove retreat from each intermediate state, test both approach directions and old completed saves, and observe whether the routing consequence is understandable without instructions. Treat these as hypotheses for a blockout, not final geometry or completed work.

## Remaining production order

1. Source blockout and traversal/logic review, then integration with old saves and both complete journeys.
2. Review the main Field/Drowned/Stand routes for repeated actions, empty connectors and one-view rooms that need spatial expansion. More room count is not the success criterion; each expansion must change the player's route or understanding.
3. Finish biome asset kits and character/enemy animation at correct collision scale. Build and inspect repeating parallax seams in both travel directions. Keep foreground threats readable through regional darkness/weather.
4. Finish audio selection/listening/mix and per-region pacing; current exploration score is provisional. Add meaningful accessibility/remapping and actionable save-recovery UX.
5. Run player comprehension, physical controller, completed-content performance and full standalone gameplay/save QA, then provenance and release packaging.

The release gates remain authoritative and incomplete. Recent isolated room polish does not complete this list. The 39-room inventory is a baseline for design review, not evidence of a finished campaign.

## Current room inventory

| Room | Goal | Connections |
|---|---|---|
| array_cable | WATCH THE DROP MARK . UPPER WALK PASSES ABOVE | array_inspection, wire_shelter |
| wire_shaft | ENTER UNDER LEFT WALL . ALTERNATE WALL KICKS | wire_shelter |
| array_inspection | WATCH THE PATROL . DASH . STOMP . OR TAKE THE UPPER WALK | array, array_cable |
| drowned_street | RECOVER THE IMPELLER . EXPLORE THE SURVEY GALLERY | basin, drowned_gallery, drowned_cycle |
| drowned_gallery | LEARN AIR JUMP . REACH THE UPPER CONTROL WALK | drowned_street, float, drowned_dock |
| drowned_dock | FOLLOW THE FREIGHT CONDUIT TO THE ARRAY | drowned_gallery, array |
| drowned_cycle | OPTIONAL . DRAIN THE SEPARATE BASIN . FIND THE ARCHIVE | drowned_street |
| stand_rim | FOLLOW THE BROKEN RIM TO THE SHELTER | shelter, return |
| stand_charge | STORE THE CURRENT . FOLLOW IT TO THE MOTOR | shelter, conductor |
| stand_bridge | THE BRIDGE HOLDS . FOLLOW THE WIRE | shelter, conductor, wire_shelter |
| stand_sluice | FOLLOW THE PIPE TO DROWNED | shelter, pump |
| stand_trial | OPTIONAL ARCHIVE . CRACKED PLATFORMS FALL | conductor |
| siphon | RAISE FLOAT . PIN . DRAIN . SERVICE THE LOWER RETURN | pump, lookout |
| hub | FOLLOW THE ANSWERING WINDOW | workshop, lookout, return, causeway, cellar, arrival, aftermath |
| workshop | STRIKE THE MEMORY . FOLLOW ITS CIRCUIT | hub, gallery |
| gallery | POWER LIFT . LATCH CATCH . REROUTE | workshop, amplifier |
| amplifier | RECOVER THE DASH PROTOCOL | gallery, return, fourth |
| return | OPEN A ROUTE YOU WILL REMEMBER | amplifier, hub, stand_rim, causeway |
| lookout | READ THE STREET BENEATH THE STATIC | hub, basin, cellar, sump, siphon |
| basin | LOWER THE WATER . FOLLOW THE EXPOSED STAIR | pump, drowned_street, lookout |
| pump | FIT THE IMPELLER . POWER THE FLOAT CONTROL WALK | basin, float, stand_sluice, siphon |
| float | RAISE THE FLOAT . AIR JUMP TO THE UPPER LATCH | drowned_gallery, pump |
| shelter | FIND THE UPPER CABLE . THE COURT IS SAFE | stand_rim, stand_charge, stand_bridge, stand_sluice, approach |
| conductor | DIVERT HELD CHARGE . OPEN THE LOWER RETURN | stand_charge, stand_bridge, stand_trial |
| causeway | MATCH THE DISHES TO THEIR ETCHED SIGHT LINES | hub, return, sump |
| cellar | STRIKE THE CRACKED INTAKE FROM BELOW | hub, lookout |
| sump | VERIFY WEST . EAST . SOUTH . COMMISSION THE FIELD | lookout, causeway |
| fourth | AN INTACT DISH . A DELIBERATE CUT | amplifier |
| flats | A/D MOVE . SPACE JUMP . STRIKE THE MEMORY FROM BELOW | conduit |
| conduit | E OR DOWN AT THE MARKED CONDUIT | flats, arrival |
| arrival | RESTORE THE BEACON . FOLLOW THE FIELD RECEIVERS | conduit, hub |
| wire_shelter | RECOVER THE BRAKE . REPAIR THE CARRIAGE | stand_bridge, wire_carriage, wire_shaft, array, array_cable |
| wire_carriage | FIT BRAKE . BOARD CARRIAGE . BOTH SHORES CAN RECALL | wire_shelter, array |
| array | TEST THE CIRCUIT . ISOLATE FAULT . ROUTE HEALTHY FEED | drowned_dock, wire_carriage, wire_shelter, approach, array_inspection |
| approach | VERIFY THE FOUR PROJECTS . OPEN THE SERVICE RETURN | array, gate, shelter |
| gate | SECURE THE LOCAL BUS . FOUR FEEDS ARRIVED | approach, source_return; aftermath after restoration |
| source_return | ISOLATE THE SHARED FAULT . WATCH THE LOCAL PATH | gate, source_walk |
| source_walk | FOLLOW FOUR INDEPENDENT FEEDS . COMMIT RESTORATION | source_return, aftermath |
| aftermath | THE SIGNAL HOLDS . YOUR WORLD REMAINS | gate, hub, source_walk |

## Free review record
OpenCode opencode/mimo-v2.5-free, session ses_f66945af4ffeSjIFX8I2i7z1hV, reported cost 0. Generic campaign summary supplied, no source files. Accepted the concern about a checklist finale without a physical consequence. Rejected invented grapple, three-feed topology, alternate ending and progressively worsening routes; they contradict current mechanics or introduce unreviewed scope. The Source brief above remains the root design hypothesis.
