// Auto-generated from 08_harness.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "에이전트 하네스")

`AgentHarness`는 Deep Agents의 핵심 설계 철학을 구현한 포괄적 기능 제공자로, 장기 실행 자율 에이전트에 필요한 계획, 파일시스템, 태스크 위임, 컨텍스트 관리, 코드 실행, Human-in-the-Loop을 하나로 통합한다. 이 장에서는 `create_deep_agent()`가 내부적으로 이 모든 기능을 어떻게 조립하는지 분해하여 살펴보고, 각 구성 요소의 역할과 설정 방법을 정리한다.

이전 장들에서 개별적으로 다룬 기능들(2장의 에이전트 생성, 3장의 커스터마이징, 4장의 백엔드, 5장의 서브에이전트, 6장의 메모리/스킬, 7장의 고급 기능)이 내부적으로 어떻게 하나의 에이전트로 조립되는지를 이해하면, Deep Agents의 설계 원칙을 깊이 있게 파악할 수 있다. `create_deep_agent()`는 사실 `AgentHarness`를 간편하게 사용하기 위한 편의 래퍼(convenience wrapper)다.

하네스라는 이름은 말(馬)의 마구(harness)에서 유래한 비유다. 마구가 고삐, 안장, 등자 등 여러 부품을 하나로 결합하여 기수에게 통일된 인터페이스를 제공하듯, `AgentHarness`는 모델, 도구, 미들웨어, 상태 관리라는 개별 부품을 결합하여 개발자에게 하나의 일관된 에이전트 인터페이스를 제공한다. 이 장을 마치면, 하네스가 내부적으로 수행하는 _수집 → 빌드 → 적용 → 컴파일_ 파이프라인의 전체 흐름을 이해할 수 있다.

#learning-header()
#learning-objectives([AgentHarness의 개념과 역할을 이해한다], [하네스의 핵심 기능(계획, 파일시스템, 태스크 위임)을 안다], [컨텍스트 관리(오프로딩, 요약)를 이해한다], [코드 실행과 Human-in-the-Loop을 설정한다], [스킬과 메모리 시스템을 연동한다])

먼저 환경 변수를 로드하고 모델을 초기화한다. 이후 각 섹션에서 하네스의 구성 요소를 하나씩 분해하여 살펴본다.

#code-block(`````python
# 환경 설정
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY가 설정되지 않았습니다!"
print("환경 설정 완료")
`````)
#output-block(`````
환경 설정 완료
`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4")

print(f"모델 설정 완료: {model.model_name}")
`````)
#output-block(`````
모델 설정 완료: gpt-5.4
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. AgentHarness 개념

_AgentHarness_는 장기 실행 자율 에이전트를 위한 _포괄적 기능 제공자_입니다.
에이전트가 복잡한 멀티 스텝 작업을 수행할 때 필요한 모든 인프라를 하나로 묶어 제공합니다. 내부적으로 하네스는 다음 단계를 순서대로 수행합니다:

+ 모델, 도구, 미들웨어, 상태 스키마를 _수집_합니다.
+ 수집된 구성 요소로 `StateGraph`를 _빌드_합니다.
+ 미들웨어 파이프라인을 _적용_합니다.
+ 최종적으로 그래프를 _컴파일_하여 `CompiledStateGraph`를 반환합니다.

=== 하네스가 제공하는 핵심 기능

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[설명],
  [_Planning_],
  [구조화된 태스크 리스트 관리 (`write_todos`)],
  [_Filesystem_],
  [가상/로컬 파일 읽기, 쓰기, 검색],
  [_Task Delegation_],
  [서브에이전트를 통한 작업 위임],
  [_Context Management_],
  [오프로딩 및 요약을 통한 컨텍스트 압축],
  [_Code Execution_],
  [샌드박스 환경에서 안전한 코드 실행],
  [_Human-in-the-Loop_],
  [민감 작업에 대한 사람 승인],
  [_Skills & Memory_],
  [전문 워크플로와 영속적 지식],
)

`create_deep_agent()`를 호출하면 이 모든 기능이 자동으로 조립되어 하나의 에이전트로 제공됩니다. 개발자는 각 기능을 개별적으로 설정할 필요 없이, `create_deep_agent()`의 파라미터만으로 원하는 조합을 선언적으로 지정할 수 있습니다.

