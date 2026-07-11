# 공식 문서 정합성 개선 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 공식 LangChain·LangGraph·Deep Agents 문서와 충돌하는 코어 교육 자료를 수정하고, 한·영 노트북·핸드북·자동 드리프트 검사를 하나의 검증 가능한 변경으로 완성한다.

**Architecture:** 행동 계약 수정, 버전 정렬, 파생 산출물 재생성, 드리프트 방지의 네 경계로 나눈다. 로컬 검사는 결정론적으로 실행하고 공식 웹 문서를 읽는 검사는 별도 온라인 모드와 정기 CI로 분리한다.

**Tech Stack:** Python 3.12+, uv, Jupyter Notebook JSON, LangChain 1.3, LangGraph 1.2, Deep Agents 0.6, Typst, GitHub Actions

## Global Constraints

- 한국어 설명, 영어 코드 원칙을 유지한다.
- 기본 모델은 `ChatOpenAI(model="gpt-5.4")` 또는 `openai:gpt-5.4`를 유지한다.
- Python 명령과 의존성 관리는 `uv run`, `uv sync`, `uv lock`을 사용한다.
- 새 외부 의존성을 추가하지 않는다. 검사 도구는 Python 표준 라이브러리로 작성한다.
- 노트북 셀 ID는 `cell-0`, `cell-1`, ... 순서를 유지한다.
- 새로 만들거나 분리한 코드 셀은 비어 있지 않은 줄 기준 10줄 이하로 유지한다.
- 공식 문서 원문 전체를 tracked 파일로 복제하지 않는다.
- `08_integration/` 전체 링크 마이그레이션은 이번 범위에서 제외한다.

---

## Requirements Summary

1. LangGraph 입력 검증은 노드당 `interrupt()` 한 번과 조건부 엣지를 사용한다.
2. 신규·프로덕션 예제는 `create_agent()`를 사용하고 `create_react_agent()`는 마이그레이션 문맥에서만 허용한다.
3. 부작용 도구 거부에는 `reject`, 질문형 도구의 사람 응답에는 `respond`를 사용한다.
4. `LocalShellBackend(virtual_mode=True)`를 보안 격리로 표현하지 않는다.
5. Deep Agents 현재 패치 버전과 선택적 `delete` 백엔드 계약을 정렬한다.
6. 코어 RAG·SQL 예제의 오래된 공식 링크를 현재 경로로 교체한다.
7. 동일 회귀를 찾는 로컬 검사와 공식 문서 드리프트를 찾는 온라인 검사를 추가한다.
8. 영향받는 영어 미러와 Typst/PDF 파생물을 동기화한다.

## Acceptance Criteria

- `rg 'create_react_agent'` 결과는 마이그레이션·역사 설명 허용 목록에만 존재한다.
- `03_langgraph/08_interrupts_and_time_travel.ipynb`와 영어 미러에 `while True` + `interrupt()` 입력 검증 예제가 없다.
- HITL 이메일 예제에서 `respond`로 전송을 거부하는 사례가 없다.
- `AGENTS.md`는 `LocalShellBackend`의 `virtual_mode=True`가 셸 격리를 제공하지 않는다고 명시한다.
- `uv.lock`의 `deepagents`가 `0.6.12` 이상이며 `BackendProtocol.delete`를 런타임에서 확인한다.
- 코어 `01`~`07`과 `en/`에 `python.langchain.com/docs/tutorials/rag` 및 `sql_qa` 링크가 없다.
- 대상 노트북이 JSON 파싱, 순차 셀 ID, 변경 코드 셀 길이 검사를 통과한다.
- 대상 노트북이 `run_notebooks.py --only ... --force`로 실행된다.
- 관련 한국어·영어 Typst 장과 두 PDF가 빌드된다.
- `uv run python scripts/check_official_docs_alignment.py --local`이 네트워크 없이 성공한다.
- `uv run python scripts/check_official_docs_alignment.py --online`이 공식 문서 핵심 계약을 확인한다.

---

### Task 1: LangGraph 입력 검증 계약 수정

