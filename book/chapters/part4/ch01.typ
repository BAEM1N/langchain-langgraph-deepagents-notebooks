// Auto-generated from 01_introduction.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "Deep Agents 소개")

== 학습 목표
#learning-objectives([Deep Agents가 무엇인지 이해한다], [SDK와 Deep Agents Code(`dcode`)의 차이를 파악한다], [핵심 개념 6가지(Planning, Context Management, Backends, Subagents, Memory, Quality Gates)를 이해한다], [다른 프레임워크와의 차이를 비교한다], [설치 상태를 확인한다])

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. Deep Agents란?

_Deep Agents_는 LangChain 팀이 만든 _에이전트 하네스(Agent Harness)_ 프레임워크입니다.
복잡한 멀티 스텝 작업을 수행하는 자율 에이전트를 쉽게 구축할 수 있도록, 아래 기능들을 내장하고 있습니다:

- _태스크 플래닝_ — 복잡한 문제를 단계별로 분해 (`write_todos`)
- _컨텍스트 관리_ — 파일 시스템 도구(`ls`, `read_file`, `write_file`, `edit_file`)
- _셸 실행_ — 샌드박스 백엔드 격리
- _JavaScript 인터프리터_ — QuickJS 런타임으로 가벼운 도구 조합 (셸/네트워크 차단)
- _플러거블 백엔드_ — in-memory state, local disk, LangGraph store, ContextHub, sandbox
- _서브에이전트 위임_ — 컨텍스트 격리와 병렬 작업
- _장기 메모리_ — LangGraph Memory Store 기반 스레드 간 지식 유지
- _파일 시스템 권한_ — 선언적 read/write 규칙
- _Human-in-the-Loop_ — `interrupt_on` 승인 워크플로
- _재사용 가능한 스킬_ — 특화 워크플로
- _시스템 프롬프트 커스터마이징 훅_

LangChain의 기본 에이전트 컴포넌트 위에 구축되었으며, _LangGraph_를 실행 엔진(durable execution + streaming)으로 사용합니다.

#tip-box[_이 교육 자료의 모델 설정_: 본 과정에서는 _OpenAI `gpt-5.4`_ 모델을 사용합니다. `OPENAI_API_KEY` 환경 변수를 설정하고, `ChatOpenAI(model="gpt-5.4")`를 사용합니다. Deep Agents의 표준 기본 모델은 `anthropic:claude-sonnet-4-6` 입니다.]

=== 아키텍처 개요

#image("../../assets/images/deepagents_architecture.png")

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. Deep Agents 제품군

Deep Agents 생태계는 세 가지 형태로 제공됩니다:

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[구분],
  text(weight: "bold")[Deep Agents SDK],
  text(weight: "bold")[Deep Agents Code],
  text(weight: "bold")[ACP Integration],
  [_패키지_],
  [`deepagents`],
  [`deepagents-code` (`dcode`)],
  [ACP 커넥터],
  [_용도_],
  [프로그래밍 방식으로 에이전트 구축],
  [터미널 코딩 에이전트],
  [Zed 등 코드 에디터 내장],
  [_설치_],
  [`pip install -qU deepagents langchain-{provider}`],
  [`curl -LsSf https://langch.in/dcode \\],
  [bash` 또는 `uvx --from deepagents-code dcode --help`],
  [Zed 확장 설치],
  [_사용 방식_],
  [Python 코드에서 `create_deep_agent()` 호출],
  [터미널에서 `dcode` 실행],
  [에디터의 ACP 클라이언트 호출],
  [_커스터마이징_],
  [완전한 API 접근 (도구·백엔드·미들웨어)],
  [`~/.deepagents/config.toml`, `AGENTS.md`, `SKILL.md`, slash commands],
  [SDK 그대로 + 에디터 UI],
  [_적합한 경우_],
  [앱에 에이전트 통합, 자동화 파이프라인],
  [대화형/비대화형 코딩 어시스턴트],
  [에디터 내부 워크플로],
)

`{provider}` 자리에는 `anthropic`, `openai`, `google-genai`, `openrouter`, `fireworks`, `baseten`, `ollama` 중 사용 모델에 맞는 값을 넣습니다.

#tip-box[이 교육 자료에서는 _SDK_를 중심으로 다루고, CLI 사용은 Deep Agents Code(`dcode`) 기준으로 소개합니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. 핵심 개념 6가지

=== 3.1 Planning (태스크 플래닝)
에이전트는 `write_todos` 도구로 복잡한 작업을 _구조화된 태스크 리스트_로 분해합니다.
각 태스크는 `pending` → `in_progress` → `completed` 상태로 추적됩니다.

=== 3.2 Context Management (컨텍스트 관리)
에이전트가 작업하면서 생성되는 방대한 정보(파일 내용, 검색 결과 등)를 효율적으로 관리합니다:
- _오프로딩_: 큰 출력은 파일 시스템 도구로 디스크에 저장하고 포인터만 유지
- _요약_: 컨텍스트가 모델 한도에 가까워지면 `SummarizationMiddleware`가 대화 이력을 압축

=== 3.3 Backends (스토리지 백엔드)
에이전트의 파일 시스템은 _플러거블 백엔드_로 구현됩니다:
- `StateBackend` — 에이전트 상태에 파일 저장 (스레드 한정, 기본값)
- `FilesystemBackend` — 로컬 디스크 접근
- `StoreBackend` — 크로스 스레드 영속 저장소 (`langgraph.store`)
- `ContextHubBackend` — LangSmith Hub 저장소
- `CompositeBackend` — 경로별 라우팅
- _샌드박스_ — Modal / Daytona / Deno / local VFS

