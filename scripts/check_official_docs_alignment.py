#!/usr/bin/env python3
from __future__ import annotations

import argparse
import ast
import html
import json
import re
import sys
import tomllib
import urllib.request
from dataclasses import dataclass
from importlib.metadata import PackageNotFoundError, version
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
WATCHLIST = ROOT / "docs/verification/official-docs-watchlist.json"
MAIN_SECTION = re.compile(r"^0[1-6]_")
LEGACY_LINKS = (
    "https://python.langchain.com/docs/tutorials/rag/",
    "https://python.langchain.com/docs/tutorials/sql_qa/",
)
CURRENT_LINKS = (
    "https://docs.langchain.com/oss/python/langchain/rag",
    "https://docs.langchain.com/oss/python/langchain/sql-agent",
)


@dataclass(frozen=True, order=True)
class Violation:
    code: str
    path: str
    detail: str

    def __str__(self) -> str:
        return f"[{self.code}] {self.path}: {self.detail}"


def _cell_source(cell: dict) -> str:
    source = cell.get("source", "")
    return "".join(source) if isinstance(source, list) else str(source)


def _python_from_ipython(source: str) -> str:
    lines = source.splitlines()
    if lines and lines[0].lstrip().startswith("%%"):
        return "pass\n"

    transformed: list[str] = []
    for line in lines:
        stripped = line.lstrip()
        if stripped.startswith(("%", "!", "?")) or stripped.endswith("?"):
            indent = line[: len(line) - len(stripped)]
            transformed.append(f"{indent}pass")
        else:
            transformed.append(line)
    return "\n".join(transformed) + "\n"


def validate_notebook(path: Path, *, display_path: str | None = None) -> list[Violation]:
    shown = display_path or path.as_posix()
    try:
        notebook = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        return [Violation("notebook-json", shown, str(exc))]

    cells = notebook.get("cells")
    if not isinstance(cells, list):
        return [Violation("notebook-cells", shown, "top-level cells must be a list")]

    violations: list[Violation] = []
    for index, cell in enumerate(cells):
        expected_id = f"cell-{index}"
        actual_id = cell.get("id")
        if actual_id != expected_id:
            violations.append(
                Violation(
                    "notebook-cell-id",
                    shown,
                    f"cell {index} has id {actual_id!r}; expected {expected_id!r}",
                )
            )

        if cell.get("cell_type") != "code":
            continue

        source = _cell_source(cell)
        try:
            ast.parse(_python_from_ipython(source), filename=f"{shown}#{expected_id}")
        except SyntaxError as exc:
            violations.append(
                Violation(
                    "notebook-code-syntax",
                    shown,
                    f"{expected_id} line {exc.lineno}: {exc.msg}",
                )
            )

        for output in cell.get("outputs", []):
            if output.get("output_type") == "error":
                name = output.get("ename", "Error")
                value = output.get("evalue", "")
                violations.append(
                    Violation(
                        "notebook-error-output",
                        shown,
                        f"{expected_id} stores {name}: {value}",
                    )
                )
    return violations


def iter_main_notebooks(root: Path) -> Iterable[tuple[Path, str]]:
    for prefix in (root, root / "en"):
        if not prefix.is_dir():
            continue
        for section in sorted(prefix.iterdir()):
            if not section.is_dir() or not MAIN_SECTION.match(section.name):
                continue
            for notebook in sorted(section.glob("*.ipynb")):
                yield notebook, notebook.relative_to(root).as_posix()


def _read(root: Path, relative: str) -> str:
    return (root / relative).read_text(encoding="utf-8")


def _contains_interrupt_loop(path: Path, text: str) -> bool:
    if path.suffix == ".ipynb":
        notebook = json.loads(text)
        code = [
            _cell_source(cell)
            for cell in notebook.get("cells", [])
            if cell.get("cell_type") == "code"
        ]
    else:
        code = re.findall(r"```python\s+(.*?)```", text, flags=re.S)
    return any("while True" in source and "interrupt(" in source for source in code)


