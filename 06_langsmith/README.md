# 06. LangSmith — 트레이싱 · 평가 · 프롬프트 운영

LangSmith는 LangChain/LangGraph/Deep Agents 애플리케이션의 **실행 기록, 데이터셋, 평가, 프롬프트 버전, 운영 모니터링**을 한곳에서 다루는 플랫폼입니다. 이 폴더는 단순 tracing quickstart를 넘어, 실제 에이전트 회귀 테스트와 Agent Evals까지 이어지는 운영 흐름을 다룹니다. Korean 원본과 English mirror(`en/06_langsmith/01~06`)가 모두 존재합니다.

---

## 언제 이 트랙을 보나

- 에이전트 실행 과정을 trace tree로 보고 싶을 때
- dataset/example 기반 regression evaluation을 만들고 싶을 때
- prompt hub로 프롬프트 버전을 관리하고 싶을 때
- production monitoring, feedback, online evaluation을 붙이고 싶을 때
- `agentevals`로 tool-call trajectory를 점검하고 싶을 때

---

## 커리큘럼

| # | 파일 | 주제 | 실행 특성 |
|---|---|---|---|
| 01 | [`01_quickstart.ipynb`](01_quickstart.ipynb) | API key, 첫 trace, UI 투어 | trace read/write |
| 02 | [`02_tracing_agents.ipynb`](02_tracing_agents.ipynb) | LangGraph subgraph, Deep Agents subagent, feedback, filters | 일부 feedback write |
| 03 | [`03_datasets_and_evaluation.ipynb`](03_datasets_and_evaluation.ipynb) | dataset, code evaluator, LLM-as-judge, pairwise/summary evaluator | dataset/evaluate write |
| 04 | [`04_prompt_hub.ipynb`](04_prompt_hub.ipynb) | `push_prompt`/`pull_prompt`, commit SHA, pinning | prompt write |
| 05 | [`05_production_monitoring.ipynb`](05_production_monitoring.ipynb) | dashboard, online autoeval, sampling, PII hygiene | monitoring/read examples |
| 06 | [`06_agent_evals.ipynb`](06_agent_evals.ipynb) | AgentEvals trajectory match, LLM-as-judge, LangSmith experiment | dataset/evaluate write |

---

## 사전 준비

```bash
uv sync
cp .env.example .env
```

`.env` 최소 예시:

```dotenv
OPENAI_API_KEY=sk-...
LANGSMITH_API_KEY=lsv2_pt_...
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=langchain-langgraph-deepagents-notebooks
```

- API 키 발급: https://smith.langchain.com/
- local harness는 LangSmith mutation 리소스를 `local-exec-*` prefix로 생성합니다.

---

## 실행 검증 메모

기본 live smoke에서는 LangSmith dataset/prompt/evaluate mutation cell을 건너뛸 수 있습니다. 실제 쓰기까지 검증하려면 명시적으로 flag를 켭니다.

```bash
UV_NO_SYNC=1 uv run python local/notebook_execution_01_07_gpt41/run_notebooks.py \
  --only 06_langsmith \
  --force --timeout 300 --allow-langsmith-mutations
```

최근 `06_agent_evals.ipynb`는 `--allow-langsmith-mutations`로 실제 dataset/experiment 생성까지 검증되었습니다. 세부 evidence는 [`../docs/verification/2026-06-17-tutorial-gap-analysis.md`](../docs/verification/2026-06-17-tutorial-gap-analysis.md)를 참고하세요.

---

## 관련 문서

- [`../docs/OBSERVABILITY.md`](../docs/OBSERVABILITY.md) — 관측 도구 전체 개요
- [`../docs/langchain/30-observability.md`](../docs/langchain/30-observability.md)
- [`../docs/langgraph/17-observability.md`](../docs/langgraph/17-observability.md)
- [`../docs/langchain/27-test.md`](../docs/langchain/27-test.md)
- Langfuse/OpenTelemetry 비교는 [`../08_integration/12_observability/`](../08_integration/12_observability/)에서 다룹니다.
