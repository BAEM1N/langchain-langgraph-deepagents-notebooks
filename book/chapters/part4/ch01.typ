// Auto-generated from 01_introduction.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "Deep Agents 소개")

Deep Agents는 LangChain 팀이 개발한 에이전트 하네스 프레임워크로, 복잡한 멀티 스텝 작업을 수행하는 자율 에이전트를 체계적으로 구축할 수 있게 해 준다. 이 장에서는 `Planning`, `Context Management`, `Backends`, `Subagents`, `Memory` 등 Deep Agents의 핵심 개념 다섯 가지를 소개하고, SDK와 CLI의 차이점을 살펴본다. 프레임워크의 전체 구조를 조감함으로써 이후 장에서 다룰 심화 주제들의 기반을 마련한다.

기존 에이전트 프레임워크들이 "LLM + 도구 호출"이라는 최소 단위에 머물렀다면, Deep Agents는 여기에 _계획 수립_, _컨텍스트 압축_, _파일 시스템 추상화_, _서브에이전트 위임_, _장기 메모리_라는 다섯 가지 인프라를 기본 탑재하여, 장기 실행 자율 에이전트를 위한 포괄적 하네스(harness)를 제공한다. `create_deep_agent()` 한 줄이면 이 모든 기능이 조립된 `CompiledStateGraph`가 반환되며, LangGraph의 모든 실행 메서드(`invoke`, `stream`, `batch`)를 그대로 활용할 수 있다.

#learning-header()
#learning-objectives([Deep Agents가 무엇인지 이해한다], [SDK와 CLI의 차이를 파악한다], [핵심 개념 5가지(Planning, Context Management, Backends, Subagents, Memory)를 이해한다], [다른 프레임워크와의 차이를 비교한다], [설치 상태를 확인한다])

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. Deep Agents란?

_Deep Agents_는 LangChain 팀이 만든 _에이전트 하네스(Agent Harness)_ 프레임워크입니다.
복잡한 멀티 스텝 작업을 수행하는 자율 에이전트를 쉽게 구축할 수 있도록, 아래 기능들을 내장하고 있습니다:

- _태스크 플래닝_ — 복잡한 문제를 단계별로 분해
- _파일 시스템 관리_ — 가상/로컬 파일 읽기·쓰기·검색
- _서브에이전트 위임_ — 전문 에이전트에게 작업 분배
- _장기 메모리_ — 대화를 넘어서 지식 유지
- _컨텍스트 관리_ — 토큰 한도 내에서 효율적 정보 관리

"에이전트 하네스"라는 이름이 시사하듯, Deep Agents는 LLM을 단순히 감싸는 래퍼가 아니라 장기 실행 자율 에이전트가 안정적으로 동작하기 위한 _운영 인프라 전체_를 포괄합니다. 기존 "LLM + 도구 호출" 패러다임에서는 개발자가 계획 수립, 토큰 관리, 파일 영속성 등을 모두 직접 구현해야 했지만, Deep Agents는 이 반복적인 인프라를 표준화하여 제공합니다.

LangChain의 기본 에이전트 컴포넌트 위에 구축되었으며, _LangGraph_를 실행 엔진으로 사용합니다. 내부적으로 `AgentHarness`가 모델, 도구, 미들웨어, 상태 스키마를 수집하여 `StateGraph`를 구성하고, 미들웨어 파이프라인을 적용한 뒤 컴파일합니다. 이 조립 과정은 크게 세 단계로 이루어집니다: (1) 파라미터로 전달된 모델, 도구, 백엔드 등을 수집하고, (2) 각 미들웨어가 빌트인 도구와 시스템 프롬프트를 주입하며, (3) 최종적으로 `StateGraph`를 컴파일하여 `CompiledStateGraph`를 반환합니다. 개발자는 이 과정을 알 필요 없이 `create_deep_agent()`라는 편의 래퍼만 호출하면 됩니다.

#warning-box[Deep Agents는 LangGraph 위에서 동작하므로, LangGraph의 기본 개념(StateGraph, 노드, 엣지, 체크포인터)을 이해하고 있으면 내부 동작을 훨씬 깊이 파악할 수 있습니다. Part 3(LangGraph)를 먼저 학습하는 것을 권장합니다.]

#tip-box[_이 교육 자료의 모델 설정_: 본 과정에서는 _OpenAI gpt-4.1_ 모델을 사용합니다. `OPENAI_API_KEY` 환경 변수를 설정하고, `ChatOpenAI(model="gpt-4.1")`를 사용합니다.]

