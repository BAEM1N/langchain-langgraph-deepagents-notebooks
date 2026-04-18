# 07. Integrations — LangChain 생태계 통합 실습

LangChain · LangGraph · Deep Agents와 연결되는 **외부 도구·서비스 통합**을 카테고리별로 정리한 실습 모음이다.
기본 커리큘럼(`02_langchain` ~ `05_advanced`)이 "어떻게 쓰나"에 집중한다면, 이 폴더는 "**무엇과 연결하나**"에 집중한다.

> 기준 버전 스냅샷: `.local/langchain-versions.md` (2026-04-18)
> langchain 1.2 · langgraph 1.1 · deepagents 0.5.0

## 폴더 규칙

- 서브폴더: `NN_topic/`
- 노트북: `NN_name.ipynb` (기존 커리큘럼과 동일한 두 자리 번호 패턴)
- 각 서브폴더 `README.md`는 커버 범위 + 진행 상태 체크리스트

## 진행 상태

| # | 카테고리 | 노트북 수 | 상태 |
|---|----------|----------|------|
| 01 | [Chat Models](./01_chat_models/) | 0 / 9 | ⬜ |
| 02 | [Embeddings](./02_embeddings/) | 0 / 6 | ⬜ |
| 03 | [Vector Stores](./03_vectorstores/) | 0 / 8 | ⬜ |
| 04 | [Document Loaders](./04_document_loaders/) | 0 / 5 | ⬜ |
| 05 | [Retrievers](./05_retrievers/) | 0 / 5 | ⬜ |
| 06 | [Text Splitters](./06_text_splitters/) | 0 / 3 | ⬜ |
| 07 | [Tools](./07_tools/) | 0 / 6 | ⬜ |
| 08 | [Checkpointers](./08_checkpointers/) | 0 / 4 | ⬜ |
| 09 | [Stores](./09_stores/) | 0 / 2 | ⬜ |
| 10 | [Sandboxes](./10_sandboxes/) | 0 / 3 | ⬜ |
| 11 | [Provider Middleware](./11_provider_middleware/) | 7 / 7 | ✅ |
| 12 | [Observability](./12_observability/) | 0 / 2 | ⬜ |
| 13 | [Providers](./13_providers/) | 0 / 9 | ⬜ |

## 우선순위 근거

1. **🔴 높음** — Provider middleware / Alt chat models / Vector stores / Checkpointers(Postgres·SQLite): 공식 문서는 성숙했으나 리포 hands-on이 전무
2. **🟡 중간** — Embeddings alt / Document loaders / Retrievers / Tools: 개념은 다뤄졌으나 벤더별 실제 코드 부족
3. **🟢 낮음** — Text splitters / Observability: 기본 실습에 일부 포함

## 노트북 스타일

기존 `02_langchain/*.ipynb`와 동일:
- 첫 셀: 제목 + 학습 목표
- 환경 설정(`.env` 로드) 셀
- 각 섹션 번호 (`7.X.N`) + 설명 markdown + 실행 가능한 코드 셀
- 말미에 정리/권장 다음 단계

## 관련 문서

- `docs/MODEL_PROVIDERS.md` — 공급자 개요
- `docs/OBSERVABILITY.md` — 관측 도구 개요
- `docs/skills/langchain-dependencies.md` — 패키지 버전 정책
