// Auto-generated from 09_comparison.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(9, "외부 프레임워크 비교")

AI 에이전트 프레임워크는 빠르게 진화하고 있으며, 프로젝트 요구사항에 맞는 프레임워크를 선택하는 것이 성공의 핵심이다. 이 장에서는 Deep Agents를 `OpenCode`, `Claude Agent SDK`와 모델 지원, 아키텍처, 생태계, 라이선스 측면에서 비교 분석한다. 사용 사례별 추천과 마이그레이션 고려사항을 함께 정리하여 실무 의사결정에 도움을 준다.

8장까지 Deep Agents의 내부 구조를 깊이 있게 탐구했다. 이제 한 발 물러서서, Deep Agents가 에이전트 프레임워크 생태계에서 어떤 위치를 차지하는지 객관적으로 평가한다. 각 프레임워크는 고유한 설계 철학과 강점을 가지므로, 절대적인 우열보다는 _프로젝트 요구사항에 맞는 선택_이 중요하다.

이 비교에서 다루는 세 프레임워크는 서로 다른 설계 축을 대표한다. Deep Agents는 _모델 무관 + 플러거블 아키텍처_, OpenCode는 _터미널 네이티브 + 로컬 모델_, Claude Agent SDK는 _단일 모델 최적화 + 간결한 API_를 지향한다. 이 장을 통해 각 프레임워크의 장단점을 균형 있게 이해하고, 프로젝트의 규모, 모델 전략, 배포 환경에 따른 합리적인 선택 기준을 세울 수 있다.

#learning-header()
#learning-objectives([Deep Agents, LangGraph, LangChain의 심화 차이를 이해한다], [OpenCode, Claude Agent SDK와 비교한다], [아키텍처, 유연성, 생태계를 비교 분석한다], [사용 사례별 추천 프레임워크를 안다], [마이그레이션 고려사항을 이해한다])

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
== 1. 비교 개요

AI 에이전트 프레임워크를 선택할 때는 _모델 지원_, _아키텍처_, _생태계_, _라이선스_ 등 여러 요소를 고려해야 합니다. 프레임워크를 선택하는 것은 단기적인 개발 속도뿐 아니라, 장기적인 유지보수성, 확장성, 벤더 종속(vendor lock-in) 위험에도 직접적인 영향을 미칩니다.

이 장에서는 세 가지 주요 프레임워크를 비교합니다:

- _LangChain Deep Agents_ — 모델 무관(model-agnostic) 에이전트 하네스. LangGraph 기반의 그래프 실행 엔진과 플러거블 백엔드를 결합하여 프로덕션급 에이전트 앱을 구축합니다.
- _OpenCode_ — 터미널/데스크톱/IDE 기반 코딩 에이전트. Go로 작성되어 가볍고 빠르며, Ollama를 통한 로컬 모델 지원이 특징입니다.
- _Claude Agent SDK_ — Anthropic의 Claude 전용 에이전트 SDK. Claude 모델에 최적화된 간결한 API로 빠른 프로토타이핑에 적합합니다.

#note-box[이 비교는 2026년 초 기준이며, 각 프레임워크는 활발하게 개발 중입니다. 특정 기능의 지원 여부는 최신 릴리즈 노트를 확인하세요. 여기서는 _설계 철학_과 _아키텍처 차이_에 초점을 맞추어, 시간이 지나도 유효한 비교 기준을 제공합니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. Deep Agents vs OpenCode vs Claude Agent SDK

먼저 세 프레임워크의 기본 스펙을 비교표로 정리합니다. 이 표는 프로젝트 초기에 후보를 좁히는 데 유용합니다.

