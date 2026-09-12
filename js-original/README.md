# MONO_RUNNER — pixel art 2D side scroller (monochrome)

Mechanics-first prototype. Level is pure geometric shapes, no assets.

## Run

Any static server (or just open the file):

```bash
python3 -m http.server 8000
# → http://localhost:8000/index.html
```

Or: `xdg-open index.html`

## Files

- `index.html` — canvas 480×270 scaled up, HUD, overlay, touch controls
- `style.css` — monochrome theme, `image-rendering: pixelated`
- `level.js` — `window.LEVEL`: platforms, movers, spikes, gems, enemies, checkpoints, goal
- `game.js` — engine: fixed-clamped loop, AABB collisions, camera, parallax, particles, SFX

## Mechanics in place

- Run: accel 1150, friction 1500, max 135px/s, air control 780, skid feel
- Jump: variable height (hold = higher), coyote 0.10s, buffer 0.12s
- Corner correction: ceiling grazes ≤4px slide past (no dead-stop)
- Collisions: X-then-Y AABB resolve, ride moving platforms
- Camera: look-ahead + velocity lead, lerped, clamped to level
- Hazards: spikes ▲, pits, patroller enemies (stomp them)
- Systems: gems ◆, checkpoints (mend AEGIS + refill dash/jumps), deaths,
  timer, win gate, pause, respawn (R), best-run persistence (localStorage)
- Remix routes: FEATHER/2×JUMP-gated high line + DASH-gated shortcut (Z1)
- Cursed glyph row: HEAVY (+25% jump, 35% heavier), GLASS (+50% run, +1 jump,
  any hit kills) — separate 2-notch budget, second HUD row

## Next steps for pixel art pass

1. Replace `drawPlayer` rect with sprite frames (same 12×14 hitbox)
2. Replace platform hatch with tileset
3. Keep palette: `#0b0b0b #3a3a3a #8a8a8a #f2f2f2`