하네스 내부의 동작 순서를 요약하면 다음과 같습니다:

+ *수집(Collect)* — 모델, 커스텀 도구, 미들웨어, 상태 스키마를 파라미터로부터 수집합니다.
+ *빌드(Build)* — 수집된 구성 요소를 LangGraph의 `StateGraph`로 조립합니다. 이 단계에서 노드(에이전트 로직)와 엣지(도구 호출 라우팅)가 정의됩니다.
+ *적용(Apply)* — `TodoListMiddleware`, `SummarizationMiddleware` 등 미들웨어 파이프라인을 그래프에 적용합니다.
+ *컴파일(Compile)* — 최종적으로 `CompiledStateGraph`를 생성하여 실행 가능한 에이전트를 반환합니다.

이 4단계 파이프라인 덕분에, 개발자는 _무엇을 사용할지_만 선언하고 _어떻게 조립할지_는 하네스에 위임할 수 있습니다.

#tip-box[`create_deep_agent()`는 `AgentHarness`의 편의 래퍼입니다. 대부분의 경우 이 래퍼만으로 충분하며, 하네스를 직접 다룰 필요는 없습니다. 하지만 내부 구조를 이해하면 문제 해결과 고급 커스터마이징에 큰 도움이 됩니다.]

#warning-box[하네스의 조립 순서는 중요합니다. 미들웨어는 반드시 `StateGraph` 빌드 _이후_에 적용되어야 하며, 미들웨어 간에도 의존 관계가 있을 수 있습니다. 예를 들어 `SummarizationMiddleware`는 파일시스템 백엔드가 설정된 후에야 오프로딩된 콘텐츠를 저장할 수 있습니다.]

다음 코드는 `create_deep_agent()`에 전달되는 하네스 구성 요소를 파이썬 딕셔너리로 정리한 것입니다. 각 키가 하네스의 어떤 기능을 활성화하는지 확인하세요.

#code-block(`````python
# AgentHarness 개념 — create_deep_agent가 하네스를 조립합니다
harness_config = {
    "model": "openai:gpt-5.4",
    "system_prompt": "당신은 프로젝트 관리 어시스턴트입니다.",
    "planning": True,         # write_todos 도구 활성화
    "filesystem": True,       # 파일시스템 도구 활성화
    "subagents": [],          # 서브에이전트 목록
    "context_management": True,  # 컨텍스트 압축 활성화
}

print("AgentHarness 구성 요소:")
for key, value in harness_config.items():
    print(f"  {key}: {value}")
`````)
#output-block(`````
AgentHarness 구성 요소:
  model: openai:gpt-5.4
  system_prompt: 당신은 프로젝트 관리 어시스턴트입니다.
  planning: True
  filesystem: True
  subagents: []
  context_management: True
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. 계획 도구

하네스의 구성 요소를 이해했으니, 이제 각 기능을 하나씩 상세히 살펴보겠습니다. 첫 번째는 태스크 계획입니다.

하네스의 첫 번째 구성 요소는 태스크 계획입니다. `TodoListMiddleware`가 자동으로 추가하는 `write_todos` 도구를 통해, 에이전트는 복잡한 작업을 _구조화된 태스크 리스트_로 분해합니다. `read_todos` 도구로 현재 진행 상황을 확인할 수도 있습니다.

태스크 계획은 단순한 편의 기능이 아닙니다. 장기 실행 에이전트가 수십 단계의 작업을 수행할 때, 현재 진행 상황을 추적하지 않으면 동일한 작업을 반복하거나 중요한 단계를 건너뛸 수 있습니다. `write_todos`는 에이전트에게 _구조화된 자기 관리 능력_을 부여합니다. 또한 요약(Summarization) 단계에서도 태스크 리스트가 컨텍스트 복원의 기준점 역할을 합니다.

각 태스크는 상태를 가집니다:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[상태],
  text(weight: "bold")[설명],
  [`pending`],
  [아직 시작하지 않음],
  [`in_progress`],
  [현재 진행 중],
  [`completed`],
  [완료됨],
)

