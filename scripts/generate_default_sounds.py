#!/usr/bin/env python3
"""Generate royalty-free placeholder WAV sounds for LGBTFinder Module 9.

Replace these with higher-quality assets from Mixkit (mixkit.co/free-sound-effects/notification/)
using the filenames in docs/SOUNDS_ASSET_GUIDE.md.
"""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100


def _fade_envelope(length: int, attack: float = 0.02, release: float = 0.08) -> list[float]:
    attack_samples = int(SAMPLE_RATE * attack)
    release_samples = int(SAMPLE_RATE * release)
    env = [1.0] * length
    for i in range(min(attack_samples, length)):
        env[i] *= i / max(attack_samples, 1)
    for i in range(min(release_samples, length)):
        env[-1 - i] *= i / max(release_samples, 1)
    return env


def _tone(freq: float, duration: float, volume: float = 0.35) -> list[float]:
    count = int(SAMPLE_RATE * duration)
    env = _fade_envelope(count)
    return [
        volume * env[i] * math.sin(2 * math.pi * freq * i / SAMPLE_RATE)
        for i in range(count)
    ]


def _concat(segments: list[list[float]]) -> list[float]:
    out: list[float] = []
    for seg in segments:
        out.extend(seg)
    return out


def _silence(duration: float) -> list[float]:
    return [0.0] * int(SAMPLE_RATE * duration)


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    clipped = [max(-1.0, min(1.0, s)) for s in samples]
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        frames = b"".join(
            struct.pack("<h", int(sample * 32767)) for sample in clipped
        )
        wf.writeframes(frames)


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    out_dir = root / "assets" / "sounds"
    android_raw = root / "android" / "app" / "src" / "main" / "res" / "raw"

    sounds = {
        "message_default.wav": _concat([
            _tone(880, 0.12, 0.32),
            _silence(0.03),
            _tone(1175, 0.14, 0.28),
        ]),
        "message_soft.wav": _tone(520, 0.22, 0.18),
        "message_pop.wav": _concat([
            _tone(180, 0.05, 0.45),
            _silence(0.02),
            _tone(240, 0.04, 0.25),
        ]),
        "message_chime.wav": _concat([
            _tone(1047, 0.1, 0.25),
            _silence(0.02),
            _tone(1319, 0.1, 0.22),
            _silence(0.02),
            _tone(1568, 0.14, 0.2),
        ]),
        "ringtone_default.wav": _concat([
            _tone(440, 0.35, 0.35),
            _silence(0.08),
            _tone(480, 0.35, 0.35),
            _silence(0.08),
            _tone(440, 0.35, 0.35),
            _silence(0.08),
            _tone(480, 0.35, 0.35),
        ]),
        "ringtone_pride.wav": _concat([
            _tone(523, 0.18, 0.3),
            _tone(659, 0.18, 0.3),
            _tone(784, 0.18, 0.3),
            _tone(988, 0.18, 0.3),
            _tone(1047, 0.28, 0.32),
        ]),
        "ringtone_classic.wav": _concat([
            _tone(425, 0.4, 0.38),
            _silence(0.12),
            _tone(425, 0.4, 0.38),
            _silence(0.35),
            _tone(425, 0.4, 0.38),
            _silence(0.12),
            _tone(425, 0.4, 0.38),
        ]),
    }

    for name, samples in sounds.items():
        asset_path = out_dir / name
        write_wav(asset_path, samples)
        write_wav(android_raw / name, samples)
        print(f"Wrote {asset_path}")
        print(f"Wrote {android_raw / name}")


if __name__ == "__main__":
    main()
