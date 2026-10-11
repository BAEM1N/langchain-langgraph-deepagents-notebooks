// Auto-generated from 08_harness.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "에이전트 하네스")

== 학습 목표
#learning-objectives([AgentHarness의 개념과 역할을 이해한다], [하네스의 핵심 기능(계획, 파일시스템, 태스크 위임)을 안다], [컨텍스트 관리(오프로딩, 요약)를 이해한다], [코드 실행과 Human-in-the-Loop을 설정한다], [스킬과 메모리 시스템을 연동한다])

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
모델 설정 완료: gpt-4.1
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. AgentHarness 개념

_AgentHarness_는 장기 실행 자율 에이전트를 위한 _포괄적 기능 제공자_입니다.
에이전트가 복잡한 멀티 스텝 작업을 수행할 때 필요한 인프라를 하나로 묶어 제공합니다.

=== 하네스가 제공하는 핵심 기능

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[설명],
  [_Filesystem_],
  [가상/로컬 파일 읽기·쓰기·검색 (멀티모달 `read_file` 포함)],
  [_Task Delegation_],
  [서브에이전트를 통한 격리·병렬·전문화 작업 위임],
  [_Context Management_],
  [설정 가능한 임계값 기반 오프로딩 + 요약 압축],
  [_Code Execution_],
  [샌드박스 백엔드의 `execute` 셸 도구 또는 QuickJS interpreter],
  [_Human-in-the-Loop_],
  [민감 작업에 대한 사람 승인],
  [_Skills & Memory_],
  [전문 워크플로(Agent Skills 표준) + 영속적 컨텍스트(`AGENTS.md`)],
  [_Planning_],
  [필요할 때 `TodoListMiddleware`를 추가해 `write_todos` 노출],
)

`create_deep_agent()`는 파일·서브에이전트·요약·skills/memory 계층을 조립합니다. 계획 도구는 자동 전제가 아니라 수업 목적에 맞게 명시적으로 켭니다.

#code-block(`````python
from langchain.agents.middleware import TodoListMiddleware

harness_config = {
    "model": "gpt-5.4",
    "filesystem": "built-in file tools",
    "subagents": "task delegation",
    "planning": TodoListMiddleware.__name__,
}

for key, value in harness_config.items():
    print(f"{key}: {value}")
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. 계획 도구

계획이 필요한 예제에서는 LangChain의 `TodoListMiddleware`를 `middleware` 목록에 추가합니다. 그러면 에이전트가 `write_todos` 도구로 복잡한 작업을 _구조화된 태스크 리스트_로 분해할 수 있습니다.

#code-block(`````python
from langchain.agents.middleware import TodoListMiddleware