**Files:**
- Modify: `docs/langgraph/08-interrupts.md:130-143`
- Modify: `03_langgraph/08_interrupts_and_time_travel.ipynb:324-378`
- Modify: `en/03_langgraph/08_interrupts_and_time_travel.ipynb`
- Regenerate: `book/chapters/part3/ch08.typ`
- Regenerate: `en/book/chapters/part3/ch08.typ`

**Interfaces:**
- Consumes: `interrupt(value)`, `Command(resume=value)`, `StateGraph.add_conditional_edges()`
- Produces: `FormState(age: int | None, pending_question: str | None)`와 노드당 한 번 인터럽트하는 입력 검증 예제

- [ ] **Step 1: 현재 회귀 증거를 고정한다**

  ```bash
  rg -n -C 8 'while True|Input Validation|루프 안 interrupt' \
    docs/langgraph/08-interrupts.md \
    03_langgraph/08_interrupts_and_time_travel.ipynb \
    en/03_langgraph/08_interrupts_and_time_travel.ipynb
  ```

- [ ] **Step 2: 현재 불일치가 세 대상에 존재하는지 확인한다**

  Run:

  ```bash
  rg -l 'while True' \
    docs/langgraph/08-interrupts.md \
    03_langgraph/08_interrupts_and_time_travel.ipynb \
    en/03_langgraph/08_interrupts_and_time_travel.ipynb
  ```

  Expected: 수정 전 세 파일을 모두 출력한다.

- [ ] **Step 3: Markdown 예제를 조건부 엣지 방식으로 바꾼다**

  예제의 핵심 구조는 다음으로 고정한다.

  ```python
  class FormState(TypedDict):
      age: int | None
      pending_question: str | None

  def collect_age(state: FormState) -> dict:
      question = state.get("pending_question") or "What is your age?"
      answer = interrupt(question)
      if isinstance(answer, int) and answer > 0:
          return {"age": answer, "pending_question": None}
      return {"pending_question": f"'{answer}' is not valid. Enter a positive integer."}

  def route_age(state: FormState) -> str:
      return END if state.get("age") is not None else "collect_age"
  ```

  `collect_age`는 호출당 `interrupt()`를 정확히 한 번 실행하고 `add_conditional_edges("collect_age", route_age)`가 재질문을 담당한다고 설명한다.

- [ ] **Step 4: 한국어 노트북을 수정한다**

  `cell-11`, `cell-18`, `cell-19`, 요약 셀에서 “루프 안에서도 안전” 문장을 제거한다. 상태/노드, 그래프 조립, 실행을 각각 10줄 이하 코드 셀로 나누고 이후 셀 ID를 순차 재지정한다.

- [ ] **Step 5: 영어 미러를 같은 구조로 수정한다**

  코드 식별자와 실행 흐름은 한국어판과 동일하게 유지하고 설명만 영어로 작성한다.

- [ ] **Step 6: 금지 패턴이 제거됐는지 확인한다**

  같은 검색이 입력 검증 예제에서 `while True`를 찾지 않아야 한다. 영구 회귀 검사는 Task 7에서 추가한다.

- [ ] **Step 7: 작업 단위를 커밋한다**

  Intent line: `Prevent interrupt validation from replaying prior attempts`

  Required trailers:

  ```text
  Constraint: Follow the current LangGraph one-interrupt-per-node guidance
  Confidence: high
  Scope-risk: narrow
  Tested: Interrupt pattern regression test and notebook structural audit
  ```

---

### Task 2: 프로덕션 예제의 레거시 에이전트 API 제거

**Files:**
- Modify: `05_advanced/09_production.ipynb:753-764`
- Modify: `en/05_advanced/09_production.ipynb`
- Regenerate: `book/chapters/part5/ch09.typ`
- Regenerate: `en/book/chapters/part5/ch09.typ`

**Interfaces:**
- Consumes: `langchain.agents.create_agent(model, tools, checkpointer=True)`
- Produces: `langgraph.json`에서 참조 가능한 `CompiledStateGraph` 변수 `graph`