=== 3.4 Subagents (서브에이전트)
메인 에이전트가 전문 서브에이전트에게 작업을 위임합니다.
`SubAgentMiddleware`가 `task` 도구를 자동 주입하며, _컨텍스트 블로트_ 문제를 해결합니다.

=== 3.5 Memory & Skills (장기 메모리·스킬)
- _Memory_ — `StoreBackend` + `AGENTS.md`로 항상 주입되는 컨벤션
- _Skills_ — `SKILL.md` 기반 progressive disclosure로 필요 시 로드
- _JavaScript Interpreter_ — QuickJS로 도구 조합/중간 상태 유지 (`deepagents>=0.6`)

=== 3.6 Quality Gates (런타임 평가)
`RubricMiddleware`는 에이전트 실행 결과를 LLM-as-a-judge 방식으로 점검하고, 필요하면 같은 실행 안에서 수정을 유도합니다.
프로덕션 전에는 `agentevals`/LangSmith 평가로 회귀 테스트를 만들고, 실행 중에는 rubric으로 품질 기준을 한 번 더 확인합니다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. 다른 프레임워크와의 비교

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[LangChain Deep Agents],
  text(weight: "bold")[OpenCode],
  text(weight: "bold")[Claude Agent SDK],
  [_모델 지원_],
  [모델 무관 (Anthropic, OpenAI 등 100+)],
  [75+ 프로바이더 (Ollama 포함)],
  [Claude 전용],
  [_라이선스_],
  [MIT],
  [MIT],
  [MIT (SDK) / 독점 (Claude Code)],
  [_SDK_],
  [Python, TypeScript + CLI],
  [터미널, 데스크톱, IDE],
  [Python, TypeScript],
  [_샌드박스_],
  [도구로 통합 (Modal, Daytona 등)],
  [미지원],
  [미지원],
  [_플러거블 백엔드_],
  [O (State, FS, Store, Composite)],
  [X],
  [X],
  [_타임 트래블_],
  [O (LangGraph)],
  [X],
  [O],
  [_관측성_],
  [LangSmith 네이티브],
  [X],
  [X],
  [_파일 도구 기본 내장_],
  [O],
  [O],
  [O],
  [_Human-in-the-Loop_],
  [O (미들웨어)],
  [O],
  [O],
)

#tip-box[Deep Agents의 핵심 차별점: _플러거블 백엔드_, _샌드박스 통합_, _LangSmith 관측성_]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. 설치 확인

#code-block(`````bash
pip install -qU deepagents langchain-openai
# 다른 프로바이더를 쓰려면 langchain-anthropic, langchain-google-genai,
# langchain-openrouter, langchain-fireworks, langchain-baseten, langchain-ollama 중 선택
`````)

아래 셀을 실행하여 `deepagents` 패키지가 올바르게 설치되었는지 확인합니다.

#code-block(`````python
# deepagents 패키지 버전 확인
import deepagents
print(f"deepagents 버전: {deepagents.__version__}")
`````)
#output-block(`````
deepagents 버전: 0.4.4
`````)

#code-block(`````python
# 주요 모듈 임포트 확인
from deepagents import create_deep_agent, SubAgent, CompiledSubAgent
from deepagents import FilesystemMiddleware, MemoryMiddleware, SubAgentMiddleware
from deepagents.backends import StateBackend, FilesystemBackend, StoreBackend, CompositeBackend
from deepagents.backends.protocol import BackendProtocol

print("모든 주요 모듈을 성공적으로 임포트했습니다!")
`````)
#output-block(`````
모든 주요 모듈을 성공적으로 임포트했습니다!
`````)

#code-block(`````python
# 의존 패키지 버전 확인
import importlib.metadata

print(f"langchain 버전: {importlib.metadata.version('langchain')}")
print(f"langgraph 버전: {importlib.metadata.version('langgraph')}")
`````)
#output-block(`````
langchain 버전: 1.2.10
langgraph 버전: 1.0.10
`````)

#code-block(`````python
# create_deep_agent 함수 시그니처 확인
import inspect

sig = inspect.signature(create_deep_agent)
print("create_deep_agent() 파라미터:")
for name, param in sig.parameters.items():
    default = param.default if param.default is not inspect.Parameter.empty else "(필수)"
    print(f"  - {name}: {default}")
`````)
#output-block(`````
create_deep_agent() 파라미터:
  - model: None
  - tools: None
  - system_prompt: None
  - middleware: ()
  - subagents: None
  - skills: None
  - memory: None
  - response_format: None
  - context_schema: None
  - checkpointer: None
  - store: None
  - backend: None
  - interrupt_on: None
  - debug: False
  - name: None
  - cache: None
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 핵심 정리

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [Deep Agents],
  [LangChain 기반 에이전트 하네스 프레임워크],
  [핵심 함수],
  [`create_deep_agent()`],
  [실행 엔진],
  [LangGraph (`CompiledStateGraph` 반환)],
  [모델 표준],
  [Deep Agents 기본 `anthropic:claude-sonnet-4-6`, 본 교재 OpenAI `gpt-5.4`],
  [모델 접근],
  [`ChatOpenAI(model="gpt-5.4")` 또는 `provider:model-name` 문자열],
  [핵심 개념],
  [Planning, Context Management, Backends, Subagents, Memory & Skills, Quality Gates],
  [빌트인 도구],
  [`write_todos`, `ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`, `task`],
  [인터프리터],
  [QuickJS 기반 JavaScript runtime (`deepagents\>=0.6`, 셸·네트워크 불가)],
  [품질 게이트],
  [`RubricMiddleware`로 런타임 LLM-as-a-judge 평가와 재시도 제어],
  [CLI],
  [Deep Agents Code(`dcode`) — `deepagents-code` 패키지 기반 터미널 에이전트],
)
