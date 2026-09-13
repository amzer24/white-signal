# Controller support

Exploration: left stick or D-pad movement; A jump; RB dash; X use; Y map; LB map page; Start pause; B close/resume; X reduced flash while paused; View return to title while paused. Title and settings: D-pad navigate/adjust, A confirm, B back. Existing keyboard bindings remain. Prompts follow the last meaningful controller or keyboard/button input. Disconnecting the active controller pauses exploration and releases held actions.

Validation: synthetic controller events cover map paging, pause, activation, disconnect, and settings navigation. Keyboard/settings and exploration regression tests pass. No physical controller was connected.

Remaining release work: physical hardware QA, configurable bindings, analog menu navigation, classic-mode draft/pause gamepad handling, full controller HOW TO PLAY page, and held-button scene-transition checks. This is an exploration controller foundation, not complete controller certification.
