# Interaction sprites (PixelLab `create_image_pixen`, 15 September 2026)

32x32 (24x24 for parts) transparent sprites, 1 generation each, native output unchanged. Runtime `scripts/action_sprites.gd` maps every action id to a sprite kind and anchors the opaque bottom-centre on the old marker's foot line, so no interaction position, route or save changed. Pickups (impeller, brake, dash, air jump) disappear once their flag is set; sockets show the fitted part after repair; exits use the open/sealed hatch by `can_use_exit`; memory blocks use the diamond block.

| Sprite | Job id | Seed | Prompt |
|---|---|---|---|
| archive | `1f62bb3a-ab9f-45da-9ecc-cc31c70cb45f` | 91341 | old operator terminal console with a small crt screen on a pedestal, reel recorder on top |
| beacon | `a6c34348-64a7-4c46-bd53-0c3069f5a235` | 91341 | tall relay beacon post with a lamp on top and a small control box |
| valve | `3c2de498-8333-4098-9911-6b6abb17f5fb` | 91341 | pipe valve with a large hand wheel on a short vertical pipe stub |
| socket | `e82efa4f-cf7c-45a5-a175-316d615e98f3` | 91341 | empty machine socket bracket with a missing part, open clamp and dangling cable |
| protocol | `65122e0a-1be3-42a3-903d-c15b6c453b45` | 91341 | glowing crystalline data module, a faceted diamond in a metal cradle |
| door_open | `61c70cf5-05e6-46f3-940c-90d72fe90543` | 91341 | narrow steel bulkhead hatch doorway standing open showing darkness inside, rivets on frame |
| door_shut | `2fe21463-1437-450b-9c70-b24337361fd0` | 91341 | narrow steel bulkhead hatch doorway sealed shut with a crossbar, rivets on frame |
| memory | `fdbeae66-51e3-4041-ad4f-a808cbf0c6bf` | 91341 | sealed steel block with a diamond emblem on its face, mario question block style but industrial |
| lever | `5b482e0c-3ca0-4458-8de5-a26a6e6ce3b4` | 19 | floor-standing lever: a rectangular steel base box with a long straight lever arm angled up-left ending in a round knob (picked from 3 seeds) |
| breaker | `32036c06-4e40-4d71-8a94-2e4d2ac096be` | 42 | tall narrow electrical switchboard cabinet with a big knife switch handle on the front and one round lamp above it (picked from 3 seeds) |
| callpost | `1948082e-b8e4-4cc5-9b92-4023ad175780` | 42 | short metal bollard post with a single large round push button on top and a small lamp, elevator call point (picked from 3 seeds) |
| crank | `b86d233a-2e57-49c0-857f-b5b04d125062` | 42 | hand crank handle on a square gearbox mounted on a short stone plinth (picked from 3 seeds) |
| brake | `8a18ee75-a275-4a31-a474-c73823c60eb0` | 42 | cable brake shoe assembly: a metal clamp block with a coil spring and a lever, small loose machine part (picked from 3 seeds) |
| impeller | `6c1a9c63-3440-428b-84a8-62cbb42d51cb` | 19 | pump impeller: a round hub with four curved blades, small loose machine part seen face-on (picked from 3 seeds) |

Common style suffix: greyscale pixel art, dark grey and light grey with black outline, side view, industrial abandoned relay station, transparent background, no text.
