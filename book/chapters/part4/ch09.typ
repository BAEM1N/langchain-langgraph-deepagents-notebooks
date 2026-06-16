// Auto-generated from 09_comparison.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(9, "외부 프레임워크 비교")

== 학습 목표
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
모델 설정 완료: gpt-4.1
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. 비교 개요

AI 에이전트 프레임워크를 선택할 때는 _모델 지원_, _아키텍처_, _생태계_, _라이선스_ 등 여러 요소를 따져봐야 합니다.

세 가지 주요 프레임워크를 비교합니다:

- _LangChain Deep Agents_ — 모델 무관(model-agnostic) 에이전트 하네스
- _OpenCode_ — 터미널/데스크톱/IDE 기반 코딩 에이전트
- _Claude Agent SDK_ — Anthropic의 Claude 전용 에이전트 SDK

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. Deep Agents vs OpenCode vs Claude Agent SDK

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

=== 공통 기능
세 프레임워크 모두 다음 기능을 지원합니다:
- 파일 작업 (읽기, 쓰기, 편집)
- 쉘 명령 실행
- 검색 기능 (grep, glob)
- 계획 기능 (태스크 리스트)
- Human-in-the-Loop (권한 프레임워크는 상이)

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
  [파일·쉘·검색·계획],
  [파일·쉘·검색·계획],
  [파일·쉘·검색·계획],
  [_샌드박스 통합_],
  [통합 도구로 사용 가능 (Modal/Daytona/Runloop/LangSmith/AgentCore)],
  [없음],
  [없음],
  [_플러거블 백엔드_],
  [스토리지·파일시스템 (StateBackend/StoreBackend/FilesystemBackend/CompositeBackend)],
  [없음],
  [없음],
  [_가상 파일시스템_],
  [플러거블 백엔드 + 멀티모달 read_file],
  [없음],
  [없음],
  [_네이티브 트레이싱_],
  [LangSmith],
  [없음],
  [없음],
)

=== 1. Execution Model — 핵심 차별점

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[축],
  text(weight: "bold")[Deep Agents],
  text(weight: "bold")[Claude Agent SDK],
  [실행 backend],
  [_Pluggable_ (local, virtual, remote, custom)],
  [Local filesystem 한정],
  [에이전트 위치],
  [샌드박스 내부 또는 외부에서 원격 명령 실행],
  [샌드박스 내부 + local FS],
)

Deep Agents는 "에이전트가 샌드박스 _안에서_ 돌든 _밖에서_ 원격으로 명령을 돌리든" 둘 다 지원합니다. Claude Agent SDK는 sandbox-internal + local filesystem으로 한정됩니다.

=== 2. Deployment & Multi-Tenancy — 핵심 차별점

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[축],
  text(weight: "bold")[Deep Agents],
  text(weight: "bold")[Claude Agent SDK],
  [Managed deployment],
  [LangSmith 제공],
  [직접 구축 필요],
  [Self-hosted],
  [Docker 공식 지원],
  [직접 구축 필요],
  [Multi-tenant],
  [scoped threads, per-user sandboxes, RBAC 빌트인],
  [서버·인증·스트리밍 직접 구현],
)

Claude Agent SDK는 "the server, auth, and streaming layer"를 사용자가 직접 만들어야 합니다. Deep Agents는 LangSmith 매니지드 + Docker 자체호스팅 모두 제공합니다.

=== 3. Per-Model Configuration — 핵심 차별점

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[축],
  text(weight: "bold")[Deep Agents],
  text(weight: "bold")[Claude Agent SDK],
  [설정 방식],
  [_Harness profiles_ (provider/model 키로 자동 적용)],
  [Code-based tuning],
  [라이선스],
  [MIT],
  [MIT],
)

Deep Agents의 `HarnessProfile`은 provider/model별 system prompt suffix, 도구 visibility, 제외 미들웨어 등을 자동 적용합니다. Claude Agent SDK는 코드에서 직접 분기해야 합니다.


#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. 아키텍처 비교

=== LangChain Deep Agents
- _플러거블 스토리지 백엔드_ — 상태, 파일시스템, 스토어를 독립적으로 구성
- _가상 파일시스템_ — 로컬, 인메모리, 샌드박스 백엔드 교체 가능
- _LangGraph 기반_ — 그래프 실행 엔진으로 복잡한 워크플로 지원
- _미들웨어 시스템_ — 에이전트 동작을 세밀하게 커스터마이징

=== OpenCode
- _터미널 네이티브_ — 가볍고 빠른 시작
- _75+ 모델 제공자_ — Ollama를 통한 로컬 모델 지원
- _LSP 통합_ — 코드 편집에 특화된 에디터 기능

=== Claude Agent SDK
- _Claude 최적화_ — Claude 모델에 특화된 기능
- _타임 트래블_ — 상태 분기(branching) 지원
- _간결한 API_ — 빠른 프로토타이핑에 적합

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. 사용 사례별 추천

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

#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. 마이그레이션 고려사항

프레임워크 간 마이그레이션 시 확인할 핵심 사항:

=== 공통 고려사항
+ _모델 호환성_ — 사용 중인 모델이 대상 프레임워크에서 지원되는지 확인
+ _도구 호환성_ — 커스텀 도구의 인터페이스 변환 필요
+ _상태 관리_ — 체크포인트/메모리 마이그레이션 방법 확인
+ _옵저버빌리티_ — 트레이싱/로깅 솔루션 대체 방안

=== Deep Agents로 마이그레이션 시 장점
- _LangChain 도구 재사용_ — 기존 LangChain 도구를 그대로 사용 가능
- _LangGraph 호환_ — LangGraph 그래프와 연동 가능
- _점진적 마이그레이션_ — 기존 코드를 단계적으로 전환 가능

=== 주의사항
- Claude Agent SDK에서 마이그레이션 시 Claude 전용 기능은 대체 구현 필요
- OpenCode에서 마이그레이션 시 터미널 UI 로직 분리 필요

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
  [_Execution Model_],
  [에이전트가 sandbox 내부/외부 어디서나 실행 vs sandbox-internal 한정],
  [Pluggable backend],
  [_Deployment & Multi-Tenancy_],
  [LangSmith 매니지드 + Docker + 빌트인 multi-tenant],
  [scoped threads, RBAC],
  [_Per-Model Configuration_],
  [Harness profiles vs code-based tuning],
  [`HarnessProfile`, `register_harness_profile`],
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
