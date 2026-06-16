// Auto-generated from 06_memory_and_skills.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "장기 메모리 & 스킬")

== 학습 목표
#learning-objectives([`CompositeBackend` + `StoreBackend`로 장기 메모리를 구현한다], [크로스 스레드 메모리 공유 패턴을 이해한다], [`AGENTS.md`로 에이전트에 컨텍스트를 주입한다], [스킬(SKILL.md)의 구조와 Progressive Disclosure를 이해한다], [Skills vs Memory의 차이를 파악한다])

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
# OpenAI gpt-5.4 모델 설정 (Deep Agents 기본은 anthropic:claude-sonnet-4-6)
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4")
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. 장기 메모리가 필요한 이유

기본 `StateBackend` 에이전트는 _대화 스레드가 끝나면 모든 정보를 잊습니다_.
실제 어시스턴트라면 아래 정보를 _대화 간에 유지_해야 합니다:

- 사용자 선호도 (코딩 스타일, 사용 언어)
- 프로젝트 컨벤션 (아키텍처 결정, 네이밍 규칙)
- 이전 대화에서 받은 피드백
- 자주 참조하는 정보 (API 문서, 설정값)

=== 정보 유형 분류 (deepagents 0.5+)

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[유형],
  text(weight: "bold")[의미],
  text(weight: "bold")[저장 예],
  text(weight: "bold")[메커니즘],
  [_Episodic_],
  [과거 경험 — 대화 세션, 문제 해결 궤적],
  [지난 스레드 히스토리],
  [Checkpointer (thread 단위)],
  [_Procedural_],
  [재사용 가능한 절차·스킬·워크플로],
  [`SKILL.md`],
  [Skills (on-demand)],
  [_Semantic_],
  [사실·선호·정책],
  [`AGENTS.md`, `/memories/*.txt`],
  [StoreBackend (always-on 파일)],
)

세 유형을 하나의 백엔드로 몰아넣지 말고 성격에 맞는 메커니즘에 분산시키는 것이 기본 원칙입니다.

=== 해결 방식: CompositeBackend

#image("../../assets/images/composite_backend.png")

`/memories/` 경로에 저장된 파일은 _어떤 대화 스레드에서든_ 접근할 수 있습니다.

#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import StateBackend, StoreBackend, CompositeBackend, FilesystemBackend
from langgraph.store.memory import InMemoryStore
from langgraph.checkpoint.memory import MemorySaver

# 프로덕션에서는 PostgresStore 사용:
# from langgraph.store.postgres import PostgresStore

# 1. 스토어와 체크포인터 생성
store = InMemoryStore()          # 개발용
checkpointer = MemorySaver()     # 에이전트 상태 유지


# 2. CompositeBackend — 사전 생성 인스턴스 (deepagents>=0.5.2)
#    /memories/만 영속, 나머지는 에페메럴
#    namespace 콜러블은 LangGraph Runtime 객체를 받음
memory_backend = CompositeBackend(
    default=StateBackend(),
    routes={
        "/memories/": StoreBackend(
            namespace=lambda rt: ("demo-user",),  # 운영: rt.context.user_id
        ),
    },
)


# 3. 에이전트 생성
memory_agent = create_deep_agent(
    model=model,
    system_prompt="""당신은 개인 어시스턴트입니다.
사용자가 기억해 달라고 하는 정보는 /memories/ 폴더에 저장하세요.
이전에 저장한 메모리가 있으면 참고하여 응답하세요.
한국어로 응답하세요.""",
    backend=memory_backend,
    store=store,
    checkpointer=checkpointer,
)

print("장기 메모리 에이전트 생성 완료")
`````)
#output-block(`````
장기 메모리 에이전트 생성 완료
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. 크로스 스레드 메모리 공유

`StoreBackend`에 저장된 데이터는 _스레드 간에 공유_됩니다.
아래 예제에서 스레드 1에서 저장한 선호도를 스레드 2에서 읽어봅니다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. AGENTS.md를 통한 컨텍스트 주입

`memory` 파라미터를 사용하면, 에이전트가 시작될 때 _AGENTS.md 파일을 자동으로 로드_하여
시스템 프롬프트에 주입합니다.

