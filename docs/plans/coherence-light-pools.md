# Decorative coherence light pools

Repaired first beacon and workshop window now illuminate nearby background detail using a cached 64 by 64 procedural alpha field. Sixteen falloff steps, displayed at exactly 2x with nearest sampling, keep the effect on the pixel grid. This is original runtime-generated light data, not an edited art asset or an imported shader.

The beacon uses a cool pale tint and the window a restrained warm tint. Pools are drawn before platforms, controls, player and HUD, so the effect cannot obscure those silhouettes. It does not change collisions, discovery, hazard visibility or enemy rules. There is no flicker or pulsation, including with reduced flashes off.

Activation interpolates to full power over 0.8 seconds of unpaused gameplay. Loaded repaired profiles start fully lit, and room changes do not restart the fade. Existing beacon/window state remains the source of truth.

NVIDIA Compatibility captures: test-user/beacon-unlit.png, beacon-light-half.png, beacon-light-pool.png, window-unlit.png and window-light-pool.png. Actual 24-physics-frame activation capture reports power 0.4792; the later capture reports 1.0. Beacon and window rendered results inspected. The cached texture is created once per exploration scene, not every frame.

This is a decorative light response, not shadow casting or a completed darkness mechanic. Authored dark routes, moving lights, occlusion and broader lighting/performance review remain future work. Avoid combining a new darkness rule with the first enemy lesson.