- [ ] **Step 1: 허용 목록 밖의 레거시 API 위치를 기록한다**

  `rg -n 'create_react_agent'` 결과에서 마이그레이션 설명 파일을 제외한다. 허용 파일은 `05_advanced/00_migration.ipynb`, 영어 미러, `docs/langgraph/00-migrate-langchain-v1.md`, 마이그레이션 목적의 핸드북 장으로 제한한다.

- [ ] **Step 2: 현재 프로덕션 노트북 때문에 검사가 실패하는지 확인한다**

  Expected: `05_advanced/09_production.ipynb`와 영어 미러를 보고 FAIL.

- [ ] **Step 3: Graph API 예제를 현재 에이전트 팩터리로 교체한다**

  ```python
  from langchain.agents import create_agent

  graph = create_agent(
      model="openai:gpt-5.4",
      tools=[search_tool],
      checkpointer=True,
  )
  ```

  `create_agent()` 반환값이 배포 그래프 엔트리포인트로 사용할 수 있는 compiled graph임을 설명한다.

- [ ] **Step 4: 한·영 노트북과 회귀 검사를 검증한다**

  Expected: 비마이그레이션 파일에서 `create_react_agent`가 0건.

- [ ] **Step 5: 작업 단위를 커밋한다**

  Intent line: `Keep production deployment examples on the supported agent factory`

---

### Task 3: HITL `reject`와 `respond` 의미 분리

**Files:**
- Modify: `docs/langchain/17-human-in-the-loop.md:54-76`
- Modify: `docs/deepagents/08-human-in-the-loop.md:21-65`
- Modify: `02_langchain/07_hitl_and_runtime.ipynb:136-157`
- Modify: `en/02_langchain/07_hitl_and_runtime.ipynb`
- Modify: `04_deepagents/07_advanced.ipynb:141-288`
- Modify: `en/04_deepagents/07_advanced.ipynb`
- Clarify: `05_advanced/06_sql_agent.ipynb:367-371`
- Clarify: `en/05_advanced/06_sql_agent.ipynb`
- Clarify: `07_examples/02_sql_agent.ipynb:388-478`
- Clarify: `en/07_examples/02_sql_agent.ipynb`
- Regenerate: `book/chapters/part2/ch07.typ`
- Regenerate: `book/chapters/part4/ch07.typ`
- Regenerate: `book/chapters/part5/ch06.typ`
- Regenerate: `book/chapters/part7/ch02.typ`
- Regenerate: `en/book/chapters/part2/ch07.typ`
- Regenerate: `en/book/chapters/part4/ch07.typ`
- Regenerate: `en/book/chapters/part5/ch06.typ`
- Regenerate: `en/book/chapters/part7/ch02.typ`

**Interfaces:**
- Consumes: `HumanInTheLoopMiddleware`, `Command(resume={"decisions": [...]})`
- Produces: 부작용 도구용 `approve/edit/reject`와 질문형 도구용 `respond` 예제

- [ ] **Step 1: 부작용 도구에 잘못 사용된 `respond` 위치를 기록한다**

  최소 금지 사례는 `send_email` 문맥에서 `respond` 메시지가 “건너뛰기/이미 처리됨”을 뜻하는 경우다. `rg -n -C 5 'send_email|respond|이미 처리됨|already sent'`로 한·영 대상의 현재 위치를 캡처한다.

- [ ] **Step 2: 이메일 예제의 정책을 좁힌다**

  `send_email`에는 `approve`, `edit`, `reject`만 허용한다. 네 번째 결정은 다음 질문형 도구로 시연한다.

  ```python
  @tool
  def ask_user(question: str) -> str:
      """Ask the user for information needed to continue."""
      return "No response provided"
  ```

  `ask_user`에는 `respond`를 허용하고 사람 메시지가 synthetic tool result가 되는 흐름을 보여준다.

- [ ] **Step 3: SQL 예제의 제한 조건을 명시한다**

  SQL 예제에서 `respond`는 쿼리 거부가 아니라 사람이 읽기 전용 질의 결과를 대신 제공하는 경우로 한정한다. 쿼리를 거부할 때는 `reject`를 사용한다고 한 문장 추가한다.