=== 기본 비교

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[특성],
  text(weight: "bold")[LangChain Deep Agents],
  text(weight: "bold")[OpenCode],
  text(weight: "bold")[Claude Agent SDK],
  [_모델 지원_],
  [모델 무관 (Anthropic, OpenAI, 100+ 제공자)],
  [75+ 제공자 (Ollama 포함 로컬)],
  [Claude 모델 전용],
  [_라이선스_],
  [MIT],
  [MIT],
  [MIT (SDK), 독점 (Claude Code)],
  [_SDK_],
  [Python, TypeScript + CLI],
  [터미널, 데스크톱, IDE 확장],
  [Python, TypeScript],
  [_샌드박스_],
  [통합 도구로 사용 가능],
  [미지원],
  [미지원],
  [_상태 관리_],
  [타임 트래블 지원],
  [미지원],
  [타임 트래블 지원],
  [_Observability_],
  [LangSmith 네이티브],
  [없음],
  [없음],
)

이 표에서 가장 두드러지는 차이는 _모델 지원 범위_입니다. Deep Agents는 100개 이상의 모델 제공자를 지원하여 벤더 종속 위험이 낮고, Claude Agent SDK는 Claude 전용으로 특정 모델에 최적화되어 있으며, OpenCode는 로컬 모델(Ollama)을 포함한 75개 이상의 제공자를 지원합니다. 다음 코드로 비교 테이블을 프로그래밍적으로 확인할 수 있습니다.

#code-block(`````python
# 프레임워크 비교 테이블 출력
frameworks = {
    "LangChain Deep Agents": {
        "모델 지원": "100+ 제공자 (model-agnostic)",
        "라이선스": "MIT",
        "SDK": "Python, TypeScript, CLI",
        "샌드박스": "통합 지원",
        "타임 트래블": "지원",
    },
    "OpenCode": {
        "모델 지원": "75+ 제공자 (로컬 포함)",
        "라이선스": "MIT",
        "SDK": "터미널, 데스크톱, IDE",
        "샌드박스": "미지원",
        "타임 트래블": "미지원",
    },
    "Claude Agent SDK": {
        "모델 지원": "Claude 전용",
        "라이선스": "MIT (SDK)",
        "SDK": "Python, TypeScript",
        "샌드박스": "미지원",
        "타임 트래블": "지원",
    },
}

print("=== 프레임워크 비교 ===")
for name, features in frameworks.items():
    print(f"\n[{name}]")
    for key, value in features.items():
        print(f"  {key}: {value}")
`````)
#output-block(`````
=== 프레임워크 비교 ===

[LangChain Deep Agents]
  모델 지원: 100+ 제공자 (model-agnostic)
  라이선스: MIT
  SDK: Python, TypeScript, CLI
  샌드박스: 통합 지원
  타임 트래블: 지원

[OpenCode]
  모델 지원: 75+ 제공자 (로컬 포함)
  라이선스: MIT
  SDK: 터미널, 데스크톱, IDE
  샌드박스: 미지원
  타임 트래블: 미지원

[Claude Agent SDK]
  모델 지원: Claude 전용
  라이선스: MIT (SDK)
  SDK: Python, TypeScript
  샌드박스: 미지원
  타임 트래블: 지원
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. 핵심 기능 비교

기본 스펙 비교에서 전체적인 윤곽을 파악했으니, 이제 각 프레임워크가 제공하는 핵심 기능을 세부적으로 비교합니다. 기능의 _유무_뿐 아니라 _구현 깊이_에도 주목하세요.

=== 공통 기능
세 프레임워크 모두 코딩 에이전트의 기본 기능을 갖추고 있습니다. 이 공통 기능은 코딩 에이전트의 _최소 요구 사항_으로, 어떤 프레임워크를 선택하든 제공됩니다:
- 파일 작업 (읽기, 쓰기, 편집)
- 쉘 명령 실행
- 검색 기능 (grep, glob)
- 계획 기능 (태스크 리스트)
- Human-in-the-Loop (권한 프레임워크는 상이)

진정한 차이는 이 공통 기능 _위에_ 각 프레임워크가 추가하는 고유 기능에서 드러납니다.

