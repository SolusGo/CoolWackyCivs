"""Run the combined package and all four civilization validation suites."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SCRIPTS = (
    "validate_mod.py",
    "validate_luna_mod.py",
    "validate_terra_mod.py",
    "validate_capano_mod.py",
)


def main() -> None:
    for script in SCRIPTS:
        print(f"\n=== {script} ===", flush=True)
        subprocess.run([sys.executable, str(REPO / "tools" / script)], cwd=REPO, check=True)
    print("\nAll Cool Wacky Civs validation suites passed.")


if __name__ == "__main__":
    main()
