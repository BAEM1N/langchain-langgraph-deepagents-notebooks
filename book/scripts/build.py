#!/usr/bin/env python3
"""build.py — Full build orchestrator for Agent Handbook.

Usage:
    python build.py                  # full build
    python build.py --skip-diagrams  # skip mmdc rendering
    python build.py --convert-only   # only run notebook conversion
    python build.py --compile-only   # only run typst compile
"""

import argparse
import subprocess
import sys
import time
from pathlib import Path


BOOK_DIR = Path(__file__).parent.parent
SCRIPTS_DIR = Path(__file__).parent
CONFIG_PATH = SCRIPTS_DIR / "config.yaml"
MAIN_TYP = BOOK_DIR / "main.typ"
OUTPUT_DIR = BOOK_DIR
OUTPUT_PDF = BOOK_DIR / "agent-handbook.pdf"


def step(name: str):
    """Print a build step header."""
    print(f"\n{'='*60}")
    print(f"  {name}")
    print(f"{'='*60}")


def run_diagrams() -> bool:
    """Render Mermaid diagrams to SVG."""
    step("Step 1: Rendering Mermaid diagrams → SVG")
    result = subprocess.run(
        [sys.executable, str(SCRIPTS_DIR / "render_diagrams.py")],
        cwd=str(BOOK_DIR),
    )
    return result.returncode == 0


def run_convert() -> bool:
    """Convert all notebooks to Typst."""
    step("Step 2: Converting 59 notebooks → Typst")
    result = subprocess.run(
        [sys.executable, str(SCRIPTS_DIR / "nb2typ.py"), "--config", str(CONFIG_PATH)],
        cwd=str(BOOK_DIR),
    )
    return result.returncode == 0


def find_typst() -> str:
    """Find typst executable."""
    import shutil
    typst = shutil.which("typst")
    if typst:
        return typst
    # WinGet install location
    winget_path = Path.home() / "AppData/Local/Microsoft/WinGet/Packages"
    for p in winget_path.glob("Typst.Typst_*/typst-*/typst.exe"):
        return str(p)
    return "typst"


def run_compile() -> bool:
    """Compile Typst to PDF."""
    step("Step 3: Compiling Typst -> PDF")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    typst_cmd = find_typst()

    result = subprocess.run(
        [typst_cmd, "compile", str(MAIN_TYP), str(OUTPUT_PDF),
         "--font-path", "fonts",],
        cwd=str(BOOK_DIR),
        capture_output=True,
        text=True,
    )

    if result.returncode == 0:
        size_mb = OUTPUT_PDF.stat().st_size / (1024 * 1024)
        print(f"  OK PDF generated: {OUTPUT_PDF}")
        print(f"  OK Size: {size_mb:.1f} MB")
        return True
    else:
        print(f"  FAIL Compilation failed:")
        print(result.stderr[:2000])
        return False


def main():
    parser = argparse.ArgumentParser(description="Build Agent Handbook PDF")
    parser.add_argument("--skip-diagrams", action="store_true",
                        help="Skip Mermaid diagram rendering")
    parser.add_argument("--convert-only", action="store_true",
                        help="Only convert notebooks, don't compile")
    parser.add_argument("--compile-only", action="store_true",
                        help="Only compile Typst, skip conversion")
    args = parser.parse_args()

    start = time.time()
    print("=" * 60)
    print("  Agent Handbook -- Build Pipeline")
    print("=" * 60)

    success = True

    if not args.compile_only:
        if not args.skip_diagrams:
            if not run_diagrams():
                print("\nWARN Diagram rendering had errors (continuing...)")

        if not run_convert():
            print("\nFAIL Notebook conversion failed")
            success = False

    if success and not args.convert_only:
        if not run_compile():
            success = False

    elapsed = time.time() - start
    print(f"\n{'='*60}")
    if success:
        print(f"  OK Build completed in {elapsed:.1f}s")
    else:
        print(f"  FAIL Build failed after {elapsed:.1f}s")
    print(f"{'='*60}")

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
