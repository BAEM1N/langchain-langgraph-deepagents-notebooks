# Tutorial Gap Analysis and Execution Plan — 2026-06-17

## Scope

This note re-checks the local notebook/book coverage against current public LangChain, LangGraph, Deep Agents, LangSmith/AgentEvals, and Deep Agents GitHub example surfaces. It is intentionally focused on course material that can fit the existing `01_beginner` through `07_examples` notebook harness. Cloud deployments, React-heavy frontend implementation, and paid sandbox examples are treated as `08_integration` or appendix candidates unless they can be converted into deterministic local notebook exercises.

## Local evidence snapshot

- Notebook tracks currently cover `01_beginner` through `07_examples` in Korean and English, with 127 `.ipynb` files in scope after adding the English async-subagents mirror.
- `book/scripts/config.yaml` Part 4 still stops at `04_deepagents/10_sandboxes_and_acp.ipynb` (`book/scripts/config.yaml:70-84`). This is expected for the notebook-to-Typst generator, because later Deep Agents book chapters are manually maintained.
- Korean and English books already include manual Deep Agents chapters `part4/ch11.typ` through `part4/ch15.typ` (`book/main.typ:53-69`, `en/book/main.typ:52-68`). Those manual chapters map to `docs/deepagents/12-async-subagents.md` through `docs/deepagents/16-permissions.md`.
- Therefore, adding `11_async_subagents.ipynb` to the book YAML would overwrite the existing manual `ch11.typ`. The safer path is: keep manual book chapters, add/verify the English notebook mirror, and do not put manual chapters into notebook config unless we deliberately migrate the whole Part 4 late-chapter pipeline.
- `07_examples` book config still stops at `06_multimodal_pdf_rag.ipynb` (`book/scripts/config.yaml:102-112`). This is the cleanest place for a new applied `Content Builder` notebook.
- `06_langsmith` has Korean notebooks only, while both Korean and English books already include manually maintained LangSmith chapters `part6/ch01.typ` through `ch05.typ`. If we add AgentEvals, add both language notebooks or clearly document the Korean-only exception.

## Current official surfaces checked

### Deep Agents docs and examples

| Surface | Current official URL | Local status | Decision |
|---|---|---|---|
| Async subagents | https://docs.langchain.com/oss/python/deepagents/async-subagents | Korean notebook exists; English notebook mirror newly created; book already has manual KO/EN ch11 | Finish mirror verification; do not overwrite manual book chapter. |
| Content Builder | https://docs.langchain.com/oss/python/deepagents/content-builder | Local markdown reference exists, but no runnable course notebook | Add as `07_examples/07_content_builder_agent.ipynb` + EN mirror. |
| Programmatic subagents | https://docs.langchain.com/oss/python/deepagents/programmatic-subagents | Mentioned briefly in `04_deepagents/07_advanced.ipynb`; no runnable chapter; installed `deepagents==0.6.10` lacks a public `programmatic` module and `langchain_quickjs` is not installed | Add as a cautious advanced notebook only after deciding dependency policy; include feature-gate/fallback cells. |
| Event streaming | https://docs.langchain.com/oss/python/deepagents/event-streaming | Book has Deep Agents streaming manual ch14; notebooks only touch related concepts | Update existing streaming chapters first; consider a short Deep Agents streaming notebook only if needed. |
| Deep Agents Code (`dcode`) | https://docs.langchain.com/oss/python/deepagents/code/overview | Mentioned in `04_deepagents/01_introduction.ipynb` and `04_deepagents/07_advanced.ipynb`; CLI-heavy | Defer to `08_integration` or appendix; not a core 01~07 live notebook. |
| Frontend/subagent streaming | https://docs.langchain.com/oss/python/deepagents/frontend/subagent-streaming | React/useStream heavy; no direct notebook | Defer to `08_integration`; summarize in streaming refresh. |
| GitHub examples | https://github.com/langchain-ai/deepagents/tree/main/examples | Local examples cover deep research, SQL, data analysis, multimodal RAG; missing Content Builder, LLM Wiki, Better Harness, RLM/REPL Swarm | Content Builder is the only immediate 01~07 fit; Better Harness may become a later eval/optimization appendix. |

### LangGraph docs

