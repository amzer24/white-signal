# CLING encounter blockout

Question: can a second NOISE routine reward reading the environment, baiting and vertical avoidance while retaining current one-hit contact, dash and stomp rules?

The isolated scene has a fixed drop lane at x250, hanging centre y112 beneath an upper walk at y88. Four 34px stair rises provide a base-jump bypass above its trigger. Entry and archive remain outside the lane. Within 55px horizontally and below y135, the enemy contracts its slit and draws a dashed vertical guide plus a 22px floor bracket for 0.65 seconds. It then falls under 720px/s² gravity to y215, rests for one second, and climbs back at 90px/s. The 14x18 body remains physical throughout. The floor mark is a warning, not an enlarged damage area. No full-body flash or color-coded threat is used.

`prototypes/cling_observation.gd`: 0 missed observations using real movement and input. Covered upper-route archive without combat, warning before fall, pause freeze, bait/retreat, dash and stomp during grounded recovery, and a deliberate lane death with safe reset. Initial dash from x185 failed because its travel ended before reaching x250; approaching x218 before dashing succeeds with unchanged player rules. A separate NVIDIA capture illustrates the warning; its starting position is a fixture, not route evidence.

Open questions before campaign integration: reverse approach, repeated complete drop/return cycles, warning visibility against final art, per-life defeat state, save/reload archive behavior, and player comprehension. This is a new routine in an isolated prototype, not yet part of the campaign enemy roster. No character art sheet, final animation or audio has been authored.

Run prototypes/cling_encounter.tscn as the current Godot scene (F6). A/D move, Space jump, Shift dash, E archive, R retry, Escape pause. No campaign saves; in-memory state only. Kept as a labelled local prototype because the project has no Git repository; excluded from development exports.

## Campaign integration
CLING now occupies `array_cable`, reached from the inspection bay's upper-right shelf. Its archive opens a two-way upper service return to the Wire shelter, forming an optional loop. The existing main routes stay available. The room, map and saved flag use the exploration profile; one flag controls archive and return atomically.

`cling_campaign_test.gd`: 0 failures for actual inspection-to-gallery traversal, base-jump avoidance, failed archive save/retry, shelter return, safe reverse entry, reverse warning, cycle recovery, per-life defeat, respawn and scene reload. Defeat in this integration check is a direct fixture; physical dash/stomp were observed in the prototype. The prototype also passed two complete reverse-approach cycles. Both full opening orders and inspection campaign regression passed sequentially.

NVIDIA room/map captures were inspected. Enemy rendering initially leaked over the map; map_open now immediately hides the active enemy and closing restores it, with explicit checks and a clean recapture. Wire/Array map layout was rearranged for eight nodes. Its unconditional Array-to-shelter service route now displays as open rather than incorrectly requiring Array restoration.

Final CLING sprite/animation, Cable Gallery art and human readability review remain unfinished. The latest downloadable Wire ZIP predates this integration.
