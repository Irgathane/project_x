#!/usr/bin/env python3
"""Smoke tests for slipgate, driven through real client input.

Run:  python3 tests/test_smoke.py
Each test launches the engine (~2-4s), scripts input, and asserts on the
resulting trace. No source changes are needed to add a test -- just new
frames and new assertions.
"""

import sys
import traceback

sys.path.insert(0, __file__.rsplit("/", 1)[0])

import runner
from runner import BUTTON_ATTACK, BUTTON_JUMP, hold, run, seconds, turn


def test_spawns_and_idles():
    """The map loads and the player exists without engine errors."""
    result = run(hold(20))
    result.assert_no_engine_errors()
    result.assert_frames(10)
    assert result.last["health"] > 0, f"player has no health: {result.last}"
    return f"{len(result.rows)} frames, health={result.last['health']:.0f}"


def test_look_around():
    """Turning is applied: yaw reaches the scripted angle and we stay put."""
    frames = turn(20, 0.0, 90.0)
    result = run(frames)
    result.assert_no_engine_errors()
    result.assert_frames(10)
    assert abs(result.yaw - 90.0) < 2.0, f"yaw ended at {result.yaw:.1f}, expected 90"
    moved = result.horizontal_distance()
    assert moved < 5.0, f"player drifted {moved:.1f} units while only turning"
    return f"yaw=90, drift={moved:.2f}u"


def test_walk_forward():
    """Forward movement moves the player along -X at yaw 0."""
    frames = hold(seconds(1.5), forward=320.0)
    result = run(frames)
    result.assert_no_engine_errors()
    result.assert_frames(10)
    moved = result.horizontal_distance()
    assert moved > 100.0, f"player only moved {moved:.1f} units in 1.5s"
    return f"moved {moved:.1f}u in 1.5s"


def test_walk_right_strafes():
    """Strafing reaches normal ground speed.

    Asserts on velocity rather than distance: the starter map is small enough
    that a strafe can hit a wall within a second, which would make a distance
    threshold a map-layout test instead of an input test.
    """
    frames = hold(3) + hold(seconds(1.0), side=320.0)
    result = run(frames)
    result.assert_no_engine_errors()
    result.assert_frames(10)
    peak = result.peak_horizontal_speed()
    assert peak > 250.0, f"strafe only reached {peak:.0f} u/s"
    moved = result.displacement(3, -1)
    assert moved > 20.0, f"strafe moved only {moved:.1f}u"
    return f"peak {peak:.0f} u/s, moved {moved:.1f}u"


def test_jump_leaves_ground():
    """Jumping raises the player above the spawn height, then lands."""
    frames = hold(5) + hold(seconds(0.6), buttons=BUTTON_JUMP) + hold(seconds(1.2))
    result = run(frames)
    result.assert_no_engine_errors()
    result.assert_frames(10)
    gain = result.max_height_gain()
    assert gain > 10.0, f"jump only raised the player {gain:.1f} units"
    landed = result.last["onground"]
    assert landed == 1, "player did not land again"
    return f"rose {gain:.1f}u and landed"


def test_shooting_spends_ammo():
    """Holding attack consumes shells (slipgate has a single weapon: shotgun)."""
    frames = hold(5) + hold(seconds(1.5), buttons=BUTTON_ATTACK)
    result = run(frames)
    result.assert_no_engine_errors()
    result.assert_frames(10)
    assert result.last["weapon"] == 1, (
        f"expected the shotgun (weapon 1), got {result.last['weapon']:.0f}"
    )
    spent = result.max_ammo() - result.min_ammo()
    assert spent > 0, (
        f"no ammo consumed while holding attack "
        f"(shells stayed at {result.max_ammo():.0f})"
    )
    return f"spent {spent:.0f} shells"


def test_dry_fire_costs_nothing():
    """With no shells left, attacking must not drain ammo below zero."""
    frames = hold(5) + hold(seconds(4.0), buttons=BUTTON_ATTACK)
    result = run(frames)
    result.assert_no_engine_errors()
    result.assert_frames(10)
    assert result.min_ammo() >= 0, f"ammo went negative: {result.min_ammo():.0f}"
    return f"floor={result.min_ammo():.0f}"


TESTS = [
    test_spawns_and_idles,
    test_look_around,
    test_walk_forward,
    test_walk_right_strafes,
    test_jump_leaves_ground,
    test_shooting_spends_ammo,
    test_dry_fire_costs_nothing,
]


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else None
    selected = [t for t in TESTS if not only or only in t.__name__]
    failures = 0

    for test in selected:
        try:
            detail = test()
            print(f"  PASS  {test.__name__}  ({detail})")
        except AssertionError as exc:
            failures += 1
            print(f"  FAIL  {test.__name__}\n        {exc}")
        except Exception:
            failures += 1
            print(f"  ERROR {test.__name__}")
            traceback.print_exc()

    print(f"\n{len(selected) - failures}/{len(selected)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())