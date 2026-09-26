#!/usr/bin/env python3
"""WHITE SIGNAL 8-bit sound effects generator.

Every sound is written for the four NES voices only:
  p1, p2  pulse waves, duty 12.5 / 25 / 50 / 75 %, 16 volume steps
  tri     the 32-step triangle (no volume control, only on or off)
  noi     the 15-bit noise register, long mode or short (metallic) mode,
          16 pitch settings (0 = highest hiss, 15 = lowest rumble)

Each voice plays one note at a time. A later note on the same voice cuts the
earlier one, exactly like the hardware. Echoes are made the way NES drivers
made them: a delayed, quieter copy placed on a free voice.

Control values are written 240 times a second (the NES envelope clock), pitch
is snapped to the real NES period registers, and the mix is rendered at 4x the
sample rate, filtered like a Famicom (37 Hz high-pass, 14 kHz low-pass) and
decimated to 44.1 kHz, 16-bit mono.

Usage:
  python tools/audio/sfx8.py            rebuild every sound
  python tools/audio/sfx8.py jump dash  rebuild only these sounds
                                        (the manifest keeps the others)

Needs Python 3 and numpy. Output: assets/audio/sfx8/*.wav plus manifest.json.
"""
from __future__ import annotations

import json
import math
import sys
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "audio" / "sfx8"

SR = 44100
OS = 4                     # render at 4x, then filter and decimate
FS = SR * OS
TICK_HZ = 240              # control rate: volume, pitch and duty change 240 times a second
SPT = FS // TICK_HZ        # samples per tick at the oversampled rate (735)
FRAME = 4                  # ticks per 60 Hz frame, used by frame envelopes
CPU = 1789773.0            # NTSC 2A03 clock

# Loudness rules for the whole set.
PEAK_CEIL_DB = -3.0        # no file peaks above this
TARGET_ST_DB = -14.5       # loudest 50 ms of every sound aims here (before per-sound trim)
ST_WIN = 0.050

NOISE_PERIODS = [4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068]
DUTY = {12: 0.125, 25: 0.25, 50: 0.5, 75: 0.75}

_TRI = np.array(list(range(15, -1, -1)) + list(range(0, 16)), dtype=np.float64)
TRI_TABLE = (_TRI - 7.5) / 7.5


def _lfsr(short: bool) -> np.ndarray:
    reg, tap, bits = 1, (6 if short else 1), []
    while True:
        bits.append(reg & 1)
        fb = (reg & 1) ^ ((reg >> tap) & 1)
        reg = (reg >> 1) | (fb << 14)
        if reg == 1:
            break
    return np.array(bits, dtype=np.int8)


LFSR_LONG = _lfsr(False)
LFSR_SHORT = _lfsr(True)

NOTE_INDEX = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def N(name: str) -> float:
    """Note name to Hz, e.g. 'A4' = 440, 'F#5', 'Bb3'."""
    letter, rest = name[0].upper(), name[1:]
    semi = NOTE_INDEX[letter]
    while rest and rest[0] in "#b":
        semi += 1 if rest[0] == "#" else -1
        rest = rest[1:]
    midi = 12 * (int(rest) + 1) + semi
    return 440.0 * 2 ** ((midi - 69) / 12)


def st(f: float, semis: float) -> float:
    return f * 2 ** (semis / 12)


def dec(v0: int, frames: int, curve: float = 1.0) -> list[int]:
    """Stepped volume decay from v0 to 0 over `frames` 60 Hz frames (curve > 1 lingers)."""
    return [int(round(v0 * (1 - i / frames) ** (1 / curve))) for i in range(frames)] + [0]


