# LangChain 생태계 업데이트 갭 점검 — 2026-10-11

## 결론

**업데이트가 필요하다(신뢰도 높음).** 마지막 버전 점검 이후 117일 동안 LangChain MCP와 Deep Agents 기본 동작에 변경이 생겼다. 기존 환경에서의 정상 동작을 최신 버전에서도 정상이라고 확장해서 해석할 수 없다.

점검 대상은 로컬 `main` commit `97b7d6df24da28eedf8359c0d6660e9843408375`다. 최신 버전 조사·갭 매핑을 완료했으며 **패키지 업그레이드와 교육 소스 마이그레이션은 아직 수행하지 않았다.**

## 확인한 로컬 지침

- `.local/RUNBOOK.md`: 7일 초과 시 전체 점검, sitemap diff → changelog → PyPI/GitHub 교차 검증 → 레포 매핑 → 로컬 기록 갱신. 명시적 요청 없으면 커밋하지 않음. 신규 노트북·breaking migration은 별도 실행 범위.
- `.local/version-check.md`: 주요 API/backend/provider 드리프트 확인.
- `.local/langchain-versions.md`: 이전 검증 2026-06-16.
- `.local/latest-check-2026-06-16.md`, `.local/drift-log.md`, `.local/session-changelog.md`: 당시 수정/실행 기록. 과거 로그의 모델/버전/경로를 현행 규칙으로 취급하지 않음.
- `local/README_WRITING_RULES.md`: README 작성 기준과 실측 수량 확인 규칙. 저장된 수량은 이전 상태.
- `AGENTS.md`, `docs/skills/AGENTS.md`: 한국어 설명, 짧은 코드 셀, docs 근거, uv, 영어 mirror 유지.
- `.codex/skills/agent-course-production/SKILL.md`: 강의 상품 산출물 제작에만 적용. 이번 점검에서 제작 작업을 활성화하지 않음.

기존 June 21 core/English/book 반영 기록을 확인했다. 과거 backlog의 완료 항목을 신규 갭으로 중복 분류하지 않았다. integration-heavy 잔여 항목은 기존 backlog로 분리한다.

## 버전 확인 — 사실

| 패키지 | 로컬 lock/설치 기준 | 최신 PyPI | 업로드일 (UTC) |
|---|---|---|---|
| `langchain` | 1.3.9 | **1.4.4** | 2026-10-08 |
| `langchain-core` | 1.4.7 | **1.6.9** | 2026-10-08 |
| `langgraph` | 1.2.5 | **1.2.14** | 2026-10-06 |
| `deepagents` | 0.6.10 | **0.7.23** | 2026-10-07 |
| `langsmith` | 0.8.16 | **0.14.7** | 2026-10-09 |
| `langchain-openai` | 1.3.2 | **1.7.0** | 2026-10-08 |
| `langchain-google-genai` | 4.2.5 | **4.4.1** | 2026-10-10 |
| `langchain-community` | 0.4.2 | **0.4.2** | 2026-05-22 |
| `langchain-quickjs` | lock 없음 | **0.3.8** | 2026-09-29 |
| `langchain-mcp-adapters` | 0.2.1 | **0.3.2** | 2026-08-06 |

최신 버전 출처는 각 `https://pypi.org/pypi/<package>/json`이며 Python 요구/업로드 시각/기준일 이후 release 목록은 `.local/update-check-2026-10-11/pypi.json`에 보관했다. 최신 주요 release는 공식 GitHub와 교차 확인했다.

