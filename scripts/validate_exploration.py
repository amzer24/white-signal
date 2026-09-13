"""Run gameplay checks with disposable user data and reject engine script errors."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile

TESTS = (
    "opening_playthrough_test", "wire_first_playthrough_test",
    "fourth_route_test", "fracture_routes_test", "menu_transition_test", "map_revisit_test",
    "exploration_settings_test", "keyboard_movement_test", "save_recovery_test", "pump_motor_test",
)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("godot")
    parser.add_argument("--tests", nargs="+", choices=TESTS, default=TESTS)
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    godot = str(Path(args.godot).resolve())
    logs = project / "test-user" / "ci-exploration"
    logs.mkdir(parents=True, exist_ok=True)
    failed = []
    for name in args.tests:
        with tempfile.TemporaryDirectory(prefix="white-signal-check-") as isolated:
            env = os.environ.copy()
            for key in ("APPDATA", "XDG_DATA_HOME", "XDG_CONFIG_HOME"):
                env[key] = isolated
            env.pop("WS_TEST", None)
            command = [godot, "--headless", "--fixed-fps", "60", "--path",
                       str(project), "--script", f"res://scripts/{name}.gd"]
            try:
                result = subprocess.run(command, env=env, capture_output=True,
                                        timeout=120, encoding="utf-8", errors="replace")
                output = result.stdout + result.stderr
                ok = result.returncode == 0 and not re.search(
                    r"SCRIPT ERROR:|Parse Error:|Assertion failed|^FAIL\b", output, re.M)
            except subprocess.TimeoutExpired as error:
                output = "TIMEOUT after 120 seconds\n" + str(error.stdout or "") + str(error.stderr or "")
                ok = False
            (logs / f"{name}.log").write_text(output, encoding="utf-8")
            print(f"{'PASS' if ok else 'FAIL'} {name}", flush=True)
            if not ok:
                failed.append(name)
                print(output[-4000:], flush=True)
    print(f"EXPLORATION VALIDATION: {len(failed)} failures", flush=True)
    return bool(failed)


if __name__ == "__main__":
    raise SystemExit(main())
