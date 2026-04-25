#!/usr/bin/env python3
"""Regenerate the ambience beds used by the public preview slice.

These loops are built from ffmpeg's local signal generators only so the
preview can ship with lawful, redistributable atmosphere beds.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


SAMPLE_RATE = 48_000
DEFAULT_DURATION = 180


TRACKS = {
    "ambient_threshold": {
        "output": "assets/audio/ambient_threshold_air.ogg",
        "inputs": [
            "anoisesrc=color=pink:sample_rate={sample_rate}:duration={duration}:amplitude=0.8",
            "anoisesrc=color=white:sample_rate={sample_rate}:duration={duration}:amplitude=0.2",
            "sine=frequency=82.4:sample_rate={sample_rate}:duration={duration}",
            "sine=frequency=659.25:sample_rate={sample_rate}:duration={duration}",
            "sine=frequency=988.88:sample_rate={sample_rate}:duration={duration}",
        ],
        "filter": (
            "[0:a]lowpass=f=920,highpass=f=70,volume=0.085[aair];"
            "[1:a]bandpass=f=2500:w=1500,volume=0.0038[shimmer];"
            "[2:a]lowpass=f=160,volume=0.013[drone];"
            "[3:a]volume='if(lt(mod(t+0.7,11.3),0.10),0.0125*(1-mod(t+0.7,11.3)/0.10),0)',"
            "aecho=0.7:0.85:130|260|480:0.25|0.18|0.10[tink1];"
            "[4:a]volume='if(lt(mod(t+4.4,17.1),0.08),0.010*(1-mod(t+4.4,17.1)/0.08),0)',"
            "aecho=0.7:0.88:150|330|650:0.20|0.14|0.08[tink2];"
            "[aair][shimmer][drone][tink1][tink2]amix=inputs=5:normalize=0,"
            "alimiter=limit=0.92,atrim=end={duration},"
            "afade=t=in:st=0:d=4,afade=t=out:st={fade_out}:d=4"
        ),
    },
    "ambient_garden": {
        "output": "assets/audio/ambient_garden_water.ogg",
        "inputs": [
            "anoisesrc=color=pink:sample_rate={sample_rate}:duration={duration}:amplitude=0.7",
            "anoisesrc=color=brown:sample_rate={sample_rate}:duration={duration}:amplitude=0.4",
            "anoisesrc=color=white:sample_rate={sample_rate}:duration={duration}:amplitude=0.18",
            "sine=frequency=784.0:sample_rate={sample_rate}:duration={duration}",
            "sine=frequency=1174.66:sample_rate={sample_rate}:duration={duration}",
        ],
        "filter": (
            "[0:a]lowpass=f=1900,highpass=f=150,volume=0.082[water];"
            "[1:a]lowpass=f=420,volume=0.018[depth];"
            "[2:a]highpass=f=2600,lowpass=f=6800,volume=0.0046[rustle];"
            "[3:a]volume='if(lt(mod(t+0.9,5.7),0.035),0.019*(1-mod(t+0.9,5.7)/0.035),0)',"
            "aecho=0.7:0.82:90|190|360:0.28|0.17|0.09[drop1];"
            "[4:a]volume='if(lt(mod(t+2.8,8.9),0.025),0.013*(1-mod(t+2.8,8.9)/0.025),0)',"
            "aecho=0.7:0.86:120|260|480:0.22|0.14|0.08[drop2];"
            "[water][depth][rustle][drop1][drop2]amix=inputs=5:normalize=0,"
            "alimiter=limit=0.92,atrim=end={duration},"
            "afade=t=in:st=0:d=4,afade=t=out:st={fade_out}:d=4"
        ),
    },
    "ambient_osservatorio": {
        "output": "assets/audio/ambient_osservatorio_metal.ogg",
        "inputs": [
            "anoisesrc=color=pink:sample_rate={sample_rate}:duration={duration}:amplitude=0.55",
            "anoisesrc=color=brown:sample_rate={sample_rate}:duration={duration}:amplitude=0.25",
            "anoisesrc=color=white:sample_rate={sample_rate}:duration={duration}:amplitude=0.20",
            "sine=frequency=466.16:sample_rate={sample_rate}:duration={duration}",
            "sine=frequency=698.46:sample_rate={sample_rate}:duration={duration}",
        ],
        "filter": (
            "[0:a]highpass=f=260,lowpass=f=2400,volume=0.050[air];"
            "[1:a]lowpass=f=260,volume=0.016[bed];"
            "[2:a]bandpass=f=3400:w=1800,volume=0.0055[friction];"
            "[3:a]volume='if(lt(mod(t+1.6,7.3),0.060),0.011*(1-mod(t+1.6,7.3)/0.060),0)',"
            "aecho=0.7:0.84:140|310|620:0.24|0.15|0.08[metal1];"
            "[4:a]volume='if(lt(mod(t+4.9,12.7),0.045),0.0085*(1-mod(t+4.9,12.7)/0.045),0)',"
            "aecho=0.7:0.88:170|380|760:0.20|0.12|0.07[metal2];"
            "[air][bed][friction][metal1][metal2]amix=inputs=5:normalize=0,"
            "alimiter=limit=0.92,atrim=end={duration},"
            "afade=t=in:st=0:d=4,afade=t=out:st={fade_out}:d=4"
        ),
    },
}


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Regenerate the ambience beds for the public preview."
    )
    parser.add_argument(
        "--duration",
        type=int,
        default=DEFAULT_DURATION,
        help="Loop duration in seconds before the graceful tail fade.",
    )
    parser.add_argument(
        "--only",
        choices=sorted(TRACKS.keys()),
        action="append",
        help="Generate only the selected ambience key(s).",
    )
    args = parser.parse_args()

    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
      print("ffmpeg is required but was not found on PATH.", file=sys.stderr)
      return 1

    repo_root = Path(__file__).resolve().parents[1]
    duration = max(args.duration, 16)
    fade_out = duration - 4
    keys = args.only or list(TRACKS.keys())

    for key in keys:
        spec = TRACKS[key]
        output = repo_root / spec["output"]
        output.parent.mkdir(parents=True, exist_ok=True)
        build_track(
            ffmpeg=ffmpeg,
            output=output,
            inputs=spec["inputs"],
            filter_complex=spec["filter"].format(
                duration=duration,
                fade_out=fade_out,
            ),
            duration=duration,
        )
        print(f"generated {output.relative_to(repo_root)}")

    return 0


def build_track(
    *,
    ffmpeg: str,
    output: Path,
    inputs: list[str],
    filter_complex: str,
    duration: int,
) -> None:
    cmd = [ffmpeg, "-y"]
    for input_spec in inputs:
        cmd.extend(
            [
                "-f",
                "lavfi",
                "-i",
                input_spec.format(sample_rate=SAMPLE_RATE, duration=duration),
            ]
        )
    cmd.extend(
        [
            "-filter_complex",
            filter_complex,
            "-ac",
            "1",
            "-c:a",
            "libvorbis",
            str(output),
        ]
    )
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


if __name__ == "__main__":
    raise SystemExit(main())
