// Auto-generated from 06_memory_and_skills.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "장기 메모리 & 스킬")

대화 스레드가 종료되면 기본 에이전트는 모든 정보를 잊는다. 실용적인 어시스턴트를 만들려면 사용자 선호도, 프로젝트 컨벤션, 도메인 지식 등을 대화 간에 유지하는 장기 메모리가 필수적이다. 이 장에서는 `CompositeBackend` + `StoreBackend`를 활용한 크로스 스레드 메모리 구현과, `AGENTS.md` 기반 컨텍스트 주입, 그리고 `SKILL.md`의 Progressive Disclosure 메커니즘을 학습한다.

5장에서 서브에이전트가 컨텍스트 격리를 제공하는 것을 보았다. 하지만 격리만으로는 대화가 끝난 뒤에도 에이전트가 학습한 내용을 유지하는 _장기 기억_을 구현할 수 없다. Deep Agents는 `InMemoryStore`(개발용) 또는 데이터베이스 기반 `Store`(프로덕션용)를 통해 크로스 스레드 메모리를 지원하며, `AGENTS.md`와 `SKILL.md`라는 두 가지 파일 기반 메커니즘으로 지식을 관리한다.

메모리 시스템의 핵심 API는 네임스페이스(namespace), `put`, `get`, `search`의 네 가지다. _네임스페이스_는 메모리 항목을 논리적으로 그룹화하는 경로이고, `put`으로 항목을 저장하고, `get`으로 특정 항목을 조회하며, `search`로 의미 기반 검색을 수행한다. 이 API는 LangGraph의 `BaseStore` 인터페이스 위에 구축되어 있으므로, 백엔드를 `InMemoryStore`에서 `PostgresStore`로 교체해도 코드 변경 없이 동작한다.

