# Wire maintenance shaft: physical blockout verdict

## Question
Can the Wire offer an optional climbing discovery, reachable before permanent abilities, that changes the return route rather than adding another flat part pickup?

## Observed answer
The real base player controller climbed the 60px internal shaft in three alternating wall kicks. The upper release records an in-memory Operator archive and opens a service bridge between a vertical lift and the upper walk. A floor underneath makes missed kicks recoverable. The main railway bypass must remain outside this optional room.

Geometry: floor y224; left wall x184..200, y100..190 (34px entry below); right wall x260..276, y66..224; upper walk x276..480 at y66. The released bridge spans x167..276 at y66. The 84px lift at x125 travels from y224 to y66 at 45px/s. Lower recall, upper recall and onboard send are separate controls. No upgrade, enemy, countdown or consumable is required.

## What changed after observation
A floor lever initially sent the lift away before boarding. Separate recall and onboard movement solved that. The original upper gap was too long for a base jump; the release now unfolds a physical bridge. The successful shortcut is walked after riding, without another wall-kick requirement.

`prototypes/wire_shaft_observation.gd` uses movement and E input at fixed 60fps, plus an explicit retry fixture. Latest result: **0 missed observations**. It observes base climb, archive release, retained in-memory release after retry, riding ascent, pause freeze, duplicate release without duplicate bridge, and reverse descent to entry. It does not prove save persistence, entry from adjoining campaign rooms, physical controller usability or player comprehension. `wire_shaft_capture.gd` renders before/after states; the released image was inspected. The capture positions the player directly for illustration and is not traversal evidence.

## Free worker review
OpenCode `opencode/mimo-v2.5-free`, session `ses_f66bf6e58ffethiBBsJKf3cNNb`, reported cost 0. Generic brief only, no source supplied. Accepted general visibility of upper reward and a lasting shortcut. Rejected its mandatory air-jump segment, new movement-upgrade reward, false shortcut and reverse-order lever resets: they contradict ability-independent access and an archive reward. Raw response: workspace `white-signal-team/jobs/wire-maintenance-review.jsonl`.

## Next integration requirements
- Optional entry from inspection shelter; keep every existing main route and brake pickup reachable.
- Map adjacency reveals unknown signal, visited name only on actual entry.
- Atomic saved release/archive; a failed write must not deploy bridge or grant reward.
- Re-enter/reload rebuilds the released bridge; lift defaults safely to lower dock with both recalls available.
- Test both district entry orders, failed save, death and full opening journey before live installation.
- Author cable housings, brake mechanism, climbing marks, lever animation and archive presentation; current rectangles are blockout geometry.

## Run
Open `prototypes/wire_shaft.tscn` in Godot and run the current scene (F6). A/D move, Space jump, E use, R retry, Escape pause. This isolated scene sets lab mode and uses no campaign save; state lasts only for the scene. The prototype remains in staging and is excluded from the development export. No Git repository is present, so it is retained as explicitly labelled local evidence rather than a throwaway branch.

## Campaign integration
The optional shelter exit at x120 now leads into `wire_shaft`; the existing brake and both main district routes remain. A single transactional write records `wire_shaft_released` and `wire_shaft_archive`. Failure grants neither flag and deploys no bridge. Re-entry and scene reconstruction recreate the bridge once; temporary lift position resets to the lower dock. The map shows adjacency before entry and an ARCHIVE milestone after discovery.

`wire_shaft_campaign_test.gd` passed actual entry, three base wall kicks, failed write/retry, death recovery, lift movement and pause, duplicate release, reverse exit, re-entry and fresh scene reload, using a disposable profile. Both opening and Wire-first full journey scripts passed with zero failures when run sequentially. Their first parallel execution interfered because both inherit the same scratch save path; those results were invalid and were not used as campaign regression evidence. Keep these two tests sequential until their profile fixture is separated.

Campaign room and map captures were inspected. The room uses the existing world rendering and procedural geometry; finished shaft art, lever animation and player comprehension testing remain outstanding. The downloadable Windows package predates this integration.