=== 차별화 기능

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[Deep Agents],
  text(weight: "bold")[OpenCode],
  text(weight: "bold")[Claude Agent SDK],
  [_코어 도구_],
  [파일, 쉘, 검색, 계획],
  [파일, 쉘, 검색, 계획],
  [파일, 쉘, 검색, 계획],
  [_샌드박스 통합_],
  [도구로 통합 가능],
  [없음],
  [없음],
  [_플러거블 백엔드_],
  [스토리지, 파일시스템],
  [없음],
  [없음],
  [_가상 파일시스템_],
  [플러거블 백엔드],
  [없음],
  [없음],
  [_네이티브 트레이싱_],
  [LangSmith],
  [없음],
  [없음],
)

#tip-box[프레임워크 선택에서 가장 과소평가되는 요소가 _Observability_(관찰 가능성)입니다. 에이전트가 예상과 다르게 동작할 때, 내부 상태와 도구 호출 과정을 추적할 수 있는지가 디버깅 시간을 결정합니다. Deep Agents의 LangSmith 통합은 이 문제에 대한 성숙한 솔루션을 제공합니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3-1. 3가지 핵심 차별점

표 위 항목들을 더 깊이 들여다보면, Deep Agents가 다른 두 프레임워크와 갈리는 지점은 _세 축_에 모인다. 단순 기능 차이가 아니라 설계 결정의 결과이므로, 어느 축이 본인 프로젝트에 결정적인지를 먼저 짚어 보면 선택이 분명해진다.

=== Execution Model — 그래프 기반 상태 머신 vs 단방향 ReAct 루프

Deep Agents는 LangGraph의 `StateGraph` 위에서 동작한다. 노드·엣지·서브그래프로 조립되며, 분기·반복·인터럽트·재개가 모두 그래프 명세에 들어간다. 결과적으로 _time travel_(과거 시점으로 분기), _interrupt/resume_(HITL 표준 경로), _subgraph 단위 스트리밍_이 자연스럽게 따라온다. OpenCode와 Claude Agent SDK는 ReAct 루프 중심이라 상태 분기·subgraph 격리에서 별도 구현 비용이 든다.

=== Deployment & Multi-Tenancy — LangSmith Deployments 통합

Deep Agents는 _LangSmith Deployments_에 그대로 배포되어, `assistant_id`/`thread_id`/`user_id`로 멀티 테넌시를 제공한다. cron 스케줄(consolidation agent), Store(영속 메모리), Checkpointer가 배포 시점에 자동 프로비저닝된다. OpenCode는 로컬 터미널 도구, Claude Agent SDK는 모델 호출 SDK에 가깝다 — 두 프레임워크 모두 별도 인프라 구축이 필요하다.

=== Per-Model Configuration — `HarnessProfile`/`ProviderProfile`

Deep Agents 0.5+는 provider/model별 기본값을 _profile로 패키징_한다. 같은 코드베이스에서 `openai:gpt-5.4`와 `anthropic:claude-sonnet-4-6`을 호출부 수정 없이 교체할 수 있다. Claude Agent SDK는 Claude 전용으로 모델 추상화 자체가 없고, OpenCode는 75+ 프로바이더를 지원하지만 _provider 차이를 흡수하는 profile_ 개념이 없다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. 아키텍처 비교

기능 목록만으로는 프레임워크의 본질을 이해하기 어렵습니다. 기능 비교를 넘어, 각 프레임워크의 _설계 철학_을 이해하면 장기적인 기술 결정에 도움이 됩니다. 어떤 기능이 있는지보다, _왜 그렇게 설계되었는지_를 아는 것이 향후 확장성과 유지보수에 더 중요합니다.

