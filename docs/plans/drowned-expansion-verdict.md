# Drowned expansion route study

## Question and decision

Can the Drowned district support a descent, separate part/ability discoveries, and a changed return without repeated mandatory water cycles? The seven-room logic study supports this shape. It does not yet prove jump distances, pacing, physical safety or finished level design.

First route: high-water rim -> exposed service street -> survey gallery -> dry stair to rim -> pump repair -> street/gallery revisit with Air Jump -> float chamber -> upper conduit -> short return to pump. The dry pump-to-float shortcut exists only after the latch. A direct powered pump/float edge was rejected because it made the shortcut redundant.

The gallery-to-float entrance needs pump repair, but never a float height controlled from inside the room. The upper landing separately requires the high float and Air Jump. This avoids a control-behind-its-own-gate deadlock.

## Room blocks for the physical blockout

| Room / planned ID | Owned action | Spatial block | Lasting result / return |
|---|---|---|---|
| High-water rim / basin | Observe and bleed | Dry horizontal rim, two clearly separated descent shelves; control above high mark; drowned mast shows depth | Marked stair remains climbable after death; main basin never needs refilling |
| Dry pump house / pump | Fit impeller | Existing landmark plinth retained; empty socket faces entry; dry upper walk reaches rim | Saved pump powers float controls; upper return door initially closed |
| Service street / drowned_street | Recover | Low street with domestic doorways and a pipe crossing them; part in a visible alcove below rim sightline | Part retained on death; fixed stair returns without a timed water cycle |
| Survey gallery / drowned_gallery | Learn Air Jump | Safe pickup floor, low ceiling-free jump space, two stepped practice gaps with walkable recovery below | Permanent ability; revisit offers a faster upper line |
| Float chamber / float | Raise, jump, latch | Dry control stair, guided vertical float, offset upper ledge demanding Air Jump; drop returns to dry control | Latch opens the short pump return and freight route |
| Freight dock / drowned_dock | Connect | Inner conduit hatch; external Array entry and retreat share a dry landing, no forced drop | Before latch, reverse visitor sees closed inner hatch and can retreat; after latch, route joins district |
| Cycling basin / drowned_cycle | Optional timing remix | Separate small reservoir, dry control and recovery ledge; archive below low line | Archive saved; optional tide cannot modify the main basin |

Existing Siphon branch stays independent. The plan expands the main district without replacing that already implemented optional branch.

## Compatibility constraints before integration

Retain basin, pump and float IDs and existing impeller, air_jump, pump_repaired and drowned_restored flags. Existing completed saves must build the new dry shortcuts immediately; old Air Jump remains learned. New room IDs require save whitelist updates. Drowned survey must reveal new outlines without marking rooms visited. Move the Array boundary to the dock while retaining a safe old-profile resume at pump. Stand sluice and Siphon connections remain documented external routes. Actual migrations and route tests are still required.

## Observation evidence

Prototype: staging prototypes/drowned-route-study.html, self-contained, in-memory only. Pure model was driven through its four guided routes with white-signal-team/observe_drowned_model.cjs. Recorded traces: prototypes/drowned-route-observation.jsonl.

- First descent finishes at pump with part, Air Jump, repair and latch retained, water low.
- Failure after collecting the part returns to dry rim and allows pump repair without recovering the part again.
- Reverse dock arrival cannot cross the unrepaired inner hatch and can retreat to Array.
- Optional basin cycles independently; death retains its archive and keeps the main street low.

Browser display was blocked by local-file URL policy; no workaround was attempted. This is model observation, not rendered browser QA or a physical game playthrough. There is no Git repository here, so the throwaway study and verdict remain explicitly labelled local artifacts, excluded from exports.

## Free-worker review

OpenCode mimo-v2.5-free, session ses_f66ef2e1dffe1YCHRDR6SSXCZw, reported cost zero. Generic brief only. Accepted dry reverse-entry retreat and accessible controls. Rejected a mandatory fully-cleared-street gate: optional discovery must remain optional. Its scenarios involving raising main water do not apply to the proposed lower-only main basin; those concerns belong to the separate optional tide.

Next: Godot blockout with the real player controller, forward/reverse and interruption observations, then integration if physical evidence supports the route.

