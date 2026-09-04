#!/usr/bin/env python3
"""Generate small placeholder SFX (16-bit mono WAV) for The Last Forge.

These are intentionally simple synthesized blips so the prototype has audio
without shipping copyrighted sound files. Replace the .wav files in
res://audio/sfx/ with real Kenney/your own audio later — the filenames are the
contract the AudioManager relies on.

Run:  python tools/generate_sfx.py
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx")


def _env(i, n, attack=0.01, release=0.3):
    """Simple attack/release amplitude envelope (0..1)."""
    t = i / n
    a = min(1.0, (t) / attack) if attack > 0 else 1.0
    r = min(1.0, (1.0 - t) / release) if release > 0 else 1.0
    return max(0.0, min(a, r))


def _write(name, samples):
    os.makedirs(OUT_DIR, exist_ok=True)
    # Normalize and clamp.
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = 0.85 / peak
    path = os.path.join(OUT_DIR, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = bytearray()
        for s in samples:
            v = int(max(-1.0, min(1.0, s * scale)) * 32767)
            frames += struct.pack("<h", v)
        w.writeframes(frames)
    print("wrote", path, "(%.2fs)" % (len(samples) / RATE))


def tone(freq0, freq1, dur, kind="sine", noise=0.0, attack=0.01, release=0.4, vibrato=0.0):
    n = int(RATE * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / n
        f = freq0 + (freq1 - freq0) * t
        if vibrato:
            f += math.sin(2 * math.pi * 6.0 * (i / RATE)) * vibrato
        phase += 2 * math.pi * f / RATE
        if kind == "square":
            base = 1.0 if math.sin(phase) >= 0 else -1.0
        elif kind == "saw":
            base = (phase / math.pi) % 2 - 1
        else:
            base = math.sin(phase)
        if noise:
            base = base * (1.0 - noise) + random.uniform(-1, 1) * noise
        out.append(base * _env(i, n, attack, release))
    return out


def mix(*layers):
    n = max(len(l) for l in layers)
    out = [0.0] * n
    for l in layers:
        for i, s in enumerate(l):
            out[i] += s
    return out


def arpeggio(freqs, step_dur, kind="sine"):
    out = []
    for f in freqs:
        out += tone(f, f, step_dur, kind=kind, attack=0.01, release=0.6)
    return out


random.seed(1234)

SOUNDS = {
    # Player attacks
    "slash":       tone(760, 340, 0.13, noise=0.35, attack=0.005, release=0.5),
    "heavy":       tone(300, 130, 0.24, noise=0.4, attack=0.01, release=0.5),
    "hit":         mix(tone(180, 90, 0.10, kind="square", noise=0.5, attack=0.002, release=0.4),
                       tone(900, 400, 0.06, noise=0.7, attack=0.002, release=0.6)),
    # Damage feedback
    "enemy_hurt":  tone(440, 300, 0.09, kind="square", noise=0.2, attack=0.003, release=0.5),
    "player_hurt": mix(tone(220, 140, 0.18, kind="saw", noise=0.3, attack=0.004, release=0.4),
                       tone(120, 80, 0.18, noise=0.4, attack=0.004, release=0.5)),
    "enemy_death": tone(520, 110, 0.30, kind="square", noise=0.45, attack=0.004, release=0.5),
    # Movement / projectiles
    "dash":        tone(300, 760, 0.18, noise=0.55, attack=0.02, release=0.5),
    "projectile":  tone(880, 1240, 0.12, attack=0.005, release=0.6),
    "charge":      tone(180, 520, 0.26, kind="saw", noise=0.3, attack=0.02, release=0.4),
    "telegraph":   tone(1200, 1200, 0.05, attack=0.005, release=0.7),
    # Rewards / flow
    "pickup":      arpeggio([660, 990], 0.09),
    "upgrade":     arpeggio([523, 659, 784, 1047], 0.10),
    "room_clear":  arpeggio([392, 523, 659, 784], 0.11),
    "game_over":   tone(330, 110, 0.6, kind="saw", noise=0.1, attack=0.01, release=0.5, vibrato=8.0),
}

for nm, data in SOUNDS.items():
    _write(nm, data)

print("\nDone. %d sounds in %s" % (len(SOUNDS), os.path.normpath(OUT_DIR)))
