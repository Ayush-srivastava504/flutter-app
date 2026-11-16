"""Composes ClipForge's royalty-free music + sound-effects library.

Everything here is synthesised from scratch (oscillators, Karplus-Strong
strings, noise drums, convolution reverb) from the note data in this file,
so the output is an original work with no samples or third-party material:
it is safe for monetised YouTube videos and is dedicated to the public
domain (CC0) — see assets/audio/library/LICENSE.txt.

  python tools/make_audio_library.py            # writes assets/audio/library/*.m4a,
                                                 # assets/audio/sfx/*.m4a and
                                                 # lib/models/audio_library.dart
Needs numpy + scipy, and an ffmpeg binary (imageio_ffmpeg's is used if present).
Deterministic: the same script always renders the same files.
"""
import json
import os
import subprocess
import sys

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), '..'))
MUSIC_DIR = os.path.join(ROOT, 'assets', 'audio', 'library')
SFX_DIR = os.path.join(ROOT, 'assets', 'audio', 'sfx')
DART_OUT = os.path.join(ROOT, 'lib', 'models', 'audio_library.dart')


def ffmpeg_bin():
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        return 'ffmpeg'


# ----------------------------------------------------------------------------- basics

def secs(n):
    return np.arange(int(n)) / SR


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def env_adsr(n, a=0.005, d=0.1, s=0.7, r=0.1):
    """Attack/decay/sustain over n samples, then an r-second release tail appended."""
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    a_n = max(1, min(a_n, n))
    d_n = max(1, min(d_n, n - a_n)) if n > a_n else 1
    s_n = max(0, n - a_n - d_n)
    e = np.concatenate([
        np.linspace(0, 1, a_n, endpoint=False),
        np.linspace(1, s, d_n, endpoint=False),
        np.full(s_n, s),
    ])[:n]
    last = e[-1] if len(e) else 0
    tail = last * np.exp(-np.arange(r_n) / max(1, r_n) * 5)
    return np.concatenate([e, tail])


def lp(x, fc, order=2):
    sos = signal.butter(order, min(fc, SR / 2 - 100), 'low', fs=SR, output='sos')
    return signal.sosfilt(sos, x, axis=0)


def hp(x, fc, order=2):
    sos = signal.butter(order, fc, 'high', fs=SR, output='sos')
    return signal.sosfilt(sos, x, axis=0)


def bp(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, min(hi, SR / 2 - 100)], 'band', fs=SR, output='sos')
    return signal.sosfilt(sos, x, axis=0)


class Bus:
    """A stereo buffer notes are mixed into."""

    def __init__(self, seconds):
        self.x = np.zeros((int(seconds * SR) + SR * 4, 2))

    def add(self, mono, at_s, gain=1.0, pan=0.0):
        i = int(at_s * SR)
        if i >= len(self.x):
            return
        mono = mono[: len(self.x) - i]
        l, r = np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)
        self.x[i:i + len(mono), 0] += mono * gain * l * 1.414
        self.x[i:i + len(mono), 1] += mono * gain * r * 1.414

    def add_stereo(self, st, at_s, gain=1.0):
        i = int(at_s * SR)
        st = st[: len(self.x) - i]
        self.x[i:i + len(st)] += st * gain


rng = np.random.default_rng(7)


def reverb(x, seconds=1.8, mix=0.25, tone=6000, seed=1):
    """Stereo convolution reverb with a decaying-noise impulse response."""
    g = np.random.default_rng(seed)
    n = int(seconds * SR)
    t = secs(n)
    decay = np.exp(-t / seconds * 6.9)
    ir = np.stack([g.standard_normal(n) * decay, g.standard_normal(n) * decay], axis=1)
    ir = lp(ir, tone)
    ir[: int(0.012 * SR)] *= np.linspace(0, 1, int(0.012 * SR))[:, None]  # pre-delay-ish
    ir /= np.sqrt((ir ** 2).sum(axis=0, keepdims=True))
    wet = np.stack([signal.fftconvolve(x[:, c], ir[:, c])[: len(x)] for c in range(2)], axis=1)
    return x * (1 - mix) + wet * mix * 2.2


def tremolo(x, rate=4.0, depth=0.25):
    t = secs(len(x))
    return x * (1 - depth / 2 + depth / 2 * np.sin(2 * np.pi * rate * t))[:, None]


def wobble(x, rate=0.6, cents=8):
    """Tape wow: slowly modulated resampling."""
    n = len(x)
    t = np.arange(n)
    dev = (2 ** (cents / 1200) - 1) * SR / (2 * np.pi * rate)
    pos = t + dev * np.sin(2 * np.pi * rate * t / SR)
    pos = np.clip(pos, 0, n - 1)
    return np.stack([np.interp(pos, t, x[:, c]) for c in range(2)], axis=1)


# ----------------------------------------------------------------------------- instruments

def rhodes(f, dur, vel=0.8):
    n = int((dur + 1.2) * SR)
    t = secs(n)
    body = (np.sin(2 * np.pi * f * t)
            + 0.30 * np.sin(2 * np.pi * 2 * f * t) * np.exp(-t * 3)
            + 0.10 * np.sin(2 * np.pi * 3 * f * t) * np.exp(-t * 6))
    tine = 0.08 * np.sin(2 * np.pi * 7.02 * f * t) * np.exp(-t * 14)
    e = np.exp(-t * 0.9) * np.minimum(1, t / 0.004)
    off = int(dur * SR)
    e[off:] *= np.exp(-np.arange(n - off) / SR * 9)
    return (body + tine * vel) * e * vel


def epiano_chord(bus, notes, at, dur, vel=0.5, spread=0.012, pan=0.0):
    for k, m in enumerate(sorted(notes)):
        bus.add(rhodes(hz(m), dur, vel * (0.9 + 0.1 * rng.random())), at + k * spread * rng.random(),
                0.22, pan + (k - len(notes) / 2) * 0.12)