| Surface | Current official URL | Local status | Decision |
|---|---|---|---|
| Fault tolerance | https://docs.langchain.com/oss/python/langgraph/fault-tolerance | `03_langgraph/12_durable_execution.ipynb` has a short reference-only section; no focused live chapter | Add focused `03_langgraph/14_fault_tolerance.ipynb` + EN mirror with deterministic retry/timeout/error-handler examples. |
| Event streaming | https://docs.langchain.com/oss/python/langgraph/event-streaming | `03_langgraph/07_streaming.ipynb` has a v3 reference section but no true live `stream_events(..., version="v3")` verification | Refresh existing notebook rather than add a duplicate. |
| Frontend custom channels / graph execution | https://docs.langchain.com/oss/python/langgraph/frontend/custom-stream-channels, https://docs.langchain.com/oss/python/langgraph/frontend/graph-execution | React/SDK-heavy | Keep conceptual bridge in LangChain/LangGraph streaming chapters; implementation belongs in `08_integration`. |
| `use-subgraphs`, `use-time-travel` | https://docs.langchain.com/oss/python/langgraph/use-subgraphs, https://docs.langchain.com/oss/python/langgraph/use-time-travel | Covered by existing subgraphs and interrupts/time-travel notebooks | Update references if stale; no new notebook. |
| `add-memory` | https://docs.langchain.com/oss/python/langgraph/add-memory | Covered across persistence/memory notebooks | No new notebook; possibly add one concise reference section during maintenance. |

### LangChain and LangSmith/AgentEvals docs

| Surface | Current official URL | Local status | Decision |
|---|---|---|---|
| Agent Evals | https://docs.langchain.com/oss/python/langchain/test/evals | `06_langsmith/03_datasets_and_evaluation.ipynb` has basic `agentevals` trajectory examples, but no dedicated agent-eval workflow chapter | Add `06_langsmith/06_agent_evals.ipynb`; prefer EN mirror if we keep the English book aligned. |
| Event streaming | https://docs.langchain.com/oss/python/langchain/event-streaming | `02_langchain/12_frontend_streaming.ipynb` already includes `useStream` and v3 references, but one live example still uses `version="v2"` for `.astream_events()` | Refresh existing notebook; do not add duplicate. |
| Test unit/integration | https://docs.langchain.com/oss/python/langchain/test/unit-testing, https://docs.langchain.com/oss/python/langchain/test/integration-testing | Existing production/eval notebooks cover some testing concepts | Consider a later compact testing appendix if course scope expands; not first batch. |
| Component architecture/philosophy | https://docs.langchain.com/oss/python/langchain/component-architecture, https://docs.langchain.com/oss/python/langchain/philosophy | Mostly conceptual; existing intro/overview notebooks cover enough | Defer; mention in references. |
| Frontend pages | https://docs.langchain.com/oss/python/langchain/frontend/overview | Existing frontend streaming notebook covers selected concepts | Keep as update-only unless `08_integration` frontend track is revived. |

## API and package compatibility notes

Verified locally with the current `.venv`:

- `deepagents==0.6.10` exposes `create_deep_agent(...)`, `SubAgent`, `AsyncSubAgent`, `FilesystemBackend`, `LocalShellBackend`, `LangSmithSandbox`, `RubricMiddleware`, and related middleware.
- The installed `deepagents` package does not expose a dedicated `programmatic_subagents` module, and `langchain_quickjs` is not installed. Programmatic-subagent material should therefore be written as a feature-gated tutorial, or we must explicitly add the `deepagents[quickjs]` dependency before expecting live execution.
- `langgraph` exposes `RetryPolicy`, `NodeTimeoutError`, `StateGraph.add_node(... retry_policy=..., timeout=..., error_handler=...)`, and `StateGraph.set_node_defaults(...)`, so a deterministic fault-tolerance notebook is feasible now.
- `agentevals` is installed, but public functions are imported from submodules, e.g. `agentevals.trajectory.match.create_trajectory_match_evaluator` and `agentevals.trajectory.llm.create_trajectory_llm_as_judge`, not the package root.

## Revised priority order

### P0 — Stabilize current branch and mirror integrity

1. Keep `book/scripts/config.yaml` and `en/book/scripts/config.yaml` unchanged for Part 4 manual chapters.
2. Keep and verify `en/04_deepagents/11_async_subagents.ipynb` as the missing English notebook mirror.
3. Run changed-only notebook validation for `04_deepagents/11_async_subagents.ipynb` and `en/04_deepagents/11_async_subagents.ipynb`.
4. Build both books to ensure manual ch11-ch15 still compile.

