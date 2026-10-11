#!/usr/bin/env python3
"""Rebuild deck outputs from portable editable source under decks/source.

Run from the repository root with:

    uv run --no-project \
      --with playwright --with beautifulsoup4 --with pymupdf --with python-pptx \
      decks/source/build_all_decks.py

The generated PPTX preserves the existing distribution format: each slide is a
full-slide rendered image with speaker notes. Edit the Python content/speech
files and CSS/HTML assets in decks/source, then rebuild.
"""
from __future__ import annotations

import csv
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
from html import escape
from pathlib import Path

import fitz
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright
from pptx import Presentation
from pptx.util import Inches


ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(__file__).resolve().parent
RENDER = ROOT / ".local" / "deck_source_render"
DECKS = ROOT / "decks"

TRACKS = [
    "01_beginner",
    "02_langchain",
    "03_langgraph",
    "04_deepagents",
    "05_advanced",
]

SCRIPT_META = {
    "01_beginner": ("AI 에이전트 개발 — 발표자 대본", "LangChain · LangGraph · Deep Agents 미리보기", "source-repo/01_beginner/*.ipynb"),
    "02_langchain": ("LangChain 마스터 — 강사용 상세 대본", "LangChain v1 실전 에이전트 개발", "source-repo/02_langchain/*.ipynb"),
    "03_langgraph": ("LangGraph 마스터 — 강사용 상세 대본", "상태 그래프와 운영형 에이전트 워크플로", "source-repo/03_langgraph/*.ipynb"),
    "04_deepagents": ("Deep Agents 마스터 — 강사용 상세 대본", "장기 작업 에이전트와 운영 하네스", "source-repo/04_deepagents/*.ipynb"),
    "05_advanced": ("Advanced Agent Engineering — 강사용 상세 대본", "RAG · HITL · MCP · 평가 · 멀티에이전트 운영", "source-repo/05_advanced/*.ipynb"),
}

SCRIPT_CSS = """
@page { size: A4; margin: 16mm 15mm 18mm 15mm; }
* { box-sizing: border-box; }
body { font-family: -apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", "Pretendard", "Noto Sans KR", sans-serif; color:#111827; line-height:1.62; font-size:13.2px; }
h1 { font-size:24px; line-height:1.25; margin:0 0 16px; color:#071521; page-break-after:avoid; }
h2 { font-size:15.5px; line-height:1.35; margin:24px 0 8px; color:#0b3b5a; border-top:1px solid #dbe6ef; padding-top:12px; page-break-after:avoid; }
p { margin:0 0 10px; orphans:3; widows:3; }
blockquote { margin:0 0 18px; padding:10px 12px; background:#eef7ff; border-left:4px solid #53b8ff; color:#334155; }
code, .mono { font-family:"SFMono-Regular", "JetBrains Mono", Consolas, monospace; font-size:0.95em; color:#0f5f8f; }
"""


def run_build(track: str) -> None:
    subprocess.run([sys.executable, "build_deck.py"], cwd=SOURCE / track, check=True)


def render_slide_pdf(page, track: str) -> None:
    html = (SOURCE / track / f"{track}.html").resolve()
    out = DECKS / track / f"{track}.pdf"
    page.goto(html.as_uri(), wait_until="domcontentloaded")
    try:
        page.wait_for_load_state("networkidle", timeout=8000)
    except Exception:
        pass
    page.emulate_media(media="print")
    page.pdf(path=str(out), prefer_css_page_size=True, print_background=True)


def pdf_to_pngs(track: str) -> list[Path]:
    pdf_path = DECKS / track / f"{track}.pdf"
    out_dir = RENDER / track / "png"
    shutil.rmtree(out_dir, ignore_errors=True)
    out_dir.mkdir(parents=True, exist_ok=True)
    doc = fitz.open(pdf_path)
    pngs: list[Path] = []
    matrix = fitz.Matrix(2, 2)
    for idx, page in enumerate(doc, start=1):
        pix = page.get_pixmap(matrix=matrix, alpha=False)
        path = out_dir / f"hp-{idx:03d}.png"
        pix.save(path)
        pngs.append(path)
    return pngs


def build_pptx(track: str, pngs: list[Path]) -> None:
    speeches_path = SOURCE / track / "_render" / "speeches.json"
    speeches = json.loads(speeches_path.read_text(encoding="utf-8"))
    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank = prs.slide_layouts[6]
    for i, png in enumerate(pngs):
        slide = prs.slides.add_slide(blank)
        slide.shapes.add_picture(str(png), 0, 0, width=prs.slide_width, height=prs.slide_height)
        if i < len(speeches) and speeches[i]:
            slide.notes_slide.notes_text_frame.text = speeches[i]
    prs.save(DECKS / track / f"{track}.pptx")


def inline_md(text: str) -> str:
    parts = text.split("`")
    return "".join(f"<code>{escape(part)}</code>" if i % 2 else escape(part) for i, part in enumerate(parts))


