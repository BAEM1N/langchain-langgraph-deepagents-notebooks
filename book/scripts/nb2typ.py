#!/usr/bin/env python3
"""nb2typ.py — Convert Jupyter notebooks (.ipynb) to Typst (.typ) files.

Usage:
    python nb2typ.py <notebook.ipynb> <output.typ> [--chapter-number N]
    python nb2typ.py --config config.yaml   # batch convert all notebooks
"""

import json
import re
import sys
import argparse
from pathlib import Path
from typing import Optional

import yaml


# ─── Typst special character escaping ──────────────────────────
TYPST_SPECIAL = {
    '#': '\\#',
    '@': '\\@',
    '$': '\\$',
}

def escape_typst(text: str) -> str:
    """Escape Typst special characters in plain text."""
    for char, escaped in TYPST_SPECIAL.items():
        text = text.replace(char, escaped)
    # Escape < and > only when they look like tags (not math/comparison)
    text = re.sub(r'<(?![=>])', '\\<', text)
    text = re.sub(r'(?<![=<-])>', '\\>', text)
    return text


# ─── Inline markdown → Typst conversion ───────────────────────
def convert_inline(text: str) -> str:
    """Convert inline markdown formatting to Typst."""
    # Protect code spans before applying Markdown emphasis. This lets patterns
    # such as **`invoke()`** become *`invoke()`* instead of leaking raw ** into
    # Typst, which compiles with noisy "no text within stars" warnings.
    code_spans: list[str] = []

    def _stash_code(m: re.Match) -> str:
        code_spans.append(f'`{m.group(1)}`')
        return f'@@CODE{len(code_spans) - 1}@@'

    protected = re.sub(r'`([^`]+)`', _stash_code, text)
    converted = _convert_inline_no_code(protected)

    for idx, code in enumerate(code_spans):
        converted = converted.replace(f'@@CODE{idx}@@', code)
    return converted


def _convert_inline_no_code(text: str) -> str:
    """Convert inline markdown (bold, italic, links) outside of code spans."""
    if not text:
        return text

    # Images: ![alt](path) → #image("path") — must be before links
    def _fix_image_path(m):
        path = m.group(2)
        # Fix relative paths: assets are copied into book/assets/
        # typ files are at book/chapters/partN/, so go up 2 levels
        clean = path.lstrip('./')
        if clean.startswith('assets/'):
            path = '../../' + clean
        return f'#image("{path}")'

    text = re.sub(
        r'!\[([^\]]*)\]\(([^)]+)\)',
        _fix_image_path,
        text
    )

    # Links: [text](url) → #link("url")[text]
    text = re.sub(
        r'\[([^\]]+)\]\(([^)]+)\)',
        lambda m: f'#link("{m.group(2)}")[{m.group(1)}]',
        text
    )

    # Bold+italic: ***text*** or ___text___
    text = re.sub(r'\*\*\*(.+?)\*\*\*', r'*_\1_*', text)

    # Bold: **text** → *text*
    # Handle **`code`** → *`code`* carefully
    text = re.sub(r'\*\*(`[^`]+`)\*\*', r'*\1*', text)
    text = re.sub(r'\*\*([^*`]+)\*\*', r'*\1*', text)

    # Italic: *text* → _text_ (but not inside bold)
    text = re.sub(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)', r'_\1_', text)

    # Escape ALL angle brackets to prevent Typst label parsing
    # Exception: URLs inside #link("...") are already safe
    text = text.replace('<', '\\<').replace('>', '\\>')

    return text


def _escape_heading(text: str) -> str:
    """Escape special chars in heading text (@ # < >)."""
    text = text.replace('@', '\\@')
    text = text.replace('<', '\\<')
    text = text.replace('>', '\\>')
    # Convert inline formatting in heading
    text = convert_inline(text)
    return text


