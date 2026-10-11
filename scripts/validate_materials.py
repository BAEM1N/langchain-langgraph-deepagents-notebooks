"""Check notebook structure and current API contracts without remote execution."""

from __future__ import annotations

import argparse
import ast
import json
import re
import subprocess
from collections.abc import Iterator
from pathlib import Path

from IPython.core.inputtransformer2 import TransformerManager

ROOT = Path(__file__).resolve().parents[1]
COURSE_DIRS = {
    "01_beginner",
    "02_langchain",
    "03_langgraph",
    "04_deepagents",
    "05_advanced",
    "06_langsmith",
    "07_examples",
    "08_integration",
}


def course_notebooks():
    for base in [ROOT, ROOT / "en"]:
        for directory in sorted(COURSE_DIRS):
            yield from sorted((base / directory).rglob("*.ipynb"))


def changed_paths():
    tracked = subprocess.check_output(
        ["git", "diff", "--name-only", "HEAD", "--", "*.ipynb"], cwd=ROOT, text=True
    ).splitlines()
    new = subprocess.check_output(
        ["git", "ls-files", "--others", "--exclude-standard", "*.ipynb"],
        cwd=ROOT,
        text=True,
    ).splitlines()
    return {ROOT / path for path in [*tracked, *new]}


def migration_errors(tree) -> Iterator[str]:
    for node in ast.walk(tree):
        if isinstance(node, ast.ImportFrom) and (node.module or "").startswith(
            "langchain_mcp_adapters"
        ):
            yield "active import uses the retired MCP adapter package"
        if isinstance(node, ast.Call):
            named_keywords = [
                keyword.arg for keyword in node.keywords if keyword.arg is not None
            ]
            if len(named_keywords) != len(set(named_keywords)):
                yield "repeated keyword argument in call"
            name = node.func.id if isinstance(node.func, ast.Name) else ""
            keywords = {keyword.arg: keyword.value for keyword in node.keywords}
            if name == "StoreBackend" and (node.args or "namespace" not in keywords):
                yield "StoreBackend requires a keyword-only namespace factory"
            if name == "StateBackend" and (node.args or node.keywords):
                yield "StateBackend no longer accepts runtime/file_format"
            if name == "SkillsMiddleware" and "backend" not in keywords:
                yield "SkillsMiddleware requires a backend instance"
            if name == "ReadResult" and {"data", "content"} & keywords.keys():
                yield "ReadResult accepts file_data, not data/content"
            if name in {"WriteResult", "EditResult"} and "files_update" in keywords:
                yield "files_update was removed from backend results"
            if name == "create_deep_agent":
                if isinstance(keywords.get("backend"), ast.Lambda):
                    yield "backend factories were removed; pass a BackendProtocol instance"
                if "pinned_skills" in keywords:
                    yield "pinned_skills belongs in run input state, not the constructor"


def book_contract_errors(transformer):
    failures = {}
    for base in [ROOT / "book/chapters", ROOT / "en/book/chapters"]:
        for path in base.rglob("*.typ"):
            blocks = re.finditer(
                r"#code-block\(\s*(`{3,})python\n(.*?)\1", path.read_text(), re.DOTALL
            )
            for index, match in enumerate(blocks):
                try:
                    tree = compile(
                        transformer.transform_cell(match[2]),
                        str(path),
                        "exec",
                        ast.PyCF_ONLY_AST | ast.PyCF_ALLOW_TOP_LEVEL_AWAIT,
                    )
                except SyntaxError:
                    # Curated books also contain explicitly partial snippets.
                    # Source notebook execution is checked separately.
                    continue
                errors = list(migration_errors(tree))
                if errors:
                    failures.setdefault(str(path.relative_to(ROOT)), []).extend(
                        f"block {index}: {error}" for error in errors
                    )
    return failures


def migration_section_parity():
    # High-risk topics must be taught in both languages, not just have a mirror file.
    required = {
        "02_langchain/11_mcp.ipynb": [
            "MCPAdapter",
            "mcpServers",
            "elicitation",
            "auth",
        ],
        "04_deepagents/05_subagents.ipynb": ["fork"],
        "04_deepagents/06_memory_and_skills.ipynb": ["include_tools", "pinned_skills"],
        "03_langgraph/08_interrupts_and_time_travel.ipynb": ["response_schema"],
        "06_langsmith/02_tracing_agents.ipynb": ["runs.query", "min_start_time"],
    }
    errors = []
    for relative, topics in required.items():
        for prefix in [ROOT, ROOT / "en"]:
            path = prefix / relative
            if not path.exists():
                continue
            cells = json.loads(path.read_text())["cells"]
            source = "\n".join(
                "".join(cell.get("source", [])) for cell in cells
            ).lower()
            for topic in topics:
                if topic.lower() not in source:
                    errors.append(
                        f"{path.relative_to(ROOT)}: missing {topic} teaching surface"
                    )
    return errors