def md_to_html(markdown: str) -> str:
    html = [f'<!doctype html><html><head><meta charset="utf-8"><style>{SCRIPT_CSS}</style></head><body>']
    para: list[str] = []

    def flush() -> None:
        if para:
            html.append("<p>" + inline_md(" ".join(para).strip()) + "</p>")
            para.clear()

    for raw in markdown.splitlines():
        line = raw.rstrip()
        if not line:
            flush()
        elif line.startswith("> "):
            flush()
            html.append("<blockquote>" + inline_md(line[2:].strip()) + "</blockquote>")
        elif line.startswith("# "):
            flush()
            html.append("<h1>" + inline_md(line[2:].strip()) + "</h1>")
        elif line.startswith("## "):
            flush()
            html.append("<h2>" + inline_md(line[3:].strip()) + "</h2>")
        elif line.startswith("- "):
            flush()
            html.append("<p>" + inline_md(line.strip()) + "</p>")
        elif line.startswith("<!--"):
            flush()
        else:
            para.append(line.strip())
    flush()
    html.append("</body></html>")
    return "".join(html)


def section_title(section, fallback: str) -> str:
    for selector in [".s-title", ".hero-title", ".divider-title", "h1", "h2"]:
        tag = section.select_one(selector)
        if tag:
            text = " ".join(tag.get_text(" ", strip=True).split())
            if text:
                return text
    return fallback


def render_script(page, track: str) -> None:
    deck_html = SOURCE / track / f"{track}.html"
    speeches_path = SOURCE / track / "_render" / "speeches.json"
    soup = BeautifulSoup(deck_html.read_text(encoding="utf-8"), "html.parser")
    sections = soup.find_all("section")
    speeches = json.loads(speeches_path.read_text(encoding="utf-8"))
    if len(sections) != len(speeches):
        raise RuntimeError(f"{track}: section/speech mismatch {len(sections)} != {len(speeches)}")
    title, subtitle, source = SCRIPT_META[track]
    lines = [f"# {title}", "", f"- 슬라이드 수: {len(sections)}"]
    if subtitle:
        lines.append(f"- 부제: {subtitle}")
    if source:
        lines.append(f"- 기준: {source}")
    lines.append("")
    for idx, (section, note) in enumerate(zip(sections, speeches), start=1):
        lines += [f"## {idx:02d}. {section_title(section, f'슬라이드 {idx}')}", "", str(note).strip() or "(발표자 노트 없음)", ""]
    md = "\n".join(lines).rstrip() + "\n"
    md_path = DECKS / track / f"{track}_대본.md"
    md_path.write_text(md, encoding="utf-8")
    html_path = RENDER / track / f"{track}_대본.html"
    html_path.parent.mkdir(parents=True, exist_ok=True)
    html_path.write_text(md_to_html(md), encoding="utf-8")
    page.goto(html_path.resolve().as_uri(), wait_until="networkidle")
    page.pdf(
        path=str(DECKS / track / f"{track}_대본.pdf"),
        format="A4",
        print_background=True,
        margin={"top": "16mm", "right": "15mm", "bottom": "18mm", "left": "15mm"},
    )


def count_pdf_pages(path: Path) -> int:
    with fitz.open(path) as doc:
        return doc.page_count


def update_readmes_and_manifest() -> None:
    rows = []
    for track in TRACKS:
        script_md = DECKS / track / f"{track}_대본.md"
        sections = len(re.findall(r"^## ", script_md.read_text(encoding="utf-8"), re.MULTILINE))
        rows.append({
            "track": track,
            "pptx_slides": count_pdf_pages(DECKS / track / f"{track}.pdf"),
            "slide_pdf_pages": count_pdf_pages(DECKS / track / f"{track}.pdf"),
            "script_pdf_pages": count_pdf_pages(DECKS / track / f"{track}_대본.pdf"),
            "script_sections": sections,
            "has_pptx": "true",
            "has_script_md": "true",
        })
    with (DECKS / "manifest.csv").open("w", encoding="utf-8", newline="") as fp:
        writer = csv.DictWriter(fp, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    RENDER.mkdir(parents=True, exist_ok=True)
    for track in TRACKS:
        run_build(track)
    with sync_playwright() as p:
        executable_path = os.environ.get("PLAYWRIGHT_CHROMIUM_EXECUTABLE")
        if executable_path is None:
            candidate = Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")
            executable_path = str(candidate) if candidate.exists() else None
        browser = p.chromium.launch(executable_path=executable_path)
        slide_page = browser.new_page(viewport={"width": 1920, "height": 1080}, device_scale_factor=1)
        script_page = browser.new_page(viewport={"width": 1240, "height": 1754}, device_scale_factor=1)
        for track in TRACKS:
            render_slide_pdf(slide_page, track)
            pngs = pdf_to_pngs(track)
            build_pptx(track, pngs)
            render_script(script_page, track)
            print(f"{track}: {len(pngs)} slides")
        browser.close()
    update_readmes_and_manifest()


if __name__ == "__main__":
    main()
