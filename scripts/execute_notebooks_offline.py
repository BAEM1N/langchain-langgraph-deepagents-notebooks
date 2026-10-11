"""Execute course notebooks with external APIs blocked.

The runner executes copied notebooks under ``.local`` and leaves source notebooks
untouched. External network/API cells are excluded by evidence: a real network
guard, credential errors, or optional integration requirements. Ordinary Python
or SDK errors remain failures.
"""

from __future__ import annotations

import argparse
import ast
import concurrent.futures
import dataclasses
import datetime as dt
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import textwrap
import time
from collections import Counter
from pathlib import Path
from typing import Any

import nbformat
from nbclient import NotebookClient

ROOT = Path(__file__).resolve().parents[1]
KERNEL_NAME = "offline-course-python"
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

SECRET_NAME_PATTERN = re.compile(
    r"(API[_-]?KEY|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIAL|COOKIE|SESSION|"
    r"OPENAI|OPENROUTER|ANTHROPIC|GOOGLE|GEMINI|TAVILY|LANGSMITH|LANGCHAIN|"
    r"LANGFUSE|SLACK|AWS|AZURE|PINECONE|COHERE|VOYAGE|RUNPOD|RUNLOOP|DAYTONA|"
    r"MODAL|NVIDIA|GROQ|MISTRAL|HUGGINGFACE|HF_)",
    re.IGNORECASE,
)

SECRET_VALUE_PATTERN = re.compile(
    r"(sk-[A-Za-z0-9_-]{16,}|sk-or-v1-[A-Za-z0-9_-]{20,}|"
    r"xox[baprs]-[A-Za-z0-9-]{20,}|hf_[A-Za-z0-9]{20,})"
)

EXTERNAL_NAME_PATTERN = re.compile(
    r"([A-Z0-9_]*(?:API_KEY|TOKEN|TOKEN_ID|SECRET_KEY|PUBLIC_KEY|ACCESS_KEY_ID)|"
    r"LANGFUSE_HOST|HF_TOKEN|HUGGINGFACE_TOKEN)"
)

OPTIONAL_MODULES = {
    "anthropic",
    "assemblyai",
    "boto3",
    "botocore",
    "cartesia",
    "chromadb",
    "cohere",
    "cosmos",
    "daytona",
    "elasticsearch",
    "fastembed",
    "google",
    "groq",
    "ddgs",
    "docling",
    "git",
    "gitpython",
    "jq",
    "langchain_anthropic",
    "langchain_aws",
    "langchain_chroma",
    "langchain_cohere",
    "langchain_docling",
    "langchain_elasticsearch",
    "langchain_experimental",
    "langchain_google_genai",
    "langchain_groq",
    "langchain_huggingface",
    "langchain_litellm",
    "langchain_milvus",
    "langchain_mistralai",
    "langchain_nvidia_ai_endpoints",
    "langchain_ollama",
    "langchain_pinecone",
    "langchain_postgres",
    "langchain_qdrant",
    "langchain_together",
    "langchain_voyageai",
    "langchain_weaviate",
    "modal",
    "nvidia",
    "opentelemetry",
    "ollama",
    "playwright",
    "pinecone",
    "pdfplumber",
    "pypdf",
    "psycopg",
    "pymilvus",
    "qdrant_client",
    "rank_bm25",
    "runloop_api_client",
    "sentence_transformers",
    "slack_sdk",
    "traceloop",
    "unstructured",
    "weaviate",
    "wikipedia",
}

INTERACTIVE_OR_SERVER_PATTERN = re.compile(
    r"(input\(|getpass\.|uvicorn|app\.run\(|\.serve\(|websockets\.serve|"
    r"while\s+True:|KeyboardInterrupt)"
)
NAME_ERROR_PATTERN = re.compile(r"name ['\"]([^'\"]+)['\"] is not defined")


@dataclasses.dataclass(frozen=True)
class SkipRecord:
    cell_index: int
    category: str
    reason: str


class IndexedNotebookClient(NotebookClient):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        self.failed_cell_index: int | None = None

    async def async_execute_cell(
        self, cell, cell_index, execution_count=None, store_history=True
    ):
        try:
            return await super().async_execute_cell(
                cell,
                cell_index,
                execution_count=execution_count,
                store_history=store_history,
            )
        except BaseException:
            self.failed_cell_index = cell_index
            raise


def course_notebooks() -> list[Path]:
    paths: list[Path] = []
    for base in [ROOT, ROOT / "en"]:
        for directory in sorted(COURSE_DIRS):
            paths.extend(sorted((base / directory).rglob("*.ipynb")))
    return paths