# ─── Markdown table → Typst table ─────────────────────────────
def convert_table(lines: list[str]) -> str:
    """Convert a markdown table to Typst #table()."""
    rows = []
    for line in lines:
        line = line.strip()
        if not line.startswith('|'):
            continue
        # Skip separator row (|---|---|)
        if re.match(r'\|[\s\-:]+\|', line):
            continue
        cells = [c.strip() for c in line.split('|')[1:-1]]
        rows.append(cells)

    if not rows:
        return ''

    n_cols = len(rows[0])
    result = [f'#table(\n  columns: {n_cols},']
    result.append(f'  align: left,')
    result.append(f'  stroke: 0.5pt + luma(200),')
    result.append(f'  inset: 8pt,')
    result.append(f'  fill: (_, row) => if row == 0 {{ rgb("#E0F2F3") }} else if calc.odd(row) {{ luma(248) }} else {{ white }},')

    for i, row in enumerate(rows):
        for cell in row:
            cell_text = convert_inline(cell)
            # Escape content that would break Typst brackets
            cell_text = cell_text.replace('\\', '\\\\')
            # Escape special chars in table cells
            cell_text = cell_text.replace('#', '\\#')
            cell_text = cell_text.replace('$', '\\$')
            cell_text = cell_text.replace('<', '\\<')
            cell_text = cell_text.replace('>', '\\>')
            cell_text = re.sub(r'@(?=\w)', '\\@', cell_text)
            if i == 0:
                result.append(f'  text(weight: "bold")[{cell_text}],')
            else:
                result.append(f'  [{cell_text}],')

    result.append(')')
    return '\n'.join(result)


# ─── Blockquote → admonition box ──────────────────────────────
def convert_blockquote(lines: list[str]) -> str:
    """Convert blockquote to tip/note/warning box."""
    content = ' '.join(line.lstrip('> ').strip() for line in lines)

    # Detect type from content keywords
    lower = content.lower()
    if any(w in lower for w in ['경고', 'warning', '주의', '위험']):
        return f'#warning-box[{convert_inline(content)}]'
    elif any(w in lower for w in ['참고', 'note', '노트', '메모']):
        return f'#note-box[{convert_inline(content)}]'
    else:
        return f'#tip-box[{convert_inline(content)}]'