- [ ] **Step 4: 고급 Deep Agents 예제의 모호한 메시지를 질문형 응답으로 바꾼다**

  `"이미 처리됨."` 대신 사용자가 도구 역할을 대신하는 명확한 응답 예시를 사용한다.

- [ ] **Step 5: 문서·한영 미러·회귀 검사를 확인한다**

  Expected: 부작용 거부는 `reject`, synthetic result는 질문형 문맥에서만 `respond`.

- [ ] **Step 6: 작업 단위를 커밋한다**

  Intent line: `Prevent synthetic HITL responses from masquerading as successful side effects`

---

### Task 4: LocalShellBackend 보안 경계 교정

**Files:**
- Modify: `AGENTS.md:125`
- Modify: `docs/deepagents/06-backends.md:11-45`
- Modify: `docs/langchain/31-deep-agent-from-scratch.md:39-50`
- Modify: `07_examples/skills/data-analysis/SKILL.md:35-39`
- Modify: `07_examples/03_data_analysis_agent.ipynb:88-116`
- Modify: `en/07_examples/03_data_analysis_agent.ipynb`
- Modify: `05_advanced/07_data_analysis.ipynb:155-204`
- Modify: `en/05_advanced/07_data_analysis.ipynb`
- Regenerate: `book/chapters/part5/ch07.typ`
- Regenerate: `book/chapters/part7/ch03.typ`
- Regenerate: `en/book/chapters/part5/ch07.typ`
- Regenerate: `en/book/chapters/part7/ch03.typ`

**Interfaces:**
- Consumes: `LocalShellBackend(root_dir=..., virtual_mode=True, env=..., inherit_env=False)`
- Produces: 파일 도구 경로 제한과 셸 격리를 명확히 분리한 안전 설명

- [ ] **Step 1: 위험한 표현의 현재 위치를 기록한다**

  `LocalShellBackend`와 같은 문단 또는 셀에서 “안전 모드”, “sandboxed”, “반드시 virtual_mode=True면 안전” 같은 표현을 검색하고 수정 대상을 확정한다. 영구 검사는 Task 7에서 추가한다.

- [ ] **Step 2: 최상위 규칙을 교정한다**

  `FilesystemBackend(root_dir=..., virtual_mode=True)`는 경로 제한 기본값으로 유지한다. `LocalShellBackend`는 개발 전용이며 `virtual_mode=True`가 셸 격리를 제공하지 않으므로 운영에서는 sandbox backend를 사용한다고 명시한다.

- [ ] **Step 3: 데이터 분석 자료의 예제 구성을 명시적으로 제한한다**

  로컬 예제는 임시 `root_dir`, 최소 `env`, `inherit_env=False`, `interrupt_on={"execute": True}`를 함께 보여준다. 이 조합도 보안 샌드박스가 아니라 피해 범위를 줄이는 개발용 설정이라고 설명한다.

- [ ] **Step 4: 한·영 자료와 파생 장을 동기화한다**

- [ ] **Step 5: 작업 단위를 커밋한다**

  Intent line: `Make the local shell trust boundary explicit in every learner path`

---

### Task 5: Deep Agents 패치 버전과 `delete` 백엔드 계약 정렬

**Files:**
- Modify: `pyproject.toml:8`
- Modify: `uv.lock:595-596`
- Modify: `docs/deepagents/06-backends.md:29-37`
- Modify: `docs/skills/deep-agents-core.md:97-110`
- Modify: `04_deepagents/04_backends.ipynb`
- Modify: `en/04_deepagents/04_backends.ipynb`
- Regenerate: `book/chapters/part4/ch04.typ`
- Regenerate: `en/book/chapters/part4/ch04.typ`

**Interfaces:**
- Consumes: `BackendProtocol.delete(file_path: str) -> DeleteResult`
- Produces: `deepagents>=0.6.12` 환경과 선택적 삭제 기능 설명

