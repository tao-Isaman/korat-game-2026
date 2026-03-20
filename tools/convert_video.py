#!/usr/bin/env python3
"""Convert MP4 videos to OGV (Theora) format for Godot 4.
Uses Docker (linuxserver/ffmpeg) since macOS ffmpeg lacks libtheora.

Usage:
    python3 tools/convert_video.py data/scene_1/video.mp4
    python3 tools/convert_video.py data/scene_1/video.mp4 -q 7
    python3 tools/convert_video.py data/scene_1/*.mp4
    python3 tools/convert_video.py data/scene_1/video.mp4 --delete-original
"""

import argparse
import subprocess
import sys
from pathlib import Path


def convert(input_path: Path, quality: int = 7, delete_original: bool = False) -> bool:
    output_path = input_path.with_suffix(".ogv")

    if output_path.exists():
        print(f"  SKIP  {output_path.name} (already exists)")
        return True

    # Mount the parent directory into Docker
    mount_dir = input_path.parent.resolve()
    input_name = input_path.name
    output_name = output_path.name

    cmd = [
        "docker", "run", "--rm",
        "-v", f"{mount_dir}:/data",
        "linuxserver/ffmpeg",
        "-i", f"/data/{input_name}",
        "-c:v", "libtheora", "-q:v", str(quality),
        "-c:a", "libvorbis", "-q:a", "5",
        f"/data/{output_name}",
    ]

    print(f"  CONVERT  {input_path} -> {output_path.name}")
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        print(f"  ERROR  {result.stderr[-200:]}")
        return False

    # Verify output
    if not output_path.exists() or output_path.stat().st_size == 0:
        print(f"  ERROR  Output file is empty or missing")
        return False

    in_size = input_path.stat().st_size / 1024 / 1024
    out_size = output_path.stat().st_size / 1024 / 1024
    print(f"  OK  {in_size:.1f}MB -> {out_size:.1f}MB")

    if delete_original:
        input_path.unlink()
        print(f"  DELETED  {input_path.name}")

    return True


def main():
    parser = argparse.ArgumentParser(description="Convert MP4 to OGV for Godot 4")
    parser.add_argument("files", nargs="+", help="MP4 files to convert")
    parser.add_argument("-q", "--quality", type=int, default=7, help="Video quality 0-10 (default: 7)")
    parser.add_argument("--delete-original", action="store_true", help="Delete MP4 after conversion")
    args = parser.parse_args()

    # Check Docker is running
    check = subprocess.run(["docker", "info"], capture_output=True)
    if check.returncode != 0:
        print("ERROR: Docker is not running. Start OrbStack/Docker first.")
        sys.exit(1)

    files = [Path(f) for f in args.files]
    ok = 0
    fail = 0

    for f in files:
        if not f.exists():
            print(f"  NOT FOUND  {f}")
            fail += 1
            continue
        if f.suffix.lower() != ".mp4":
            print(f"  SKIP  {f.name} (not MP4)")
            continue
        if convert(f, args.quality, args.delete_original):
            ok += 1
        else:
            fail += 1

    print(f"\nDone: {ok} converted, {fail} failed")


if __name__ == "__main__":
    main()