- [LangChain 공식 통합 changelog](https://docs.langchain.com/oss/python/releases/changelog)
- [LangChain releases](https://github.com/langchain-ai/langchain/releases)
- [LangGraph releases](https://github.com/langchain-ai/langgraph/releases)
- [Deep Agents releases](https://github.com/langchain-ai/deepagents/releases)
- [LangSmith SDK releases](https://github.com/langchain-ai/langsmith-sdk/releases)

## 우선순위와 반영 상태

| 우선 | 변경/갭 | 판단 | 영향 위치 | 확신 |
|---|---|---|---|---|
| 높음 | Deep Agents 0.7 todo가 opt-in | 기본 계획 도구가 자동 내장된다는 설명 수정 필요 | `docs/skills/deep-agents-core.md`, `docs/skills/deep-agents-orchestration.md`, `docs/deepagents/01-overview.md`, `04_deepagents/08_harness.ipynb`, 영어 mirror | 높음 |
| 높음 | backend compatibility 제거 | `BackendFactory` 시그니처 및 `StoreBackend` 예시 수정 필요 | `docs/skills/deep-agents-core.md`, `docs/skills/deep-agents-memory.md`, `docs/deepagents/14-context-engineering.md`, `docs/langchain/11-middleware-builtin.md` | 높음 |
| 높음 | LangChain MCP migration | 현재 adapter 기반 실습은 새 API 설명이 미반영. Beta/API 기능 차이 때문에 import만 치환하면 안 됨 | `02_langchain/11_mcp.ipynb`, `02_langchain/07_hitl_and_runtime.ipynb`, 영어 mirror, `docs/langchain/16-mcp.md`, `docs/langchain/mcp.md`, pyproject/lock | 높음 |
| 높음 | SDK/lock/실제 환경 노후 | 기존 환경과 별도 검증 환경을 비교한 뒤 기준 버전 변경 필요 | `pyproject.toml`, `uv.lock`, validation harness | 높음 |
| 중간 | filesystem 결과와 쓰기 동작 변화 | `delete`, 덮어쓰기, 출력 파싱 의존성 확인 필요 | filesystem/backend/harness 문서·노트북·permissions 예제 | 높음(공식 변경), 영향 정도 미확인 |
| 중간 | dynamic subagents / pinned skills | 기존 interpreter/task/skills 내용과 신규 표면을 대조해야 함 | `04_deepagents/05_subagents.ipynb`, `06_memory_and_skills.ipynb`, `07_advanced.ipynb`, `docs/deepagents/`, skills 문서 | 중간 |
| 중간 | Deep Agents fault tolerance, multimodal, retrieval/RAG 문서 | 기존 기능 설명의 재배치/확장 여부를 먼저 분류 | `04_deepagents/`, `05_advanced/`, `07_examples/` | 중간 |
| 중간 | LangSmith 0.8→0.14, OpenAI 1.3→1.7 | 버전 차이는 확정, API별 영향은 아직 미확정 | `06_langsmith/`, prompt loader, providers | 버전 높음 / 영향 미확인 |
| 낮음 | 수량/지침 드리프트 | AGENTS 60, README 작성 지침 207은 실제 241과 불일치 | `AGENTS.md`, `local/README_WRITING_RULES.md` | 높음 |
| 별도 | June 잔여 integration backlog | 이번 upstream 신설 항목과 구분 필요 | 기존 `docs/verification/2026-06-21-official-docs-implementation-batch-2.md` | 높음 |

### 정확한 API 근거

- 최신 Deep Agents 0.7.23 wheel의 `create_deep_agent`는 `backend: BackendProtocol | None`이고 `state_schema`가 있다. 로컬 skill 시그니처에는 `BackendFactory`가 남아 있다.
- 같은 wheel의 `StoreBackend.__init__`는 `def __init__(self, *, namespace: NamespaceFactory, store: BaseStore | None = None)`다. namespace는 **callable**이며 `namespace=lambda rt: (...)`는 유효하다. lambda라는 이유로 backend factory 제거 대상으로 분류하면 안 된다.
- 코어 한국어 backend/memory 노트북에서 확인한 StoreBackend 코드 셀 6개에는 namespace가 있다. 반면 `docs/skills/deep-agents-memory.md`의 `StoreBackend(store=store)`와 `docs/deepagents/14-context-engineering.md`의 `StoreBackend(runtime)`는 새 시그니처와 맞지 않는다.
- 최신 LangChain 1.4.4 wheel의 `langchain/mcp/__init__.py`는 MCPAdapter를 export하고 beta warning을 명시한다.
- [MCP migration 공식 문서](https://docs.langchain.com/oss/python/migrate/langchain-mcp-adapters): MCPConfig 구조, `get_tools`→`list_tools`, context manager, prompt/resource/session 제거, elicitation interrupt, interceptor→middleware가 함께 바뀐다.
- 최신 공식 backend/middleware 문서 일부에는 namespace 없는 예시가 아직 남아 있다. 이 충돌은 최신 배포 코드와 release를 기준으로 판정했다.

최신 배포 wheel을 설치하지 않고 추출하여 AST를 확인했다. 원본 URL/hash와 선택 소스는 `.local/update-check-2026-10-11/wheel-evidence.json`, `wheel-sources/`에 있다.

## 문서 sitemap diff — 사실

이전 141 / 현재 141 경로. **추가 13 / 이탈 13**. 동일 총량이어도 내용은 바뀌었다. 경로 이탈은 삭제/기능 폐지의 확정 근거가 아니다.

### 새로 baseline에 등장한 경로

- `/oss/python/deepagents/ag-ui.md`
- `/oss/python/deepagents/dynamic-subagents.md`
- `/oss/python/deepagents/fault-tolerance.md`
- `/oss/python/deepagents/multimodal.md`
- `/oss/python/deepagents/rag.md`
- `/oss/python/deepagents/retrieval.md`
- `/oss/python/langchain/frontend/controlled-generative-ui.md`
- `/oss/python/langchain/frontend/declarative-generative-ui.md`
- `/oss/python/langchain/frontend/generative-ui-overview.md`
- `/oss/python/langchain/frontend/open-ended-generative-ui.md`
- `/oss/python/langchain/mcp/auth.md`
- `/oss/python/langchain/mcp/connections.md`
- `/oss/python/langchain/mcp/tools.md`

### 기존 baseline에서 이탈한 경로

- `/oss/python/deepagents/code/configuration.md`
- `/oss/python/deepagents/code/data-locations.md`
- `/oss/python/deepagents/code/mcp-tools.md`
- `/oss/python/deepagents/code/memory-and-skills.md`
- `/oss/python/deepagents/code/overview.md`
- `/oss/python/deepagents/code/providers.md`
- `/oss/python/deepagents/code/remote-sandboxes.md`
- `/oss/python/deepagents/code/subagents.md`
- `/oss/python/deepagents/harness.md`
- `/oss/python/deepagents/programmatic-subagents.md`
- `/oss/python/langchain/frontend/generative-ui.md`
- `/oss/python/langchain/rag.md`
- `/oss/python/langchain/retrieval.md`

### 기존 탐지 규칙의 사각지대

Deep Agents Code는 `/oss/python/deepagents/code/*`에서 `/oss/deepagents/code/*`로 이동했다. 현재 sitemap에서 이 영역 16개, Python migration 4개를 별도 수집했다. 기존 4개 Python 영역 regex만으로는 migration 안내와 Code 확장 문서를 놓친다.

`programmatic-subagents`→`dynamic-subagents`는 기존 interpreter 기반 task dispatch와 연결되므로 완전히 새로운 기능이라고 단정하지 않았다. LangChain retrieval/RAG 경로 이탈과 Deep Agents retrieval/RAG 경로 등장은 문서 지도 이동 후보다.

원문: [공식 sitemap](https://docs.langchain.com/sitemap.xml). 로컬 diff/supplemental 경로와 14개 기능 원문은 `.local/update-check-2026-10-11/`에 보관했다.

## GitHub 저장소 동기화 — 별도 확인

- 로컬 HEAD: `97b7d6df24da28eedf8359c0d6660e9843408375`
- 원격 main: `761077b2776c624462ae06cfda577f062f682b7e`
- GitHub compare: **diverged**, 원격 전용 8 / 로컬 전용 2.
- 원격 비교에 나타난 변경 파일 27개는 decks 영역이다. 강의자료 동기화와 SDK migration은 별개다.
- 원격 pyproject.toml / AGENTS.md / README.md를 직접 읽어 로컬과 바이트 일치 확인.
- pull/reset/rebase/merge는 수행하지 않았다. 기존 release note의 reset --hard 안내를 이 diverged 상태에 자동 적용하면 안 된다.
- [비교 결과](https://github.com/BAEM1N/langchain-langgraph-deepagents-notebooks/compare/97b7d6df24da28eedf8359c0d6660e9843408375...761077b2776c624462ae06cfda577f062f682b7e)

## 실행 시 갱신한 파일

- `.local/langchain-versions.md`: 확인된 최신 버전·갭·검증 한계.
- `.local/known-docs.prev.md`: 기존 baseline 백업.
- `.local/known-docs.md`: 현재 141개 Python 경로.
- `.local/version-check.md`, `.local/RUNBOOK.md`: migration/Code 경로 탐지 보완 및 이번 점검 로그.
- 본 리포트: `docs/verification/2026-10-11-ecosystem-update-gap.md`.
- `.local/update-check-2026-10-11/`: 원문, JSON 근거, 선택 wheel 소스, 이전 기록 백업.

## 남은 실행 범위와 검증 기준

이번 점검에서 교육 노트북, pyproject, uv.lock, 책/데크는 수정하지 않았다. 커밋/푸시도 하지 않았다.

Breaking migration 실행은 위 영향 목록을 기준으로 코어 한국어/영어 노트북과 docs/skills를 함께 갱신해야 한다. 검증은 API import/signature, 외부 호출 없는 동작 검증, 변경 notebook JSON/셀 ID/문법, 필요한 live smoke, handbook 재생성과 비교를 포함한다. 기본 harness는 소스를 gpt-4.1 복사본으로 변환하므로 그대로의 모델/API 검증과 같지 않다. 08 integration은 기존 정책대로 별도 검증 범위다.

## 점검 한계

- 이번 점검에서 live 모델 호출, LangSmith 쓰기, 외부 DB/클라우드 실행은 하지 않았다.
- 모든 patch release 본문이나 기존 141개 문서 본문 전체의 변경을 전수 비교하지 않았다.
- sitemap 신규/이탈 전체를 저장했으나 frontend 개별 신규 3개는 overview 수준으로만 분류했다.
- 최신 SDK API 판정은 배포 코드로 확인했고, 실제 최신 환경에서의 전 노트북 실행 성공을 주장하지 않는다.

## 후속 조사에서 확인된 사항

[업데이트 자료조사](2026-10-11-update-research.md)에서 LangSmith SmithDB 이전, LangGraph response_schema/trace_policy, Deep Agents fork 및 skill tools/pinned_skills의 구체 API를 확인했다. 따라서 위 표의 LangSmith API 영향 미확정 상태는 후속 조사 문서 기준으로 보완한다. Deep Agents 0.7.0의 공식 요약 날짜와 PyPI/GitHub 게시 날짜가 다르며, state_schema는 0.6.10에도 존재했던 인자임을 구분했다. 실제 마이그레이션은 아직 수행하지 않았다.
