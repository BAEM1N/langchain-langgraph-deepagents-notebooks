"""Preserve notebook code-language intent in derived handbook chapters."""

import importlib.util
import unittest
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1] / "book/scripts/nb2typ.py"
SPEC = importlib.util.spec_from_file_location("nb2typ", SOURCE)
assert SPEC is not None and SPEC.loader is not None
CONVERTER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CONVERTER)


class MarkdownFences(unittest.TestCase):
    def test_unlabelled_diagram_is_not_python(self):
        rendered = CONVERTER.convert_markdown_cell("```\nSTART → classify → END\n```")
        self.assertIn("START → classify → END", rendered)
        self.assertNotIn("`````python", rendered)

    def test_python_fence_keeps_highlighting(self):
        rendered = CONVERTER.convert_markdown_cell("```python\nvalue = 3\n```")
        self.assertIn("`````python\nvalue = 3", rendered)

    def test_code_cell_remains_python(self):
        rendered = CONVERTER.convert_code_cell(
            {"source": ["value = 3\n"], "outputs": []}
        )
        self.assertIn("`````python\nvalue = 3", rendered)


if __name__ == "__main__":
    unittest.main()