def stable_slug(path: Path) -> str:
    relative = str(path.relative_to(ROOT))
    digest = hashlib.sha256(relative.encode()).hexdigest()[:10]
    return (
        re.sub(r"[^A-Za-z0-9_.-]+", "__", relative.replace("/", "__")) + f"__{digest}"
    )


def sanitized_env(guard_dir: Path, work_home: Path) -> dict[str, str]:
    keep_names = {
        "PATH",
        "SHELL",
        "TMPDIR",
        "TERM",
        "LANG",
        "LC_ALL",
        "VIRTUAL_ENV",
        "UV_CACHE_DIR",
        "UV_PROJECT_ENVIRONMENT",
        "PYTHONPATH",
    }
    env = {
        key: value
        for key, value in os.environ.items()
        if key in keep_names and not SECRET_NAME_PATTERN.search(key)
    }
    prior_pythonpath = env.get("PYTHONPATH")
    env["PYTHONPATH"] = (
        str(guard_dir)
        if not prior_pythonpath
        else f"{guard_dir}{os.pathsep}{prior_pythonpath}"
    )
    env.update(
        {
            "HOME": str(work_home),
            "PYTHONNOUSERSITE": "1",
            "PYDEVD_DISABLE_FILE_VALIDATION": "1",
            "LANGSMITH_TRACING": "false",
            "LANGCHAIN_TRACING_V2": "false",
            "LANGCHAIN_ENDPOINT": "",
            "TOKENIZERS_PARALLELISM": "false",
            "MPLCONFIGDIR": str(work_home / ".matplotlib"),
            "JUPYTER_PATH": str(guard_dir.parent / "jupyter"),
            "JUPYTER_PLATFORM_DIRS": "1",
            "COURSE_OFFLINE_NOTEBOOK_RUN": "1",
        }
    )
    return env


def write_network_guard(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)
    (path / "sitecustomize.py").write_text(
        textwrap.dedent(
            r"""
            from __future__ import annotations

            import ipaddress
            import builtins
            import io
            import os
            import pathlib
            import socket
            import subprocess

            class ExternalNetworkBlockedError(RuntimeError):
                pass

            os.environ.setdefault("LANGSMITH_TRACING", "false")
            os.environ.setdefault("LANGCHAIN_TRACING_V2", "false")

            _real_connect = socket.socket.connect
            _real_connect_ex = socket.socket.connect_ex
            _real_create_connection = socket.create_connection
            _real_popen = subprocess.Popen
            _real_open = builtins.open
            _real_io_open = io.open
            _real_path_open = pathlib.Path.open

            def _allowed_host(host):
                if host in {None, "", "localhost", "0.0.0.0", "::"}:
                    return True
                try:
                    return ipaddress.ip_address(str(host)).is_loopback
                except ValueError:
                    return str(host).endswith(".localhost")

            def _host_from_address(address):
                if isinstance(address, str):
                    return None
                if isinstance(address, bytes):
                    return None
                try:
                    return address[0]
                except Exception:
                    return None

            def _guarded_connect(self, address):
                host = _host_from_address(address)
                if _allowed_host(host):
                    return _real_connect(self, address)
                raise ExternalNetworkBlockedError(
                    f"External network blocked during offline notebook validation: {host!r}"
                )

            def _guarded_connect_ex(self, address):
                host = _host_from_address(address)
                if _allowed_host(host):
                    return _real_connect_ex(self, address)
                raise ExternalNetworkBlockedError(
                    f"External network blocked during offline notebook validation: {host!r}"
                )

            def _guarded_create_connection(address, timeout=None, source_address=None, *args, **kwargs):
                host = _host_from_address(address)
                if _allowed_host(host):
                    return _real_create_connection(
                        address, timeout=timeout, source_address=source_address, *args, **kwargs
                    )
                raise ExternalNetworkBlockedError(
                    f"External network blocked during offline notebook validation: {host!r}"
                )

            def _guarded_popen(args, *pargs, **kwargs):
                command = args if isinstance(args, str) else " ".join(map(str, args))
                executable = command.split()[0].split("/")[-1] if command.split() else ""
                blocked = {"curl", "wget", "http", "https", "ftp", "nc", "ncat", "telnet", "ssh", "scp", "sftp", "pip", "uv", "docker"}
                lower_command = command.lower()
                if executable in blocked:
                    raise ExternalNetworkBlockedError(
                        f"External subprocess blocked during offline notebook validation: {executable}"
                    )
                if ("http://" in lower_command or "https://" in lower_command) and "localhost" not in lower_command and "127.0.0.1" not in lower_command:
                    raise ExternalNetworkBlockedError(
                        "External URL subprocess blocked during offline notebook validation"
                    )
                return _real_popen(args, *pargs, **kwargs)

            def _secret_path(path):
                text = str(path).lower()
                return (
                    text == ".env"
                    or text.endswith("/.env")
                    or text.endswith("secrets.env")
                    or "/.config/ddok/" in text
                    or "/.aws/" in text
                    or "/.ssh/" in text
                    or "/.claude/" in text
                )

            def _guarded_open(file, *args, **kwargs):
                if _secret_path(file):
                    raise PermissionError(
                        f"Secret file read blocked during offline notebook validation: {file}"
                    )
                return _real_open(file, *args, **kwargs)

            def _guarded_io_open(file, *args, **kwargs):
                if _secret_path(file):
                    raise PermissionError(
                        f"Secret file read blocked during offline notebook validation: {file}"
                    )
                return _real_io_open(file, *args, **kwargs)

            def _guarded_path_open(self, *args, **kwargs):
                if _secret_path(self):
                    raise PermissionError(
                        f"Secret file read blocked during offline notebook validation: {self}"
                    )
                return _real_path_open(self, *args, **kwargs)

            socket.socket.connect = _guarded_connect
            socket.socket.connect_ex = _guarded_connect_ex
            socket.create_connection = _guarded_create_connection
            subprocess.Popen = _guarded_popen
            builtins.open = _guarded_open
            io.open = _guarded_io_open
            pathlib.Path.open = _guarded_path_open

            try:
                import dotenv
                import dotenv.main

                def _offline_load_dotenv(*args, **kwargs):
                    return False

                def _offline_find_dotenv(*args, **kwargs):
                    return ""

                def _offline_dotenv_values(*args, **kwargs):
                    return {}

                dotenv.load_dotenv = _offline_load_dotenv
                dotenv.find_dotenv = _offline_find_dotenv
                dotenv.dotenv_values = _offline_dotenv_values
                dotenv.main.load_dotenv = _offline_load_dotenv
                dotenv.main.find_dotenv = _offline_find_dotenv
                dotenv.main.dotenv_values = _offline_dotenv_values
            except Exception:
                pass
            """
        ).lstrip(),
        encoding="utf-8",
    )