def saw(f, n, harmonics=40):
    t = secs(n)
    out = np.zeros(n)
    for h in range(1, harmonics + 1):
        if h * f > SR / 2.2:
            break
        out += np.sin(2 * np.pi * h * f * t) / h
    return out * 0.6


def pad(f, dur, attack=0.6, release=1.2, detune=0.08, voices=3, harmonics=24):
    n = int(dur * SR)
    e = env_adsr(n, attack, 0.3, 0.85, release)
    total = len(e)
    out = np.zeros(total)
    for v in range(voices):
        cents = (v - (voices - 1) / 2) * detune * 100 / max(1, voices - 1) * 2
        out += saw(f * 2 ** (cents / 1200), total, harmonics)
    return out * e / voices


def pluck(f, dur, bright=0.5, decay=0.996):
    """Karplus-Strong, computed a period at a time (vectorised)."""
    period = max(2, int(round(SR / f)))
    n = int((dur + 0.6) * SR)
    g = np.random.default_rng(int(f * 10))
    y = np.zeros(n + period + 2)
    burst = g.uniform(-1, 1, period)
    burst = lp(burst, 1500 + bright * 7000, 1)
    y[1:period + 1] = burst
    i = period + 1
    while i < n:
        j = min(i + period, n)
        y[i:j] = decay * 0.5 * (y[i - period:j - period] + y[i - period - 1:j - period - 1])
        i = j
    out = y[1:n + 1]
    off = int(dur * SR)
    out[off:] *= np.exp(-np.arange(n - off) / SR * 12)
    return out


def bass(f, dur, kind='sub'):
    n = int((dur + 0.15) * SR)
    t = secs(n)
    if kind == 'saw':
        x = lp(saw(f, n, 20), 700)
    else:
        x = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * 2 * f * t)
    e = env_adsr(int(dur * SR), 0.006, 0.12, 0.75, 0.12)[:n]
    e = np.pad(e, (0, n - len(e)))
    return np.tanh(1.4 * x * e) * 0.8


def bell(f, dur):
    n = int((dur + 1.5) * SR)
    t = secs(n)
    x = (np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * 2.76 * f * t) * np.exp(-t * 2)
         + 0.25 * np.sin(2 * np.pi * 5.4 * f * t) * np.exp(-t * 4))
    return x * np.exp(-t * 2.2) * np.minimum(1, t / 0.002)


def piano(f, dur, vel=0.7):
    n = int((dur + 1.5) * SR)
    t = secs(n)
    x = np.zeros(n)
    for h, a in [(1, 1), (2, 0.45), (3, 0.22), (4, 0.12), (5, 0.07), (6, 0.04)]:
        x += a * np.sin(2 * np.pi * h * f * 1.0005 ** h * t) * np.exp(-t * (1.1 + h * 0.6))
    e = np.minimum(1, t / 0.003)
    off = int(dur * SR)
    e[off:] *= np.exp(-np.arange(n - off) / SR * 6)
    return x * e * vel


# ----------------------------------------------------------------------------- drums

def kick(punch=1.0, lofi=False):
    n = int(0.5 * SR)
    t = secs(n)
    f = 46 + 110 * np.exp(-t * 32) * punch
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) * np.exp(-t * (6 if not lofi else 8))
    x[: int(0.003 * SR)] += rng.uniform(-0.4, 0.4, int(0.003 * SR))
    if lofi:
        x = lp(x, 2500)
    return np.tanh(1.6 * x)


def snare(lofi=False):
    n = int(0.35 * SR)
    t = secs(n)
    noise = bp(rng.standard_normal(n), 1200, 7000) * np.exp(-t * 17)
    tone = np.sin(2 * np.pi * 188 * t) * np.exp(-t * 28) * 0.6
    x = noise * 0.8 + tone
    if lofi:
        x = lp(x, 3500)
    return x * 0.9


def clap():
    n = int(0.4 * SR)
    t = secs(n)
    x = np.zeros(n)
    for k, d in enumerate([0, 0.011, 0.022]):
        i = int(d * SR)
        seg = bp(rng.standard_normal(n - i), 900, 3200) * np.exp(-secs(n - i) * (60 if k < 2 else 13))
        x[i:] += seg
    return x * 0.7


def hat(open_=False, lofi=False):
    n = int((0.35 if open_ else 0.08) * SR)
    t = secs(n)
    x = hp(rng.standard_normal(n), 7500, 4) * np.exp(-t * (11 if open_ else 70))
    if lofi:
        x = lp(x, 9000)
    return x * 0.35


def shaker():
    n = int(0.12 * SR)
    t = secs(n)
    e = np.minimum(1, t / 0.02) * np.exp(-t * 35)
    return hp(rng.standard_normal(n), 5000, 2) * e * 0.25


def rim():
    n = int(0.06 * SR)
    t = secs(n)
    return (np.sin(2 * np.pi * 1700 * t) + 0.5 * bp(rng.standard_normal(n), 2000, 6000)) * np.exp(-t * 90) * 0.4


# ----------------------------------------------------------------------------- harmony

