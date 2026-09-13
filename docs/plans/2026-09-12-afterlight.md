# Afterlight implementation plan

**Goal:** A playable lighting study entered from the title screen, with three image-generated parallax layers and ordinary/dark/readability comparisons.

**Architecture:** The existing campaign remains the default. A lab flag selects a separate LevelData layout and suppresses campaign saves. A background-only CanvasLayer renders generated assets with integer-aligned parallax and a stepped grayscale shader. The foreground renderer remains unmodulated so platforms, player, pickups and hazards retain their established contrast. Memory-block events drive six-second afterimages. Beacon events persist lit windows for the current room. Lab settings affect only the lab.

**Tech stack:** Godot 4.7 Compatibility renderer, GDScript, canvas_item shader, built-in image generation, transparent PNG assets.

1. Write and run failing tests for lab entry, save isolation, replayable memory light without duplicate rewards, pause/death timing, beacon persistence, geometry invariance, and return to campaign.
2. Add `scripts/afterlight_data.gd`, a short three-beat room with familiar geometry and no glyph requirements. Wire title-screen L and explicit lab completion/menu navigation through RunState/HUD.
3. Add `scripts/afterlight_view.gd` and `shaders/afterlight.gdshader`. Render independently moving far/mid/near layers behind unchanged gameplay, then memories, lamp and persistent beacon windows. Add 1/2/3 lighting comparison, G generated/procedural, H gentle-motion setting.
4. Preserve the original PNGs in `assets/backgrounds/afterlight-v1/`, inspect actual transparency and record complete prompts. Updated after the user's tiling requirement: regenerate independent horizontal planes in `afterlight-v2/`, use ordinary repetition with exact logical periods, and keep the broadcast landmark separate. Inspect source edge metrics and three-copy boards, then test full camera wraps and stops. Quantize/limit luminance at rendering time rather than destructively processing source art; report remaining source-art mismatch honestly.
5. Capture normal/dark/memory/assist and shifted-camera frames in the real renderer. Verify routes with the real player and rerun all campaign tests. Record measured evidence and remaining human evaluation work in the research report.
6. Hash-check the live source against a pre-edit snapshot, apply only changed files and assets, then verify the installed project. Update backlog status to research and prototype delivered; broader playtesting, full lighting rollout and later campaign relays remain separate work.