agent = create_deep_agent(
    model=model,
    middleware=[TodoListMiddleware()],
)
`````)

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

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. 가상 파일시스템

하네스는 구성 가능한 파일시스템 백엔드를 통해 표준 파일 작업을 지원합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도구],
  text(weight: "bold")[설명],
  [`ls`],
  [디렉토리 목록 (size, modified time 메타데이터 포함)],
  [`read_file`],
  [줄 번호와 offset/limit 지원, _멀티모달 반환_: 이미지(PNG/JPG/GIF/WebP/_HEIC_), 비디오(_MP4/MOV/AVI_), 오디오(_WAV/MP3/AAC/FLAC_), 문서(_PDF/PPT_)],
  [`write_file`],
  [파일 생성],
  [`edit_file`],
  [exact string replacement (옵션: global replace)],
  [`glob`],
  [패턴 기반 파일 검색 (예: `**/*.py`)],
  [`grep`],
  [내용 검색, 다양한 출력 모드],
  [`execute`],
  [셸 명령 실행 (sandbox 백엔드 전용)],
)


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

하네스는 메인 에이전트가 _임시 서브에이전트_를 생성하여 격리된 멀티 스텝 태스크를 수행할 수 있게 합니다.

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

장기 실행 에이전트의 가장 큰 과제는 _컨텍스트 윈도우 한계_입니다.
하네스는 두 가지 기법으로 이를 해결합니다.

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
  [큰 도구 결과를 디스크에 저장, 활성 메모리에 파일 포인터 + 프리뷰만 유지],
  [_configurable threshold_ (예: 20,000 토큰)],
  [_요약_],
  [대화 히스토리를 구조화 요약(session intent / artifacts / next steps)으로 압축],
  [모델 `max_input_tokens`의 ~85% 또는 `ContextOverflowError`],
)

원본 메시지는 파일시스템 스토리지에 보존되므로 정보 손실이 없습니다. 자세한 정책은 `docs/deepagents/14-context-engineering.md` 참조.


#code-block(`````python
# 컨텍스트 관리 설정 예시 (참고용) — threshold는 configurable
context_config = {
    "offloading": {
        "enabled": True,
        "threshold_tokens": 20000,  # configurable
        "storage": "filesystem",
    },
    "summarization": {
        "enabled": True,
        "trigger_ratio": 0.85,        # max_input_tokens의 85%
        "recent_message_keep": 0.10,  # 최근 10% 보존
        "fallback_trigger_tokens": 170000,
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

하네스는 _두 가지 코드 실행 경로_를 지원합니다.

=== Sandbox 백엔드 — `execute` 셸 도구
샌드박스 백엔드(Modal/Daytona/Runloop/LangSmith/AgentCore 등)를 backend로 주면 `execute` 도구가 노출됩니다. 격리된 환경에서 임의 셸 명령을 실행합니다.

=== QuickJS Interpreter — `CodeInterpreterMiddleware`
`langchain-quickjs`의 `CodeInterpreterMiddleware`를 추가하면 에이전트 루프 안에 _QuickJS 기반 코드 실행 공간_이 생깁니다. 셸/네트워크 접근 없이 결정적 도구 조합·데이터 변환에 적합합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[구분],
  text(weight: "bold")[Sandbox],
  text(weight: "bold")[Interpreter],
  [실행 위치],
  [외부 격리 런타임/컨테이너],
  [에이전트 루프 내부 QuickJS],
  [주 용도],
  [파일·패키지·셸·데이터 분석],
  [도구 조합·중간 상태·구조화 변환],
  [보안 경계],
  [provider 정책],
  [QuickJS + PTC allowlist],
  [컨텍스트 절약],
  [실행 결과만 모델로 반환],
  [변수 공간을 interpreter에 유지],
)

설치: `pip install -U "deepagents[quickjs]"`. 자세한 옵션 10가지와 PTC는 `docs/deepagents/17-interpreters.md` 참조.


#code-block(`````python
# 코드 실행 예시 (참고용)

# 1) Sandbox execute 도구
execute_examples = [
    {"command": "python -c 'print(2+2)'", "desc": "Python 코드 실행"},
    {"command": "pip install requests",      "desc": "패키지 설치"},
    {"command": "pytest tests/",              "desc": "테스트 실행"},
]

print("=== Sandbox execute 도구 예시 ===")
for ex in execute_examples:
    print(f"  $ {ex['command']}")
    print(f"    -> {ex['desc']}")

# 2) QuickJS Interpreter — CodeInterpreterMiddleware
interpreter_snippet = r'''
from deepagents import create_deep_agent
from langchain_quickjs import CodeInterpreterMiddleware

agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[CodeInterpreterMiddleware(ptc=["task"])],  # task만 PTC 노출
)
'''
print()
print("=== QuickJS Interpreter 예시 ===")
print(interpreter_snippet)

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

#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. Human-in-the-Loop

선택적 인터럽트 설정으로 지정된 도구 호출 시 사람의 승인을 요구합니다.

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

=== 스킬 (Skills)
_Agent Skills 표준_을 따르는 전문 워크플로입니다.
관련성이 있을 때 점진적으로 로드되어 토큰 소비를 줄입니다.

- 각 스킬은 `SKILL.md` 파일로 정의
- 트리거 조건에 따라 자동 활성화
- 도구, 프롬프트, 워크플로를 캡슐화

=== 메모리 (Memory)
_AGENTS.md_ 형식의 영속적 컨텍스트 파일입니다.
대화를 넘어서 재사용 가능한 가이드라인, 선호도, 프로젝트 지식을 제공합니다.

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
  [장기 실행 에이전트를 위한 기능 조립],
  [`create_deep_agent()`],
  [계획 도구],
  [opt-in 태스크 리스트 관리],
  [`TodoListMiddleware`, `write_todos`],
  [파일시스템],
  [가상/로컬 파일 작업 + 멀티모달 read_file],
  [`ls`, `read_file`, `write_file`, `edit_file`, `delete`, `glob`, `grep`, `execute`],
  [서브에이전트],
  [기본 isolated 위임, 실험적 fork 문맥 상속],
  [`subagents`, `task`, `mode="fork"`],
  [컨텍스트 관리],
  [configurable threshold 오프로딩 + 요약],
  [middleware stack],
  [코드 실행],
  [Sandbox `execute` + QuickJS `CodeInterpreterMiddleware`],
  [`execute`, `eval`],
  [HITL],
  [approve/edit/reject/respond 재개],
  [`interrupt_on`, `Command(resume=...)`],
  [스킬/메모리],
  [전문 워크플로 + 영속적 컨텍스트],
  [`SKILL.md`, `metadata.include_tools`, `pinned_skills`, `AGENTS.md`],
)

=== Profiles 보강

Profile은 provider/model별 도구 설명, 제외 도구, 추가 middleware, 프롬프트 suffix를 묶습니다. Profile이 조정하는 것은 실행 환경이고, Rubric은 결과물이 충족해야 할 완료 기준입니다.

#references-box[
- #link("../docs/deepagents/05-harness.md")[Deep Agents Harness]
- #link("../docs/deepagents/17-interpreters.md")[Interpreters]
- #link("../docs/deepagents/18-profiles.md")[Profiles]
- #link("../docs/deepagents/14-context-engineering.md")[Context Engineering]
]
#chapter-end()