=== LangChain Deep Agents
Deep Agents의 아키텍처는 _플러거블 추상화_를 핵심 원칙으로 설계되었습니다. 이 철학의 핵심은 "교체 가능성"입니다. 모델, 스토리지, 파일시스템, 관찰 도구를 독립적인 추상화 레이어로 분리하여, 하나의 컴포넌트를 교체해도 나머지에 영향을 주지 않습니다:
- _플러거블 스토리지 백엔드_ -- 상태, 파일시스템, 스토어를 독립적으로 구성. 인메모리, SQLite, PostgreSQL 등 필요에 따라 교체 가능
- _가상 파일시스템_ — 로컬, 인메모리, 샌드박스 백엔드 교체 가능. `BackendProtocol` 구현체만 바꾸면 에이전트 코드 변경 없이 전환
- _LangGraph 기반_ — 그래프 실행 엔진으로 복잡한 워크플로 지원. 노드와 엣지로 정의된 상태 머신이 도구 호출, 분기, 반복을 관리
- _미들웨어 시스템_ — `TodoListMiddleware`, `SummarizationMiddleware` 등으로 에이전트 동작을 세밀하게 커스터마이징

=== OpenCode
OpenCode는 _개발자 경험(DX)_을 최우선으로 설계된 프레임워크입니다:
- _터미널 네이티브_ — Go 바이너리 하나로 설치 완료. 별도의 Python 환경 구성 없이 즉시 사용 가능
- _75+ 모델 제공자_ — Ollama를 통한 로컬 모델 지원. 인터넷 없이도 에이전트 실행 가능
- _LSP 통합_ — Language Server Protocol을 활용하여 코드 자동 완성, 정의 이동 등 에디터 수준의 코드 이해 제공

=== Claude Agent SDK
Claude Agent SDK는 _단일 모델 최적화_라는 명확한 설계 선택을 했습니다:
- _Claude 최적화_ — Claude 모델의 고유 기능(extended thinking, tool use 패턴)에 특화된 추상화 제공
- _타임 트래블_ — 상태 분기(branching) 지원. 에이전트 실행 중 특정 시점으로 되돌아가 다른 경로를 탐색 가능
- _간결한 API_ — 최소한의 코드로 에이전트를 구축할 수 있어 빠른 프로토타이핑에 적합

#warning-box[모델 종속(vendor lock-in)은 프레임워크 선택에서 반드시 고려해야 할 요소입니다. Claude Agent SDK는 Claude 모델에 특화된 만큼 강력한 최적화를 제공하지만, 향후 다른 모델로 전환이 필요할 때 상당한 리팩토링이 필요합니다. 반면 Deep Agents의 모델 무관 설계는 초기 설정이 다소 복잡하더라도 장기적인 유연성을 보장합니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. 사용 사례별 추천

아키텍처를 이해했으니, 이제 구체적인 사용 사례에 따라 어떤 프레임워크를 선택해야 하는지 정리합니다. 가장 중요한 기준은 _프로젝트의 규모와 수명_입니다. 단기 프로토타입이라면 API의 간결함이 중요하고, 장기 프로덕션이라면 확장성과 옵저버빌리티가 결정적입니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[사용 사례],
  text(weight: "bold")[추천 프레임워크],
  text(weight: "bold")[이유],
  [프로덕션 에이전트 앱],
  [_Deep Agents_],
  [플러거블 백엔드, 옵저버빌리티, 샌드박스],
  [멀티 모델 에이전트],
  [_Deep Agents_],
  [100+ 모델 제공자 지원],
  [터미널 코딩 어시스턴트],
  [_OpenCode_],
  [가볍고 빠른 시작, 로컬 모델],
  [Claude 전용 앱],
  [_Claude Agent SDK_],
  [Claude 최적화, 간결한 API],
  [빠른 프로토타이핑],
  [_Claude Agent SDK_],
  [간결한 API, 빠른 설정],
  [복잡한 멀티 에이전트 시스템],
  [_Deep Agents_],
  [서브에이전트, 컨텍스트 관리],
  [로컬 모델 사용],
  [_OpenCode_],
  [Ollama 네이티브 지원],
)

