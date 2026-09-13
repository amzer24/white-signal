# Inspection NOISE sprite

The exploration patroller now uses a PixelLab damaged-meter sprite inside its unchanged contact outline. The inner slit contracts during the existing 0.35-second turn pause. Foot offsets alternate only while walking and only with reduced-flash disabled; reduced-flash mode retains a static silhouette and the same readable slit contraction. No whole-body flashing or collision changes.

Inspection campaign regression: 0 failures (avoidance, archive save/retry, pause, dash, life/re-entry and respawn contracts). `noise_sprite_capture.gd` captures actual walking and turn states, with observed turn_time=0.35. Both native game views were inspected. Existing classic enemy rendering is unchanged.

Free OpenCode review: `opencode/mimo-v2.5-free`, session `ses_f66a606a3ffe3UZ9QPf7C4yl44`, reported cost 0; generic brief only. Accepted restrained foot motion and stable bounds. Rejected shadow contraction as the main cue because it is unreliable against the floor. Its proposed rule that any additional changed pixel is a flash violation was not adopted as an accessibility standard. Human readability and broader accessibility review remain pending.

The original source has more pixels than the destination and uses nearest sampling. A purpose-authored animation sheet and full biome enemy roster remain unfinished. The current downloadable package predates this sprite.
