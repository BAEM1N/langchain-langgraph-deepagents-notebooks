# 교육 저장소 업데이트 자료조사

조사 기준: 2026-10-11 KST. 비교 기준은 기존 2026-06-16 점검과 로컬 `97b7d6d` 커밋이다.

## 조사 결론

업데이트의 중심은 **Deep Agents 하네스의 기본 동작, LangChain MCP 통합, LangSmith 조회 API**다. 여기에 LangGraph의 승인 응답 스키마와 tracing, 서브에이전트 대화 상속, skill별 도구 공개를 보강해야 한다.

이번 조사에서는 교육 소스나 실행 환경을 변경하지 않았다. 기존 노트북이 현재 환경에서 실패한다고 판정한 것도 아니다. 확인된 변경은 새 버전으로 교육 기준을 옮길 때 검토할 근거다.

자료:

- [변경사항과 파일별 반영 매트릭스](2026-10-11-update-research-matrix.csv): 21개 조사 항목, 분류, 수정 후보, 공식 근거, 필요한 검증.
- [공식 릴리스 인덱스](2026-10-11-update-release-index.csv): 기준일 이후 140개 릴리스 레코드. 버전 문자열 기준으로 안정 릴리스 136개와 시험 버전 4개를 구분했다.
- [이전 갭 점검](2026-10-11-ecosystem-update-gap.md): 문서 sitemap, 로컬 지침, 원격 브랜치 상태.
- 로컬 원문·배포 코드·분석 JSON: `.local/update-research-2026-10-11/`.

## 근거의 범위와 해석

| 구분 | 조사 내용 | 해석 한계 |
|---|---|---|
| 공식 릴리스 | LangChain·core·OpenAI 통합·LangGraph·Deep Agents·LangSmith의 136개 안정 릴리스 | 릴리스 노트의 모든 수정이 이 교육 저장소의 변경 대상은 아님 |
| 문서 | 이번 공식 문서 27개와 앞선 점검 원문 14개 확보 | 모든 기존 문서의 본문 diff를 수행한 것은 아님 |
| 배포 코드 | 6개 패키지의 이전/현재 wheel에서 선택 모듈을 AST로 비교 | 실행 성공, 원격 서비스 지원, 전체 의미 호환을 증명하지 않음 |
| 로컬 소스 | tracked Markdown·노트북·Python의 심볼을 파일/셀별 매핑 | 키워드 후보 수는 오류 수나 수정 파일 수가 아님 |

공식 GitHub 릴리스는 페이지를 과거 기준일까지 내려가며 수집했다. 안정 버전 목록은 PyPI의 기준일 이후 버전 목록과 대조했으며 아래 6개 패키지에서 빠진 안정 버전은 없었다.

| 패키지 | 안정 릴리스 수 | 비교 버전 |
|---|---:|---|
| langchain | 14 | 1.3.9 → 1.4.4 |
| langchain-core | 19 | 최신 1.6.9, 기존 lock 1.4.7 |
| langchain-openai | 19 | 1.3.2 → 1.7.0 |
| langgraph | 9 | 1.2.5 → 1.2.14 |
| deepagents | 26 | 0.6.10 → 0.7.23 |
| langsmith | 49 | 0.8.16 → 0.14.7 |

core는 릴리스/로컬 사용을 조사했고, wheel 모듈 비교에는 대신 Google 통합 4.2.5 → 4.4.1을 포함했다. AST 비교는 공개 함수 시그니처와 클래스 필드를 분리했다. 데코레이터 변경을 함수 시그니처 변경으로 잘못 세지 않도록 처리했다.