## Physical blockout — first main loop observed

Added prototypes/drowned_blockout.gd and .tscn, with the real player controller, seven rooms plus an Array boundary stub, in-memory discoveries, a moving float and separate optional water. E interacts, R recovers, Escape pauses. No campaign save is read or written.

prototypes/drowned_route_observation.gd drives actual movement and E input from the rim through the street, Air Jump gallery, dry pump repair, powered float ascent, upper latch and short return to pump. At fixed 60 Hz it reports zero missed landings; final room pump, part/air/repair/latch all true and main water low. Log: test-user/drowned-blockout-route.log.

The initial gallery shelf demanded marginal horizontal travel during the first air-jump lesson. Its left edge moved from x265 to x235 while retaining a 70px rise above the practice shelf and safe floor below. The route observation launches near the shelf edge. Other initial misses were corrected in observation timing and launch positions, without reducing the intended vertical challenges.

All seven rooms render in prototypes/drowned_blockout_capture.gd; gallery capture inspected on the NVIDIA Compatibility renderer. These remain geometry studies with placeholder art. Physical freight reverse-entry, interruption/recovery, optional tide and base-jump exclusion observations remain pending. Do not replace live Drowned rooms until those checks and save compatibility are covered.

## Recovery observations and room adapter

prototypes/drowned_recovery_observation.gd now drives the physical failure cases at fixed 60 Hz, reporting zero missed observations (test-user/drowned-blockout-recovery.log):

- Unrepaired freight inner hatch rejects entry; walking back to Array and returning to the dock succeeds.
- Base jump from the gallery practice shelf reaches centre y128.21, below the target standing height y113, then lands on the recovery floor.
- Optional archive is reachable and its return stair climbable with base jumps. Draining that basin leaves the main water high in this isolated scenario.
- After earning impeller and Air Jump through controls, entering high optional water triggers recovery on the dry rim, keeps both discoveries, and resets main water low / float low.

scripts/drowned_district_rooms.gd adapts the validated blockout into seven campaign-shaped data records, retaining basin/pump/float IDs and translating prototype control names to campaign action names. It is deliberately not merged into the live room registry yet. The adapter parses and every internal exit has a reverse edge; external connections are Lookout, Stand sluice, Siphon and Array. No new campaign behavior is claimed from this data-only stage.

Remaining integration work: update mechanism ownership across rooms, save whitelist and old-profile handling, wire the registry/external exits, map/survey/goal updates, restore the pump landmark, then run both full journey orders and save-failure checks. The physical float interruption after pump repair and post-latch reconstruction should be covered at the campaign level too.

## Campaign integration — 13 September 2026

The seven-room module is now merged into the campaign registry. Main water, float and optional tide have separate state. Air Jump moved to the gallery; old learned abilities remain valid. Float landing requires pump repair, Air Jump and a physically raised float. The return latch writes float_latch and drowned_restored together through a transactional multi-flag save. A failed save grants neither flag and permits retry.

The registry retains original basin/pump/float IDs. Four new room IDs are whitelisted. Existing completed profiles at each old Drowned room resume with discoveries retained, open pump/float shortcut and open freight connection. Array now leads into the freight dock; its inner hatch remains closed until Drowned restoration, while the external retreat remains usable. Stand sluice and Siphon remain attached to the pump. Drowned respawn returns to the dry rim, retaining discoveries.

The map has an eighth page for the seven-room district. Survey reveals main-route outlines; names still require visits. Optional basin remains an adjacent discovery. Guidance follows part recovery, ability discovery, repair and latch. The existing PixelLab pump landmark is preserved.

Evidence: drowned_expanded_test, drowned_test, drowned_expanded_routes_test, exploration_save_test, siphon_test and controller_test report zero failures. Fresh opening_playthrough_test and wire_first_playthrough_test both complete the campaign through the ending and saved scene reconstruction at fixed 60 Hz. The integrated route uses actual movement and E input. Seven rendered rooms and the district map were captured; map, pump, rim and float inspected on the NVIDIA Compatibility renderer.

This completes the initial Drowned expansion integration, not the biome's final art, enemy population, hand-paced playtesting or full release. Prototype artifacts stay excluded from export. Existing standalone development export predates this expansion and soundtrack.
