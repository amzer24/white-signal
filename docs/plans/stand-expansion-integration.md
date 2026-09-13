# Expanded Stand integration

Seven rooms replace the two-room foundation: Broken rim, Shelter court, Charge bay, Reservoir walk, Latched bridge, Sluice shelter and optional Fracture trial. Existing shelter/conductor IDs remain safe entries for schema-1 profiles. New IDs extend the whitelist without rewriting old profiles. External Field, Drowned and Wire routes point to rim, sluice and bridge respectively; Approach still returns to court.

Stored charge persists across internal transitions and resets on respawn/district exit. The motor saves stand_restored before opening bridge geometry. Trial collapse resets locally; stand_archive commits before the stable return appears. Failed writes leave both unlocks closed and retain motor charge for retry. Old completed repairs and Dash retain expanded bridge/Wire access.

Verification: fresh Drowned-first input journey traverses the expanded Stand, all four feeders, Gate/ending, hub revisit and saved scene reconstruction with zero failures at fixed 60 Hz. Expanded forward/reverse/Sluice route, save-failure and legacy-profile checks, historical Stand contract, controller and Siphon checks pass. No physical controller attached. NVIDIA-rendered reservoir and internal seven-room map inspected. Capture visits rooms directly and is not discovery-order evidence.

Source blockout and verdict: prototypes/stand_blockout.gd and prototypes/STAND-VERDICT.md. Those artifacts are excluded from exports. No claim that prototype evidence alone verifies integration.

Remaining: Wire-first full journey, optional trial timing accessibility, deliberate upgraded movement skips, external map boundary clarity, human-paced visual/audio review and final environmental art. This is a playable seven-room foundation, not a polished district. The current standalone Windows export predates the expansion and must be rebuilt before distribution.
