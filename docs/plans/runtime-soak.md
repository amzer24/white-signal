# Current-content runtime sample

Measured on the actual NVIDIA GeForce RTX 4070 Compatibility renderer at the game's 480x270 logical viewport. Each of six rooms received 90 process frames of warm-up, then 120 rendered frames, with Engine.max_fps explicitly set to 60. The shaft includes active motor/lift and archive replay; other rooms use normal idle mechanics. This is not a player-driven combat stress test or a minimum-hardware benchmark.

| Room | Frame median ms | Frame p95 ms | Max ms | Max draw calls |
|---|---:|---:|---:|---:|
| array_inspection | 16.669 | 16.956 | 17.167 | 24 |
| arrival | 16.658 | 16.968 | 17.412 | 32 |
| conductor | 16.685 | 16.985 | 17.075 | 23 |
| drowned_gallery | 16.661 | 17.054 | 17.215 | 34 |
| wire_carriage | 16.654 | 16.969 | 17.333 | 22 |
| wire_shaft | 16.683 | 16.974 | 17.378 | 58 |

At matching shaft checkpoints after 10, 30 and 60 five-room cycles (300 total transitions), counts held at 24 nodes, 1593 objects and 38 resources. Tracked static memory grew from 37,561,086 to 37,562,566 bytes (+1,480 bytes). This supports no obvious per-transition node/resource accumulation during this run; it does not prove absence of leaks.

Godot TIME_PROCESS samples are periodically refreshed and showed a 20.397ms p95 value for Array despite sub-17.5ms rendered intervals. They may include nearby loading/callback work and are retained in the raw report, not treated as precise per-frame CPU timings. The initial uncapped short sample had stale process readings and was superseded by this explicit capped run. No GPU headroom or long-session claim is made.

Harness: scripts/runtime_soak_test.gd. Raw retained evidence: runtime-soak-report.json. Profile was disposable and removed. Final scene teardown also captured counts in the report. Full polished content, combat/action stress, loading hitches, hours-long sessions, low-end hardware and exported-executable profiling remain unverified.