=== 아키텍처 개요

Deep Agents의 아키텍처는 세 계층으로 구성됩니다. 최하단에는 LangChain의 모델/도구 인터페이스가 위치하고, 중간 계층의 LangGraph가 상태 기반 그래프 실행을 담당하며, 최상위에 Deep Agents 하네스가 계획, 파일시스템, 서브에이전트, 메모리 등 고수준 기능을 통합합니다. 이 계층 구조 덕분에 각 계층의 기능을 독립적으로 교체하거나 확장할 수 있습니다. 예를 들어, LangChain 계층에서 모델만 교체하면 나머지 인프라는 그대로 유지되고, LangGraph 계층에서 체크포인터를 바꾸면 영속성 전략만 변경됩니다.

#align(center)[#image("../../assets/diagrams/png/deepagents_architecture.png", width: 78%, height: 112mm, fit: "contain")]

아래 다이어그램에서 주목할 점은 _화살표의 방향_입니다. Deep Agents 하네스는 LangGraph와 LangChain을 _의존_하지만, 반대 방향은 성립하지 않습니다. 즉, LangGraph로 직접 그래프를 구축하던 기존 코드도 Deep Agents 없이 독립적으로 동작할 수 있습니다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. SDK vs CLI

아키텍처를 이해했으니, 이제 Deep Agents를 실제로 사용하는 두 가지 방법을 비교합니다.

Deep Agents는 동일한 핵심 엔진 위에 구축된 두 가지 인터페이스를 제공합니다. 프로그래밍 방식으로 에이전트를 앱에 통합하고 싶다면 SDK를, 터미널에서 즉시 코딩 에이전트를 사용하고 싶다면 CLI를 선택합니다. 두 인터페이스 모두 내부적으로 동일한 `AgentHarness` 엔진을 사용하므로, 한쪽에서 익힌 개념(백엔드, 미들웨어, 서브에이전트 등)은 다른 쪽에서도 그대로 적용됩니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[구분],
  text(weight: "bold")[Deep Agents SDK],
  text(weight: "bold")[Deep Agents CLI],
  [_패키지_],
  [`deepagents`],
  [`deepagents-cli`],
  [_용도_],
  [프로그래밍 방식으로 에이전트 구축],
  [터미널에서 직접 코딩 에이전트 사용],
  [_설치_],
  [`pip install deepagents`],
  [`uv tool install deepagents-cli`],
  [_사용 방식_],
  [Python 코드에서 `create_deep_agent()` 호출],
  [터미널에서 `deepagents-cli` 실행],
  [_커스터마이징_],
  [완전한 API 접근 (도구, 백엔드, 미들웨어)],
  [설정 파일 + 슬래시 커맨드],
  [_적합한 경우_],
  [앱에 에이전트 통합, 자동화 파이프라인],
  [대화형 코딩 어시스턴트],
)

#tip-box[이 교육 자료에서는 _SDK_를 중심으로 다룹니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. 핵심 개념 5가지

SDK와 CLI라는 두 인터페이스를 확인했으니, 이제 Deep Agents의 내부를 구성하는 다섯 가지 핵심 축을 하나씩 살펴봅니다. 이 개념들은 이후 장에서 각각 독립된 챕터로 심화되므로, 여기서는 전체적인 역할과 상호 관계를 파악하는 데 집중합니다. 이 다섯 가지 축은 서로 독립적이면서도 상호 보완적입니다. 예를 들어, 서브에이전트가 작업을 위임할 때 파일 시스템 백엔드를 통해 결과를 저장하고, 장기 메모리에서 이전 작업 패턴을 참조하는 식으로 연동됩니다.

=== 3.1 Planning (태스크 플래닝)
에이전트는 `write_todos` / `read_todos` 빌트인 도구를 사용하여 복잡한 작업을 _구조화된 태스크 리스트_로 분해합니다.
각 태스크는 `pending` → `in_progress` → `completed` 상태로 추적됩니다. 이 계획 수립 능력은 단순한 메모가 아니라, 에이전트가 멀티 스텝 작업의 진행 상황을 자기 자신에게 보고하며 다음 행동을 결정하는 _자기 관리 메커니즘_입니다. 내부적으로 `write_todos`는 `TodoListMiddleware`에 의해 에이전트 상태에 주입되며, 에이전트가 매 턴마다 현재 태스크 상태를 확인하고 다음 행동을 결정하는 _루프 기반 계획 수립_을 가능하게 합니다. 복잡한 리서치 작업에서 에이전트가 "조사 → 분석 → 보고서 작성"의 흐름을 스스로 관리하는 이유가 바로 이 메커니즘 덕분입니다.

