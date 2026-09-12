/* LEVEL 01 — GEOMETRY FLATS v2
 * 3 themed zones (Celeste-style: teach → challenge → remix).
 * Units = world pixels. Ground Y = 230. x right, y down.
 * New types: crumbles (fall after stand), springs (launch), signs (teach text).
 */
window.LEVEL = {
  name: "GEOMETRY FLATS v2",
  width: 3800,
  height: 270,
  spawn: { x: 30, y: 180 },
  killY: 300,
  goal: { x: 3700, y: 150, w: 26, h: 80 },

  zones: [
    { x0: 0, x1: 1150, name: "Z0 · FLATS", sub: "learn to move" },
    { x0: 1150, x1: 2420, name: "Z1 · RUINS", sub: "crumble + spring" },
    { x0: 2420, x1: 3800, name: "Z2 · GATE", sub: "climb + sprint" },
  ],

  platforms: [
    // ---- Z0 FLATS: safe teach ----
    { x: 0, y: 230, w: 380, h: 40, type: "ground" },
    { x: 410, y: 230, w: 220, h: 40, type: "ground" },
    { x: 660, y: 230, w: 200, h: 40, type: "ground" },
    { x: 800, y: 186, w: 16, h: 44, type: "block" }, // practice wall: jumpable, or slide + kick
    { x: 880, y: 210, w: 50, h: 60, type: "block" },
    { x: 930, y: 190, w: 50, h: 80, type: "block" },
    { x: 980, y: 170, w: 50, h: 100, type: "block" },
    { x: 1030, y: 170, w: 140, h: 20, type: "block" },
    // ---- Z1 RUINS: risk ----
    { x: 1210, y: 230, w: 260, h: 40, type: "ground" },
    // pit with secret floor (drop in, jump out) — ground split so secret is reachable
    { x: 1760, y: 230, w: 120, h: 40, type: "ground" },
    { x: 1940, y: 230, w: 120, h: 40, type: "ground" },
    { x: 1990, y: 150, w: 110, h: 12, type: "block" },   // spring landing (widened)
    { x: 2060, y: 230, w: 380, h: 40, type: "ground" }, // low-ceil corridor floor (reaches the shaft)
    { x: 2100, y: 170, w: 160, h: 12, type: "block" },  // low ceiling
    // ---- Z2 GATE: climb + climax ----
    { x: 2440, y: 230, w: 200, h: 40, type: "ground" },
    // wall shaft — alternating kicks to the top ledge (96px inner gap).
    // LEFT wall bottom raised to 200: a 30px walk-through passage at ground
    // level (the shaft is a climb you ENTER, not a wall that blocks entry).
    { x: 2436, y: 120, w: 16, h: 80, type: "block" },
    { x: 2548, y: 120, w: 16, h: 110, type: "block" },
    { x: 2520, y: 75, w: 140, h: 20, type: "block" },
    { x: 2700, y: 230, w: 300, h: 40, type: "ground" },
    { x: 3040, y: 230, w: 760, h: 40, type: "ground" },
    { x: 3220, y: 190, w: 80, h: 12, type: "block" },
    { x: 3340, y: 190, w: 80, h: 12, type: "block" },
    // secret alcove floor at bottom of pit (reachable!)
    { x: 1882, y: 254, w: 56, h: 10, type: "secret" },
    // ---- REMIX ROUTES (GDD §7): safe skip vs risky shortcut ----
    // HIGH LINE — 58px above spring ledge top (150): max jump rise is 57.5px,
    // so it needs SPRING (82px) or 2×JUMP. Floats over the spike corridor.
    { x: 2060, y: 92, w: 48, h: 12, type: "block" },  // high line pad 1
    { x: 2140, y: 92, w: 48, h: 12, type: "block" },  // high line pad 2
    { x: 2220, y: 92, w: 48, h: 12, type: "block" },  // high line pad 3
    // DASH SHORTCUT — 112px gap from high line end (2268): plain full jump's
    // feet cross pad level at x≈2352, 28px short (dash REQUIRED). Jump+dash
    // lands x≈2390-2440 — 60px of fair margin on a 96px pad. Pad right end
    // sits beside the shaft top ledge (2520) so the shortcut skips the
    // corridor AND the shaft. Landing short drops onto the corridor floor
    // (risk = the spike bed), never a softlock.
    { x: 2380, y: 100, w: 96, h: 12, type: "secret" }, // dash gate pad (dashed = risky optional)
  ],

  // crumble bridges over voids
  crumbles: [
    { x: 1500, y: 205, w: 70, h: 12 },
    { x: 1580, y: 205, w: 70, h: 12 },
    { x: 1660, y: 205, w: 70, h: 12 },
    { x: 2740, y: 195, w: 60, h: 10 },
    { x: 2810, y: 195, w: 60, h: 10 },
    { x: 2880, y: 195, w: 60, h: 10 },
  ],

  springs: [
    { x: 1946, y: 212, w: 24, h: 18, power: 540 }, // pit-edge → high ledge (hold RIGHT)
    { x: 3118, y: 212, w: 24, h: 18, power: 500 }, // hop to high gems
  ],

  movers: [
    // Z0→Z1 ferry: top level with the ledge (170), never slides under it
    // (min x 1180 > ledge end 1170) — ride across, or just jump the 40px pit
    { x: 1210, y: 170, w: 60, h: 10, axis: "x", range: 30, speed: 1.2, phase: 0 },
    { x: 2655, y: 190, w: 70, h: 10, axis: "y", range: 45, speed: 1.3, phase: 1 },
  ],

  spikes: [
    { x: 1380, y: 218, w: 48, h: 12 },
    { x: 2180, y: 218, w: 60, h: 12 },
    { x: 3180, y: 218, w: 48, h: 12 },
    { x: 3480, y: 218, w: 72, h: 12 },
  ],

  gems: [
    // Z0 easy line
    { x: 450, y: 190 }, { x: 700, y: 190 }, { x: 808, y: 150 }, { x: 1080, y: 130 },
    // Z1 risk / secret
    { x: 1615, y: 165 },
    { x: 1892, y: 238, secret: true }, { x: 1912, y: 238, secret: true },
    { x: 1960, y: 175 }, { x: 1990, y: 130 }, // spring arc guide
    { x: 2040, y: 110 },
    { x: 2180, y: 140 }, { x: 2220, y: 140 },
    // Z2 high / climax
    { x: 2500, y: 170 }, // mid-shaft guide
    { x: 2590, y: 40 },
    { x: 2770, y: 155 }, { x: 2840, y: 155 }, { x: 2910, y: 155 },
    { x: 3120, y: 150 }, { x: 3100, y: 175 }, { x: 3140, y: 175 },
    { x: 3260, y: 150 }, { x: 3380, y: 150 },
    // remix-route rewards
    { x: 2180, y: 72 },  // high line cluster (above pad 2)
    { x: 2420, y: 80 },  // dash-gate reward (over the pad, mid-shaft)
  ],

  enemies: [
    { x: 1820, y: 212, w: 14, h: 18, minX: 1780, maxX: 1866, speed: 50 }, // stays on left ledge (pit + spring at 1882+)
    { x: 2120, y: 212, w: 14, h: 18, minX: 2070, maxX: 2360, speed: 70 },
    { x: 3100, y: 212, w: 14, h: 18, minX: 3060, maxX: 3300, speed: 85 },
    { x: 3500, y: 212, w: 14, h: 18, minX: 3420, maxX: 3660, speed: 100 },
  ],

  checkpoints: [
    // y = ground base the beacon stands on (pole draws upward from here)
    { x: 880, y: 210 },
    { x: 1760, y: 230 },
    { x: 2460, y: 230 },
    { x: 3040, y: 230 },
  ],

  signs: [
    { x: 80, y: 208, text: "ARROWS MOVE" },
    { x: 450, y: 208, text: "HOLD JUMP = HIGHER" },
    { x: 730, y: 208, text: "WALL: HOLD IN + JUMP" },
    { x: 1240, y: 208, text: "CRUMBLE! KEEP MOVING" },
    { x: 1855, y: 208, text: "SPRING UP: HOLD RIGHT" },
    { x: 2030, y: 208, text: "HIGH LINE UP TOP" },
    { x: 2500, y: 208, text: "WALL JUMP UP" },
    { x: 3060, y: 208, text: "SPRING!" },
  ],

  deco: [
    { x: 200, y: 60, s: 40 }, { x: 700, y: 40, s: 70 },
    { x: 1200, y: 80, s: 30 }, { x: 1600, y: 50, s: 90 },
    { x: 2100, y: 60, s: 50 }, { x: 2600, y: 40, s: 80 },
    { x: 3100, y: 50, s: 60 }, { x: 3550, y: 60, s: 46 },
  ],
};
