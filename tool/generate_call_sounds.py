"""Generate original in-app WAV sound effects (PCM 16-bit, 22050 Hz, mono)."""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

RATE = 22050
AMP = 0.32


def _clamp(sample: float) -> int:
    value = int(max(-1.0, min(1.0, sample)) * 32767)
    return value


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(b"".join(struct.pack("<h", _clamp(s)) for s in samples))


def env(i: int, n: int, attack: float = 0.012, release: float = 0.08) -> float:
    if n <= 1:
        return 0.0
    t = i / (n - 1)
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (1.0 - t) / release) if release > 0 else 1.0
    return a * r


def tone(freq: float, seconds: float, volume: float = 1.0, attack: float = 0.02, release: float = 0.08) -> list[float]:
    n = max(1, int(seconds * RATE))
    return [
        math.sin(2 * math.pi * freq * i / RATE) * volume * env(i, n, attack, release)
        for i in range(n)
    ]


def dual(f1: float, f2: float, seconds: float, volume: float = 1.0) -> list[float]:
    n = max(1, int(seconds * RATE))
    out = []
    for i in range(n):
        s = 0.5 * (
            math.sin(2 * math.pi * f1 * i / RATE)
            + math.sin(2 * math.pi * f2 * i / RATE)
        )
        out.append(s * volume * env(i, n, 0.02, 0.06))
    return out


def silence(seconds: float) -> list[float]:
    return [0.0] * max(1, int(seconds * RATE))


def concat(*parts: list[float]) -> list[float]:
    out: list[float] = []
    for part in parts:
        out.extend(part)
    return out


def repeat(part: list[float], times: int) -> list[float]:
    out: list[float] = []
    for _ in range(times):
        out.extend(part)
    return out


def mix(*parts: list[float]) -> list[float]:
    n = max(len(p) for p in parts)
    out = [0.0] * n
    for part in parts:
        for i, sample in enumerate(part):
            out[i] += sample
    return out


def fade_noise(seconds: float, volume: float = 0.12) -> list[float]:
    n = max(1, int(seconds * RATE))
    seed = 1234567
    out = []
    for i in range(n):
        seed = (1103515245 * seed + 12345) & 0x7FFFFFFF
        noise = ((seed / 0x7FFFFFFF) * 2.0) - 1.0
        out.append(noise * volume * env(i, n, 0.004, 0.18))
    return out


def message_default() -> list[float]:
    return concat(
        tone(880, 0.07, 0.9, 0.004, 0.05),
        tone(1320, 0.11, 0.7, 0.004, 0.08),
        silence(0.04),
    )


def message_soft() -> list[float]:
    return concat(tone(660, 0.16, 0.45, 0.02, 0.12), silence(0.04))


def message_pop() -> list[float]:
    return concat(
        mix(tone(180, 0.05, 0.55, 0.001, 0.04), fade_noise(0.05, 0.18)),
        tone(980, 0.08, 0.7, 0.002, 0.07),
        silence(0.03),
    )


def message_chime() -> list[float]:
    return concat(
        tone(523.25, 0.14, 0.7, 0.01, 0.12),
        tone(783.99, 0.22, 0.55, 0.01, 0.18),
        silence(0.05),
    )


def ringtone_classic() -> list[float]:
    burst = dual(440, 480, 0.38, 0.85)
    gap = silence(0.12)
    cycle = concat(burst, gap, burst, silence(0.55))
    return repeat(cycle, 4)


def ringtone_default() -> list[float]:
    phrase = concat(
        tone(659.25, 0.16, 0.8, 0.01, 0.05),
        tone(783.99, 0.16, 0.8, 0.01, 0.05),
        tone(987.77, 0.22, 0.85, 0.01, 0.08),
        silence(0.12),
        tone(880.0, 0.16, 0.75, 0.01, 0.05),
        tone(659.25, 0.28, 0.7, 0.01, 0.12),
        silence(0.35),
    )
    return repeat(phrase, 3)


def ringtone_pride() -> list[float]:
    notes = [523.25, 587.33, 659.25, 783.99, 880.0, 987.77]
    phrase: list[float] = []
    for freq in notes:
        phrase.extend(tone(freq, 0.11, 0.72, 0.008, 0.04))
    phrase.extend(silence(0.08))
    for freq in reversed(notes[1:-1]):
        phrase.extend(tone(freq, 0.09, 0.62, 0.008, 0.04))
    phrase.extend(silence(0.28))
    return repeat(phrase, 3)


def call_ringback() -> list[float]:
    return concat(dual(440, 480, 2.0, 0.7), silence(4.0))


def call_busy() -> list[float]:
    burst = concat(dual(480, 620, 0.45, 0.7), silence(0.45))
    return repeat(burst, 3)


def call_end() -> list[float]:
    return concat(
        tone(740, 0.12, 0.55, 0.01, 0.06),
        tone(554, 0.12, 0.5, 0.01, 0.06),
        tone(370, 0.22, 0.45, 0.01, 0.16),
        silence(0.05),
    )


def call_connect() -> list[float]:
    return concat(
        tone(523.25, 0.09, 0.55, 0.008, 0.05),
        tone(783.99, 0.16, 0.7, 0.008, 0.12),
        silence(0.04),
    )


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    sounds = root / "assets" / "sounds"
    raw = root / "android" / "app" / "src" / "main" / "res" / "raw"

    files = {
        "message_default.wav": message_default(),
        "message_soft.wav": message_soft(),
        "message_pop.wav": message_pop(),
        "message_chime.wav": message_chime(),
        "ringtone_default.wav": ringtone_default(),
        "ringtone_pride.wav": ringtone_pride(),
        "ringtone_classic.wav": ringtone_classic(),
        "call_ringback.wav": call_ringback(),
        "call_busy.wav": call_busy(),
        "call_end.wav": call_end(),
        "call_connect.wav": call_connect(),
    }

    for name, samples in files.items():
        scaled = [s * AMP for s in samples]
        dest = sounds / name
        write_wav(dest, scaled)
        print(f"wrote {dest} ({len(scaled) / RATE:.2f}s)")

    for name in (
        "ringtone_default.wav",
        "ringtone_pride.wav",
        "ringtone_classic.wav",
        "message_default.wav",
        "message_soft.wav",
        "message_pop.wav",
        "message_chime.wav",
    ):
        src = sounds / name
        dest = raw / name
        dest.write_bytes(src.read_bytes())
        print(f"copied {dest.name} -> res/raw")


if __name__ == "__main__":
    main()