#tip-box[`write_todos`는 에이전트의 _시스템 프롬프트_에 태스크 관리 지침이 포함되어 있어, 모델이 자연스럽게 계획을 수립합니다. 별도의 설정 없이도 기본적으로 활성화됩니다.]

=== 3.2 Context Management (컨텍스트 관리)
장기 실행 에이전트의 최대 적은 컨텍스트 윈도우 한계입니다. 수십 번의 도구 호출과 긴 응답이 누적되면 토큰 한도를 빠르게 초과하여 에이전트가 동작을 멈추게 됩니다. Deep Agents는 두 가지 자동 기법으로 이 문제를 해결합니다:
- _오프로딩_: 20,000 토큰 이상의 콘텐츠는 파일시스템 백엔드에 저장하고 포인터만 컨텍스트에 유지합니다. 원본은 언제든 다시 읽을 수 있으므로 정보 손실이 없습니다. 이 방식은 에이전트의 컨텍스트를 "작업 메모리(RAM)"처럼 관리하고, 백엔드를 "디스크 저장소"처럼 활용하는 것과 유사합니다.
- _요약_: 컨텍스트가 모델 윈도우의 약 85%에 도달하면, `SummarizationMiddleware`가 대화 이력을 구조화된 요약으로 자동 압축합니다. 요약은 단순한 텍스트 줄이기가 아니라, 핵심 결정 사항, 중간 결과, 아직 완료되지 않은 태스크를 구조적으로 보존하는 방식으로 이루어집니다.

이 두 기법이 결합되면 에이전트는 이론적으로 무제한에 가까운 장기 작업을 수행할 수 있습니다. 컨텍스트 관리는 8장에서 심화합니다.

=== 3.3 Backends (스토리지 백엔드)
에이전트의 파일 도구(`write_file`, `read_file`, `ls` 등)가 실제로 데이터를 저장하고 읽는 계층은 _플러거블 백엔드_로 추상화됩니다. 백엔드를 교체하는 것만으로 에이전트의 저장소 전략을 완전히 바꿀 수 있으며, _에이전트 코드 자체는 한 줄도 변경할 필요가 없습니다_. 이것이 백엔드 추상화의 핵심 가치입니다:
- `StateBackend` — 에이전트 상태(LangGraph state)에 파일 저장. 프로세스 종료 시 소멸하는 에페메럴 스크래치패드입니다. 기본값이며 추가 설정이 필요 없습니다. 프로토타이핑 단계에서 가장 빠르게 시작할 수 있습니다.
- `FilesystemBackend` — 로컬 디스크에 직접 접근합니다. `DATA_DIR` 환경 변수로 루트 경로를 설정할 수 있습니다. 코딩 에이전트나 데이터 분석 에이전트처럼 실제 파일을 다루는 시나리오에 적합합니다.
- `StoreBackend` — LangGraph `BaseStore`를 활용하여 크로스 스레드 영속 저장소를 제공합니다. 사용자 선호도나 학습된 패턴을 대화 세션을 넘어 유지해야 할 때 사용합니다.
- `CompositeBackend` — 경로 프리픽스에 따라 서로 다른 백엔드로 라우팅합니다(예: `/memories/`는 영속, 나머지는 에페메럴). 실전에서 가장 자주 사용되는 패턴입니다.

커스텀 백엔드가 필요하면 `BackendProtocol`을 구현하면 됩니다. 4장에서 각 백엔드를 상세히 다룹니다.

=== 3.4 Subagents (서브에이전트)
에이전트가 도구를 반복 호출하면 중간 결과가 컨텍스트 윈도우를 빠르게 채우는 _컨텍스트 블로트_ 문제가 발생합니다. 예를 들어, 10개의 파일을 순차적으로 읽고 분석하는 작업에서 각 파일의 전체 내용이 메인 에이전트의 컨텍스트에 누적되면, 정작 중요한 분석 결과를 생성할 공간이 부족해집니다.