- [ ] **Step 1: 의존성 업그레이드 전 런타임 계약을 기록한다**

  `inspect.signature`로 설치된 `BackendProtocol`에 `delete`가 없는 현재 상태와 `deepagents==0.6.10`을 기록한다. 업그레이드 후 같은 명령으로 시그니처와 `DeleteResult`를 확인한다.

- [ ] **Step 2: Deep Agents만 제한적으로 업그레이드한다**

  ```bash
  uv lock --upgrade-package deepagents
  uv sync
  ```

  `uv.lock` diff에서 `deepagents`와 불가피한 직접 종속성 외의 대규모 변경이 있으면 중단한다.

- [ ] **Step 3: 최소 버전을 실제 계약 도입 버전으로 올린다**

  `pyproject.toml`을 `deepagents>=0.6.12`로 변경한다.

- [ ] **Step 4: 백엔드 문서와 노트북을 갱신한다**

  `delete`는 선택적 메서드이고 미구현 백엔드에서는 모델에 도구가 노출되지 않는다고 설명한다. `write`의 create-only 의미와 `delete`의 재귀 삭제 위험을 함께 구분한다.

- [ ] **Step 5: 임시 디렉터리에서 삭제 동작을 검증한다**

  테스트는 임시 파일을 만들고 `FilesystemBackend.delete("/sample.txt")` 성공, 존재하지 않는 경로의 오류 결과, 경로 밖 접근 차단을 확인한다.

- [ ] **Step 6: 작업 단위를 커밋한다**

  Intent line: `Align backend lessons with the optional deletion contract`

---

### Task 6: 코어 공식 문서 링크 갱신

**Files:**
- Modify: `07_examples/01_rag_agent.ipynb:444`
- Modify: `en/07_examples/01_rag_agent.ipynb:374`
- Modify: `07_examples/02_sql_agent.ipynb:487`
- Modify: `en/07_examples/02_sql_agent.ipynb:431`
- Regenerate: `book/chapters/part7/ch01.typ`
- Regenerate: `book/chapters/part7/ch02.typ`
- Regenerate: `en/book/chapters/part7/ch01.typ`
- Regenerate: `en/book/chapters/part7/ch02.typ`
- Add backlog note: `docs/verification/official-docs-link-migration-backlog.md`

**Interfaces:**
- Produces: 현재 `docs.langchain.com`의 LangChain RAG와 SQL Agent 직접 링크

- [ ] **Step 1: 코어 경로의 오래된 도메인 위치를 기록한다**

  `rg -n 'python\.langchain\.com|langchain-ai\.github\.io/langgraph'`로 현재 위치를 기록한다. 대상은 `01_beginner`~`07_examples`, `en/`, `docs/`다. `08_integration/`은 이번 실패 범위에서 제외하고 발견 목록을 보고한다.

- [ ] **Step 2: 네 링크를 현재 공식 URL로 교체한다**

  - RAG: `https://docs.langchain.com/oss/python/langchain/rag`
  - SQL: `https://docs.langchain.com/oss/python/langchain/sql-agent`

- [ ] **Step 3: `08_integration/` 잔여 링크를 별도 백로그에 기록한다**

  각 오래된 URL, 대상 파일, 현재 후보 URL, 확인 상태를 표로 남긴다. 확인하지 않은 후보를 확정 링크로 쓰지 않는다.

- [ ] **Step 4: 코어 링크 검사를 통과시킨다**

- [ ] **Step 5: 작업 단위를 커밋한다**

  Intent line: `Keep core examples anchored to the current official documentation`

---

### Task 7: 공식 문서 정합성 검사와 CI 추가

**Files:**
- Create: `scripts/check_official_docs_alignment.py`
- Create: `docs/verification/official-docs-watchlist.json`
- Create: `tests/__init__.py`
- Create: `tests/test_official_docs_alignment.py`
- Create: `.github/workflows/official-docs-alignment.yml`

**Interfaces:**
- CLI: `check_official_docs_alignment.py [--local] [--online] [--json]`
- Exit code: `0` 정합, `1` 계약 위반 또는 드리프트, `2` 네트워크/설정 오류
- Watchlist entry: `id`, `url`, `required_anchors`, `local_targets`, `forbidden_patterns`, `allowlist`

