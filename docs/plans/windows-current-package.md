# Current Windows development package

Source checkpoint d7d49be, 13 September 2026. Runtime assets/scripts match the live project; the main scene was copied from live before export. Staging export exclusions additionally omit diagnostic probes and background_fingerprint.gd; this exclusion correction is installed alongside this note.

Artifact: build/WHITE-SIGNAL-development-current.zip (43,416,243 bytes). SHA256 7837097a6b6cf2e3e6bb2f704c872f0c51d0be358e89db82e0e33298a9f138c3. Per-file hashes are in windows-current-package.json. ZIP CRC and every payload SHA256 were verified. This replaces the older receiver package as the newest local development download, not as a finished release.

## Evidence

- All 13 checks from scripts/validate_exploration.py passed, including both complete campaign input orders, shutter route, Extras, remapping, saves and revisit checks.
- The exported PCK was loaded with Godot 4.7.2 editor-capable binary and an external harness. It contains the new Source receiver, aftermath town, shutter room, previous biome assets and pump audio; diagnostic scripts and Drowned music originals are excluded. Rendered PCK asset check exited zero.
- The complete opening input journey ran against that PCK using an external copy of the existing route harness. Only inheritance paths, isolated user profile path and ending cleanup were adapted; gameplay inputs remained unchanged. It reached all feeder repairs, Source restoration, aftermath, hub return and scene reconstruction with zero failures.
- The retained user://standalone-journey.json was opened in a new process against the same PCK. Ending, all four feeders, Dash, Air Jump and aftermath revisit exit were retained, with no save-byte mutation during load. Reload exited zero.
- The actual exported WHITE SIGNAL.exe rendered the title with Start Exploration, Classic, Settings, How to Play, Extras and Quit visible. Its documented --write-movie option captured three frames; exit code zero. An isolated APPDATA kept this separate from the user's save.

## Important limit

The first external --script attempt on the exported EXE printed no harness marker. Inspection of that executable's --help confirmed that --script is not exposed by this debug export template; the idle process was stopped. It did not run the input journey. The subsequent PCK tests use the editor-capable engine and are not evidence of a full standalone EXE playthrough. No hidden test loader or shipping test hook was added.

The environment certificate-store warning appeared in sandboxed logs. No script/parse/assertion errors occurred in the successful checks. Numerical startup/movie timings are not a performance profile.

Working evidence: white-signal-team/current-pck-journey.*, current-pck-reload.*, current-pack.*, current-exe-title.*, current-package.json. The external harness lives in white-signal-team/standalone-current-qa. The development script runner logs live under test-user/ci-exploration.

OpenCode mimo-v2.5-free session ses_f65cf9432ffeMZBSpKyz99BEZq reported cost zero for a generic scope review. Its claim that the proposed scope already proves the binary works was not accepted as evidence; actual runs established the narrower results above. Physical-device, human comprehension, full standalone gameplay, broader finished-content art/audio and release rights checks remain open.
