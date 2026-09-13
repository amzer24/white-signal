# Campaign journey fixture isolation

The Drowned-first and Wire-first harnesses previously inherited one literal opening_playthrough.json path. Concurrent execution could delete or replace the other process's profile, producing false progression failures.

The shared harness now creates a res://test-user path from the actual script basename and OS process ID. The same path is retained through scene reconstruction and used for exact .json/.tmp/.bak cleanup. This permits different orders and repeated concurrent instances without sharing a save. No player profile or runtime gameplay file path was changed.

Verified simultaneous fixed-60Hz runs: opening_playthrough_test PID 56452 and wire_first_playthrough_test PID 29380 both exited 0 with 0 failures. Logs print distinct paths. Both final profile files were absent after completion. Earlier guidance to serialize these two tests is superseded for this version of the harness. Long-lived multi-process save conflict testing remains separate from fixture isolation.