def _scan_legacy_links(root: Path) -> list[Violation]:
    violations: list[Violation] = []
    roots = [
        path
        for path in (*root.glob("0[1-7]_*"), *(root / "en").glob("0[1-7]_*"))
        if path.is_dir()
    ]
    for base in roots:
        for path in base.rglob("*"):
            if path.suffix not in {".ipynb", ".md", ".py", ".typ"}:
                continue
            text = path.read_text(encoding="utf-8")
            for link in LEGACY_LINKS:
                if link in text:
                    violations.append(
                        Violation(
                            "legacy-official-link",
                            path.relative_to(root).as_posix(),
                            link,
                        )
                    )
    return violations


def _check_deepagents_contract(root: Path) -> list[Violation]:
    violations: list[Violation] = []
    project = tomllib.loads(_read(root, "pyproject.toml"))
    dependencies = project.get("project", {}).get("dependencies", [])
    requirement = next((item for item in dependencies if item.startswith("deepagents")), "")
    match = re.search(r">=(\d+)\.(\d+)\.(\d+)", requirement)
    if not match or tuple(map(int, match.groups())) < (0, 6, 12):
        violations.append(
            Violation(
                "deepagents-min-version",
                "pyproject.toml",
                f"expected deepagents>=0.6.12; found {requirement or 'missing'}",
            )
        )

    lock = _read(root, "uv.lock")
    package = re.search(
        r'\[\[package\]\]\s+name = "deepagents"\s+version = "([^"]+)"',
        lock,
    )
    if not package or tuple(map(int, package.group(1).split(".")[:3])) < (0, 6, 12):
        found = package.group(1) if package else "missing"
        violations.append(
            Violation(
                "deepagents-lock-version",
                "uv.lock",
                f"expected 0.6.12 or newer; found {found}",
            )
        )

    try:
        runtime_version = version("deepagents")
    except PackageNotFoundError as exc:
        violations.append(Violation("deepagents-runtime", "environment", str(exc)))
    else:
        if package and runtime_version != package.group(1):
            violations.append(
                Violation(
                    "deepagents-runtime-version",
                    "environment",
                    f"installed {runtime_version}; lock contains {package.group(1)}",
                )
            )

    backend_docs = _read(root, "docs/deepagents/06-backends.md")
    if "0.7.0a" not in backend_docs or "0.6.12" not in backend_docs:
        violations.append(
            Violation(
                "deepagents-delete-version-gap",
                "docs/deepagents/06-backends.md",
                "distinguish stable 0.6.12 from the 0.7.0 alpha delete contract",
            )
        )
    return violations