def deck_contract_errors(transformer):
    """Validate the editable source, not only the rendered deck snapshots."""
    failures = {}
    for path in (ROOT / "decks/source").glob("*/content/*_content.py"):
        slides = None
        for node in ast.parse(path.read_text()).body:
            if isinstance(node, ast.Assign) and any(
                isinstance(target, ast.Name) and target.id == "SLIDES"
                for target in node.targets
            ):
                slides = ast.literal_eval(node.value)
        if not isinstance(slides, list):
            failures[str(path.relative_to(ROOT))] = [
                "SLIDES must contain the final literal source"
            ]
            continue
        for index, slide in enumerate(slides, 1):
            source = slide.get("code", "")
            if not isinstance(source, str) or not source.strip():
                continue
            try:
                tree = compile(
                    transformer.transform_cell(source),
                    str(path),
                    "exec",
                    ast.PyCF_ONLY_AST | ast.PyCF_ALLOW_TOP_LEVEL_AWAIT,
                )
            except SyntaxError:
                # Existing code slides also show fragments of longer examples.
                continue
            errors = list(migration_errors(tree))
            for node in ast.walk(tree):
                if not isinstance(node, (ast.For, ast.AsyncFor)) or not isinstance(
                    node.iter, ast.Call
                ):
                    continue
                function = node.iter.func
                if (
                    isinstance(function, ast.Attribute)
                    and function.attr == "query"
                    and isinstance(function.value, ast.Attribute)
                    and function.value.attr == "runs"
                ):
                    if isinstance(node, ast.For):
                        errors.append("runs.query requires async iteration")
                    keywords = {keyword.arg for keyword in node.iter.keywords}
                    if keywords & {"project_id", "start_time", "end_time", "limit"}:
                        errors.append("runs.query uses retired parameter names")
                    if "selects" not in keywords:
                        errors.append(
                            "runs.query must explicitly select consumed fields"
                        )
            if errors:
                failures.setdefault(str(path.relative_to(ROOT)), []).extend(
                    f"slide {index}: {error}" for error in errors
                )
    return failures


def check_notebook(path, enforce_contracts, transformer):
    errors = []
    notebook = json.loads(path.read_text(encoding="utf-8"))
    for index, cell in enumerate(notebook["cells"]):
        if cell.get("id") != f"cell-{index}":
            errors.append(f"cell {index}: expected id cell-{index}")
        if cell["cell_type"] != "code":
            continue
        source = "".join(cell.get("source", []))
        if not source.strip():
            continue
        try:
            python = transformer.transform_cell(source)
            compile(python, str(path), "exec", ast.PyCF_ALLOW_TOP_LEVEL_AWAIT)
            tree = compile(
                python,
                str(path),
                "exec",
                ast.PyCF_ONLY_AST | ast.PyCF_ALLOW_TOP_LEVEL_AWAIT,
            )
        except SyntaxError as error:
            errors.append(f"cell {index}: {error.msg} at line {error.lineno}")
            continue
        if enforce_contracts:
            errors.extend(
                f"cell {index}: {message}" for message in migration_errors(tree)
            )
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--changed-only", action="store_true")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    changed = changed_paths()
    paths = list(course_notebooks())
    if args.changed_only:
        paths = [path for path in paths if path in changed]
    transformer = TransformerManager()
    failures = {}
    for path in paths:
        try:
            errors = check_notebook(path, path in changed, transformer)
        except (ValueError, KeyError, TypeError) as error:
            errors = [str(error)]
        if errors:
            failures[str(path.relative_to(ROOT))] = errors
    core = [
        path.relative_to(ROOT)
        for path in paths
        if path.relative_to(ROOT).parts[0] in COURSE_DIRS - {"08_integration"}
    ]
    mirrors = {
        path.relative_to(ROOT / "en")
        for path in paths
        if path.is_relative_to(ROOT / "en")
    }
    parity_errors = [
        str(path)
        for path in core
        if path not in mirrors and (ROOT / "en" / path).exists() is False
    ]
    book_errors = book_contract_errors(transformer)
    section_errors = migration_section_parity()
    deck_errors = deck_contract_errors(transformer)
    report = {
        "checked": len(paths),
        "changed": len(changed),
        "failures": failures,
        "missing_english_mirrors": parity_errors,
        "book_contract_errors": book_errors,
        "migration_section_errors": section_errors,
        "deck_contract_errors": deck_errors,
    }
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return int(
        bool(failures or parity_errors or book_errors or section_errors or deck_errors)
    )


if __name__ == "__main__":
    raise SystemExit(main())