NOTE = {'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3, 'E': 4, 'F': 5, 'F#': 6, 'Gb': 6, 'G': 7,
        'G#': 8, 'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11}
QUAL = {
    'maj': [0, 4, 7], 'm': [0, 3, 7], 'maj7': [0, 4, 7, 11], 'm7': [0, 3, 7, 10], '7': [0, 4, 7, 10],
    'maj9': [0, 4, 7, 11, 14], 'm9': [0, 3, 7, 10, 14], '9': [0, 4, 7, 10, 14], '13': [0, 4, 10, 14, 21],
    'sus2': [0, 2, 7], 'add9': [0, 4, 7, 14], 'm11': [0, 3, 7, 10, 14, 17], '6': [0, 4, 7, 9],
}


def chord(sym, octave=4):
    """'Dm9' -> midi notes rooted in [octave]; also returns the root."""
    root = sym[:2] if len(sym) > 1 and sym[1] in '#b' else sym[:1]
    q = sym[len(root):] or 'maj'
    r = 12 * (octave + 1) + NOTE[root]
    return [r + i for i in QUAL[q]], r


def voice_lead(prev, notes):
    """Move chord tones by octaves to sit near the previous chord (smooth voicing)."""
    if not prev:
        return notes
    centre = np.mean(prev)
    out = []
    for m in notes:
        while m - centre > 6:
            m -= 12
        while centre - m > 6:
            m += 12
        out.append(m)
    return sorted(set(out))


SCALES = {'minor': [0, 2, 3, 5, 7, 8, 10], 'major': [0, 2, 4, 5, 7, 9, 11], 'dorian': [0, 2, 3, 5, 7, 9, 10],
          'penta': [0, 3, 5, 7, 10], 'majpenta': [0, 2, 4, 7, 9]}


def melody_line(key_root, scale, bars, beats_per_bar, seed, chord_roots, density=0.5, low=70, high=86):
    """A motif-based melody: a 2-bar phrase, repeated with variation."""
    g = np.random.default_rng(seed)
    pool = [key_root + o * 12 + s for o in range(-1, 3) for s in SCALES[scale]]
    pool = [p for p in pool if low <= p <= high]
    steps = beats_per_bar * 2  # 8th notes
    phrase = []
    cur = pool[len(pool) // 2]
    for i in range(steps * 2):
        if g.random() < density or i % steps == 0:
            move = g.choice([-2, -1, -1, 0, 1, 1, 2, 3, -3])
            idx = int(np.clip(pool.index(min(pool, key=lambda p: abs(p - cur))) + move, 0, len(pool) - 1))
            cur = pool[idx]
            length = g.choice([1, 1, 2, 2, 3, 4])
            phrase.append((i, cur, length))
    notes = []
    for b in range(0, bars, 2):
        vary = (b // 2) % 2 == 1
        for (i, m, l) in phrase:
            if vary and g.random() < 0.3:
                m = pool[int(np.clip(pool.index(m) + g.choice([-1, 1]), 0, len(pool) - 1))]
            notes.append((b * steps + i, m, l))
    return notes  # (8th index, midi, length in 8ths)


# ----------------------------------------------------------------------------- songs

class Song:
    def __init__(self, bpm, bars, beats=4):
        self.bpm, self.bars, self.beats = bpm, bars, beats
        self.beat = 60 / bpm
        self.bar = self.beat * beats
        self.len = self.bar * bars
        self.buses = {}

    def bus(self, name):
        if name not in self.buses:
            self.buses[name] = Bus(self.len)
        return self.buses[name]

    def step_time(self, bar, step, swing=0.0, steps=16):
        st = self.bar / steps
        t = bar * self.bar + step * st
        if step % 2 == 1:
            t += swing * st
        return t

    def drums(self, pattern, bars, kit, swing=0.0, vel=1.0, humanise=0.004):
        """pattern: dict name -> 16-char string per bar ('x' hit, 'o' soft)."""
        for bar in bars:
            for name, pat in pattern.items():
                steps = len(pat)
                for s, ch in enumerate(pat):
                    if ch == '.':
                        continue
                    v = vel * (1.0 if ch == 'x' else 0.5)
                    t = self.step_time(bar, s, swing, steps) + rng.normal(0, humanise)
                    self.bus('drums').add(kit[name], max(0, t), v * KIT_GAIN.get(name, 1.0),
                                          KIT_PAN.get(name, 0.0))

    def render(self, master_gain=1.0):
        mix = np.zeros_like(next(iter(self.buses.values())).x)
        for b in self.buses.values():
            mix += b.x
        return mix * master_gain


KIT_GAIN = {'k': 0.9, 's': 0.55, 'c': 0.5, 'h': 0.55, 'o': 0.4, 'sh': 0.6, 'r': 0.5}
KIT_PAN = {'h': 0.25, 'o': 0.25, 'sh': -0.3, 'r': -0.15}


def kit(lofi=False):
    return {'k': kick(lofi=lofi), 's': snare(lofi), 'c': clap(), 'h': hat(lofi=lofi), 'o': hat(True, lofi),
            'sh': shaker(), 'r': rim()}


def crackle(seconds, amount=1.0, seed=3):
    g = np.random.default_rng(seed)
    n = int(seconds * SR)
    x = np.zeros(n)
    pops = g.random(n) < 0.0009 * amount
    x[pops] = g.uniform(-1, 1, pops.sum()) * g.random(pops.sum()) ** 3
    x = bp(x, 800, 9000) * 0.6
    hiss = lp(g.standard_normal(n), 5000) * 0.012 * amount
    st = np.stack([x + hiss, np.roll(x, 37) + hiss], axis=1)
    return st


def sidechain(x, song, depth=0.5, length=0.22):
    t = secs(len(x))
    pos = (t % song.beat) / length
    g = 1 - depth * np.exp(-pos * 3) * (pos < 1.5)
    return x * g[:, None]


def master(x, lowcut=30, sat=1.2):
    x = hp(x, lowcut)
    x = np.tanh(x * sat) / np.tanh(sat)
    return x


def fade(x, fin=0.02, fout=2.0):
    n = len(x)
    a, b = int(fin * SR), int(fout * SR)
    x[:a] *= np.linspace(0, 1, a)[:, None]
    x[n - b:] *= np.linspace(1, 0, b)[:, None] ** 2
    return x


def trim_len(x, seconds):
    return x[: int(seconds * SR)]


# --- song builders --------------------------------------------------------------

def lofi_song(bpm, progression, key_root, scale, seed, drum_pat, title_seed_shift=0, melody='rhodes',
              chord_octave=3, swing=0.28):
    """Intro (2 bars chords, filtered) → A (8) → break (2, no drums) → A' (4) → outro (2)."""
    bars = 18
    s = Song(bpm, bars)
    k = kit(lofi=True)
    chords = []
    prev = None
    for i in range(bars):
        notes, root = chord(progression[i % len(progression)], chord_octave)
        notes = voice_lead(prev, notes)
        prev = notes
        chords.append((notes, root))
    for i, (notes, root) in enumerate(chords):
        t = i * s.bar
        # Lazy, slightly late "laid back" chord stabs.
        epiano_chord(s.bus('keys'), notes, t + 0.02, s.bar * 0.95, vel=0.55)
        if i not in (0, 1) and i < bars - 2:
            for half in (0, 2):
                s.bus('bass').add(bass(hz(root - 12), s.beat * 1.7), t + half * s.beat, 0.55)
    drum_bars = [b for b in range(2, bars - 2) if b not in (10, 11)]
    s.drums(drum_pat, drum_bars, k, swing=swing, vel=0.9)
    mel = melody_line(key_root, scale, 8, 4, seed, [c[1] for c in chords], density=0.38, low=67, high=84)
    for start_bar in (2, 12):
        for (i8, m, l) in mel:
            bar = start_bar + i8 // 8
            if bar >= bars - 2 or (start_bar == 12 and bar > 15):
                continue
            t = s.step_time(bar, (i8 % 8) * 2, swing)
            snd = pluck(hz(m), l * s.beat / 2, bright=0.3) if melody == 'pluck' else rhodes(hz(m), l * s.beat / 2, 0.6)
            s.bus('lead').add(snd, t, 0.16 if melody == 'pluck' else 0.12, 0.2)
    keys = tremolo(s.buses['keys'].x, rate=bpm / 60 * 2 / 4, depth=0.18)
    s.buses['keys'].x = lp(keys, 2600)
    s.buses['lead'].x = lp(s.buses['lead'].x, 3200)
    s.buses['drums'].x = lp(s.buses['drums'].x, 7500) * 0.9
    mix = s.render()
    mix = sidechain(mix, s, 0.12)
    mix[: int(2 * s.bar * SR)] = lp(mix[: int(2 * s.bar * SR)], 900)  # muffled intro
    mix = reverb(mix, 2.2, 0.22, 4500, seed)
    mix = wobble(mix, 0.5, 7)
    mix += crackle(len(mix) / SR, 1.0, seed) * 0.6
    return fade(master(trim_len(mix, s.len + 1.5), sat=1.4), 0.01, 2.5), s.bpm


def pop_song(bpm, progression, key_root, seed, four_floor=True, bright=True):
    bars = 24
    s = Song(bpm, bars)
    k = kit()
    prev = None
    for i in range(bars):
        notes, root = chord(progression[i % len(progression)], 4)
        notes = voice_lead(prev, notes)
        prev = notes
        t = i * s.bar
        section = 'intro' if i < 4 else 'verse' if i < 12 else 'chorus' if i < 20 else 'outro'
        # Offbeat pluck chords (the "tropical" stab) in the chorus, held chords otherwise.
        if section == 'chorus':
            for st in [2, 6, 10, 14, 3, 11]:
                for m in notes:
                    s.bus('pluck').add(pluck(hz(m + 12), s.beat * 0.4, bright=0.8), s.step_time(i, st), 0.09)
        for m in notes:
            s.bus('pad').add(pad(hz(m), s.bar, 0.08 if section != 'intro' else 0.6, 0.4, 0.06), t, 0.07)
        if section != 'intro':
            for q in range(4):
                s.bus('bass').add(bass(hz(root - 12), s.beat * 0.85, 'saw'), t + q * s.beat, 0.55)
    pat_v = {'k': 'x...x...x...x...', 'c': '....x.......x...', 'h': '..x...x...x...x.', 'sh': 'oxoxoxoxoxoxoxox'}
    pat_c = {'k': 'x...x...x...x...', 'c': '....x.......x...', 'o': '..x...x...x...x.', 'h': 'xxxxxxxxxxxxxxxx'}
    if not four_floor:
        pat_v['k'] = 'x.....x...x.....'
        pat_c['k'] = 'x.....x.x.x.....'
    s.drums(pat_v, range(4, 12), k)
    s.drums(pat_c, range(12, 20), k)
    s.drums({'k': 'x...x...x...x...', 'h': '..x...x...x...x.'}, range(20, 22), k, vel=0.8)
    mel = melody_line(key_root, 'majpenta', 8, 4, seed, [], density=0.5, low=72, high=88)
    for (i8, m, l) in mel:
        bar = 12 + i8 // 8
        if bar < 20:
            s.bus('lead').add(bell(hz(m), l * s.beat / 2), s.step_time(bar, (i8 % 8) * 2), 0.11, 0.15)
    s.buses['pad'].x = lp(s.buses['pad'].x, 3500 if bright else 2200)
    if 'pluck' in s.buses:
        s.buses['pluck'].x = reverb(s.buses['pluck'].x, 1.2, 0.3, 7000, seed)
    mix = s.render()
    mix = sidechain(mix, s, 0.35)
    mix = reverb(mix, 1.6, 0.15, 7000, seed)
    return fade(master(trim_len(mix, s.len + 1.0), sat=1.3), 0.01, 2.0), s.bpm


def hiphop_song(bpm, progression, key_root, seed):
    bars = 16
    s = Song(bpm, bars)
    k = kit(lofi=True)
    prev = None
    for i in range(bars):
        notes, root = chord(progression[i % len(progression)], 3)
        notes = voice_lead(prev, notes)
        prev = notes
        t = i * s.bar
        for st in (0, 6, 10):
            for m in notes:
                s.bus('keys').add(piano(hz(m + 12), s.beat * 0.6, 0.5), s.step_time(i, st, 0.18), 0.13)
        if i >= 2:
            s.bus('bass').add(bass(hz(root - 12), s.beat * 1.5), t, 0.7)
            s.bus('bass').add(bass(hz(root - 12), s.beat * 0.8), s.step_time(i, 10, 0.18), 0.6)
    pat = {'k': 'x......xx.x.....', 's': '....x.......x...', 'h': 'x.x.x.x.x.xxx.x.', 'r': '...........o....'}
    s.drums(pat, range(2, bars - 1), k, swing=0.18)
    s.buses['keys'].x = lp(s.buses['keys'].x, 3000)
    mix = s.render()
    mix = reverb(mix, 1.2, 0.14, 5000, seed)
    mix += crackle(len(mix) / SR, 0.5, seed) * 0.4
    return fade(master(trim_len(mix, s.len + 1.0), sat=1.5), 0.01, 2.0), s.bpm


def synthwave_song(bpm, progression, key_root, seed):
    bars = 20
    s = Song(bpm, bars)
    k = kit()
    prev = None
    for i in range(bars):
        notes, root = chord(progression[i % len(progression)], 4)
        notes = voice_lead(prev, notes)
        prev = notes
        t = i * s.bar
        for m in notes:
            s.bus('pad').add(pad(hz(m), s.bar, 0.3, 0.8, 0.12, 4, 30), t, 0.06)
        if i >= 2:
            arp = notes + [notes[0] + 12]
            for st in range(16):
                m = arp[st % len(arp)] + 12
                s.bus('arp').add(lp(saw(hz(m), int(s.beat / 4 * SR * 0.9), 18), 3000) *
                                 env_adsr(int(s.beat / 4 * SR * 0.9), 0.003, 0.08, 0.3, 0.05)[: int(s.beat / 4 * SR * 0.9)],
                                 s.step_time(i, st), 0.09, 0.3 if st % 2 else -0.3)
            for st in range(0, 16, 2):
                s.bus('bass').add(bass(hz(root - 12), s.beat / 2 * 0.8, 'saw'), s.step_time(i, st), 0.45)
    pat = {'k': 'x...x...x...x...', 's': '....x.......x...', 'h': '..x...x...x...x.'}
    s.drums(pat, range(4, bars - 2), k)
    s.buses['drums'].x = s.buses['drums'].x + reverb(s.buses['drums'].x, 0.9, 0.5, 6000, 5) * 0.3  # gated-ish snare air
    s.buses['arp'].x = reverb(s.buses['arp'].x, 1.0, 0.25, 6000, 9)
    mix = s.render()
    mix = sidechain(mix, s, 0.3)
    mix = reverb(mix, 2.5, 0.18, 6000, seed)
    return fade(master(trim_len(mix, s.len + 1.5), sat=1.3), 0.01, 2.5), s.bpm


def cinematic_song(bpm, progression, seed):
    bars = 14
    s = Song(bpm, bars)
    for i in range(bars):
        notes, root = chord(progression[i % len(progression)], 3)
        t = i * s.bar
        build = min(1.0, 0.35 + i / bars)
        for m in notes + [notes[0] + 12]:
            s.bus('strings').add(pad(hz(m), s.bar, 1.2, 1.8, 0.05, 4, 16), t, 0.07 * build)
        s.bus('low').add(bass(hz(root - 24), s.bar * 0.95), t, 0.35 * build)
        if i >= 6:
            for q in (0, 2, 2.5, 3):
                n = int(0.8 * SR)
                tt = secs(n)
                boom = np.sin(2 * np.pi * (52 + 30 * np.exp(-tt * 20)) * tt) * np.exp(-tt * 4)
                boom += lp(rng.standard_normal(n), 500) * np.exp(-tt * 8) * 0.4
                s.bus('perc').add(boom, t + q * s.beat, 0.5 * build)
        if i >= 8:
            for st in range(0, 16, 2):
                m = notes[(st // 2) % len(notes)] + 24
                s.bus('ost').add(piano(hz(m), s.beat / 2, 0.5), s.step_time(i, st), 0.1)
    s.buses['strings'].x = lp(s.buses['strings'].x, 2400)
    mix = s.render()
    mix = reverb(mix, 3.5, 0.35, 5000, seed)
    return fade(master(trim_len(mix, s.len + 3.0), sat=1.1), 1.5, 4.0), s.bpm


def ambient_song(progression, seed):
    bpm = 60
    bars = 12
    s = Song(bpm, bars)
    for i in range(bars):
        notes, root = chord(progression[i % len(progression)], 3)
        t = i * s.bar
        for m in notes + [notes[1] + 12, notes[0] + 24]:
            s.bus('pad').add(pad(hz(m), s.bar * 1.1, 2.0, 2.5, 0.1, 3, 12), t, 0.06)
        g = np.random.default_rng(seed + i)
        for _ in range(3):
            m = notes[g.integers(len(notes))] + 24
            s.bus('bells').add(bell(hz(m), 0.5), t + g.random() * s.bar, 0.05, g.uniform(-0.6, 0.6))
    s.buses['pad'].x = lp(s.buses['pad'].x, 1800)
    mix = s.render()
    mix = reverb(mix, 5.0, 0.45, 4000, seed)
    return fade(master(trim_len(mix, s.len + 3.0), sat=1.0), 2.5, 5.0), bpm


def acoustic_song(bpm, progression, key_root, seed):
    bars = 18
    s = Song(bpm, bars)
    k = kit()
    prev = None
    strum = [0, 3, 6, 8, 10, 12, 14]
    for i in range(bars):
        notes, root = chord(progression[i % len(progression)], 3)
        notes = voice_lead(prev, notes)
        prev = notes
        for st in strum:
            for j, m in enumerate(notes):
                s.bus('guitar').add(pluck(hz(m + 12), s.beat * 0.9, 0.55, 0.997), s.step_time(i, st, 0.1) + j * 0.008,
                                    0.08 * (1 if st % 4 == 0 else 0.7), -0.25)
        if i >= 2:
            s.bus('bass').add(bass(hz(root - 12), s.beat * 1.8), i * s.bar, 0.45)
            s.bus('bass').add(bass(hz(root - 12 + 7), s.beat * 1.8), i * s.bar + 2 * s.beat, 0.4)
    s.drums({'sh': 'oxoxoxoxoxoxoxox', 'k': 'x.......x.......', 'c': '....x.......x...'}, range(2, bars - 2), k, 0.1, 0.8)
    mel = melody_line(key_root, 'majpenta', 8, 4, seed, [], density=0.4, low=72, high=86)
    for (i8, m, l) in mel:
        bar = 6 + i8 // 8
        if bar < 14:
            s.bus('lead').add(pluck(hz(m), l * s.beat / 2, 0.7), s.step_time(bar, (i8 % 8) * 2, 0.1), 0.14, 0.25)
    mix = s.render()
    mix = reverb(mix, 1.8, 0.2, 6500, seed)
    return fade(master(trim_len(mix, s.len + 1.5), sat=1.2), 0.01, 2.5), s.bpm


def house_song(bpm, progression, seed):
    bars = 24
    s = Song(bpm, bars)
    k = kit()
    prev = None
    for i in range(bars):
        notes, root = chord(progression[i % len(progression)], 4)
        notes = voice_lead(prev, notes)
        prev = notes
        if i >= 4:
            for st in (3, 6, 11, 14):
                for m in notes:
                    s.bus('stab').add(piano(hz(m), s.beat * 0.3, 0.6), s.step_time(i, st), 0.09)
        if i >= 8:
            for st in (2, 6, 10, 14):
                s.bus('bass').add(bass(hz(root - 12), s.beat * 0.4, 'saw'), s.step_time(i, st), 0.6)
    s.drums({'k': 'x...x...x...x...'}, range(0, bars - 1), k)
    s.drums({'c': '....x.......x...', 'o': '..x...x...x...x.', 'h': 'x.xxx.xxx.xxx.xx'}, range(8, bars - 2), k, vel=0.85)
    s.buses['stab'].x = lp(s.buses['stab'].x, 4000)
    mix = s.render()
    mix = sidechain(mix, s, 0.45)
    mix = reverb(mix, 1.4, 0.15, 7000, seed)
    return fade(master(trim_len(mix, s.len + 1.0), sat=1.35), 0.01, 2.0), s.bpm


# ----------------------------------------------------------------------------- the catalogue

MUSIC = [
    # id, title, category, mood, builder
    ('lofi_rainy_window', 'Rainy Window', 'Lofi', 'Calm study beat, warm keys',
     lambda: lofi_song(78, ['Dm9', 'G13', 'Cmaj9', 'Am7'], 62, 'dorian', 11, {
         'k': 'x.......x.x.....', 's': '....x.......x...', 'h': 'x.x.x.x.x.x.x.x.'})),
    ('lofi_late_night', 'Late Night Notes', 'Lofi', 'Sleepy, soft and slow',
     lambda: lofi_song(72, ['Fmaj7', 'Em7', 'Dm7', 'Cmaj7'], 60, 'major', 23, {
         'k': 'x.........x.....', 's': '....x.......x...', 'h': 'o.x.o.x.o.x.o.x.'}, melody='pluck')),
    ('lofi_coffee_break', 'Coffee Break', 'Lofi', 'Jazzy, cosy, a little upbeat',
     lambda: lofi_song(86, ['Ebmaj7', 'Cm9', 'Fm9', 'Bb13'], 63, 'major', 37, {
         'k': 'x......xx.......', 's': '....x.......x...', 'h': 'x.x.x.x.x.x.x.xo', 'r': '..........o.....'})),
    ('chill_sunday', 'Sunday Drift', 'Chill', 'Easy-going, bright pads',
     lambda: pop_song(92, ['Cmaj7', 'Am9', 'Fmaj9', 'G6'], 60, 41, four_floor=False, bright=False)),
    ('pop_bright_side', 'Bright Side', 'Upbeat', 'Happy, vlog-ready energy',
     lambda: pop_song(120, ['C', 'G', 'Am', 'F'], 60, 53)),
    ('pop_good_days', 'Good Days', 'Upbeat', 'Light, summery, feel-good',
     lambda: pop_song(112, ['Dmaj', 'A', 'Bm', 'G'], 62, 59)),
    ('hiphop_street_lights', 'Street Lights', 'Hip-hop', 'Boom-bap groove, moody piano',
     lambda: hiphop_song(90, ['Am7', 'Dm7', 'Em7', 'Am7'], 57, 61)),
    ('synth_neon_highway', 'Neon Highway', 'Electronic', 'Retro 80s drive',
     lambda: synthwave_song(100, ['Am', 'F', 'C', 'G'], 57, 67)),
    ('house_night_pulse', 'Night Pulse', 'Electronic', 'Four-on-the-floor house',
     lambda: house_song(124, ['Am9', 'Dm9', 'Gsus2', 'Cmaj7'], 71)),
    ('cine_rising_tide', 'Rising Tide', 'Cinematic', 'Builds into an epic swell',
     lambda: cinematic_song(70, ['Dm', 'Bbmaj', 'Fmaj', 'C'], 73)),
    ('ambient_weightless', 'Weightless', 'Ambient', 'Floating, no drums',
     lambda: ambient_song(['Cmaj9', 'Am9', 'Fmaj9', 'Gsus2'], 79)),
    ('acoustic_paper_planes', 'Paper Planes', 'Acoustic', 'Plucked strings, hopeful',
     lambda: acoustic_song(96, ['G', 'D', 'Em', 'C'], 67, 83)),
]


# --- sound effects -------------------------------------------------------------

def to_st(x, width=0.0):
    return np.stack([x, np.roll(x, int(width * SR))], axis=1)


def sfx_whoosh(fast=False):
    d = 0.45 if fast else 0.9
    n = int(d * SR)
    t = secs(n)
    e = np.sin(np.pi * t / d) ** (3 if fast else 2)
    noise = rng.standard_normal(n)
    out = np.zeros(n)
    # Swept band-pass: process in short blocks with a rising centre frequency.
    blk = 512
    for i in range(0, n, blk):
        c = 400 + 4200 * (i / n) ** 1.5
        out[i:i + blk] = bp(noise[max(0, i - 2048):i + blk], c * 0.6, c * 1.6)[-len(out[i:i + blk]):]
    x = out * e
    pan = np.linspace(-0.8, 0.8, n)
    return np.stack([x * (1 - pan) / 2, x * (1 + pan) / 2], axis=1) * 2


def sfx_riser():
    d = 2.5
    n = int(d * SR)
    t = secs(n)
    f = 200 * 2 ** (t / d * 3)
    ph = 2 * np.pi * np.cumsum(f) / SR
    tone = (np.sin(ph) + 0.4 * np.sin(2 * ph)) * (t / d) ** 2
    noise = hp(rng.standard_normal(n), 2000) * (t / d) ** 3 * 0.5
    x = tone * 0.5 + noise
    return reverb(to_st(x), 1.5, 0.3)


def sfx_impact():
    n = int(2.0 * SR)
    t = secs(n)
    boom = np.sin(2 * np.pi * (40 + 80 * np.exp(-t * 15)) * t) * np.exp(-t * 2.5)
    crack = lp(rng.standard_normal(n), 3000) * np.exp(-t * 20)
    return reverb(to_st(np.tanh(2 * (boom + crack * 0.6))), 2.0, 0.25, 3000)


def sfx_pop():
    n = int(0.15 * SR)
    t = secs(n)
    f = 300 + 900 * np.exp(-t * 60)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 35)
    return to_st(x)


def sfx_click():
    n = int(0.05 * SR)
    t = secs(n)
    x = (np.sin(2 * np.pi * 2500 * t) * 0.6 + hp(rng.standard_normal(n), 3000) * 0.4) * np.exp(-t * 180)
    return to_st(x)


def sfx_ding():
    return reverb(to_st(bell(hz(88), 0.4) * 0.8), 1.2, 0.2)


def sfx_notify():
    b = Bus(1.5)
    b.add(bell(hz(84), 0.2), 0, 0.5)
    b.add(bell(hz(91), 0.3), 0.12, 0.5)
    return reverb(trim_len(b.x, 1.5), 1.0, 0.18)


def sfx_shutter():
    n = int(0.25 * SR)
    t = secs(n)
    a = bp(rng.standard_normal(n), 1500, 8000) * np.exp(-t * 90)
    b2 = np.zeros(n)
    i = int(0.07 * SR)
    b2[i:] = bp(rng.standard_normal(n - i), 1000, 6000) * np.exp(-secs(n - i) * 60)
    return to_st(a + b2 * 0.8)


def sfx_typing():
    b = Bus(2.0)
    g = np.random.default_rng(5)
    t0 = 0.0
    for _ in range(14):
        n = int(0.04 * SR)
        tt = secs(n)
        key = (bp(g.standard_normal(n), 1500, 6000) + np.sin(2 * np.pi * g.uniform(300, 500) * tt) * 0.4) * np.exp(-tt * 120)
        b.add(key, t0, g.uniform(0.4, 0.7), g.uniform(-0.3, 0.3))
        t0 += g.uniform(0.07, 0.16)
    return trim_len(b.x, t0 + 0.2)


def sfx_glitch():
    n = int(0.6 * SR)
    g = np.random.default_rng(9)
    x = np.zeros(n)
    i = 0
    while i < n:
        l = int(g.uniform(0.01, 0.06) * SR)
        kind = g.integers(3)
        tt = secs(l)
        if kind == 0:
            seg = np.sign(np.sin(2 * np.pi * g.uniform(100, 1500) * tt))
        elif kind == 1:
            seg = g.standard_normal(l)
        else:
            seg = np.zeros(l)
        x[i:i + l] = seg[: len(x[i:i + l])] * 0.5
        i += l
    x = np.round(x * 6) / 6  # bitcrush
    return to_st(x, 0.003)


def sfx_scratch():
    n = int(0.6 * SR)
    t = secs(n)
    speed = np.sin(2 * np.pi * 3.3 * t)
    pos = np.cumsum(np.abs(speed)) / SR * 400
    x = np.sin(2 * np.pi * pos) * np.abs(speed) + bp(rng.standard_normal(n), 300, 3000) * np.abs(speed) * 0.5
    return to_st(np.tanh(x * 1.5) * np.exp(-t * 1.5))


def sfx_coin():
    b = Bus(1.2)
    b.add(bell(hz(95), 0.1) * 0.7, 0, 0.6)
    b.add(bell(hz(100), 0.3) * 0.7, 0.08, 0.6)
    return trim_len(b.x, 1.0)


def sfx_heartbeat():
    b = Bus(2.2)
    for beat in range(2):
        for j, off in enumerate((0, 0.22)):
            n = int(0.25 * SR)
            tt = secs(n)
            thump = np.sin(2 * np.pi * (45 + 30 * np.exp(-tt * 30)) * tt) * np.exp(-tt * 18)
            b.add(thump, beat * 0.9 + off, 0.9 if j == 0 else 0.6)
    return trim_len(b.x, 2.0)


def sfx_drop():
    n = int(1.6 * SR)
    t = secs(n)
    f = 160 * np.exp(-t * 2.2) + 35
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 1.2)
    return to_st(np.tanh(2.5 * x))


def sfx_sparkle():
    b = Bus(2.0)
    g = np.random.default_rng(13)
    for i in range(10):
        m = 84 + g.choice([0, 4, 7, 12, 16, 19])
        b.add(bell(hz(m), 0.15), i * 0.06, 0.18, g.uniform(-0.7, 0.7))
    return reverb(trim_len(b.x, 1.8), 1.5, 0.3, 9000)


def sfx_swipe():
    return sfx_whoosh(fast=True)


SFX = [
    ('sfx_whoosh', 'Whoosh', 'Transitions', sfx_whoosh),
    ('sfx_swipe', 'Swipe', 'Transitions', sfx_swipe),
    ('sfx_riser', 'Riser', 'Transitions', sfx_riser),
    ('sfx_impact', 'Impact', 'Transitions', sfx_impact),
    ('sfx_drop', 'Bass drop', 'Transitions', sfx_drop),
    ('sfx_glitch', 'Glitch', 'Transitions', sfx_glitch),
    ('sfx_pop', 'Pop', 'UI & pop-ups', sfx_pop),
    ('sfx_click', 'Click', 'UI & pop-ups', sfx_click),
    ('sfx_ding', 'Ding', 'UI & pop-ups', sfx_ding),
    ('sfx_notify', 'Notification', 'UI & pop-ups', sfx_notify),
    ('sfx_sparkle', 'Sparkle', 'UI & pop-ups', sfx_sparkle),
    ('sfx_coin', 'Coin', 'UI & pop-ups', sfx_coin),
    ('sfx_shutter', 'Camera shutter', 'Real world', sfx_shutter),
    ('sfx_typing', 'Typing', 'Real world', sfx_typing),
    ('sfx_heartbeat', 'Heartbeat', 'Real world', sfx_heartbeat),
    ('sfx_scratch', 'Record scratch', 'Real world', sfx_scratch),
]


# ----------------------------------------------------------------------------- output

def encode(x, path, music):
    """Normalise and encode to AAC .m4a with ffmpeg."""
    x = np.asarray(x, dtype=np.float64)
    peak = np.max(np.abs(x)) + 1e-9
    x = x / peak * 0.89
    tmp = path + '.wav'
    wavfile.write(tmp, SR, (x * 32767).astype(np.int16))
    af = 'loudnorm=I=-16:TP=-1.5:LRA=11,aresample=44100' if music else 'alimiter=limit=0.89'
    br = '128k' if music else '96k'
    subprocess.run([ffmpeg_bin(), '-hide_banner', '-loglevel', 'error', '-y', '-i', tmp, '-af', af,
                    '-c:a', 'aac', '-b:a', br, '-movflags', '+faststart', path], check=True)
    os.remove(tmp)
    return int(round(len(x) / SR * 1000))


def dart_string(s):
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def main():
    os.makedirs(MUSIC_DIR, exist_ok=True)
    os.makedirs(SFX_DIR, exist_ok=True)
    only = set(sys.argv[1:])
    entries = []
    for (id_, title, cat, mood, build) in MUSIC:
        path = os.path.join(MUSIC_DIR, id_ + '.m4a')
        if only and id_ not in only and os.path.exists(path + '.json'):
            entries.append(json.load(open(path + '.json')))
            continue
        x, bpm = build()
        ms = encode(x, path, True)
        e = dict(id=id_, title=title, category=cat, mood=mood, bpm=bpm, ms=ms, kind='music',
                 asset=f'assets/audio/library/{id_}.m4a')
        json.dump(e, open(path + '.json', 'w'))
        entries.append(e)
        print(f'music {id_:28s} {ms / 1000:5.1f}s {bpm} bpm  {os.path.getsize(path) // 1024} KB')
    for (id_, title, cat, build) in SFX:
        path = os.path.join(SFX_DIR, id_ + '.m4a')
        if only and id_ not in only and os.path.exists(path + '.json'):
            entries.append(json.load(open(path + '.json')))
            continue
        x = build()
        ms = encode(x, path, False)
        e = dict(id=id_, title=title, category=cat, mood='', bpm=0, ms=ms, kind='sfx',
                 asset=f'assets/audio/sfx/{id_}.m4a')
        json.dump(e, open(path + '.json', 'w'))
        entries.append(e)
        print(f'sfx   {id_:28s} {ms / 1000:5.2f}s  {os.path.getsize(path) // 1024} KB')

    lines = [
        '// GENERATED by tools/make_audio_library.py — do not edit by hand.',
        '// Every sound is synthesised by that script (no samples), so the library is an',
        '// original work dedicated to the public domain (CC0): free for any use, including',
        '// monetised YouTube videos, no attribution needed. See assets/audio/library/LICENSE.txt.',
        "import 'library_sound.dart';",
        '',
        'const List<LibrarySound> audioLibrary = [',
    ]
    for e in entries:
        lines.append(
            f"  LibrarySound(id: {dart_string(e['id'])}, title: {dart_string(e['title'])}, "
            f"category: {dart_string(e['category'])}, mood: {dart_string(e['mood'])}, bpm: {e['bpm']}, "
            f"durationMs: {e['ms']}, isSfx: {'true' if e['kind'] == 'sfx' else 'false'}, "
            f"assetPath: {dart_string(e['asset'])}),")
    lines.append('];')
    lines.append('')
    open(DART_OUT, 'w', encoding='utf-8').write('\n'.join(lines))
    # Sidecar json files are build caches only.
    for d in (MUSIC_DIR, SFX_DIR):
        for f in os.listdir(d):
            if f.endswith('.json') and not only:
                os.remove(os.path.join(d, f))
    print('wrote', DART_OUT)


if __name__ == '__main__':
    main()