아래 예시는 에이전트가 생성할 수 있는 태스크 리스트의 형태를 보여줍니다. 실제 실행에서는 에이전트가 자율적으로 `write_todos`를 호출하여 태스크를 생성하고, 각 태스크를 완료할 때마다 상태를 업데이트합니다.

#code-block(`````python
# write_todos 도구 — 구조화된 태스크 리스트 예시
todo_list = [
    {"task": "프로젝트 구조 분석", "status": "completed"},
    {"task": "API 엔드포인트 설계", "status": "in_progress"},
    {"task": "데이터베이스 스키마 작성", "status": "pending"},
    {"task": "테스트 코드 작성", "status": "pending"},
    {"task": "문서화", "status": "pending"},
]

print("=== 에이전트 태스크 리스트 ===")
for i, item in enumerate(todo_list, 1):
    icon = {"completed": "[x]", "in_progress": "[-]", "pending": "[ ]"}
    print(f"  {icon[item['status']]} {i}. {item['task']}")
`````)
#output-block(`````
=== 에이전트 태스크 리스트 ===
  [x] 1. 프로젝트 구조 분석
  [-] 2. API 엔드포인트 설계
  [ ] 3. 데이터베이스 스키마 작성
  [ ] 4. 테스트 코드 작성
  [ ] 5. 문서화
`````)

#tip-box[에이전트가 태스크 리스트를 효과적으로 활용하도록 하려면, 시스템 프롬프트에 "복잡한 작업을 시작할 때 먼저 `write_todos`로 계획을 세우세요"와 같은 지침을 포함하는 것이 좋습니다. 계획 수립 없이 바로 실행에 들어가면 장기 작업에서 일관성이 떨어질 수 있습니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. 가상 파일시스템

계획이 에이전트의 _사고 구조_라면, 파일시스템은 에이전트의 _작업 공간_입니다. 이제 에이전트가 파일을 읽고, 쓰고, 검색하는 방법을 살펴봅니다.

하네스는 구성 가능한 파일시스템 백엔드를 통해 표준 파일 작업을 지원합니다. 여기서 핵심 설계 원칙은 _플러거블 백엔드_입니다. 4장에서 학습한 `BackendProtocol`을 구현하는 어떤 백엔드든(로컬 파일시스템, 인메모리, 샌드박스) 동일한 도구 인터페이스로 접근할 수 있습니다. 에이전트의 코드를 변경하지 않고도, `backend` 파라미터만 교체하면 로컬 개발에서 샌드박스 프로덕션으로 전환할 수 있습니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도구],
  text(weight: "bold")[설명],
  [`ls`],
  [디렉토리 목록 (메타데이터 포함)],
  [`read_file`],
  [파일 내용 읽기 (줄 번호 포함, 멀티모달 — 이미지 PNG/JPG/GIF/WebP/HEIC, 비디오 MP4/MOV/AVI, 오디오 WAV/MP3/AAC/FLAC, 문서 PDF/PPT)],
  [`write_file`],
  [파일 생성],
  [`edit_file`],
  [문자열 치환 편집],
  [`glob`],
  [패턴 기반 파일 검색],
  [`grep`],
  [내용 검색 (여러 출력 모드)],
  [`execute`],
  [쉘 명령 실행 (샌드박스 백엔드 전용)],
)

`read_file`은 이미지 파일(PNG, JPG, GIF, WEBP)도 지원하므로, 에이전트가 스크린샷이나 차트를 분석하는 작업에도 활용할 수 있습니다. `execute`는 샌드박스 백엔드에서만 노출되며, 10장에서 자세히 다룹니다. 다음 코드는 각 파일시스템 도구의 호출 형태를 정리합니다.

#code-block(`````python
# 파일시스템 도구 사용 예시 (참고용)
fs_operations = {
    "ls": 'ls(path="/project/src")',
    "read_file": 'read_file(path="/project/src/main.py")',
    "write_file": 'write_file(path="/project/config.yaml", content="debug: true")',
    "edit_file": 'edit_file(path="/project/src/main.py", old="v1", new="v2")',
    "glob": 'glob(pattern="**/*.py")',
    "grep": 'grep(pattern="TODO", path="/project/src")',
}