#tip-box[하나의 프레임워크가 모든 요구사항을 완벽하게 충족하기는 어렵습니다. 실무에서는 _프로토타입 단계_에서 Claude Agent SDK로 빠르게 검증한 후, _프로덕션 전환 시_ Deep Agents로 마이그레이션하는 전략도 효과적입니다. 7절의 마이그레이션 고려사항을 함께 참고하세요.]

다음 코드는 사용 사례를 입력하면 적합한 프레임워크를 추천하는 간단한 도우미 함수입니다.

#code-block(`````python
# 사용 사례별 프레임워크 추천 도우미
def recommend_framework(use_case: str) -> str:
    """사용 사례에 따라 프레임워크를 추천합니다."""
    recommendations = {
        "production": ("Deep Agents", "플러거블 백엔드, 옵저버빌리티, 샌드박스"),
        "multi-model": ("Deep Agents", "100+ 모델 제공자 지원"),
        "terminal": ("OpenCode", "가볍고 빠른 시작, 로컬 모델"),
        "claude-only": ("Claude Agent SDK", "Claude 최적화, 간결한 API"),
        "prototyping": ("Claude Agent SDK", "간결한 API, 빠른 설정"),
        "multi-agent": ("Deep Agents", "서브에이전트, 컨텍스트 관리"),
        "local-model": ("OpenCode", "Ollama 네이티브 지원"),
    }
    if use_case in recommendations:
        fw, reason = recommendations[use_case]
        return f"{fw} — {reason}"
    return "해당 사용 사례를 찾을 수 없습니다."

# 테스트
test_cases = ["production", "terminal", "claude-only", "multi-agent"]
print("=== 프레임워크 추천 ===")
for case in test_cases:
    print(f"  {case}: {recommend_framework(case)}")
`````)
#output-block(`````
=== 프레임워크 추천 ===
  production: Deep Agents — 플러거블 백엔드, 옵저버빌리티, 샌드박스
  terminal: OpenCode — 가볍고 빠른 시작, 로컬 모델
  claude-only: Claude Agent SDK — Claude 최적화, 간결한 API
  multi-agent: Deep Agents — 서브에이전트, 컨텍스트 관리
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. 생태계 비교

프레임워크 자체의 기능도 중요하지만, 주변 생태계의 성숙도는 실제 개발 경험에 큰 영향을 미칩니다. 문서 품질, 커뮤니티 규모, 서드파티 통합 수준을 비교합니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[Deep Agents],
  text(weight: "bold")[OpenCode],
  text(weight: "bold")[Claude Agent SDK],
  [_커뮤니티_],
  [LangChain 생태계 (대규모)],
  [GitHub 커뮤니티],
  [Anthropic 커뮤니티],
  [_문서_],
  [공식 문서 + LangSmith 연동],
  [GitHub README],
  [Anthropic 공식 문서],
  [_통합_],
  [LangChain, LangGraph, LangSmith],
  [LSP, 터미널],
  [Claude API],
  [_패키지 관리_],
  [pip/uv],
  [go install / brew],
  [pip/npm],
  [_에디터 통합_],
  [ACP (Zed, JetBrains, VS Code, Neovim)],
  [자체 에디터],
  [없음],
)

Deep Agents의 가장 큰 생태계 장점은 LangChain 생태계와의 통합입니다. LangChain의 방대한 도구 라이브러리, LangGraph의 그래프 실행 엔진, LangSmith의 트레이싱 플랫폼을 모두 활용할 수 있습니다. 또한 ACP 프로토콜을 통해 주요 에디터와 통합할 수 있어, 개발자가 익숙한 도구에서 에이전트를 사용할 수 있습니다.

#note-box[생태계 규모는 장점이자 단점이 될 수 있습니다. LangChain 생태계는 풍부한 서드파티 도구를 제공하지만, 버전 호환성 관리와 학습 곡선이 상대적으로 높습니다. OpenCode는 생태계가 작지만 단일 바이너리로 설치가 간단하고, Claude Agent SDK는 Anthropic이 직접 관리하므로 API 안정성이 높습니다.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. 마이그레이션 고려사항