서브에이전트는 이 문제를 근본적으로 해결합니다. 전문 서브에이전트가 _격리된 컨텍스트_에서 작업을 수행하고, 압축된 최종 결과만 메인 에이전트에 반환합니다. 이는 마치 팀장이 팀원에게 작업을 위임하고 요약 보고서만 받는 것과 같습니다. 서브에이전트는 명시적 정의(`subagents` 파라미터)와 동적 생성(`create_subagent` 도구) 두 가지 방식으로 사용할 수 있습니다. 각 서브에이전트는 독립된 컨텍스트 윈도우, 도구 세트, 시스템 프롬프트를 가지므로, 메인 에이전트의 토큰 예산에 영향을 주지 않습니다.

=== 3.5 Memory (장기 메모리)
기본 에이전트는 대화 스레드가 종료되면 모든 정보를 잊습니다. 이것은 매번 새로운 직원을 고용하는 것과 같습니다. 장기 메모리는 에이전트가 이전 대화에서 학습한 패턴, 사용자 선호도, 프로젝트 규칙 등을 _세션을 넘어_ 유지할 수 있게 합니다. 장기 메모리는 두 가지 메커니즘으로 제공됩니다:
- *`AGENTS.md`*: `memory` 파라미터로 지정하면, 에이전트 시작 시 해당 파일이 _항상_ 시스템 프롬프트에 주입됩니다. 프로젝트 컨벤션이나 사용자 선호도처럼 모든 대화에 적용되어야 하는 규칙에 적합합니다.
- *`SKILL.md`*: `skills` 파라미터로 스킬 디렉토리를 지정하면, _Progressive Disclosure_(점진적 공개)를 통해 필요한 전문 지식만 온디맨드로 로드합니다. 처음에는 프론트매터(이름, 설명)만 로드되고, 에이전트가 관련성을 판단한 스킬의 전체 내용을 그때 로드합니다.

#tip-box[`AGENTS.md`는 항상 로드되므로 간결할수록 좋습니다. 반면 `SKILL.md`는 대용량(최대 10MB)도 가능합니다. 이 차이를 활용하면 토큰 효율을 크게 개선할 수 있습니다.]

다섯 가지 핵심 개념을 이해했습니다. 이 개념들은 서로 독립적으로 사용할 수도 있지만, 실전에서는 유기적으로 결합되어 강력한 시너지를 발휘합니다. 예를 들어, 메인 에이전트가 Planning으로 작업을 분해하고, 각 태스크를 Subagent에게 위임하며, 결과를 Backend에 저장하고, Context Management로 토큰을 효율적으로 관리하고, Memory로 학습한 패턴을 재활용하는 전체 흐름이 하나의 `create_deep_agent()` 호출로 구성됩니다. 이제 이런 통합 인프라를 제공하는 Deep Agents가 다른 프레임워크와 어떤 차별점을 가지는지 비교해 봅니다.

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

프레임워크의 개념과 차별점을 확인했으니, 실제 개발 환경이 올바르게 구성되었는지 검증합니다. 아래 코드는 `deepagents` 패키지와 주요 의존성의 버전을 출력합니다. 모든 임포트가 성공하면 개발 환경이 정상적으로 설정된 것입니다.

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

설치가 확인되었으니, Deep Agents의 핵심 함수인 `create_deep_agent()`의 시그니처를 살펴봅니다. `create_deep_agent()`는 Deep Agents의 유일한 진입점이며, 반환 타입은 LangGraph의 `CompiledStateGraph`입니다. 아래에서 이 함수가 받는 전체 파라미터를 확인합니다. `model`, `tools`, `system_prompt`는 기본 구성이고, `subagents`, `backend`, `memory`, `skills`, `interrupt_on`, `middleware`, `response_format`, `context_schema`, `checkpointer` 등이 심화 파라미터입니다. 각 파라미터의 상세한 사용법은 2장(기본 사용)과 3장(커스터마이징)에서 다룹니다.

#warning-box[아래 출력에서 대부분의 파라미터 기본값이 `None`인 점에 주목하세요. 이는 Deep Agents가 "합리적 기본값(sensible defaults)" 원칙을 따르기 때문입니다. `model`만 전달해도 나머지는 자동으로 구성됩니다.]

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
  [모델 접근],
  [_OpenAI gpt-4.1_ — `ChatOpenAI(model="gpt-4.1")`],
  [핵심 개념],
  [Planning, Context Management, Backends, Subagents, Memory],
  [빌트인 도구],
  [`write_todos`, `ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`],
)

이 장에서 Deep Agents의 전체 아키텍처와 핵심 개념 다섯 가지를 조감했습니다. 다음 장에서는 `create_deep_agent()`를 직접 호출하여 첫 번째 에이전트를 생성하고, `invoke()`와 `stream()`으로 실행하는 실습을 진행합니다.

