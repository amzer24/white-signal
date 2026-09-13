# Source campaign adapter preparation

source_district_rooms.gd defines the measured gantry/isolation/commissioning geometry under IDs gate, source_return and source_walk. It is now merged into the staging room registry and save whitelist. Live installation remains pending.

The old gate ID and gate_latched/gate_isolated/gate_tested/signal_restored flags are retained. Read-only derived progress treats a later saved stage as evidence of its prerequisites, without rewriting the profile. Latched work supplies return stairs; tested work supplies the independent bridge. A completed old save retains an additional ground-level gate-to-aftermath exit, avoiding a new mandatory movement challenge after completion.

source_adapter_test.gd: 0 failures across fresh, latched, isolated, tested and completed flag fixtures. Checks old schema validity, no input flag mutation, known exit targets, appropriate geometry and completed route home. This is data/schema evidence, not actual disk migration, failed-write, runtime gate or physical traversal proof. One GDScript inferred-type parse error in the harness was corrected before the passing run.

Staging integration now includes room-scoped actions, transactional verification, pending-sequence cancellation, updated map/guidance, and flag-derived one-way collision geometry. Both complete input journeys (Drowned-first and Wire-first) passed with 0 failures through the new finale and ending reload. source_campaign_test.gd passed the actual air-jump/dash crossing, all three rooms, commissioning, and rebuilt return stairs/bridge. gate_test.gd passed the four-feeder gates and failed restoration write. Rendered gantry and Source map inspected; the map's home-return line was rerouted below Stand to avoid implying a nonexistent connection. Source art remains blockout quality.

## Circuit persistence preparation

source_circuit.gd now supplies the staged room-scoped controller. Securing the bus persists immediately. Isolation starts a 1.5-second transient verification; pausing freezes it, leaving the room or explicit death cancellation discards it. Successful verification writes gate_isolated and gate_tested in one profile transaction, so failed writes cannot deploy a bridge. Previously completed profiles derive prerequisite state without rewriting their flags.

source_circuit_test.gd passed with 0 failures using a disposable real disk profile: missing feeders, incorrect action room, premature commissioning, pause, exit/death cancellation, failed write rollback, retry, disk reconstruction, restoration, and read-only legacy completion. gate_mechanism now delegates to this controller. No live install has yet been performed. Remaining pre-install work: scene-level old-save and failed-diagnostic geometry reconstruction, review corrected map rendering, refresh campaign inventory, and checked installation. Bridge deployment still needs a final animation/art pass; human route-comprehension testing remains outstanding.

## Pre-install reconstruction evidence

source_reconstruction_test.gd passed with 0 failures: four old disk-save stages, read-only prerequisite derivation, completed floor exit, bridge reconstruction, actual scene map pause, death/exit cancellation, failed diagnostic retaining closed geometry, successful retry, and new-room disk reload. Corrected map rendering inspected. Inventory refreshed to 39 rooms with no broken targets or structural orphans. Full-game completion and final art remain unproven.
