"""Generate the small, original sound palette used by The Last Signal."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "audio"
OUT.mkdir(exist_ok=True)


def write(name: str, duration: float, sample) -> None:
    frames = bytearray()
    for i in range(int(RATE * duration)):
        t = i / RATE
        value = max(-1.0, min(1.0, sample(t, duration)))
        frames += struct.pack("<h", int(value * 32767))
    with wave.open(str(OUT / name), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(frames)


def bell(t: float, duration: float, start: float, end: float, volume: float) -> float:
    p = t / duration
    freq = start + (end - start) * p
    phase = 2 * math.pi * (start * t + (end - start) * t * t / (2 * duration))
    envelope = math.sin(math.pi * p) ** 0.65 * math.exp(-1.3 * p)
    return volume * envelope * (math.sin(phase) + 0.24 * math.sin(phase * 2))


write("pickup.wav", 0.20, lambda t, d: bell(t, d, 430, 690, 0.32))
write("rotate.wav", 0.16, lambda t, d: bell(t, d, 620, 390, 0.25))
write("power.wav", 0.43, lambda t, d: bell(t, d, 310, 800, 0.36))


def success(t: float, duration: float) -> float:
    envelope = math.sin(math.pi * t / duration) ** 0.55 * math.exp(-0.55 * t)
    chord = sum(math.sin(2 * math.pi * hz * t) for hz in (261.63, 329.63, 392.0)) / 3
    return 0.34 * envelope * chord


write("success.wav", 0.86, success)


def ambient(t: float, duration: float) -> float:
    pulse = 0.78 + 0.22 * math.sin(2 * math.pi * t / duration)
    return 0.085 * pulse * (math.sin(2 * math.pi * 55 * t) + 0.45 * math.sin(2 * math.pi * 82.5 * t))


write("ambient.wav", 6.0, ambient)
