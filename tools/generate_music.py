#!/usr/bin/env python3
"""Generate seamless-looping ambient music beds for The Last Forge.

Two tracks, both built from slow sine/triangle pads on an A-minor chord so they
sit under the action without melody (forgiving + atmospheric):
  - music_calm.wav   : soft, airy — title screen & the Forge hub.
  - music_combat.wav  : lower, tenser, with a slow root pulse — the dungeon.

Every voice frequency and LFO rate completes a WHOLE number of cycles over the
loop length, so the file loops with no seam/click. 16-bit mono WAV.

Run:  python tools/generate_music.py
"""
import math
import os
import struct
import wave

RATE = 22050
DUR = 24.0                      # loop length (seconds)
N = int(RATE * DUR)
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "Assets", "Audio")
TWO_PI = 2.0 * math.pi


def perfect_freq(approx_hz):
    """Nearest frequency completing a whole number of cycles in DUR seconds."""
    k = max(1, round(approx_hz * DUR))
    return k / DUR


def build(voices):
    """voices: list of dicts {f, amp, lfo, depth, kind, phase}. Returns samples."""
    # Pre-resolve seamless params.
    vs = []
    for v in voices:
        vs.append({
            "f": perfect_freq(v["f"]),
            "amp": v["amp"],
            "lfo": int(round(v.get("lfo", 1))),   # integer cycles over the buffer
            "depth": v.get("depth", 0.0),
            "kind": v.get("kind", "sine"),
            "phase": v.get("phase", 0.0),
        })
    out = [0.0] * N
    for i in range(N):
        s = 0.0
        for v in vs:
            ph = TWO_PI * v["f"] * i / RATE + v["phase"]
            if v["kind"] == "tri":
                w = (2.0 / math.pi) * math.asin(math.sin(ph))
            else:
                w = math.sin(ph)
            if v["depth"] > 0.0:
                lfo = 1.0 - v["depth"] + v["depth"] * 0.5 * (1.0 + math.sin(TWO_PI * v["lfo"] * i / N))
            else:
                lfo = 1.0
            s += v["amp"] * lfo * w
        out[i] = s
    return out


def write(name, samples, target_peak=0.34):
    os.makedirs(OUT_DIR, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = target_peak / peak
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
    print("wrote", os.path.normpath(path), "(%.1fs loop)" % DUR)


# A-minor pad: A, C, E across a couple of octaves. Calm = airy + higher shimmer.
#
# Tuning notes (2026-07-26): these beds are meant to be *barely noticed*. Two
# things made the old versions fatiguing, and both are easy traps:
#   - Triangle waves on the low voices. Their odd harmonics stack into a buzz
#     that a sustained drone has nowhere to hide. Low voices are sines now; the
#     single remaining tri sits mid-range at low amplitude for a little bite.
#   - Fast, deep LFOs. A pad that pumps every two seconds reads as "throbbing"
#     rather than "breathing". Rates are slower and depths shallower.
CALM = [
    {"f": 110.0, "amp": 0.55, "lfo": 1, "depth": 0.22},                  # A2
    {"f": 130.8, "amp": 0.40, "lfo": 2, "depth": 0.26},                  # C3
    {"f": 164.8, "amp": 0.40, "lfo": 1, "depth": 0.26, "phase": 1.1},    # E3
    {"f": 220.0, "amp": 0.26, "lfo": 2, "depth": 0.32},                  # A3
    {"f": 329.6, "amp": 0.09, "lfo": 3, "depth": 0.45, "phase": 0.6},    # E4 shimmer
    {"f": 493.9, "amp": 0.03, "lfo": 4, "depth": 0.55},                  # B4 air
]

# Combat: drop an octave for weight and tighten the voicing. The old version
# leaned on a Bb3 minor second against the A root for "unease" — over a looping
# drone that beats against the root and is the single most irritating thing in
# the mix. Replaced with G3, which keeps the natural-minor colour without the
# grinding. Root pulse halved in rate so it breathes instead of throbbing.
COMBAT = [
    {"f": 55.0, "amp": 0.55, "lfo": 6, "depth": 0.32},                   # A1 pulse
    {"f": 110.0, "amp": 0.42, "lfo": 1, "depth": 0.22},                  # A2
    {"f": 130.8, "amp": 0.38, "lfo": 2, "depth": 0.30},                  # C3
    {"f": 164.8, "amp": 0.36, "lfo": 1, "depth": 0.30, "phase": 0.8},    # E3
    {"f": 196.0, "amp": 0.14, "lfo": 3, "depth": 0.45, "kind": "tri"},   # G3 colour
    {"f": 246.9, "amp": 0.05, "lfo": 4, "depth": 0.55},                  # B3 air
]


if __name__ == "__main__":
    write("music_calm", build(CALM))
    write("music_combat", build(COMBAT))
    print("Done.")
