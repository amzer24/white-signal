#!/usr/bin/env python3
"""Catchiness and fit checks for WHITE SIGNAL's music (tools/audio/sfx8.py).

Reads the lead line (pulse 1) of every music loop straight from the generator, one pass,
and measures the things that make a game tune stick (docs/research/music-2026-09-26.md):

  hook     how often the opening bar and a half comes back on a bar line in a pass, with
           the same rhythm and the same ups and downs (in any key or mode, the way listeners
           hear a tune moved to a new chord as the same tune)
  reuse    share of bars whose rhythm and shape appear somewhere else in the pass
  rhythms  distinct bar rhythms per 8 bars (fewer means a stronger rhythmic signature)
  sync     share of notes that start off the beat and hold across it (syncopation)
  steps    share of moves that are a step (2 semitones or less)
  runs     share of notes inside broken-chord runs (4+ leaps of 3 to 5 semitones in one
           direction): busy, and hard to sing
  range    lowest to highest lead note, in semitones, and the top note
  air      share of the pass spent in rests or on notes held a beat or longer
  density  notes per bar

    python tools/audio/music_check.py              every music loop
    python tools/audio/music_check.py m_1_1 ...    just these
    python tools/audio/music_check.py --json out   also write the numbers as JSON
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import sfx8  # noqa: E402

# The limits a lead should sit inside (see the research note, R1 to R8).
LIMITS = {
    "hook": (3, None),        # the hook comes back at least 3 times a pass
    "reuse": (0.5, None),     # at least half the bars reuse material
    "rhythms": (None, 4.0),   # at most 4 distinct bar rhythms per 8 bars
    "sync": (0.08, None),     # some syncopation
    "steps": (0.5, None),     # mostly steps
    "runs": (None, 0.25),     # few broken-chord runs
    "range": (None, 19),      # an octave and a fifth at most
    "top": (None, 88),        # nothing above E6 (MIDI 88): thin pulses get shrill up there
    "air": (0.3, None),       # room to breathe
    "clash": (None, 0.05),    # almost no strong notes a semitone or tritone off the bass
}
# the story intro's cues sit under cards and aren't tunes, so they're left out
MUSIC = [n for n, sp in sfx8.SOUNDS.items()
         if sp["category"] == "music" and not n.startswith("intro_")]
# tracks whose tune is shared between both pulses (call and answer)
LEAD = {"m_2_3": ("p1", "p2")}
# tracks that play the hook at half speed, so their syncopation is counted in half bars
HALF_SPEED = {"title_theme"}


def _record():
    """Wrap Sound.seq so every part played is logged as (voice, start s, bpm, notes)."""
    log: list[tuple[str, float, float, list]] = []
    real = sfx8.Sound.seq

    def seq(self, voice, t0, bpm, notes, **kw):
        name = next(v for v in ("p1", "p2", "tri", "noi") if voice is getattr(self, v))
        log.append((name, t0, bpm, list(notes)))
        return real(self, voice, t0, bpm, notes, **kw)

    sfx8.Sound.seq = seq
    return log, real


def lead(name: str, voices: tuple[str, ...] | None = None
         ) -> tuple[float, list[tuple[float, int | None, float]]]:
    """(bpm, notes) of one pass of a loop's lead: (start in beats, midi or None, beats)."""
    spec = sfx8.SOUNDS[name]
    voices = voices or LEAD.get(name, ("p1",))
    log, real = _record()
    try:
        s = sfx8.Sound(2 * spec["dur"] + 1)
        spec["fn"](s)
    finally:
        sfx8.Sound.seq = real
    start = spec["intro"][1] if spec["intro"] else 0.0
    log = [x for x in log if x[0] in voices]
    bpm = log[0][2]
    beat = 60 / bpm
    out = []
    pass_beats = spec["dur"] / beat
    for _, t0, _, notes in log:
        t = round((t0 - start) / beat * 48) / 48      # count in beats, so bars line up exactly
        for n, b in notes:
            if -1e-6 <= t < pass_beats - 1e-6:
                out.append((t, None if n is None else sfx8._midi(n), b))
            t = round((t + b) * 48) / 48
    out.sort(key=lambda x: x[0])
    # a shared tune: one voice's rests are the other voice's notes
    if len(voices) > 1:
        out = [x for x in out if x[1] is not None]
    return bpm, out