Acceptance criteria:
- No config diff that would overwrite manual Part 4 chapters.
- KO/EN async-subagents notebooks parse, have sequential cell IDs, and pass the gpt-4.1 smoke harness.
- Both Typst books build without new errors.

### P1 — Add Content Builder as the next applied example

Files:
- `07_examples/07_content_builder_agent.ipynb`
- `en/07_examples/07_content_builder_agent.ipynb`
- Optional: `07_examples/skills/content-builder/SKILL.md`
- `book/scripts/config.yaml`, `en/book/scripts/config.yaml`
- `book/main.typ`, `en/book/main.typ`
- generated `book/chapters/part7/ch07.typ`, `en/book/chapters/part7/ch07.typ`, PDFs

Design:
- Adapt the official Content Builder pattern into a text-only local notebook: `AGENTS.md` brand voice, skill folder, research/writer subagent definitions, and filesystem-backed artifacts.
- Keep Tavily/search and Google image generation optional/reference-only to avoid non-OpenAI provider coupling.
- Use `FilesystemBackend(virtual_mode=True)` and generated files under ignored `local/` paths.

Acceptance criteria:
- Runs end-to-end with OpenAI/gpt-4.1 and LangSmith tracing only.
- Produces deterministic blog/social draft files in `local/`.
- No image-provider or paid-cloud key required.

### P2 — Add LangGraph Fault Tolerance as a focused chapter

Files:
- `03_langgraph/14_fault_tolerance.ipynb`
- `en/03_langgraph/14_fault_tolerance.ipynb`
- book/en config + main includes + generated part3 ch14 Typst/PDFs

Design:
- Demonstrate `RetryPolicy` with a deterministic fake flaky node.
- Demonstrate node/run timeout concepts without slow real sleeps in the live path.
- Demonstrate `error_handler`/`Command` recovery and `set_node_defaults(...)` precedence.
- Link back to `03_langgraph/12_durable_execution.ipynb` instead of duplicating checkpointing content.

Acceptance criteria:
- The chapter has runnable cells for retries and handled errors.
- Timeout material is either deterministic or printed as reference code only.
- Harness pass is not flaky.

### P3 — Add LangSmith Agent Evals as a dedicated evaluation chapter

Files:
- `06_langsmith/06_agent_evals.ipynb`
- `en/06_langsmith/06_agent_evals.ipynb` if keeping English parity
- manual `book/chapters/part6/ch06.typ`, `en/book/chapters/part6/ch06.typ`
- `book/main.typ`, `en/book/main.typ`
- harness LangSmith mutation allowlist updates if needed

Design:
- Teach trajectory match modes and LLM-as-judge trajectory grading using `agentevals.trajectory.*` imports.
- Use a tiny weather/tool trajectory and a small LangSmith dataset/experiment with prefixed names.
- Require `--allow-langsmith-mutations` for live verification; default harness should skip mutating cells unless explicitly enabled.

Acceptance criteria:
- Local non-mutating examples pass normally.
- Mutating LangSmith run passes with explicit flag and project `langchain-langgraph-deepagents-notebooks`.
- No keys or run IDs with sensitive values are committed.

### P4 — Refresh existing event-streaming notebooks

Files:
- `02_langchain/12_frontend_streaming.ipynb`
- `en/02_langchain/12_frontend_streaming.ipynb`
- `03_langgraph/07_streaming.ipynb`
- `en/03_langgraph/07_streaming.ipynb`
- generated Part 2 ch12 and Part 3 ch07 Typst/PDFs

Design:
- Replace stale or low-level-only references with the current event-streaming terminology: `stream.messages`, `stream.tool_calls`, `stream.values`, `stream.output`, `stream.subgraphs`, `stream.extensions`, `stream.interrupts`.
- Keep Python-first cells runnable; React/useStream remains markdown/reference unless moved to `08_integration`.
- Ensure LangChain and LangGraph chapters distinguish agent projections from graph protocol projections.

Acceptance criteria:
- Existing streaming notebooks still pass live smoke.
- References point to current event-streaming docs.
- Book chapters regenerate cleanly.

### P5 — Programmatic subagents: gated advanced chapter or defer

Option A — Add now with feature gate:
- `04_deepagents/12_programmatic_subagents.ipynb`
- `en/04_deepagents/12_programmatic_subagents.ipynb`
- Use cells that detect `langchain_quickjs` and installed Deep Agents capabilities; provide runnable fallback with ordinary `SubAgent` fan-out.