def _check_required_contracts(root: Path) -> list[Violation]:
    violations: list[Violation] = []
    interrupt_targets = (
        "docs/langgraph/08-interrupts.md",
        "03_langgraph/08_interrupts_and_time_travel.ipynb",
        "en/03_langgraph/08_interrupts_and_time_travel.ipynb",
    )
    for relative in interrupt_targets:
        text = _read(root, relative)
        if _contains_interrupt_loop(root / relative, text):
            violations.append(
                Violation(
                    "interrupt-validation-loop",
                    relative,
                    "input validation must use one interrupt per node invocation",
                )
            )
        if "add_conditional_edges" not in text:
            violations.append(
                Violation(
                    "interrupt-validation-routing",
                    relative,
                    "conditional re-prompt routing is missing",
                )
            )

    for relative in ("05_advanced/09_production.ipynb", "en/05_advanced/09_production.ipynb"):
        text = _read(root, relative)
        if "from langgraph.prebuilt import create_react_agent" in text:
            violations.append(
                Violation(
                    "legacy-agent-factory",
                    relative,
                    "production material must use langchain.agents.create_agent",
                )
            )

    forbidden_hitl = {
        "02_langchain/07_hitl_and_runtime.ipynb": ("이미 어제 보냈으니 건너뛰세요",),
        "en/02_langchain/07_hitl_and_runtime.ipynb": ("already sent", "skip it"),
        "04_deepagents/07_advanced.ipynb": ("이미 처리됨",),
        "en/04_deepagents/07_advanced.ipynb": ("already handled",),
    }
    for relative, phrases in forbidden_hitl.items():
        text = _read(root, relative).lower()
        if any(phrase.lower() in text for phrase in phrases):
            violations.append(
                Violation(
                    "hitl-respond-side-effect",
                    relative,
                    "respond must be reserved for ask-user style tools",
                )
            )

    shell_contracts = {
        "AGENTS.md": ("LocalShellBackend", "셸 격리"),
        "docs/deepagents/06-backends.md": ("LocalShellBackend", "no sandboxing"),
        "docs/langchain/31-deep-agent-from-scratch.md": ("LocalShellBackend", "shell"),
        "07_examples/skills/data-analysis/SKILL.md": ("LocalShellBackend", "sandbox"),
    }
    for relative, anchors in shell_contracts.items():
        text = _read(root, relative)
        missing = [anchor for anchor in anchors if anchor.lower() not in text.lower()]
        if missing:
            violations.append(
                Violation(
                    "local-shell-boundary",
                    relative,
                    f"missing explicit trust-boundary anchors: {', '.join(missing)}",
                )
            )
    return violations


def check_local(root: Path = ROOT) -> list[Violation]:
    violations: list[Violation] = []
    for notebook, relative in iter_main_notebooks(root):
        violations.extend(validate_notebook(notebook, display_path=relative))
        if re.search(r"gpt-4\.1(?!-)", notebook.read_text(encoding="utf-8")):
            violations.append(
                Violation(
                    "default-model-policy",
                    relative,
                    "use gpt-5.4 for the course default; keep suffixed comparison models explicit",
                )
            )
    violations.extend(_check_required_contracts(root))
    violations.extend(_check_deepagents_contract(root))
    violations.extend(_scan_legacy_links(root))
    return sorted(set(violations))


def _visible_text(raw_html: str) -> str:
    no_scripts = re.sub(r"<(script|style).*?</\1>", " ", raw_html, flags=re.I | re.S)
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", no_scripts)))


def check_online(watchlist_path: Path = WATCHLIST) -> list[Violation]:
    data = json.loads(watchlist_path.read_text(encoding="utf-8"))
    violations: list[Violation] = []
    for page in data["pages"]:
        request = urllib.request.Request(
            page["url"],
            headers={"User-Agent": "agent-notebooks-doc-alignment/1.0"},
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                text = _visible_text(response.read().decode("utf-8", errors="replace"))
        except OSError as exc:
            violations.append(Violation("online-fetch", page["id"], str(exc)))
            continue

        lowered = text.lower()
        for group in page["required_anchor_groups"]:
            if not all(anchor.lower() in lowered for anchor in group):
                violations.append(
                    Violation(
                        "online-anchor",
                        page["id"],
                        f"missing anchor group: {group}",
                    )
                )
    return violations


def _print_result(label: str, violations: list[Violation]) -> None:
    if violations:
        print(f"{label}: FAIL ({len(violations)} violations)")
        for violation in violations:
            print(f"  {violation}")
    else:
        print(f"{label}: PASS")


def main() -> int:
    parser = argparse.ArgumentParser(description="Check course material against official contracts.")
    parser.add_argument("--local", action="store_true", help="run deterministic repository checks")
    parser.add_argument("--online", action="store_true", help="fetch official docs and check anchors")
    args = parser.parse_args()
    if not args.local and not args.online:
        parser.error("select --local, --online, or both")

    failed = False
    if args.local:
        local = check_local(ROOT)
        _print_result("local alignment", local)
        failed |= bool(local)
    if args.online:
        online = check_online(WATCHLIST)
        _print_result("online watchlist", online)
        failed |= bool(online)
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
