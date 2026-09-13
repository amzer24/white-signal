# Optional Siphon branch

Entrance: repaired pump house, upper platform beside the pump socket. Return: opened service stair to the lookout; the pump exit always remains available from the central dry dock.

Sequence: transfer water right, ride to the upper catch, pin the float, return to the central valve, drain right, use the held float to reach the lower service wheel. The wheel permanently opens the lookout shortcut. The left archive is optional and not part of Gate commissioning.

Temporary state: water distribution and float catch reset on room entry/death. Permanent flags: `siphon_archive`, `siphon_return`, using the existing transactional profile. The map has a Siphon Service page. Keyboard, controller, pause and disconnect handling come from Exploration.

Evidence: input-driven room route, reload/reset shortcut checks and complete existing ending journey pass in staging. Actual Godot room and map captures reviewed. Geometry deliberately retains the prototype's verified one-way ledges and floats. Production art, broader approach/revisit playtests, save-failure matrix and final puzzle readability remain unfinished.