# ─── Markdown cell → Typst ─────────────────────────────────────
def convert_markdown_cell(source: str, is_first_cell: bool = False,
                          chapter_number: Optional[int] = None) -> str:
    """Convert a markdown cell to Typst markup."""
    lines = source.split('\n')
    output_lines = []
    i = 0

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Empty line
        if not stripped:
            output_lines.append('')
            i += 1
            continue

        # Chapter title (first cell, # heading)
        if is_first_cell and stripped.startswith('# ') and chapter_number is not None:
            # Parse: # NN. Title — Subtitle
            title_match = re.match(r'#\s+\d+\.\s+(.+?)(?:\s*[—–-]\s*(.+))?$', stripped)
            if title_match:
                title = title_match.group(1).strip()
                subtitle = title_match.group(2)
                if subtitle:
                    output_lines.append(f'#chapter({chapter_number}, "{title}", subtitle: "{subtitle.strip()}")')
                else:
                    output_lines.append(f'#chapter({chapter_number}, "{title}")')
                i += 1
                # Skip the next line if it's the subtitle paragraph
                if i < len(lines) and lines[i].strip() and not lines[i].strip().startswith('#'):
                    output_lines.append('')
                    output_lines.append(convert_inline(lines[i].strip()))
                    i += 1
                continue

        # Top-level heading (# ) in non-first cells → treat as level 2 section
        if not is_first_cell and re.match(r'^#\s+(.+)$', stripped):
            title_text = stripped[2:].strip()
            title_text = _escape_heading(title_text)
            output_lines.append(f'== {title_text}')
            i += 1
            continue

        # Headings: ## → ==, ### → ===, #### → ====
        # Level 1 (=) is reserved for Part headings in the outline
        heading_match = re.match(r'^(#{2,6})\s+(.+)$', stripped)
        if heading_match:
            level = len(heading_match.group(1))  # ## → 2 (==), ### → 3 (===)
            prefix = '=' * level
            title_text = heading_match.group(2).strip()

            # 학습 목표 section — convert to learning objectives
            if '학습 목표' in title_text:
                output_lines.append(f'{prefix} 학습 목표')
                i += 1
                # Collect bullet points
                objectives = []
                while i < len(lines):
                    l = lines[i].strip()
                    if l.startswith('- '):
                        objectives.append(l[2:])
                        i += 1
                    elif l == '':
                        i += 1
                        # Check if next line is still a bullet
                        if i < len(lines) and lines[i].strip().startswith('- '):
                            continue
                        break
                    else:
                        break
                if objectives:
                    args = ', '.join(f'[{convert_inline(o)}]' for o in objectives)
                    output_lines.append(f'#learning-objectives({args})')
                continue

            # 요약 section — use custom summary header
            if title_text.endswith('요약') or title_text == '요약':
                output_lines.append('#chapter-summary-header()')
                i += 1
                continue

            # 다음 단계 section — skip entirely (not needed in book format)
            if '다음 단계' in title_text:
                i += 1
                while i < len(lines):
                    l = lines[i].strip()
                    if not l:
                        if i + 1 < len(lines) and lines[i + 1].strip():
                            next_l = lines[i + 1].strip()
                            if next_l.startswith('#') or re.match(r'^-{3,}$', next_l) or '참고 문서' in next_l:
                                break
                            i += 1
                            continue
                        break
                    if re.match(r'^-{3,}$|^\*{3,}$|^_{3,}$', l):
                        break
                    if '참고 문서' in l:
                        break
                    i += 1
                continue

            output_lines.append(f'{prefix} {_escape_heading(title_text)}')
            i += 1
            continue

        # Horizontal rule — convert to nothing if followed by 참고 문서 (handled separately)
        if re.match(r'^-{3,}$|^\*{3,}$|^_{3,}$', stripped):
            # Check if this is the divider before 참고 문서
            next_content = ''
            for j in range(i + 1, min(i + 3, len(lines))):
                if lines[j].strip():
                    next_content = lines[j].strip()
                    break
            if '참고 문서' in next_content:
                i += 1
                continue  # skip — references-box handles its own styling
            output_lines.append('#line(length: 100%, stroke: 0.5pt + luma(200))')
            i += 1
            continue

        # Table detection
        if stripped.startswith('|') and i + 1 < len(lines):
            table_lines = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                table_lines.append(lines[i])
                i += 1
            if len(table_lines) >= 2:
                output_lines.append(convert_table(table_lines))
            continue

        # Blockquote
        if stripped.startswith('> '):
            quote_lines = []
            while i < len(lines) and lines[i].strip().startswith('> '):
                quote_lines.append(lines[i])
                i += 1
            output_lines.append(convert_blockquote(quote_lines))
            continue

        # Unordered list
        if re.match(r'^[-*+]\s', stripped):
            output_lines.append(f'- {convert_inline(stripped[2:])}')
            i += 1
            continue

        # Ordered list
        ol_match = re.match(r'^(\d+)\.\s+(.+)$', stripped)
        if ol_match:
            output_lines.append(f'+ {convert_inline(ol_match.group(2))}')
            i += 1
            continue

        # Fenced code block in markdown
        if stripped.startswith('```'):
            lang = stripped[3:].strip() or "python"
            code_lines = []
            i += 1
            while i < len(lines) and not lines[i].strip().startswith('```'):
                code_lines.append(lines[i])
                i += 1
            i += 1  # skip closing ```
            code = '\n'.join(code_lines)
            output_lines.append(f'#code-block(`````{lang}\n{code}\n`````)')
            continue

        # 참고 문서 section — collect and wrap in references-box
        if '참고 문서' in stripped:
            i += 1
            ref_lines = []
            while i < len(lines):
                l = lines[i].strip()
                if not l:
                    i += 1
                    continue
                if l.startswith('- ') or l.startswith('* '):
                    ref_lines.append(f'- {convert_inline(l[2:])}')
                    i += 1
                elif l.startswith('#'):
                    break  # next heading
                else:
                    ref_lines.append(convert_inline(l))
                    i += 1
            if ref_lines:
                content = '\n'.join(ref_lines)
                output_lines.append(f'#references-box[\n{content}\n]')
            output_lines.append('#chapter-end()')
            continue

        # Regular paragraph
        output_lines.append(convert_inline(stripped))
        i += 1

    return '\n'.join(output_lines)


# ─── Code cell → Typst ─────────────────────────────────────────
def convert_code_cell(cell: dict, skip_patterns: list[str] = None) -> str:
    """Convert a code cell to Typst code-block + output-block."""
    source = ''.join(cell.get('source', []))
    if not source.strip():
        return ''

    # Check skip patterns
    if skip_patterns:
        for pattern in skip_patterns:
            if pattern in source:
                return ''

    parts = []

    # Code block
    parts.append(f'#code-block(`````python\n{source}\n`````)')

    # Outputs
    outputs = cell.get('outputs', [])
    output_text = extract_output_text(outputs)
    if output_text:
        parts.append(f'#output-block(`````\n{output_text}\n`````)')

    return '\n'.join(parts)


