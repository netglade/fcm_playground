#!/usr/bin/env python3
"""Generate res/raw/chime.wav, the sound d5_custom_sound plays.

Generated rather than sourced: no licence question, byte-identical on repeated
runs on the same machine, and a reader can see exactly what it is. Not
guaranteed byte-identical across different machines or platforms — that rests
on libm's sin() agreeing to the last bit, which the IEEE 754 standard does not
require. Run from apps/fcm_app:

    python3 tool/generate_chime.py

Two descending notes with a short decay, which is distinguishable from every
stock Android notification sound without being unpleasant. Mono 22.05 kHz
16-bit PCM, about 0.6 s and under 30 kB — small enough to sit in the repo.
"""

import math
import struct
import wave
from pathlib import Path

RATE = 22050
NOTES = ((988.0, 0.22), (659.0, 0.38))  # B5 then E5, in seconds
AMPLITUDE = 0.55
OUTPUT = Path(__file__).resolve().parent.parent / "android/app/src/main/res/raw/chime.wav"


def note(frequency: float, seconds: float) -> list[int]:
    """One note, faded out so the join between the two does not click."""
    total = int(RATE * seconds)
    samples = []
    for index in range(total):
        t = index / RATE
        decay = (1.0 - index / total) ** 2.2
        value = AMPLITUDE * decay * math.sin(2.0 * math.pi * frequency * t)
        samples.append(int(max(-1.0, min(1.0, value)) * 32767))
    return samples


def main() -> None:
    samples: list[int] = []
    for frequency, seconds in NOTES:
        samples.extend(note(frequency, seconds))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(struct.pack("<h", s) for s in samples))

    print(f"wrote {OUTPUT} ({OUTPUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