출처: [LangChain releases](https://github.com/langchain-ai/langchain/releases), [LangGraph releases](https://github.com/langchain-ai/langgraph/releases), [Deep Agents releases](https://github.com/langchain-ai/deepagents/releases), [LangSmith SDK releases](https://github.com/langchain-ai/langsmith-sdk/releases), 각 패키지 PyPI JSON.

## Deep Agents: 기본 구성과 확장 계약

### 계획 도구와 프롬프트

확인 사실: 0.7에서는 계획 도구가 기본 제공되지 않는다. 계획이 필요한 예시에는 `TodoListMiddleware`를 명시해야 한다. 부모 설정만으로 모든 서브에이전트의 계획 구성을 같다고 설명하면 안 된다. 기본 프롬프트와 일부 middleware의 자동 안내 문구도 줄었다.

교육 판단: 입문·하네스 설명의 “자동 계획”을 조건부로 고쳐야 한다. 계획을 가르치는 예제는 계획 도구를 의도적으로 구성하고, 일반 에이전트와 비교해야 한다.

주요 위치: `docs/skills/deep-agents-core.md`, `docs/skills/deep-agents-orchestration.md`, `04_deepagents/08_harness.ipynb`와 영어 mirror.

근거: [0.7.0 release](https://github.com/langchain-ai/deepagents/releases/tag/deepagents%3D%3D0.7.0), 이전·현재 `deepagents/graph.py`와 middleware 소스.

### Backend의 생성자와 반환 계약

배포 코드로 확인한 차이:

| API | 이전 | 현재 |
|---|---|---|
| StateBackend | 위치 runtime 인자와 file_format 호환 인자 수용 | 인자 없는 생성자 |
| StoreBackend | runtime 위치 인자, 선택 namespace | keyword-only namespace 필수 |
| create_deep_agent backend | BackendProtocol 또는 BackendFactory | BackendProtocol 인스턴스 |
| legacy 메서드 | ls_info / glob_info / grep_raw 등의 호환 메서드 | 해당 메서드 제거 |
| 결과 구조 | deprecated files_update 경로 존재 | 호환 경로 제거, 삭제 결과 및 일부 truncated 필드 추가 |

`namespace=lambda rt: (...)`는 현재에도 유효하다. 제거된 **backend factory**와 **namespace factory**를 구분해야 한다. 현재 코어 한국어 backend/memory 노트북의 StoreBackend 코드 셀 6개에는 이미 namespace가 있으므로 일괄 치환 대상이 아니다.

확정 수정 후보: `docs/skills/deep-agents-memory.md`의 namespace 없는 예시와 `docs/deepagents/14-context-engineering.md`의 위치 runtime 예시. 커스텀 backend는 구현한 메서드와 반환 형식을 별도로 비교해야 한다.

근거: [Deep Agents 0.7.23 배포](https://pypi.org/project/deepagents/0.7.23/), wheel의 `backends/protocol.py`, `state.py`, `store.py`.

### 파일 도구의 기본값과 동작

배포 소스에서 `FilesystemBackend`와 `LocalShellBackend`의 `virtual_mode` 기본값이 True인 것을 확인했다. `write_file`은 기존 파일을 교체하며, backend가 지원하면 삭제 도구도 노출된다. 파일 쓰기 권한은 삭제 권한과 연결되므로 기존 permissions 예제에서 허용되는 작업 범위를 다시 설명해야 한다.

도구 출력 문자열과 backend의 구조화된 반환값은 별개다. 빈 결과, 줄 표시, 검색 결과 잘림에 의존하는 설명·파서만 골라 확인한다.

주요 위치: `04_deepagents/04_backends.ipynb`, `15_permissions.ipynb`, `docs/deepagents/16-permissions.md`, sandbox·하네스 설명.

근거: 위 PyPI 배포의 filesystem/local_shell/protocol 소스, [공식 permissions](https://docs.langchain.com/oss/python/deepagents/permissions).

### 서브에이전트의 isolated와 fork

0.7.12에 `mode="fork"`가 추가됐다. 기본 isolated 방식과 달리 부모의 유효 대화 문맥을 이어받는 실험적 방식이다. 배포 소스는 fork에서 별도 `skills` 설정을 거부한다.

교육 판단: 현재 “Stateless”, “부모 스킬 미상속” 설명을 모든 실행 모드에 적용하면 틀린 설명이 된다. 기본 모드의 호출 간 상태와 fork 시 전달되는 부모 문맥을 구분해야 한다. fork가 독립적인 장기 메모리를 자동 제공한다고 확대해서 설명하지 않는다.

주요 위치: `04_deepagents/05_subagents.ipynb`, `docs/skills/deep-agents-orchestration.md`, 고급 subagent 트랙.

근거: [0.7.12 release](https://github.com/langchain-ai/deepagents/releases/tag/deepagents%3D%3D0.7.12), [공식 subagents](https://docs.langchain.com/oss/python/deepagents/subagents), `middleware/subagents.py`.

### Skill 본문뿐 아니라 도구를 필요할 때 공개

0.7.22는 skill을 읽은 후 관련 도구를 공개한다. `metadata.include_tools`는 공백으로 나눈 도구 이름 문자열이며 YAML 리스트나 `allowed-tools`와 의미가 다르다. middleware에 도구 목록 또는 resolver를 연결한다.

0.7.23의 `pinned_skills`는 호출 입력 state에 skill 이름을 전달하는 표면이다. `create_deep_agent(pinned_skills=...)`라는 새 생성자 인자로 설명하면 안 된다. 요약 이후 도구 공개 상태의 수명도 설명할 필요가 있다.

교육 판단: 기존 progressive disclosure 설명을 유지하면서 본문·도구 schema·pin의 차이를 보강한다. 기존 07_examples SKILL.md를 전부 바꿀 근거는 없다.

주요 위치: `04_deepagents/06_memory_and_skills.ipynb`, `docs/skills/deep-agents-core.md`, 예제별 skills.

근거: [Skills](https://docs.langchain.com/oss/python/deepagents/skills), [0.7.22 release](https://github.com/langchain-ai/deepagents/releases/tag/deepagents%3D%3D0.7.22), [0.7.23 release](https://github.com/langchain-ai/deepagents/releases/tag/deepagents%3D%3D0.7.23), `middleware/skills.py`.

### Middleware·rubric·profiles

현재 하네스는 같은 이름의 사용자 middleware 인스턴스로 기본 인스턴스를 대체할 수 있다. 이를 LangChain의 일반 middleware 중복 규칙과 혼동하면 안 된다. rubric에는 기준별 평가 커버리지와 grader 연동 hook 관련 수정이 있다.

교육 판단: 실제 `RubricMiddleware` 구성과 교육용 결정적 grader를 구분한다. profile별 tool/middleware 변화가 기본 구성 설명에 영향을 주는지도 확인한다.

주요 위치: `04_deepagents/03_customization.ipynb`, `07_advanced.ipynb`, `16_quality_profiles_rubric.ipynb`, `05_advanced/09_production.ipynb`, `06_langsmith/09_runtime_rubric_evaluation.ipynb`.

근거: [Customization](https://docs.langchain.com/oss/python/deepagents/customization), [Profiles](https://docs.langchain.com/oss/python/deepagents/profiles), [0.7.11 release](https://github.com/langchain-ai/deepagents/releases/tag/deepagents%3D%3D0.7.11).

## LangChain: MCP는 API와 실행 수명주기를 함께 이전

MCP의 새 namespace는 beta다. 기존 adapter 패키지를 바로 제거하고 import만 바꾸는 접근은 충분하지 않다.

| 현재 교육 표면 | 새 표면의 조사 결과 |
|---|---|
| MultiServerMCPClient / get_tools | MCPAdapter / list_tools, async context manager |
| transport가 있는 서버별 설정 | MCPConfig의 mcpServers와 transport 추론 |
| tool_interceptors | LangChain wrap_tool_call middleware |
| client callback 기반 elicitation | LangGraph interrupt 기반 응답·재개 |
| 연결별 인증/headers | FastMCP client/transport에 설정 |
| get_prompt / get_resources / session | 새 adapter에 직접 대응하는 메서드 없음 |

기존 한국어 `02_langchain/11_mcp.ipynb`는 도구 변환뿐 아니라 callback과 interceptor를 다룬다. `07_hitl_and_runtime.ipynb`에도 기존 adapter import가 있어 함께 검토해야 한다. 한국어·영어 합산 static code-cell 후보는 17개지만 print/참고 snippet도 포함하므로 17개 실행 실패를 뜻하지 않는다.

`wrap_tool_call(state_schema=...)`와 middleware trace 설정은 별도 보강 항목이다. 기존 wrapper 예시는 새 인자를 추가하지 않아도 유지될 수 있다. legacy chat-message-history 심볼은 조사한 교육 소스에서 발견되지 않아 이번 수정 대상으로 잡지 않았다.

근거: [MCP migration](https://docs.langchain.com/oss/python/migrate/langchain-mcp-adapters), [LangChain 1.3.15](https://github.com/langchain-ai/langchain/releases/tag/langchain%3D%3D1.3.15), [core 1.6.4](https://github.com/langchain-ai/langchain/releases/tag/langchain-core%3D%3D1.6.4), LangChain wheel의 factory/types/MCP 모듈.

## LangGraph: 승인 응답 스키마와 tracing 보강

1.2.12의 `interrupt`는 keyword-only `response_schema`를 받는다. 기존 `interrupt(value)`는 여전히 유효하다. 승인·선택 응답의 스키마와 `Command`로 재개하는 계약을 함께 보여주는 보강이 적합하다.

`StateGraph.add_node`에는 `trace_policy`가 있다. 이전 릴리스에 이미 들어온 timeout/error_handler/DeltaChannel을 이번 신설 기능으로 중복 분류하지 않았다.

주요 위치: `03_langgraph/08_interrupts_and_time_travel.ipynb`, `10_production.ipynb`, LangSmith tracing 노트북과 관련 docs/skills.

근거: [1.2.12 release](https://github.com/langchain-ai/langgraph/releases/tag/1.2.12), [1.2.11 release](https://github.com/langchain-ai/langgraph/releases/tag/1.2.11), [Interrupts](https://docs.langchain.com/oss/python/langgraph/interrupts), 이전·현재 `types.py`와 `graph/state.py`.

## LangSmith: SmithDB 조회 이전이 실제 교육 코드에 영향

공식 안내는 새 Python API를 SDK 0.10.15부터 제공한다. Cloud의 이전 API 제거일은 2027-01-31로 안내하며 self-hosted는 별도 서버 버전 조건이 있다. 사용자 서비스가 어느 배포 방식과 버전인지 이번에는 확인하지 않았다.

`list_runs`는 단순 이름 치환 대상이 아니다:

- `runs.query`는 await가 필요한 API다.
- project 이름 대신 UUID 목록을 사용한다.
- 기간 생략 시 최근 하루로 범위가 좁아진다.
- 총 조회 수와 페이지 크기를 구분하고 cursor를 처리한다.
- run type/field projection 값, 응답 객체와 필드를 다시 확인한다.

현재 한국어 4개 노트북, 6개 코드 셀에서 `client.list_runs`를 확인했다. 영어 mirror에도 대응 코드가 있다. 조회 범위를 그대로 유지하지 않으면 학습자가 다른 데이터로 평가하거나 “trace가 없다”고 오해할 수 있다.

주요 위치: `06_langsmith/01_quickstart.ipynb` cell 18, `02_tracing_agents.ipynb` cells 14/17/25, `03_datasets_and_evaluation.ipynb` cell 8, `05_production_monitoring.ipynb` cell 5. cell 표기는 0부터 시작하는 JSON index다.

새 예외 클래스는 SmithDB API 영역에 적용한다. Prompt Hub loader 등 기존 API를 모두 같은 방식으로 치환하는 것은 근거가 부족하다. 기존 `evaluate` 호출은 유지 가능한 시그니처이며 `disable_evaluator_tracing`은 선택적인 설명 보강이다.

근거: [SmithDB migration](https://docs.langchain.com/langsmith/smithdb-sdk-migration), [Run query migration](https://docs.langchain.com/langsmith/smithdb-sdk-migration-query-runs), [Prompt management](https://docs.langchain.com/langsmith/manage-prompts-programmatically), 이전·현재 Client/evaluation wheel 소스.

## Provider 통합과 의존성: 버전만 개별적으로 올릴 수 없음

최신 배포 metadata에서 확인한 결합 조건:

| 패키지 | 주요 요구사항 |
|---|---|
| deepagents 0.7.23 | langchain >=1.4.3, core >=1.6.7, langsmith >=0.14.4, Google 통합 >=4.4.0 |
| langchain 1.4.4 | core >=1.6.9, langgraph >=1.2.11 및 <1.3 |
| langchain-openai 1.7.0 | core >=1.6.8, OpenAI SDK >=2.45 및 <4 |
| Deep Agents quickjs extra | langchain-quickjs >=0.3.8 |

일부 상한은 표에서 생략했으며 정확한 전체 requires_dist는 로컬 API-diff JSON에 있다. 이후 의존성 변경 때는 전체 metadata와 실제 resolver 결과를 사용한다. 새로운 MCP에는 기존 langchain 의존성의 mcp extra가 필요하므로 패키지 숫자만 바꾸는 수정으로 끝나지 않는다.

OpenAI 통합의 선택 모듈 공개 함수 시그니처는 같았지만 API key resolver와 prompt_cache_options 필드가 달라졌다. 기존 .env·base_url·Responses 처리의 회귀 확인이 필요하다. Decisions API나 새 모델 ID를 기본 교육 내용에 넣을 필요성은 확인되지 않았다.

Google 통합에는 reasoning_effort/thinking_level alias, thinking_config, async 종료 표면이 있다. 현재 Google 예시가 이 변경으로 깨졌다는 증거는 없으므로 통합 트랙 보강과 회귀 대상으로 분류했다.

근거: [Deep Agents PyPI](https://pypi.org/project/deepagents/0.7.23/), [LangChain PyPI](https://pypi.org/project/langchain/1.4.4/), [OpenAI 통합 release](https://github.com/langchain-ai/langchain/releases/tag/langchain-openai%3D%3D1.7.0), [Google 통합 PyPI](https://pypi.org/project/langchain-google-genai/4.4.1/), 각 wheel 소스/metadata.

## 문서 이동과 새 교육 범위의 구분

- dynamic-subagents는 기존 interpreter/task dispatch와 연결된다. 이름이 바뀌었다는 이유로 신규 독립 노트북을 만들지 않는다.
- fault tolerance, multimodal, retrieval/RAG는 기존 04/05/07 트랙과 내용 중복을 확인한 뒤 반영한다.
- Generative UI는 controlled/declarative/open-ended로 구분됐다. AG-UI와 함께 frontend/서버 통합 영역에 둔다.
- Code는 `/oss/deepagents/code/`로 이동했고 config·approval·extensions·plugins 문서가 있다. Python 코어와 구분해 기존 integration backlog에 연결한다.
- June 21에 이미 완료한 한국어/영어 코어와 handbook 항목은 새 갭으로 다시 세지 않는다.

근거: [Dynamic subagents](https://docs.langchain.com/oss/python/deepagents/dynamic-subagents), [Fault tolerance](https://docs.langchain.com/oss/python/deepagents/fault-tolerance), [Generative UI overview](https://docs.langchain.com/oss/python/langchain/frontend/generative-ui-overview), [AG-UI](https://docs.langchain.com/oss/python/deepagents/ag-ui), [Deep Agents Code](https://docs.langchain.com/oss/deepagents/code/overview).

## 충돌하거나 오해하기 쉬운 근거

1. 공식 요약 changelog는 Deep Agents 0.7.0을 7월 24일로 표기하지만 PyPI 업로드와 GitHub release published_at은 7월 29일이다. 릴리스 날짜를 쓸 때 출처를 구분한다.
2. 공식 backend/middleware 문서 일부는 namespace 없는 StoreBackend 예시와 이전 virtual_mode 설명을 포함한다. 최신 wheel 계약과 충돌하는 예시는 그대로 복사하지 않는다.
3. `state_schema`는 이전 0.6.10의 create_deep_agent에도 존재했다. 이번에 새로 생긴 인자로 분류하지 않는다. 로컬 skill 시그니처 누락은 별도의 기존 문서 문제다.
4. `pinned_skills`는 생성자 keyword가 아니다. fork의 문맥 상속을 영속 메모리로 해석해서도 안 된다.
5. GitHub prerelease 플래그가 False여도 a/rc 버전 문자열이 있다. 140개를 모두 안정 릴리스라고 세지 않았다.

## 후속 검증에 필요한 조건

조사 매트릭스는 다음 수정과 검증을 위한 근거이며 구현 완료 목록이 아니다.

- 코어 한국어와 영어 mirror를 같이 검토하고 docs/skills 계약을 먼저 정합화한다.
- 새 환경에서 import/signature, 파일 도구, namespace, skill disclosure, interrupt/resume, MCP lifecycle을 외부 모델 호출 없이 검증할 수 있는 부분부터 확인한다.
- LangSmith와 provider live 검증은 실제 지원 환경과 key를 확인한 뒤 수행한다. Jupyter의 top-level await와 페이지 순회가 교육 셀 구조에 들어갈 수 있어야 한다.
- 기존 smoke harness는 gpt-4.1 복사본을 실행하므로 원본 모델/설정의 회귀 검증과 구분한다.
- handbook은 원본 수정 이후 재생성·검토하며 원격에 추가된 decks와 로컬 분기 상태는 별도 동기화 문제로 유지한다.

이번 조사에서는 환경 설치, LLM 호출, LangSmith 쓰기, 브랜치 병합, commit/push를 수행하지 않았다. 조사 문서와 근거 자료만 추가했다.
