# English Handbook Worktree

This directory contains the English Typst handbook worktree.

## Current state

- `metadata.typ`, `template.typ`, frontmatter, and glossary are prepared.
- English chapter `.typ` files have been generated under `chapters/part*/` from the translated notebooks.
- English diagram assets have been generated under `../assets/images/` and copied into `assets/images/` for the handbook.
- `agent-handbook-en.pdf` is now generated from a **full compile** in `main.typ` that includes the translated chapter sources.

## Key files

- `main.typ` — current English handbook entry point
- `agent-handbook-en.pdf` — final compiled English handbook PDF
- `scripts/config.yaml` — English notebook-to-Typst mapping
- `chapters/` — generated English chapter sources
