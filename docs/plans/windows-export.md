# Windows development export

13 September 2026. Staging export only; not a polished release or an installed source update.

Preset: Windows Development in export_presets.cfg. Uses existing matching 4.7.2.stable x86_64 templates from E:/Godot games/Tooling/export-templates/4.7.2. Paths are machine-specific.

Artifacts: build/windows/WHITE SIGNAL.exe, WHITE SIGNAL.pck, optional console executable. Keep executable and PCK together. SHA256 inventory: build-manifest.json.

Verification: --export-debug exited 0. The exported executable, started with its build directory as working directory, ran the default title scene headlessly for 120 process frames and exited 0. This is startup coverage, not a physics journey test. Export log confirms data/flats_rooms.json inclusion. Development test and capture scripts, prototypes, test-user and research documents are excluded.

Sandbox reported inaccessible editor settings during export and a certificate-store warning during launch. No script/resource loading errors appeared in launch log. Logs: test-user/windows-export.log and windows-launch.log.

Remaining: inspect rendered standalone game, exercise Exploration map and campaign from an isolated profile, test save/relaunch, audit package contents and provenance, produce a distributable archive after those checks. Do not infer release readiness from this smoke check.

## Packaged map and restart check

External harness: white-signal-team/export_qa.gd. First pass uses a fresh isolated absolute profile, opens map with M, advances with Tab, closes with Escape, directly enters Lookout and activates its survey. It checks packaged background/window resources, parsed Flats room data, hinted neighbours and surveyed-but-unvisited rooms. This is component coverage, not a traversal playthrough.

A second OS process loads that same profile and verifies restored Lookout/survey, Drowned outlines and hidden Gate. It renders the map using OpenGL Compatibility on NVIDIA RTX 4070. Screenshot was visually inspected: current room, surveyed label, hollow outlines, hints and controls are legible. Both passes report EXPORT QA: 0 failures and exit 0.

Execution uses the Godot editor binary with --main-pack pointing to the exported PCK and --script pointing to the external harness. The Windows template ignores the external script option; its earlier timed-out attempt is not test evidence. Template startup and packaged-data verification are separate claims. Logs and screenshot: white-signal-team/export-qa/pack-first.log, pack-resume.log, map.png. No normal player save was modified.
