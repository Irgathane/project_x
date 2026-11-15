"""Drive QuakeSpasm with scripted input for automated gameplay tests.

The engine side lives in quakespasm/Quake/test_input.c: it replaces the
keyboard-derived usercmd with lines from a script file, and writes a CSV trace
of the local player's state every frame. This module generates those scripts,
runs the engine, and parses the trace.

Fixed `host_framerate` gives a fixed timestep, so one script line is one frame
and distances are comparable between runs.
"""

import csv
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

from dataclasses import dataclass, field

PROJECT_ROOT = Path(__file__).resolve().parent.parent
ENGINE = PROJECT_ROOT / "quakespasm" / "Quake" / "quakespasm"
GAMEDIR = "slipgate"

# 20 frames per second: small enough to keep runs short, large enough that
# movement and physics stay well-conditioned.
FRAMERATE = 0.05
FPS = int(round(1.0 / FRAMERATE))

BUTTON_ATTACK = 1
BUTTON_JUMP = 2


@dataclass
class Frame:
    """One client frame of scripted input."""

    yaw: float = 0.0
    pitch: float = 0.0
    roll: float = 0.0
    forward: float = 0.0
    side: float = 0.0
    up: float = 0.0
    buttons: int = 0
    impulse: int = 0

    def line(self):
        return (
            f"{self.yaw:.3f} {self.pitch:.3f} {self.roll:.3f} "
            f"{self.forward:.3f} {self.side:.3f} {self.up:.3f} "
            f"{self.buttons:d} {self.impulse:d}"
        )


def hold(frames, **kw):
    """Repeat one input for N frames."""
    return [Frame(**kw) for _ in range(frames)]


def turn(frames, yaw_from, yaw_to, pitch=0.0, **kw):
    """Turn linearly from yaw_from to yaw_to over N frames."""
    if frames == 1:
        return [Frame(yaw=yaw_to, pitch=pitch, **kw)]
    step = (yaw_to - yaw_from) / float(frames - 1)
    return [Frame(yaw=yaw_from + step * i, pitch=pitch, **kw) for i in range(frames)]


def seconds(value):
    """Convert a duration in seconds to whole frames."""
    return max(1, int(round(value * FPS)))


@dataclass
class Result:
    returncode: int
    stdout: str
    rows: list = field(default_factory=list)

    # -- trace accessors ---------------------------------------------------
    @property
    def first(self):
        return self.rows[0] if self.rows else None

    @property
    def last(self):
        return self.rows[-1] if self.rows else None

    def column(self, name):
        return [r[name] for r in self.rows]

    @property
    def yaw(self):
        return self._wrap(self.last["yaw"]) if self.rows else 0.0

    @staticmethod
    def _wrap(angle):
        """Normalise to (-180, 180] so 355 and -5 compare equal."""
        angle = (angle + 180.0) % 360.0 - 180.0
        return angle

    def peak_horizontal_speed(self):
        """Fastest horizontal speed reached, in units/second."""
        if not self.rows:
            return 0.0
        return max((r["vx"] ** 2 + r["vy"] ** 2) ** 0.5 for r in self.rows)

    def horizontal_distance(self):
        """Total ground distance covered, in map units."""
        return self.displacement(0, -1)

    def displacement(self, start, end=-1):
        """Straight-line distance between two trace rows."""
        if len(self.rows) < 2:
            return 0.0
        a, b = self.rows[start], self.rows[end]
        return ((b["px"] - a["px"]) ** 2 + (b["py"] - a["py"]) ** 2) ** 0.5

    def max_height_gain(self):
        if not self.rows:
            return 0.0
        start = self.rows[0]["pz"]
        return max(r["pz"] for r in self.rows) - start

    def min_ammo(self):
        keys = ("shells", "nails", "rockets", "cells")
        return min(sum(r[k] for k in keys) for r in self.rows) if self.rows else 0

    def max_ammo(self):
        keys = ("shells", "nails", "rockets", "cells")
        return max(sum(r[k] for k in keys) for r in self.rows) if self.rows else 0

    # -- assertions --------------------------------------------------------
    def assert_no_engine_errors(self):
        problems = [
            line
            for line in self.stdout.splitlines()
            if "Host_Error" in line or "PR_GetString" in line
            or line.startswith("ERROR:") or "Error:" in line and "Sys_Error" in line
        ]
        assert not problems, "engine reported errors:\n  " + "\n  ".join(problems)

    def assert_frames(self, minimum=5):
        assert len(self.rows) >= minimum, (
            f"only {len(self.rows)} trace rows, expected >= {minimum}; "
            f"engine exit {self.returncode}"
        )


def run(frames, map_name="starter", timeout=60, cvars=None):
    """Run the engine with `frames` as scripted input and return a Result."""
    if not ENGINE.exists():
        raise RuntimeError(f"engine not built: {ENGINE}")

    workdir = Path(tempfile.mkdtemp(prefix="qs-test-"))
    script = workdir / "input.txt"
    trace = workdir / "trace.csv"
    script.write_text("\n".join(f.line() for f in frames) + "\n")

    args = [
        str(ENGINE),
        "-game", GAMEDIR,
        "-window", "-width", "320", "-height", "240",
        "-nosound", "-nomouse",
        "-test_input", str(script),
        "-test_trace", str(trace),
        "-test_quit_eof",
        "-test_fps", str(FPS),
    ]
    args += ["+map", map_name]

    env = dict(os.environ)
    env.setdefault("SDL_AUDIODRIVER", "dummy")

    try:
        proc = subprocess.run(
            args,
            cwd=str(PROJECT_ROOT),
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
            text=True,
            errors="replace",
        )
        stdout, returncode = proc.stdout, proc.returncode
    except subprocess.TimeoutExpired as exc:
        stdout = (exc.stdout or b"").decode("utf-8", "replace")
        returncode = -1
        stdout += "\n[TIMEOUT] engine did not exit after script finished\n"

    rows = _read_trace(trace)
    returncode = returncode if rows else returncode
    result = Result(returncode=returncode, stdout=stdout, rows=rows)
    result._workdir = workdir
    return result


def _read_trace(path):
    if not Path(path).exists():
        return []
    rows = []
    with open(path, newline="") as handle:
        for raw in csv.DictReader(handle):
            row = {}
            for key, value in raw.items():
                if key is None:
                    continue
                try:
                    row[key] = float(value)
                except (TypeError, ValueError):
                    row[key] = value
            rows.append(row)
    return rows


def cleanup(result):
    shutil.rmtree(getattr(result, "_workdir", ""), ignore_errors=True)