Option B — Defer until dependency update:
- Do not add a runnable notebook yet.
- Add a short section to `04_deepagents/07_advanced.ipynb` saying the current official programmatic-subagents feature requires QuickJS/PTC support and should be tested after adding `deepagents[quickjs]`.

Recommendation: choose Option B unless we explicitly accept a dependency change. This keeps the 01~07 gpt-4.1 harness green without adding a new runtime surface.

### P6 — Later / integration-only candidates

- Deep Agents Code (`dcode`): appendix or `08_integration`, because it is CLI/TUI/shell-oriented.
- Deep Agents frontend todo/subagent-streaming/sandbox: `08_integration`, because it is React/SDK and server-state heavy.
- LLM Wiki, RLM Agent, REPL Swarm, Better Harness: evaluate after P1-P4; likely advanced appendices rather than core learner path.
- Managed/cloud/auth/provider pages: keep out of 01~07 unless all required keys/services are provided and the cost model is explicit.

## Revised execution phases

1. **Branch stabilization** — remove accidental config diffs, validate async-subagents EN mirror, run KO/EN changed harness, build books.
2. **Source-note capture** — add concise local source notes for Content Builder, Fault Tolerance, Agent Evals, and Event Streaming so notebooks have a repo-local evidence base without copying official docs verbatim.
3. **Content Builder** — add KO/EN notebooks, skills if useful, book ch07, changed harness, build.
4. **Fault Tolerance** — add KO/EN LangGraph notebooks, book ch14, changed harness, build.
5. **Agent Evals** — add KO/EN or KO-only per parity decision, manual book ch06, run both non-mutating and explicit LangSmith-mutation tests.
6. **Streaming refresh** — update four existing notebooks and regenerated chapters.
7. **Programmatic subagents decision** — add feature-gated chapter only if dependency policy allows QuickJS; otherwise defer and add an explicit current-version note.
8. **Final audit/commit** — full JSON/cell ID audit, changed-only smoke, book builds, secret scan, `git diff --check`, Lore commit.

## Verification checklist

For each phase:

- Parse every changed notebook with `json.loads`.
- Audit sequential `cell-0`, `cell-1`, ... IDs.
- Run the local gpt-4.1 harness only for changed 01~07 notebooks, excluding `08_integration/`.
- For LangSmith mutations, run with `--allow-langsmith-mutations` and do not print API keys.
- Build Korean and English books after every book-impacting phase.
- Remove untracked runtime artifacts such as `langgraph.example.json` if generated by notebook execution.
- Run a tracked-file secret scan using exact `.env` values without printing them.
- Run `git diff --check -- ':!book/agent-handbook.pdf' ':!en/book/agent-handbook-en.pdf'`.

## Decision record

Decision: prioritize Content Builder, Fault Tolerance, Agent Evals, and Streaming Refresh; treat Programmatic Subagents as gated until dependency policy is explicit.

Drivers:
- Maintain 01~07 live-harness reliability with OpenAI/gpt-4.1.
- Keep Korean and English learner paths aligned.
- Avoid overwriting manually maintained book chapters.
- Prefer applied notebooks that teach one current production pattern at a time.

Alternatives considered:
- Add every new official page as a notebook: rejected because frontend/cloud/CLI pages would dilute the executable notebook course and increase provider-service failures.
- Convert all manual Part 4 book chapters back into notebook-generated chapters immediately: rejected because it risks regressing mature manual Typst chapters and is larger than the tutorial-gap task.
- Add Programmatic Subagents immediately with a new dependency: rejected for now because the installed package lacks the required public module/QuickJS dependency.

Follow-ups:
- If we later migrate Part 4 manual chapters to notebooks, do it as a separate book-pipeline refactor with one chapter at a time and book visual diff checks.
- If Programmatic Subagents becomes available in the installed dependency set, promote it from P5 to P1.

---

## Second-pass detailed investigation — 2026-06-17

### Local branch state after the first remediation wave

The working tree now reflects the first accepted remediation wave, but it is not yet committed. The branch is ahead of `origin/main` and contains notebook, Typst, PDF, and config changes. The current local shape is:

