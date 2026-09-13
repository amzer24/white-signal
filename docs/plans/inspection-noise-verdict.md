# Optional inspection NOISE encounter

## Question

Can one readable patroller create a meaningful dash / stomp / avoidance choice without gating exploration behind combat? The isolated controller study supports this encounter layout. It is now integrated as an optional Array branch.

## Validated shape

An optional inspection bay has a 190–310px ground patrol lane, safe entry at x40 and an archive on the far shelf at x420. Base jumps connect a left shelf, the upper bypass, and the archive shelf. The player can reach the archive while leaving NOISE alive. A 0.35-second stationary pause precedes each direction reversal; a stable 14 by 18 outline preserves the contact boundary while the inner shape contracts. Reduced-flash mode holds interior marks steady.

The actor reuses the existing dash/stomp/contact rules in enemy.gd. Side contact causes player recovery, dash defeats the actor, and downward contact produces the existing stomp bounce. The enemy re-forms after death; archive discovery remains in memory. No currency, HP or new mandatory ability is added.

## Evidence

prototypes/inspection_observation.gd uses actual movement, jump, dash and E input. It reports zero missed observations for upper-route archive access without combat, stationary turn tell, dash defeat, stomp defeat and safe-entry recovery with enemy re-formation. The first stomp attempt launched too far away and landed before contact; moving the launch closer succeeded without changing collision rules. Observations are at fixed 60 Hz and are not human playtesting.

Prototype files: inspection_encounter.gd/.tscn and inspection_noise.gd. Capture: test-user/inspection-patrol.png, inspected on the NVIDIA Compatibility renderer. A turn-pose capture is also available. They remain throwaway, no-save artifacts excluded from export; no Git repository is available for a separate prototype branch.

## Free review

OpenCode mimo-v2.5-free session ses_f66d47f73ffeJ8UhRq1L3Tn0iA, reported cost zero, generic brief only. Accepted emphasis on legible bypass and safe spawn distance. Rejected its unsupported assertion that 0.45s is a required minimum turn tell and its proposal to keep enemies dead after player death, which conflicts with the established re-formation rule. Existing stomp bounce provides motion feedback; richer defeat animation and final art still need work.

## Campaign integration requirements

Place the bay as an optional Array branch with an unconditional return. Keep its entry interaction separated from existing Array controls. Record its archive transactionally, without a kill requirement. Track defeated actors per room for the current life, so simply leaving and returning does not resurrect them; death resets those transient defeats. Keep the patrol out of entrance, archive and recovery bounds. Verify actual campaign approach/retreat, archive save failure, re-entry, death, pause and controller disconnect before enabling it in the live game.

## Campaign integration

The Array's new upper inspection door is reached by two one-way shelves, separate from its floor controls. The bay has an unconditional return, an upper bypass and transactional inspection_archive discovery. exploration_noise.gd uses the validated turn pause and existing combat rules. exploration_world.gd owns a per-life cleared-room set: defeats survive room changes, while death clears transient defeats and respawns NOISE outside the entry zone. A new session also re-forms enemies. Persistent archive progress is independent.

inspection_campaign_test.gd passes actual Array approach, bypass, failed archive save, successful retry without combat, controller-disconnect pause, dash defeat, exit/re-entry without resurrection, death re-formation, safe spawn and archive reload. Both full campaign order tests still complete through ending and saved reconstruction. The rendered bay was inspected on the NVIDIA Compatibility renderer; capture: test-user/inspection-campaign.png.

This is the first exploration encounter, not a completed enemy roster or final animation pass. Additional enemy types, placement across districts, readable defeat animation and human combat feel review remain open. The current downloadable Windows archive predates this bay.
