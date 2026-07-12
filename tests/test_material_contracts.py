from __future__ import annotations

import json
import re
import tempfile
import unittest
from pathlib import Path
from typing import TypedDict

from deepagents.backends.protocol import BackendProtocol
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph import END, START, StateGraph
from langgraph.types import Command, interrupt

from scripts.audit_notebook_cells import audit_all
from book.scripts.nb2typ import convert_notebook


ROOT = Path(__file__).resolve().parents[1]


def cell_source(relative: str, cell_id: str) -> str:
    notebook = json.loads((ROOT / relative).read_text(encoding="utf-8"))
    cell = next(cell for cell in notebook["cells"] if cell["id"] == cell_id)
    source = cell["source"]
    return "".join(source) if isinstance(source, list) else source


class MaterialContractTests(unittest.TestCase):
    def test_project_defaults_to_python_314(self) -> None:
        self.assertEqual("3.14", (ROOT / ".python-version").read_text(encoding="utf-8").strip())

    def test_typst_generation_removes_trailing_whitespace(self) -> None:
        notebook = {
            "cells": [
                {"cell_type": "markdown", "metadata": {}, "source": ["# 01. Test\n"]},
                {"cell_type": "code", "metadata": {}, "source": ["x = 1  \n"], "outputs": []},
            ],
            "metadata": {},
            "nbformat": 4,
            "nbformat_minor": 5,
        }
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "test.ipynb"
            output = Path(directory) / "test.typ"
            source.write_text(json.dumps(notebook), encoding="utf-8")
            convert_notebook(str(source), str(output), chapter_number=1)
            self.assertIsNone(re.search(r"[ \t]+$", output.read_text(encoding="utf-8"), re.MULTILINE))

    def test_all_core_notebook_cells_pass_offline_audit(self) -> None:
        failures = {
            item.path: item.errors
            for item in audit_all(ROOT)
            if item.errors
        }
        self.assertEqual({}, failures)

    def test_interrupt_validation_reprompts_without_inner_loop(self) -> None:
        for relative, definition_cell, graph_cell in (
            ("03_langgraph/08_interrupts_and_time_travel.ipynb", "cell-19", "cell-20"),
            ("en/03_langgraph/08_interrupts_and_time_travel.ipynb", "cell-16", "cell-17"),
        ):
            namespace = {
                "TypedDict": TypedDict,
                "END": END,
                "START": START,
                "StateGraph": StateGraph,
                "InMemorySaver": InMemorySaver,
                "interrupt": interrupt,
            }
            exec(cell_source(relative, definition_cell), namespace)
            exec(cell_source(relative, graph_cell), namespace)
            graph = namespace["age_graph"]
            config = {"configurable": {"thread_id": f"test-{definition_cell}"}}

            first = graph.invoke(
                {"age": None, "pending_question": None},
                config,
                version="v2",
            )
            self.assertTrue(first.interrupts)
            invalid = graph.invoke(Command(resume=-1), config, version="v2")
            self.assertTrue(invalid.interrupts)
            valid = graph.invoke(Command(resume=30), config, version="v2")
            self.assertEqual(30, valid.value["age"])

    def test_custom_backend_examples_execute_on_stable_contract(self) -> None:
        for relative in (
            "04_deepagents/04_backends.ipynb",
            "en/04_deepagents/04_backends.ipynb",
        ):
            namespace: dict[str, object] = {}
            exec(cell_source(relative, "cell-19"), namespace)
            backend = namespace["custom_backend"]
            self.assertIsNone(backend.ls("/").error)
            self.assertIsNone(backend.read("/docs/guide.md").error)
            self.assertIsNone(backend.grep("install" if relative.startswith("en/") else "설치").error)

    def test_hitl_policies_separate_reject_from_respond(self) -> None:
        for relative in (
            "02_langchain/07_hitl_and_runtime.ipynb",
            "en/02_langchain/07_hitl_and_runtime.ipynb",
        ):
            source = cell_source(relative, "cell-7")
            self.assertIn('"send_email": {"allowed_decisions": ["approve", "edit", "reject"]}', source)
            self.assertIn('"ask_user": {"allowed_decisions": ["respond"]}', source)

    def test_directly_invoked_subagent_uses_concrete_checkpointer(self) -> None:
        source = cell_source("02_langchain/08_multi_agent.ipynb", "cell-10")
        self.assertIn("checkpointer=math_memory", source)
        self.assertIn("math_memory = InMemorySaver()", source)
        self.assertNotIn("checkpointer=True", source)

    def test_stable_backend_contract_is_documented_without_inventing_delete(self) -> None:
        self.assertFalse(hasattr(BackendProtocol, "delete"))
        docs = (ROOT / "docs/deepagents/06-backends.md").read_text(encoding="utf-8")
        self.assertIn("deepagents==0.6.12", docs)
        self.assertIn("0.7.0a6", docs)


if __name__ == "__main__":
    unittest.main()