=== AGENTS.md란?
에이전트에게 항상 적용되어야 하는 _규칙, 컨벤션, 컨텍스트 정보_를 담는 마크다운 파일입니다.

=== 특징
- 에이전트가 시작할 때 _항상 로드_ (on-demand 아님)
- `<agent_memory>` 태그로 시스템 프롬프트에 주입
- 여러 소스 지정 가능 (배열)
- 에이전트가 `edit_file` 도구로 AGENTS.md를 _스스로 업데이트_ 가능

=== Memory 스코프 패턴

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[스코프],
  text(weight: "bold")[namespace],
  text(weight: "bold")[용도],
  [_agent-scoped_],
  [`(assistant_id,)`],
  [조직 공통 컨벤션, 도메인 지식 (사용자 간 공유)],
  [_user-scoped_],
  [`(user_id,)` 또는 `(assistant_id, user_id)`],
  [개인화 — 운영 기본],
  [_context-driven_],
  [`lambda rt: (rt.context.user_id,)`],
  [호출자가 user_id 를 직접 주입 (멀티 테넌트 SaaS)],
)

#code-block(`````python
from deepagents.backends import StoreBackend

# 컨텍스트로 user_id 를 주입하는 패턴 (멀티 테넌트)
user_scoped = StoreBackend(
    namespace=lambda rt: (rt.context.user_id,),
)
`````)

#code-block(`````python
import tempfile

# 임시 디렉토리 생성 — FilesystemBackend의 root_dir로 사용
tmp_dir = tempfile.mkdtemp()
print(f"임시 디렉토리 생성: {tmp_dir}")
`````)
#output-block(`````
임시 디렉토리 생성: C:\Users\HEESU\AppData\Local\Temp\tmpj97x7phs
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. 스킬 (Skills)

스킬은 에이전트에게 _도메인 전문 지식_을 부여하는 모듈화된 지침 세트입니다.

=== Memory vs Skills

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[비교],
  text(weight: "bold")[Memory (AGENTS.md)],
  text(weight: "bold")[Skills (SKILL.md)],
  [_로딩_],
  [항상 로드 (Always)],
  [필요 시 로드 (On-demand)],
  [_파일 형식_],
  [`AGENTS.md`],
  [`SKILL.md` (YAML 프론트매터)],
  [_적합한 용도_],
  [항상 적용되는 규칙/컨벤션],
  [특정 태스크에 필요한 큰 컨텍스트],
  [_토큰 효율_],
  [항상 소비],
  [점진적 공개로 절약],
  [_크기_],
  [간결할수록 좋음],
  [대용량 가능 (10MB 제한)],
  [_업데이트_],
  [에이전트가 edit_file로 수정 가능],
  [보통 정적],
)

=== Progressive Disclosure (점진적 공개)

스킬은 한 번에 전부 로드하지 않습니다:
+ 처음에는 _프론트매터(이름, 설명)_만 로드
+ 사용자 요청과 관련된 스킬을 _에이전트가 판단_
+ 필요한 스킬의 _전체 내용_을 그때 로드

이 방식으로 토큰을 절약하면서 필요한 전문 지식에 접근할 수 있습니다.

=== SKILL.md 구조

#code-block(`````yaml
---
name: web-research              # 스킬 식별자 (최대 64자, 소문자+하이픈)
description: >                  # 설명 (최대 1024자) — 매칭에 사용
  체계적인 웹 리서치를 수행하기 위한 단계별 가이드.
  정보 수집, 검증, 정리까지의 전체 워크플로를 다룹니다.
module: ./helpers.py            # 선택 — 인터프리터에 노출할 Python/TypeScript 모듈
license: MIT
compatibility: Python 3.8+
metadata:
  category: research
allowed-tools: ls read_file write_file
---

# Web Research 스킬

## 사용 시기
- 사용자가 특정 주제에 대한 조사를 요청할 때
- 최신 정보가 필요한 질문이 들어올 때

