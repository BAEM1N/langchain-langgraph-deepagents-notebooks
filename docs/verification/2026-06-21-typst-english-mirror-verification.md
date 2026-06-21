# Typst · English Mirror Verification — 2026-06-21

## Scope

Reflected the official-doc tutorial expansion in both learner notebooks and handbook outputs.

## Added English mirror notebooks

Created and executed 17 English mirrors for the 17 new Korean notebooks:

- `en/02_langchain/14_semantic_search.ipynb`
- `en/03_langgraph/15_backward_compatibility.ipynb`
- `en/03_langgraph/16_case_studies.ipynb`
- `en/04_deepagents/12_models_and_tools.ipynb`
- `en/04_deepagents/13_programmatic_subagents.ipynb`
- `en/04_deepagents/14_event_streaming.ipynb`
- `en/04_deepagents/15_permissions.ipynb`
- `en/04_deepagents/16_quality_profiles_rubric.ipynb`
- `en/05_advanced/10_deep_agent_from_scratch.ipynb`
- `en/05_advanced/11_custom_workflow_agent.ipynb`
- `en/06_langsmith/07_testing_strategy.ipynb`
- `en/06_langsmith/08_langgraph_testing.ipynb`
- `en/06_langsmith/09_runtime_rubric_evaluation.ipynb`
- `en/07_examples/10_personal_assistant_subagents.ipynb`
- `en/07_examples/11_customer_support_handoffs.ipynb`
- `en/07_examples/12_router_knowledge_base.ipynb`
- `en/07_examples/13_skills_sql_assistant.ipynb`

## Typst handbook updates

Added corresponding Typst chapters and updated part/index includes:

- Korean handbook: `book/main.typ`, `book/chapters/part*/_part.typ`, new `ch*.typ` files.
- English handbook: `en/book/main.typ`, `en/book/chapters/part*/_part.typ`, new `ch*.typ` files.
- Deep Agents manually maintained chapters `ch11~ch15` were preserved; new notebook-derived chapters start at `ch16~ch20`.
- Existing LangSmith chapters `ch01~ch06` were left unchanged in this batch; new notebook-derived LangSmith chapters use `ch07~ch09`.

## Validation evidence

Commands run from repository root:

```bash
python book/scripts/build.py --skip-diagrams
python book/scripts/nb2typ.py --config en/book/scripts/config.yaml
python en/book/scripts/build.py
```

Results:

- Korean build passed and regenerated `book/agent-handbook.pdf` (13 MB).
- English targeted Typst regeneration passed for the new notebook-derived chapters.
- English build passed and regenerated `en/book/agent-handbook-en.pdf` (14 MB).

Notebook validation:

```text
STRUCTURE OK: 34 notebooks
EXEC OK 01/34 ...
...
EXEC OK 34/34 en/07_examples/13_skills_sql_assistant.ipynb
ALL OK 34 notebooks in 53.8s
```

Structure validation checked:

- JSON parses.
- Cell IDs are sequential (`cell-0`, `cell-1`, ...).
- Code cells stay within the 10 nonblank-line convention.
- `nbclient` executed every new Korean and English notebook with `allow_errors=False`.

## Count updates

- Korean core notebooks: 86
- English mirror notebooks: 86
- Integration notebooks: 69
- Total tracked curriculum notebooks: 241

Additional repository hygiene check:

```bash
git diff --check -- . ':(exclude)*.pdf'
```

Result: passed. PDF binaries were excluded from whitespace diff checks because binary xref/content streams can look like textual trailing whitespace to Git.

## English textbook-style polish pass

After the first executable mirror was complete, the 17 new English notebooks were edited again for natural course-reader prose:

- Replaced repeated "mirrors the Korean source notebook" boilerplate with chapter-specific learning introductions.
- Added explicit English learning goals to each new notebook.
- Rewrote section openers as concise textbook-style explanations.
- Removed Korean strings from the new English mirror notebooks and examples.
- Regenerated the corresponding new English Typst chapters and rebuilt the English PDF.

Validation after polish:

```text
POLISH STRUCTURE OK: 17 English notebooks
EXEC OK 01/17 en/02_langchain/14_semantic_search.ipynb
...
EXEC OK 17/17 en/07_examples/13_skills_sql_assistant.ipynb
ALL ENGLISH POLISHED NOTEBOOKS OK in 27.8s
```

Additional checks:

- No Korean Hangul text remains in the 17 polished English notebooks.
- No repeated first-pass mirror boilerplate remains.
- Cell IDs remain sequential.
- Code cells remain within the 10 nonblank-line convention.
- `python en/book/scripts/build.py` passed after regenerating the new English Typst chapters.
- `git diff --check -- . ':(exclude)*.pdf'` passed.

## Review-fix pass

A first review found two release-quality issues and several maintenance notes. Fixes applied:

- SQL safety checker in Korean and English `07_examples/13_skills_sql_assistant.ipynb` now enforces `LIMIT` for exploratory read-only `SELECT` queries and demonstrates both allowed and rejected examples.
- Each new English mirror notebook now has a `## Reference docs` section linking to repo-local official reference notes.
- `book/scripts/build.py` derives the notebook conversion count from `book/scripts/config.yaml` instead of printing a stale hardcoded count.
- `en/book/scripts/config.yaml` is now explicitly scoped to targeted regeneration of the new English notebook-derived chapters; English `build.py` remains a compile-only path for the curated Typst tree.
- `en/README.md` documents the Korean/English regeneration boundary and notes that Part VIII / `08_integration` is a separate handbook lane.

Post-fix validation:

```bash
python book/scripts/build.py --skip-diagrams
python book/scripts/nb2typ.py --config en/book/scripts/config.yaml
python en/book/scripts/build.py
```

All three commands passed. The Korean build now reports `Step 2: Converting 79 notebooks → Typst` from the YAML-derived count.

Notebook execution after fixes:

```text
STRUCTURE OK: 34 notebooks
EXEC OK 01/34 ...
EXEC OK 34/34 en/07_examples/13_skills_sql_assistant.ipynb
ALL OK 34 notebooks in 51.5s
```

Diff hygiene after fixes:

```bash
git diff --check -- . ':(exclude)*.pdf'
```

Result: passed.

## Final review-low cleanup

The second review found one remaining LOW issue: an older English LangGraph notebook suggested uncommenting placeholder Langfuse keys directly in the notebook. This was removed and replaced with environment-only guidance:

- Keep secrets in `.env` or environment variables.
- Never paste API keys into notebooks.

Additional cleanup:

- `en/book/scripts/build.py` now prints and documents its compile-only boundary: refresh notebook-derived chapters with `en/book/scripts/config.yaml` when notebooks change.
- `book/scripts/build.py` no longer has the stale `F541` f-string diagnostic.

Validation after final cleanup:

```bash
python -m py_compile book/scripts/build.py en/book/scripts/build.py
ruff check book/scripts/build.py en/book/scripts/build.py
python book/scripts/build.py --skip-diagrams
python book/scripts/nb2typ.py --config en/book/scripts/config.yaml
python en/book/scripts/build.py
git diff --check -- . ':(exclude)*.pdf'
```

All commands passed. `en/03_langgraph/02_graph_api.ipynb` also executed successfully with `nbclient` after the secret-handling text edit.
