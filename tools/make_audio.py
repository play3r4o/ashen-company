from __future__ import annotations

import math
import random
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio"
RATE = 22_050
random.seed(1742)


def write_wav(name: str, samples: list[float]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        pcm = bytearray()
        for value in samples:
            integer = int(max(-1.0, min(1.0, value)) * 32767)
            pcm.extend(integer.to_bytes(2, "little", signed=True))
        wav.writeframes(pcm)


def envelope(t: float, duration: float, attack: float = 0.01, release: float = 0.08) -> float:
    return min(1.0, t / attack) * min(1.0, max(0.0, duration - t) / release)


def camp_theme(seconds: float = 18.0) -> list[float]:
    notes = [293.66, 349.23, 440.0, 349.23, 261.63, 293.66, 220.0, 261.63]
    result: list[float] = []
    filtered_noise = 0.0
    for index in range(int(seconds * RATE)):
        t = index / RATE
        drone = math.sin(2 * math.pi * 73.42 * t) * 0.045 + math.sin(2 * math.pi * 110.0 * t) * 0.025
        beat = int(t / 2.25)
        local = t - beat * 2.25
        pluck = 0.0
        if local < 1.5:
            frequency = notes[beat % len(notes)]
            decay = math.exp(-local * 3.4)
            pluck = (math.sin(2 * math.pi * frequency * local) + 0.35 * math.sin(4 * math.pi * frequency * local)) * 0.085 * decay
        filtered_noise = filtered_noise * 0.94 + random.uniform(-1.0, 1.0) * 0.06
        fire = filtered_noise * 0.018
        if random.random() < 0.00065:
            fire += random.uniform(0.08, 0.18)
        result.append((drone + pluck + fire) * envelope(t, seconds, 1.2, 1.2))
    return result


def moor_theme(seconds: float = 18.0) -> list[float]:
    result: list[float] = []
    wind = 0.0
    for index in range(int(seconds * RATE)):
        t = index / RATE
        wind = wind * 0.992 + random.uniform(-1.0, 1.0) * 0.008
        gust = 0.45 + 0.35 * math.sin(2 * math.pi * 0.07 * t) ** 2
        drone = math.sin(2 * math.pi * 55.0 * t) * 0.040 + math.sin(2 * math.pi * 82.41 * t) * 0.022
        distant = math.sin(2 * math.pi * 146.83 * t + math.sin(t * 0.23)) * 0.015
        result.append((drone + distant + wind * gust * 0.14) * envelope(t, seconds, 1.5, 1.5))
    return result


def strike() -> list[float]:
    duration = 0.16
    return [
        (random.uniform(-1.0, 1.0) * math.exp(-t * 28.0) * 0.55 + math.sin(2 * math.pi * (170 - t * 500) * t) * math.exp(-t * 20.0) * 0.25)
        for t in (i / RATE for i in range(int(duration * RATE)))
    ]


def guard() -> list[float]:
    duration = 0.24
    return [
        (math.sin(2 * math.pi * (310 - 150 * t) * t) * math.exp(-t * 14.0) * 0.35 + random.uniform(-0.2, 0.2) * math.exp(-t * 18.0))
        for t in (i / RATE for i in range(int(duration * RATE)))
    ]


def pickup() -> list[float]:
    duration = 0.18
    return [
        (math.sin(2 * math.pi * (520 + 700 * t) * t) * envelope(t, duration, 0.005, 0.06) * 0.28)
        for t in (i / RATE for i in range(int(duration * RATE)))
    ]


def hurt() -> list[float]:
    duration = 0.20
    return [
        (math.sin(2 * math.pi * 82.0 * t) * math.exp(-t * 12.0) * 0.40 + random.uniform(-0.25, 0.25) * math.exp(-t * 15.0))
        for t in (i / RATE for i in range(int(duration * RATE)))
    ]


write_wav("camp_theme.wav", camp_theme())
write_wav("moor_theme.wav", moor_theme())
write_wav("strike.wav", strike())
write_wav("guard.wav", guard())
write_wav("pickup.wav", pickup())
write_wav("hurt.wav", hurt())