## 워크플로
1. 검색 쿼리 설계
2. 다양한 소스에서 정보 수집
3. 정보 교차 검증
4. 구조화된 보고서 작성
`````)

#tip-box[`module` 필드는 interpreter 기반 스킬에서 사용합니다. QuickJS 인터프리터 (`deepagents>=0.6`) 또는 샌드박스 스크립트 실행과 결합하면, 결정론적 헬퍼(파싱·검증·점수화)와 의존성/CLI 가 필요한 스크립트를 분리할 수 있습니다.]

=== 스킬을 지원하는 백엔드

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[백엔드],
  text(weight: "bold")[시나리오],
  [`StateBackend`],
  [`invoke(files={...})` 와 `create_file_data()` 로 시드],
  [`StoreBackend`],
  [영속 namespace 에서 로드 (`InMemoryStore`, `PostgresStore`)],
  [`FilesystemBackend`],
  [에이전트 root 기준 디스크 읽기],
  [`CompositeBackend`],
  [스킬 파일은 `StoreBackend`, 실행은 샌드박스로 분리],
)

#code-block(`````python
# 스킬을 사용하는 에이전트 생성
skilled_agent = create_deep_agent(
    model=model,
    system_prompt="당신은 시니어 개발자입니다. 사용 가능한 스킬을 활용하여 작업을 수행하세요.",
    backend=FilesystemBackend(root_dir=tmp_dir, virtual_mode=True),
    skills=["/skills/"],  # 스킬 소스 디렉토리
)

print("스킬 에이전트 생성 완료")
`````)
#output-block(`````
스킬 에이전트 생성 완료
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. 스킬 소스 우선순위

여러 스킬 소스를 지정하면, _나중에 나온 소스가 우선_합니다 (last wins).

#code-block(`````python
skills=[
    "/skills/base/",     # 기본 스킬
    "/skills/user/",     # 사용자 스킬 (base 덮어쓰기 가능)
    "/skills/project/",  # 프로젝트 스킬 (최우선)
]
`````)

같은 이름의 스킬이 여러 소스에 있으면, 마지막 소스의 스킬이 사용됩니다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. 서브에이전트의 스킬 상속

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[서브에이전트 유형],
  text(weight: "bold")[스킬 상속],
  [General-purpose (빌트인)],
  [메인 에이전트의 스킬을 _자동 상속_],
  [커스텀 SubAgent],
  [**명시적 `skills` 파라미터** 필요],
)

#code-block(`````python
# 커스텀 서브에이전트에 스킬 부여
subagent = {
    "name": "reviewer",
    "description": "코드 리뷰 전문 에이전트",
    "system_prompt": "...",
    "tools": [],
    "skills": ["/skills/code-review/"],  # 명시적 스킬 경로
}
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 핵심 정리

=== Skills vs Memory 레이어링

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[비교],
  text(weight: "bold")[Memory (AGENTS.md)],
  text(weight: "bold")[Skills (SKILL.md)],
  [_로딩_],
  [항상 주입 (always-on)],
  [Progressive disclosure (on-demand)],
  [_형식_],
  [`AGENTS.md`],
  [`SKILL.md` + frontmatter (`name`, `description`, optional `module`)],
  [_레이어링_],
  [사용자 + 프로젝트 결합],
  [마지막 소스 우선 (last wins)],
  [_적합 용도_],
  [항상 적용되는 컨벤션],
  [대용량 task-specific 컨텍스트],
  [_토큰 효율_],
  [항상 소비],
  [절약 (필요 시 로드)],
  [_업데이트_],
  [에이전트가 `edit_file`로 수정 가능],
  [보통 정적],
)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [장기 메모리],
  [`CompositeBackend` + `StoreBackend`로 `/memories/` 영속화],
  [프로덕션 store],
  [`from langgraph.store.postgres import PostgresStore`],
  [namespace 패턴],
  [`lambda rt: (rt.context.user_id,)` — 컨텍스트 주입 user_id],
  [AGENTS.md],
  [`memory=["/path/AGENTS.md"]` → 항상 시스템 프롬프트에 주입],
  [Skills],
  [`skills=["/skills/"]` → SKILL.md 기반 progressive disclosure],
  [스킬 `module`],
  [인터프리터 노출 Python/TS 파일 — 결정론적 헬퍼],
  [스킬 우선순위],
  [나중 소스가 우선 (last wins)],
  [정보 유형],
  [Episodic (checkpointer) / Procedural (skills) / Semantic (store)],
)