print("=== 파일시스템 도구 호출 예시 ===")
for tool_name, call_example in fs_operations.items():
    print(f"  {tool_name:12s} -> {call_example}")
`````)
#output-block(`````
=== 파일시스템 도구 호출 예시 ===
  ls           -> ls(path="/project/src")
  read_file    -> read_file(path="/project/src/main.py")
  write_file   -> write_file(path="/project/config.yaml", content="debug: true")
  edit_file    -> edit_file(path="/project/src/main.py", old="v1", new="v2")
  glob         -> glob(pattern="**/*.py")
  grep         -> grep(pattern="TODO", path="/project/src")
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. 태스크 위임 — 서브에이전트

파일시스템으로 에이전트의 작업 공간을 확보했으니, 이제 에이전트가 작업을 _분업_하는 방법을 살펴봅니다.

하네스는 메인 에이전트가 _임시 서브에이전트(ephemeral subagent)_를 생성하여 격리된 멀티 스텝 태스크를 수행할 수 있게 합니다. 서브에이전트는 메인 에이전트의 컨텍스트와 완전히 분리된 독립적인 에이전트로, 자신만의 시스템 프롬프트, 도구 세트, 컨텍스트를 가집니다. 작업이 완료되면 결과만 압축하여 메인 에이전트에 반환하므로, 메인 에이전트의 컨텍스트 윈도우를 효율적으로 보존합니다.

=== 서브에이전트의 장점

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[장점],
  text(weight: "bold")[설명],
  [_컨텍스트 격리_],
  [서브에이전트 실행이 메인 컨텍스트를 오염시키지 않음],
  [_병렬 실행_],
  [여러 서브에이전트를 동시에 실행 가능],
  [_전문화_],
  [각 서브에이전트에 특화된 도구와 프롬프트 제공],
  [_토큰 효율_],
  [결과 압축으로 메인 에이전트의 토큰 절약],
)

#note-box[서브에이전트를 과도하게 사용하면 오버헤드가 증가합니다. 단순한 단일 도구 호출(예: 파일 하나 읽기)은 서브에이전트 없이 메인 에이전트가 직접 수행하는 것이 효율적입니다. 서브에이전트는 _여러 단계의 조사나 코드 작성_처럼 자체적인 계획과 반복이 필요한 작업에 사용하세요.]

다음 예시는 조사 담당(researcher)과 코드 작성 담당(coder) 두 서브에이전트를 구성하는 방법을 보여줍니다. 각 서브에이전트에 특화된 도구와 프롬프트를 부여하는 점에 주목하세요.

#code-block(`````python
# 서브에이전트 위임 구성 예시 (참고용)
subagent_config = [
    {
        "name": "researcher",
        "description": "인터넷 검색으로 정보를 조사합니다.",
        "system_prompt": "검색 결과를 간결하게 요약하세요.",
        "tools": ["internet_search"],
    },
    {
        "name": "coder",
        "description": "코드를 작성하고 테스트합니다.",
        "system_prompt": "깔끔하고 테스트 가능한 코드를 작성하세요.",
        "tools": ["write_file", "execute"],
    },
]

print("=== 서브에이전트 구성 ===")
for sa in subagent_config:
    print(f"  [{sa['name']}] {sa['description']}")
    print(f"    도구: {', '.join(sa['tools'])}")
`````)
#output-block(`````
=== 서브에이전트 구성 ===
  [researcher] 인터넷 검색으로 정보를 조사합니다.
    도구: internet_search
  [coder] 코드를 작성하고 테스트합니다.
    도구: write_file, execute
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. 컨텍스트 관리

계획, 파일시스템, 서브에이전트까지 갖추면 에이전트는 매우 강력해지지만, 동시에 새로운 문제가 등장합니다. 바로 _컨텍스트 폭발_입니다.

계획, 파일시스템, 서브에이전트가 모두 동작하면서 에이전트의 컨텍스트는 빠르게 채워집니다. 장기 실행 에이전트의 가장 큰 과제인 _컨텍스트 윈도우 한계_를 하네스는 두 가지 자동 기법으로 해결합니다. 개발자가 별도로 설정할 필요 없이, `SummarizationMiddleware`가 이를 자동으로 관리합니다. 이 미들웨어가 없다면, 장기 실행 에이전트는 컨텍스트 윈도우를 초과하여 오류가 발생하거나, 초기 지시사항을 잊어버리는 문제가 발생합니다.