#learning-header()
#learning-objectives([`CompositeBackend` + `StoreBackend`로 장기 메모리를 구현한다], [크로스 스레드 메모리 공유 패턴을 이해한다], [`AGENTS.md`를 통해 에이전트에 컨텍스트를 주입한다], [스킬(SKILL.md)의 구조와 Progressive Disclosure를 이해한다], [Skills vs Memory의 차이를 파악한다])

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
# OpenAI gpt-4.1 모델 설정
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")
`````)

환경 설정을 마쳤으므로, 왜 장기 메모리가 필요한지부터 이해한 뒤 구현 방법으로 넘어간다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. 장기 메모리가 필요한 이유

기본 `StateBackend` 에이전트는 _대화 스레드가 끝나면 모든 정보를 잊습니다_. 체크포인터(`MemorySaver`)가 대화 상태를 보존하지만, 이는 _같은 스레드_ 내에서만 유효하다. 새 대화(새 `thread_id`)가 시작되면 에이전트는 백지 상태로 돌아간다.

하지만 실제 어시스턴트는 아래 정보를 _대화 간에 유지_해야 합니다:

- 사용자 선호도 (코딩 스타일, 사용 언어)
- 프로젝트 컨벤션 (아키텍처 결정, 네이밍 규칙)
- 이전 대화에서 학습한 피드백
- 자주 참조하는 정보 (API 문서, 설정값)

=== 해결 방식: CompositeBackend

#align(center)[#image("../../assets/diagrams/png/composite_backend.png", width: 68%, height: 122mm, fit: "contain")]

`/memories/` 경로에 저장된 파일은 _어떤 대화 스레드에서든_ 접근할 수 있습니다. 이 구조에서 `StateBackend`는 현재 대화의 임시 파일을 관리하고, `StoreBackend`는 `/memories/` 하위 경로의 파일을 `InMemoryStore`(또는 데이터베이스)에 영속적으로 저장한다. `CompositeBackend`가 경로별로 어떤 백엔드를 사용할지 라우팅하는 역할을 한다.

다음 코드에서 이 세 가지 백엔드를 조합하여 장기 메모리 에이전트를 구축하는 전체 과정을 살펴보자.

#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import StateBackend, StoreBackend, CompositeBackend, FilesystemBackend
from langgraph.store.memory import InMemoryStore
from langgraph.checkpoint.memory import MemorySaver


# 1. 스토어와 체크포인터 생성
store = InMemoryStore()          # 개발용 (프로덕션: PostgresStore)
checkpointer = MemorySaver()     # 에이전트 상태 유지


# 2. CompositeBackend 팩토리 — /memories/만 영속, 나머지는 에페메럴
def memory_backend_factory(runtime):
    return CompositeBackend(
        default=StateBackend(runtime),
        routes={
            "/memories/": StoreBackend(runtime),
        },
    )


# 3. 에이전트 생성
memory_agent = create_deep_agent(
    model=model,
    system_prompt="""당신은 개인 어시스턴트입니다.
사용자가 기억해 달라고 하는 정보는 /memories/ 폴더에 저장하세요.
이전에 저장한 메모리가 있으면 참고하여 응답하세요.
한국어로 응답하세요.""",
    backend=memory_backend_factory,
    store=store,
    checkpointer=checkpointer,
)

print("장기 메모리 에이전트 생성 완료")
`````)
#output-block(`````
장기 메모리 에이전트 생성 완료
`````)

위 코드에서 `memory_backend_factory`는 함수(팩토리 패턴)로 정의되어 있다. `runtime` 인자는 에이전트 실행 시 자동으로 주입되며, 현재 스레드의 `assistant_id`, `thread_id` 등의 런타임 정보를 포함한다. 이 정보를 기반으로 `StoreBackend`가 올바른 네임스페이스에 메모리를 저장한다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. 크로스 스레드 메모리 공유

장기 메모리의 핵심은 _크로스 스레드 공유_입니다. `StoreBackend`에 저장된 데이터는 `assistant_id` 기반 네임스페이스로 관리되며, _어떤 대화 스레드에서든_ 같은 네임스페이스의 데이터에 접근할 수 있습니다. 아래 예제에서 스레드 1에서 저장한 선호도를 스레드 2에서 읽어봅니다.

네임스페이스의 구조는 `(assistant_id, "memories", category)` 형태의 튜플이다. 예를 들어 `("asst-001", "memories", "preferences")`라는 네임스페이스에 `put`으로 항목을 저장하면, 동일한 `assistant_id`를 사용하는 모든 스레드에서 `get` 또는 `search`로 해당 항목을 조회할 수 있다. `search` API는 의미 기반 유사도 검색을 지원하므로, 정확한 키를 모르더라도 자연어 쿼리로 관련 메모리를 찾을 수 있다.

#tip-box[`InMemoryStore`는 개발/테스트 용도입니다. 프로덕션 환경에서는 `PostgresStore` 등 영구 스토어를 사용하세요. LangSmith 배포 시에는 스토어가 자동으로 프로비저닝됩니다. `InMemoryStore`는 프로세스가 종료되면 모든 데이터가 사라지므로, 영속성이 필요한 경우 반드시 데이터베이스 기반 스토어를 선택하라.]

크로스 스레드 메모리가 _동적으로 학습된_ 정보를 저장하는 메커니즘이라면, `AGENTS.md`는 _사전에 정의된_ 규칙과 컨텍스트를 에이전트에 주입하는 메커니즘이다. 두 가지를 함께 사용하면, 에이전트는 프로젝트 규칙을 항상 준수하면서도 사용자별 선호도를 기억하는 완전한 지식 시스템을 갖출 수 있다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. AGENTS.md를 통한 컨텍스트 주입

`memory` 파라미터를 사용하면, 에이전트가 시작될 때 _AGENTS.md 파일을 자동으로 로드_하여
시스템 프롬프트에 주입합니다.

=== AGENTS.md란?
에이전트에게 항상 적용되어야 하는 _규칙, 컨벤션, 컨텍스트 정보_를 담는 마크다운 파일입니다. 프로젝트의 아키텍처 결정, 코딩 스타일 가이드, 자주 참조하는 API 정보 등을 기록합니다. `AGENTS.md`는 LLM 에이전트판 `.editorconfig` 또는 `.eslintrc`에 해당한다고 볼 수 있다. 팀원 모두가 같은 규칙을 따르듯, 에이전트도 `AGENTS.md`에 정의된 규칙을 일관되게 따른다.

=== 특징
- 에이전트가 시작할 때 _항상 로드_ (on-demand가 아님) -- `MemoryMiddleware`가 `<agent_memory>` 태그로 시스템 프롬프트에 주입
- `memory` 파라미터에 여러 경로를 배열로 지정 가능 (예: `memory=["/global/AGENTS.md", "/project/AGENTS.md"]`)
- 에이전트가 `edit_file` 도구로 AGENTS.md를 _스스로 업데이트_ 가능 -- 사용자 피드백을 반영하여 자가 학습

#warning-box[`AGENTS.md`는 매 대화마다 시스템 프롬프트에 포함되므로, 내용이 길어지면 토큰 비용이 증가합니다. 핵심 규칙만 간결하게 유지하고, 상세한 가이드는 `SKILL.md`로 분리하세요. 일반적으로 `AGENTS.md`는 500~1,000 토큰 이내를 권장합니다.]

#tip-box[`AGENTS.md`를 여러 경로로 분리하면 _글로벌 규칙_과 _프로젝트별 규칙_을 계층적으로 관리할 수 있다. 예: `memory=["/global/AGENTS.md", "/project/AGENTS.md"]`. 두 파일의 내용이 충돌하면 _나중에 나온 경로_(프로젝트)가 우선한다.]

#code-block(`````python
import tempfile