def _bars(notes, total_bars):
    bars = [[] for _ in range(total_bars)]
    for t, m, b in notes:
        k = int(t // 4 + 1e-9)
        if 0 <= k < total_bars:
            bars[k].append((round(t - 4 * k, 3), m, b))
    return bars


def _shape(seq, contour=False):
    """Rhythm plus steps between sounding notes: a key-free fingerprint of a stretch of tune.
    contour=True keeps only whether each step goes up, down or stays."""
    rhythm = tuple((t, b, m is None) for t, m, b in seq)
    ms = [m for _, m, _ in seq if m is not None]
    steps = tuple(b - a for a, b in zip(ms, ms[1:]))
    return rhythm, tuple((d > 0) - (d < 0) for d in steps) if contour else steps


def measure(name: str) -> dict:
    bpm, notes = lead(name)
    dur = sfx8.SOUNDS[name]["dur"]
    total_bars = round(dur * bpm / 60 / 4)
    bars = _bars(notes, total_bars)
    sounding = [(t, m, b) for t, m, b in notes if m is not None]
    ms = [m for _, m, _ in sounding]
    moves = [b - a for a, b in zip(ms, ms[1:])]

    # hook: the opening bar and a half, found again on any bar line, in any key. The loop's
    # own opening counts. A second try lets the first note differ (a new pickup).
    def span(k):
        return [(round(t - 4 * k, 3), m, b) for t, m, b in notes if 4 * k - 1e-6 <= t < 4 * k + 6 - 1e-6]

    hook_shape = _shape(span(0), True)
    hook_core = (hook_shape[0][1:], hook_shape[1][1:])
    hits = 0
    for k in range(total_bars):
        sh = _shape(span(k), True)
        if sh == hook_shape or (sh[0][1:], sh[1][1:]) == hook_core:
            hits += 1
    first = min((t for t, _, _ in sounding), default=0.0)

    shapes = [_shape(b) for b in bars]
    reuse = sum(1 for i, sh in enumerate(shapes) if bars[i] and shapes.count(sh) > 1) / total_bars
    rhythms = len({s[0] for s in shapes}) / total_bars * 8

    # syncopation: starts off the beat and is still sounding when the next beat arrives
    u = 2 if name in HALF_SPEED else 1
    sync = sum(1 for t, _, b in sounding if abs(t / u - round(t / u)) > 1e-6
               and (math.floor(t / u + 1e-9) + 1) * u < t + b - 1e-6) / max(len(sounding), 1)
    steps = sum(1 for d in moves if abs(d) <= 2) / max(len(moves), 1)

    in_run = set()
    i = 0
    while i < len(moves):
        j = i
        while j < len(moves) and 3 <= abs(moves[j]) <= 5 and (moves[j] > 0) == (moves[i] > 0):
            j += 1
        if j - i >= 3:                     # 3+ such leaps = 4+ notes
            in_run.update(range(i, j + 1))
        i = max(j, i + 1)
    runs = len(in_run) / max(len(ms), 1)

    # clashes: lead notes of half a beat or more on a beat that sit a semitone or a tritone
    # from the bass note sounding under them
    _, bass = lead(name, ("tri",))
    def bass_at(t):
        for bt, bm, bb in reversed(bass):
            if bt <= t + 1e-6:
                return bm if t < bt + bb - 1e-6 else None
        return None
    strong = [(t, m) for t, m, b in sounding if b >= 0.5 and abs(t - round(t)) < 1e-6]
    clash = sum(1 for t, m in strong
                if bass_at(t) is not None and (m - bass_at(t)) % 12 in (1, 6)) / max(len(strong), 1)

    total_beats = total_bars * 4
    air = (sum(b for _, m, b in notes if m is None) + sum(b for _, m, b in sounding if b >= 1)
           + max(0.0, total_beats - sum(b for _, _, b in notes))) / total_beats

    return {
        "name": name, "bpm": round(bpm, 1), "bars": total_bars,
        "hook": hits, "first_note_beat": round(first, 2),
        "reuse": round(reuse, 2), "rhythms": round(rhythms, 1), "sync": round(sync, 2),
        "steps": round(steps, 2), "runs": round(runs, 2),
        "range": (max(ms) - min(ms)) if ms else 0, "low": sfx8._note(min(ms)) if ms else "",
        "top": max(ms) if ms else 0, "top_note": sfx8._note(max(ms)) if ms else "",
        "air": round(air, 2), "density": round(len(sounding) / total_bars, 1),
        "clash": round(clash, 2),
    }


def misses(r: dict) -> list[str]:
    out = []
    for k, (lo, hi) in LIMITS.items():
        v = r[k]
        if lo is not None and v < lo:
            out.append(f"{k} {v} < {lo}")
        if hi is not None and v > hi:
            out.append(f"{k} {v} > {hi}")
    return out


def main(argv: list[str]) -> int:
    out_json = None
    if "--json" in argv:
        i = argv.index("--json")
        out_json = argv[i + 1]
        argv = argv[:i] + argv[i + 2:]
    names = argv[1:] or MUSIC
    rows = [measure(n) for n in names]
    cols = ["hook", "reuse", "rhythms", "sync", "steps", "runs", "range", "top_note", "air",
            "density", "clash"]
    print(f"{'track':14} " + " ".join(f"{c:>8}" for c in cols) + "  misses")
    passed = 0
    for r in rows:
        m = misses(r)
        passed += not m
        print(f"{r['name']:14} " + " ".join(f"{str(r[c]):>8}" for c in cols)
              + f"  {len(m)}: " + ", ".join(m))
    print(f"{passed} of {len(rows)} tracks inside every limit")
    if out_json:
        Path(out_json).write_text(json.dumps(rows, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
