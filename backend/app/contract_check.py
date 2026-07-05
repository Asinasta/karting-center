"""BE-01 contract check: every OpenAPI operationId must exist as a route.

Compares operationId + (method, path) declared in 01-analysis/api against the
routes registered on the FastAPI app. Path params are normalized so that
{slotId} and {slot_id} compare equal.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
API_DIR = REPO_ROOT / "01-analysis" / "api"
HTTP_METHODS = {"get", "post", "put", "patch", "delete"}

_PARAM_RE = re.compile(r"\{[^}]+\}")


def _normalize_path(path: str) -> str:
    return _PARAM_RE.sub("{}", path)


def _load_contract_operations() -> dict[str, tuple[str, str]]:
    registry = yaml.safe_load((API_DIR / "redocly.yaml").read_text(encoding="utf-8"))
    operations: dict[str, tuple[str, str]] = {}
    for api in registry.get("apis", {}).values():
        root = API_DIR / api["root"]
        doc = yaml.safe_load(root.read_text(encoding="utf-8"))
        for path, item in (doc.get("paths") or {}).items():
            for method, op in item.items():
                if method.lower() not in HTTP_METHODS:
                    continue
                op_id = op.get("operationId")
                if not op_id:
                    continue
                operations[op_id] = (method.lower(), _normalize_path(path))
    return operations


def _load_app_operations() -> dict[str, set[tuple[str, str]]]:
    from .main import create_app

    app = create_app()
    result: dict[str, set[tuple[str, str]]] = {}
    generated = app.openapi()
    for path, item in (generated.get("paths") or {}).items():
        for method, op in item.items():
            if method.lower() not in HTTP_METHODS:
                continue
            op_id = op.get("operationId")
            if not op_id:
                continue
            result.setdefault(op_id, set()).add((method.lower(), _normalize_path(path)))
    return result


def run() -> int:
    contract = _load_contract_operations()
    app_ops = _load_app_operations()

    problems: list[str] = []

    for op_id, (method, path) in contract.items():
        if op_id not in app_ops:
            problems.append(f"MISSING route for operationId '{op_id}' ({method.upper()} {path})")
            continue
        if (method, path) not in app_ops[op_id]:
            problems.append(
                f"MISMATCH '{op_id}': contract={method.upper()} {path}, app={app_ops[op_id]}"
            )

    contract_ids = set(contract)
    for op_id in app_ops:
        if op_id not in contract_ids:
            problems.append(f"EXTRA route operationId '{op_id}' not present in OpenAPI")

    if problems:
        print("Contract check FAILED:")
        for p in problems:
            print(f"  - {p}")
        return 1

    print(f"Contract check OK: {len(contract)} operations match the app routes.")
    return 0


if __name__ == "__main__":
    sys.exit(run())
