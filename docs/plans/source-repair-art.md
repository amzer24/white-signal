# Source repair machinery

The staging Source now has recessed cabinet bays and a buried common bus. In the common-return chamber, the knife switch opens while four separate conductors light in sequence toward the bridge motor. Seven dark deck sections rise from a recessed cradle during verification. The standard solid platform appears only after the successful profile transaction; decorative sections have no collision. A steady muted green light surrounds the powered motor.

Animation reads the existing diagnostic timer, so map/pause freezes it and leaving or dying returns unfinished machinery to its idle state. Saved verification reconstructs the completed visual directly. No new timer, save flag, flashing effect or gameplay collider was introduced. Final beam/platform rendering remains above this background pass.

Rendered completed chamber inspected at the actual viewport. Idle and intermediate captures are included in source_campaign_capture.gd. This is an initial mechanical art pass; bespoke Source landmark assets, audio and human readability testing remain unfinished.

The machinery art was installed with hash verification and backups in install-source-art-backup. A later staged cue pass adds three quiet low-register verification ticks and a longer fourth tone only after successful saving. It uses the existing SFX bus and frame-driven diagnostic time, avoiding delayed timer queues and replay on reload. A slow frame emits only the most recent crossed step. A failed save emits one low rejection tone.

source_audio_test.gd passed with 0 failures, observing actual AudioStreamPlayer creation: individual feed ticks, map pause, four total successful cues, no completed-action/reset replay, rejection without a success burst, and an immediately audible retry after a failed write. Listening and music-mix judgement remain pending before installation.

Free review: OpenCode mimo-v2.5-free, session ses_f66792d31ffe93naT3WmVPeYMH, completed at reported cost 0. Accepted a restrained rising pitch grammar and distinct failure cue; changed the middle tick to a minor third (110, 130.81, 165, 220 Hz). Rejected its five-second timestamp debounce because it would suppress valid rapid retries. Rejected extra hum/reverb and delayed completion scheduling for now. Its example major arpeggio contradicted its own minor-interval recommendation; the root chose the minor version. No source files were supplied to the worker.

source_audio_capture.gd now records the actual synthesized streams produced by gate_mechanism into a four-second audition: three feed ticks, successful lock, then a separate failed-save example. Output test-user/source-repair-audition.wav contains five cues; peak 2304/32768 (about -23 dBFS), no sample clipping. This is the source signal before user bus gains and without the score; it does not prove audibility or a finished mix. Capture succeeded and the preview was provided for listening. Cue changes remain staged.

The cue implementation is approved for the development build on functional evidence, with final listening/mix kept as an unresolved release requirement. install_source_audio.py performs the checked installation; its backup manifest, rather than this planning note, is the installation receipt.
