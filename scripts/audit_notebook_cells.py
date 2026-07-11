#!/usr/bin/env python3
from __future__ import annotations

import argparse
import ast
import importlib
import importlib.util
import json
import re
import sys
import tomllib
from dataclasses import asdict, dataclass
from pathlib import Path
from urllib.parse import unquote, urlsplit

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from scripts.check_official_docs_alignment import (
    ROOT,
    _cell_source,
    _python_from_ipython,
    iter_main_notebooks,
    validate_notebook,
)


MARKDOWN_LINK = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
MARKDOWN_FENCE = re.compile(r"^\s*(`{3,})([^`]*)$")


@dataclass
class NotebookAudit:
    path: str
    cells: int
    code_cells: int
    markdown_cells: int
    errors: list[str]
    warnings: list[str]


def _optional_packages(root: Path) -> set[str]:
    project = tomllib.loads((root / "pyproject.toml").read_text(encoding="utf-8"))
    groups = project.get("project", {}).get("optional-dependencies", {})
    packages: set[str] = set()
    for requirements in groups.values():
        for requirement in requirements:
            package = re.split(r"[<>=!~\[]", requirement, maxsplit=1)[0]
            packages.add(package.strip().replace("-", "_"))
    return packages


def _optional_import_lines(tree: ast.AST) -> set[int]:
    lines: set[int] = set()
    for node in ast.walk(tree):
        if not isinstance(node, ast.Try):
            continue
        catches_import_error = any(
            isinstance(handler.type, ast.Name) and handler.type.id in {"ImportError", "ModuleNotFoundError"}
            for handler in node.handlers
        )
        if catches_import_error:
            for child in node.body:
                lines.update(range(child.lineno, getattr(child, "end_lineno", child.lineno) + 1))
    return lines


def _import_errors(tree: ast.AST, optional_packages: set[str]) -> list[str]:
    errors: list[str] = []
    optional_lines = _optional_import_lines(tree)
    for node in ast.walk(tree):
        if not isinstance(node, (ast.Import, ast.ImportFrom)) or node.lineno in optional_lines:
            continue

        if isinstance(node, ast.Import):
            modules = [alias.name for alias in node.names]
        elif node.level or not node.module:
            continue
        else:
            modules = [node.module]

        for module_name in modules:
            top_level = module_name.split(".")[0]
            if top_level in optional_packages:
                continue
            try:
                spec = importlib.util.find_spec(top_level)
            except (ImportError, ValueError):
                spec = None
            if spec is None:
                errors.append(f"missing module {top_level!r}")
                continue

            if not isinstance(node, ast.ImportFrom):
                continue
            try:
                module = importlib.import_module(node.module)
            except Exception:
                continue
            for alias in node.names:
                if alias.name == "*" or hasattr(module, alias.name):
                    continue
                try:
                    submodule = importlib.util.find_spec(f"{node.module}.{alias.name}")
                except (ImportError, ModuleNotFoundError, ValueError):
                    submodule = None
                if submodule is None:
                    errors.append(f"missing symbol {node.module}.{alias.name}")
    return errors


def _broken_links(path: Path, source: str) -> list[str]:
    errors: list[str] = []
    for raw_target in MARKDOWN_LINK.findall(source):
        target = raw_target.strip().split(maxsplit=1)[0].strip("<>")
        parsed = urlsplit(target)
        if parsed.scheme or target.startswith(("#", "mailto:")):
            continue
        relative = unquote(parsed.path)
        if not relative:
            continue
        candidate = (path.parent / relative).resolve()
        if not candidate.exists():
            errors.append(f"broken local link {target!r}")
    return errors


def _markdown_fence_errors(source: str) -> list[str]:
    errors: list[str] = []
    open_fence: str | None = None
    for line_number, line in enumerate(source.splitlines(), start=1):
        if "```" in line and not line.lstrip().startswith("```"):
            errors.append(f"line {line_number}: code fence must start on its own line")
            continue
        match = MARKDOWN_FENCE.match(line)
        if not match:
            continue
        fence = match.group(1)
        if open_fence is None:
            open_fence = fence
        elif len(fence) >= len(open_fence):
            open_fence = None
    if open_fence is not None:
        errors.append("unclosed code fence")
    return errors


def audit_notebook(path: Path, relative: str, optional_packages: set[str]) -> NotebookAudit:
    notebook = json.loads(path.read_text(encoding="utf-8"))
    errors = [str(item) for item in validate_notebook(path, display_path=relative)]
    warnings: list[str] = []
    cells = notebook.get("cells", [])

    for index, cell in enumerate(cells):
        source = _cell_source(cell)
        cell_id = cell.get("id", f"cell-{index}")
        if cell.get("cell_type") == "markdown":
            errors.extend(f"{cell_id}: {item}" for item in _broken_links(path, source))
            errors.extend(f"{cell_id}: {item}" for item in _markdown_fence_errors(source))
            continue
        if cell.get("cell_type") != "code":
            continue

        tree = ast.parse(_python_from_ipython(source), filename=f"{relative}#{cell_id}")
        errors.extend(f"{cell_id}: {item}" for item in _import_errors(tree, optional_packages))
        nonblank = sum(bool(line.strip()) for line in source.splitlines())
        if nonblank > 10:
            warnings.append(f"{cell_id}: {nonblank} nonblank code lines (course guideline: 10)")

    return NotebookAudit(
        path=relative,
        cells=len(cells),
        code_cells=sum(cell.get("cell_type") == "code" for cell in cells),
        markdown_cells=sum(cell.get("cell_type") == "markdown" for cell in cells),
        errors=sorted(set(errors)),
        warnings=sorted(set(warnings)),
    )


def audit_all(root: Path = ROOT) -> list[NotebookAudit]:
    optional_packages = _optional_packages(root)
    return [
        audit_notebook(path, relative, optional_packages)
        for path, relative in iter_main_notebooks(root)
    ]


def _print_markdown(audits: list[NotebookAudit]) -> None:
    total_cells = sum(item.cells for item in audits)
    code_cells = sum(item.code_cells for item in audits)
    errors = sum(len(item.errors) for item in audits)
    warnings = sum(len(item.warnings) for item in audits)
    print("# Core notebook cell audit")
    print()
    print("Scope: Korean and English notebooks under sections 01 through 06. Sections 07 and 08 are excluded.")
    print()
    print(f"- Notebooks: {len(audits)}")
    print(f"- Cells: {total_cells} ({code_cells} code)")
    print(f"- Errors: {errors}")
    print(f"- Style warnings: {warnings}")
    print()
    print("| Notebook | Cells | Code | Errors | Warnings |")
    print("|---|---:|---:|---:|---:|")
    for item in audits:
        print(f"| `{item.path}` | {item.cells} | {item.code_cells} | {len(item.errors)} | {len(item.warnings)} |")
    if errors:
        print("\n## Errors")
        for item in audits:
            for error in item.errors:
                print(f"- `{item.path}` — {error}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit every cell in the 01-06 course notebooks.")
    parser.add_argument("--format", choices=("json", "markdown"), default="markdown")
    args = parser.parse_args()
    audits = audit_all(ROOT)
    if args.format == "json":
        print(json.dumps([asdict(item) for item in audits], ensure_ascii=False, indent=2))
    else:
        _print_markdown(audits)
    return int(any(item.errors for item in audits))


if __name__ == "__main__":
    raise SystemExit(main())