프레임워크는 한 번 선택하면 영원히 고정되는 것이 아닙니다. 프레임워크 선택 후에도 요구사항 변화에 따라 마이그레이션이 필요할 수 있습니다. 프레임워크 간 마이그레이션 시 고려할 핵심 사항을 정리합니다.

=== 공통 고려사항
+ _모델 호환성_ — 사용 중인 모델이 대상 프레임워크에서 지원되는지 확인
+ _도구 호환성_ — 커스텀 도구의 인터페이스 변환 필요
+ _상태 관리_ — 체크포인트/메모리 마이그레이션 방법 확인
+ _옵저버빌리티_ — 트레이싱/로깅 솔루션 대체 방안

=== Deep Agents로 마이그레이션 시 장점
Deep Agents는 LangChain 생태계 위에 구축되어 있으므로, 기존 LangChain/LangGraph 사용자에게 마이그레이션이 가장 용이합니다:
- _LangChain 도구 재사용_ -- 기존 LangChain 도구(`@tool` 데코레이터로 만든 함수)를 `tools` 파라미터에 그대로 전달 가능
- _LangGraph 호환_ -- `CompiledSubAgent`를 통해 기존 LangGraph 그래프를 서브에이전트로 연결 가능
- _점진적 마이그레이션_ -- 기존 코드를 단계적으로 전환하면서 Deep Agents 기능을 점진적으로 도입 가능

#tip-box[이미 LangChain이나 LangGraph를 사용 중이라면, Deep Agents로의 마이그레이션은 `create_deep_agent()` 래퍼를 추가하는 것만으로 시작할 수 있습니다. 기존 도구와 그래프를 재사용하면서 계획, 컨텍스트 관리, 메모리 등의 하네스 기능을 점진적으로 활용하세요.]

=== 주의사항
- Claude Agent SDK에서 마이그레이션 시 Claude 전용 기능(extended thinking, Claude 고유 도구 호출 패턴)은 대체 구현이 필요합니다
- OpenCode에서 마이그레이션 시 터미널 UI 로직과 에이전트 비즈니스 로직을 분리해야 합니다. OpenCode는 Go 기반이므로, Python 환경으로의 전환도 고려해야 합니다
- 모든 마이그레이션에서 가장 비용이 높은 부분은 _프롬프트 엔지니어링_의 재작업입니다. 각 프레임워크는 시스템 프롬프트를 처리하는 방식이 다르므로, 기존 프롬프트를 그대로 사용하면 성능이 저하될 수 있습니다

#warning-box[마이그레이션을 결정하기 전에, 현재 프레임워크에서 원하는 기능을 _확장(extension)_으로 구현할 수 있는지 먼저 검토하세요. Deep Agents의 미들웨어 시스템이나 커스텀 도구를 통해 많은 요구사항을 기존 프레임워크 내에서 해결할 수 있습니다. 전체 마이그레이션은 최후의 수단으로 고려하는 것이 좋습니다.]

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
  [3-way 비교],
  [Deep Agents, OpenCode, Claude Agent SDK],
  [모델 지원, 라이선스, SDK],
  [핵심 기능],
  [공통 도구 + 차별화 기능],
  [샌드박스, 플러거블 백엔드],
  [아키텍처],
  [플러거블 vs 네이티브 vs 최적화],
  [LangGraph, LSP, Claude API],
  [사용 사례],
  [프로덕션, 터미널, 프로토타이핑 등],
  [`recommend_framework()`],
  [생태계],
  [커뮤니티, 문서, 통합, 에디터],
  [LangSmith, ACP],
  [마이그레이션],
  [모델/도구/상태 호환성 확인],
  [점진적 전환],
)


#references-box[
- #link("../docs/deepagents/04-comparison.md")[Comparison with OpenCode and Claude Agent SDK]
]
#chapter-end()
