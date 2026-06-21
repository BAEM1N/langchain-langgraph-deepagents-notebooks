#!/usr/bin/env python3
from pathlib import Path
import shutil
import subprocess

BOOK_DIR = Path(__file__).resolve().parent.parent
OUTPUT_PDF = BOOK_DIR / "agent-handbook-en.pdf"

def main() -> int:
    # compile-only boundary: this validates the curated Typst tree, not
    # freshness of notebook-derived generated chapters. Refresh those with
    # `python book/scripts/nb2typ.py --config en/book/scripts/config.yaml`.
    typst = shutil.which("typst")
    if not typst:
        print("typst is not installed")
        return 1
    repo_root = BOOK_DIR.parent.parent
    shared_fonts = repo_root / "book" / "fonts"
    cmd = [
        typst,
        "compile",
        str(BOOK_DIR / "main.typ"),
        str(OUTPUT_PDF),
        "--root",
        str(repo_root),
        "--font-path",
        str(shared_fonts),
    ]
    print("English handbook compile-only: refresh generated chapters with en/book/scripts/config.yaml when notebooks change.")
    result = subprocess.run(cmd, cwd=str(BOOK_DIR))
    return result.returncode

if __name__ == "__main__":
    raise SystemExit(main())