=== 입력 컨텍스트 조립
시스템 프롬프트, 지침, 메모리 가이드라인, 스킬 정보, 파일시스템 문서를 종합하여 초기 프롬프트를 구성합니다.

=== 런타임 컨텍스트 압축

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기법],
  text(weight: "bold")[동작],
  text(weight: "bold")[트리거],
  [_오프로딩_],
  [configurable threshold (기본 20,000 토큰) 초과 콘텐츠를 디스크에 저장, 포인터 참조 유지],
  [콘텐츠 크기 기준],
  [_요약_],
  [대화 히스토리를 구조화된 요약(session intent / artifacts / next steps)으로 압축. 모델 `max_input_tokens`의 약 _85%_ 도달 시 트리거하며, 최근 _10%_ 메시지는 그대로 보존. `max_input_tokens` 미설정 시 170k 토큰 fallback],
  [모델 윈도우 한계 접근 시],
)

원본 메시지는 파일시스템 스토리지에 보존되므로 정보 손실이 없습니다. 에이전트가 요약된 정보에서 원본을 다시 참조해야 할 경우, `read_file` 도구로 접근할 수 있습니다. 이는 _손실 없는 압축_이라는 하네스의 핵심 설계 원칙을 보여줍니다.

#note-box[오프로딩의 20,000 토큰 임계값과 요약의 85% 윈도우 트리거는 합리적인 기본값이지만, 모델과 작업 특성에 따라 조정이 필요할 수 있습니다. 예를 들어, 대용량 코드 분석 작업에서는 오프로딩 임계값을 낮추고, 간단한 대화형 작업에서는 높여도 됩니다.]

#warning-box[요약 과정에서 에이전트의 초기 시스템 프롬프트와 핵심 지시사항은 항상 보존됩니다. 그러나 대화 중간에 사용자가 추가한 임시 지시사항은 요약 시 압축될 수 있습니다. 중요한 지시사항은 시스템 프롬프트에 포함하거나 `AGENTS.md` 메모리에 기록하세요.]

다음 코드는 오프로딩과 요약의 설정 옵션을 정리한 것입니다. 실제로는 하네스가 이 설정을 자동으로 관리하지만, 미세 조정이 필요한 경우 참고할 수 있습니다.

#code-block(`````python
# 컨텍스트 관리 설정 예시 (참고용)
context_config = {
    "offloading": {
        "enabled": True,
        "threshold_tokens": 20000,
        "storage": "filesystem",
    },
    "summarization": {
        "enabled": True,
        "trigger": "window_limit_approach",
        "preserve_original": True,
    },
}

print("=== 컨텍스트 관리 설정 ===")
for section, settings in context_config.items():
    print(f"\n[{section}]")
    for key, value in settings.items():
        print(f"  {key}: {value}")
`````)
#output-block(`````
=== 컨텍스트 관리 설정 ===

[offloading]
  enabled: True
  threshold_tokens: 20000
  storage: filesystem

[summarization]
  enabled: True
  trigger: window_limit_approach
  preserve_original: True
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. 코드 실행

컨텍스트 관리로 에이전트의 장기 실행을 보장했으니, 이제 에이전트가 실제로 코드를 _실행_하는 방법을 살펴봅니다.

샌드박스 백엔드는 `execute` 도구를 노출하여 격리된 환경에서 명령을 실행합니다. 호스트 시스템에 영향을 주지 않으면서 보안성, 깨끗한 환경, 재현성을 제공합니다. `execute` 도구는 샌드박스 백엔드(Modal, Daytona, Runloop 등)가 설정된 경우에만 사용할 수 있습니다. 로컬 파일시스템 백엔드에서는 보안상 이 도구가 노출되지 않습니다.

코드 실행은 에이전트가 작성한 코드를 검증하거나, 패키지를 설치하거나, 테스트를 수행할 때 사용됩니다. 다음은 `execute` 도구로 수행할 수 있는 대표적인 작업입니다.

