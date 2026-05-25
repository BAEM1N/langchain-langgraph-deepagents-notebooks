# Framework Selection

LangChain, LangGraph, Deep Agents 세 프레임워크의 비교 및 선택 기준.

## 계층 아키텍처

```
Deep Agents (최상위 하네스)
  ├── 계획, 메모리, 스킬, 파일, 서브에이전트
  ├── 17-파라미터 create_deep_agent() 진입점
  ├── 내장 미들웨어: TodoList, Filesystem, SubAgent, Summarization,
  │   AnthropicPromptCaching, PatchToolCalls (+ Skills/Memory/HITL)
  │
LangChain v1 (에이전트 + 미들웨어)
  ├── create_agent(), 6단계 미들웨어 훅
  ├── response_format (ToolStrategy / ProviderStrategy)
  ├── context_schema + runtime.execution_info / server_info
  │
LangGraph (오케스트레이션 런타임)
  └── StateGraph, 노드/엣지, Command/Send, checkpointer, Store
```

Deep Agents 는 LangChain 위에 얹는 사전 구성 미들웨어 묶음, LangChain v1 의 `create_agent()` 는 내부적으로 LangGraph `StateGraph` 로 컴파일된다. 즉 모두 동일한 런타임을 공유하므로 혼합 사용이 자연스럽다.

## 선택 기준

| 기준 | LangChain v1 | LangGraph | Deep Agents |
|------|--------------|-----------|-------------|
| 진입점 | `create_agent()` | `StateGraph` | `create_deep_agent()` |
| 제어 단위 | 6단계 미들웨어 훅 | 노드/엣지/Command | 미들웨어 묶음 + 서브에이전트 |
| 상태 관리 | AgentState (TypedDict) | 임의 state schema + checkpointer | StateBackend/StoreBackend/FilesystemBackend/Composite |
| 멀티 에이전트 | handoff 도구 | 서브그래프 / Send fan-out | `SubAgentMiddleware` + `task` 도구 |
| 파일 I/O | 수동 (도구 직접 작성) | 수동 | 내장 도구 7종 + BackendProtocol |
| 계획 수립 | 수동 | 수동 | `write_todos` 내장 |
| 컨텍스트 압축 | 수동 / `SummarizationMiddleware` | 수동 | 기본 활성 (offload + summarize) |
| HITL | `HumanInTheLoopMiddleware` | `interrupt()` + `Command(resume=...)` | `interrupt_on` 설정만 |
| 학습 곡선 | 낮음 | 중간 | 중간 (의견 있는 기본값) |

## Pattern Selection Matrix

| 패턴 | 권장 프레임워크 | 근거 |
|------|---------------|------|
| 도구 몇 개 붙은 단일 assistant | **LangChain v1** `create_agent()` | 최소 구성, 6훅 미들웨어로 확장 |
| 구조화된 추출 (RAG 후처리, 분류) | **LangChain v1** `response_format=` | `ToolStrategy` / `ProviderStrategy` 자동 선택 |
| RAG 파이프라인 (loader → splitter → vectorstore → retriever) | **LangChain v1** 컴포넌트 | LCEL 보조 사용 가능 |
| 다단계 결정적 워크플로 (분류 → 라우팅 → 후처리) | **LangGraph** `StateGraph` | 노드 단위 추적·재시도·분기 |
| 사이클/재시도 루프, 정확한 분기 제어 | **LangGraph** | edge 조건 표현이 가장 명시적 |
| 사람 승인이 여러 단계에 끼어드는 흐름 | **LangGraph** `interrupt()` | resume 토큰으로 재개 |
| 파일 기반 자율 작업 (조사 → 메모 → 보고서) | **Deep Agents** | 가상 파일시스템 + 컨텍스트 압축이 기본 |
| 서브에이전트 fan-out 으로 컨텍스트 격리 | **Deep Agents** | `SubAgentMiddleware` + `task` 도구 |
| 멀티 테넌트 배포, LangSmith 통합 운영 | **Deep Agents** | Hub 백엔드, 네임스페이스 팩토리, 매니지드 배포 |
| 단순 1회성 변환 (prompt | model | parser) | LCEL (보조용) | 에이전트 orchestration 의 기본값은 아님 |

## 언제 무엇을 선택하는가

- **LangChain v1**: 단일 에이전트, 도구 호출, 구조화 출력, RAG. 미들웨어로 정책·관찰성·HITL 을 부착한다.
- **LangGraph**: 단계가 분리되거나 사람 승인·재시도·서브그래프가 필요한 워크플로. 상태 schema 와 checkpointer 를 직접 다룬다.
- **Deep Agents**: 파일 시스템·계획·서브에이전트가 한꺼번에 필요한 자율 에이전트. Anthropic 캐싱·요약·오류 복구가 기본 활성이라 처음부터 작업 자체에 집중할 수 있다.

## 프레임워크 혼합

세 프레임워크는 동일 런타임을 공유하므로 자유롭게 섞을 수 있다. Deep Agents 내부에서 LangChain 도구를 그대로 쓰고, 복잡한 노드는 LangGraph 서브그래프(`CompiledSubAgent`) 로 끼워 넣는 패턴이 표준이다.

```python
from deepagents import create_deep_agent
from langchain.tools import tool

@tool
def lookup_internal(query: str) -> str:
    """Search internal knowledge base."""
    return knowledge_base.search(query)

agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    tools=[lookup_internal],
    subagents=[research_subagent],  # SubAgent dict or CompiledSubAgent
)
```

## 결정 순서 요약

1. **단계가 하나뿐이고 도구 호출만 있는가?** → LangChain v1 `create_agent()`.
2. **분기·루프·HITL 이 명시적으로 보이는가?** → LangGraph `StateGraph`.
3. **파일/계획/서브에이전트가 함께 필요한가?** → Deep Agents `create_deep_agent()`.
4. **여러 형태가 섞여 있는가?** → Deep Agents 를 셸로 두고 내부 노드에 LangGraph/LangChain 을 끼워 넣는다.
