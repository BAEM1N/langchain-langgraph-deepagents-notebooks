# 08. LangSmith — 트레이싱 · 평가 · 프롬프트 허브

LangSmith는 LangChain 팀이 만든 **LLM 애플리케이션 관측 플랫폼**이다.
`02_langchain`~`05_advanced`까지의 에이전트 코드에 **환경변수 하나만 추가**하면 모든 LLM/tool call이 자동으로 기록된다.
본 폴더는 quickstart부터 프로덕션 모니터링까지 단계적으로 다룬다.

## 왜 별도 폴더인가

- 튜토리얼이 5개 이상으로 커져 `12_observability` 단일 위치보다 전용 폴더가 깔끔
- 데이터셋·평가·프롬프트 허브까지 **자체 제품군**이라 단일 노트북에 담기 어려움
- LangChain 팀의 "기본 권장 관측 스택"으로 학습 우선순위가 높음

## 커리큘럼

| # | 파일 | 주제 | 상태 |
|---|------|------|------|
| 01 | `01_quickstart.ipynb` | API 키 · 첫 트레이스 · UI 투어 | ✅ |
| 02 | `02_tracing_agents.ipynb` | LangGraph subgraph · Deep Agents subagent · feedback · filter | ✅ |
| 03 | `03_datasets_and_evaluation.ipynb` | Dataset · code/LLM-as-judge/pairwise/summary evaluator · online | ✅ |
| 04 | `04_prompt_hub.ipynb` | `push_prompt`/`pull_prompt` · commit SHA vs tag · CI 핀 | ✅ |
| 05 | `05_production_monitoring.ipynb` | Dashboard · online autoeval · feedback API · sampling · PII | ✅ |

## 사전 준비

```bash
pip install -U langsmith langchain
```

```dotenv
# .env
LANGSMITH_API_KEY=lsv2_pt_...
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=my-first-project
```

- API 키 발급: https://smith.langchain.com/
- 무료 플랜: 월 50k trace

## 관련 문서

- `docs/OBSERVABILITY.md` — 관측 도구 전체 개요
- `docs/langchain/30-observability.md`
- `docs/langgraph/17-observability.md`
- Langfuse·OTel 비교는 `08_integration/12_observability/` 에 배치 예정 (벤더 중립 관측)