| Area | Current local count | Book generation status | Notes |
|---|---:|---|---|
| Korean `01_beginner` | 8 | YAML-generated | Fully listed in `book/scripts/config.yaml`. |
| Korean `02_langchain` | 13 | YAML-generated | Streaming chapter updated in-place. |
| Korean `03_langgraph` | 14 | YAML-generated | New `14_fault_tolerance.ipynb` is listed. |
| Korean `04_deepagents` | 11 | ch01-ch10 YAML-generated; ch11-ch15 manual Typst | `11_async_subagents.ipynb` intentionally stays out of YAML to avoid overwriting manual ch11. |
| Korean `05_advanced` | 10 | YAML-generated | No new first-wave file. |
| Korean `06_langsmith` | 6 | manual Typst includes ch01-ch06 | New `06_agent_evals.ipynb` has manual book ch06. |
| Korean `07_examples` | 7 | YAML-generated | New Content Builder ch07 is listed. |
| English `01_beginner` | 8 | YAML-generated | Fully listed in `en/book/scripts/config.yaml`. |
| English `02_langchain` | 13 | YAML-generated | Streaming chapter updated in-place. |
| English `03_langgraph` | 14 | YAML-generated | New `14_fault_tolerance.ipynb` is listed. |
| English `04_deepagents` | 11 | ch01-ch10 YAML-generated; ch11-ch15 manual Typst | New `11_async_subagents.ipynb` is a notebook mirror only; not listed in YAML. |
| English `05_advanced` | 10 | YAML-generated | No new first-wave file. |
| English `06_langsmith` | 1 | manual Typst includes ch01-ch06 | **Parity debt remains:** only Agent Evals has an English notebook; ch01-ch05 exist as manual book chapters, not source notebooks. |
| English `07_examples` | 7 | YAML-generated | New Content Builder ch07 is listed. |

Confirmed local dependency gate:

- `langchain==1.3.9`
- `langgraph==1.2.5`
- `deepagents==0.6.10`
- `agentevals==0.0.9`
- `langsmith==0.8.16`
- `langchain-openai==1.3.2`
- `langchain_quickjs` is **not installed**

Implication: programmatic subagents should not become a new required live notebook yet. The current safe path is a compatibility note and fallback section in `04_deepagents/07_advanced.ipynb` and `en/04_deepagents/07_advanced.ipynb`.

### Official surfaces re-checked

Primary sources checked in this pass:

- LangChain Agent Evals: `https://docs.langchain.com/oss/python/langchain/test/evals.md`
- LangChain Event Streaming: `https://docs.langchain.com/oss/python/langchain/event-streaming.md`
- LangChain Unit Testing: `https://docs.langchain.com/oss/python/langchain/test/unit-testing.md`
- LangChain Integration Testing: `https://docs.langchain.com/oss/python/langchain/test/integration-testing.md`
- LangGraph Fault Tolerance: `https://docs.langchain.com/oss/python/langgraph/fault-tolerance.md`
- LangGraph Event Streaming: `https://docs.langchain.com/oss/python/langgraph/event-streaming.md`
- Deep Agents Content Builder: `https://docs.langchain.com/oss/python/deepagents/content-builder.md`
- Deep Agents Programmatic Subagents: `https://docs.langchain.com/oss/python/deepagents/programmatic-subagents.md`
- Deep Agents Event Streaming: `https://docs.langchain.com/oss/python/deepagents/event-streaming.md`
- Deep Agents Code overview: `https://docs.langchain.com/oss/python/deepagents/code/overview.md`
- Deep Agents frontend subagent streaming: `https://docs.langchain.com/oss/python/deepagents/frontend/subagent-streaming.md`
- Deep Agents GitHub examples tree: `https://github.com/langchain-ai/deepagents/tree/main/examples`

The already-applied first-wave choices are still the right immediate choices:

1. **Content Builder** is the best `07_examples` addition because it combines `AGENTS.md`, skills, subagents, filesystem artifacts, and applied publishing workflow without requiring a server.
2. **Fault Tolerance** is the best `03_langgraph` addition because retries, timeouts, error handlers, and graph defaults were only lightly covered before.
3. **Agent Evals** is the best LangSmith addition because `agentevals` trajectory matching and LLM-as-judge workflows are now first-class enough to deserve their own lesson.
4. **Event streaming** should remain an in-place refresh rather than a duplicate chapter because the repo already has LangChain and LangGraph streaming chapters.
5. **Programmatic Subagents** stays gated because the current environment lacks the QuickJS package path required for the official pattern.

