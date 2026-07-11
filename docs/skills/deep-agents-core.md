# Deep Agents Core

에이전트 아키텍처, 하네스 설정, SKILL.md 형식.

## 아키텍처

Deep Agents 는 내장 미들웨어 묶음 위에서 작동한다. 기본 스택은 다음과 같다.

| 미들웨어 | 기능 |
|----------|------|
| `TodoListMiddleware` | 계획 수립 (`write_todos`) |
| `FilesystemMiddleware` | 파일 I/O (`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`) |
| `SubAgentMiddleware` | 서브에이전트 위임 (`task`) — 동기 서브에이전트가 있으면 자동 부착, 제거 불가 |
| `SummarizationMiddleware` | 컨텍스트 압축 |
| `AnthropicPromptCachingMiddleware` | 토큰 캐시 최적화 |
| `PatchToolCallsMiddleware` | 도구 호출 오류 복구 |
| `SkillsMiddleware` | 스킬 progressive disclosure (선택) |
| `MemoryMiddleware` | AGENTS.md → 시스템 프롬프트 (선택) |
| `HumanInTheLoopMiddleware` | 승인 워크플로 (선택) |

## 에이전트 생성

`create_deep_agent()` 의 17 파라미터 시그니처:

```python
create_deep_agent(
    model: str | BaseChatModel | None = None,
    tools: Sequence[BaseTool | Callable | dict[str, Any]] | None = None,
    *,
    system_prompt: str | SystemMessage | None = None,
    middleware: Sequence[AgentMiddleware] = (),
    subagents: Sequence[SubAgent | CompiledSubAgent | AsyncSubAgent] | None = None,
    skills: list[str] | None = None,
    memory: list[str] | None = None,
    permissions: list[FilesystemPermission] | None = None,
    backend: BackendProtocol | BackendFactory | None = None,
    interrupt_on: dict[str, bool | InterruptOnConfig] | None = None,
    response_format: ResponseFormat[ResponseT] | type[ResponseT] | dict[str, Any] | None = None,
    context_schema: type[ContextT] | None = None,
    checkpointer: Checkpointer | None = None,
    store: BaseStore | None = None,
    debug: bool = False,
    name: str | None = None,
    cache: BaseCache | None = None,
) -> CompiledStateGraph
```

기본 모델은 `claude-sonnet-4-6`. 모델 ID 는 `provider:model-name` 형식을 따른다 (`anthropic:claude-sonnet-4-6`, `openai:gpt-5.4`, `google_genai:gemini-3.5-flash` 등).

예시:

```python
from deepagents import create_deep_agent

agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    memory=["./AGENTS.md"],
    skills=["./skills/"],
    tools=[custom_tool_1, custom_tool_2],
    backend=FilesystemBackend(root_dir="./output"),
)
```

## SKILL.md 형식

```yaml
---
name: skill-name
description: Short description for progressive disclosure
---

# Skill Name

Detailed instructions loaded when the agent needs this skill.

## Workflow
1. Step one
2. Step two
```

YAML frontmatter 의 `description` 이 항상 노출되고, 본문은 `SkillsMiddleware` 가 필요 시 로드한다.

## 내장 도구

| 도구 | 기능 |
|------|------|
| `write_todos` | 작업 계획 저장 |
| `ls` | 디렉토리 목록 |
| `read_file` | 파일 읽기 (이미지·오디오·비디오·PDF 멀티모달) |
| `write_file` | 파일 쓰기 |
| `edit_file` | 정확한 문자열 치환 (`replace_all` 옵션) |
| `glob` | 패턴 매칭 파일 검색 |
| `grep` | 파일 내용 검색 |
| `task` | 서브에이전트 호출 (SubAgentMiddleware 가 주입) |
| `execute` | 셸 실행 (LocalShellBackend / Sandbox 한정) |

## BackendProtocol

커스텀 백엔드는 다음 메서드를 구현한다 (옛 `ls_info` 명칭은 더 이상 사용하지 않는다).

| 메서드 | 반환 | 비고 |
|--------|------|------|
| `ls(path)` | `LsResult` | entries 는 결정적으로 정렬 |
| `read(file_path, offset=0, limit=2000)` | `ReadResult` | 누락 파일은 `ReadResult(error=...)` |
| `grep(pattern, path=None, glob=None)` | `GrepResult` | 오류 시 raise 대신 `error=` 반환 |
| `glob(pattern, path="/")` | `GlobResult` | 무매칭은 `matches=[]` |
| `write(file_path, content)` | `WriteResult` | create-only, 충돌 시 `error=` |
| `edit(file_path, old_string, new_string, replace_all=False)` | `EditResult` | `replace_all=False` 면 unique 매칭 강제, `occurrences` 포함 |

현재 안정판 `deepagents==0.6.12`에는 `BackendProtocol.delete`가 없다. 공식 호스팅 문서의 선택적 `delete(file_path) -> DeleteResult`는 `0.7.0a6` 프리릴리스에서 확인되므로, 안정판 0.7 채택 전에는 현재 실습 API로 가르치지 않는다.

## TodoList + Dispatch 패턴

`TodoListMiddleware` 가 제공하는 `write_todos` 로 계획을 세우고, `SubAgentMiddleware` 의 `task` 도구로 항목별 위임한다. 스트리밍/도구 추적 시 `lc_agent_name` 메타데이터로 어떤 서브에이전트의 호출인지 구분할 수 있다.

## 설정 경계

**커스터마이즈 가능**: 모델, 도구, 시스템 프롬프트, 백엔드, 스킬, 서브에이전트, 권한, HITL, 응답 포맷, context schema, checkpointer/store, 캐시.

**변경 불가**: 동기 서브에이전트를 쓰는 한 `SubAgentMiddleware` 는 `excluded_middleware` 로 제거할 수 없다 (강제 시 `ValueError`). 내장 도구 이름은 그대로 유지된다.
