from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from scripts.check_official_docs_alignment import (
    check_local,
    validate_notebook,
)


ROOT = Path(__file__).resolve().parents[1]


class OfficialDocsAlignmentTests(unittest.TestCase):
    def test_current_repository_is_aligned(self) -> None:
        self.assertEqual([], check_local(ROOT))

    def test_notebook_validation_reports_cell_id_and_syntax(self) -> None:
        notebook = {
            "cells": [
                {"cell_type": "markdown", "id": "wrong", "source": "# title"},
                {"cell_type": "code", "id": "cell-1", "source": "if True print('x')"},
            ],
            "metadata": {},
            "nbformat": 4,
            "nbformat_minor": 5,
        }
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "broken.ipynb"
            path.write_text(json.dumps(notebook), encoding="utf-8")
            violations = validate_notebook(path)

        codes = {violation.code for violation in violations}
        self.assertIn("notebook-cell-id", codes)
        self.assertIn("notebook-code-syntax", codes)

    def test_notebook_validation_accepts_ipython_magics(self) -> None:
        notebook = {
            "cells": [
                {"cell_type": "code", "id": "cell-0", "source": "%pip --version"},
            ],
            "metadata": {},
            "nbformat": 4,
            "nbformat_minor": 5,
        }
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "magic.ipynb"
            path.write_text(json.dumps(notebook), encoding="utf-8")
            violations = validate_notebook(path)

        self.assertEqual([], violations)


if __name__ == "__main__":
    unittest.main()