#code-block(`````python
# 샌드박스 코드 실행 예시 (참고용)
execute_examples = [
    {"command": "python -c 'print(2+2)'", "desc": "Python 코드 실행"},
    {"command": "pip install requests", "desc": "패키지 설치"},
    {"command": "pytest tests/", "desc": "테스트 실행"},
]

print("=== 샌드박스 execute 도구 예시 ===")
for ex in execute_examples:
    print(f"  $ {ex['command']}")
    print(f"    -> {ex['desc']}")
`````)
#output-block(`````
=== 샌드박스 execute 도구 예시 ===
  $ python -c 'print(2+2)'
    -> Python 코드 실행
  $ pip install requests
    -> 패키지 설치
  $ pytest tests/
    -> 테스트 실행
`````)

#tip-box[코드 실행의 보안과 샌드박스 프로바이더 선택에 대한 심화 내용은 10장 "샌드박스와 ACP"에서 다룹니다. 이 장에서는 하네스 관점에서 `execute` 도구의 역할만 이해하면 충분합니다.]

=== 두 갈래 실행: Sandbox `execute` vs QuickJS `CodeInterpreterMiddleware`

하네스는 코드 실행을 두 갈래로 노출한다. 하나는 _샌드박스 백엔드_가 노출하는 셸 `execute` 도구, 다른 하나는 _interpreter 미들웨어_가 노출하는 QuickJS eval 도구다. 둘은 서로 다른 문제를 푼다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[Sandbox `execute` (셸)],
  text(weight: "bold")[QuickJS `CodeInterpreterMiddleware`],
  [실행 위치],
  [에이전트 외부의 격리 환경 (Modal/Daytona/Runloop 등)],
  [에이전트 루프 내부의 QuickJS VM],
  [언어],
  [셸 명령 → 임의 언어 (Python, Node, …)],
  [JavaScript (QuickJS)],
  [네트워크/파일시스템],
  [기본 활성 (정책으로 제어)],
  [기본 비활성 — bridge로 노출된 도구만],
  [패키지 설치],
  [`pip install`/`npm install` 가능],
  [불가능],
  [적합한 용도],
  [패키지 설치·테스트 실행·대용량 데이터 처리],
  [도구 호출 조합·서브에이전트 fan-out·구조화 데이터 변환],
  [활성화],
  [`backend=ModalSandbox(...)` 등 백엔드 교체],
  [`middleware=[CodeInterpreterMiddleware(...)]` 추가],
)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. Human-in-the-Loop

자율 에이전트가 파일을 수정하고 코드를 실행할 수 있다면, _안전 장치_가 필수입니다. Human-in-the-Loop(HITL)은 에이전트의 자율성과 안전성 사이의 균형을 제공합니다.

선택적 인터럽트 설정으로 지정된 도구 호출 시 사람의 승인을 요구합니다. 에이전트가 해당 도구를 호출하면 실행이 일시 중단되고, 사용자가 승인(approve), 거부(reject), 또는 수정(edit)을 선택할 수 있습니다. 이 기능은 LangGraph의 `interrupt` 메커니즘 위에 구현되므로, 중단된 시점의 상태가 완전히 보존됩니다.

다음 코드는 파일 쓰기, 편집, 코드 실행에 대해 승인을 요구하도록 설정하는 예시입니다.

#code-block(`````python
# Human-in-the-Loop 설정 예시 (참고용)
hitl_config = {
    "interrupt_on": {
        "write_file": True,   # 파일 쓰기 전 승인
        "edit_file": True,    # 파일 편집 전 승인
        "execute": True,      # 명령 실행 전 승인
    }
}

print("=== Human-in-the-Loop 설정 ===")
print("승인이 필요한 도구:")
for tool, enabled in hitl_config["interrupt_on"].items():
    status = "승인 필요" if enabled else "자동 실행"
    print(f"  {tool}: {status}")

print("\n승인 옵션: approve(승인), reject(거부), edit(수정)")
`````)
#output-block(`````
=== Human-in-the-Loop 설정 ===
승인이 필요한 도구:
  write_file: 승인 필요
  edit_file: 승인 필요
  execute: 승인 필요