class Voice:
    def __init__(self, kind: str, ticks: int):
        self.kind = kind
        self.freq = np.zeros(ticks)
        self.vol = np.zeros(ticks)
        self.duty = np.full(ticks, 0.5)
        self.short = np.zeros(ticks, dtype=bool)
        self.scale = None      # loops with lock_phase: tiny pitch trim so each pass ends in phase
        self.restart = None    # loops with lock_phase (noise): restart the shift register every N ticks

    def put(self, t0: float, dur: float, f0: float, f1: float | None = None, *,
            v0: float = 15, v1: float | None = None, vcurve: float = 1.0,
            venv: list[int] | None = None, level: float = 1.0,
            duty: int = 50, glide: str = "exp", gcurve: float = 1.0,
            arp: list[float] | None = None, arp_ticks: int = FRAME,
            vib: tuple[float, float] | None = None, short: bool = False,
            only_where_silent: bool = False) -> None:
        """Write one note. Times in seconds. For noise, f0/f1 are pitch settings 0..15.

        v0 -> v1 is a straight or curved volume ramp over the note. venv is a
        per-frame (60 Hz) volume list, last value held, scaled by `level`.
        arp cycles semitone offsets every arp_ticks. vib = (rate Hz, depth semitones).
        """
        n = len(self.freq)
        a = int(round(t0 * TICK_HZ))
        k = max(1, int(round(dur * TICK_HZ)))
        b = min(a + k, n)
        if a >= n:
            return
        k = b - a
        x = np.arange(k) / max(k - 1, 1)
        if f1 is None:
            f = np.full(k, float(f0))
        elif glide == "exp" and self.kind != "noi":
            f = f0 * (f1 / f0) ** (x ** gcurve)
        else:
            f = f0 + (f1 - f0) * x ** gcurve
        if arp:
            offs = np.array(arp, dtype=float)[(np.arange(k) // arp_ticks) % len(arp)]
            f = f + offs if self.kind == "noi" else f * 2 ** (offs / 12)
        if vib:
            rate, depth = vib
            tt = np.arange(k) / TICK_HZ
            f = f * 2 ** (depth * np.sin(2 * math.pi * rate * tt) / 12)
        if venv is not None:
            e = np.repeat(np.array(venv, dtype=float), FRAME)
            if len(e) < k:
                e = np.concatenate([e, np.full(k - len(e), e[-1] if len(e) else 0)])
            vol = e[:k] * level
        else:
            v1 = v0 if v1 is None else v1
            vol = v0 + (v1 - v0) * x ** vcurve
        vol = np.clip(np.round(vol), 0, 15)
        sl = slice(a, b)
        mask = (self.vol[sl] == 0) if only_where_silent else np.ones(k, dtype=bool)
        self.freq[sl] = np.where(mask, f, self.freq[sl])
        self.vol[sl] = np.where(mask, vol, self.vol[sl])
        self.duty[sl] = np.where(mask, DUTY.get(duty, 0.5), self.duty[sl])
        self.short[sl] = np.where(mask, short, self.short[sl])


class Sound:
    def __init__(self, dur: float):
        self.dur = dur
        ticks = int(math.ceil(dur * TICK_HZ)) + 1
        self.p1 = Voice("pulse", ticks)
        self.p2 = Voice("pulse", ticks)
        self.tri = Voice("tri", ticks)
        self.noi = Voice("noi", ticks)

    def echo(self, src: Voice, dst: Voice, delay: float, scale: float = 0.5,
             duty: int | None = None) -> None:
        """Copy src onto dst, delayed and quieter, only where dst is silent."""
        d = int(round(delay * TICK_HZ))
        n = len(src.vol)
        if d >= n:
            return
        f = np.zeros(n); v = np.zeros(n); du = np.full(n, 0.5)
        f[d:], v[d:], du[d:] = src.freq[:n - d], np.round(src.vol[:n - d] * scale), src.duty[:n - d]
        if duty is not None:
            du[:] = DUTY[duty]
        m = (dst.vol == 0) & (v > 0)
        dst.freq[m], dst.vol[m], dst.duty[m] = f[m], v[m], du[m]

    def seq(self, voice: Voice, t0: float, bpm: float, notes: list, *, duty: int = 50,
            venv: list[int] | None = None, level: float = 1.0, gate: float = 0.92,
            vib: tuple[float, float] | None = None, last_decay: float | None = None) -> float:
        """Play (note, beats) pairs; note None is a rest. Returns end time."""
        beat, t = 60.0 / bpm, t0
        for i, (name, beats) in enumerate(notes):
            d = beats * beat
            if name is not None:
                if last_decay and i == len(notes) - 1:
                    voice.put(t, last_decay, N(name), v0=(venv[0] if venv else 12) * level,
                              v1=0, vcurve=0.8, duty=duty, vib=vib)
                else:
                    voice.put(t, d * gate, N(name), venv=venv, level=level, duty=duty, vib=vib,
                              v0=12 * level)
            t += d
        return t


# ---------------------------------------------------------------- rendering

def _snap(freq: np.ndarray, div: int) -> np.ndarray:
    """Snap to the nearest real NES period register value (11-bit)."""
    out = np.zeros_like(freq)
    on = freq > 0
    p = np.clip(np.round(CPU / (div * freq[on]) - 1), 8, 2047)
    out[on] = CPU / (div * (p + 1))
    return out


def _render_pulse(v: Voice) -> np.ndarray:
    f = np.repeat(_snap(v.freq, 16), SPT)
    if v.scale is not None:
        f = f * v.scale
    vol = np.repeat(v.vol, SPT) / 15.0
    d = np.repeat(v.duty, SPT)
    ph = np.cumsum(f / FS) % 1.0
    return ((ph < d).astype(np.float64) - d) * vol


def _render_tri(v: Voice) -> np.ndarray:
    gate = v.vol > 0
    f = np.repeat(np.where(gate, _snap(v.freq, 32), 0.0), SPT)
    if v.scale is not None:
        f = f * v.scale
    ph = np.cumsum(f / FS) % 1.0
    idx = np.minimum((ph * 32).astype(np.int64), 31)
    return TRI_TABLE[idx] * 0.565   # frozen when off: holds its level like the hardware


def _render_noise(v: Voice) -> np.ndarray:
    per = np.array(NOISE_PERIODS, dtype=float)[np.clip(np.round(v.freq), 0, 15).astype(int)]
    rate = np.repeat(CPU / per, SPT)
    if v.restart is None:
        pos = np.cumsum(rate / FS).astype(np.int64)
    else:
        # count register steps afresh in each block, so every block gets the same noise
        blk = v.restart * SPT
        n = len(rate)
        r = np.concatenate([rate, np.zeros(-n % blk)]).reshape(-1, blk) / FS
        pos = np.cumsum(r, axis=1).ravel()[:n].astype(np.int64)
    short = np.repeat(v.short, SPT)
    bit = np.where(short, LFSR_SHORT[pos % len(LFSR_SHORT)], LFSR_LONG[pos % len(LFSR_LONG)])
    vol = np.repeat(v.vol, SPT) / 15.0
    return ((1 - bit) - 0.5) * 0.66 * vol


def _lowpass_fir(cut: float, taps: int = 127) -> np.ndarray:
    n = np.arange(taps) - (taps - 1) / 2
    h = np.sinc(2 * cut / FS * n) * np.blackman(taps)
    return h / h.sum()


FIR = _lowpass_fir(14000.0)


def _highpass(x: np.ndarray, fc: float = 37.0) -> np.ndarray:
    rc = 1.0 / (2 * math.pi * fc)
    a = rc / (rc + 1.0 / SR)
    xs = x.tolist()
    ys = [0.0] * len(xs)
    y, px = 0.0, xs[0] if xs else 0.0
    for i, xv in enumerate(xs):
        y = a * (y + xv - px)
        px = xv
        ys[i] = y
    return np.array(ys)


def render(s: Sound) -> np.ndarray:
    mix = _render_pulse(s.p1) + _render_pulse(s.p2) + _render_tri(s.tri) + _render_noise(s.noi)
    mix = np.convolve(mix, FIR, mode="same")[::OS]
    mix = _highpass(mix)
    return mix[: int(s.dur * SR)]


def db(x: float) -> float:
    return 20 * math.log10(max(x, 1e-9))


def short_term_max_rms(x: np.ndarray) -> float:
    w = int(ST_WIN * SR)
    if len(x) <= w:
        return float(np.sqrt(np.mean(x ** 2)))
    c = np.concatenate([[0.0], np.cumsum(x ** 2)])
    hop = int(0.005 * SR)
    starts = np.arange(0, len(x) - w + 1, hop)
    return float(np.sqrt(np.max(c[starts + w] - c[starts]) / w))


def finish(x: np.ndarray, trim_db: float, fade_out: float) -> tuple[np.ndarray, dict]:
    peak = float(np.max(np.abs(x)))
    if peak <= 0:
        raise ValueError("silent sound")
    # tight head: drop anything quieter than -50 dB of peak before the attack
    thr = peak * 10 ** (-50 / 20)
    start = int(np.argmax(np.abs(x) > thr))
    x = x[start:]
    # tail: drop trailing near-silence, keep a short fade
    loud = np.nonzero(np.abs(x) > peak * 10 ** (-60 / 20))[0]
    x = x[: loud[-1] + 1 + int(0.005 * SR)]
    fi = min(int(0.001 * SR), len(x) // 4)      # 1 ms anti-click ramp at the head
    x[:fi] *= np.linspace(0, 1, fi, endpoint=False) ** 0.5
    fo = min(int(fade_out * SR), len(x) // 3)
    x[len(x) - fo:] *= np.cos(np.linspace(0, math.pi / 2, fo)) ** 2
    gain = min(10 ** (PEAK_CEIL_DB / 20) / np.max(np.abs(x)),
               10 ** ((TARGET_ST_DB + trim_db) / 20) / short_term_max_rms(x))
    x = x * gain
    pcm = np.clip(np.round(x * 32767), -32768, 32767).astype(np.int16)
    y = pcm / 32768.0
    stats = {
        "duration": round(len(pcm) / SR, 3),
        "peak_dbfs": round(db(float(np.max(np.abs(y)))), 2),
        "rms_dbfs": round(db(float(np.sqrt(np.mean(y ** 2)))), 2),
        "loudest_50ms_rms_dbfs": round(db(short_term_max_rms(y)), 2),
    }
    return pcm, stats


LOOP_XFADE = 0.08          # loops: the end is blended into the start over this long
LOOP_SEARCH = 0.005        # loops: look this far either side of the set length for the best seam


def finish_loop(x: np.ndarray, length: float, trim_db: float,
                power: bool = False) -> tuple[np.ndarray, dict]:
    """Cut a seamless loop out of a steady render. x starts one full loop early (pre-roll)
    so the filters have settled. The tail past the loop is crossfaded into the head, so the
    last sample runs straight on into the first. No head ramp or fade-out: those would click.
    power=True uses an equal-power blend, for loops whose seam is mostly noise: two different
    stretches of noise blended in a straight line dip by up to 3 dB halfway through."""
    L = int(round(length * SR))
    xf = int(LOOP_XFADE * SR)
    sr = int(LOOP_SEARCH * SR)
    seg = x[L:]
    head = seg[:xf]

    def match(n: int) -> float:
        tail = seg[n:n + xf]
        return float(np.dot(head, tail) / (np.linalg.norm(head) * np.linalg.norm(tail) + 1e-12))

    n = max(range(L - sr, L + sr + 1), key=match)
    w = np.linspace(0.0, 1.0, xf, endpoint=False)
    w_in, w_out = (np.sin(w * math.pi / 2), np.cos(w * math.pi / 2)) if power else (w, 1 - w)
    out = seg[:n].copy()
    out[:xf] = seg[:xf] * w_in + seg[n:n + xf] * w_out
    gain = min(10 ** (PEAK_CEIL_DB / 20) / np.max(np.abs(out)),
               10 ** ((TARGET_ST_DB + trim_db) / 20) / short_term_max_rms(out))
    pcm = np.clip(np.round(out * gain * 32767), -32768, 32767).astype(np.int16)
    y = pcm / 32768.0
    stats = {
        "duration": round(len(pcm) / SR, 3),
        "peak_dbfs": round(db(float(np.max(np.abs(y)))), 2),
        "rms_dbfs": round(db(float(np.sqrt(np.mean(y ** 2)))), 2),
        "loudest_50ms_rms_dbfs": round(db(short_term_max_rms(y)), 2),
    }
    return pcm, stats


def lock_phase(s: Sound, length: float) -> dict:
    """Make a loop render the same at the start of every pass, not just nearly the same.

    The notes repeat every pass, but the oscillators run on: a pulse or the triangle ends a
    pass part-way through a cycle, so the next pass starts at a different point in its wave.
    The seam crossfade then blends two copies that are out of step, which thins the sound for
    80 ms. Tuned music makes that easy to hear. Here each pulse and the triangle get a tiny
    pitch trim (well under a cent) so they run a whole number of cycles per pass, and the noise
    register restarts at every pass. The render then repeats sample for sample, so the seam
    blends identical audio. The run-in pass is also overwritten with a copy of the loop pass
    (notes ringing in from the end included), so what leads into the seam is exactly what
    leads into it in the game. Returns the pitch trim per voice, in cents."""
    lt = int(round(length * TICK_HZ))
    if lt * SPT % OS or abs(lt / TICK_HZ - length) > 1e-9:
        raise ValueError("lock_phase: loop length must be a whole number of ticks, divisible by 4")
    n = len(s.p1.vol)
    for name, v in (("p1", s.p1), ("p2", s.p2), ("tri", s.tri), ("noi", s.noi)):
        m = n - 2 * lt
        for arr in (v.freq, v.vol, v.duty, v.short):
            if not np.array_equal(arr[2 * lt:], arr[lt:lt + m]):
                raise ValueError(f"lock_phase: {name} does not repeat every {length} s")
            arr[:lt] = arr[lt:2 * lt]
    trims = {}
    for name, v, div in (("p1", s.p1, 16), ("p2", s.p2, 16), ("tri", s.tri, 32)):
        f = _snap(v.freq[lt:2 * lt], div)
        if v.kind == "tri":
            f = np.where(v.vol[lt:2 * lt] > 0, f, 0.0)
        cycles = float(np.sum(f)) / TICK_HZ
        if cycles >= 1:
            v.scale = round(cycles) / cycles
            trims[name] = round(1200 * math.log2(v.scale), 4)
    s.noi.restart = lt
    return trims


def write_wav(path: Path, pcm: np.ndarray, loop: bool = False) -> None:
    if not loop:
        with wave.open(str(path), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm.tobytes())
        return
    # Looping file: add a 'smpl' chunk with one forward loop over the whole file. Godot's
    # importer (Loop Mode: Detect From WAV, the default here) reads it and loops the sound.
    # The loop end is written as the frame count, which is how Godot reads it (exclusive).
    import struct
    data = pcm.tobytes()
    fmt = struct.pack("<HHIIHH", 1, 1, SR, SR * 2, 2, 16)
    smpl = struct.pack("<9I", 0, 0, int(round(1e9 / SR)), 60, 0, 0, 0, 1, 0)
    smpl += struct.pack("<6I", 0, 0, 0, len(pcm), 0, 0)
    body = (b"WAVE" + b"fmt " + struct.pack("<I", len(fmt)) + fmt
            + b"data" + struct.pack("<I", len(data)) + data
            + b"smpl" + struct.pack("<I", len(smpl)) + smpl)
    path.write_bytes(b"RIFF" + struct.pack("<I", len(body)) + body)


# ---------------------------------------------------------------- the set

SOUNDS: dict[str, dict] = {}


def sfx(name: str, dur: float, category: str, trigger: str, trim_db: float = 0.0,
        fade: float = 0.012, loop: bool = False, power_seam: bool = False,
        lock: bool = False):
    """loop=True: dur is the loop length. The function is called on a longer Sound and must
    fill all of s.dur with a pattern that repeats a whole number of times per loop.
    power_seam=True: blend the loop seam at equal power (for loops that are mostly noise).
    lock=True: lock the oscillators so every pass renders identically (see lock_phase)."""
    def deco(fn):
        SOUNDS[name] = dict(fn=fn, dur=dur, category=category, trigger=trigger,
                            trim_db=trim_db, fade=fade, loop=loop, power_seam=power_seam,
                            lock=lock)
        return fn
    return deco


# House motif: root, fifth, octave on D. Positive cues are in D major,
# losses fall toward D minor. Everything shares these pitches.

# ---- player

@sfx("jump", 0.20, "player", "Player leaves the ground with a normal or buffered jump")
def _(s):
    s.p1.put(0, 0.17, N("D5"), N("A6"), venv=[13, 13, 12, 12, 11, 10, 9, 8, 7, 6, 5, 3], duty=25,
             gcurve=0.55)
    s.noi.put(0, 0.02, 3, venv=[6, 2])


@sfx("wall_kick", 0.18, "player", "Player kicks off a wall")
def _(s):
    s.noi.put(0, 0.035, 2, 5, venv=[12, 8, 3], glide="lin")
    s.p1.put(0.008, 0.14, N("A5"), N("D7"), venv=[14, 13, 11, 9, 7, 5, 4, 3, 2], duty=12, gcurve=0.5)
    s.p2.put(0.03, 0.12, N("E5"), N("A6"), venv=[6, 5, 4, 3, 2, 1], duty=25, gcurve=0.5)


@sfx("land_soft", 0.08, "player", "Player lands from a short fall", trim_db=-5.0)
def _(s):
    s.noi.put(0, 0.07, 11, 13, venv=[10, 7, 4, 2, 1], glide="lin")
    s.tri.put(0, 0.035, N("A2"), N("D2"))


@sfx("land_hard", 0.22, "player", "Player lands from a long fall or a dash-fall", trim_db=-1.0)
def _(s):
    s.tri.put(0, 0.13, N("D3"), N("D1"), gcurve=0.6)
    s.noi.put(0, 0.2, 10, 14, venv=[15, 13, 10, 8, 6, 5, 4, 3, 2, 2, 1, 1], glide="lin")
    s.p1.put(0, 0.03, N("A3"), N("D3"), venv=[10, 6], duty=50)


@sfx("dash", 0.26, "player", "Player starts a dash")
def _(s):
    s.noi.put(0, 0.24, 1, 8, venv=[15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1], glide="lin",
              gcurve=0.7)
    s.p1.put(0, 0.11, N("D7"), N("D5"), venv=[12, 11, 9, 7, 5, 3, 2], duty=12, gcurve=0.6)
    s.p2.put(0.02, 0.1, N("A6"), N("A4"), venv=[6, 5, 4, 3, 2, 1], duty=12, gcurve=0.6)


def _stomp(s, chain: int):
    up = [0, 3, 7][chain - 1]           # rises by third steps: D, F, A
    root = st(N("D5"), up)
    s.noi.put(0, 0.05, 6, 10, venv=[15, 11, 6, 2], glide="lin")
    s.tri.put(0, 0.05, st(N("D3"), up), st(N("D2"), up))
    s.p1.put(0.0, 0.05, root, venv=[14, 13, 12], duty=50)
    s.p1.put(0.05, 0.14, st(root, 7), st(root, 12), venv=[14, 12, 10, 8, 6, 4, 3, 2, 1], duty=25,
             gcurve=0.4)
    s.echo(s.p1, s.p2, 0.05, 0.4, duty=12)
    if chain >= 3:
        s.p2.put(0.11, 0.12, st(root, 24), venv=[8, 6, 4, 3, 2, 1], duty=12)


@sfx("stomp_1", 0.24, "player", "Player lands on an enemy, first in a chain")
def _(s): _stomp(s, 1)


@sfx("stomp_2", 0.24, "player", "Second enemy in the same air chain")
def _(s): _stomp(s, 2)


@sfx("stomp_3", 0.26, "player", "Third or later enemy in the same air chain")
def _(s): _stomp(s, 3)


@sfx("bump_block", 0.14, "blocks", "Player's head hits a block that still has something in it")
def _(s):
    s.tri.put(0, 0.09, N("A3"), N("D2"), gcurve=0.5)
    s.p1.put(0, 0.08, N("D4"), N("A3"), venv=[14, 11, 8, 5, 3], duty=50)
    s.noi.put(0, 0.06, 7, 11, venv=[12, 7, 3, 1], glide="lin")
    s.p2.put(0.0, 0.1, N("D5"), N("A4"), venv=[5, 4, 3, 2, 1], duty=25)


@sfx("bump_used", 0.1, "blocks", "Player's head hits an empty or solid block", trim_db=-3.0)
def _(s):
    s.tri.put(0, 0.05, N("E2"), N("A1"))
    s.noi.put(0, 0.06, 10, 13, venv=[13, 8, 4, 1], glide="lin")
    s.p1.put(0, 0.03, N("A2"), venv=[9, 5], duty=50)


@sfx("brick_break", 0.46, "blocks", "Charged player breaks a brick with a head bump")
def _(s):
    s.noi.put(0, 0.08, 4, 7, venv=[15, 13, 10, 7, 5], glide="lin")
    s.noi.put(0.08, 0.12, 6, 9, venv=[11, 9, 7, 5, 3, 2, 1], glide="lin")
    s.noi.put(0.2, 0.12, 8, 10, venv=[8, 6, 5, 3, 2, 1], glide="lin")
    s.noi.put(0.32, 0.12, 10, 12, venv=[5, 4, 3, 2, 1], glide="lin")
    s.tri.put(0, 0.1, N("D3"), N("D1"), gcurve=0.5)
    s.p1.put(0, 0.04, N("D6"), N("A5"), venv=[10, 6, 2], duty=12)


@sfx("shard", 0.42, "pickups", "Player collects a shard", fade=0.03)
def _(s):
    s.p1.put(0, 0.05, N("D6"), venv=[13, 13, 12], duty=25)
    s.p1.put(0.05, 0.36, N("A6"), venv=[13, 12, 11, 10, 9, 8, 8, 7, 7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1],
             duty=25)


@sfx("big_shard", 0.9, "pickups", "Player collects one of the three big shards", fade=0.05)
def _(s):
    notes = ["D6", "F#6", "A6", "D7", "A6", "D7", "F#7", "A7"]
    for i, n in enumerate(notes):
        s.p1.put(i * 0.05, 0.05, N(n), venv=[14, 12, 11], duty=25)
    s.p1.put(0.4, 0.45, N("D7"), venv=[13, 12, 11, 10, 9, 8, 7, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1],
             duty=25, vib=(7, 0.15))
    s.echo(s.p1, s.p2, 0.075, 0.45, duty=12)
    s.tri.put(0, 0.2, N("D4"))
    s.tri.put(0.2, 0.2, N("A3"))
    s.tri.put(0.4, 0.2, N("D4"))


@sfx("extra_life", 0.95, "pickups", "Player earns a life (100 shards or a 1UP block)", fade=0.05)
def _(s):
    bpm = 300
    s.seq(s.p1, 0, bpm, [("A5", 0.5), ("D6", 0.5), ("F#6", 0.5), ("E6", 0.5), ("A6", 0.5),
                         ("D7", 3)], duty=50, venv=[13, 12, 11, 10], last_decay=0.55)
    s.echo(s.p1, s.p2, 0.07, 0.4, duty=25)
    s.tri.put(0, 0.2, N("D4"))
    s.tri.put(0.25, 0.25, N("A4"))
    s.tri.put(0.5, 0.2, N("D5"))


@sfx("charge_get", 1.05, "pickups", "Player picks up CHARGE", fade=0.05)
def _(s):
    chords = [("D5", [0, 4, 7]), ("E5", [0, 4, 7]), ("F#5", [0, 3, 7]), ("G5", [0, 4, 7]),
              ("A5", [0, 4, 7])]
    t = 0.0
    for root, arp in chords:
        s.p1.put(t, 0.14, N(root), arp=arp, arp_ticks=FRAME, venv=[13, 13, 12, 12, 11, 11, 10, 10, 9],
                 duty=25)
        s.tri.put(t, 0.12, st(N(root), -24))
        t += 0.14
    s.p1.put(t, 0.33, N("D6"), arp=[0, 4, 7, 12], arp_ticks=FRAME,
             venv=[14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1], duty=25)
    s.tri.put(t, 0.22, N("D3"))
    s.echo(s.p1, s.p2, 0.035, 0.45, duty=12)


@sfx("charge_lose", 0.7, "player", "Charged player is hit and loses CHARGE (survives)", fade=0.04)
def _(s):
    s.noi.put(0, 0.1, 3, 8, venv=[15, 12, 9, 6, 4, 2], glide="lin")
    s.p1.put(0, 0.66, N("A5"), N("D3"), arp=[0, -12], arp_ticks=2, duty=50,
             venv=[14, 13, 13, 12, 12, 11, 11, 10, 10, 9, 9, 8, 8, 7, 7, 6, 6, 5, 5, 4, 4, 3, 3,
                   2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0], gcurve=0.8)
    s.p2.put(0, 0.08, N("D6"), N("D5"), venv=[10, 7, 4, 2, 1], duty=12)
    s.tri.put(0.0, 0.5, N("D4"), N("D2"))


@sfx("death", 1.9, "player", "Player dies (hit uncharged, pit, crush or timer)", fade=0.08)
def _(s):
    # the hit
    s.noi.put(0, 0.14, 2, 9, venv=[15, 14, 11, 8, 6, 4, 2, 1], glide="lin")
    s.p1.put(0, 0.12, N("D7"), N("D5"), venv=[15, 13, 11, 9, 7, 5, 3], duty=12)
    s.p2.put(0, 0.12, N("G#6"), N("G#4"), venv=[9, 8, 6, 4, 2], duty=50)
    # silence, then the signal falls away
    t = 0.34
    for n in ["A5", "G#5", "G5"]:
        s.p1.put(t, 0.13, N(n), venv=[12, 11, 10, 9], duty=25)
        t += 0.15
    s.p1.put(t, 0.95, N("F#5"), N("D3"), venv=dec(12, 57, 1.6), duty=25, vib=(6, 0.35), gcurve=1.6)
    s.echo(s.p1, s.p2, 0.09, 0.4, duty=12)
    s.tri.put(0.34, 0.13, N("D4"))
    s.tri.put(0.49, 0.13, N("C#4"))
    s.tri.put(0.64, 0.13, N("C4"))
    s.tri.put(0.79, 0.5, N("B3"), N("D2"), gcurve=1.5)


@sfx("spring", 0.42, "level", "Player is thrown upward by a spring", fade=0.03)
def _(s):
    s.p1.put(0, 0.38, N("D4"), N("D6"), vib=(22, 1.6), venv=[15, 14, 13, 12, 12, 11, 10, 9, 8, 7, 6,
                                                            5, 5, 4, 4, 3, 3, 2, 2, 1, 1, 1, 1],
             duty=12, gcurve=0.5)
    s.tri.put(0, 0.12, N("D3"), N("A3"), vib=(22, 2))
    s.noi.put(0, 0.03, 5, venv=[10, 4])


@sfx("lift_ring", 0.34, "level", "Player passes through a lift ring (dash refilled, popped up)",
     fade=0.03)
def _(s):
    for i, n in enumerate(["A5", "D6", "F#6", "A6"]):
        s.p1.put(i * 0.03, 0.03, N(n), venv=[14, 13], duty=12)
    s.p1.put(0.12, 0.2, N("D7"), N("A7"), venv=[13, 11, 9, 7, 6, 5, 4, 3, 2, 2, 1, 1], duty=12,
             gcurve=0.4)
    s.echo(s.p1, s.p2, 0.04, 0.5, duty=25)
    s.noi.put(0, 0.12, 1, 4, venv=[7, 6, 5, 4, 3, 2, 1], glide="lin")


@sfx("checkpoint", 1.3, "level", "Player lights the midway beacon", fade=0.08)
def _(s):
    # a bell: fifth + octave, struck twice, with a long echo tail
    bell = dec(15, 64, 0.45)
    s.p1.put(0, 0.12, N("A5"), venv=bell, duty=25)
    s.p1.put(0.12, 1.1, N("D6"), venv=bell, duty=25, vib=(5, 0.08))
    s.p2.put(0.12, 1.1, N("A6"), venv=dec(8, 50, 0.45), duty=12)
    s.tri.put(0, 0.1, N("A3"))
    s.tri.put(0.12, 0.5, N("D3"))
    s.noi.put(0, 0.05, 1, venv=[9, 5, 2])
    s.noi.put(0.12, 0.05, 1, venv=[9, 5, 2])


@sfx("mast_touch", 0.32, "level", "Player grabs the goal mast (plays before the slide)", fade=0.03)
def _(s):
    s.noi.put(0, 0.05, 0, 3, venv=[15, 10, 5, 2], glide="lin", short=True)
    s.p1.put(0, 0.3, N("D7"), venv=[15, 13, 11, 10, 9, 8, 7, 6, 5, 4, 4, 3, 3, 2, 2, 1, 1, 1],
             duty=12)
    s.p2.put(0, 0.3, N("A6"), venv=[10, 9, 8, 7, 6, 5, 4, 3, 3, 2, 2, 1, 1], duty=25)
    s.tri.put(0, 0.08, N("D4"))


@sfx("mast_slide", 1.05, "level", "Player slides down the mast to the ground", fade=0.05)
def _(s):
    # stepped falls, like a hand going down rungs
    t = 0.0
    top = N("D7")
    while t < 0.98:
        s.p1.put(t, 0.065, top, st(top, -3), venv=[11, 9, 7, 5], duty=12)
        top = st(top, -1.2)
        t += 0.07
    s.noi.put(0, 1.0, 1, venv=[3, 3, 3, 3, 2], short=False)
    s.tri.put(0, 1.0, N("A4"), N("D3"), glide="exp")


@sfx("level_clear", 2.7, "jingles", "Level finished (after the mast slide)", fade=0.12)
def _(s):
    bpm = 150
    mel = [("A4", 0.25), ("D5", 0.25), ("F#5", 0.25), ("A5", 0.25), ("B5", 0.5), ("A5", 0.5),
           ("F#5", 0.25), ("G5", 0.25), ("A5", 0.5), ("E5", 0.5), ("D6", 2.0)]
    s.seq(s.p1, 0, bpm, mel, duty=25, venv=[14, 13, 12, 11, 11, 10], last_decay=1.05)
    har = [("F#4", 0.25), ("A4", 0.25), ("D5", 0.25), ("F#5", 0.25), ("G5", 0.5), ("F#5", 0.5),
           ("D5", 0.25), ("E5", 0.25), ("F#5", 0.5), ("C#5", 0.5), ("A5", 2.0)]
    s.seq(s.p2, 0, bpm, har, duty=12, venv=[9, 9, 8, 8, 7], last_decay=1.0)
    bass = [("D3", 1), ("G2", 1), ("D3", 0.5), ("A2", 0.5), ("D3", 1.0)]
    s.seq(s.tri, 0, bpm, bass, gate=0.8, last_decay=0.8)
    beat = 60 / bpm
    for i in range(10):
        s.noi.put(i * beat / 2, 0.03, 1, venv=[8 if i % 2 == 0 else 5, 3, 1])
    s.noi.put(4 * beat, 0.25, 4, 9, venv=[12, 10, 8, 6, 5, 4, 3, 2, 1], glide="lin")


@sfx("world_clear", 4.6, "jingles", "World finished: the Gate is lit", fade=0.2)
def _(s):
    bpm = 132
    b = 60 / bpm
    lead = [("D5", 0.5), ("A5", 0.5), ("D6", 1.0), ("C#6", 0.5), ("B5", 0.5), ("A5", 1.0),
            ("B5", 0.5), ("C6", 0.5), ("D6", 0.5), ("E6", 0.5), ("F#6", 1.5), ("E6", 0.5),
            ("D6", 3.0)]
    s.seq(s.p1, 0, bpm, lead, duty=50, venv=[13, 12, 12, 11, 11, 10, 10, 10], vib=(5.5, 0.12),
          last_decay=1.7)
    second = [("A4", 0.5), ("F#5", 0.5), ("A5", 1.0), ("A5", 0.5), ("G5", 0.5), ("F#5", 1.0),
              ("G5", 0.5), ("A5", 0.5), ("B5", 0.5), ("C#6", 0.5), ("D6", 1.5), ("C#6", 0.5),
              ("A5", 3.0)]
    s.seq(s.p2, 0, bpm, second, duty=25, venv=[9, 9, 8, 8, 8, 7], last_decay=1.6)
    bass = [("D3", 1), ("D3", 0.5), ("A2", 0.5), ("G2", 1), ("A2", 1), ("G2", 1), ("A2", 1),
            ("B2", 1), ("A2", 1), ("D3", 3.0)]
    s.seq(s.tri, 0, bpm, bass, gate=0.85, last_decay=1.5)
    for i in range(16):
        accent = i % 4 == 2
        s.noi.put(i * b / 2, 0.08 if accent else 0.03, 5 if accent else 1,
                  venv=[12, 8, 5, 3, 1] if accent else [6, 3, 1])
    t = 8 * b
    for i in range(8):   # snare roll into the last chord
        s.noi.put(t + i * b / 8, b / 8, 4, venv=[5 + i, 3 + i // 2, 2])
    s.noi.put(t + b, 0.6, 5, 11, venv=[13, 12, 10, 9, 8, 7, 6, 5, 4, 4, 3, 3, 2, 2, 1],
              glide="lin")


@sfx("game_over", 3.1, "jingles", "Last life lost (restart the world at level 1)", fade=0.2)
def _(s):
    bpm = 96
    lead = [("D5", 0.5), ("C5", 0.5), ("Bb4", 0.5), ("A4", 0.5), ("G4", 0.75), ("F4", 0.25),
            ("E4", 0.5), ("D4", 2.0)]
    s.seq(s.p1, 0, bpm, lead, duty=50, venv=[12, 11, 11, 10, 10, 9, 9, 9], vib=(5, 0.1),
          last_decay=1.25)
    s.echo(s.p1, s.p2, 0.12, 0.35, duty=12)
    bass = [("D3", 1), ("G2", 1), ("A2", 1), ("D2", 2.0)]
    s.seq(s.tri, 0, bpm, bass, gate=0.9, last_decay=1.2)
    s.noi.put(0, 0.3, 12, 14, venv=[6, 5, 4, 3, 2, 1], glide="lin")


@sfx("timer_warning", 1.0, "ui", "Level timer drops below 100", fade=0.04)
def _(s):
    for i in range(3):
        t = i * 0.3
        s.p1.put(t, 0.07, N("A6"), venv=[14, 13, 12, 11], duty=50)
        s.p1.put(t + 0.1, 0.1, N("D7"), venv=[14, 13, 12, 10, 8, 5], duty=50)
        s.p2.put(t, 0.07, N("A5"), venv=[8, 7, 6], duty=12)
        s.p2.put(t + 0.1, 0.1, N("D6"), venv=[8, 7, 6, 4, 2], duty=12)
        s.tri.put(t, 0.05, N("D4"))


@sfx("pause", 0.34, "ui", "Game paused or unpaused", fade=0.03)
def _(s):
    for i, n in enumerate(["D6", "A5", "D6", "A6"]):
        last = i == 3
        s.p1.put(i * 0.055, 0.2 if last else 0.05, N(n),
                 venv=[12, 11, 9, 7, 5, 4, 3, 2, 1] if last else [12, 11, 10], duty=50)
    s.echo(s.p1, s.p2, 0.03, 0.35, duty=12)


@sfx("menu_move", 0.05, "ui", "Menu cursor moves", trim_db=-5.0)
def _(s):
    s.p1.put(0, 0.045, N("A6"), venv=[12, 8, 4], duty=12)


@sfx("menu_confirm", 0.22, "ui", "Menu choice confirmed", trim_db=-2.0, fade=0.02)
def _(s):
    s.p1.put(0, 0.045, N("D6"), venv=[13, 12, 11], duty=25)
    s.p1.put(0.05, 0.16, N("A6"), venv=[13, 12, 10, 8, 6, 4, 3, 2, 1], duty=25)
    s.echo(s.p1, s.p2, 0.03, 0.4, duty=12)


# ---- traps

@sfx("loose_floor_shake", 0.36, "traps", "Loose floor starts its 0.35 s shake after being stood on",
     trim_db=-4.0)
def _(s):
    for i in range(9):
        s.noi.put(i * 0.04, 0.03, 9 if i % 2 else 7, venv=[9, 5, 2], short=False)
    s.tri.put(0, 0.34, N("D2"), arp=[0, 1], arp_ticks=2)
    s.p1.put(0, 0.34, N("A2"), arp=[0, 1, 0, -1], arp_ticks=2, venv=[4, 5, 5, 6, 6, 5], duty=12)


@sfx("loose_floor_crack", 0.16, "traps", "Loose floor breaks free (end of the shake)")
def _(s):
    s.noi.put(0, 0.04, 2, 4, venv=[15, 11, 6], glide="lin")
    s.noi.put(0.04, 0.11, 6, 10, venv=[10, 8, 6, 4, 2, 1], glide="lin")
    s.p1.put(0, 0.025, N("E6"), N("A5"), venv=[12, 6], duty=12)
    s.tri.put(0, 0.06, N("A2"), N("E2"))


@sfx("loose_floor_fall", 0.36, "traps", "Loose floor drops (plays while falling)", trim_db=-3.0,
     fade=0.04)
def _(s):
    s.noi.put(0, 0.34, 5, 11, venv=[10, 10, 9, 9, 8, 7, 6, 5, 4, 3, 2, 1], glide="lin")
    s.p1.put(0, 0.3, N("A5"), N("A3"), venv=[6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1], duty=12)


@sfx("loose_floor_land", 0.4, "traps", "Fallen floor lands as rubble (also crushes what is below)",
     fade=0.04)
def _(s):
    s.tri.put(0, 0.14, N("A2"), N("A0"), gcurve=0.6)
    s.noi.put(0, 0.12, 11, 13, venv=[15, 14, 12, 10, 8, 6, 5], glide="lin")
    for i, t in enumerate([0.12, 0.19, 0.25, 0.31]):
        s.noi.put(t, 0.05, 6 + i, venv=[7 - i, 4 - i // 2, 1])
    s.p1.put(0, 0.04, N("D3"), N("A2"), venv=[12, 6, 2], duty=50)


@sfx("loose_ceiling_crack", 0.2, "traps", "Loose ceiling chunk breaks loose (0.4 s before it falls)")
def _(s):
    s.noi.put(0, 0.03, 1, venv=[15, 9], short=True)
    s.noi.put(0.03, 0.14, 5, 9, venv=[11, 9, 7, 6, 4, 3, 2, 1], glide="lin")
    s.p1.put(0, 0.06, N("A6"), N("D6"), venv=[11, 8, 5, 2], duty=12)
    s.p2.put(0.06, 0.12, N("D4"), N("C#4"), arp=[0, 1], arp_ticks=1, venv=[6, 5, 4, 3, 2, 1],
             duty=12)


@sfx("loose_ceiling_fall", 0.3, "traps", "Ceiling chunk falls (plays while dropping)", trim_db=-3.0,
     fade=0.04)
def _(s):
    s.p1.put(0, 0.28, N("D6"), N("D4"), venv=[9, 9, 8, 8, 7, 6, 5, 4, 3, 2, 1], duty=12)
    s.noi.put(0, 0.28, 4, 8, venv=[6, 6, 5, 5, 4, 3, 2, 1], glide="lin")


@sfx("loose_ceiling_land", 0.3, "traps", "Ceiling chunk hits the ground", fade=0.03)
def _(s):
    s.tri.put(0, 0.1, N("E3"), N("A1"), gcurve=0.6)
    s.noi.put(0, 0.26, 8, 12, venv=[15, 12, 9, 7, 5, 4, 3, 2, 1], glide="lin")
    s.p1.put(0, 0.03, N("A3"), venv=[11, 5], duty=50)


@sfx("press_shake", 0.32, "traps", "Press shakes for 0.3 s as its warning before a slam",
     trim_db=-2.0)
def _(s):
    s.p1.put(0, 0.3, N("D3"), arp=[0, 1], arp_ticks=1, venv=[5, 7, 8, 9, 10, 10, 11, 11, 11, 11, 11,
                                                             11, 11, 11, 11, 11, 11, 11, 6],
             duty=50)
    for i in range(7):
        s.noi.put(i * 0.045, 0.03, 8, venv=[6 + i // 2, 3, 1])
    s.tri.put(0, 0.3, N("D2"), arp=[0, 1], arp_ticks=2)


@sfx("press_slam", 0.48, "traps", "Press hits the floor", fade=0.05)
def _(s):
    s.tri.put(0, 0.18, N("D3"), N("D0"), gcurve=0.5)
    s.noi.put(0, 0.45, 12, 15, venv=[15, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 3, 2, 2, 1,
                                     1, 1, 1, 1, 1, 1, 1, 1, 0], glide="lin")
    s.noi.put(0, 0.02, 3, venv=[15])
    s.p1.put(0, 0.08, N("A2"), N("D2"), venv=[15, 12, 8, 4, 2], duty=50)
    s.p2.put(0.0, 0.2, N("D5"), venv=[7, 6, 5, 4, 3, 2, 2, 1, 1], duty=12, arp=[0, 6],
             arp_ticks=1)  # metal ring


@sfx("spike_warn", 0.26, "traps", "Spike vent about to fire (short tell before the spikes rise)",
     trim_db=-3.0)
def _(s):
    s.noi.put(0, 0.24, 6, venv=[2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 11, 11, 11, 11, 0], short=True)
    s.p1.put(0, 0.24, N("D5"), N("A5"), venv=[2, 3, 3, 4, 5, 5, 6, 7, 7, 8, 8, 8, 8, 8, 0], duty=12)


@sfx("spike_pop", 0.14, "traps", "Spikes spring up from a vent")
def _(s):
    s.p1.put(0, 0.05, N("D6"), N("D8"), venv=[15, 13, 10], duty=12, gcurve=0.5)
    s.noi.put(0, 0.1, 0, 3, venv=[15, 12, 8, 5, 3, 1], glide="lin")
    s.p2.put(0.03, 0.1, N("A7"), venv=[8, 6, 4, 2, 1], duty=25)


@sfx("dropper_tell", 0.18, "traps", "Dropper lets go (player passed underneath)", trim_db=-1.0)
def _(s):
    s.noi.put(0, 0.025, 2, venv=[14, 6], short=True)
    s.p1.put(0, 0.03, N("A4"), venv=[12, 6], duty=50)
    s.p1.put(0.05, 0.12, N("A4"), N("D3"), venv=[10, 9, 7, 5, 3, 1], duty=12)
    s.tri.put(0.05, 0.1, N("A3"), N("D2"))


@sfx("dropper_slam", 0.4, "traps", "Dropper hits the ground", fade=0.04)
def _(s):
    s.tri.put(0, 0.14, N("A3"), N("A0"), gcurve=0.5)
    s.noi.put(0, 0.36, 10, 14, venv=[15, 14, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 2, 1, 1, 1, 1, 0],
              glide="lin")
    s.p1.put(0, 0.06, N("D3"), N("A2"), venv=[14, 10, 5, 2], duty=50)
    s.p2.put(0.0, 0.3, N("A5"), venv=[8, 7, 6, 5, 4, 3, 2, 2, 1, 1, 1], duty=12, arp=[0, 5],
             arp_ticks=1)


@sfx("dropper_rise", 1.25, "traps", "Dropper winds back up to the ceiling (retrigger if longer)",
     trim_db=-4.0, fade=0.04)
def _(s):
    t, i = 0.0, 0
    while t < 1.2:
        f = st(N("D3"), i * 0.6)
        s.noi.put(t, 0.03, 6, venv=[9, 4, 1], short=(i % 2 == 1))
        s.p1.put(t, 0.05, f, venv=[8, 6, 3], duty=12)
        s.tri.put(t, 0.03, st(f, -12))
        t += 0.085
        i += 1


@sfx("plate_click", 0.1, "traps", "Pressure plate pressed down", trim_db=-2.0)
def _(s):
    s.noi.put(0, 0.02, 1, venv=[15, 6])
    s.p1.put(0, 0.03, N("D4"), venv=[12, 6], duty=50)
    s.p1.put(0.045, 0.05, N("A4"), venv=[10, 6, 2], duty=25)
    s.tri.put(0, 0.04, N("D3"), N("A2"))


@sfx("gate_open", 0.62, "traps", "Gate slides open", fade=0.04)
def _(s):
    t, i = 0.0, 0
    while t < 0.5:
        s.p1.put(t, 0.045, st(N("D3"), i * 1.0), venv=[10, 8, 4], duty=50)
        s.noi.put(t, 0.035, 9, venv=[8, 4, 1])
        t += 0.05
        i += 1
    s.tri.put(0, 0.5, N("D2"), N("D3"))
    s.noi.put(0.5, 0.1, 5, 9, venv=[14, 9, 5, 2, 1], glide="lin")
    s.p2.put(0.5, 0.1, N("A5"), venv=[10, 7, 4, 2, 1], duty=12)


@sfx("gate_close", 0.5, "traps", "Gate slides shut (timed gates closing too)", fade=0.04)
def _(s):
    t, i = 0.0, 0
    while t < 0.3:
        s.p1.put(t, 0.035, st(N("D4"), -i * 1.3), venv=[10, 8, 4], duty=50)
        s.noi.put(t, 0.03, 8, venv=[8, 4, 1])
        t += 0.04
        i += 1
    s.tri.put(0.3, 0.12, N("D3"), N("D1"))
    s.noi.put(0.3, 0.18, 10, 13, venv=[15, 12, 9, 6, 4, 2, 1], glide="lin")
    s.p2.put(0.3, 0.15, N("D5"), venv=[9, 7, 5, 3, 2, 1], duty=12, arp=[0, 6], arp_ticks=1)


@sfx("lever_pull", 0.32, "traps", "Player pulls the lever", fade=0.03)
def _(s):
    s.noi.put(0, 0.025, 1, venv=[13, 5], short=True)
    s.p1.put(0, 0.04, N("A4"), venv=[12, 7, 3], duty=50)
    s.noi.put(0.08, 0.025, 2, venv=[13, 5], short=True)
    s.p1.put(0.08, 0.04, N("D5"), venv=[12, 7, 3], duty=50)
    s.tri.put(0.16, 0.1, N("D3"), N("D2"))
    s.noi.put(0.16, 0.12, 8, 11, venv=[14, 10, 7, 4, 2, 1], glide="lin")
    s.p2.put(0.16, 0.14, N("A5"), venv=[8, 6, 4, 3, 2, 1], duty=12)


@sfx("bridge_collapse", 1.5, "traps", "Lever drops the bridge: planks give way one after another",
     fade=0.1)
def _(s):
    for i in range(8):
        t = i * 0.085
        s.noi.put(t, 0.06, 3 + i % 3, venv=[15 - i // 2, 9, 4, 1])
        s.p1.put(t, 0.05, st(N("A5"), -i * 2), st(N("A4"), -i * 2), venv=[11, 8, 4], duty=12)
    s.tri.put(0, 0.7, N("D3"), N("D1"), gcurve=0.8)
    s.noi.put(0.68, 0.8, 11, 15, venv=dec(14, 48, 0.6), glide="lin")
    s.p2.put(0.68, 0.3, N("D3"), N("D2"), venv=[10, 8, 6, 4, 3, 2, 1], duty=50)


@sfx("warden_step", 0.14, "enemies", "Warden footstep while pacing the bridge", trim_db=-4.0)
def _(s):
    s.tri.put(0, 0.07, N("D2"), N("A1"))
    s.noi.put(0, 0.1, 12, 14, venv=[13, 9, 5, 2, 1], glide="lin")
    s.p1.put(0, 0.025, N("D3"), venv=[9, 4], duty=50)


@sfx("warden_hop", 0.3, "enemies", "Warden jumps", trim_db=-2.0, fade=0.03)
def _(s):
    s.p1.put(0, 0.24, N("D3"), N("D4"), venv=[13, 12, 11, 10, 9, 7, 5, 3, 2, 1], duty=50,
             gcurve=0.5)
    s.tri.put(0, 0.18, N("A2"), N("A3"), gcurve=0.5)
    s.noi.put(0, 0.05, 11, venv=[12, 6, 2])


@sfx("warden_fall", 1.5, "enemies", "Warden falls when the bridge collapses (scream as it drops)",
     fade=0.1)
def _(s):
    s.p1.put(0, 1.45, N("A6"), N("D3"), vib=(9, 0.8), duty=12, gcurve=0.9, venv=dec(14, 86, 1.3))
    s.p2.put(0, 1.4, st(N("A6"), 0.4), st(N("D3"), 0.4), vib=(9, 0.8), duty=50, gcurve=0.9,
             venv=dec(6, 80, 1.3))
    s.noi.put(0, 0.12, 3, 6, venv=[10, 7, 4, 2], glide="lin")


@sfx("walker_squish", 0.16, "enemies", "Walker flattened by a stomp (play with stomp_N)",
     trim_db=-3.0)
def _(s):
    s.noi.put(0, 0.1, 9, 12, venv=[12, 9, 6, 3, 1], glide="lin")
    s.p1.put(0, 0.12, N("A3"), N("D2"), venv=[11, 9, 7, 5, 3, 1], duty=25, gcurve=0.6)


@sfx("hopper_hop", 0.14, "enemies", "Hopper jumps", trim_db=-4.0)
def _(s):
    s.p1.put(0, 0.11, N("A3"), N("A4"), venv=[11, 10, 8, 6, 4, 2], duty=25, gcurve=0.5)
    s.noi.put(0, 0.03, 10, venv=[8, 3])


@sfx("hopper_land", 0.1, "enemies", "Hopper lands (pairs with hopper_hop)", trim_db=-4.0)
def _(s):
    # hopper_hop turned over: the same 25% voice dropping a fourth and bouncing once,
    # so it reads as the hopper and not as the player's own soft landing
    s.p1.put(0, 0.04, N("D5"), N("A4"), venv=[12, 10, 7], duty=25)
    s.p1.put(0.045, 0.05, N("D5"), N("A4"), venv=[6, 4, 2, 1], duty=25)
    s.tri.put(0, 0.03, N("D3"), N("A2"))
    s.noi.put(0, 0.025, 9, venv=[8, 3])


# ---- World 2: the Switchyard (channel blocks, spiked walkers, the relay boss)

@sfx("channel_switch", 0.2, "blocks",
     "Player bumps a channel switch block: the solid and outline blocks swap", trim_db=-1.0,
     fade=0.02)
def _(s):
    # a relay armature: two crisp clacks a fifth apart, bright and dry, no thump under it
    # (the falling triangle thump is bump_block's)
    s.noi.put(0, 0.03, 0, 2, venv=[15, 8, 2], glide="lin", short=True)
    s.p1.put(0, 0.04, N("D6"), venv=[14, 11, 6], duty=12)
    s.tri.put(0, 0.025, N("D4"))
    s.noi.put(0.055, 0.03, 1, 3, venv=[14, 7, 2], glide="lin", short=True)
    s.p1.put(0.055, 0.13, N("A6"), venv=[14, 12, 9, 7, 5, 3, 2, 1], duty=12)
    s.tri.put(0.055, 0.025, N("A4"))
    s.echo(s.p1, s.p2, 0.02, 0.4, duty=25)


@sfx("channel_arm", 0.3, "boss",
     "Relay boss is about to swap the channels by itself: play when its 0.3 s warning starts, "
     "it ends as the swap lands (then channel_swap)", trim_db=-2.0, fade=0.006)
def _(s):
    # a relay coil buzzing up to strength: root and fifth flipped every tick, climbing an
    # octave, with the tick at the front so the warning is heard the moment it starts
    s.noi.put(0, 0.02, 1, venv=[12, 4], short=True)
    swell = [7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15]
    s.p1.put(0, 0.3, N("D4"), N("D5"), arp=[0, 7], arp_ticks=1, venv=swell, duty=25)
    s.p2.put(0, 0.3, N("D3"), N("D4"), arp=[0, 12], arp_ticks=2, venv=swell, level=0.45, duty=50)
    s.tri.put(0, 0.3, N("D3"), N("D4"))
    s.noi.put(0.02, 0.28, 9, 3, venv=[2, 3, 3, 4, 5, 5, 6, 7, 7, 8, 9, 9, 10, 10, 11, 11, 12],
              glide="lin", short=True)


@sfx("channel_swap", 0.28, "boss",
     "The relay boss swaps the channels: blocks change over (plays as channel_arm ends)",
     fade=0.03)
def _(s):
    # thunk: a short low drop
    s.tri.put(0, 0.08, N("D3"), N("D1"), gcurve=0.5)
    s.p1.put(0, 0.05, N("A2"), N("D2"), venv=[14, 10, 5], duty=50)
    s.noi.put(0, 0.02, 3, venv=[15])
    # static: chopped, jumping hiss that crackles out
    s.noi.put(0.02, 0.26, 1, venv=[12, 3, 10, 9, 2, 8, 3, 7, 6, 1, 5, 2, 4, 1, 3, 0],
              arp=[0, 3, 1, 4], arp_ticks=1)
    s.p2.put(0, 0.1, N("D5"), N("D6"), arp=[0, 13], arp_ticks=1, venv=[6, 5, 4, 3, 2, 1], duty=12)


@sfx("spiky_knock", 0.3, "enemies",
     "Spiked walker knocked out from below or crushed by a trap", trim_db=-1.0, fade=0.03)
def _(s):
    # walker_squish made heavier and metal: a clank on top, a real thump under it, and the
    # spikes jangling a semitone apart as it goes
    s.noi.put(0, 0.04, 2, 4, venv=[15, 10, 5], glide="lin", short=True)
    s.noi.put(0.04, 0.16, 9, 12, venv=[11, 8, 6, 4, 2, 1], glide="lin")
    s.tri.put(0, 0.12, N("A2"), N("D1"), gcurve=0.6)
    s.p1.put(0, 0.16, N("A3"), N("D2"), venv=[14, 12, 10, 8, 6, 4, 2, 1], duty=50, gcurve=0.6)
    s.p2.put(0.01, 0.26, N("E6"), venv=[9, 8, 7, 6, 5, 4, 3, 3, 2, 2, 1, 1], duty=12, arp=[0, 1],
             arp_ticks=1)


@sfx("spiky_hurt", 0.14, "player",
     "Player touches a spiked walker's spikes (the sting only: death or charge_lose plays "
     "as well)", trim_db=-1.0)
def _(s):
    # a double tritone sting on a metallic buzz ("tz-tzz"); no falling tail, so it does not
    # sound like the death or charge_lose it sits on top of
    for t, v in [(0.0, 15), (0.06, 13)]:
        s.noi.put(t, 0.045, 0, 2, venv=[v, v - 3, v - 8], glide="lin", short=True)
        s.p1.put(t, 0.05, N("G#5"), arp=[0, 6], arp_ticks=1, venv=[v, v - 2, v - 6], duty=50)
        s.p2.put(t, 0.04, N("D7"), venv=[v - 6, v - 9, 1], duty=12, arp=[0, 1], arp_ticks=1)


@sfx("fuse_blow", 0.55, "boss", "Player bumps a fuse socket and blows the fuse", fade=0.05)
def _(s):
    # pop
    s.noi.put(0, 0.03, 3, venv=[15, 12])
    s.tri.put(0, 0.05, N("A3"), N("A1"))
    s.p1.put(0, 0.05, N("D6"), N("D5"), venv=[15, 11, 6], duty=50)
    # fizz: bright hiss with a jittery, crackling envelope that burns down
    fizz = [11, 7, 10, 5, 9, 8, 4, 8, 6, 3, 7, 5, 2, 5, 4, 1, 4, 3, 1, 3, 2, 1, 2, 1, 1, 0]
    s.noi.put(0.04, 0.5, 0, venv=fizz, arp=[0, 1, 0, 2], arp_ticks=1)
    s.p2.put(0.04, 0.4, N("A7"), N("D7"), venv=[5, 4, 5, 3, 4, 2, 3, 2, 1, 2, 1, 1, 0], duty=12,
             arp=[0, 5], arp_ticks=1)


RELAY_LOOP = 1.5


@sfx("relay_hum", RELAY_LOOP, "boss",
     "Relay boss idle hum. LOOPS: play it with looping on (the file loops by itself in Godot "
     "and has no click at the seam)", trim_db=-5.0, loop=True)
def _(s):
    # Every pattern here repeats a whole number of times in 1.5 s, so the loop is seamless.
    frames = int(math.ceil(s.dur * 60)) + 2
    wobble = [3, 3, 4, 5, 6, 6, 6, 5, 4, 3, 3, 2, 2, 2, 2]          # 0.25 s, 6 per loop
    tile = lambda p: (p * (frames // len(p) + 1))[:frames]
    s.tri.put(0, s.dur, N("D2"))                                    # the body of the hum
    s.p1.put(0, s.dur, N("A2"), venv=tile(wobble), duty=12)         # reedy fifth, wobbling
    s.p2.put(0, s.dur, N("D3"), venv=tile([3, 3, 3, 3, 3, 2, 2, 2, 2, 2]), duty=25)
    s.noi.put(0, s.dur, 12, venv=tile([3, 3, 2, 2, 2]), short=True)  # low mains buzz


@sfx("relay_overload", 1.5, "boss",
     "All three fuses blown: the relay boss alarms and crashes (then relay_down)", fade=0.1)
def _(s):
    # alarm: root and tritone see-saw, climbing a fifth and speeding up for 1 s
    t, i = 0.0, 0
    while t < 1.0:
        step = 0.1 - 0.05 * t
        f = st(N("D5"), 7 * t + (6 if i % 2 else 0))
        s.p1.put(t, step * 0.9, f, venv=[13, 12, 12, 11], duty=50)
        s.p2.put(t, step * 0.9, st(f, -12), venv=[6, 6, 5, 5], duty=12)
        t += step
        i += 1
    s.tri.put(0, 1.0, N("D3"), N("A3"))
    s.noi.put(0, 1.0, 10, 2, venv=[2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9], glide="lin")
    # crash
    s.noi.put(1.0, 0.03, 1, venv=[15, 15], short=True)
    s.noi.put(1.03, 0.47, 3, 14, venv=dec(15, 28, 0.6), glide="lin")
    s.tri.put(1.0, 0.25, N("D3"), N("D0"), gcurve=0.5)
    s.p1.put(1.0, 0.18, N("A2"), N("D1"), venv=[15, 13, 11, 9, 7, 5, 4, 3, 2, 1], duty=50)
    s.p2.put(1.0, 0.4, N("A4"), venv=dec(9, 24), duty=12, arp=[0, 1], arp_ticks=1)


@sfx("relay_down", 1.0, "boss", "Relay boss powers down and dies (after relay_overload)",
     fade=0.1)
def _(s):
    # the hum winding down: a falling note whose flutter slows, and sputters that thin out
    total, f0, f1 = 0.95, N("A4"), N("D2")
    vol = dec(12, 57, 1.3)
    t = 0.0
    for dur, rate in [(0.2, 14), (0.2, 10), (0.2, 7), (0.2, 5), (0.15, 3)]:
        a, b = t / total, (t + dur) / total
        fa, fb = f0 * (f1 / f0) ** (a ** 0.7), f0 * (f1 / f0) ** (b ** 0.7)
        k0 = int(round(t * 60))
        s.p1.put(t, dur, fa, fb, venv=vol[k0:k0 + int(round(dur * 60)) + 1], duty=25,
                 vib=(rate, 0.6))
        t += dur
    s.tri.put(0, 0.8, N("D3"), N("D1"), gcurve=0.7)
    s.p2.put(0, 0.4, N("D4"), N("D3"), venv=dec(6, 24), duty=12, gcurve=0.7)
    for k, tt in enumerate([0.0, 0.1, 0.22, 0.36, 0.52, 0.7]):
        s.noi.put(tt, 0.04, 8 + k, venv=[10 - k, 5 - k // 2, 1], short=(k % 2 == 0))


# ---- ambience loops, weather, lamps and menus

def _curve(s: Sound, loop: float, keys: list[tuple[float, float]]) -> np.ndarray:
    """One value per control tick, following (time, value) keyframes that repeat every `loop`
    seconds. The last key should sit at t = loop with the same value as the first."""
    t = (np.arange(len(s.p1.vol)) / TICK_HZ) % loop
    kt, kv = zip(*keys)
    return np.interp(t, kt, kv)


def _loop_pattern(s: Sound, loop: float, seed: int, lo: int, hi: int, frame_ticks: int = FRAME
                  ) -> np.ndarray:
    """A fixed random pattern (lo..hi, changing every frame_ticks) that repeats every `loop`."""
    per = int(round(loop * TICK_HZ)) // frame_ticks
    pat = np.random.RandomState(seed).randint(lo, hi + 1, per).repeat(frame_ticks)
    reps = len(s.p1.vol) // len(pat) + 1
    return np.tile(pat, reps)[: len(s.p1.vol)].astype(float)


def _every_loop(s: Sound, loop: float, fn) -> None:
    """Call fn(offset) once per loop pass, so one-off events recur exactly every `loop`."""
    k = 0
    while k * loop < s.dur:
        fn(k * loop)
        k += 1


AMB_W1_LOOP = 8.0
AMB_W2_LOOP = 7.0


@sfx("amb_w1", AMB_W1_LOOP, "ambience",
     "World 1 ambience under the music: distant wind over dead wires, a faint signal blip. "
     "LOOPS (the file loops by itself in Godot, no click at the seam)", trim_db=-8.0, loop=True,
     power_seam=True)
def _(s):
    L = AMB_W1_LOOP
    # wind: long-mode noise, low and breathy, rising in two gusts per loop
    s.noi.freq[:] = np.round(_curve(s, L, [(0, 10), (1.2, 9), (2.0, 8), (2.8, 9), (3.9, 11),
                                           (4.8, 9), (5.6, 8), (6.3, 7), (7.1, 9), (L, 10)]))
    s.noi.vol[:] = np.round(_curve(s, L, [(0, 3), (1.2, 4), (2.0, 6), (2.8, 4), (3.9, 2),
                                          (4.8, 4), (5.6, 7), (6.3, 6), (7.1, 3), (L, 3)]))
    # dead wires: a thin 12.5% whistle that only sings when the gusts push it,
    # wavering 0.75 times a second (6 whole wavers per loop)
    wire = np.round(_curve(s, L, [(0, 0), (1.3, 0), (2.0, 2), (2.6, 1), (3.1, 0), (5.0, 0),
                                  (5.6, 2), (6.4, 2), (7.0, 1), (7.5, 0), (L, 0)]))
    tt = np.arange(len(wire)) / TICK_HZ
    s.p1.freq[:] = N("A5") * 2 ** (0.3 * np.sin(2 * math.pi * 0.75 * tt) / 12)
    s.p1.vol[:] = wire
    s.p1.duty[:] = DUTY[12]

    # the signal: one soft two-note blip, answered faintly, once per loop
    def blip(o):
        s.p2.put(o + 3.3, 0.05, N("A5"), venv=[4, 4, 3, 1], duty=25)
        s.p2.put(o + 3.36, 0.09, N("D6"), venv=[4, 4, 3, 3, 2, 1], duty=25)
        s.p2.put(o + 3.62, 0.05, N("A5"), venv=[2, 2, 1], duty=25)
        s.p2.put(o + 3.68, 0.09, N("D6"), venv=[2, 2, 1, 1, 1], duty=25)
    _every_loop(s, L, blip)


@sfx("amb_w2", AMB_W2_LOOP, "ambience",
     "World 2 (relay yard) ambience under the music: transformer hum, far-off metal clanks, "
     "rain. LOOPS (the file loops by itself in Godot, no click at the seam)", trim_db=-8.0,
     loop=True)
def _(s):
    L = AMB_W2_LOOP
    # transformer hum: a 50% pulse on A2 breathing between two volume steps twice a loop,
    # with a faint 12.5% buzz an octave up (a different pitch and colour from relay_hum)
    s.p2.freq[:] = N("A2")
    s.p2.vol[:] = np.round(_curve(s, L, [(0, 3), (1.75, 4), (3.5, 3), (5.25, 4), (L, 3)]))
    s.p2.duty[:] = DUTY[50]
    s.p1.freq[:] = N("A3")
    s.p1.vol[:] = 1
    s.p1.duty[:] = DUTY[12]
    # rain: high long-mode hiss, pitch and volume pattering every frame
    s.noi.freq[:] = _loop_pattern(s, L, 21, 1, 2)
    s.noi.vol[:] = _loop_pattern(s, L, 22, 3, 5)

    # far-off clanks: a metal tick on the noise (it briefly cuts the rain, as on the chip)
    # and a dull ringing pulse, each answered by an echo off the yard
    def clank(o, t, note, v):
        s.noi.put(o + t, 0.02, 4, venv=[v, v // 2], short=True)
        ring = [v, v - 1, v - 2, v - 3, v - 3, v - 4, v - 4, v - 5, v - 5]
        s.p1.put(o + t, 0.16, N(note), arp=[0, 6], arp_ticks=1, duty=25,
                 venv=[max(x, 1) for x in ring] + [0])
        s.p1.put(o + t + 0.2, 0.1, N(note), arp=[0, 6], arp_ticks=1, duty=25,
                 venv=[max(v - 5, 1), max(v - 6, 1), 1, 0])

    def clanks(o):
        clank(o, 1.4, "E4", 6)
        clank(o, 4.55, "C#4", 5)
        clank(o, 4.75, "G#3", 4)
    _every_loop(s, L, clanks)


@sfx("lamp_on", 0.36, "level", "A signal lamp sputters on", trim_db=-1.0, fade=0.03)
def _(s):
    # the filament catches on the third try: crackles, then a warm 50% pulse climbing
    # D4 to D5 that flickers before it holds, with the triangle underneath once it's lit
    for t, v, p in [(0.0, 11, 5), (0.045, 7, 6), (0.085, 12, 4), (0.13, 6, 6)]:
        s.noi.put(t, 0.02, p, venv=[v, v // 3])
    flick = [10, 0, 0, 8, 2, 0, 11, 4, 12, 12, 12, 12, 12, 11, 11, 10, 9, 8, 7, 6, 5, 3, 2, 1, 0]
    s.p1.put(0, 0.36, N("D4"), N("D5"), venv=flick, duty=50, gcurve=0.6, vib=(8, 0.08))
    s.p2.put(0.1, 0.26, N("A4"), N("A5"), venv=[5, 6, 6, 6, 6, 5, 5, 4, 4, 3, 3, 2, 1, 0], duty=25,
             gcurve=0.6)
    s.tri.put(0.1, 0.2, N("D3"), N("D4"), gcurve=0.6)


@sfx("thunder", 1.2, "level", "Lightning strikes: a crack, then a rolling rumble", fade=0.12)
def _(s):
    # crack: the brightest hiss, flickering like the flash, with a falling zap on top
    s.noi.put(0, 0.075, 0, 3, venv=[15, 15, 9, 14, 7, 12], glide="lin", arp=[0, 2], arp_ticks=1)
    s.p1.put(0, 0.06, N("D8"), N("D5"), venv=[12, 9, 5, 2], duty=12, gcurve=0.5)
    s.tri.put(0.03, 0.1, N("D2"), N("D1"), gcurve=0.6)
    # rumble: low noise rolling in slowing swells and sinking as it goes away
    k = int(round(1.125 * 60))
    tt = np.arange(k) / 60
    roll = 1 + 0.4 * np.sin(2 * math.pi * (4.0 * tt - 1.0 * tt ** 2))
    body = np.array(dec(13, k, 1.3)[:k], dtype=float)
    s.noi.put(0.075, 1.125, 10, 15, venv=list(np.clip(np.round(body * roll), 0, 15)) + [0],
              glide="lin", arp=[0, 1], arp_ticks=2)


@sfx("menu_back", 0.12, "ui", "Menu back or cancel (pairs with menu_move and menu_confirm)",
     trim_db=-3.0, fade=0.015)
def _(s):
    # menu_confirm turned over: down a fifth instead of up, an octave lower and shorter
    s.p1.put(0, 0.035, N("A5"), venv=[12, 11], duty=25)
    s.p1.put(0.04, 0.075, N("D5"), venv=[12, 10, 7, 4, 2], duty=25)
    s.echo(s.p1, s.p2, 0.02, 0.4, duty=12)


@sfx("save_done", 0.32, "ui", "Game saved: a short two-note chime", trim_db=-2.0, fade=0.03)
def _(s):
    # F#6 then D7 (mi up to do): clear 50% bells with a light mallet of triangle under each
    s.p1.put(0, 0.08, N("F#6"), venv=[13, 11, 9, 8, 7], duty=50)
    s.p1.put(0.08, 0.24, N("D7"), venv=[14, 12, 10, 9, 8, 7, 6, 5, 4, 4, 3, 3, 2, 2, 1, 1],
             duty=50)
    s.tri.put(0, 0.04, N("F#5"))
    s.tri.put(0.08, 0.04, N("D6"))
    s.echo(s.p1, s.p2, 0.04, 0.35, duty=12)


# ---- Last Relay, the hub village: NPC voices, talking, doors, the shop, village loops

# Voices. The game plays one blip every two letters and nudges its pitch a little each time,
# so each blip is short and has no tail. Every speaker differs in three ways at once: the
# waveform, the register (roughly a fifth to an octave apart: hum A2, mast F#3, brace D4,
# dot D5, tally A5, wren E6) and the shape of the blip (sag, flat, chirp, click, buzz).

@sfx("voice_mast", 0.05, "voices", "Mast (old keeper) speaks: one blip every two letters",
     trim_db=1.0, fade=0.006)
def _(s):
    # the triangle alone, round and soft, sagging a tone like an old man's "mm"
    s.tri.put(0, 0.05, N("F#3"), N("E3"), gcurve=0.8)


@sfx("voice_tally", 0.04, "voices", "Tally (trader) speaks: one blip every two letters",
     trim_db=-9.0, fade=0.006)
def _(s):
    # thin 12.5% pulse, hard attack and gone: quick trader's patter
    s.p1.put(0, 0.035, N("A5"), venv=[14, 10, 5], duty=12)


@sfx("voice_wren", 0.05, "voices", "Wren (kid with headphones) speaks: one blip every two letters",
     trim_db=-9.5, fade=0.006)
def _(s):
    # a high 25% chirp that flicks up a fifth, with a faint tinny octave above it (the
    # headphones leaking)
    s.p1.put(0, 0.045, N("E6"), N("B6"), venv=[11, 12, 7, 2], duty=25, gcurve=0.5)
    s.p2.put(0.004, 0.04, N("E7"), N("B7"), venv=[3, 3, 2, 1], duty=12, gcurve=0.5)


@sfx("voice_brace", 0.05, "voices", "Brace (lineworker) speaks: one blip every two letters",
     trim_db=-6.0, fade=0.006)
def _(s):
    # mid 25% pulse that drops a third, gruff, with a little low hiss riding under it
    s.p1.put(0, 0.045, N("D4"), N("B3"), venv=[13, 12, 8, 3], duty=25, gcurve=1.4)
    s.noi.put(0, 0.045, 7, venv=[5, 4, 3, 1])


@sfx("voice_dot", 0.04, "voices", "Dot (switch operator, lamp head) speaks: one blip every two "
     "letters", trim_db=-7.0, fade=0.004)
def _(s):
    # a relay click on metallic noise, then a clipped 50% pip that stops dead
    s.noi.put(0, 0.008, 1, venv=[13], short=True)
    s.p1.put(0.004, 0.03, N("D5"), venv=[13, 11], duty=50)


@sfx("voice_hum", 0.055, "voices", "Hum (relay technician) speaks: one blip every two letters",
     trim_db=-1.0, fade=0.006)
def _(s):
    # a low 50% pulse fluttering a semitone every tick, which makes it buzz like a coil
    s.p1.put(0, 0.05, N("A2"), arp=[0, 1], arp_ticks=1, venv=[11, 12, 11, 7], duty=50)


@sfx("talk_open", 0.12, "ui", "A speech bubble opens", trim_db=-4.0, fade=0.015)
def _(s):
    # two soft ticks up a fourth (A5 then D6) on a quiet 50% pulse, with a faint echo
    s.p1.put(0, 0.03, N("A5"), venv=[9, 5, 2], duty=50)
    s.p1.put(0.045, 0.065, N("D6"), venv=[10, 7, 4, 2, 1], duty=50)
    s.echo(s.p1, s.p2, 0.02, 0.35, duty=25)


@sfx("talk_next", 0.035, "ui", "Player advances to the next line of speech", trim_db=-6.0,
     fade=0.006)
def _(s):
    # one tiny tick: the second note of talk_open, cut short
    s.p1.put(0, 0.025, N("D6"), venv=[10, 4], duty=50)


@sfx("door_open", 0.46, "village", "A small house door opens (latch, then the creak)",
     trim_db=-2.0, fade=0.04)
def _(s):
    # the latch lifts: a metal click and a small knock
    s.noi.put(0, 0.02, 1, venv=[13, 5], short=True)
    s.p1.put(0, 0.03, N("A4"), venv=[11, 5], duty=50)
    # the creak: metallic noise sliding up in pitch, its volume catching and slipping every
    # frame like a dry hinge, with a thin whine a semitone apart under it
    creak = [5, 2, 7, 3, 8, 2, 7, 4, 8, 3, 7, 2, 6, 3, 6, 2, 5, 2, 4, 1, 3, 1, 0]
    s.noi.put(0.05, 0.38, 9, 5, venv=creak, glide="lin", short=True, arp=[0, 1, 0, 0, 1],
              arp_ticks=1)
    s.p2.put(0.05, 0.36, N("E4"), N("A4"), venv=[1, 2, 2, 3, 2, 3, 2, 2, 1, 2, 1, 1, 0],
             duty=12, arp=[0, 1], arp_ticks=1)


@sfx("door_close", 0.16, "village", "A small house door shuts (the latch drops)", trim_db=-2.0,
     fade=0.02)
def _(s):
    # the door meets the frame (a dull knock), then the latch drops into place: clack-clk
    s.tri.put(0, 0.05, N("D3"), N("A2"))
    s.noi.put(0, 0.05, 10, 12, venv=[11, 6, 2], glide="lin")
    s.noi.put(0.06, 0.02, 1, venv=[13, 4], short=True)
    s.p1.put(0.06, 0.04, N("E5"), venv=[10, 5, 2], duty=12)
    s.noi.put(0.1, 0.015, 2, venv=[7, 2], short=True)


@sfx("shop_buy", 0.44, "village", "Player buys something in the shop", trim_db=-1.0, fade=0.04)
def _(s):
    # the till ticks, then a quick run up the D major chord that lands on a ringing D7
    s.noi.put(0, 0.02, 0, venv=[10, 4], short=True)
    for i, n in enumerate(["D6", "F#6", "A6"]):
        s.p1.put(i * 0.035, 0.035, N(n), venv=[13, 12, 11], duty=25)
    s.p1.put(0.105, 0.32, N("D7"), venv=[14, 13, 11, 9, 8, 7, 6, 5, 4, 3, 3, 2, 2, 1, 1],
             duty=50, vib=(6, 0.1))
    s.echo(s.p1, s.p2, 0.035, 0.4, duty=12)
    s.tri.put(0.105, 0.05, N("A4"))


@sfx("shop_deny", 0.3, "village", "Player can't afford it (not enough shards)", trim_db=0.0,
     fade=0.02)
def _(s):
    # "uh-uh": two low buzzes, the second a semitone lower. A 50% pulse flutters against a
    # 25% one a semitone above it, over the triangle an octave down
    for t, root in [(0.0, N("D3")), (0.15, N("C#3"))]:
        s.p1.put(t, 0.11, root, venv=[13, 13, 12, 11, 8, 0], duty=50, arp=[0, 1], arp_ticks=1)
        s.p2.put(t, 0.11, st(root, 1), venv=[7, 7, 6, 5, 3, 0], duty=25)
        s.tri.put(t, 0.09, st(root, -12))


AMB_VILLAGE_LOOP = 8.0


@sfx("amb_village", AMB_VILLAGE_LOOP, "ambience",
     "Last Relay village ambience under the music: soft wind, a distant wind chime, a far-off "
     "radio murmuring. LOOPS (the file loops by itself in Godot, no click at the seam)",
     trim_db=-8.0, loop=True, lock=True)
def _(s):
    L = AMB_VILLAGE_LOOP
    # wind: low long-mode hiss, softer than World 1's, swelling twice a pass
    s.noi.freq[:] = np.round(_curve(s, L, [(0, 10), (1.4, 10), (2.3, 9), (3.3, 10), (4.4, 11),
                                           (5.6, 9), (6.6, 10), (L, 10)]))
    s.noi.vol[:] = np.round(_curve(s, L, [(0, 2), (1.3, 3), (2.3, 4), (3.3, 3), (4.4, 2),
                                          (5.6, 4), (6.6, 3), (L, 2)]))

    # far-off radio: a voice murmuring on the same noise voice. Short mode buzzes at a
    # speaking pitch. While a syllable sounds it takes the noise from the wind, as on the chip.
    def murmur(o):
        for t0, words in [(0.75, [(0.0, 0.09, 6), (0.12, 0.13, 7), (0.29, 0.1, 6)]),
                          (3.9, [(0.0, 0.1, 6), (0.13, 0.07, 7), (0.23, 0.14, 6), (0.41, 0.07, 5),
                                 (0.51, 0.12, 7), (0.69, 0.09, 6), (0.82, 0.16, 7)])]:
            for t, d, p in words:
                s.noi.put(o + t0 + t, d, p, venv=[1, 2, 2, 2, 1], short=True)

    # the chime: a handful of distant 25% bells from the D major pentatonic, struck as the
    # wind swells, alternating between the two pulses so each one rings on under the next
    def chime(o):
        for i, (t, n) in enumerate([(1.9, "A6"), (2.15, "D7"), (2.33, "F#6"), (2.7, "B6"),
                                    (5.25, "E7"), (5.5, "A6"), (5.95, "D7")]):
            v = s.p1 if i % 2 == 0 else s.p2
            v.put(o + t, 0.8, N(n), venv=dec(4, 48, 0.5), duty=25)

    _every_loop(s, L, murmur)
    _every_loop(s, L, chime)


# The village theme. Written as note text (see _tune) for the four voices, one pass per loop.

def _tune(text: str) -> list[tuple[str | None, float]]:
    """Note text to (note, beats) pairs for Sound.seq. 'F#5:1.5' is a note and its length in
    beats, '-:1' is a rest, and '|' bar lines are checked: every bar must hold 4 beats."""
    out: list[tuple[str | None, float]] = []
    for i, bar in enumerate(text.split("|")):
        notes = [tok.split(":") for tok in bar.split()]
        beats = sum(float(b) for _, b in notes)
        if notes and abs(beats - 4) > 1e-9:
            raise ValueError(f"_tune: bar {i + 1} holds {beats} beats, not 4")
        out += [(None if n == "-" else n, float(b)) for n, b in notes]
    return out


VILLAGE_BPM = 100
VILLAGE_BARS = 16
VILLAGE_LOOP = VILLAGE_BARS * 4 * 60 / VILLAGE_BPM          # 38.4 s

# chord per bar ("G+A" is half a bar each), with the bass (root, fifth) and the three
# notes of the broken chord on pulse 2
VILLAGE_CHORDS = "D Bm G A  D Bm G+A D  G A F#m Bm  G A D A".split()
VILLAGE_BASS = {"D": ("D3", "A2"), "Bm": ("B2", "F#2"), "G": ("G2", "D3"), "A": ("A2", "E2"),
                "F#m": ("F#2", "C#3")}
VILLAGE_ARP = {"D": ("D4", "F#4", "A4"), "Bm": ("B3", "D4", "F#4"), "G": ("G3", "B3", "D4"),
               "A": ("A3", "C#4", "E4"), "F#m": ("F#3", "A3", "C#4")}
VILLAGE_MELODY = """
A4:.5 D5:.5 F#5:1.5 E5:.5 D5:1 | B4:.5 D5:.5 F#5:1 E5:1 D5:1 |
B4:.5 D5:.5 G5:1.5 F#5:.5 E5:1 | E5:1.5 F#5:.5 E5:1 -:1 |
A4:.5 D5:.5 F#5:1.5 E5:.5 D5:1 | B4:.5 D5:.5 F#5:1 A5:1 F#5:1 |
G5:1 F#5:.5 E5:.5 E5:1 C#5:1 | D5:3 -:1 |
B5:1.5 A5:.5 G5:1 D5:1 | A5:1.5 G5:.5 F#5:1 E5:1 |
F#5:1.5 E5:.5 C#5:1 A4:1 | B4:1 D5:1 F#5:2 |
G5:1.5 F#5:.5 E5:1 D5:1 | E5:1 F#5:.5 G5:.5 A5:2 |
F#5:1.5 E5:.5 D5:2 | E5:1.5 D5:.5 C#5:1 -:1
"""


@sfx("village_theme", VILLAGE_LOOP, "music",
     "Last Relay village theme, on the Music bus. Calm D major, all four voices, 16 bars at "
     "100 BPM. LOOPS (the file loops by itself in Godot, no click at the seam)",
     trim_db=3.0, loop=True, lock=True)
def _(s):
    bpm, beat = VILLAGE_BPM, 60 / VILLAGE_BPM
    melody = _tune(VILLAGE_MELODY)
    bass: list[tuple[str | None, float]] = []
    arps: list[tuple[int, list[tuple[str | None, float]]]] = []    # (bar, eighth notes)
    for bar, chord in enumerate(VILLAGE_CHORDS):
        halves = chord.split("+")
        for h in halves:
            root, fifth = VILLAGE_BASS[h]
            if len(halves) == 2:
                bass += [(root, 1.5), (fifth, 0.5)]
            elif bar == VILLAGE_BARS - 1:          # last bar walks up into the top of the loop
                bass += [(root, 1.5), (fifth, 0.5), (root, 1), ("C#3", 1)]
            else:
                bass += [(root, 1.5), (fifth, 0.5), (root, 1), (fifth, 1)]
            lo, mid, hi = VILLAGE_ARP[h]
            arps.append((bar, [(n, 0.5) for n in [lo, hi, mid, hi] * (2 // len(halves))]))
    lead_env = [8, 10, 11, 11, 10, 10, 10, 9, 9, 9, 9, 8, 8, 8, 8, 7, 7, 7, 7, 6, 6, 6, 6, 5]

    def one_pass(o):
        s.seq(s.p1, o, bpm, melody, duty=50, venv=lead_env, gate=0.95, vib=(5, 0.1))
        s.seq(s.tri, o, bpm, bass, gate=0.85)
        t = o
        for bar, notes in arps:
            # the middle eight (bars 9 to 12) thins the chords to 12.5% for a change of colour
            duty = 12 if 8 <= bar <= 11 else 25
            t = s.seq(s.p2, t, bpm, notes, duty=duty, venv=[6, 5, 4, 4, 3, 3], gate=0.9)
        for i in range(VILLAGE_BARS * 8):          # every eighth note
            t, on_beat, b = o + i * beat / 2, i % 2 == 0, (i // 2) % 4
            if on_beat and b == 0:
                s.noi.put(t, 0.1, 12, venv=[7, 5, 3, 1])          # soft low thud
            elif on_beat and b in (1, 3):
                s.noi.put(t, 0.1, 4, venv=[4, 3, 2, 1])           # brush
            else:
                s.noi.put(t, 0.03, 0 if not on_beat else 1, venv=[2, 1])   # shaker tick

    _every_loop(s, VILLAGE_LOOP, one_pass)


# ---- level music: one loop per level, written as note text like the village theme.
#
# World 1 tracks all quote the opening of the FIRST LIGHT theme (m_1_1): scale steps
# 5 1 1 2 3 1 in the rhythm short short short short long long (in G: D G G A B G).
# World 2 tracks all share the Switchyard motif: 5 b6 5 8 b7 5 in the rhythm
# short short short long short long (in A minor: E F E A G E).
# Every tempo is 3600 / n BPM for a whole number n, so a sixteenth note lasts exactly n
# control ticks and every note starts on a tick, the same way in every pass.

_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def _midi(name: str) -> int:
    return int(round(69 + 12 * math.log2(N(name) / 440)))


def _note(m: int) -> str:
    return f"{_NAMES[m % 12]}{m // 12 - 1}"


def _tone(chord: str, tok: str, lo: int) -> str:
    """One chord-relative token to a note name. The root is the lowest one at or above lo."""
    if tok[0] in "ABCDEFG":
        return tok
    down = tok.startswith("_")
    tok = tok.lstrip("_")
    i = 2 if chord[1:2] in ("#", "b") else 1
    root, kind = chord[:i], chord[i:]
    r = lo + (_midi(root + "4") - lo) % 12
    third = 3 if kind in ("m", "dim") else 4
    semis = {"R": 0, "3": third, "5": 6 if kind == "dim" else 7, "7": 10, "8": 12,
             "10": 12 + third, "12": 19}[tok]
    return _note(r + semis - (12 if down else 0))


def _comp(chords: str, pattern: str | list[str], base: str) -> list[tuple[str | None, float]]:
    """A part that follows the chords. pattern is one bar of tokens, used for every bar, or a
    list with one bar per chord. Tokens: R 3 5 7 8 10 12 are the root, third, fifth, flat
    seventh, octave, and the third and fifth an octave up. '_' in front drops a tone an
    octave, '-' is a rest, a plain note name plays as written. Each token takes the chord
    sounding when it starts ('G+D' is half a bar of each). Roots sit at or above `base`."""
    bars = chords.split()
    pats = pattern if isinstance(pattern, list) else [pattern] * len(bars)
    if len(pats) != len(bars):
        raise ValueError(f"_comp: {len(bars)} chords but {len(pats)} bar patterns")
    lo = _midi(base)
    out: list[tuple[str | None, float]] = []
    for sym, pat in zip(bars, pats):
        halves = sym.split("+")
        t = 0.0
        for tok, beats in _tune(pat):
            if tok is not None:
                tok = _tone(halves[min(int(t * len(halves) // 4), len(halves) - 1)], tok, lo)
            out.append((tok, beats))
            t += beats
    return out


def _part(s: Sound, voice: Voice, o: float, bpm: float, notes: list, bars: int,
          **kw) -> float:
    """Sound.seq, after checking the part fills exactly `bars` bars."""
    beats = sum(b for _, b in notes)
    if abs(beats - 4 * bars) > 1e-9:
        raise ValueError(f"_part: {beats} beats where {bars} bars ({4 * bars} beats) were due")
    return s.seq(voice, o, bpm, notes, **kw)


def _bar_index(notes: list, bar: int) -> int:
    """Index of the first note at or after the start of `bar` (0-based) in a (note, beats) list."""
    t = 0.0
    for i, (_, b) in enumerate(notes):
        if t >= 4 * bar - 1e-9:
            return i
        t += b
    return len(notes)


# The drum kit on the noise voice: pitch setting (0 highest .. 15 lowest), 60 Hz frame
# volumes, and short (metallic) mode.
KIT = {
    "k": (13, [10, 8, 5, 3, 1], False),                 # kick: a low thud
    "K": (14, [13, 11, 8, 6, 4, 2, 1], False),          # heavy thud (the presses)
    "s": (6, [11, 9, 7, 6, 5, 4, 3, 2, 1], False),      # snare
    "h": (0, [5, 3, 1], False),                         # closed hat
    "m": (5, [7, 5, 3, 2, 1], True),                    # metal clank
    "r": (11, [6, 4, 3, 1], False),                     # crumbling rubble
    "x": (3, [4, 1, 3, 1], True),                       # static crackle
    "z": (1, [9, 7, 8, 6, 7, 5, 4, 3, 2, 1], False),    # burst of static (a channel flip)
    "c": (2, dec(10, 45, 0.6), False),                  # crash, lightning
    "t": (12, dec(7, 60, 0.7), False),                  # far thunder
}


def _drums(s: Sound, o: float, bpm: float, bars: list[str], level: float = 1.0) -> None:
    """One character per sixteenth note, 16 to a bar, '.' for nothing (see KIT)."""
    step = 15 / bpm
    for b, pat in enumerate(bars):
        if len(pat) != 16:
            raise ValueError(f"_drums: bar {b + 1} has {len(pat)} steps, not 16")
        for i, ch in enumerate(pat):
            if ch != ".":
                p, env, short = KIT[ch]
                s.noi.put(o + (b * 16 + i) * step, len(env) * FRAME / TICK_HZ, p, venv=env,
                          level=level, short=short)


def _hiss(s: Sound, o: float, length: float, seed: int, vols: tuple, pitches: tuple) -> None:
    """Fill the noise voice's silent ticks in one pass with faint fixed-random hiss (rain), or
    with the odd pop of static when most of `vols` is 0. Drums keep the noise when they play."""
    a, n = int(round(o * TICK_HZ)), int(round(length * TICK_HZ))
    b = min(a + n, len(s.noi.vol))
    if b <= a:
        return
    rs = np.random.RandomState(seed)
    frames = n // FRAME + 1
    vol = rs.choice(vols, frames).repeat(FRAME)[: b - a]
    pit = rs.choice(pitches, frames).repeat(FRAME)[: b - a]
    sl = slice(a, b)
    m = s.noi.vol[sl] == 0
    s.noi.freq[sl] = np.where(m, pit, s.noi.freq[sl])
    s.noi.vol[sl] = np.where(m, vol, s.noi.vol[sl])
    s.noi.short[sl] = np.where(m, False, s.noi.short[sl])


def _bpm(n: int) -> float:
    return 3600 / n


def _loop_len(bars: int, n: int) -> float:
    return bars * 16 * n / TICK_HZ


LEAD_ENV = [10, 10, 10, 10, 9, 9, 9, 9, 8, 8, 8, 8, 8, 8, 7]
STAB_ENV = [7, 6, 4, 2]
ARP_ENV = [5, 4, 3, 2]


# ---- m_training: the training yard. C major, 120 BPM, 16 bars.

TRAIN_N, TRAIN_BARS = 30, 16
TRAIN_LOOP = _loop_len(TRAIN_BARS, TRAIN_N)                  # 32.0 s
TRAIN_CHORDS = "C Am F G  C Am Dm G  F G Em Am  Dm G C G"
TRAIN_MELODY = """
G4:.5 C5:.5 C5:.5 D5:.5 E5:1 C5:1 | E5:.5 -:.25 E5:.25 D5:.5 C5:.5 A4:1 -:1 |
A4:.5 C5:.5 F5:.5 A5:.5 G5:.5 F5:.5 E5:.5 D5:.5 | D5:1 B4:.5 G4:.5 -:2 |
G4:.5 C5:.5 C5:.5 D5:.5 E5:1 G5:1 | A5:.5 G5:.5 E5:.5 C5:.5 D5:.5 E5:.5 C5:1 |
F5:.5 E5:.5 D5:.5 F5:.5 A5:1 F5:1 | G5:1 D5:.5 B4:.5 -:2 |
C6:.5 A5:.5 F5:.5 A5:.5 C6:.5 -:.5 A5:1 | B5:.5 G5:.5 D5:.5 G5:.5 B5:.5 -:.5 G5:1 |
G5:.5 E5:.5 B4:.5 E5:.5 G5:.5 A5:.5 B5:1 | C6:1 B5:.5 A5:.5 E5:2 |
F5:.5 -:.25 F5:.25 E5:.5 D5:.5 A5:1 F5:1 | G5:.5 -:.25 G5:.25 F5:.5 D5:.5 B4:1 G4:1 |
C5:.5 E5:.5 G5:.5 C6:.5 B5:.5 G5:.5 E5:.5 D5:.5 | D5:.5 B4:.5 G4:1 -:1 D4:.5 E4:.25 F4:.25
"""


@sfx("m_training", TRAIN_LOOP, "music",
     "Training yard music, on the Music bus. Light and bouncy C major, 120 BPM, 16 bars; opens "
     "with the FIRST LIGHT figure. LOOPS (the file loops by itself in Godot, no click at the "
     "seam)", trim_db=2.9, loop=True, lock=True)
def _(s):
    bpm = _bpm(TRAIN_N)
    melody = _tune(TRAIN_MELODY)
    chop = "-:.5 5:.5 -:.5 8:.5 -:.5 5:.5 -:.5 8:.5"
    answer = "-:.5 5:.5 -:.5 8:.5 G5:.5 A5:.5 B5:.5 D6:.5"
    # pulse 2 plays the off-beat "pah" and answers the melody in the gaps at bars 4 and 8
    p2 = _comp(TRAIN_CHORDS, [answer if b in (3, 7) else chop for b in range(TRAIN_BARS)], "C4")
    bass = _comp(TRAIN_CHORDS, "R:.75 8:.25 5:.5 8:.5 R:.75 8:.25 5:.5 8:.5", "E2")
    beat = "k.h.s.h.k.k.s.h."
    drums = [beat] * 7 + ["k.h.s.h.k.s.s.ss"] + [beat] * 7 + ["k.h.s.h.s.s.ssss"]

    def one_pass(o):
        _part(s, s.p1, o, bpm, melody, TRAIN_BARS, duty=25, venv=[10, 10, 10, 9, 9, 9, 8, 8, 8, 7],
              gate=0.85)
        _part(s, s.p2, o, bpm, p2, TRAIN_BARS, duty=50, venv=STAB_ENV, gate=0.8)
        _part(s, s.tri, o, bpm, bass, TRAIN_BARS, gate=1.0)
        _drums(s, o, bpm, drums, level=0.8)

    _every_loop(s, TRAIN_LOOP, one_pass)


# ---- m_1_1 FIRST LIGHT: the main theme. G major, 150 BPM, 24 bars (A, B, A again).

FL_N, FL_BARS = 24, 24
FL_LOOP = _loop_len(FL_BARS, FL_N)                           # 38.4 s
FL_CHORDS = ("G D Em C  G D C D    Em C G D  Em C Am D    "
             "G D Em C  G D C+D G+D")
FL_MELODY_A = """
D5:.5 G5:.5 G5:.5 A5:.5 B5:1 G5:1 | A5:.5 B5:.5 A5:.5 F#5:.5 D5:2 |
E5:.5 G5:.5 G5:.5 A5:.5 B5:1 E6:1 | D6:1 C6:.5 B5:.5 G5:2 |
D5:.5 G5:.5 G5:.5 A5:.5 B5:1 D6:1 | C6:.5 B5:.5 A5:.5 B5:.5 A5:1 F#5:1 |
G5:.5 A5:.5 G5:.5 E5:.5 C5:1 E5:1 | D5:1.5 E5:.5 F#5:1 A5:1
"""
FL_MELODY_B = """
B4:.5 E5:1 E5:.5 F#5:.5 G5:1 -:.5 | E5:.5 G5:1 A5:.5 G5:2 |
D5:.5 G5:1 G5:.5 A5:.5 B5:1 -:.5 | A5:1 F#5:1 D5:2 |
B4:.5 E5:1 E5:.5 F#5:.5 G5:1 B5:.5 | C6:1 B5:.5 A5:.5 G5:1 E5:1 |
A5:1.5 G5:.5 F#5:.5 E5:.5 C6:1 | B5:1 A5:1 F#5:1 A5:1
"""
FL_MELODY_C = """
D5:.5 G5:.5 G5:.5 A5:.5 B5:1 G5:1 | A5:.5 B5:.5 A5:.5 F#5:.5 D5:2 |
E5:.5 G5:.5 G5:.5 A5:.5 B5:1 E6:1 | D6:1 C6:.5 B5:.5 C6:1 E6:1 |
D6:1.5 B5:.5 G5:1 B5:1 | C6:.5 B5:.5 A5:.5 B5:.5 A5:1 F#5:1 |
E5:.5 G5:.5 C6:1 B5:.5 A5:.5 F#5:1 | G5:2 -:1 B4:.5 C5:.5
"""


@sfx("m_1_1", FL_LOOP, "music",
     "Level 1-1 FIRST LIGHT music, the game's main theme, on the Music bus. Hopeful and driving, "
     "G major, 150 BPM, 24 bars. LOOPS (the file loops by itself in Godot, no click at the "
     "seam)", trim_db=2.1, loop=True, lock=True)
def _(s):
    bpm, bar = _bpm(FL_N), 4 * 60 / _bpm(FL_N)
    chords = FL_CHORDS.split()
    ch = lambda a, b: " ".join(chords[a:b])
    pump = "R:.5 8:.5 R:.5 8:.5 R:.5 8:.5 R:.5 8:.5"
    walk = "R:.5 5:.5 8:.5 5:.5 R:.5 5:.5 8:.5 5:.5"
    bass = _comp(FL_CHORDS, [pump] * 8 + [walk] * 8 + [pump] * 7
                 + ["R:.5 8:.5 R:.5 8:.5 R:.5 R:.5 3:.5 5:.5"], "E2")
    chop = "-:.5 3:.5 -:.5 5:.5 -:.5 3:.5 -:.5 5:.5"
    chop_hi = "-:.5 5:.5 -:.5 8:.5 -:.5 5:.5 -:.5 10:.5"
    arp = "R:.5 5:.5 8:.5 5:.5 10:.5 5:.5 8:.5 5:.5"
    groove, fill = "k.h.s.h.k.hks.h.", "k.h.s.h.k.s.ssss"
    drums = ([groove] * 7 + [fill] + ["k.h.s.hkk.h.s.h."] * 7 + [fill]
             + ["c...s.h.k.hks.h."] + [groove] * 6 + [fill])

    def one_pass(o):
        for i, (text, duty) in enumerate([(FL_MELODY_A, 25), (FL_MELODY_B, 50),
                                          (FL_MELODY_C, 25)]):
            _part(s, s.p1, o + 8 * i * bar, bpm, _tune(text), 8, duty=duty, venv=LEAD_ENV,
                  gate=0.9, vib=(5, 0.08))
        _part(s, s.p2, o, bpm, _comp(ch(0, 8), chop, "G3"), 8, duty=50, venv=STAB_ENV, gate=0.8)
        _part(s, s.p2, o + 8 * bar, bpm, _comp(ch(8, 16), arp, "E3"), 8, duty=12, venv=ARP_ENV,
              gate=0.9)
        _part(s, s.p2, o + 16 * bar, bpm, _comp(ch(16, 24), chop_hi, "G3"), 8, duty=50,
              venv=STAB_ENV, gate=0.8)
        _part(s, s.tri, o, bpm, bass, FL_BARS, gate=1.0)
        _drums(s, o, bpm, drums, level=0.8)

    _every_loop(s, FL_LOOP, one_pass)


# ---- m_1_1_bonus: a bonus room. E major, 180 BPM, 16 bars.

BONUS_N, BONUS_BARS = 20, 16
BONUS_LOOP = _loop_len(BONUS_BARS, BONUS_N)                  # 21.33 s
BONUS_CHORDS = "E C#m A B  E C#m F#m B  A B G#m C#m  A B E B"
BONUS_MELODY = """
B5:.5 G#5:.5 B5:.5 E6:.5 D#6:.5 E6:.5 B5:1 | G#5:.5 E5:.5 G#5:.5 C#6:.5 B5:1 G#5:1 |
A5:.5 C#6:.5 E6:.5 C#6:.5 B5:.5 A5:.5 F#5:1 | F#5:.5 G#5:.5 A5:.5 B5:.5 -:2 |
B4:.5 E5:.5 E5:.5 F#5:.5 G#5:1 E5:1 | B4:.5 E5:.5 E5:.5 F#5:.5 G#5:1 C#6:1 |
A5:.5 G#5:.5 F#5:.5 E5:.5 F#5:.5 A5:.5 C#6:1 | B5:1 A5:.5 F#5:.5 D#5:2 |
E6:.5 -:.5 C#6:.5 -:.5 A5:.5 C#6:.5 E6:1 | D#6:.5 -:.5 B5:.5 -:.5 F#5:.5 B5:.5 D#6:1 |
B5:.5 D#6:.5 G#6:.5 D#6:.5 B5:.5 G#5:.5 D#5:1 | E5:.5 G#5:.5 C#6:.5 E6:.5 D#6:1 C#6:1 |
C#6:.5 B5:.5 A5:.5 B5:.5 C#6:1 E6:1 | D#6:.5 C#6:.5 B5:.5 C#6:.5 D#6:1 F#6:1 |
E6:.5 B5:.5 G#5:.5 B5:.5 E6:.5 -:.5 E6:.5 -:.5 |
D#6:.25 E6:.25 D#6:.25 C#6:.25 B5:1 -:1 F#5:.5 A5:.5
"""


@sfx("m_1_1_bonus", BONUS_LOOP, "music",
     "Level 1-1 bonus room music, on the Music bus. Short, playful and sparkly, E major, "
     "180 BPM, 16 bars; bars 5 and 6 quote FIRST LIGHT. LOOPS (the file loops by itself in "
     "Godot, no click at the seam)", trim_db=2.0, loop=True, lock=True)
def _(s):
    bpm = _bpm(BONUS_N)
    melody = _tune(BONUS_MELODY)
    sparkle = _comp(BONUS_CHORDS, "R:.25 3:.25 5:.25 8:.25 10:.25 8:.25 5:.25 3:.25 "
                                  "R:.25 3:.25 5:.25 8:.25 10:.25 8:.25 5:.25 3:.25", "E4")
    bass = _comp(BONUS_CHORDS, "R:.5 8:.5 R:.5 8:.5 R:.5 8:.5 R:.5 8:.5", "E2")
    groove = "k.h.s.h.kkh.s.hh"
    drums = [groove] * 7 + ["k.h.s.h.s.s.ssss"] + [groove] * 7 + ["k.h.s.h.sss.ssss"]

    def one_pass(o):
        _part(s, s.p1, o, bpm, melody, BONUS_BARS, duty=25, venv=[10, 10, 9, 9, 8, 8, 8, 7],
              gate=0.85)
        _part(s, s.p2, o, bpm, sparkle, BONUS_BARS, duty=12, venv=[4, 4, 3, 2], gate=0.9)
        _part(s, s.tri, o, bpm, bass, BONUS_BARS, gate=1.0)
        _drums(s, o, bpm, drums, level=0.65)

    _every_loop(s, BONUS_LOOP, one_pass)


# ---- m_1_2 LOOSE GROUND: crumbling floors. E minor, 144 BPM, 24 bars. The bass and drums
# group the sixteenths 3+3+2, so the beat never quite sits where you expect it.

LG_N, LG_BARS = 25, 24
LG_LOOP = _loop_len(LG_BARS, LG_N)                           # 40.0 s
LG_CHORDS = ("Em Em+F C B  Em Em+F Am B    C D Em Em  C D B B    "
             "Em Em+F C B  Am B Em B")
LG_MELODY = """
-:.5 B4:.5 E5:.5 E5:.5 F#5:.5 G5:1 E5:.5 | B5:.75 A5:.25 G5:.5 F#5:.5 F5:.75 E5:.25 C5:1 |
E5:.5 G5:.5 -:.25 G5:.25 A5:.5 G5:.75 E5:.25 C5:1 | D#5:.75 F#5:.75 B5:.5 A5:.75 F#5:.75 D#5:.5 |
-:.5 B4:.5 E5:.5 E5:.5 F#5:.5 G5:1 B5:.5 | E6:.75 D6:.25 B5:.5 G5:.5 A5:.75 G5:.25 F5:1 |
E5:.5 A5:.5 -:.25 A5:.25 C6:.5 B5:.75 A5:.25 E5:1 | F#5:.75 A5:.75 D#6:.5 C6:.75 B5:.75 A5:.5 |
G5:.5 F#5:.25 G5:.25 E5:1 -:.5 C5:.5 E5:.5 G5:.5 | A5:.5 G5:.25 A5:.25 F#5:1 -:.5 D5:.5 F#5:.5 A5:.5 |
B5:1.5 A5:.25 G5:.25 F#5:.5 E5:.5 D#5:.5 E5:.5 | B4:.75 G4:.75 E4:.5 -:2 |
G5:.5 F#5:.25 G5:.25 E5:1 -:.5 C6:.5 B5:.5 G5:.5 | A5:.5 G5:.25 A5:.25 F#5:1 -:.5 D6:.5 C6:.5 A5:.5 |
B5:.75 A5:.75 F#5:.5 D#5:.75 C5:.75 B4:.5 | D#5:.25 E5:.25 F#5:.25 A5:.25 -:1 B4:.5 -:.5 B4:.5 -:.5 |
-:.5 B4:.5 E5:.5 E5:.5 F#5:.5 G5:1 E5:.5 | B5:.75 A5:.25 G5:.5 F#5:.5 F5:.75 E5:.25 C5:1 |
E5:.5 G5:.5 -:.25 G5:.25 A5:.5 G5:.75 E5:.25 C5:1 | D#5:.75 F#5:.75 B5:.5 A5:.75 F#5:.75 D#5:.5 |
E5:.5 A5:.5 -:.25 A5:.25 C6:.5 B5:.75 A5:.25 E5:1 | F#5:.75 A5:.75 D#6:.5 C6:.75 B5:.75 A5:.5 |
G5:.75 F#5:.75 E5:.5 B4:.75 G4:.75 E4:.5 | F#4:.25 G4:.25 A4:.25 B4:.25 D#5:.5 F#5:.5 A5:.5 -:1.5
"""


@sfx("m_1_2", LG_LOOP, "music",
     "Level 1-2 LOOSE GROUND music, on the Music bus. Nervous and off-balance, E minor, "
     "144 BPM, 24 bars; opens with the FIRST LIGHT figure a half-beat late. LOOPS (the file "
     "loops by itself in Godot, no click at the seam)", trim_db=2.4, loop=True, lock=True)
def _(s):
    bpm = _bpm(LG_N)
    melody = _tune(LG_MELODY)
    skitter = _comp(LG_CHORDS, "R:.25 3:.25 5:.25 3:.25 8:.25 5:.25 3:.25 5:.25 "
                               "R:.25 3:.25 5:.25 3:.25 8:.25 5:.25 3:.25 5:.25", "E4")
    bass = _comp(LG_CHORDS, "R:.75 8:.75 5:.5 R:.75 8:.75 5:.5", "E2")
    lurch, gap, crumble = "k.hk.hs.k.hk.hs.", "k.....h.k.....s.", "k.......r.r.rrrr"
    drums = ([lurch] * 8 + [gap] * 3 + [crumble] + [gap] * 3 + [crumble]
             + [lurch] * 7 + ["k.hk.hs.k.s.ssss"])

    def one_pass(o):
        _part(s, s.p1, o, bpm, melody, LG_BARS, duty=50, venv=[11, 11, 10, 10, 9, 9, 8, 8, 7],
              gate=0.85)
        _part(s, s.p2, o, bpm, skitter, LG_BARS, duty=12, venv=[4, 3, 2], gate=0.9)
        _part(s, s.tri, o, bpm, bass, LG_BARS, gate=1.0)
        _drums(s, o, bpm, drums, level=0.75)

    _every_loop(s, LG_LOOP, one_pass)


# ---- m_1_3 THE PRESSES: machinery in rhythm. C minor, 112.5 BPM, 20 bars. A heavy thud on
# every beat is the pulse to move to, metal clanks sit off the beat, static pops in the gaps.

PR_N, PR_BARS = 32, 20
PR_LOOP = _loop_len(PR_BARS, PR_N)                           # 42.67 s
PR_CHORDS = "Cm Cm Ab Bb  Cm Cm Ab G  Fm Fm Cm Cm  Ab Bb G G  Cm Ab Fm G"
PR_MELODY = """
C5:.75 C5:.75 Eb5:.5 -:.5 G5:.5 F5:.5 Eb5:.5 | D5:.75 Eb5:.75 C5:.5 -:2 |
C5:.75 C5:.75 Eb5:.5 -:.5 Ab5:.5 G5:.5 F5:.5 | G5:.75 F5:.75 D5:.5 -:1 Bb4:.5 D5:.5 |
G4:.5 C5:.5 C5:.5 D5:.5 Eb5:1 C5:1 | G5:.75 G5:.75 F5:.5 Eb5:.5 D5:.5 C5:1 |
Eb5:.5 Ab5:.5 C6:.5 Ab5:.5 G5:.75 F5:.75 Eb5:.5 | D5:.75 G5:.75 B5:.5 -:1 G4:.5 B4:.5 |
Ab5:1 -:.25 Ab5:.25 G5:.25 F5:.25 C5:1 F5:1 | Ab5:.5 G5:.5 F5:.5 Eb5:.5 F5:2 |
G5:1 -:.25 G5:.25 F5:.25 Eb5:.25 C5:1 Eb5:1 | D5:.5 Eb5:.5 D5:.5 C5:.5 G4:2 |
C6:.75 C6:.75 Bb5:.5 Ab5:.75 G5:.75 Eb5:.5 | D6:.75 D6:.75 C6:.5 Bb5:.75 F5:.75 D5:.5 |
B5:.75 B5:.75 G5:.5 D5:.75 B4:.75 G4:.5 | -:2 D5:.25 D5:.25 D5:.5 F5:.5 B4:.5 |
G4:.5 C5:.5 C5:.5 D5:.5 Eb5:1 G5:1 | Ab5:.75 G5:.75 Eb5:.5 C5:2 |
F5:.75 Ab5:.75 C6:.5 Bb5:.75 Ab5:.75 F5:.5 | G5:.75 D5:.75 B4:.5 -:1 G4:.5 -:.5
"""


@sfx("m_1_3", PR_LOOP, "music",
     "Level 1-3 THE PRESSES music, on the Music bus. Mechanical and syncopated over a steady "
     "thud, C minor, 112.5 BPM, 20 bars; bars 5 and 17 quote FIRST LIGHT. LOOPS (the file "
     "loops by itself in Godot, no click at the seam)", trim_db=3.2, loop=True, lock=True)
def _(s):
    bpm = _bpm(PR_N)
    melody = _tune(PR_MELODY)
    steam = _comp(PR_CHORDS, "-:.5 8:.25 -:.75 5:.25 -:.5 8:.25 -:.5 10:.25 -:.75", "C4")
    bass = _comp(PR_CHORDS, "R:.5 R:.25 8:.25 R:.5 5:.25 8:.25 "
                            "R:.5 R:.25 8:.25 7:.25 5:.25 8:.5", "E2")
    press, spark = "K..mK.m.K..mK.s.", "K..mK.mxK..mK.sx"
    drums = ([press, press, press, spark] * 3 + [press, press, press, "K..mK.m.K.mmKmss"]
             + [press, press, press, "K..mK.m.K..mKsss"])

    def one_pass(o):
        _part(s, s.p1, o, bpm, melody, PR_BARS, duty=50, venv=[11, 11, 10, 10, 9, 9, 8, 8],
              gate=0.8)
        _part(s, s.p2, o, bpm, steam, PR_BARS, duty=25, venv=STAB_ENV, gate=0.9)
        _part(s, s.tri, o, bpm, bass, PR_BARS, gate=1.0)
        _drums(s, o, bpm, drums, level=0.75)
        _hiss(s, o, PR_LOOP, 31, (0,) * 14 + (2, 3), (0, 1, 2, 3))      # static weather

    _every_loop(s, PR_LOOP, one_pass)


# ---- m_1_4 THE GATE: the World 1 finale. D minor, 163.6 BPM, 24 bars. The last section
# turns the FIRST LIGHT figure into a major-key call to arms over a galloping bass.

GT_N, GT_BARS = 22, 24
GT_LOOP = _loop_len(GT_BARS, GT_N)                           # 35.2 s
GT_CHORDS = ("Dm Dm Bb C  Dm Dm Bb A    Gm Gm Dm Dm  Bb C A A    "
             "Bb C Dm Dm  Bb C A A")
GT_MELODY = """
D5:1.5 A4:.5 D5:.5 E5:.5 F5:1 | E5:.5 F5:.5 G5:.5 E5:.5 A5:2 |
F5:1.5 D5:.5 F5:.5 G5:.5 Bb5:1 | A5:.5 G5:.5 E5:.5 C5:.5 G5:2 |
D5:1.5 A4:.5 D5:.5 E5:.5 F5:1 | A5:.5 G5:.5 F5:.5 E5:.5 D5:1 F5:1 |
Bb5:1 A5:.5 G5:.5 F5:1 D5:1 | E5:1 C#5:.5 E5:.5 A5:2 |
G5:.75 A5:.75 Bb5:.5 D6:1 Bb5:1 | A5:.5 Bb5:.5 A5:.5 G5:.5 D5:2 |
F5:.75 G5:.75 A5:.5 D6:1 A5:1 | G5:.5 A5:.5 G5:.5 F5:.5 E5:1 D5:1 |
D5:.5 F5:.5 Bb5:.5 D6:.5 F6:1 D6:1 | E6:.5 D6:.5 C6:.5 G5:.5 E5:1 G5:1 |
A5:.25 G5:.25 A5:.25 Bb5:.25 A5:.5 E5:.5 C#5:1 E5:1 | A5:.5 -:.5 A5:.5 -:.5 C#6:1 E6:1 |
F5:.5 Bb5:.5 Bb5:.5 C6:.5 D6:1 Bb5:1 | G5:.5 C6:.5 C6:.5 D6:.5 E6:1 C6:1 |
D6:2.5 C6:.5 A5:1 | F5:.5 E5:.5 D5:.5 E5:.5 F5:1 A5:1 |
Bb5:1.5 A5:.5 Bb5:.5 C6:.5 D6:1 | C6:1.5 Bb5:.5 C6:.5 D6:.5 E6:1 |
C#6:2 A5:1 E5:1 | C#5:.5 E5:.5 A5:.5 C#6:.5 E6:.5 C#6:.5 A5:.5 E5:.5
"""


@sfx("m_1_4", GT_LOOP, "music",
     "Level 1-4 THE GATE music, the World 1 finale, on the Music bus. Tense then heroic, "
     "D minor, 163.6 BPM, 24 bars; bars 17 and 18 turn FIRST LIGHT into a major-key call. "
     "LOOPS (the file loops by itself in Godot, no click at the seam)", trim_db=2.0,
     loop=True, lock=True)
def _(s):
    bpm, bar = _bpm(GT_N), 4 * 60 / _bpm(GT_N)
    chords = GT_CHORDS.split()
    ch = lambda a, b: " ".join(chords[a:b])
    melody = _tune(GT_MELODY)
    drive = "R:.5 8:.5 R:.5 8:.5 R:.5 8:.5 5:.5 8:.5"
    gallop = "R:.5 8:.25 5:.25 " * 3 + "8:.5 R:.25 5:.25"
    bass = _comp(GT_CHORDS, [drive] * 8 + [gallop] * 16, "E2")
    tremble = "8:.25 5:.25 3:.25 5:.25 " * 4
    brass = "5:1 3:1 5:1 8:1"
    groove, march = "k.h.s.hkk.h.s.h.", "kkh.s.h.kkh.s.hs"
    roll = "s.s.s.sss.ssssss"
    drums = ([groove] * 7 + ["k.h.s.h.s.s.ssss"] + [march] * 7 + [roll]
             + ["c...s...kkh.s.hs"] + [march] * 6 + [roll])

    def one_pass(o):
        _part(s, s.p1, o, bpm, melody, GT_BARS, duty=25, venv=LEAD_ENV, gate=0.9, vib=(5, 0.08))
        _part(s, s.p2, o, bpm, _comp(ch(0, 8), tremble.strip(), "D4"), 8, duty=12,
              venv=ARP_ENV, gate=0.9)
        _part(s, s.p2, o + 8 * bar, bpm, _comp(ch(8, 24), brass, "A3"), 16, duty=50,
              venv=[5, 6, 6, 6, 5, 5, 5, 5, 4], gate=0.9)
        _part(s, s.tri, o, bpm, bass, GT_BARS, gate=1.0)
        _drums(s, o, bpm, drums, level=0.8)

    _every_loop(s, GT_LOOP, one_pass)


# ---- World 2, the Switchyard. Every track uses the Switchyard motif (5 b6 5 8 b7 5).

# m_2_1 RAIL HOPPERS: rain and lightning. A minor, 133.3 BPM, 20 bars. Bouncy.

RH_N, RH_BARS = 27, 20
RH_LOOP = _loop_len(RH_BARS, RH_N)                           # 36.0 s
RH_CHORDS = "Am Am F G  Am Am Dm E  F G Em Am  F G E E  Am F Dm E"
RH_MELODY = """
E5:.5 F5:.5 E5:.5 A5:1 G5:.5 E5:1 | A4:.5 -:.25 A4:.25 C5:.5 E5:.5 A5:.5 -:.5 E5:1 |
F5:.5 A5:.5 C6:.5 A5:.5 F5:.5 -:.5 C5:1 | D5:.5 G5:.5 B5:.5 G5:.5 D6:1 B5:1 |
E5:.5 F5:.5 E5:.5 A5:1 G5:.5 E5:1 | C6:.5 -:.25 C6:.25 B5:.5 A5:.5 E5:.5 -:.5 A4:1 |
D5:.5 F5:.5 A5:.5 D6:.5 C6:.5 A5:.5 F5:1 | E5:.5 G#5:.5 B5:.5 E6:.5 D6:1 B5:1 |
A5:1 G5:.5 A5:.5 C6:1 A5:1 | B5:1 A5:.5 B5:.5 D6:1 B5:1 |
G5:.5 E5:.5 B4:.5 E5:.5 G5:.5 B5:.5 E6:1 | C6:1.5 B5:.5 A5:1 E5:1 |
A5:.5 C6:.5 F6:.5 C6:.5 A5:.5 F5:.5 C5:1 | B5:.5 D6:.5 G6:.5 D6:.5 B5:.5 G5:.5 D5:1 |
G#5:1 B5:1 E6:1 D6:1 | B5:.5 G#5:.5 E5:.5 D5:.5 B4:1 -:1 |
E5:.5 F5:.5 E5:.5 A5:1 G5:.5 E5:1 | F5:.5 G5:.5 F5:.5 C6:1 A5:.5 F5:1 |
D5:.5 E5:.5 F5:.5 A5:1 G5:.5 F5:1 | E5:1 G#5:.5 B5:.5 D6:.5 C6:.5 B5:1
"""


@sfx("m_2_1", RH_LOOP, "music",
     "Level 2-1 RAIL HOPPERS music, on the Music bus. Bouncy A minor with rain and lightning, "
     "133.3 BPM, 20 bars; opens with the Switchyard motif. LOOPS (the file loops by itself in "
     "Godot, no click at the seam)", trim_db=2.2, loop=True, lock=True)
def _(s):
    bpm = _bpm(RH_N)
    melody = _tune(RH_MELODY)
    offbeat = _comp(RH_CHORDS, "-:.5 3:.5 -:.5 5:.5 -:.5 3:.5 -:.5 8:.5", "A3")
    bass = _comp(RH_CHORDS, "R:.5 8:.25 R:.25 8:.5 5:.5 R:.5 8:.25 R:.25 8:.5 5:.5", "E2")
    hop, fill = "k.hks.h.k.hks.h.", "k.hks.h.k.s.ssss"
    strike = "c..ks.h.k.hks.h."
    drums = ([hop] * 7 + [fill] + [strike] + [hop] * 6 + [fill] + [strike] + [hop] * 2
             + ["k.hks.h.s.s.ssss"])

    def one_pass(o):
        _part(s, s.p1, o, bpm, melody, RH_BARS, duty=50, venv=[11, 11, 10, 10, 9, 9, 8, 8, 8],
              gate=0.85)
        _part(s, s.p2, o, bpm, offbeat, RH_BARS, duty=25, venv=[5, 4, 2], gate=0.8)
        _part(s, s.tri, o, bpm, bass, RH_BARS, gate=1.0)
        _drums(s, o, bpm, drums, level=0.75)
        _hiss(s, o, RH_LOOP, 41, (1, 1, 2), (0, 1, 1, 2))                # rain

    _every_loop(s, RH_LOOP, one_pass)


# m_2_2 SPIKED LINE: rain and a dark stretch. B minor, 90 BPM, 16 bars. The triangle creeps
# through the Switchyard motif at half speed, a heartbeat thuds, the lead echoes faintly.

SL_N, SL_BARS = 40, 16
SL_LOOP = _loop_len(SL_BARS, SL_N)                           # 42.67 s
SL_MELODY = """
-:2 F#5:.5 G5:.5 F#5:1 | B5:1.5 A5:.5 F#5:2 |
-:1 G5:.5 F#5:.5 E5:.5 D5:.5 B4:1 | C#5:1.5 A#4:.5 F#4:2 |
-:2 F#5:.5 G5:.5 F#5:1 | D6:1.5 C#6:.5 B5:1 F#5:1 |
G5:.75 F#5:.25 E5:.5 D5:.5 E5:.5 D5:.5 B4:1 | A#4:1 C#5:1 F#5:2 |
B5:.5 C6:.5 B5:.5 E6:1 D6:.5 B5:1 | G5:1 F#5:.5 E5:.5 B4:2 |
F#5:.5 G5:.5 F#5:.5 B5:1 A5:.5 F#5:1 | D5:1 C#5:.5 B4:.5 F#4:2 |
-:1 D5:.5 E5:.5 G5:1 B5:1 | A5:1 G5:.5 E5:.5 B4:2 |
A#5:1 C#6:1 F#5:1 E5:1 | C#5:2 -:2
"""
SL_BASS = """
F#2:1 G2:1 F#2:1 B2:1 | B2:1 A2:1 F#2:2 | G2:1 -:.5 G2:.5 F#2:1 E2:1 | F#2:1 -:1 C#2:1 F#2:1 |
F#2:1 G2:1 F#2:1 B2:1 | B2:1 A2:1 F#2:2 | G2:1 A2:1 G2:1 E2:1 | F#2:1 E2:1 D2:1 C#2:1 |
B2:1 C3:1 B2:1 E3:1 | E3:1 D3:1 B2:2 | F#2:1 G2:1 F#2:1 B2:1 | B2:1 A2:1 F#2:2 |
G2:1 -:1 G2:1 B2:1 | E2:1 -:1 E2:1 G2:1 | F#2:1 -:1 F#2:1 A#2:1 | C#3:1 C3:1 B2:1 A#2:1
"""


@sfx("m_2_2", SL_LOOP, "music",
     "Level 2-2 SPIKED LINE music, on the Music bus. Cautious, low and creeping, B minor, "
     "90 BPM, 16 bars, with rain; the bass creeps through the Switchyard motif. LOOPS (the "
     "file loops by itself in Godot, no click at the seam)", trim_db=2.2, loop=True, lock=True)
def _(s):
    bpm = _bpm(SL_N)
    heart = "k.k.....k.k....."
    drums = [heart] * 8 + ["t.......k.k....."] + [heart] * 7

    def one_pass(o):
        _part(s, s.p1, o, bpm, _tune(SL_MELODY), SL_BARS, duty=25,
              venv=[9, 10, 10, 9, 9, 8, 8, 8, 7, 7, 7, 6], gate=0.9, vib=(4, 0.15))
        _part(s, s.tri, o, bpm, _tune(SL_BASS), SL_BARS, gate=1.0)
        _drums(s, o, bpm, drums, level=0.65)
        _hiss(s, o, SL_LOOP, 52, (1, 1, 1, 2), (0, 1, 1, 2))             # rain

    _every_loop(s, SL_LOOP, one_pass)
    # pulse 2 is a faint echo of the lead, three eighths behind, the way NES drivers did it
    s.echo(s.p1, s.p2, 0.75 * 60 / bpm, scale=0.45, duty=25)


# m_2_3 CHANNELS: switches flip the world between two channels. G minor, 124.1 BPM, 20 bars.
# The two pulses call and answer. Pulse 1 is the bold channel and pulse 2 the thin one until
# bar 9, where the world flips: pulse 2 calls, bold, and pulse 1 answers, thin. At bar 15 it
# flips back and they play the motif together, bold over thin. A burst of static marks every
# flip.

CH_N, CH_BARS = 29, 20
CH_LOOP = _loop_len(CH_BARS, CH_N)                           # 38.67 s
CH_CHORDS = "Gm Gm Eb F  Gm Gm Cm D  Eb F Cm D  Eb F Gm Gm  Cm Cm D D"
CH_P1 = """
D5:.5 Eb5:.5 D5:.5 G5:1 F5:.5 D5:1 | -:4 | Eb5:.5 G5:.5 Bb5:.5 Eb6:1 D6:.5 Bb5:1 | -:4 |
D5:.5 Eb5:.5 D5:.5 G5:1 F5:.5 D5:1 | -:4 | C6:.5 Bb5:.5 G5:.5 Eb5:1 D5:.5 C5:1 | -:4 |
-:4 | A5:.5 G5:.5 F5:.5 C5:1 D5:.5 F5:1 | -:4 | F#5:.5 E5:.5 D5:.5 A4:1 C5:.5 D5:1 |
Eb5:.5 G5:.5 Bb5:1 -:2 | F5:.5 A5:.5 C6:1 -:2 | D5:.5 Eb5:.5 D5:.5 G5:1 F5:.5 D5:1 | G5:2 -:2 |
C5:.5 Eb5:.5 G5:.5 C6:1 Bb5:.5 G5:1 | -:4 | D5:.25 F#5:.25 A5:.25 D6:.25 -:.5 D6:.5 C6:.5 A5:.5 F#5:1 | -:4
"""
CH_P2 = """
-:4 | G5:.5 F5:.5 D5:.5 Bb4:1 C5:.5 D5:1 | -:4 | C6:.5 A5:.5 F5:.5 C5:1 D5:.5 Eb5:1 |
-:4 | G5:.5 A5:.5 Bb5:.5 D6:1 C6:.5 Bb5:1 | -:4 | D5:.5 F#5:.5 A5:.5 D6:1 C6:.5 A5:1 |
Bb5:.5 C6:.5 Bb5:.5 Eb6:1 D6:.5 Bb5:1 | -:4 | G5:.5 Ab5:.5 G5:.5 C6:1 Bb5:.5 G5:1 | -:4 |
-:2 C6:.5 Bb5:.5 G5:1 | -:2 D6:.5 C6:.5 A5:1 | Bb4:.5 C5:.5 Bb4:.5 D5:1 C5:.5 Bb4:1 | D5:2 -:2 |
-:4 | C6:.5 Bb5:.5 G5:.5 Eb5:1 D5:.5 C5:1 | -:4 | A5:.25 F#5:.25 D5:.25 A4:.25 -:.5 A4:.5 C5:.5 D5:.5 -:1
"""


@sfx("m_2_3", CH_LOOP, "music",
     "Level 2-3 CHANNELS music, on the Music bus. The two pulse voices call and answer and swap "
     "roles when the world flips, G minor, 124.1 BPM, 20 bars, with static; built on the "
     "Switchyard motif. LOOPS (the file loops by itself in Godot, no click at the seam)",
     trim_db=2.6, loop=True, lock=True)
def _(s):
    bpm, bar = _bpm(CH_N), 4 * 60 / _bpm(CH_N)
    p1, p2 = _tune(CH_P1), _tune(CH_P2)
    bass = _comp(CH_CHORDS, "R:.5 8:.5 5:.5 8:.5 R:.5 8:.5 5:.5 8:.5", "E2")
    bold = dict(duty=50, venv=[11, 11, 10, 10, 9, 9, 8, 8])
    thin = dict(duty=12, venv=[8, 8, 7, 7, 6, 6, 5])
    under = dict(duty=12, venv=[6, 6, 5, 5, 4])          # pulse 2 under the motif, bars 15-16
    plan = ((s.p1, p1, [(0, 8, bold), (8, 14, thin), (14, 20, bold)]),
            (s.p2, p2, [(0, 8, thin), (8, 14, bold), (14, 16, under), (16, 20, thin)]))
    groove, flip = "k.h.s.h.k.hxs.h.", "z...s.h.k.hxs.h."
    drums = ([flip] + [groove] * 7 + [flip] + [groove] * 5 + [flip] + [groove] * 4
             + ["k.h.s.h.x.x.xxxx"])

    def one_pass(o):
        for voice, notes, sections in plan:
            for a, b, look in sections:
                _part(s, voice, o + a * bar, bpm, notes[_bar_index(notes, a):_bar_index(notes, b)],
                      b - a, gate=0.85, **look)
        _part(s, s.tri, o, bpm, bass, CH_BARS, gate=1.0)
        _drums(s, o, bpm, drums, level=0.75)
        _hiss(s, o, CH_LOOP, 63, (0,) * 12 + (2, 3), (0, 1, 2))           # static

    _every_loop(s, CH_LOOP, one_pass)


# m_2_4 THE RELAY: the World 2 boss. F minor, 200 BPM, 32 bars. Fast and relentless:
# driving octaves, sixteenth-note arpeggios, lightning on every eight bars.

RL_N, RL_BARS = 18, 32
RL_LOOP = _loop_len(RL_BARS, RL_N)                           # 38.4 s
RL_CHORDS = ("Fm Fm Db Eb  Fm Fm Db C    Bbm Bbm Fm Fm  Db Eb C C    "
             "Fm Fm Db Eb  Fm Fm Gb C    Db Eb Fm Fm  Db Eb C C")
RL_MELODY = """
C5:.5 Db5:.5 C5:.5 F5:1 Eb5:.5 C5:1 | F5:.5 Ab5:.5 C6:.5 Ab5:.5 F5:.5 Ab5:.5 C6:1 |
Db6:1 C6:.5 Ab5:.5 F5:1 Ab5:1 | G5:1 Bb5:.5 G5:.5 Eb5:1 Bb4:1 |
C5:.5 Db5:.5 C5:.5 F5:1 Eb5:.5 C5:1 | F5:.5 Ab5:.5 C6:.5 F6:.5 Eb6:.5 C6:.5 Ab5:1 |
Db6:.5 C6:.5 Ab5:.5 F5:.5 Db6:1 F6:1 | E6:1.5 C6:.5 G5:1 E5:1 |
F5:.5 Gb5:.5 F5:.5 Bb5:1 Ab5:.5 F5:1 | Db6:1.5 C6:.5 Bb5:1 F5:1 |
C6:.5 Db6:.5 C6:.5 F6:1 Eb6:.5 C6:1 | Ab5:1.5 G5:.5 F5:1 C5:1 |
F5:.5 Ab5:.5 Db6:.5 F6:.5 Eb6:1 Db6:1 | G5:.5 Bb5:.5 Eb6:.5 G6:.5 F6:1 Eb6:1 |
E6:.5 F6:.5 E6:.5 C6:.5 G5:.5 C6:.5 E6:1 | G6:1 E6:.5 C6:.5 G5:.5 E5:.5 C5:1 |
C5:.5 Db5:.5 C5:.5 F5:1 Eb5:.5 C5:1 | F5:.5 Ab5:.5 C6:.5 Ab5:.5 F5:.5 Ab5:.5 C6:1 |
Db6:1 C6:.5 Ab5:.5 F5:1 Ab5:1 | G5:1 Bb5:.5 G5:.5 Eb5:1 Bb4:1 |
C5:.5 Db5:.5 C5:.5 F5:1 Eb5:.5 C5:1 | F5:.5 Ab5:.5 C6:.5 F6:.5 Eb6:.5 C6:.5 Ab5:1 |
Gb5:.5 Bb5:.5 Db6:.5 Gb6:.5 F6:1 Db6:1 | E6:.5 C6:.5 G5:.5 E5:.5 C5:.5 E5:.5 G5:1 |
Ab5:1 F5:.5 Ab5:.5 Db6:1 F6:1 | G6:1 F6:.5 Eb6:.5 Bb5:1 G5:1 |
C6:.5 Db6:.5 C6:.5 F6:1 Eb6:.5 C6:1 | F6:1.5 Eb6:.5 C6:1 Ab5:1 |
F6:.5 Eb6:.5 Db6:.5 C6:.5 Db6:.5 Eb6:.5 F6:1 | G6:.5 F6:.5 Eb6:.5 D6:.5 Eb6:.5 F6:.5 G6:1 |
E6:.5 -:.5 E6:.5 -:.5 E6:.5 G6:.5 E6:.5 C6:.5 | G5:.5 E5:.5 C5:.5 E5:.5 G5:.5 Bb5:.5 C6:.25 Bb5:.25 G5:.25 E5:.25
"""


@sfx("m_2_4", RL_LOOP, "music",
     "Level 2-4 THE RELAY music, the World 2 boss, on the Music bus. Fast, relentless and "
     "urgent, F minor, 200 BPM, 32 bars, lightning every eight bars; built on the Switchyard "
     "motif. LOOPS (the file loops by itself in Godot, no click at the seam)", trim_db=2.3,
     loop=True, lock=True)
def _(s):
    bpm, bar = _bpm(RL_N), 4 * 60 / _bpm(RL_N)
    melody = _tune(RL_MELODY)
    arps = _comp(RL_CHORDS, "R:.25 3:.25 5:.25 8:.25 " * 4, "F3")
    octs = "R:.5 8:.5 R:.5 8:.5 R:.5 8:.5 R:.5 8:.5"
    churn = "R:.5 R:.5 8:.5 R:.5 5:.5 R:.5 8:.5 5:.5"
    bass = _comp(RL_CHORDS, [octs] * 8 + [churn] * 8 + [octs] * 8 + [churn] * 8, "E2")
    drive, strike, fill = "k.hks.h.kkh.s.hh", "c..ks.h.kkh.s.hh", "k.hks.h.s.sss.ss"
    drums = ([strike] + [drive] * 6 + [fill]) * 3 + [strike] + [drive] * 6 + ["s.s.s.s.ssssssss"]

    def one_pass(o):
        for i, duty in enumerate((25, 50, 25, 50)):          # the lead changes colour every 8 bars
            a, b = _bar_index(melody, 8 * i), _bar_index(melody, 8 * i + 8)
            _part(s, s.p1, o + 8 * i * bar, bpm, melody[a:b], 8, duty=duty, venv=LEAD_ENV,
                  gate=0.85)
        _part(s, s.p2, o, bpm, arps, RL_BARS, duty=12, venv=[5, 4, 3], gate=0.9)
        _part(s, s.tri, o, bpm, bass, RL_BARS, gate=1.0)
        _drums(s, o, bpm, drums, level=0.8)

    _every_loop(s, RL_LOOP, one_pass)


# ---------------------------------------------------------------- build

def build(names: list[str] | None = None) -> list[dict]:
    OUT.mkdir(parents=True, exist_ok=True)
    manifest_path = OUT / "manifest.json"
    old = {}
    if names and manifest_path.exists():
        old = {e["name"]: e for e in json.loads(manifest_path.read_text())["sounds"]}
    entries = []
    for name, spec in SOUNDS.items():
        if names and name not in names:
            if name in old:
                entries.append(old[name])
            continue
        if spec["loop"]:
            s = Sound(2 * spec["dur"] + LOOP_XFADE + LOOP_SEARCH + 0.02)
            spec["fn"](s)
            if spec["lock"]:
                lock_phase(s, spec["dur"])
            pcm, stats = finish_loop(render(s), spec["dur"], spec["trim_db"], spec["power_seam"])
        else:
            s = Sound(spec["dur"])
            spec["fn"](s)
            pcm, stats = finish(render(s), spec["trim_db"], spec["fade"])
        write_wav(OUT / f"{name}.wav", pcm, loop=spec["loop"])
        entries.append({"name": name, "file": f"{name}.wav", "category": spec["category"],
                        **stats, "trim_db": spec["trim_db"], "trigger": spec["trigger"],
                        **({"loop": True} if spec["loop"] else {})})
    manifest = {
        "format": "44100 Hz, 16-bit, mono PCM WAV",
        "generator": "tools/audio/sfx8.py",
        "loudness_rule": f"peak ceiling {PEAK_CEIL_DB} dBFS; loudest 50 ms RMS aimed at "
                         f"{TARGET_ST_DB} dBFS plus each sound's trim_db",
        "sounds": entries,
    }
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    return entries


def main(argv: list[str]) -> int:
    names = argv[1:] or None
    unknown = [n for n in names or [] if n not in SOUNDS]
    if unknown:
        print("unknown sound(s):", ", ".join(unknown))
        print("known:", ", ".join(SOUNDS))
        return 1
    entries = build(names)
    print(f"{'name':22} {'dur':>6} {'peak':>7} {'rms':>7} {'50ms':>7} {'trim':>5}")
    for e in entries:
        print(f"{e['name']:22} {e['duration']:6.2f} {e['peak_dbfs']:7.2f} {e['rms_dbfs']:7.2f} "
              f"{e['loudest_50ms_rms_dbfs']:7.2f} {e['trim_db']:5.1f}")
    print(f"{len(entries)} sounds in {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
