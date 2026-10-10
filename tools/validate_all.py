"""Run the combined seventeen-civilization package and focused validation suites."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SCRIPTS = (
    "validate_mod.py",
    "validate_modbuddy_entrypoints.py",
    "validate_luna_mod.py",
    "validate_terra_mod.py",
    "validate_capano_mod.py",
    "validate_filthy_mod.py",
    "validate_dual_order_mod.py",
    "validate_roman_gladius_mod.py",
    "validate_messi_mod.py",
    "validate_masaya_mod.py",
    "validate_psj_mod.py",
    "validate_viltrum_mod.py",
    "validate_token_mod.py",
    "validate_kingdoms_mod.py",
    "validate_sol_mod.py",
    "validate_shattered_mod.py",
    "validate_lastcity_mod.py",
    "validate_ronaldo_mod.py",
)


def main() -> None:
    for script in SCRIPTS:
        print(f"\n=== {script} ===", flush=True)
        subprocess.run([sys.executable, str(REPO / "tools" / script)], cwd=REPO, check=True)
    print("\nAll seventeen-civilization Cool Wacky Civs validation suites passed.")


if __name__ == "__main__":
    main()
