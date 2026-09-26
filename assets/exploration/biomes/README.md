# Biome art kits (PixelLab, 15 September 2026)

Generated over the PixelLab MCP HTTP endpoint with the project's own subscription (Tier 1). Every file below is the native PixelLab output except that tilesets were converted to greyscale (alpha untouched) so they sit inside the four-grey identity. Seed 91340. Nothing here is hand-cleaned.

## Sidescroller Wang tilesets (16px, `tileset15` 4x4 layout, `create_sidescroller_tileset`, ~3 generations each)

| Biome | Tileset id | Prompt (lower / transition) |
|---|---|---|
| flats | `a1687512-6573-40fd-b748-c9c40df4e6dd` | cracked dry salt crust over dark packed earth, flat pale mineral surface with fine cracks, dead salt flats / flat pale salt rim, thin light grey edge, no protrusions |
| field | `9923de83-9b70-4688-82af-b70506ffb1ec` | weathered relay station concrete masonry, large rectangular blocks, hairline cracks, faint recessed cable conduit lines / flat worn concrete lip, thin grey edge, no protrusions |
| stand | `1b776442-0119-4de2-b510-265710d27e7a` | storm-dark riveted steel plating, bolted seams, dark streaks, transmission tower deck / flat steel walkway rim with small rivets, thin grey edge, no protrusions |
| wire | `a3111f4b-3dea-4f49-8f46-3833b3d5508d` | dark steel lattice girder with diagonal cross braces, industrial pylon truss / flat steel grating walkway rim, thin light grey edge, no protrusions |
| array | `507fbfb1-91df-473a-9b58-fca8cfdaad40` | dark relay equipment panels, recessed vents, thin unlit status slots, bolted frames, transmitter interior / flat metal floor rim, thin grey edge, no protrusions |
| source | `0b6580e4-0b90-4f83-bf54-3424b9f49988` | clean pale relay panel walls, fine seams, faint lit strips, restored transmitter core / flat clean pale floor rim, thin light edge, no protrusions |

Runtime: `scripts/biome_material.gd` autotiles any platform rect (index = air corners, NW*8+NE*4+SW*2+SE*1; wang_0 is the solid interior). Tiles sit on a half-tile-offset grid and are clipped to the collision rect, so picture and collision never disagree. Drowned keeps `wet-concrete.png` through the same path. Existing two-pixel landing lips stay on top.

## Biome skylines (480x160, `create_image_pixen`, 1 generation each)

| Biome | Job id |
|---|---|
| flats | `263ff098-025f-4519-b375-43fab7154eaa` |
| field | `aa5acb1f-60f6-44a0-b2d6-6e4a1034dbea` |
| stand | `8bce7ddf-3290-4dcd-8cf7-97d2dd8cac75` |
| wire | `7893bd7e-10bf-4bc3-a102-e7c5c6b8b870` |
| array | `b61063e4-06b8-4350-8ec7-d81a8b3d7820` |
| source | `c9f22604-7f71-4654-8a9b-71394b35beca` |

Runtime: drawn once per room at 0.08x parallax with mirrored copies either side (no seam at any offset), tinted 0.52, faded into the floor over the last 24px. Rooms with their own set-piece backdrops (Drowned skyline, aftermath town, shaft/cable/shutter interiors) are skipped. The Source rooms' opaque fill became 55% so the hall shows through.

## Room dressing

`scripts/room_dressing.gd` adds non-solid ceilings, pillars and ledge struts in the biome material (tint 0.55) to the interior rooms (Field halls, Array, Source). No collision, route or save data changed; both test suites pass unchanged.

## Parallax layers (480x96, `create_image_pixen`, transparent, bottom-aligned, seed 91340)

`flats-mid`, `flats-near`, `stand-mid`, `stand-near`, `wire-mid`. Runtime (`exploration_world.gd` `_draw_backdrop`): far skyline 0.04x, mid 0.12x, near 0.28x, all snapped to whole pixels, with a half-rate vertical lift as the player climbs; far layers are tinted toward the background and near layers darker (atmospheric depth). A coded foreground cable layer runs at 1.3x in front of the play layer on exterior biomes. Interior biomes (field halls, array, source) are a wall right behind the player, so they move at 0.02x with no mid/near layers.