### Additional tutorial candidates beyond the current branch

| Candidate | Fit | Priority | Recommended placement | Why / dependency gate |
|---|---|---:|---|---|
| English LangSmith notebook parity (`01`-`05`) | Course source parity | P1 next wave | `en/06_langsmith/01_*.ipynb` through `05_*.ipynb` | English book already has manual ch01-ch05, but source notebooks are missing. This is the largest remaining learner-facing parity gap. |
| Programmatic Subagents compatibility section | Current branch closeout | P0 current wave | `04_deepagents/07_advanced.ipynb`, `en/04_deepagents/07_advanced.ipynb` | Add a feature gate that prints installed versions and falls back to ordinary `SubAgent` orchestration. Avoid a new `ch12` notebook until `langchain_quickjs` policy is accepted. |
| LangChain testing strategy notebook | Testing discipline | P2 | likely `06_langsmith/07_testing_strategy.ipynb` or `05_advanced/10_testing_and_replay.ipynb` | Official unit/integration testing pages emphasize mock models, in-memory checkpointing, API key management, structural assertions, and replay. Good but less urgent than parity and first-wave additions. |
| Deep Agents Code / `dcode` | CLI/integration | P2 integration | `08_integration/` appendix, not `01`-`07` | CLI/TUI and local shell semantics do not fit the main gpt-4.1 notebook harness. |
| Deep Agents frontend subagent streaming | Frontend integration | P2 integration | `08_integration/` React/useStream example | Requires frontend runtime and selector-based UI state; should stay out of the main notebook harness. |
| Deep Agents GitHub examples: `llm-wiki`, `better-harness`, `rlm_agent`, `repl_swarm` | Advanced examples | P3 | optional `07_examples/08_*` or `05_advanced/10_*` after evaluation | Useful, but each needs a stronger scope/cost story before adding. Content Builder was the only clear immediate fit. |
| Deploy examples (`deploy-*`, `nvidia_deep_agent`, `talon-whatsapp`) | Cloud/provider integration | P3/08 only | `08_integration/` | Provider/cloud keys and runtime costs make them unsuitable for the default course harness. |

### Revised execution plan from here

#### Phase 0 — finish current branch closeout

1. Add the Programmatic Subagents compatibility/fallback section to both `04_deepagents/07_advanced.ipynb` and `en/04_deepagents/07_advanced.ipynb`.
2. Regenerate `book/chapters/part4/ch07.typ` and `en/book/chapters/part4/ch07.typ` only.
3. Run the gpt-4.1 harness for both changed advanced notebooks.
4. Run a changed-notebook smoke for all first-wave notebooks once before commit.
5. Build Korean and English books.
6. Run JSON/cell-ID audit, `git diff --check`, and exact-value secret scan.
7. Commit with Lore trailers.

Acceptance criteria:

- No `langchain_quickjs` import is required in source execution.
- Harness passes for the two advanced notebooks.
- Existing manual Part 4 ch11-ch15 remain untouched by YAML generation.
- Both PDFs build.

#### Phase 1 — English LangSmith parity wave

1. Create `en/06_langsmith/01_quickstart.ipynb` through `05_production_monitoring.ipynb` by translating/adapting the Korean notebooks, not by reverse-engineering from PDF text.
2. Keep model cells as `gpt-5.4` in source; rely on the local harness replacement to run gpt-4.1.
3. Use the same LangSmith project policy: `langchain-langgraph-deepagents-notebooks` in local execution, and mutation cells gated by `--allow-langsmith-mutations`.
4. Decide whether English Part 6 should remain manual Typst or move to notebook-generated Typst. Default: keep the manual book chapters unless a visual diff plan is approved.

Acceptance criteria:

- Five new English notebooks parse and have sequential `cell-0...` IDs.
- Normal smoke skips mutation cells; explicit mutation smoke runs only prefixed resources.
- English book remains stable; no accidental rewrite of manual Part 6 chapters.

#### Phase 2 — testing strategy chapter decision

1. Compare existing `06_langsmith/03_datasets_and_evaluation.ipynb`, `06_langsmith/06_agent_evals.ipynb`, and production/testing material against official unit/integration testing docs.
2. If the concepts are scattered, add a compact testing strategy chapter focused on: mock chat model, in-memory checkpointer, structural assertions, key management, cost/latency controls, and record/replay guidance.
3. If coverage is sufficient, add only cross-references and skip a new chapter.