- [ ] **Step 1: 파서와 판정 함수 단위 테스트를 작성한다**

  최소 함수 계약:

  ```python
  def load_watchlist(path: Path) -> list[dict[str, object]]: ...
  def scan_local(root: Path, entries: list[dict[str, object]]) -> list[Finding]: ...
  def check_upstream(text: str, required_anchors: list[str]) -> list[str]: ...
  def fetch_markdown(url: str, timeout: float = 20.0) -> str: ...
  ```

  네트워크 함수는 `unittest.mock`으로 대체하고 성공, 앵커 누락, HTTP 오류를 검증한다.

- [ ] **Step 2: 테스트 실패를 확인한다**

  ```bash
  uv run python -m unittest tests.test_official_docs_alignment -v
  ```

- [ ] **Step 3: 표준 라이브러리만으로 CLI를 구현한다**

  `argparse`, `json`, `pathlib`, `urllib.request`, `dataclasses`만 사용한다. 기본 실행은 `--local`이며 온라인 검사는 명시적으로 요청할 때만 수행한다.

- [ ] **Step 4: 감시 목록을 작성한다**

  네 개 공식 페이지를 감시한다.

  - LangChain Agents: `create_agent`
  - LangGraph Interrupts: 노드당 단일 `interrupt`, conditional edge 경고
  - Deep Agents HITL: `reject`와 `respond` 의미 구분
  - Deep Agents Backends: `virtual_mode` 셸 경계, 선택적 `delete`

  모델명과 공급자 예시는 앵커에 넣지 않는다.

- [ ] **Step 5: CI를 로컬과 온라인 경로로 분리한다**

  PR/push job은 단위 테스트와 `--local`만 실행한다. 정기·수동 job은 `--online`을 실행해 공식 문서 변경을 감지한다.

- [ ] **Step 6: 실패 출력이 조치 가능함을 검증한다**

  각 finding은 rule id, 파일/URL, 기대 계약, 실제 누락 내용을 포함해야 한다.

- [ ] **Step 7: 작업 단위를 커밋한다**

  Intent line: `Detect official documentation drift before it reaches course material`

---

### Task 8: 한·영 파생 산출물 재생성과 최종 검증

**Files:**
- Regenerate only affected files under `book/chapters/` and `en/book/chapters/`
- Regenerate: `book/agent-handbook.pdf`
- Regenerate: `en/book/agent-handbook-en.pdf`
- Create: `docs/verification/official-docs-alignment-verification.md`

**Interfaces:**
- Consumes: 수정 완료된 노트북
- Produces: 최신 Typst 장, PDF, 검증 기록

- [ ] **Step 1: 대상 노트북 구조를 검사한다**

  JSON 파싱, 셀 ID 순차성, 변경 코드 셀 10줄 제한을 검사한다. 대상은 Tasks 1~6에서 수정한 모든 한·영 노트북이다.

- [ ] **Step 2: 대상 노트북을 실행한다**

  각 경로를 `--only`로 명시한다.

  ```bash
  uv run python local/notebook_execution_01_07_gpt41/run_notebooks.py \
    --only 02_langchain/07_hitl_and_runtime.ipynb \
    --only 03_langgraph/08_interrupts_and_time_travel.ipynb \
    --only 04_deepagents/04_backends.ipynb \
    --only 04_deepagents/07_advanced.ipynb \
    --only 05_advanced/06_sql_agent.ipynb \
    --only 05_advanced/07_data_analysis.ipynb \
    --only 05_advanced/09_production.ipynb \
    --only 07_examples/01_rag_agent.ipynb \
    --only 07_examples/02_sql_agent.ipynb \
    --only 07_examples/03_data_analysis_agent.ipynb \
    --force
  ```

  영어 미러도 같은 방식으로 실행한다. 외부 키가 없는 셀은 기존 하네스 게이트를 그대로 사용한다.