def write_kernel_spec(run_root: Path) -> None:
    guard_dir = run_root / "guard"
    sandbox_profile = guard_dir / "offline-network.sb"
    root_env = ROOT / ".env"
    sandbox_profile.write_text(
        textwrap.dedent(
            f"""\
            (version 1)
            (allow default)
            (deny network-outbound)
            (allow network-outbound (remote ip "localhost:*"))
            (deny file-read-data (subpath "/Users/baem1n/.config/ddok"))
            (deny file-read-data (subpath "/Users/baem1n/.aws"))
            (deny file-read-data (subpath "/Users/baem1n/.ssh"))
            (deny file-read-data (subpath "/Users/baem1n/.claude"))
            (deny file-read-data (literal "{root_env}"))
            """
        ),
        encoding="utf-8",
    )
    wrapper = guard_dir / "offline-python-kernel"
    if Path("/usr/bin/sandbox-exec").exists():
        wrapper.write_text(
            "#!/bin/sh\n"
            f'exec /usr/bin/sandbox-exec -f {sandbox_profile} {sys.executable} "$@"\n',
            encoding="utf-8",
        )
    else:
        wrapper.write_text(
            f'#!/bin/sh\nexec {sys.executable} "$@"\n',
            encoding="utf-8",
        )
    wrapper.chmod(0o755)
    kernel_dir = run_root / "jupyter" / "kernels" / KERNEL_NAME
    kernel_dir.mkdir(parents=True, exist_ok=True)
    spec = {
        "argv": [str(wrapper), "-m", "ipykernel_launcher", "-f", "{connection_file}"],
        "display_name": "Offline Course Python",
        "language": "python",
    }
    (kernel_dir / "kernel.json").write_text(
        json.dumps(spec, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def scrub_text(value: str) -> str:
    return SECRET_VALUE_PATTERN.sub("[REDACTED_SECRET]", value)


def clear_outputs(notebook: dict[str, Any]) -> None:
    for cell in notebook.get("cells", []):
        if cell.get("cell_type") == "code":
            cell["outputs"] = []
            cell["execution_count"] = None


def executed_cell_count(notebook: dict[str, Any]) -> int:
    return sum(
        cell.get("cell_type") == "code"
        and cell.get("execution_count") is not None
        and "skip-execution" not in cell.get("metadata", {}).get("tags", [])
        for cell in notebook.get("cells", [])
    )


def add_skip_tag(cell: dict[str, Any]) -> None:
    metadata = cell.setdefault("metadata", {})
    tags = list(metadata.get("tags", []))
    if "skip-execution" not in tags:
        tags.append("skip-execution")
    metadata["tags"] = tags


def static_skip_reason(source: str) -> tuple[str, str] | None:
    stripped = source.strip()
    if stripped.startswith(("%pip ", "!pip ")):
        return "environment", "package installation is skipped in offline validation"
    if INTERACTIVE_OR_SERVER_PATTERN.search(source):
        return "environment", "interactive or long-running server cell is excluded"
    return None


def defined_names(source: str) -> set[str]:
    names: set[str] = set()
    try:
        tree = ast.parse(source)
    except SyntaxError:
        return names

    class GlobalNames(ast.NodeVisitor):
        def visit_FunctionDef(
            self, node: ast.FunctionDef | ast.AsyncFunctionDef | ast.ClassDef
        ):
            names.add(node.name)

        def visit_AsyncFunctionDef(self, node: ast.AsyncFunctionDef):
            self.visit_FunctionDef(node)

        def visit_ClassDef(self, node: ast.ClassDef):
            self.visit_FunctionDef(node)

        def visit_Lambda(self, node):
            pass

        def visit_Import(self, node):
            for alias in node.names:
                names.add(alias.asname or alias.name.split(".")[0])

        def visit_ImportFrom(self, node):
            for alias in node.names:
                names.add(alias.asname or alias.name)

        def visit_Assign(self, node):
            for target in node.targets:
                names.update(target_names(target))

        def visit_AnnAssign(self, node):
            names.update(target_names(node.target))

        def visit_For(self, node: ast.For | ast.AsyncFor):
            names.update(target_names(node.target))
            self.generic_visit(node)

        def visit_AsyncFor(self, node: ast.AsyncFor):
            self.visit_For(node)

        def visit_With(self, node: ast.With | ast.AsyncWith):
            for item in node.items:
                if item.optional_vars is not None:
                    names.update(target_names(item.optional_vars))
            self.generic_visit(node)

        def visit_AsyncWith(self, node: ast.AsyncWith):
            self.visit_With(node)

    GlobalNames().visit(tree)
    return names


def target_names(target: ast.AST) -> set[str]:
    if isinstance(target, ast.Name):
        return {target.id}
    if isinstance(target, (ast.Tuple, ast.List)):
        return {name for item in target.elts for name in target_names(item)}
    return set()


def prepare_workspace(out_dir: Path, notebook_path: Path) -> Path:
    workspace = out_dir / "workspace"
    if workspace.exists():
        shutil.rmtree(workspace)
    workspace.mkdir(parents=True, exist_ok=True)
    for name in ["assets", "docs"]:
        source = ROOT / name
        if source.exists():
            (workspace / name).symlink_to(source, target_is_directory=True)
    examples_skills = ROOT / "07_examples" / "skills"
    if examples_skills.exists():
        skills_parent = workspace / "07_examples"
        skills_parent.mkdir(parents=True, exist_ok=True)
        (skills_parent / "skills").symlink_to(examples_skills, target_is_directory=True)
    for parent in [
        notebook_path.parent,
        ROOT / "07_examples",
        ROOT / "en" / "07_examples",
    ]:
        if not parent.exists():
            continue
        target_parent = workspace / parent.relative_to(ROOT)
        target_parent.mkdir(parents=True, exist_ok=True)
        for file_path in parent.iterdir():
            if (
                file_path.is_file()
                and file_path.suffix != ".ipynb"
                and file_path.name != ".env"
            ):
                link = target_parent / file_path.name
                if not link.exists():
                    link.symlink_to(file_path)
    chinook = ROOT / "05_advanced" / "Chinook.db"
    if chinook.exists():
        for db_parent in [workspace / "05_advanced", workspace / "en" / "05_advanced"]:
            db_parent.mkdir(parents=True, exist_ok=True)
            db_link = db_parent / "Chinook.db"
            if not db_link.exists():
                db_link.symlink_to(chinook)
    work_cwd = workspace / notebook_path.relative_to(ROOT).parent
    work_cwd.mkdir(parents=True, exist_ok=True)
    return work_cwd


def classify_error(
    source: str,
    ename: str,
    evalue: str,
    traceback: str,
    names_from_skipped: set[str],
) -> tuple[str, str] | None:
    evidence = f"{ename}\n{evalue}\n{traceback}"
    if (
        "ExternalNetworkBlockedError" in evidence
        or "External network blocked" in evidence
    ):
        return "external_api", "external network/API access was blocked"
    provider_source = re.search(
        r"Chat(OpenAI|Anthropic|Google|Groq|Mistral)|Client\(|WebClient\(|"
        r"OpenAIEmbeddings|GoogleGenerativeAIEmbeddings|CohereEmbeddings|"
        r"VoyageAIEmbeddings|TavilySearch",
        source,
    )
    if EXTERNAL_NAME_PATTERN.search(evalue) or (
        provider_source
        and re.search(
            r"api[_ -]?key|credential|authentication|unauthorized",
            evalue,
            re.IGNORECASE,
        )
        and re.search(
            r"openai|anthropic|google|gemini|tavily|langsmith|slack|aws|azure|pinecone|cohere|voyage|huggingface|groq|mistral",
            evidence,
            re.IGNORECASE,
        )
    ):
        return "external_api", "provider credential is intentionally absent"
    if re.search(r"FileNotFoundError", evidence) and re.search(
        r"local/content_builder|post\.md", evidence
    ):
        return (
            "external_dependency",
            "depends on skipped external content-generation cell",
        )
    if (
        ename == "AttributeError"
        and "'NoneType' object has no attribute 'id'" in evalue
        and ("create_feedback" in source or "project.id" in source)
    ):
        return (
            "external_api",
            "LangSmith project/run context is intentionally absent offline",
        )
    if ename == "AttributeError" and "ChatOllama" in evalue:
        return (
            "environment",
            "optional Ollama integration package is unavailable in offline validation",
        )
    if (
        ename == "ResponseError"
        and re.search(r"model .+not found", evalue)
        and "status code: 404" in evalue
        and re.search(r"ollama|ChatOllama|OllamaEmbeddings", evidence, re.IGNORECASE)
    ):
        return (
            "environment",
            "optional local Ollama model is unavailable in offline validation",
        )
    if ename == "PermissionError" and (
        str(ROOT / ".env") in evalue or "Secret file read blocked" in evalue
    ):
        return (
            "external_api",
            "credential-file loading is intentionally blocked offline",
        )
    missing_name = NAME_ERROR_PATTERN.search(evalue)
    if missing_name and missing_name.group(1) in names_from_skipped:
        return (
            "external_dependency",
            f"depends on skipped external cell symbol: {missing_name.group(1)}",
        )
    missing = re.search(r"No module named ['\"]([^'\"]+)['\"]", evidence)
    if missing:
        if missing.group(1) in {
            "langgraph.store.postgres",
            "langgraph.checkpoint.postgres",
            "langgraph.checkpoint.sqlite",
        }:
            return (
                "environment",
                f"optional persistence dependency missing: {missing.group(1)}",
            )
        top_level = missing.group(1).split(".")[0]
        if top_level in OPTIONAL_MODULES or any(
            module.startswith(top_level) for module in OPTIONAL_MODULES
        ):
            return (
                "environment",
                f"optional integration dependency missing: {missing.group(1)}",
            )
    import_error = re.search(
        r"(?:`([^`]+)` package not found|Could not import ([A-Za-z0-9_.-]+) python package|([A-Za-z0-9_.-]+) package not found)",
        evidence,
        re.IGNORECASE,
    )
    if import_error:
        package = next(group for group in import_error.groups() if group)
        top_level = package.replace("-", "_").split(".")[0]
        if top_level in OPTIONAL_MODULES or any(
            module.startswith(top_level) for module in OPTIONAL_MODULES
        ):
            return "environment", f"optional integration dependency missing: {package}"
    if "BrowserType.launch" in evidence and "Executable doesn't exist" in evidence:
        return (
            "environment",
            "optional Playwright browser binary is unavailable in offline validation",
        )
    if re.search(
        r"connection refused|name or service not known|could not connect|server selection timeout|ECONNREFUSED|DNSNameResolutionError|nodename nor servname",
        evidence,
        re.IGNORECASE,
    ):
        return (
            "environment",
            "optional local/external service is unavailable in offline validation",
        )
    if "LangfuseConfigError" in evidence or (
        "ConfigError" in evidence
        and "unable to infer type" in evidence
        and "description" in evidence
    ):
        return (
            "environment",
            "optional Langfuse runtime is unavailable in offline validation",
        )
    if (
        ename in {"TimeoutError", "CellTimeoutError"} or "A cell timed out" in evidence
    ) and INTERACTIVE_OR_SERVER_PATTERN.search(source):
        return "environment", "interactive or server cell timed out and is excluded"
    return None


def execute_once(
    notebook: dict[str, Any], cwd: Path, timeout: int
) -> tuple[bool, dict[str, Any] | None]:
    client = IndexedNotebookClient(
        notebook,
        timeout=timeout,
        startup_timeout=90,
        kernel_name=KERNEL_NAME,
        allow_errors=False,
        force_raise_errors=True,
        skip_cells_with_tag="skip-execution",
        resources={"metadata": {"path": str(cwd)}},
    )
    try:
        client.execute(cwd=str(cwd))
        return True, None
    except Exception as error:  # noqa: BLE001 - result evidence is persisted.
        cell_index = client.failed_cell_index
        cell = notebook["cells"][cell_index] if cell_index is not None else {}
        outputs = cell.get("outputs", []) if isinstance(cell, dict) else []
        ename = getattr(error, "ename", type(error).__name__)
        evalue = getattr(error, "evalue", str(error))
        traceback = getattr(error, "traceback", str(error))
        return False, {
            "cell_index": cell_index,
            "ename": scrub_text(str(ename)),
            "evalue": scrub_text(str(evalue)),
            "traceback": scrub_text(str(traceback)),
            "outputs": scrub_text(json.dumps(outputs, ensure_ascii=False)[:4000]),
        }


def worker(
    notebook_path: Path, run_root: Path, timeout: int, max_iterations: int
) -> dict[str, Any]:
    started = time.monotonic()
    relative = notebook_path.relative_to(ROOT)
    slug = stable_slug(notebook_path)
    out_dir = run_root / "executed" / slug
    out_dir.mkdir(parents=True, exist_ok=True)
    work_home = out_dir / "home"
    work_home.mkdir(parents=True, exist_ok=True)
    copied = out_dir / "notebook.ipynb"
    work_cwd = prepare_workspace(out_dir, notebook_path)
    shutil.copy2(notebook_path, copied)
    notebook = nbformat.read(copied, as_version=4)
    clear_outputs(notebook)
    skip_records: list[SkipRecord] = []
    skipped_indexes: set[int] = set()
    names_from_skipped: set[str] = set()
    code_cell_count = sum(
        1 for cell in notebook.cells if cell.get("cell_type") == "code"
    )
    source_failures: list[dict[str, Any]] = []

    for index, cell in enumerate(notebook.cells):
        if cell.get("cell_type") != "code":
            continue
        source = "".join(cell.get("source", ""))
        reason = static_skip_reason(source)
        if reason is None:
            continue
        category, detail = reason
        add_skip_tag(cell)
        skipped_indexes.add(index)
        names_from_skipped.update(defined_names(source))
        skip_records.append(SkipRecord(index, category, detail))

    last_failure: dict[str, Any] | None = None
    for _ in range(max_iterations):
        success, failure = execute_once(notebook, work_cwd, timeout)
        if success:
            nbformat.write(notebook, copied)
            elapsed = round(time.monotonic() - started, 3)
            status = "passed"
            if source_failures:
                status = "failed"
            elif skip_records:
                status = "passed_with_exclusions"
            return {
                "path": str(relative),
                "source_sha256": sha256_file(notebook_path),
                "status": status,
                "elapsed_seconds": elapsed,
                "code_cells": code_cell_count,
                "excluded_cells": len(skip_records),
                "executed_cells": executed_cell_count(notebook),
                "skipped_cells": [
                    dataclasses.asdict(record) for record in skip_records
                ],
                "source_failures": source_failures,
                "failure": source_failures[0] if source_failures else None,
                "executed_copy": str(copied.relative_to(run_root)),
            }
        assert failure is not None
        last_failure = failure
        cell_index = failure.get("cell_index")
        if cell_index is None or cell_index in skipped_indexes:
            break
        cell = notebook.cells[cell_index]
        source = "".join(cell.get("source", ""))
        classified = classify_error(
            source,
            failure["ename"],
            failure["evalue"],
            failure["traceback"],
            names_from_skipped,
        )
        if classified is None:
            add_skip_tag(cell)
            skipped_indexes.add(cell_index)
            names_from_skipped.update(defined_names(source))
            source_failures.append(failure)
            skip_records.append(
                SkipRecord(
                    cell_index,
                    "source_failure",
                    "source cell failed; skipped to continue census",
                )
            )
            continue
        category, reason = classified
        add_skip_tag(cell)
        skipped_indexes.add(cell_index)
        names_from_skipped.update(defined_names(source))
        skip_records.append(SkipRecord(cell_index, category, reason))

    nbformat.write(notebook, copied)
    return {
        "path": str(relative),
        "source_sha256": sha256_file(notebook_path),
        "status": "failed",
        "elapsed_seconds": round(time.monotonic() - started, 3),
        "code_cells": code_cell_count,
        "excluded_cells": len(skip_records),
        "executed_cells": executed_cell_count(notebook),
        "skipped_cells": [dataclasses.asdict(record) for record in skip_records],
        "source_failures": source_failures,
        "failure": last_failure
        or {
            "cell_index": None,
            "ename": "RunnerIterationLimit",
            "evalue": "Notebook did not converge after classified exclusions",
            "traceback": "",
            "outputs": "",
        },
        "executed_copy": str(copied.relative_to(run_root)),
    }


def run_worker_subprocess(
    path: Path, run_root: Path, timeout: int, max_iterations: int
) -> dict[str, Any]:
    guard_dir = run_root / "guard"
    work_home = run_root / "worker-home" / stable_slug(path)
    work_home.mkdir(parents=True, exist_ok=True)
    env = sanitized_env(guard_dir, work_home)
    command = [
        sys.executable,
        str(Path(__file__).resolve()),
        "--worker",
        str(path),
        "--run-root",
        str(run_root),
        "--timeout",
        str(timeout),
        "--max-iterations",
        str(max_iterations),
    ]
    completed = subprocess.run(
        command,
        cwd=ROOT,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        return {
            "path": str(path.relative_to(ROOT)),
            "source_sha256": sha256_file(path),
            "status": "runner_error",
            "elapsed_seconds": None,
            "code_cells": None,
            "excluded_cells": 0,
            "executed_cells": 0,
            "skipped_cells": [],
            "source_failures": [],
            "failure": {
                "cell_index": None,
                "ename": "RunnerProcessError",
                "evalue": scrub_text(
                    completed.stderr[-4000:] or completed.stdout[-4000:]
                ),
                "traceback": "",
                "outputs": "",
            },
            "executed_copy": None,
        }
    try:
        return json.loads(completed.stdout)
    except json.JSONDecodeError as error:
        return {
            "path": str(path.relative_to(ROOT)),
            "source_sha256": sha256_file(path),
            "status": "runner_error",
            "elapsed_seconds": None,
            "code_cells": None,
            "excluded_cells": 0,
            "executed_cells": 0,
            "skipped_cells": [],
            "source_failures": [],
            "failure": {
                "cell_index": None,
                "ename": "RunnerJsonError",
                "evalue": scrub_text(f"{error}: {completed.stdout[-4000:]}"),
                "traceback": "",
                "outputs": "",
            },
            "executed_copy": None,
        }


def scan_generated_artifacts(run_root: Path) -> dict[str, int]:
    scanned = 0
    matches = 0
    for path in run_root.rglob("*"):
        if not path.is_file() or path.suffix not in {
            ".json",
            ".md",
            ".ipynb",
            ".txt",
            ".log",
        }:
            continue
        scanned += 1
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        if SECRET_VALUE_PATTERN.search(text):
            matches += 1
    return {"artifacts_scanned": scanned, "secret_value_matches": matches}


def write_reports(run_root: Path, results: list[dict[str, Any]]) -> None:
    summary = Counter(item["status"] for item in results)
    skipped = Counter(
        record["category"]
        for item in results
        for record in item.get("skipped_cells", [])
    )
    payload = {
        "generated_at": dt.datetime.now(dt.UTC).isoformat(),
        "total_notebooks": len(results),
        "total_code_cells": sum(item.get("code_cells") or 0 for item in results),
        "total_executed_cells": sum(
            item.get("executed_cells") or 0 for item in results
        ),
        "total_excluded_cells": sum(
            item.get("excluded_cells") or 0 for item in results
        ),
        "summary": dict(sorted(summary.items())),
        "skipped_cells": dict(sorted(skipped.items())),
        "secret_scan": scan_generated_artifacts(run_root),
        "results": sorted(results, key=lambda item: item["path"]),
    }
    (run_root / "summary.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    public = run_root / "verification.md"
    failed = [
        item
        for item in payload["results"]
        if item["status"] in {"failed", "runner_error"}
    ]
    lines = [
        "# Offline Notebook Execution Verification",
        "",
        f"Generated: {payload['generated_at']}.",
        "",
        "External provider APIs, remote services and credential-dependent cells were excluded under a guarded kernel environment. Source notebooks were not overwritten; executed copies and per-notebook evidence are stored under `.local/`.",
        "",
        "## Scope",
        "",
        f"- Notebooks discovered: {payload['total_notebooks']}",
        f"- Code cells: {payload['total_code_cells']}",
        f"- Executed cells: {payload['total_executed_cells']}",
        f"- Excluded cells: {payload['total_excluded_cells']}",
        f"- Status counts: `{json.dumps(payload['summary'], sort_keys=True)}`",
        f"- Skipped cell categories: `{json.dumps(payload['skipped_cells'], sort_keys=True)}`",
        f"- Secret scan: `{json.dumps(payload['secret_scan'], sort_keys=True)}`",
        "",
        "## Failed Or Runner-Error Notebooks",
        "",
    ]
    if failed:
        for item in failed:
            failure = item.get("failure") or {}
            lines.append(
                f"- `{item['path']}`: {item['status']} at cell {failure.get('cell_index')} "
                f"({failure.get('ename')}: {failure.get('evalue')})"
            )
    else:
        lines.append("- None.")
    lines.extend(
        [
            "",
            "## Notes",
            "",
            "- The guard removes secret-bearing environment variables before kernel startup.",
            "- The guard blocks non-loopback socket connections and common network subprocesses.",
            "- Excluded cells are counted as exclusions, not successful API calls.",
        ]
    )
    public.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-root", type=Path)
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--timeout", type=int, default=180)
    parser.add_argument("--max-iterations", type=int, default=64)
    parser.add_argument("--limit", type=int)
    parser.add_argument("--only", action="append", default=[])
    parser.add_argument("--worker", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    run_root = args.run_root
    if run_root is None:
        stamp = dt.datetime.now().strftime("%Y%m%dT%H%M%S")
        run_root = ROOT / ".local" / f"offline-notebook-execution-{stamp}"
    run_root.mkdir(parents=True, exist_ok=True)
    write_network_guard(run_root / "guard")
    write_kernel_spec(run_root)

    if args.worker is not None:
        result = worker(
            args.worker.resolve(), run_root.resolve(), args.timeout, args.max_iterations
        )
        print(json.dumps(result, ensure_ascii=False))
        return 0

    paths = course_notebooks()
    if args.only:
        needles = tuple(args.only)
        paths = [
            path
            for path in paths
            if any(needle in str(path.relative_to(ROOT)) for needle in needles)
        ]
    if args.limit:
        paths = paths[: args.limit]

    manifest = {
        "generated_at": dt.datetime.now(dt.UTC).isoformat(),
        "paths": [str(path.relative_to(ROOT)) for path in paths],
        "source_hashes": {
            str(path.relative_to(ROOT)): sha256_file(path) for path in paths
        },
        "jobs": args.jobs,
        "timeout": args.timeout,
        "max_iterations": args.max_iterations,
    }
    (run_root / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    results: list[dict[str, Any]] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.jobs)) as pool:
        future_map = {
            pool.submit(
                run_worker_subprocess,
                path,
                run_root.resolve(),
                args.timeout,
                args.max_iterations,
            ): path
            for path in paths
        }
        for index, future in enumerate(concurrent.futures.as_completed(future_map), 1):
            result = future.result()
            results.append(result)
            print(
                f"[{index}/{len(paths)}] {result['status']} {result['path']}",
                flush=True,
            )
            write_reports(run_root, results)

    write_reports(run_root, results)
    summary = Counter(item["status"] for item in results)
    print(
        json.dumps(
            {"run_root": str(run_root), "summary": dict(summary)}, ensure_ascii=False
        )
    )
    secret_scan = scan_generated_artifacts(run_root)
    source_changed = any(
        sha256_file(path) != manifest["source_hashes"][str(path.relative_to(ROOT))]
        for path in paths
    )
    return (
        1
        if summary.get("failed")
        or summary.get("runner_error")
        or secret_scan["secret_value_matches"]
        or source_changed
        else 0
    )


if __name__ == "__main__":
    raise SystemExit(main())