승인 옵션: approve(승인), reject(거부), edit(수정)
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 8. 스킬과 메모리

지금까지 살펴본 기능들(계획, 파일시스템, 서브에이전트, 컨텍스트 관리, 코드 실행, HITL)이 에이전트의 _런타임 능력_이라면, 스킬과 메모리는 에이전트의 _축적된 지식_입니다. 이 두 시스템은 에이전트가 대화를 넘어서 전문성과 경험을 유지하게 합니다.

=== 스킬 (Skills)
_Agent Skills 표준_을 따르는 전문 워크플로입니다.
관련성이 있을 때 점진적으로 로드되어 토큰 소비를 줄입니다. 모든 스킬을 항상 로드하면 컨텍스트를 낭비하므로, 하네스는 사용자의 요청과 스킬의 트리거 조건을 매칭하여 필요한 스킬만 활성화합니다.

- 각 스킬은 `SKILL.md` 파일로 정의
- 트리거 조건에 따라 자동 활성화
- 도구, 프롬프트, 워크플로를 캡슐화

=== 메모리 (Memory)
_AGENTS.md_ 형식의 영속적 컨텍스트 파일입니다.
대화를 넘어서 재사용 가능한 가이드라인, 선호도, 프로젝트 지식을 제공합니다. 메모리는 글로벌 범위와 프로젝트 범위 두 가지로 구분되며, 에이전트가 새 대화를 시작할 때 자동으로 로드됩니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[구분],
  text(weight: "bold")[위치],
  text(weight: "bold")[범위],
  [글로벌 메모리],
  [`~/.deepagents/\<agent\>/memories/`],
  [모든 프로젝트],
  [프로젝트 메모리],
  [`.deepagents/AGENTS.md`],
  [현재 프로젝트],
)

#note-box[스킬과 메모리는 서로 다른 목적을 가집니다. _스킬_은 특정 작업을 수행하기 위한 도구와 워크플로의 묶음(how to do)이고, _메모리_는 프로젝트의 규칙과 맥락 정보(what to know)입니다. 예를 들어, "코드 리뷰" 스킬은 리뷰 절차를 정의하고, `AGENTS.md` 메모리는 "이 프로젝트는 TypeScript를 사용하고, 테스트 커버리지 80% 이상을 유지한다"와 같은 규칙을 저장합니다.]

다음 코드는 스킬과 메모리의 설정 구조를 보여줍니다.

#code-block(`````python
# 스킬과 메모리 설정 예시 (참고용)
skills_config = [
    {"name": "code-review", "trigger": "코드 리뷰 요청 시"},
    {"name": "test-writer", "trigger": "테스트 작성 요청 시"},
    {"name": "doc-generator", "trigger": "문서화 요청 시"},
]

memory_config = {
    "global": "~/.deepagents/my-agent/memories/",
    "project": ".deepagents/AGENTS.md",
}

print("=== 스킬 설정 ===")
for skill in skills_config:
    print(f"  [{skill['name']}] 트리거: {skill['trigger']}")

print("\n=== 메모리 설정 ===")
for scope, path in memory_config.items():
    print(f"  {scope}: {path}")
`````)
#output-block(`````
=== 스킬 설정 ===
  [code-review] 트리거: 코드 리뷰 요청 시
  [test-writer] 트리거: 테스트 작성 요청 시
  [doc-generator] 트리거: 문서화 요청 시

=== 메모리 설정 ===
  global: ~/.deepagents/my-agent/memories/
  project: .deepagents/AGENTS.md
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 9. Harness Profiles

`HarnessProfile`은 `create_deep_agent()` 호출부를 바꾸지 않고도 provider/model별 harness 기본값을 패키징한다. 시스템 프롬프트, 도구 설명 override, 제외할 도구/미들웨어, 일반 목적 서브에이전트 설정, 추가 미들웨어를 profile로 등록할 수 있다.

