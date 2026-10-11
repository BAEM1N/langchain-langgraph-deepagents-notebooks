"""Execute authored query helpers against an ID-only-by-default service fixture."""

import ast
import json
import unittest
from datetime import UTC, datetime, timedelta
from pathlib import Path
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parents[1]
TOPICS = {
    "01_quickstart": {"NAME"},
    "02_tracing_agents": {"NAME"},
    "03_datasets_and_evaluation": {"INPUTS", "OUTPUTS"},
    "05_production_monitoring": {"START_TIME", "END_TIME"},
}


class AuthoredQueryHelpers(unittest.IsolatedAsyncioTestCase):
    async def test_consumed_fields_are_requested_in_both_languages(self):
        for prefix in [ROOT, ROOT / "en"]:
            for topic in TOPICS:
                path = prefix / "06_langsmith" / f"{topic}.ipynb"
                notebook = json.loads(path.read_text())
                helpers = 0
                for cell in notebook["cells"]:
                    source = "".join(cell.get("source", []))
                    if (
                        cell["cell_type"] != "code"
                        or "async def collect_runs" not in source
                    ):
                        continue
                    with self.subTest(
                        notebook=str(path.relative_to(ROOT)), helper=helpers
                    ):
                        calls = []

                        class Runs:
                            async def query(self, _calls=calls, **query):
                                _calls.append(query)
                                selected = query.get("selects", [])
                                values = {
                                    "ID": "run-1",
                                    "NAME": "example",
                                    "INPUTS": {"question": "example"},
                                    "OUTPUTS": {"answer": "example"},
                                    "START_TIME": datetime.now(UTC),
                                    "END_TIME": datetime.now(UTC),
                                }
                                values.update(
                                    {
                                        field: {}
                                        for field in selected
                                        if field not in values
                                    }
                                )
                                yield SimpleNamespace(
                                    **{
                                        key.lower(): value
                                        for key, value in values.items()
                                        if key == "ID" or key in selected
                                    }
                                )

                        end = datetime.now(UTC)
                        namespace = {
                            "client": SimpleNamespace(runs=Runs()),
                            "project": SimpleNamespace(id="project-uuid"),
                            "window_start": end - timedelta(days=7),
                            "window_end": end,
                        }
                        tree = ast.parse(source)
                        expected = {
                            node.attr.upper()
                            for node in ast.walk(tree)
                            if isinstance(node, ast.Attribute)
                            and isinstance(node.value, ast.Name)
                            and node.value.id in {"r", "run", "latest", "row"}
                            and node.attr.upper()
                            in {
                                "NAME",
                                "INPUTS",
                                "OUTPUTS",
                                "START_TIME",
                                "END_TIME",
                                "TAGS",
                                "FEEDBACK_STATS",
                                "METADATA",
                                "RUN_TYPE",
                            }
                        }
                        definitions = []
                        for node in tree.body:
                            if isinstance(node, ast.Assign):
                                try:
                                    value = ast.literal_eval(node.value)
                                except (ValueError, TypeError):
                                    continue
                                for target in node.targets:
                                    if isinstance(target, ast.Name):
                                        namespace[target.id] = value
                            if (
                                isinstance(node, ast.AsyncFunctionDef)
                                and node.name == "collect_runs"
                            ):
                                definitions.append(node)
                        module = ast.Module(body=definitions, type_ignores=[])
                        exec(compile(module, str(path), "exec"), namespace)  # noqa: S102 -- reviewed repository function
                        rows = await namespace["collect_runs"](take=1)
                        self.assertEqual(len(rows), 1)
                        self.assertTrue(
                            expected <= set(calls[0].get("selects", [])), calls[0]
                        )
                        self.assertEqual(calls[0]["project_ids"], ["project-uuid"])
                        self.assertEqual(
                            calls[0]["min_start_time"], namespace["window_start"]
                        )
                        self.assertEqual(
                            calls[0]["max_start_time"], namespace["window_end"]
                        )
                        for field in expected:
                            self.assertIsNotNone(getattr(rows[0], field.lower()))
                    helpers += 1
                self.assertGreater(helpers, 0, str(path))


if __name__ == "__main__":
    unittest.main()
