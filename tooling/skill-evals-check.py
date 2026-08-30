#!/usr/bin/env python3
"""Schema-check evals/<skill>/ for every skill. Prints path:skill-evals:detail. Exit 1 on findings."""
from __future__ import annotations

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILLS = os.path.join(ROOT, "skills")
PLUGINS = os.path.join(ROOT, "plugins")
EVALS = os.path.join(ROOT, "evals")
FINDINGS = 0


def fail(path: str, detail: str) -> None:
    global FINDINGS
    print(f"{path}:skill-evals:{detail}")
    FINDINGS += 1


def check_skill(skill_dir: str, name: str) -> None:
    suite = os.path.join(EVALS, name)
    if os.path.isdir(os.path.join(skill_dir, "evals")):
        fail(os.path.join(skill_dir, "evals"), "evals/ must not live inside a skill; use evals/<skill>/")
    path = os.path.join(suite, "evals.json")
    if not os.path.isfile(path):
        fail(suite, "missing evals.json")
        return
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
    except json.JSONDecodeError as exc:
        fail(path, f"invalid JSON: {exc}")
        return
    if data.get("skill_name") != name:
        fail(path, f"skill_name '{data.get('skill_name')}' != directory '{name}'")
    evals = data.get("evals")
    if not isinstance(evals, list) or len(evals) < 2:
        fail(path, "need at least two evals")
        return
    ids: list[int] = []
    for i, ev in enumerate(evals):
        if not isinstance(ev, dict):
            fail(path, f"eval[{i}] is not an object")
            continue
        eid = ev.get("id")
        if not isinstance(eid, int):
            fail(path, f"eval[{i}] id must be an integer")
        else:
            ids.append(eid)
        if not ev.get("prompt"):
            fail(path, f"eval id {eid} missing prompt")
        if not ev.get("expected_output"):
            fail(path, f"eval id {eid} missing expected_output")
        assertions = ev.get("assertions") or ev.get("expectations") or []
        if not assertions:
            fail(path, f"eval id {eid} missing assertions")
        for src in ev.get("files") or []:
            fp = os.path.join(suite, src)
            if not os.path.isfile(fp):
                fail(path, f"listed source missing: {src}")
    if len(ids) != len(set(ids)):
        fail(path, "duplicate eval ids")

    qpath = os.path.join(suite, "eval_queries.json")
    if not os.path.isfile(qpath):
        fail(suite, "missing eval_queries.json")
        return
    try:
        with open(qpath, encoding="utf-8") as fh:
            queries = json.load(fh)
    except json.JSONDecodeError as exc:
        fail(qpath, f"invalid JSON: {exc}")
        return
    if not isinstance(queries, list):
        fail(qpath, "must be a JSON array")
        return
    for i, item in enumerate(queries):
        if not isinstance(item, dict) or not item.get("query"):
            fail(qpath, f"item {i} missing query")
        if not isinstance(item.get("should_trigger"), bool):
            fail(qpath, f"item {i} should_trigger must be boolean")
    if len(queries) < 8:
        fail(qpath, f"need at least 8 trigger queries (have {len(queries)})")
    n_yes = sum(1 for q in queries if isinstance(q, dict) and q.get("should_trigger") is True)
    n_no = sum(1 for q in queries if isinstance(q, dict) and q.get("should_trigger") is False)
    if n_yes < 3 or n_no < 3:
        fail(qpath, f"need at least 3 should_trigger true and 3 false (have {n_yes}/{n_no})")


def skill_dirs() -> list[tuple[str, str]]:
    out: list[tuple[str, str]] = []
    if os.path.isdir(SKILLS):
        for entry in sorted(os.listdir(SKILLS)):
            d = os.path.join(SKILLS, entry)
            if os.path.isdir(d) and os.path.isfile(os.path.join(d, "SKILL.md")):
                out.append((d, entry))
    if os.path.isdir(PLUGINS):
        for plugin in sorted(os.listdir(PLUGINS)):
            pskills = os.path.join(PLUGINS, plugin, "skills")
            if not os.path.isdir(pskills):
                continue
            for entry in sorted(os.listdir(pskills)):
                d = os.path.join(pskills, entry)
                if os.path.isdir(d) and os.path.isfile(os.path.join(d, "SKILL.md")):
                    out.append((d, entry))
    return out


def main() -> int:
    for skill_dir, name in skill_dirs():
        check_skill(skill_dir, name)
    return 1 if FINDINGS else 0


if __name__ == "__main__":
    sys.exit(main())