=== `HarnessProfile` 7필드

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[필드],
  text(weight: "bold")[의미],
  [`base_system_prompt`],
  [베이스 system prompt 자체를 교체],
  [`system_prompt_suffix`],
  [조립된 베이스 prompt 끝에 텍스트 추가],
  [`tool_description_overrides`],
  [도구 이름별 설명 override (mapping)],
  [`excluded_tools`],
  [주입 이후 이름으로 제거할 도구 집합 (set)],
  [`excluded_middleware`],
  [제거할 middleware 클래스 집합 (set)],
  [`extra_middleware`],
  [추가로 붙일 middleware 인스턴스 리스트],
  [`general_purpose_subagent`],
  [`GeneralPurposeSubagentProfile`로 일반 목적 서브에이전트 활성·비활성·커스터마이즈],
)

=== Merge semantics

여러 profile이 매칭될 때의 병합 규칙은 다음과 같다.

- 후행 profile이 선행 profile의 _scalar 필드_(예: `base_system_prompt`)를 덮어쓴다.
- `tool_description_overrides` 같은 _mapping류_는 키 단위로 merge.
- `excluded_tools`/`excluded_middleware` 같은 _set류_는 합집합.

=== `ProviderProfile` 3필드

`ProviderProfile`은 harness 동작이 아니라 `init_chat_model()`에 넘길 초기화 인자를 다룬다. credential check, provider별 기본 temperature, runtime header 구성처럼 모델 생성 전후 기본값을 묶을 때 사용한다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[필드],
  text(weight: "bold")[의미],
  [`init_kwargs`],
  [`init_chat_model()` 호출 시 전달할 기본 kwargs (예: `temperature`)],
  [`credentials_check`],
  [모델 초기화 전에 실행하는 자격 증명 확인 callable],
  [`runtime_headers`],
  [요청마다 첨부할 HTTP 헤더 매핑],
)

=== YAML/JSON 워크플로 — `HarnessProfileConfig.from_dict`

`HarnessProfileConfig`는 `from_dict()`, `to_dict()`, `from_harness_profile()` 클래스 메서드를 제공한다. YAML로 profile을 관리해 코드를 건드리지 않고 운영 환경별로 다른 설정을 적용할 수 있다.

#code-block(`````yaml
# profile.yaml
base_system_prompt: You are helpful.
system_prompt_suffix: Respond briefly.
excluded_tools:
  - execute
excluded_middleware:
  - SummarizationMiddleware
general_purpose_subagent:
  enabled: false
`````)

#code-block(`````python
import yaml
from deepagents import HarnessProfileConfig, register_harness_profile

with open("profile.yaml") as f:
    register_harness_profile(
        "openai:gpt-5.4",
        HarnessProfileConfig.from_dict(yaml.safe_load(f)),
    )
`````)

=== Entry-point 플러그인

`pyproject.toml`의 entry-point로 profile을 패키지처럼 배포할 수 있다. 로드 순서는 _built-ins → entry-point plugins → 사용자 코드의 직접 `register_*_profile` 호출_ 순이다.

#code-block(`````toml
[project.entry-points."deepagents.harness_profiles"]
"anthropic:claude-sonnet-4-6" = "my_pkg.profiles:claude_profile"

[project.entry-points."deepagents.provider_profiles"]
"openai" = "my_pkg.profiles:openai_provider"
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
#chapter-summary-header()

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[주제],
  text(weight: "bold")[핵심 개념],
  text(weight: "bold")[핵심 API/도구],
  [하네스 개념],
  [장기 실행 에이전트를 위한 포괄적 기능 제공자],
  [`create_deep_agent()`],
  [계획 도구],
  [구조화된 태스크 리스트 관리],
  [`write_todos`],
  [파일시스템],
  [가상/로컬 파일 작업 (7종 도구)],
  [`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`, `execute`],
  [서브에이전트],
  [격리된 태스크 위임, 병렬 실행],
  [`subagents`, `task`],
  [컨텍스트 관리],
  [오프로딩(20K 토큰), 요약 압축],
  [자동 관리],
  [코드 실행],
  [샌드박스에서 안전한 명령 실행],
  [`execute`],
  [HITL],
  [민감 도구 호출 시 사람 승인],
  [`interrupt_on`],
  [스킬/메모리],
  [전문 워크플로 + 영속적 컨텍스트],
  [`SKILL.md`, `AGENTS.md`],
)


#references-box[
- #link("../docs/deepagents/05-harness.md")[Deep Agents Harness]
]
#chapter-end()
