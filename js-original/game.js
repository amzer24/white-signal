/* MONO_RUNNER v2 — staged upgrade
 * Stage 1: zones, crumbles, springs, signs, secrets
 * Stage 2: 1-bit dithering, squash & stretch, dust, danger language, parallax
 * Canvas 480x270, palette #0b0b0b #3a3a3a #8a8a8a #f2f2f2. All pixel-snapped.
 */
(() => {
  const canvas = document.getElementById("game");
  const ctx = canvas.getContext("2d");
  ctx.imageSmoothingEnabled = false;
  const W = 480, H = 270;
  const PAL = { bg: "#0b0b0b", dark: "#3a3a3a", gray: "#8a8a8a", white: "#f2f2f2" };

  const $ = (id) => document.getElementById(id);
  let draftRects = [], skipRect = null; // clickable regions, rebuilt each draft frame

  let AC = null;
  function beep(freq, dur = 0.07, vol = 0.06, type = "square") {
    try {
      AC = AC || new (window.AudioContext || window.webkitAudioContext)();
      if (AC.state === "suspended") AC.resume(); // iOS/Safari autoplay policy
      const o = AC.createOscillator(), g = AC.createGain();
      o.type = type; o.frequency.value = freq; g.gain.value = vol;
      o.connect(g); g.connect(AC.destination);
      o.start(); o.stop(AC.currentTime + dur);
    } catch (_) {}
  }

  const keys = {};
  const touch = { left: false, right: false, jump: false, dash: false };
  let dashQueued = false, prevDashHeld = false;
  addEventListener("keydown", (e) => {
    if (["ArrowLeft", "ArrowRight", "ArrowUp", "Space"].includes(e.code)) e.preventDefault();
    if (state === "draft") {
      if (e.code === "Digit1" || e.code === "Numpad1") pickCard(0);
      else if (e.code === "Digit2" || e.code === "Numpad2") pickCard(1);
      else if (e.code === "Digit3" || e.code === "Numpad3") pickCard(2);
      else if (e.code === "KeyS" || e.code === "Escape") skipDraft();
      return;
    }
    keys[e.code] = true;
    if ((e.code === "ShiftLeft" || e.code === "ShiftRight" || e.code === "KeyK") && !e.repeat) dashQueued = true;
    if (e.code === "KeyR") respawn(false);
    if (e.code === "KeyP") togglePause();
    if (["Space", "ArrowUp", "KeyW"].includes(e.code)) tryStart();
  });
  addEventListener("keyup", (e) => { keys[e.code] = false; });
  // stuck-input guard: alt-tab / focus loss / mobile gestures can eat keyup
  const clearInput = () => {
    for (const k in keys) keys[k] = false;
    touch.left = touch.right = touch.jump = touch.dash = false;
    dashQueued = false;
  };
  addEventListener("blur", clearInput);
  document.addEventListener("visibilitychange", () => { if (document.hidden) clearInput(); });
  const bindHold = (id, prop) => {
    const el = $(id);
    const on = (e) => { e.preventDefault(); touch[prop] = true; tryStart(); };
    const off = (e) => { e.preventDefault(); touch[prop] = false; };
    el.addEventListener("pointerdown", on);
    el.addEventListener("pointerup", off);
    el.addEventListener("pointerleave", off);
    el.addEventListener("pointercancel", off); // gesture stolen by browser scroll
    el.addEventListener("contextmenu", (e) => e.preventDefault()); // long-press menu
  };
  bindHold("t-left", "left"); bindHold("t-right", "right"); bindHold("t-jump", "jump"); bindHold("t-dash", "dash");

  const L = window.LEVEL;
  let state = "menu";
  let cam = { x: 0, y: 0 };
  let time = 0, deaths = 0, fps = 60, lastFpsT = performance.now(), frames = 0;
  let gemsCollected = 0, gems = [], movers = [], enemies = [], particles = [];
  let crumbles = [], springs = [];
  let checkpoint = { ...L.spawn };
  let shake = 0, hitstop = 0, newBest = false;
  let zoneIdx = 0, zoneBannerT = 0;
  let runDustT = 0;

  const P = {
    x: L.spawn.x, y: L.spawn.y, w: 12, h: 14, vx: 0, vy: 0,
    onGround: false, coyote: 0, buffer: 0, jumpHeld: false,
    face: 1, anim: 0, sx: 1, sy: 1, springT: 0,
    airJumps: 0, dashReady: false, dashT: 0, dashDirX: 1, invuln: 0, shieldChg: 0,
    touchWall: 0, wallCoyote: 0, wallDir: 1, wallTopY: 0, sliding: false,
  };
  const TUNE = {
    maxRun: 135, accel: 1150, airAccel: 780, friction: 1500,
    gravity: 920, jumpVel: 325, shortHopMult: 0.45,
    coyote: 0.10, buffer: 0.12, maxFall: 390,
    fallMult: 1, airJumps: 0, dash: false, magnetR: 13, shieldMax: 0, stompPlus: false, glass: false,
  };
  const BASE = { ...TUNE };

  // ---------- GLYPH DECK (platformer x deckbuilder) ----------
  // Hades-style 1-of-3 draft at checkpoints + Hollow Knight charm-notch capacity.
  const CARDS = {
    dash:    { g: "≫", n: "DASH",   cost: 2, d: "Air dash · SHIFT · kills foes", fx: () => { TUNE.dash = true; } },
    jump2:   { g: "²", n: "2×JUMP", cost: 2, d: "+1 air jump",                    fx: () => { TUNE.airJumps += 1; } },
    feather: { g: "~", n: "FEATHER",cost: 1, d: "−30% fall speed · floaty",      fx: () => { TUNE.fallMult = 0.7; } },
    swift:   { g: "»", n: "SWIFT",  cost: 1, d: "+25% run speed",                 fx: () => { TUNE.maxRun *= 1.25; TUNE.accel *= 1.2; TUNE.airAccel *= 1.15; } },
    spring:  { g: "⇑", n: "SPRING", cost: 1, d: "+20% jump height",               fx: () => { TUNE.jumpVel *= 1.2; } },
    magnet:  { g: "◎", n: "MAGNET", cost: 1, d: "Gems fly to you",                fx: () => { TUNE.magnetR = 46; } },
    aegis:   { g: "◈", n: "AEGIS",  cost: 1, d: "Survive 1 hit per life",         fx: () => { TUNE.shieldMax = 1; } },
    stomp:   { g: "▼", n: "STOMP+", cost: 1, d: "Shockwave stomps · +bounce",     fx: () => { TUNE.stompPlus = true; } },
    // --- cursed row (own 2-notch budget, second HUD row; risk/reward) ---
    heavy:   { g: "⇓", n: "HEAVY",  cost: 1, cursed: true, d: "+25% jump · 35% heavier", fx: () => { TUNE.jumpVel *= 1.25; TUNE.gravity *= 1.35; TUNE.maxFall *= 1.3; } },
    glass:   { g: "◇", n: "GLASS",  cost: 1, cursed: true, d: "+50% run · +1 jump · any hit kills", fx: () => { TUNE.maxRun *= 1.5; TUNE.accel *= 1.3; TUNE.airAccel *= 1.25; TUNE.airJumps += 1; TUNE.glass = true; } },
  };
  let deck = [], maxNotches = 3, cursedMax = 2, draftOpts = [], draftsSeen = 0, lastSurge = 0;
  const usedNotches = () => deck.reduce((s, id) => s + (CARDS[id].cursed ? 0 : CARDS[id].cost), 0);
  const usedCursed = () => deck.reduce((s, id) => s + (CARDS[id].cursed ? CARDS[id].cost : 0), 0);

  function applyDeck() {
    Object.assign(TUNE, BASE);
    for (const id of deck) CARDS[id].fx();
    P.airJumps = TUNE.airJumps;
    P.dashReady = !!TUNE.dash;
    P.dashT = 0;
    if (!TUNE.shieldMax) P.shieldChg = 0; else P.shieldChg = Math.max(P.shieldChg, 1);
  }

  function wrapDesc(s, n) { // greedy wrap for canvas cards
    const words = s.split(" "), lines = [];
    let cur = "";
    for (const w of words) {
      if ((cur + " " + w).trim().length > n) { lines.push(cur.trim()); cur = w; }
      else cur += " " + w;
    }
    if (cur.trim()) lines.push(cur.trim());
    return lines.slice(0, 3);
  }

  function openDraft() {
    state = "draft";
    draftsSeen++;
    const pool = Object.keys(CARDS).filter((id) => !deck.includes(id));
    // shuffle
    for (let i = pool.length - 1; i > 0; i--) { const j = (Math.random() * (i + 1)) | 0;[pool[i], pool[j]] = [pool[j], pool[i]]; }
    draftOpts = pool.slice(0, 3);
    if (draftsSeen === 1 && !deck.includes("dash") && !draftOpts.includes("dash")) {
      draftOpts[2] = "dash"; // first draft always offers the marquee verb
    }
    draftRects = []; skipRect = null; // rebuilt in drawDraft
    beep(660, 0.08);
  }
  function pickCard(i) {
    if (state !== "draft" || !draftOpts[i]) return;
    const id = draftOpts[i];
    if (CARDS[id].cursed) {
      if (usedCursed() + CARDS[id].cost > cursedMax) { beep(140, 0.1, 0.05, "sawtooth"); return; }
    } else if (usedNotches() + CARDS[id].cost > maxNotches) { beep(140, 0.1, 0.05, "sawtooth"); return; }
    deck.push(id);
    beep(523, 0.09); setTimeout(() => beep(784, 0.12), 90);
    burst(P.x + 6, P.y + 7, 12);
    applyDeck();
    closeDraft();
  }
  function skipDraft() {
    if (state !== "draft") return;
    beep(330, 0.07);
    closeDraft();
  }
  function closeDraft() {
    draftOpts = [];
    draftRects = []; skipRect = null;
    if (state === "draft") state = "play";
  }

  // 4x4 Bayer for ditherpunk shading
  const BAYER = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5];
  function bayer(x, y) { return BAYER[((y & 3) << 2) | (x & 3)]; }

  function resetLevel() {
    gems = L.gems.map((g, i) => ({ ...g, taken: false, id: i, bob: Math.random() * 6 }));
    movers = L.movers.map((m) => ({ ...m, ox: m.x, oy: m.y, dx: 0, dy: 0, t: m.phase || 0 }));
    enemies = L.enemies.map((e) => ({ ...e, dir: 1, ox: e.x }));
    crumbles = L.crumbles.map((c) => ({ ...c, shakeT: 0, broken: false, respawn: 0, standing: false }));
    springs = L.springs.map((s) => ({ ...s, anim: 0, cool: 0 }));
    particles = [];
    gemsCollected = 0; time = 0; deaths = 0; shake = 0; hitstop = 0; newBest = false;
    zoneIdx = 0; zoneBannerT = 0;
    deck = []; maxNotches = 3; draftsSeen = 0; draftOpts = []; lastSurge = 0;
    dashQueued = false; prevDashHeld = false; runDustT = 0;
    checkpoint = { ...L.spawn };
    placePlayer(L.spawn);
    applyDeck();
    cam.x = 0; cam.y = 0;
  }
  function placePlayer(pt) {
    P.x = pt.x; P.y = pt.y; P.vx = 0; P.vy = 0;
    P.onGround = false; P.coyote = 0; P.buffer = 0; P.sx = 1; P.sy = 1; P.springT = 0;
    P.dashT = 0; P.invuln = Math.max(P.invuln, 0.5);
    P.touchWall = 0; P.wallCoyote = 0; P.wallTopY = 0; P.sliding = false;
    P.airJumps = TUNE.airJumps; P.dashReady = !!TUNE.dash;
  }
  // AEGIS/shield absorbs lethal hits; pits still kill (execution beats protection)
  function lethalHit() {
    if (P.invuln > 0) return;
    if (TUNE.glass) { respawn(true); return; } // GLASS curse: any hit kills, AEGIS void
    if (P.shieldChg > 0) {
      P.shieldChg--; P.invuln = 1.2; P.vy = -220; P.onGround = false;
      burst(P.x + 6, P.y + 7, 12); shake = Math.max(shake, 4);
      beep(220, 0.15, 0.08, "sawtooth");
      return;
    }
    respawn(true);
  }
  function respawn(countDeath = true) {
    if (state !== "play" && state !== "pause") return;
    if (countDeath) { deaths++; beep(110, 0.2, 0.08, "sawtooth"); }
    burst(P.x + 6, P.y + 7, 14);
    shake = 5;
    // checkpoint.y is the ground base — stand the player on top of it
    placePlayer({ x: checkpoint.x, y: checkpoint.y - P.h });
    // reset crumbles near checkpoint so player never spawns stuck
    for (const c of crumbles) { c.broken = false; c.shakeT = 0; c.respawn = 0; }
    // world threat reset: dying re-forms every NOISE (kills stick per life only)
    enemies = L.enemies.map((e) => ({ ...e, dir: 1, ox: e.x }));
    state = "play";
  }
  function tryStart() {
    if (state === "menu" || state === "win") {
      resetLevel();
      state = "play";
      zoneBannerT = 2.5;
    }
  }
  function togglePause() {
    if (state === "play") state = "pause";
    else if (state === "pause") state = "play";
  }
  // canvas clicks drive every screen: menu / draft cards / pause / win
  canvas.addEventListener("click", (e) => {
    const r = canvas.getBoundingClientRect();
    const cx = (e.clientX - r.left) * W / r.width;
    const cy = (e.clientY - r.top) * H / r.height;
    if (state === "menu" || state === "win") { tryStart(); return; }
    if (state === "pause") { togglePause(); return; }
    if (state === "draft") {
      for (const rc of draftRects) {
        if (cx >= rc.x && cx <= rc.x + rc.w && cy >= rc.y && cy <= rc.y + rc.h) { pickCard(rc.i); return; }
      }
      if (skipRect && cx >= skipRect.x && cx <= skipRect.x + skipRect.w && cy >= skipRect.y && cy <= skipRect.y + skipRect.h) skipDraft();
    }
  });

  function burst(x, y, n = 8, spread = 160) {
    for (let i = 0; i < n; i++) {
      particles.push({
        x, y, vx: (Math.random() - 0.5) * spread, vy: -Math.random() * 140 - 20,
        life: 0.4 + Math.random() * 0.35, t: 0, s: Math.random() < 0.6 ? 1 : 2,
      });
    }
  }
  function dust(x, y, n = 4) {
    for (let i = 0; i < n; i++) {
      particles.push({
        x: x + (Math.random() - 0.5) * 8, y: y - Math.random() * 2,
        vx: (Math.random() - 0.5) * 70, vy: -Math.random() * 40,
        life: 0.3 + Math.random() * 0.2, t: 0, s: 1,
      });
    }
  }

  function activeSolids() {
    const list = L.platforms.concat(movers);
    for (const c of crumbles) if (!c.broken) list.push(c);
    return list;
  }
  function overlap(a, b) {
    return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
  }

  function moveAndCollide(dt) {
    // X axis — skip solids the player could be RIDING (feet at their top edge,
    // not rising). Stops a rising platform from ejecting its rider sideways.
    // Must NOT skip while rising (vy<0): that let the player tunnel into a
    // wall through its top-edge zone, and the Y-pass then snapped them to the
    // wall's BOTTOM — the "wall jump teleports me" bug.
    P.x += P.vx * dt;
    P.touchWall = 0;
    for (const s of activeSolids()) {
      if (P.vy >= 0 && (P.y + P.h) - s.y < 5) continue;
      if (overlap(P, s)) {
        if (P.vx > 0) { P.x = s.x - P.w; P.touchWall = 1; }
        else if (P.vx < 0) { P.x = s.x + s.w; P.touchWall = -1; }
        if (P.touchWall !== 0) P.wallTopY = s.y; // remember top edge for grace-kick gate
        P.vx = 0;
      }
    }
    P.x = Math.max(0, Math.min(L.width - P.w, P.x));
    // Y axis — resolve only to the side the player actually came from.
    const prevY = P.y;
    P.y += P.vy * dt;
    P.onGround = false;
    for (const s of activeSolids()) {
      if (overlap(P, s)) {
        const wasAbove = prevY + P.h <= s.y + 0.5;
        const wasBelow = prevY >= s.y + s.h - 0.5;
        if (P.vy > 0 && wasAbove) { P.y = s.y - P.h; P.vy = 0; P.onGround = true; if (s.shakeT !== undefined) s.standing = true; }
        else if (P.vy < 0 && wasBelow) {
          // corner correction: grazing a ceiling corner by ≤4px slides past
          // instead of dead-stopping the arc (GDD pillar 1 "jump correction")
          const ovL = (P.x + P.w) - s.x, ovR = (s.x + s.w) - P.x;
          if (Math.min(ovL, ovR) <= 4) {
            if (ovL < ovR) P.x = s.x - P.w - 0.5; else P.x = s.x + s.w + 0.5;
          } else { P.y = s.y + s.h; P.vy = 0; }
        }
      }
    }
    // ride movers — carry by delta, then snap flush (no drift, no teleport).
    // Skipped mid-dash: dash is gravity-free at fixed height, snapping onto a
    // mover mid-dash reads as a teleport.
    for (const m of movers) {
      const standing = P.dashT <= 0 && Math.abs((P.y + P.h) - m.y) < 4 && P.x + P.w > m.x + 1 && P.x < m.x + m.w - 1 && P.vy >= 0;
      if (standing) { P.x += m.dx; P.y = m.y - P.h; P.vy = 0; P.onGround = true; }
    }
    for (const c of crumbles) {
      if (c.broken) continue;
      const standing = Math.abs((P.y + P.h) - c.y) < 3 && P.x + P.w > c.x && P.x < c.x + c.w;
      if (standing) c.standing = true;
    }
  }

  function zoneOf(x) {
    for (let i = 0; i < L.zones.length; i++) if (x < L.zones[i].x1) return i;
    return L.zones.length - 1;
  }

  function update(dt) {
    if (hitstop > 0) { hitstop -= dt; return; }
    time += dt;

    for (const m of movers) {
      m.t += dt * m.speed;
      const off = Math.sin(m.t) * m.range;
      const nx = m.axis === "x" ? m.ox + off : m.ox;
      const ny = m.axis === "y" ? m.oy + off : m.oy;
      m.dx = nx - m.x; m.dy = ny - m.y; m.x = nx; m.y = ny;
    }
    for (const s of springs) { s.anim = Math.max(0, s.anim - dt * 5); s.cool = Math.max(0, s.cool - dt); }
    P.springT = Math.max(0, P.springT - dt);
    P.invuln = Math.max(0, P.invuln - dt);
    // crumbles
    for (const c of crumbles) {
      if (c.broken) {
        c.respawn -= dt;
        if (c.respawn <= 0) { c.broken = false; c.shakeT = 0; }
      } else if (c.standing) {
        c.shakeT += dt;
        if (c.shakeT > 0.45) { c.broken = true; c.respawn = 2.0; burst(c.x + c.w / 2, c.y + 4, 8, 100); beep(180, 0.12, 0.05, "sawtooth"); }
      } else c.shakeT = Math.max(0, c.shakeT - dt * 2);
      c.standing = false;
    }
    for (const e of enemies) {
      e.x += e.dir * e.speed * dt;
      if (e.x < e.minX) { e.x = e.minX; e.dir = 1; }
      if (e.x > e.maxX) { e.x = e.maxX; e.dir = -1; }
    }
    for (const g of gems) g.bob += dt * 4;

    const wasGround = P.onGround;
    const fallSpeed = P.vy;

    const left = keys.ArrowLeft || keys.KeyA || touch.left;
    const right = keys.ArrowRight || keys.KeyD || touch.right;
    const jumpDown = keys.Space || keys.ArrowUp || keys.KeyW || touch.jump;
    if (jumpDown && !P.jumpHeld) P.buffer = TUNE.buffer;
    P.jumpHeld = !!jumpDown;
    P.buffer -= dt; P.coyote -= dt; P.wallCoyote -= dt;

    const acc = P.onGround ? TUNE.accel : TUNE.airAccel;
    // skid dust
    if (P.onGround && ((left && P.vx > 80) || (right && P.vx < -80))) {
      runDustT -= dt;
      if (runDustT <= 0) { dust(P.x + 6, P.y + P.h, 1); runDustT = 0.06; }
    }
    // overspeed (wall-kick 1.15x burst) decays gently instead of hard-clamping,
    // so the kick boost is actually felt before settling back to max run
    if (left && !right) {
      P.face = -1;
      if (P.vx < -TUNE.maxRun) P.vx = Math.min(-TUNE.maxRun, P.vx + 350 * dt);
      else P.vx = Math.max(-TUNE.maxRun, P.vx - acc * dt);
    } else if (right && !left) {
      P.face = 1;
      if (P.vx > TUNE.maxRun) P.vx = Math.max(TUNE.maxRun, P.vx - 350 * dt);
      else P.vx = Math.min(TUNE.maxRun, P.vx + acc * dt);
    }
    else if (P.onGround) {
      const f = TUNE.friction * dt;
      P.vx = Math.abs(P.vx) <= f ? 0 : P.vx - Math.sign(P.vx) * f;
    } else P.vx *= (1 - 0.4 * dt);

    if (P.onGround) P.coyote = TUNE.coyote;
    if (P.buffer > 0 && P.coyote > 0) {
      P.vy = -TUNE.jumpVel; P.buffer = 0; P.coyote = 0; P.onGround = false;
      P.sx = 0.72; P.sy = 1.32; // stretch
      beep(440 + Math.random() * 60, 0.08);
      dust(P.x + 6, P.y + P.h, 4);
    }
    if (!P.jumpHeld && P.springT <= 0 && P.dashT <= 0 && P.vy < -TUNE.jumpVel * TUNE.shortHopMult) P.vy = -TUNE.jumpVel * TUNE.shortHopMult;
    // wall jump — push off the last-touched wall (0.12s grace, works after leaving it).
    // Grace kick is gated to the wall's vertical span: once you rise past the top
    // edge, the wall is BELOW you and a grace kick reads as a random teleport
    // (short tutorial wall). Direct kicks still fire anywhere along the wall.
    if (P.buffer > 0 && !P.onGround && P.wallCoyote > 0 && P.dashT <= 0 &&
        P.y + P.h >= P.wallTopY - 4) {
      P.dashT = 0;
      P.vy = -TUNE.jumpVel * 0.95;
      P.vx = -P.wallDir * TUNE.maxRun * 1.15;
      P.face = -P.wallDir;
      P.buffer = 0; P.coyote = 0; P.wallCoyote = 0; P.onGround = false;
      P.sx = 0.75; P.sy = 1.3;
      beep(500 + Math.random() * 40, 0.08);
      burst(P.x + 6, P.y + 7, 5);
    }
    // double jump (2×JUMP glyph)
    if (P.buffer > 0 && !P.onGround && P.coyote <= 0 && P.airJumps > 0 && P.springT <= 0 && P.dashT <= 0) {
      P.airJumps--; P.vy = -TUNE.jumpVel * 0.92; P.buffer = 0;
      P.sx = 0.75; P.sy = 1.3;
      beep(560 + Math.random() * 40, 0.08);
      burst(P.x + 6, P.y + P.h, 5);
    }
    // dash (DASH glyph, Celeste-lite: fixed burst, gravity-free, refills on ground)
    const dashHeld = keys.ShiftLeft || keys.ShiftRight || keys.KeyK || touch.dash;
    if ((dashQueued || (dashHeld && !prevDashHeld)) && TUNE.dash && P.dashReady && P.dashT <= 0) {
      P.dashT = 0.13; P.dashReady = false;
      const l = keys.ArrowLeft || keys.KeyA || touch.left, r = keys.ArrowRight || keys.KeyD || touch.right;
      P.dashDirX = l && !r ? -1 : r && !l ? 1 : P.face;
      P.face = P.dashDirX;
      P.vy = 0; P.invuln = Math.max(P.invuln, 0.2);
      P.sx = 1.35; P.sy = 0.65;
      beep(700, 0.07); burst(P.x + 6, P.y + 7, 6);
    }
    dashQueued = false; prevDashHeld = !!dashHeld;
    if (P.dashT > 0) {
      P.dashT -= dt;
      P.vx = P.dashDirX * 340; P.vy = 0;
      particles.push({ x: P.x + 6, y: P.y + 7, vx: -P.dashDirX * 30, vy: 0, life: 0.25, t: 0, s: 2 });
      if (P.dashT <= 0) P.vx = P.dashDirX * 170;
    } else {
      const g = P.vy > 0 ? TUNE.gravity * (TUNE.fallMult || 1) : TUNE.gravity;
      const mf = TUNE.fallMult < 1 ? TUNE.maxFall * 0.75 : TUNE.maxFall;
      P.vy = Math.min(mf, P.vy + g * dt);
    }

    moveAndCollide(dt);
    if (P.onGround) { P.dashReady = !!TUNE.dash; P.airJumps = TUNE.airJumps; P.sliding = false; }
    else {
      if (P.touchWall !== 0) { P.wallCoyote = 0.12; P.wallDir = P.touchWall; }
      P.sliding = false;
      const Lk = keys.ArrowLeft || keys.KeyA || touch.left, Rk = keys.ArrowRight || keys.KeyD || touch.right;
      if (P.touchWall !== 0 && P.vy > 0 && P.dashT <= 0 &&
          ((P.touchWall === 1 && Rk) || (P.touchWall === -1 && Lk))) {
        P.sliding = true;
        P.vy = Math.min(P.vy, 60); // controlled slide, not a fall
        runDustT -= dt;
        if (runDustT <= 0) { dust(P.x + (P.touchWall === 1 ? P.w + 1 : -1), P.y + 8, 1); runDustT = 0.09; }
      }
    }
    P.anim += dt * (Math.abs(P.vx) > 10 && P.onGround ? 11 : 3);
    P.sx += (1 - P.sx) * Math.min(1, dt * 10);
    P.sy += (1 - P.sy) * Math.min(1, dt * 10);

    // landing squash + dust
    if (!wasGround && P.onGround) {
      const hard = fallSpeed > 260;
      P.sx = hard ? 1.35 : 1.18; P.sy = hard ? 0.65 : 0.8;
      dust(P.x + 6, P.y + P.h, hard ? 7 : 4);
      if (hard) { shake = Math.max(shake, 2); beep(140, 0.05, 0.04); }
    }
    // run dust
    if (P.onGround && Math.abs(P.vx) > 100) {
      runDustT -= dt;
      if (runDustT <= 0) { dust(P.x + 6 - P.face * 4, P.y + P.h, 1); runDustT = 0.12; }
    }

    // springs — generous trigger, fire even when just running over (no jump-hold needed)
    for (const s of springs) {
      if (s.cool > 0) continue;
      const feetY = P.y + P.h;
      // wide pad zone: player feet inside pad + horizontal overlap
      const overX = P.x + P.w > s.x - 4 && P.x < s.x + s.w + 4;
      const onPad = feetY > s.y - 10 && feetY < s.y + s.h + 8;
      if (overX && onPad && P.vy > -50) {
        P.vy = -(s.power + Math.min(80, Math.abs(P.vx) * 0.3)); // momentum bonus, capped
        P.onGround = false; P.coyote = 0; P.buffer = 0;
        P.springT = 0.3; // exempt from short-hop velocity cut
        P.sx = 0.7; P.sy = 1.4; s.anim = 1; s.cool = 0.15;
        burst(s.x + s.w / 2, s.y, 10); shake = Math.max(shake, 2);
        beep(300, 0.1); setTimeout(() => beep(620, 0.1), 60);
      }
    }

    const zi = zoneOf(P.x);
    if (zi !== zoneIdx) {
      zoneIdx = zi; zoneBannerT = 2.5; beep(520, 0.08);
      if (zi === 2 && maxNotches < 4) {
        maxNotches = 4; // climax Bowl: bigger builds for the Gate sprint
        beep(780, 0.12); setTimeout(() => beep(1040, 0.12), 100);
        burst(P.x + 6, P.y, 10);
      }
    }
    zoneBannerT = Math.max(0, zoneBannerT - dt);

    for (const c of L.checkpoints) {
      if (Math.abs(P.x - c.x) < 14 && Math.abs(P.y - c.y) < 30) {
        if (checkpoint.x !== c.x) { checkpoint = { ...c }; beep(660, 0.09); burst(c.x, c.y, 6); }
        P.shieldChg = TUNE.shieldMax; // beacons mend the AEGIS
        P.dashReady = !!TUNE.dash; P.airJumps = TUNE.airJumps; // ...and refill verbs (GDD §7)
      }
    }
    for (const g of gems) {
      if (!g.taken && Math.abs(P.x + 6 - g.x) < TUNE.magnetR && Math.abs(P.y + 7 - g.y) < TUNE.magnetR + 2) {
        g.taken = true; gemsCollected++;
        beep(880 + gemsCollected * 40, 0.09);
        burst(g.x, g.y, 9);
        // SIGNAL SURGE — every 5th shard drafts a glyph (coins trigger cards)
        const surge = Math.floor(gemsCollected / 5);
        if (surge > lastSurge) {
          lastSurge = surge;
          shake = Math.max(shake, 3);
          beep(660, 0.1); setTimeout(() => beep(990, 0.14), 100);
          openDraft(); return;
        }
      }
    }
    for (const e of enemies) {
      if (e.dead) continue;
      if (overlap(P, e)) {
        if (P.dashT > 0) {
          // DASH kills — sticks for the life; player death re-forms NOISE
          e.dead = true;
          burst(e.x + 7, e.y + 9, 12); hitstop = 0.05; shake = Math.max(shake, 3);
          beep(760, 0.08);
          continue;
        }
        const stomping = P.vy > 60 && (P.y + P.h - e.y) < 10;
        if (stomping) {
          P.vy = TUNE.stompPlus ? -300 : -230; P.sy = 1.3; P.sx = 0.75;
          burst(e.x + 7, e.y + 9, TUNE.stompPlus ? 16 : 10);
          e.dead = true; // stomp kills too — no fake teleport-respawn
          hitstop = 0.06; shake = Math.max(shake, 3);
          if (TUNE.stompPlus) {
            // shockwave — nearby foes die too
            for (const o of enemies) {
              if (o !== e && !o.dead && Math.abs(o.x - e.x) < 46 && Math.abs(o.y - e.y) < 30) {
                o.dead = true; burst(o.x + 7, o.y + 9, 10);
              }
            }
            shake = Math.max(shake, 5);
          }
          beep(520, 0.08);
        } else { lethalHit(); return; }
      }
    }
    enemies = enemies.filter((e) => !e.dead);
    for (const s of L.spikes) {
      if (overlap(P, { x: s.x + 2, y: s.y + 5, w: s.w - 4, h: s.h - 5 })) { lethalHit(); return; }
    }
    if (P.y > L.killY) { respawn(true); return; }
    if (overlap(P, L.goal)) {
      newBest = saveBest(time, deaths, gemsCollected); // persist best run
      state = "win"; // stats drawn in-canvas by drawWin
      beep(523, 0.12); setTimeout(() => beep(784, 0.15), 120);
    }

    const targetX = Math.round(P.x + P.w / 2 - W / 2 + P.face * 40 + P.vx * 0.25);
    const targetY = Math.round(P.y + P.h / 2 - H / 2 - 20);
    cam.x += (Math.max(0, Math.min(L.width - W, targetX)) - cam.x) * Math.min(1, dt * 6);
    cam.y += (Math.max(-40, Math.min(40, targetY)) - cam.y) * Math.min(1, dt * 4);
    shake = Math.max(0, shake - dt * 20);

    for (const p of particles) { p.t += dt; p.x += p.vx * dt; p.y += p.vy * dt; p.vy += 500 * dt; }
    particles = particles.filter((p) => p.t < p.life);
  }

  // ---------- render ----------
  function px(n) { return Math.round(n); }

  function drawBackground() {
    ctx.fillStyle = PAL.bg; ctx.fillRect(0, 0, W, H);
    const tsec = performance.now() / 1000;
    // dithered depth bands — horizon gradient, subtle y-parallax (GDD §8)
    {
      const bands = ["#0e0e0e", "#131313", "#181818", "#1e1e1e"];
      const baseY = 168 - px(cam.y * 0.2);
      for (let b = 0; b < bands.length; b++) {
        const y0 = baseY + b * 16;
        ctx.fillStyle = bands[b];
        ctx.fillRect(0, y0, W, H - y0);
        if (b > 0) { // bayer-dithered band edge: two sparse strips
          ctx.fillStyle = bands[b - 1];
          for (let x = 0; x < W; x += 2) {
            if (bayer(x, y0) < 6) ctx.fillRect(x, y0, 2, 2);
            else if (bayer(x, y0 + 5) < 3) ctx.fillRect(x, y0 + 5, 2, 2);
          }
        }
      }
    }
    // static starfield — drifts slow, twinkles, denser in RUINS
    const starN = zoneIdx === 1 ? 60 : 44;
    for (let i = 0; i < starN; i++) {
      let sx = (i * 173 - cam.x * 0.1) % W; if (sx < 0) sx += W;
      const sy = 6 + ((i * 57) % 150);
      if (((i * 7 + ((tsec * 1.5) | 0)) & 3) === 0) continue; // twinkle off-phase
      ctx.fillStyle = i % 5 === 0 ? PAL.gray : "#2a2a2a";
      ctx.fillRect(Math.round(sx), sy, 1, 1);
    }
    // drifting STATIC specks — the dead broadcast's noise, denser in RUINS
    {
      const n = zoneIdx === 1 ? 26 : 14;
      for (let i = 0; i < n; i++) {
        const sx = (i * 97 + Math.floor(tsec * 2.2) * 29 + ((i * i * 7) | 0)) % W;
        const sy = 10 + ((i * 83 + Math.floor(tsec * 1.3) * 41) % 140);
        if (((i + ((tsec * 6) | 0)) & 3) === 0) continue; // flicker
        ctx.fillStyle = i % 4 === 0 ? PAL.gray : "#2e2e2e";
        ctx.fillRect(sx, sy, 1, 1);
      }
    }
    // signal ghost pulse — every ~7s a dying waveform ripple sweeps the sky
    {
      const tIn = (tsec % 7) / 7;
      if (tIn < 0.35) {
        const gx = tIn / 0.35 * (W + 140) - 70 - px(cam.x * 0.3);
        ctx.globalAlpha = 0.55 * (1 - Math.abs(tIn - 0.175) / 0.175);
        ctx.fillStyle = PAL.gray;
        for (let x = 0; x < 64; x += 3) {
          const yy = Math.sin(x * 0.35 + tsec * 10) * (7 - x * 0.09);
          if (yy > -5 && yy < 5) ctx.fillRect(gx + x, Math.round(66 + yy - cam.y * 0.3), 2, 1);
        }
        ctx.globalAlpha = 1;
      }
    }
    // far antenna towers 0.25x — dead relay masts, slow blinking tips
    for (let k = -1; k < 9; k++) {
      const wx = k * 640 + 180;
      const sx = Math.round(wx - cam.x * 0.25);
      if (sx < -30 || sx > W + 30) continue;
      const th = 120 + ((k * 37 + 200) % 50);
      const ty = H - th - px(cam.y * 0.25); // towers respond to camera height
      ctx.fillStyle = "#141414";
      ctx.fillRect(sx - 1, ty, 3, th); // mast
      ctx.fillStyle = PAL.dark;
      ctx.fillRect(sx - 9, ty + 18, 19, 2); // crossbars
      ctx.fillRect(sx - 7, ty + 34, 15, 2);
      ctx.fillRect(sx - 11, H - 40, 23, 3); // base block
      const lit = (((tsec | 0) >> 1) + k) % 3 !== 0;
      ctx.fillStyle = lit ? PAL.gray : "#222";
      ctx.fillRect(sx, ty - 3, 1, 2); // tip light
    }
    // mid relay ruins 0.5x — L.deco blocks with breathing lights
    ctx.strokeStyle = PAL.dark; ctx.lineWidth = 1;
    for (const d of L.deco) {
      const sx = px(d.x - cam.x * 0.5), sy = px(d.y - cam.y * 0.5);
      if (sx < -100 || sx > W + 100) continue;
      ctx.strokeRect(sx, sy, d.s, d.s);
      ctx.strokeRect(sx + 4, sy + 4, d.s - 8, d.s - 8);
      const on = (((d.x >> 4) + ((tsec * 0.8) | 0)) & 3) === 0;
      ctx.fillStyle = on ? PAL.white : PAL.dark;
      ctx.fillRect(sx + (d.s >> 1), sy - 3, 2, 2);
    }
    // far dunes 0.5x — darker, taller swell behind the crest line
    for (let x = 0; x < W; x += 3) {
      const wx = x + cam.x * 0.5;
      const ry = Math.round(196 + Math.sin(wx * 0.011) * 18 + Math.sin(wx * 0.031 + 2.2) * 8 - cam.y * 0.5);
      ctx.fillStyle = "#101010";
      ctx.fillRect(x, ry, 3, H - ry + 40);
      ctx.fillStyle = "#1c1c1c";
      ctx.fillRect(x, ry, 3, 1);
    }
    // waveform dunes 0.65x — the world's signal made land, pale crest
    for (let x = 0; x < W; x += 2) {
      const wx = x + cam.x * 0.65;
      const ry = Math.round(208 + Math.sin(wx * 0.02) * 14 + Math.sin(wx * 0.053 + 1.7) * 6 - cam.y * 0.65);
      ctx.fillStyle = "#141414";
      ctx.fillRect(x, ry, 2, H - ry + 40);
      ctx.fillStyle = (x >> 1) % 2 === 0 ? PAL.gray : PAL.dark;
      ctx.fillRect(x, ry, 2, 1);
    }
    // GATE beacon beam — visible across Z2, the readable goal; slow breathing
    {
      const bx = Math.round(L.goal.x + 13 - cam.x);
      if (bx > -20 && bx < W + 20) {
        const breathe = 0.10 + Math.sin(tsec * 1.1) * 0.04;
        ctx.globalAlpha = breathe; ctx.fillStyle = PAL.white;
        ctx.fillRect(bx - 8, 0, 16, H);
        ctx.globalAlpha = breathe + 0.06;
        ctx.fillRect(bx - 4, 0, 8, H);
        ctx.globalAlpha = 1;
      }
    }
    // foreground cables 1.15x — fast, dark, bottom third only (never platforms)
    ctx.fillStyle = "#1e1e1e";
    for (let x = 0; x < W; x += 3) {
      const wx = x + cam.x * 1.15;
      const cy = Math.round(252 + Math.sin(wx * 0.03) * 7 - cam.y);
      if (cy > H - 30) ctx.fillRect(x, cy, 3, 1);
    }
    // deepest cable layer 1.4x — darkest, fastest, hugs the very bottom
    ctx.fillStyle = "#151515";
    for (let x = 0; x < W; x += 3) {
      const wx = x + cam.x * 1.4;
      const cy = Math.round(262 + Math.sin(wx * 0.017) * 6 - cam.y * 1.4);
      if (cy > H - 14 && cy < H) ctx.fillRect(x, cy, 3, 1);
    }
    // fog band above ground
    ctx.fillStyle = "rgba(138,138,138,0.08)";
    ctx.fillRect(0, 205 - px(cam.y), W, 30);
  }

  function tilePlatform(sx, sy, w, h, secret, wx, wy, tufts) {
    // base
    ctx.fillStyle = secret ? "#101010" : PAL.dark;
    ctx.fillRect(sx, sy, w, h);
    // 8px tile grid — brick offset every other row, fast rects only
    ctx.fillStyle = secret ? "#222" : "#232323";
    const y0 = sy + 3;
    for (let y = y0; y < sy + h; y += 8) {
      ctx.fillRect(sx, y, w, 1); // horizontal mortar
      const off = (((y - y0) / 8) | 0) % 2 === 0 ? 0 : 4;
      for (let x = sx + off; x < sx + w; x += 8) ctx.fillRect(x, y, 1, Math.min(8, sy + h - y));
    }
    // dither indexed by WORLD coords so the pattern stays put while scrolling
    ctx.fillStyle = secret ? "#1a1a1a" : "#484848";
    for (let y = wy + 4; y < wy + h - 1; y += 4) {
      const dyy = sy + (y - wy);
      for (let x = wx + 2; x < wx + w - 1; x += 4) {
        if (bayer(x, y) < 3) ctx.fillRect(sx + (x - wx), dyy, 2, 1);
      }
    }
    // top highlight: 2px white + 1px gray (readable "stand here" edge)
    ctx.fillStyle = PAL.white;
    ctx.fillRect(sx, sy, w, 2);
    ctx.fillStyle = PAL.gray;
    ctx.fillRect(sx, sy + 2, w, 1);
    // deterministic tufts + cracks from world x (stable, no flicker)
    if (tufts && !secret && h >= 12) {
      for (let i = 0; i < w; i += 7) {
        const hash = ((wx + i) * 13 + 5) % 17;
        if (hash < 3) { // sprout: 1px stem + leaf
          ctx.fillStyle = PAL.white;
          ctx.fillRect(sx + i, sy - 2, 1, 2);
          ctx.fillRect(sx + i + 1, sy - 2, 1, 1);
        } else if (hash > 14) { // crack notch
          ctx.fillStyle = PAL.bg;
          ctx.fillRect(sx + i, sy + 3, 1, 3);
        }
      }
    }
    // bottom shadow for depth
    ctx.fillStyle = PAL.bg;
    ctx.fillRect(sx, sy + h - 2, w, 2);
    // corner rivets
    ctx.fillStyle = PAL.gray;
    ctx.fillRect(sx + 1, sy + 4, 2, 2);
    ctx.fillRect(sx + w - 3, sy + 4, 2, 2);
  }
  function drawPlatforms() {
    for (const s of L.platforms.concat(movers)) {
      const sx = px(s.x - cam.x), sy = px(s.y - cam.y);
      if (sx + s.w < 0 || sx > W || sy + s.h < -20 || sy > H + 20) continue;
      const isSecret = s.type === "secret";
      const isMover = s.range !== undefined;
      tilePlatform(sx, sy, s.w, s.h, isSecret, Math.round(s.x), Math.round(s.y), !isMover);
      if (isMover) { // chevron stripe = "this moves"
        ctx.fillStyle = PAL.white;
        for (let x = sx + 3; x < sx + s.w - 5; x += 10) {
          ctx.fillRect(x, sy + 6, 3, 2);
          ctx.fillRect(x + 1, sy + 5, 1, 1);
        }
      }
      if (isSecret) { // dashed outline = hidden / optional
        ctx.fillStyle = PAL.white;
        for (let x = sx; x < sx + s.w; x += 6) { ctx.fillRect(x, sy - 2, 3, 1); }
      }
      ctx.strokeStyle = PAL.gray; ctx.lineWidth = 1;
      ctx.strokeRect(sx + 0.5, sy + 0.5, s.w - 1, s.h - 1);
    }
    // crumbles: cracked, shake + blink before break
    const t = performance.now() / 90;
    for (const c of crumbles) {
      if (c.broken) continue;
      const jx = c.shakeT > 0 ? Math.round(Math.sin(t * 3) * c.shakeT * 4) : 0;
      const sx = px(c.x - cam.x) + jx, sy = px(c.y - cam.y);
      if (sx + c.w < 0 || sx > W) continue;
      const urgent = c.shakeT > 0.2;
      ctx.fillStyle = urgent && (Math.floor(t) % 2 === 0) ? PAL.gray : PAL.dark;
      ctx.fillRect(sx, sy, c.w, c.h);
      ctx.fillStyle = PAL.white;
      ctx.fillRect(sx, sy, c.w, 1);
      // cracks
      ctx.fillStyle = PAL.bg;
      ctx.fillRect(sx + 8, sy + 3, 2, c.h - 5);
      ctx.fillRect(sx + c.w / 2, sy + 2, 2, c.h - 4);
      ctx.fillRect(sx + c.w - 10, sy + 4, 2, c.h - 6);
      ctx.strokeStyle = PAL.gray;
      ctx.strokeRect(sx + 0.5, sy + 0.5, c.w - 1, c.h - 1);
    }
  }

  function drawSprings() {
    ctx.textAlign = "center";
    for (const s of springs) {
      const sx = px(s.x - cam.x), sy = px(s.y - cam.y);
      const comp = Math.round(s.anim * 6);
      // shadow bed
      ctx.fillStyle = PAL.bg;
      ctx.fillRect(sx - 1, sy + s.h - 1, s.w + 2, 3);
      // body
      ctx.fillStyle = PAL.dark;
      ctx.fillRect(sx, sy + comp, s.w, s.h - comp);
      tilePlatform(sx, sy + comp, s.w, Math.max(4, s.h - comp), false, Math.round(s.x), Math.round(s.y) + comp, false);
      // pad — flashes white on bounce
      ctx.fillStyle = s.anim > 0.3 ? PAL.white : PAL.gray;
      ctx.fillRect(sx - 2, sy + comp, s.w + 4, 4);
      ctx.fillStyle = PAL.bg;
      ctx.fillRect(sx, sy + comp + 1, s.w, 2);
      // coil
      ctx.fillStyle = PAL.white;
      ctx.fillRect(sx + 5, sy + 7 + comp, 3, 5);
      ctx.fillRect(sx + s.w - 8, sy + 7 + comp, 3, 5);
      // readable label — 8px, centered, clamped on screen
      ctx.font = "8px monospace";
      const lx = Math.max(20, Math.min(W - 20, sx + s.w / 2));
      ctx.fillStyle = PAL.bg;
      ctx.fillText("^^^", lx + 1, sy - 3 + comp + 1);
      ctx.fillStyle = PAL.white;
      ctx.fillText("^^^", lx, sy - 3 + comp);
    }
    ctx.textAlign = "left";
  }

  function drawSigns() {
    ctx.textAlign = "center";
    for (const sg of L.signs) {
      const sx = px(sg.x - cam.x), sy = px(sg.y - cam.y);
      if (sx < -140 || sx > W + 140) continue;
      // post + lamp head
      ctx.fillStyle = PAL.gray;
      ctx.fillRect(sx, sy, 2, 22);
      ctx.fillStyle = PAL.white;
      ctx.fillRect(sx - 3, sy - 4, 8, 6);
      ctx.fillStyle = PAL.bg;
      ctx.fillRect(sx - 1, sy - 2, 4, 2);
      const near = Math.abs(P.x - sg.x) < 110;
      ctx.font = "8px monospace";
      if (near) {
        // big readable bubble: white fill, black border, black text, clamped
        const tw = ctx.measureText(sg.text).width + 12;
        let bx = Math.max(tw / 2 + 2, Math.min(W - tw / 2 - 2, sx));
        const by = Math.max(16, sy - 26);
        ctx.fillStyle = PAL.bg;
        ctx.fillRect(Math.round(bx - tw / 2) - 1, by - 9, Math.ceil(tw) + 2, 13);
        ctx.fillStyle = PAL.white;
        ctx.fillRect(Math.round(bx - tw / 2), by - 8, Math.ceil(tw), 11);
        ctx.fillStyle = PAL.bg;
        ctx.fillText(sg.text, bx, by);
        // connector tick
        ctx.fillRect(sx, by + 3, 1, 5);
      } else {
        // far hint — small white text with black shadow so it reads at distance
        ctx.fillStyle = PAL.bg;
        ctx.fillText("?", sx + 1, sy - 7 + 1);
        ctx.fillStyle = PAL.gray;
        ctx.fillText("?", sx, sy - 7);
      }
    }
    ctx.textAlign = "left";
  }

  function drawSpikes() {
    const blink = Math.floor(performance.now() / 160) % 2 === 0;
    for (const s of L.spikes) {
      const sx = px(s.x - cam.x), sy = px(s.y - cam.y);
      // black base = danger bed (Downwell-style readability)
      ctx.fillStyle = PAL.bg;
      ctx.fillRect(sx - 1, sy + s.h - 2, s.w + 2, 3);
      const n = Math.max(1, Math.round(s.w / 12));
      const tw = s.w / n;
      for (let i = 0; i < n; i++) {
        ctx.fillStyle = blink ? PAL.white : PAL.gray; // blink = danger language, stays monochrome
        ctx.beginPath();
        ctx.moveTo(px(sx + i * tw), sy + s.h);
        ctx.lineTo(px(sx + i * tw + tw / 2), sy);
        ctx.lineTo(px(sx + i * tw + tw), sy + s.h);
        ctx.fill();
      }
    }
  }

  function drawGems() {
    const t = performance.now() / 300;
    for (const g of gems) {
      if (g.taken) continue;
      const bobY = Math.sin(g.bob) * 2;
      const sx = px(g.x - cam.x), sy = px(g.y + bobY - cam.y);
      if (sx < -20 || sx > W + 20) continue;
      const squish = Math.abs(Math.sin(t + g.id)) * 3;
      ctx.fillStyle = PAL.white;
      ctx.beginPath();
      ctx.moveTo(sx, sy - 5); ctx.lineTo(sx + 5 - squish, sy);
      ctx.lineTo(sx, sy + 5); ctx.lineTo(sx - 5 + squish, sy);
      ctx.fill();
      ctx.fillStyle = PAL.bg;
      ctx.fillRect(sx - 1, sy - 1, 2, 2);
      // sparkle cross
      ctx.fillStyle = PAL.white;
      const sp = Math.floor(t * 2 + g.id) % 4 === 0;
      if (sp) { ctx.fillRect(sx + 6, sy - 4, 1, 1); ctx.fillRect(sx - 7, sy + 3, 1, 1); }
    }
  }

  function drawEnemies() {
    const f = Math.floor(performance.now() / 150) % 2;
    for (const e of enemies) {
      const sx = px(e.x - cam.x), sy = px(e.y - cam.y);
      if (sx < -30 || sx > W + 30) continue;
      const turning = (e.dir === 1 && e.maxX - e.x < 20) || (e.dir === -1 && e.x - e.minX < 20);
      const blink = turning && Math.floor(performance.now() / 100) % 2 === 0;
      const squash = turning ? 1 : 0; // anticipation squash before turning
      // black halo so it reads on white tops
      ctx.fillStyle = PAL.bg;
      ctx.fillRect(sx - 1, sy - 1 + squash, e.w + 2, e.h + 2 - squash);
      ctx.fillStyle = blink ? PAL.gray : PAL.white;
      ctx.fillRect(sx, sy + squash, e.w, e.h - squash);
      // angry slanted eyes (direction matters)
      ctx.fillStyle = PAL.bg;
      const ex = e.dir > 0 ? sx + 8 : sx + 2;
      ctx.fillRect(ex, sy + 4 + squash, 2, 2);
      ctx.fillRect(ex + (e.dir > 0 ? -1 : 1), sy + 3 + squash, 3, 1); // brow slant
      ctx.fillRect(ex, sy + 10, 2, 3);
      // jaw teeth
      ctx.fillRect(sx + 3, sy + e.h - 3, 2, 1);
      ctx.fillRect(sx + e.w - 5, sy + e.h - 3, 2, 1);
      // feet — 2px alternate
      ctx.fillStyle = PAL.gray;
      ctx.fillRect(sx, sy + e.h, f ? 5 : 3, 2);
      ctx.fillRect(sx + e.w - (f ? 3 : 5), sy + e.h, f ? 3 : 5, 2);
    }
  }

  function drawPlayer() {
    const w = Math.max(4, Math.round(P.w * P.sx));
    const h = Math.max(6, Math.round(P.h * P.sy));
    const sx = px(P.x + P.w / 2 - w / 2 - cam.x);
    const sy = px(P.y + P.h - h - cam.y);
    const face = P.sliding && P.touchWall !== 0 ? P.touchWall : P.face; // look at the wall
    ctx.fillStyle = "rgba(255,255,255,0.15)";
    ctx.fillRect(px(P.x - cam.x) + 1, px(P.y + P.h - cam.y) + 1, P.w - 2, 2);
    // spawn/shield invulnerability blink — ghost only
    if (P.invuln > 0 && P.dashT <= 0 && Math.floor(performance.now() / 70) % 2 === 0) {
      ctx.fillStyle = "rgba(242,242,242,0.35)";
      ctx.fillRect(sx, sy, w, h);
      return;
    }
    // black halo — separates the white body from white platform tops
    ctx.fillStyle = PAL.bg;
    ctx.fillRect(sx - 1, sy - 1, w + 2, h + 2);
    // body
    ctx.fillStyle = PAL.white;
    ctx.fillRect(sx, sy, w, h);
    // hood peak (back of head)
    ctx.fillRect(face > 0 ? sx - 1 : sx + w, sy + 1, 1, 3);
    // visor + shine pixel
    ctx.fillStyle = PAL.bg;
    const vx = face > 0 ? sx + w - 6 : sx + 2;
    ctx.fillRect(vx, sy + 3, 4, 3);
    ctx.fillStyle = PAL.gray;
    ctx.fillRect(vx + (face > 0 ? 0 : 3), sy + 3, 1, 1);
    // scarf — 2 segments, flutter with run cycle
    ctx.fillStyle = PAL.gray;
    const fl = Math.floor(P.anim * 2) % 2;
    const bx = face > 0 ? sx - 3 : sx + w + 1;
    ctx.fillRect(bx, sy + 4 + fl, 3, 2);
    ctx.fillRect(bx + (face > 0 ? -2 : 2), sy + 5 - fl, 2, 1);
    // legs
    ctx.fillStyle = PAL.bg;
    if (P.sliding) { // wall press: one foot braced against the wall
      ctx.fillRect(sx + 2, sy + h - 2, 3, 2);
      ctx.fillRect(face > 0 ? sx + w - 1 : sx - 2, sy + h - 5, 3, 2);
    } else if (!P.onGround) { ctx.fillRect(sx + 2, sy + h - 2, 3, 2); ctx.fillRect(sx + w - 5, sy + h - 3, 3, 3); }
    else if (Math.abs(P.vx) > 10) {
      const fr = Math.floor(P.anim) % 2;
      ctx.fillRect(sx + 2, sy + h - 2, 3, 2 + (fr ? 0 : 1));
      ctx.fillRect(sx + w - 5, sy + h - 3 - (fr ? 1 : 0), 3, 2 + (fr ? 1 : 0));
    } else { ctx.fillRect(sx + 2, sy + h - 2, 3, 2); ctx.fillRect(sx + w - 5, sy + h - 2, 3, 2); }
    // AEGIS ring — visible while a shield charge is held
    if (P.shieldChg > 0) {
      const pulse = Math.floor(performance.now() / 300) % 2 === 0;
      ctx.fillStyle = pulse ? PAL.white : PAL.gray;
      ctx.fillRect(sx - 2, sy - 2, w + 4, 1);
      ctx.fillRect(sx - 2, sy + h + 1, w + 4, 1);
      ctx.fillRect(sx - 2, sy, 1, h);
      ctx.fillRect(sx + w + 1, sy, 1, h);
    }
    // DASH pip — white = ready, dark = spent
    if (TUNE.dash) {
      ctx.fillStyle = P.dashReady ? PAL.white : PAL.dark;
      ctx.fillRect(sx + ((w / 2) | 0) - 1, sy - 5, 3, 3);
      ctx.fillStyle = PAL.bg;
      ctx.fillRect(sx + ((w / 2) | 0), sy - 4, 1, 1);
    }
  }

  function drawCheckpointsGoal() {
    const t = performance.now() / 400;
    for (const c of L.checkpoints) {
      const sx = px(c.x - cam.x), sy = px(c.y - cam.y); // c.y = ground base
      const active = checkpoint.x === c.x;
      ctx.fillStyle = active ? PAL.white : PAL.dark;
      ctx.fillRect(sx, sy - 26, 2, 26); // pole planted on the ground
      const wave = active ? Math.sin(t + c.x) * 1 : 0;
      ctx.fillStyle = active ? PAL.white : PAL.gray;
      ctx.fillRect(sx + 2, sy - 26 + Math.round(wave), active ? 10 : 7, 6); // flag at pole top
    }
    const g = L.goal;
    const sx = px(g.x - cam.x), sy = px(g.y - cam.y);
    const pulse = Math.floor(performance.now() / 500) % 2 === 0;
    const scroll = Math.floor(performance.now() / 200) % 8;
    // twin pillars + lintel (torii gate — the run's finish reads from afar)
    ctx.fillStyle = PAL.white;
    ctx.fillRect(sx - 4, sy - 4, 4, g.h + 8);       // left pillar
    ctx.fillRect(sx + g.w, sy - 4, 4, g.h + 8);     // right pillar
    ctx.fillRect(sx - 6, sy - 8, g.w + 12, 5);      // lintel
    ctx.fillStyle = pulse ? PAL.white : PAL.gray;
    ctx.fillRect(sx - 4, sy - 10, g.w + 8, 2);      // crown glint
    // inner void — scrolling checker (alive, monochrome)
    ctx.fillStyle = PAL.bg;
    ctx.fillRect(sx, sy, g.w, g.h);
    ctx.fillStyle = PAL.dark;
    for (let y = 0; y < g.h; y += 8)
      for (let x = 0; x < g.w; x += 8)
        if (((x + y + scroll) >> 3) % 2 === 0) ctx.fillRect(sx + x + 1, sy + y + 1, 6, 6);
    // base steps
    ctx.fillStyle = PAL.gray;
    ctx.fillRect(sx - 6, sy + g.h + 4, g.w + 12, 2);
    ctx.fillRect(sx - 4, sy + g.h + 6, g.w + 8, 1);
    ctx.fillStyle = PAL.white;
    ctx.font = "8px monospace";
    ctx.textAlign = "center";
    ctx.fillStyle = PAL.bg;
    ctx.fillText("GATE", sx + g.w / 2 + 1, sy - 5 + 1);
    ctx.fillStyle = PAL.white;
    ctx.fillText("GATE", sx + g.w / 2, sy - 5);
    ctx.textAlign = "left";
  }

  function drawParticles() {
    for (const p of particles) {
      ctx.fillStyle = p.t < p.life / 2 ? PAL.white : PAL.gray;
      ctx.fillRect(px(p.x - cam.x), px(p.y - cam.y), p.s, p.s);
    }
  }

  function drawBanner() {
    if (zoneBannerT <= 0) return;
    const z = L.zones[zoneIdx];
    const a = Math.min(1, zoneBannerT);
    ctx.globalAlpha = a;
    ctx.textAlign = "center";
    // black plate behind text so it reads over any background
    ctx.fillStyle = PAL.bg;
    ctx.fillRect(W / 2 - 120, 40, 240, 42);
    ctx.strokeStyle = PAL.gray;
    ctx.strokeRect(W / 2 - 120 + 0.5, 40 + 0.5, 239, 41);
    ctx.font = "bold 16px monospace";
    ctx.fillStyle = PAL.bg;
    ctx.fillText(z.name, W / 2 + 1, 61);
    ctx.fillStyle = PAL.white;
    ctx.fillText(z.name, W / 2, 60);
    ctx.font = "8px monospace";
    ctx.fillStyle = PAL.gray;
    ctx.fillText(z.sub, W / 2, 74);
    ctx.textAlign = "left";
    ctx.globalAlpha = 1;
  }

  const SHORT = { dash: "DSH", jump2: "JMP", feather: "FTH", swift: "SWF", spring: "SPR", magnet: "MAG", aegis: "AEG", stomp: "STM", heavy: "HVY", glass: "GLS" };
  function drawHUD() {
    // top bar
    ctx.fillStyle = PAL.bg; ctx.fillRect(0, 0, W, 18);
    ctx.fillStyle = PAL.dark; ctx.fillRect(0, 18, W, 1);
    ctx.font = "8px monospace"; ctx.textAlign = "left";
    ctx.fillStyle = PAL.white;
    ctx.fillText(`◆ ${gemsCollected}/${L.gems.length}`, 4, 12);
    for (let i = 0; i < 5; i++) { // surge progress pips
      ctx.fillStyle = i < gemsCollected % 5 ? PAL.white : PAL.dark;
      ctx.fillRect(62 + i * 6, 6, 4, 6);
    }
    ctx.textAlign = "center";
    ctx.fillStyle = PAL.gray;
    ctx.fillText(`${L.zones[zoneIdx].name}  ${fmtTime(time)}`, W / 2, 12);
    ctx.textAlign = "right";
    ctx.fillStyle = PAL.white;
    ctx.fillText(`✕${deaths} ${fps}`, W - 4, 12);
    ctx.textAlign = "left";
    // bottom-left deck chips + notches (shadowed text, no plate)
    const u = usedNotches();
    const norm = deck.filter((id) => !CARDS[id].cursed);
    const curs = deck.filter((id) => CARDS[id].cursed);
    const label = norm.length ? norm.map((id) => SHORT[id]).join(" ") : "NO GLYPHS";
    const np = "◆".repeat(u) + "◇".repeat(Math.max(0, maxNotches - u));
    ctx.fillStyle = PAL.bg;
    ctx.fillText(label, 5, H - 3);
    ctx.fillText(np, 5, H - 13);
    ctx.fillStyle = PAL.gray;
    ctx.fillText(label, 4, H - 4);
    ctx.fillStyle = PAL.white;
    ctx.fillText(np, 4, H - 14);
    if (curs.length) { // cursed row — its own 2-notch budget
      const cu = usedCursed();
      const cl = curs.map((id) => SHORT[id]).join(" ");
      const cp = "◇".repeat(cu) + "◆".repeat(Math.max(0, cursedMax - cu));
      ctx.fillStyle = PAL.bg; ctx.fillText(cl, 5, H - 23); ctx.fillText(cp, 5, H - 33);
      ctx.fillStyle = PAL.gray; ctx.fillText(cl, 4, H - 24);
      ctx.fillStyle = PAL.white; ctx.fillText(cp, 4, H - 34);
    }
  }
  function drawMenu() {
    ctx.fillStyle = "rgba(0,0,0,0.55)"; ctx.fillRect(0, 0, W, H);
    ctx.textAlign = "center";
    ctx.font = "bold 30px monospace";
    ctx.fillStyle = PAL.bg;
    ctx.fillText("WHITE SIGNAL", W / 2 + 2, 82);
    ctx.fillStyle = PAL.white;
    ctx.fillText("WHITE SIGNAL", W / 2, 80);
    ctx.font = "8px monospace"; ctx.fillStyle = PAL.gray;
    ctx.fillText("A MONO RUNNER · CARRY THE SPARK TO THE GATE", W / 2, 98);
    const mb = loadBest();
    if (mb) ctx.fillText(`BEST ${fmtTime(mb.t)} · ✕${mb.d}`, W / 2, 110);
    ctx.fillStyle = PAL.white;
    ctx.fillText("A/D MOVE · SPACE JUMP (HOLD = HIGHER)", W / 2, 124);
    ctx.fillText("HOLD INTO WALL + JUMP = WALL KICK", W / 2, 138);
    ctx.fillText("◆ ×5 = SIGNAL SURGE · DRAFT A GLYPH", W / 2, 152);
    ctx.fillStyle = PAL.gray;
    ctx.fillText("SHIFT DASH · R RESPAWN · P PAUSE", W / 2, 166);
    if (Math.floor(performance.now() / 500) % 2 === 0) {
      ctx.fillStyle = PAL.white;
      ctx.fillText("CLICK OR SPACE TO IGNITE", W / 2, 196);
    }
    ctx.textAlign = "left";
  }
  function drawPause() {
    ctx.fillStyle = "rgba(0,0,0,0.66)"; ctx.fillRect(0, 0, W, H);
    ctx.textAlign = "center";
    ctx.fillStyle = PAL.white; ctx.font = "bold 20px monospace";
    ctx.fillText("PAUSED", W / 2, 120);
    ctx.font = "8px monospace"; ctx.fillStyle = PAL.gray;
    ctx.fillText("P / CLICK TO RESUME · R RESPAWN", W / 2, 140);
    ctx.textAlign = "left";
  }
  function drawDraft() {
    ctx.fillStyle = "rgba(0,0,0,0.72)"; ctx.fillRect(0, 0, W, H);
    ctx.textAlign = "center";
    ctx.fillStyle = PAL.white; ctx.font = "bold 14px monospace";
    ctx.fillText("SIGNAL SURGE", W / 2, 40);
    ctx.font = "8px monospace"; ctx.fillStyle = PAL.gray;
    ctx.fillText(`CHOOSE A GLYPH · 1/2/3 · S SKIP · NOTCHES ${usedNotches()}/${maxNotches}`, W / 2, 54);
    draftRects = [];
    const cw = 132, ch = 108, cy = 84;
    draftOpts.forEach((id, i) => {
      const c = CARDS[id];
      const cx = 30 + i * (cw + 12);
      const afford = c.cursed ? usedCursed() + c.cost <= cursedMax : usedNotches() + c.cost <= maxNotches;
      draftRects.push({ x: cx, y: cy, w: cw, h: ch, i });
      ctx.fillStyle = afford ? PAL.white : PAL.gray;
      ctx.fillRect(cx, cy, cw, ch);
      ctx.fillStyle = PAL.bg;
      ctx.fillRect(cx + 2, cy + 2, cw - 4, ch - 4);
      ctx.fillStyle = afford ? PAL.white : PAL.gray;
      ctx.font = "bold 16px monospace";
      ctx.fillText(c.g, cx + cw / 2, cy + 26);
      ctx.font = "8px monospace";
      ctx.fillText(c.n, cx + cw / 2, cy + 40);
      ctx.fillStyle = afford ? PAL.gray : PAL.dark;
      ctx.fillText("◆".repeat(c.cost), cx + cw / 2, cy + 52);
      ctx.fillStyle = afford ? PAL.white : PAL.gray;
      wrapDesc(c.d, 22).forEach((ln, k) => ctx.fillText(ln, cx + cw / 2, cy + 66 + k * 10));
      ctx.fillStyle = PAL.dark;
      ctx.fillText(afford ? (c.cursed ? `CURSED [${i + 1}]` : `[${i + 1}]`) : "LOCKED", cx + cw / 2, cy + ch - 6);
    });
    skipRect = { x: W / 2 - 70, y: 204, w: 140, h: 16 };
    ctx.strokeStyle = PAL.gray; ctx.lineWidth = 1;
    ctx.strokeRect(skipRect.x + 0.5, skipRect.y + 0.5, skipRect.w - 1, skipRect.h - 1);
    ctx.fillStyle = PAL.gray;
    ctx.fillText("SKIP [S]", W / 2, skipRect.y + 12);
    ctx.textAlign = "left";
  }
  function drawWin() {
    ctx.fillStyle = "rgba(0,0,0,0.66)"; ctx.fillRect(0, 0, W, H);
    ctx.textAlign = "center";
    ctx.fillStyle = PAL.white; ctx.font = "bold 20px monospace";
    ctx.fillText("SIGNAL RESTORED", W / 2, 100);
    ctx.font = "8px monospace"; ctx.fillStyle = PAL.gray;
    ctx.fillText(`◆ ${gemsCollected}/${L.gems.length} · ${fmtTime(time)} · ✕${deaths}`, W / 2, 122);
    ctx.fillText(`GLYPHS: ${deck.length ? deck.map((id) => SHORT[id]).join(" ") : "NONE"}`, W / 2, 136);
    const b = loadBest();
    if (newBest) { ctx.fillStyle = PAL.white; ctx.fillText(`NEW BEST · ${fmtTime(b ? b.t : time)}`, W / 2, 152); }
    else if (b) ctx.fillText(`BEST ${fmtTime(b.t)}`, W / 2, 152);
    if (Math.floor(performance.now() / 500) % 2 === 0) {
      ctx.fillStyle = PAL.white;
      ctx.fillText("CLICK OR SPACE — NEW RUN", W / 2, 164);
    }
    ctx.textAlign = "left";
  }
  function drawScanVignette() {
    ctx.fillStyle = "rgba(0,0,0,0.20)";
    for (let y = 0; y < H; y += 3) ctx.fillRect(0, y, W, 1);
    // vignette corners
    const gr = ctx.createRadialGradient(W / 2, H / 2, H / 3, W / 2, H / 2, H);
    gr.addColorStop(0, "rgba(0,0,0,0)");
    gr.addColorStop(1, "rgba(0,0,0,0.45)");
    ctx.fillStyle = gr;
    ctx.fillRect(0, 0, W, H);
  }

  function render() {
    ctx.save();
    if (shake > 0) ctx.translate(Math.round((Math.random() - 0.5) * shake), Math.round((Math.random() - 0.5) * shake));
    drawBackground();
    drawCheckpointsGoal();
    drawPlatforms();
    drawSprings();
    drawSigns();
    drawSpikes();
    drawGems();
    drawEnemies();
    drawPlayer();
    drawParticles();
    ctx.restore();
    drawScanVignette();
    if (state !== "draft" && state !== "win") drawBanner(); // banner collides with draft/win text
    if (state !== "menu") drawHUD();
    if (state === "menu") drawMenu();
    else if (state === "pause") drawPause();
    else if (state === "draft") drawDraft();
    else if (state === "win") drawWin();
  }

  function fmtTime(t) {
    const m = Math.floor(t / 60), s = t % 60;
    return `${String(m).padStart(2, "0")}:${s.toFixed(1).padStart(4, "0")}`;
  }
  // best-run persistence (roadmap v4): lower time wins
  const BEST_KEY = "ws_best_v1";
  function loadBest() { try { return JSON.parse(localStorage.getItem(BEST_KEY)) || null; } catch (_) { return null; } }
  function saveBest(t, d, g) {
    const b = loadBest();
    if (b && !(t < b.t)) return false;
    try { localStorage.setItem(BEST_KEY, JSON.stringify({ t, d, g })); } catch (_) {}
    return true;
  }
  // HUD is drawn in-canvas by drawHUD (no DOM).

  let last = performance.now();
  function loop(now) {
    requestAnimationFrame(loop);
    const dt = Math.min(0.033, (now - last) / 1000);
    last = now;
    frames++;
    if (now - lastFpsT > 500) { fps = Math.round(frames * 1000 / (now - lastFpsT)); frames = 0; lastFpsT = now; }
    if (state === "play") update(dt);
    render();
  }

  // debug/testing hook (headless harness drives drafts through this)
  window.__WS = { get state() { return state; }, get draftOpts() { return draftOpts; }, get deck() { return deck; }, get enemies() { return enemies; }, get crumbles() { return crumbles; }, get springs() { return springs; }, get movers() { return movers; }, get TUNE() { return TUNE; }, get best() { return loadBest(); }, openDraft, pickCard, skipDraft, tryStart, P, L };

  resetLevel();
  state = "menu";
  requestAnimationFrame(loop);
})();
