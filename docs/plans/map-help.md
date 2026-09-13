# Map discovery help

Every exploration map now offers H (keyboard) or X (controller) for a shared legend. It explains visited names, adjacent unknown signals, survey outlines, current location, dim routes and distant hidden places. The Lookout survey remains an earned discovery; help reveals no room names or progression.

Escape/B returns from help to the map while retaining pause. M/Y closes both; changing district dismisses help. Opening the map always starts on its map view.

Validation: map_help_test.gd passed keyboard and simulated controller navigation, paging and pause/resume. map_help_capture.gd rendered the 480x270 legend and the captured image was inspected for fit. Physical controller testing remains pending. Headless shutdown reported existing resource-leak warnings; these checks do not establish a clean lifecycle release gate.