Acceptance criteria:

- New chapter only if it avoids duplicating Agent Evals.
- Live cells use local deterministic graphs or low-cost gpt-4.1 calls.
- No paid/provider-specific service required.

#### Phase 3 — integration-only backlog formalization

1. Add or update an `08_integration` manifest/README that explicitly marks it excluded from the default 01~07 harness.
2. Sort candidates into provider, frontend, sandbox, deployment, observability, and local-server buckets.
3. For each bucket, document required keys/services and estimated cost/risk before implementation.

Acceptance criteria:

- Default harness still reports `08_integration/` excluded.
- Integration candidates have a clear key/cost gate.
- No cloud/provider integration is accidentally included in the 01~07 live smoke.

### Decision record update

Decision: finish the current first-wave branch, then prioritize English LangSmith source parity before adding more new conceptual chapters.

Drivers:

- The first wave already covers the highest-value new official tutorial surfaces.
- The largest remaining learner-facing debt is not another new concept; it is English source parity for LangSmith ch01-ch05.
- Programmatic Subagents is important, but the current local dependency set makes a required live notebook risky.
- `08_integration/` should absorb cloud/frontend/provider-heavy examples so the main gpt-4.1 harness remains reliable.

Rejected:

- Add `04_deepagents/12_programmatic_subagents.ipynb` immediately | would create a dependency mismatch with the current venv and risk confusing learners.
- Move English LangSmith ch01-ch05 into YAML generation immediately | could rewrite manual book chapters before we have visual diff coverage.
- Add deployment/provider examples to `07_examples` | would violate the current low-friction 01~07 execution contract.

---

## Phase 6 and final verification evidence — 2026-06-17

Phase 6 was closed with a compatibility-first implementation:

- `04_deepagents/07_advanced.ipynb` now explicitly detects whether `langchain_quickjs` is available before recommending the Programmatic Subagents path.
- `en/04_deepagents/07_advanced.ipynb` now mirrors the Korean advanced chapter sections for `CodeInterpreterMiddleware`, Programmatic Subagents compatibility, `RubricMiddleware`, and Deep Agents Code (`dcode`).
- Both advanced notebooks now use deterministic local snippets in the streaming demo, so the default 01~07 gpt-4.1 harness does not require a Tavily key.
- `en/book/assets` is a symlink to `../assets` so regenerated English Typst chapters can resolve `../../assets/...` image paths produced by `book/scripts/nb2typ.py`.

Verification run:

```bash
UV_NO_SYNC=1 uv run python local/notebook_execution_01_07_gpt41/run_notebooks.py \
  --force --timeout 300 --allow-langsmith-mutations \
  --only 04_deepagents/11_async_subagents.ipynb \
  --only en/04_deepagents/11_async_subagents.ipynb \
  --only 07_examples/07_content_builder_agent.ipynb \
  --only en/07_examples/07_content_builder_agent.ipynb \
  --only 03_langgraph/14_fault_tolerance.ipynb \
  --only en/03_langgraph/14_fault_tolerance.ipynb \
  --only 06_langsmith/06_agent_evals.ipynb \
  --only en/06_langsmith/06_agent_evals.ipynb \
  --only 02_langchain/12_frontend_streaming.ipynb \
  --only en/02_langchain/12_frontend_streaming.ipynb \
  --only 03_langgraph/07_streaming.ipynb \
  --only en/03_langgraph/07_streaming.ipynb \
  --only 04_deepagents/07_advanced.ipynb \
  --only en/04_deepagents/07_advanced.ipynb
```

Result:

- Target notebooks: 14
- Passed: 14
- Failed: 0
- Skipped runtime cells: 0
- LangSmith mutations: enabled with prefix `local-exec-20260616-174310`
- `08_integration/` remained excluded from the harness scope.

Book builds:

- `python book/scripts/build.py` passed and generated `book/agent-handbook.pdf`.
- `python en/book/scripts/build.py` passed and generated `en/book/agent-handbook-en.pdf`.

Static gates:

- Changed notebook JSON parse and sequential `cell-0...` ID audit passed for 13 changed notebooks.
- `git diff --check -- ':!book/agent-handbook.pdf' ':!en/book/agent-handbook-en.pdf'` passed.
- Exact-value secret scan against secret-like `.env` values passed with zero hits outside ignored local/env paths.