def extract_output_text(outputs: list, max_lines: int = 30) -> str:
    """Extract text from cell outputs."""
    texts = []
    for output in outputs:
        otype = output.get('output_type', '')

        if otype == 'stream':
            text = ''.join(output.get('text', []))
            texts.append(text)
        elif otype in ('execute_result', 'display_data'):
            data = output.get('data', {})
            if 'text/plain' in data:
                text = ''.join(data['text/plain'])
                texts.append(text)
        elif otype == 'error':
            ename = output.get('ename', 'Error')
            evalue = output.get('evalue', '')
            texts.append(f'{ename}: {evalue}')

    if not texts:
        return ''

    combined = '\n'.join(texts).strip()
    lines = combined.split('\n')
    if len(lines) > max_lines:
        lines = lines[:max_lines]
        lines.append('... (truncated)')
    return '\n'.join(lines)


# ─── Full notebook conversion ──────────────────────────────────
def convert_notebook(nb_path: str, output_path: str,
                     chapter_number: int = 0,
                     skip_patterns: list[str] = None,
                     first_chapter_observability: bool = False) -> None:
    """Convert a single notebook to a Typst file."""
    with open(nb_path, 'r', encoding='utf-8') as f:
        nb = json.load(f)

    cells = nb.get('cells', [])
    parts = []

    # File header with template import
    parts.append(f'// Auto-generated from {Path(nb_path).name}')
    parts.append(f'// Do not edit manually -- regenerate with nb2typ.py')
    parts.append(f'#import "../../template.typ": *')
    parts.append(f'#import "../../metadata.typ": *')
    parts.append('')

    is_first_cell = True
    skip_observability = not first_chapter_observability

    for cell in cells:
        cell_type = cell.get('cell_type', '')
        source = ''.join(cell.get('source', []))

        if cell_type == 'markdown':
            converted = convert_markdown_cell(
                source,
                is_first_cell=is_first_cell,
                chapter_number=chapter_number
            )
            if converted.strip():
                parts.append(converted)
                parts.append('')
            is_first_cell = False

        elif cell_type == 'code':
            # Skip observability cells (except in first chapter)
            if skip_observability and any(p in source for p in (skip_patterns or [])):
                continue

            converted = convert_code_cell(cell, skip_patterns=None)
            if converted.strip():
                parts.append(converted)
                parts.append('')

    # Write output
    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)
    rendered = '\n'.join(line.rstrip() for line in '\n'.join(parts).splitlines())
    with open(output, 'w', encoding='utf-8') as f:
        f.write(rendered.rstrip() + '\n')

    print(f"  OK {Path(nb_path).name} -> {output.name}")


# ─── Batch conversion from config ─────────────────────────────
def batch_convert(config_path: str, base_dir: str = None) -> None:
    """Convert all notebooks defined in config.yaml."""
    with open(config_path, 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)

    if base_dir is None:
        base_dir = str(Path(config_path).parent.parent.parent)

    book_dir = Path(config_path).parent.parent
    skip_patterns = config.get('skip_patterns', [])
    max_lines = config.get('output_truncate_lines', 30)

    for part in config['parts']:
        part_num = part['number']
        source_dir = part['source_dir']
        part_dir = book_dir / 'chapters' / f'part{part_num}'
        part_dir.mkdir(parents=True, exist_ok=True)

        print(f"\nPart {part_num}: {part['title']}")

        for idx, ch in enumerate(part['chapters']):
            nb_path = Path(base_dir) / source_dir / ch['source']
            out_path = part_dir / ch['output']

            if not nb_path.exists():
                print(f"  SKIP {ch['source']} -- not found")
                continue

            # Extract chapter number from filename
            ch_num_match = re.match(r'ch(\d+)', ch['output'])
            ch_num = int(ch_num_match.group(1)) if ch_num_match else idx

            # First chapter of first part gets observability
            first_ch_obs = (part_num == 1 and idx == 0)

            convert_notebook(
                str(nb_path),
                str(out_path),
                chapter_number=ch_num,
                skip_patterns=skip_patterns,
                first_chapter_observability=first_ch_obs,
            )


# ─── CLI ───────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description='Convert Jupyter notebooks to Typst')
    parser.add_argument('input', nargs='?', help='Input notebook path')
    parser.add_argument('output', nargs='?', help='Output .typ path')
    parser.add_argument('--chapter-number', '-n', type=int, default=0,
                        help='Chapter number for heading')
    parser.add_argument('--config', '-c', help='Config YAML for batch conversion')

    args = parser.parse_args()

    if args.config:
        batch_convert(args.config)
    elif args.input and args.output:
        convert_notebook(args.input, args.output, chapter_number=args.chapter_number)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == '__main__':
    main()