- [ ] **Step 3: 변경한 장만 개별 변환한다**

  전체 config 변환으로 손수 다듬은 장을 덮어쓰지 않는다. 각 노트북과 출력 `.typ`을 위치 인자로 전달하고 해당 장 번호를 지정한다.

  ```bash
  uv run python book/scripts/nb2typ.py \
    03_langgraph/08_interrupts_and_time_travel.ipynb \
    book/chapters/part3/ch08.typ --chapter-number 8
  ```

  나머지 영향 장과 영어 미러도 같은 방식으로 변환한다.

- [ ] **Step 4: 두 핸드북을 컴파일한다**

  ```bash
  uv run python book/scripts/build.py --compile-only
  uv run python en/book/scripts/build.py
  ```

- [ ] **Step 5: 전체 정적 검사를 실행한다**

  ```bash
  uv run python -m unittest tests.test_official_docs_alignment -v
  uv run python scripts/check_official_docs_alignment.py --local
  uv run python scripts/check_official_docs_alignment.py --online
  git diff --check -- . ':(exclude)*.pdf'
  git status --short
  ```

- [ ] **Step 6: 검증 기록을 작성한다**

  `docs/verification/official-docs-alignment-verification.md`에 패키지 버전, 실행한 노트북, Typst/PDF 빌드, 로컬/온라인 검사, 알려진 `08_integration` 링크 백로그를 기록한다.

- [ ] **Step 7: 최종 Lore 커밋을 만든다**

  Intent line: `Keep course artifacts aligned with verified upstream contracts`

  Required trailers:

  ```text
  Constraint: Preserve gpt-5.4 course policy and avoid full upstream mirroring
  Rejected: Full 148-page content sync | creates noisy provider and model churn
  Confidence: high
  Scope-risk: moderate
  Directive: Update the watchlist when upstream behavior changes intentionally
  Tested: Unit tests, local and online alignment checks, targeted notebook execution, KO/EN Typst builds
  Not-tested: Full 08_integration link migration
  ```

---

## Risks and Mitigations

| Risk | Mitigation | Stop condition |
|---|---|---|
| 공식 문구 변경으로 온라인 오탐 | 짧은 의미 앵커 여러 개 사용, 모델명 제외 | 핵심 계약을 사람이 확인할 수 없으면 watchlist 갱신 보류 |
| `uv.lock` 대규모 변화 | `--upgrade-package deepagents`만 사용하고 diff 검토 | 무관 패키지가 대량 변경되면 업그레이드 분리 |
| 한·영 노트북 내용 불일치 | 같은 task에서 함께 수정하고 API 토큰 검사 | 한쪽만 실행되거나 파생 장이 다르면 미완료 |
| 자동 변환이 수동 Typst 편집 덮어씀 | 개별 입력/출력 변환만 사용 | 대상 밖 `.typ` 변경 발생 시 되돌리고 원인 조사 |
| 네트워크 불안정으로 PR 실패 | PR은 `--local`, 온라인은 정기·수동 실행 | 온라인 오류는 exit code 2로 계약 드리프트와 구분 |

## Verification Matrix

| Claim | Proof |
|---|---|
| 인터럽트 재질문이 선형 실행 | 단위 테스트 + 대상 노트북 실행 + 공식 앵커 검사 |
| 레거시 API 제거 | 허용 목록 기반 repo scan |
| HITL 의미 정합 | 문맥 기반 금지 패턴 검사 + 노트북 실행 |
| LocalShell 경계 명시 | 문구 검사 + 문서/노트북 검토 |
| `delete` 계약 사용 가능 | 설치 버전·시그니처·임시 파일 삭제 테스트 |
| 링크 최신성 | 코어 도메인 scan + HTTP 최종 URL 검사 |
| 한·영·PDF 동기화 | JSON/셀 ID 검사 + 대상 Typst diff + 두 PDF 빌드 |

## Stop Condition

모든 Acceptance Criteria가 증거와 함께 통과하고, `git status --short`에 계획된 파일만 남으며, 알려진 잔여 범위가 `08_integration` 링크 백로그로 한정될 때 완료한다. 하나라도 충족하지 못하면 완료로 보고하지 않고 해당 Task로 돌아간다.