# 임시 디렉토리 생성 — FilesystemBackend의 root_dir로 사용
tmp_dir = tempfile.mkdtemp()
print(f"임시 디렉토리 생성: {tmp_dir}")
`````)
#output-block(`````
임시 디렉토리 생성: C:\Users\HEESU\AppData\Local\Temp\tmpj97x7phs
`````)

`AGENTS.md`가 항상 로드되는 규칙이라면, 다음에 다룰 _스킬(Skills)_은 필요할 때만 로드되는 전문 지식이다. 대규모 API 레퍼런스처럼 항상 로드하기에는 너무 큰 지식을 효율적으로 관리하는 방법이다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. 스킬 (Skills)

스킬은 에이전트에게 _도메인 전문 지식_을 부여하는 모듈화된 지침 세트입니다. `SKILL.md` 파일로 정의하며, YAML 프론트매터에 이름과 설명을, 마크다운 본문에 상세 지침을 담는다. 스킬의 핵심 설계 원리는 _Progressive Disclosure(점진적 공개)_로, 프론트매터만 먼저 노출하고 전체 내용은 필요할 때만 로드하여 토큰을 절약한다.

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

스킬은 한 번에 전부 로드하지 않습니다. 이것이 `AGENTS.md`(항상 로드)와의 핵심 차이점입니다:
+ 에이전트 시작 시, `SkillsMiddleware`가 모든 `SKILL.md` 파일의 _프론트매터(이름, 설명)만 로드_하여 시스템 프롬프트에 스킬 목록으로 제시합니다.
+ 사용자 요청이 들어오면, 에이전트가 스킬 목록을 참조하여 _관련 스킬을 판단_합니다.
+ 필요한 스킬의 _전체 내용_(마크다운 본문)을 그때 로드하여 컨텍스트에 추가합니다.

이 방식으로 수십 개의 스킬을 등록해도, 실제로 사용되는 스킬만 토큰을 소비합니다. 각 스킬 파일은 최대 10MB까지 가능하므로, 대규모 API 레퍼런스나 도메인 가이드도 스킬로 관리할 수 있습니다.

#warning-box[스킬의 `description`이 모호하면 에이전트가 관련 스킬을 찾지 못하거나 잘못된 스킬을 로드할 수 있다. _"웹 리서치 스킬"_보다는 _"체계적인 웹 리서치를 수행하기 위한 단계별 가이드. 정보 수집, 검증, 정리까지의 전체 워크플로를 다룹니다"_처럼 구체적으로 작성하라. `description`은 최대 1,024자까지 허용된다.]

=== SKILL.md 구조

다음은 `SKILL.md` 파일의 전체 구조이다. YAML 프론트매터(`---`로 감싼 부분)에는 스킬 메타데이터를, 그 아래 마크다운 본문에는 에이전트가 따라야 할 상세 지침을 작성한다.

#code-block(`````yaml
---
name: web-research           # 스킬 식별자 (최대 64자, 소문자+하이픈)
description: >               # 설명 (최대 1024자) — 매칭에 사용
  체계적인 웹 리서치를 수행하기 위한 단계별 가이드.
  정보 수집, 검증, 정리까지의 전체 워크플로를 다룹니다.
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

위 코드에서 `skills=["/skills/"]`는 해당 경로 아래의 모든 `SKILL.md` 파일을 자동으로 탐색한다. 에이전트가 시작되면 `SkillsMiddleware`가 각 스킬 파일의 프론트매터만 읽어 _스킬 카탈로그_를 시스템 프롬프트에 추가한다. 사용자 요청이 들어오면 에이전트가 카탈로그를 참고하여 관련 스킬을 선택하고, 그때 비로소 전체 내용을 로드한다.

스킬 소스는 하나만 지정할 수도 있고 여러 개를 지정할 수도 있다. 여러 소스를 지정하면 우선순위가 적용된다.

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

같은 이름의 스킬이 여러 소스에 있으면, 마지막 소스의 스킬이 사용됩니다. 이 규칙을 활용하면 _기본 스킬 세트를 팀 전체가 공유_하면서, 프로젝트나 사용자 단위로 특화된 스킬을 덮어쓸 수 있다.

서브에이전트도 스킬을 사용할 수 있다. 다만 스킬 상속 방식이 서브에이전트 유형에 따라 다르므로, 다음 섹션에서 이를 정리한다.

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
  [*명시적 `skills` 파라미터* 필요],
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

#tip-box[서브에이전트에 스킬을 부여할 때는 _최소 권한 원칙_을 따르라. 리뷰 전문 서브에이전트에 배포 관련 스킬까지 주면 불필요한 토큰 소비와 혼란이 발생한다. 각 서브에이전트의 역할에 딱 맞는 스킬만 할당하라.]

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
  [장기 메모리],
  [`CompositeBackend` + `StoreBackend`로 `/memories/` 영속화],
  [AGENTS.md],
  [`memory=["/path/AGENTS.md"]` → 항상 시스템 프롬프트에 주입],
  [Skills],
  [`skills=["/skills/"]` → SKILL.md 기반 점진적 공개],
  [Progressive Disclosure],
  [프론트매터만 먼저 로드 → 필요 시 전체 로드],
  [스킬 우선순위],
  [나중 소스가 우선 (last wins)],
  [Memory vs Skills],
  [Memory = 항상 로드 / Skills = 필요 시 로드],
)

장기 메모리와 스킬 시스템을 통해 에이전트는 대화를 넘어서 지식을 축적하고, 필요할 때 전문 능력을 발휘할 수 있게 되었습니다. 다음 장에서는 Human-in-the-Loop, 스트리밍 심화, 샌드박스, ACP, CLI 등 프로덕션 수준의 고급 기능을 다룹니다.

