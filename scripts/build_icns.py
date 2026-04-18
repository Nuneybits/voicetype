#!/usr/bin/env python3

from __future__ import annotations

import struct
import subprocess
import sys
import tempfile
from pathlib import Path


ICON_TYPES = {
    16: "icp4",
    32: "icp5",
    64: "icp6",
    128: "ic07",
    256: "ic08",
    512: "ic09",
    1024: "ic10",
}


def render_png(source: Path, destination: Path, size: int) -> None:
    subprocess.run(
        [
            "sips",
            "-z",
            str(size),
            str(size),
            str(source),
            "--out",
            str(destination),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def build_icns(source: Path, destination: Path) -> None:
    chunks: list[bytes] = []

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir_path = Path(tmpdir)
        for size, chunk_type in ICON_TYPES.items():
            png_path = tmpdir_path / f"{size}.png"
            render_png(source, png_path, size)
            png_bytes = png_path.read_bytes()
            chunk = chunk_type.encode("ascii") + struct.pack(">I", len(png_bytes) + 8) + png_bytes
            chunks.append(chunk)

    payload = b"".join(chunks)
    icns = b"icns" + struct.pack(">I", len(payload) + 8) + payload
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(icns)


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: build_icns.py <source-png> <destination-icns>", file=sys.stderr)
        return 1

    source = Path(sys.argv[1])
    destination = Path(sys.argv[2])

    if not source.exists():
        print(f"source not found: {source}", file=sys.stderr)
        return 1

    build_icns(source, destination)
    print(f"wrote {destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
