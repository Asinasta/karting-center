"""Project command entry point: run / test / lint / format / contract-check.

Usage:
    python manage.py run
    python manage.py test
    python manage.py lint
    python manage.py format
    python manage.py contract-check
"""

from __future__ import annotations

import subprocess
import sys


def _run(cmd: list[str]) -> int:
    print("$", " ".join(cmd))
    return subprocess.call(cmd)


def cmd_run() -> int:
    import uvicorn

    from app.config import get_settings

    settings = get_settings()
    settings.validate_startup()
    uvicorn.run("app.main:app", host=settings.host, port=settings.port, reload=settings.is_dev)
    return 0


def cmd_test() -> int:
    return _run([sys.executable, "-m", "pytest"])


def cmd_lint() -> int:
    return _run([sys.executable, "-m", "ruff", "check", "."])


def cmd_format() -> int:
    return _run([sys.executable, "-m", "ruff", "format", "."])


def cmd_contract_check() -> int:
    from app.contract_check import run

    return run()


COMMANDS = {
    "run": cmd_run,
    "test": cmd_test,
    "lint": cmd_lint,
    "format": cmd_format,
    "contract-check": cmd_contract_check,
}


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print(f"Usage: python manage.py [{' | '.join(COMMANDS)}]")
        return 2
    return COMMANDS[sys.argv[1]]()


if __name__ == "__main__":
    raise SystemExit(main())
