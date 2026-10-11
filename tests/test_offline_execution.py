"""Keep offline exclusions from hiding ordinary notebook errors."""

import argparse
import contextlib
import io
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts.execute_notebooks_offline import (
    classify_error,
    clear_outputs,
    defined_names,
    main,
)


class OfflineEvidenceTests(unittest.TestCase):
    def test_credential_name_in_source_does_not_hide_type_error(self):
        source = 'assert os.getenv("OPENAI_API_KEY")\ncreate_agent(prompt="bad")'
        self.assertIsNone(
            classify_error(
                source,
                "TypeError",
                "create_agent() got an unexpected keyword argument 'prompt'",
                source,
                set(),
            )
        )

    def test_nested_function_locals_are_not_missing_globals(self):
        self.assertEqual(
            defined_names(
                "import os\ndef tool():\n    local_result = 1\n    return local_result"
            ),
            {"os", "tool"},
        )

    def test_missing_core_module_is_not_optional(self):
        self.assertIsNone(
            classify_error(
                "import langgraph.bad_example",
                "ModuleNotFoundError",
                "No module named 'langgraph.bad_example'",
                "",
                set(),
            )
        )

    def test_missing_provider_key_is_an_explicit_exclusion(self):
        result = classify_error(
            'assert os.getenv("GROQ_API_KEY")',
            "AssertionError",
            "GROQ_API_KEY required",
            "",
            set(),
        )
        self.assertIsNotNone(result)
        assert result is not None
        self.assertEqual(result[0], "external_api")

    def test_missing_optional_provider_is_an_environment_exclusion(self):
        result = classify_error(
            "from langchain_weaviate import WeaviateVectorStore",
            "ModuleNotFoundError",
            "No module named 'langchain_weaviate'",
            "",
            set(),
        )
        self.assertIsNotNone(result)
        assert result is not None
        self.assertEqual(result[0], "environment")

    def test_old_outputs_are_removed_before_execution(self):
        notebook = {
            "cells": [
                {
                    "cell_type": "code",
                    "outputs": [{"output_type": "stream", "text": "old data"}],
                    "execution_count": 8,
                }
            ]
        }
        clear_outputs(notebook)
        self.assertEqual(notebook["cells"][0]["outputs"], [])
        self.assertIsNone(notebook["cells"][0]["execution_count"])

    def test_optional_postgres_store_is_distinct_from_core_import_errors(self):
        result = classify_error(
            "from langgraph.store.postgres import PostgresStore",
            "ModuleNotFoundError",
            "No module named 'langgraph.store.postgres'",
            "",
            set(),
        )
        assert result is not None
        self.assertEqual(result[0], "environment")

    def test_missing_local_ollama_model_requires_provider_evidence(self):
        message = 'model "qwen-example" not found (status code: 404)'
        result = classify_error(
            "model.invoke('ping')",
            "ResponseError",
            message,
            "ollama/_client.py",
            set(),
        )
        assert result is not None
        self.assertEqual(result[0], "environment")
        self.assertIsNone(
            classify_error(
                "custom.invoke('ping')", "ResponseError", message, "custom.py", set()
            )
        )

    def test_ordinary_permission_error_is_not_an_external_api_exclusion(self):
        self.assertIsNone(
            classify_error(
                "Path('report').write_text('data')",
                "PermissionError",
                "cannot write report",
                "",
                set(),
            )
        )

    def test_secret_pattern_hit_makes_an_otherwise_clean_run_fail(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "synthetic.txt").write_text("sk-" + "a" * 32)
            args = argparse.Namespace(
                run_root=root,
                worker=None,
                only=[],
                limit=None,
                jobs=1,
                timeout=1,
                max_iterations=1,
            )
            with (
                patch(
                    "scripts.execute_notebooks_offline.parse_args", return_value=args
                ),
                patch(
                    "scripts.execute_notebooks_offline.course_notebooks",
                    return_value=[],
                ),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                self.assertEqual(main(), 1)


if __name__ == "__main__":
    unittest.main()
