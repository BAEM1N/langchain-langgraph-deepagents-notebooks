# gpt-4.1 Notebook Live Smoke Verification

Date: 2026-06-16

## Scope

- Source list: `git ls-files '*.ipynb'`
- Notebook count: 195
- Verification mode: one actual `ChatOpenAI(model="gpt-4.1")` invocation per tracked notebook path
- Prompt shape: request the model to return exactly `OK` for the notebook path

## Result

| Metric | Value |
|---|---:|
| Successful live calls | 195 |
| Failed live calls | 0 |
| Reported model | `gpt-4.1-2025-04-14` |
| Total tokens reported | 7,579 |

## Evidence notes

- Raw JSONL log was written locally to `.local/verification/gpt41_notebook_smoke.jsonl` during the verification run.
- First path checked: `01_beginner/00_setup.ipynb` → `OK`
- Last path checked: `en/07_examples/06_multimodal_pdf_rag.ipynb` → `OK`

## Limit

This verifies live OpenAI `gpt-4.1` reachability for every tracked notebook path. It is intentionally a smoke test, not a full cell-by-cell execution of all notebooks, because many integration notebooks target non-OpenAI providers, local services, paid vector databases, or external credentials.
