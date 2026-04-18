# LangChain v1 Modern Authoring Guardrail

이 문서는 **LangChain v1 코드를 작성할 때 legacy 패턴으로 회귀하지 않도록 막는 공용 기준서**다.
특히 다음 두 가지를 기본 선택지로 두지 않는다.

- `create_react_agent()`
- LCEL 기반 `prompt | model | parser` 스타일 체인을 **에이전트/워크플로의 주 orchestration**으로 사용하는 방식

## 목적

이 레포에서는 LangChain v1의 현재 권장 패턴을 중심으로 교육 자료와 예제를 유지한다.
따라서 코드 작성 시 기본 출발점은 다음과 같다.

1. **도구 호출 에이전트**: `create_agent()`
2. **결정적 분기/루프/다단계 워크플로**: `StateGraph` 기반 커스텀 워크플로
3. **구조화된 추출**: `with_structured_output()`
4. **상태/대화 지속성**: checkpointer + `thread_id`
5. **런타임 개입 지점**: middleware

## 소스 우선순위

항상 아래 순서로 근거를 찾는다.

1. 이 레포의 `docs/skills/*.md`
2. 이 레포의 `docs/langchain/*.md`
3. 관련 노트북 (`02_langchain/`, `05_advanced/`)
4. 그래도 부족할 때만 공식 문서/공식 skill

## 기본 선택 규칙

### 1) 도구를 쓰는 assistant/agent를 만들 때
**기본값은 `create_agent()`** 이다.

근거 소스:
- `docs/skills/langchain-fundamentals.md`
- `docs/langchain/03-agents.md`
- `02_langchain/01_introduction.ipynb`

권장 예:

```python
from langchain.chat_models import init_chat_model
from langchain.agents import create_agent

model = init_chat_model("openai:gpt-4.1")
agent = create_agent(model, tools=[...], system_prompt="...")
```

### 2) 단계형 파이프라인, 분기, 루프, HITL이 필요할 때
**기본값은 LangGraph `StateGraph`** 이다.

근거 소스:
- `docs/langchain/23-custom-workflow.md`
- `02_langchain/09_custom_workflow_and_rag.ipynb`
- `03_langgraph/*`

규칙:
- 단순 도구 호출 assistant면 `create_agent()`
- 검색 → 검증 → 라우팅 → 후처리처럼 **단계가 분리**되면 `StateGraph`
- 사람 승인, 재시도 루프, 조건 분기, 서브그래프가 보이면 `StateGraph`

### 3) 출력 스키마가 중요할 때
**기본값은 `with_structured_output()`** 이다.

근거 소스:
- `docs/langchain/09-structured-output.md`
- `docs/skills/langchain-fundamentals.md`

### 4) 실행 전후 훅, 정책, 관찰 가능성이 필요할 때
**기본값은 middleware** 이다.

근거 소스:
- `docs/langchain/10-middleware-overview.md`
- `docs/langchain/11-middleware-builtin.md`
- `docs/langchain/12-middleware-custom.md`
- `docs/skills/langchain-middleware.md`

## 피해야 할 패턴

### A. `create_react_agent()`를 새 코드의 기본값으로 사용
이 레포에서는 `create_react_agent()`를 **신규 예제의 기본 API로 사용하지 않는다.**

허용되는 경우:
- v0.x → v1 마이그레이션을 설명하는 비교 섹션
- “왜 지금은 `create_agent()`를 쓰는가”를 보여주는 역사적 예시

그 외에는 `create_agent()`로 바꾼다.

### B. LCEL 체인을 agent orchestration의 기본값으로 사용
다음 같은 패턴을 **에이전트 대체재로 남용하지 않는다.**

```python
chain = prompt | model | parser
```

LCEL이 허용되는 경우:
- 아주 짧은 1회성 변환
- 내부 헬퍼 runnable
- 스트리밍/어댑터 레이어의 국소 조합

LCEL을 피해야 하는 경우:
- tool calling agent를 만들 때
- 상태를 유지해야 할 때
- 조건 분기/루프가 있을 때
- 사람 개입(HITL)이나 persistence가 필요할 때

즉, **LCEL은 보조 구성 요소로는 가능하지만, 이 레포의 기본 orchestration 패턴은 아니다.**

## 빠른 결정표

| 상황 | 기본 선택 |
|------|-----------|
| 도구 몇 개 붙인 범용 assistant | `create_agent()` |
| 구조화된 추출 | `with_structured_output()` |
| 대화 지속성/스레드 관리 | checkpointer + `thread_id` |
| 정책/로깅/승인/동적 제어 | middleware |
| 검색→판단→후처리 같은 다단계 흐름 | `StateGraph` |
| 조건 분기/루프/HITL | `StateGraph` |
| 역사적 비교용 legacy 예시 | 제한적으로 `create_react_agent()` / LCEL |

## 이 레포에서 먼저 볼 파일

### LangChain v1 핵심
- `docs/skills/langchain-fundamentals.md`
- `docs/langchain/03-agents.md`
- `docs/langchain/09-structured-output.md`
- `docs/langchain/10-middleware-overview.md`
- `docs/langchain/14-runtime.md`
- `docs/langchain/17-human-in-the-loop.md`
- `docs/langchain/23-custom-workflow.md`

### 실제 교육 예제
- `02_langchain/01_introduction.ipynb`
- `02_langchain/06_middleware.ipynb`
- `02_langchain/07_hitl_and_runtime.ipynb`
- `02_langchain/09_custom_workflow_and_rag.ipynb`
- `05_advanced/01_middleware.ipynb`

## 공식 LangChain skill과의 차별점

LangChain 팀의 공식 example skill 중 하나는 `langgraph-docs` 스타일의 **문서 fetcher skill**이다.
그 skill의 핵심 역할은:
- 온라인 문서 인덱스(`llms.txt`)를 읽고
- 관련 문서를 2~4개 골라
- 구현에 필요한 LangGraph 문서를 가져오는 것

반면 이 레포의 `langchain-v1-modern`은 다음에 초점을 둔다.

1. **repo-local source first**
   - 먼저 이 레포의 `docs/`와 노트북을 본다.
2. **LangChain v1 authoring guardrail**
   - `create_react_agent()` / LCEL 회귀를 막는다.
3. **교육 자료 작성 기준 포함**
   - 이 레포 예제/노트북 구조와 맞는 선택을 강제한다.
4. **LangChain 중심**
   - generic docs fetching이 아니라, LangChain v1의 권장 authoring 패턴을 고정한다.

정리하면:
- **공식 skill**: 온라인 문서 탐색기
- **우리 skill**: 이 레포용 LangChain v1 작성 가드레일
