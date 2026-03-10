// Auto-generated from 09_production.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(9, "프로덕션 배포", subtitle: "- 테스트, 관측성, 배포")

Part 5의 마지막 장입니다. 앞선 장들에서 미들웨어, 멀티에이전트, 컨텍스트 엔지니어링, RAG, SQL, 데이터 분석, 보이스 에이전트를 학습했습니다. 이 모든 에이전트를 실제 사용자에게 제공하려면 _테스트 → 관측성 → 배포_의 프로덕션 파이프라인이 필수입니다. 에이전트를 프로덕션에 배포하기 위한 전체 파이프라인을 다룹니다. 단위 테스트와 LangSmith 평가로 품질을 보장하고, 트레이싱으로 관측성을 확보한 뒤, LangGraph Platform으로 배포합니다.

#code-block(`````python
개발 -> 테스트 (단위 + 평가) -> 관측성 (트레이싱) -> 배포 (LangGraph Platform)
`````)

=== 왜 에이전트에 특화된 프로덕션 파이프라인이 필요한가?

에이전트는 전통적인 소프트웨어와 다른 특성을 갖습니다:

- _비결정적 실행_: 동일한 입력에도 다른 도구 호출 순서, 다른 응답을 생성할 수 있음
- _상태 유지_: 대화 기록과 체크포인트를 관리하는 장기 실행 프로세스
- _다중 컴포넌트_: LLM, 도구, 메모리, 체크포인터 등 여러 시스템이 연동

따라서 단순한 단위 테스트를 넘어 _궤적(trajectory) 평가_, _LLM-as-Judge_, _트레이스 기반 모니터링_ 등 에이전트 전용 품질 보장 기법이 필요합니다.

#learning-header()
이 노트북을 완료하면 다음을 수행할 수 있습니다:

+ _단위 테스트_ -- `GenericFakeChatModel`로 LLM 응답을 모킹하여 결정적 테스트를 작성할 수 있다
+ _LangSmith 평가_ -- 데이터셋 생성, 평가자 정의, 자동화된 에이전트 평가를 수행할 수 있다
+ _트레이스 분석_ -- LangSmith 트레이싱으로 레이턴시, 토큰 사용량, 에러를 추적할 수 있다
+ _LangGraph Studio_ -- 시각적 디버깅 도구로 에이전트 실행 흐름을 분석할 수 있다
+ _배포 옵션_ -- LangGraph Platform, 셀프호스트, Cloud 배포 간 차이를 이해할 수 있다
+ _langgraph.json_ -- 배포 설정 파일을 구성하고 배포 명령어를 실행할 수 있다

== 9.1 환경 설정

테스트, 관측성, 배포에 필요한 패키지를 설치합니다. 이 장에서는 `pytest`, `agentevals`, `langsmith`, `langgraph-cli`, `langgraph-sdk`를 활용합니다. 각 패키지는 프로덕션 파이프라인의 서로 다른 단계를 담당합니다.

에이전트를 실제 서비스로 운영하기 위해서는 "동작한다"는 것만으로는 부족합니다. _얼마나 잘 동작하는지_, _언제 문제가 발생하는지_, _어떻게 확장할 것인지_를 체계적으로 관리해야 합니다. 이것이 프로덕션 파이프라인의 핵심 목적입니다.

== 9.2 프로덕션 파이프라인 개요

에이전트의 비결정적 특성 때문에 전통적인 소프트웨어 테스트만으로는 품질을 보장할 수 없습니다.

#align(center)[#image("../../assets/diagrams/png/production_lifecycle_flow.png", width: 92%, height: 82mm, fit: "contain")]

이 흐름도는 프로덕션 운영을 _개발 → 검증 → 관측 → 배포 → 운영_ 의 닫힌 루프로 보여줍니다. 에이전트는 배포 후에도 계속 프롬프트, 도구, 평가셋이 수정되므로, 마지막 운영 단계가 다시 테스트와 개발로 되돌아가는 구조를 의도적으로 가져가야 합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[단계],
  text(weight: "bold")[목적],
  text(weight: "bold")[도구],
  [_개발_],
  [에이전트 구현 및 로컬 테스트],
  [LangGraph, LangGraph Studio],
  [_테스트_],
  [단위 테스트 + LLM 기반 평가],
  [pytest, agentevals, LangSmith],
  [_관측성_],
  [트레이싱, 메트릭, 에러 추적],
  [LangSmith Tracing],
  [_배포_],
  [프로덕션 환경 배포],
  [LangGraph Platform],
)

=== 테스트 전략

에이전트 테스트는 두 가지 접근을 병행해야 합니다:

+ _개발 단계_ — 로컬 재현성과 회귀 검증 확보
+ _평가 단계_ — 실제 궤적과 답변 품질을 데이터셋으로 측정
+ _추적 단계_ — 운영 중 실패 사례와 비용 상승을 트레이스로 발견
+ _배포 단계_ — 설정, 체크포인터, 환경 변수까지 함께 검증

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[유형],
  text(weight: "bold")[특징],
  text(weight: "bold")[적합 대상],
  [_단위 테스트_],
  [`GenericFakeChatModel`로 LLM 응답을 모킹하여 격리된 결정적 테스트 수행. API 호출 없이 빠르게 실행],
  [개별 도구, 파서, 프롬프트 포맷팅, 상태 변환 로직],
  [_통합 테스트_],
  [실제 네트워크 호출로 컴포넌트 간 협업 검증. `agentevals`의 궤적 평가로 에이전트 행동 패턴 분석],
  [전체 에이전트 흐름, 도구 호출 시퀀스, 최종 응답 품질],
)

에이전트 시스템은 다중 컴포넌트가 체이닝되어 동작하므로, 일반적으로 통합 테스트의 비중이 더 높습니다. 단위 테스트로 개별 컴포넌트의 정확성을 확인하고, 통합 테스트로 전체 흐름의 품질을 평가합니다.

단위 테스트로 개별 컴포넌트를 검증한 다음, 전체 에이전트의 행동 패턴을 평가하는 통합 테스트가 필요합니다. LangSmith는 에이전트 전용 평가 인프라를 제공합니다.

단위 테스트가 개별 컴포넌트의 정확성을 검증한다면, LangSmith 평가는 에이전트의 _전체 행동 패턴_을 평가합니다. 전통적인 소프트웨어에서는 입출력 비교로 충분하지만, 에이전트는 같은 결과에 다른 경로로 도달할 수 있으므로 _궤적 기반 평가_가 필수적입니다.

== 9.3 에이전트 테스트 -- LangSmith 평가

`agentevals` 패키지는 에이전트 궤적(trajectory) 전용 평가자를 제공합니다.

#tip-box[LangSmith 평가를 CI/CD 파이프라인에 통합하면, 코드 변경이나 프롬프트 수정 후 자동으로 에이전트 품질을 검증할 수 있습니다. 데이터셋에 다양한 시나리오(정상 케이스, 엣지 케이스, 다국어 입력 등)를 포함하여 회귀 테스트를 구성하세요. 평가 결과의 점수 추이를 모니터링하면 품질 저하를 조기에 감지할 수 있습니다.] 궤적이란 에이전트가 최종 응답에 도달하기까지의 모든 단계(도구 호출, 중간 추론, 의사결정)를 의미합니다. 전통적인 입출력 비교 테스트와 달리, 궤적 평가는 에이전트가 _올바른 과정_을 거쳤는지까지 검증합니다. 궤적이란 에이전트가 최종 응답에 도달하기까지의 모든 단계(도구 호출, 중간 추론, 의사결정)를 의미합니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[전략],
  text(weight: "bold")[설명],
  text(weight: "bold")[장점],
  text(weight: "bold")[단점],
  [_Trajectory Match_],
  [기대 시퀀스와 단계별 비교. 미리 정의한 참조 궤적과 에이전트의 실제 궤적을 매칭],
  [정확한 검증, 재현 가능],
  [구체적 기대값 필요, 유연성 낮음],
  [_LLM-as-Judge_],
  [LLM이 궤적을 루브릭(평가 기준) 기반으로 정성 평가. 도구 사용 적절성, 응답 정확성 등을 자동 판단],
  [유연한 평가, 복잡한 시나리오 대응],
  [추가 LLM 비용, 평가 자체의 비결정성],
)

=== Trajectory Match 모드

에이전트의 도구 호출 순서에 대한 기대 수준을 4단계로 조절할 수 있습니다:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[설명],
  text(weight: "bold")[사용 시점],
  [`strict`],
  [메시지와 도구 호출 순서가 참조와 완전히 동일해야 통과],
  [순서가 중요한 워크플로 (예: 인증 -\\\> 조회 -\\\> 업데이트)],
  [`unordered`],
  [동일한 도구들을 호출했으면 순서 무관하게 통과],
  [독립적인 도구 호출이 여러 개인 경우],
  [`subset`],
  [에이전트가 참조 도구만 호출 (추가 도구 호출 없음)],
  [불필요한 도구 호출을 방지하고 싶을 때],
  [`superset`],
  [에이전트가 참조 도구를 최소한 포함 (추가 호출 허용)],
  [핵심 도구 호출만 보장하고 싶을 때],
)

#code-block(`````python
try:
    from langsmith import Client

    ls_client = Client()

    dataset = ls_client.create_dataset("agent-eval-v1")
    ls_client.create_examples(
        inputs=[{"query": "LangGraph란 무엇인가요?"}],
        outputs=[{"expected": "에이전트를 위한 프레임워크"}],
        dataset_id=dataset.id,
    )
    print("데이터셋 생성됨:", dataset.name)
except Exception as e:
    print(f"LangSmith 미설정 (건너뜀): {e}")
    ls_client = None
    dataset = None
`````)
#output-block(`````
LangSmith 미설정 (건너뜀): Authentication failed for /datasets. HTTPError('401 Client Error: Unauthorized for url: https://api.smith.langchain.com/datasets', '{"detail":"Invalid token"}')
`````)

#code-block(`````python
try:
    from agentevals.trajectory import create_trajectory_llm_as_judge

    evaluator = create_trajectory_llm_as_judge(
        rubric=(
            "에이전트가 적절한 도구를 사용했습니까? "
            "최종 답변이 정확했습니까?"
        ),
    )
    print("평가자 생성됨:", type(evaluator).__name__)
except ImportError:
    print("agentevals 미설치. 설치: pip install agentevals")
    evaluator = None
except Exception as e:
    print(f"평가자 생성 건너뜀 (LLM API 키 필요): {e}")
    evaluator = None
`````)
#output-block(`````
평가자 생성 건너뜀 (LLM API 키 필요): create_trajectory_llm_as_judge() got an unexpected keyword argument 'rubric'
`````)

LangSmith 평가가 통합 테스트라면, 단위 테스트는 에이전트의 개별 구성 요소를 격리하여 검증합니다. 특히 도구 함수, 상태 변환 로직, 프롬프트 포맷팅은 단위 테스트로 빠르게 검증해야 하는 핵심 대상입니다.

== 9.4 단위 테스트 패턴

`GenericFakeChatModel`을 사용하면 API 호출 없이 LLM 응답을 모킹하여 결정적 테스트를 작성할 수 있습니다. 응답 이터레이터를 받아 호출마다 하나씩 반환합니다.

#warning-box[`GenericFakeChatModel`은 _도구 호출 응답_도 모킹할 수 있지만, 이 경우 AIMessage의 `tool_calls` 필드를 올바르게 구성해야 합니다. 도구 호출 형식이 맞지 않으면 에이전트 루프가 정상적으로 동작하지 않으므로, 실제 LLM 응답의 형식을 먼저 확인한 후 모킹 데이터를 작성하세요.]

=== 왜 모킹이 필요한가?

에이전트 테스트에서 실제 LLM API를 호출하면 다음 문제가 발생합니다:
- _비결정적 결과_: 동일 입력에도 매번 다른 응답이 올 수 있어 테스트 재현이 어려움
- _비용_: 테스트를 실행할 때마다 API 비용 발생
- _속도_: 네트워크 지연으로 테스트 속도 저하
- _가용성_: API 장애 시 테스트 실패

`GenericFakeChatModel`은 미리 정의한 응답을 순서대로 반환하므로, _결정적이고 빠르며 무료인_ 테스트를 작성할 수 있습니다. 스트리밍 패턴도 지원하여 `astream()` 기반 코드도 테스트 가능합니다.

=== 상태 지속성 테스트

`InMemorySaver` 체크포인터를 사용하면 여러 대화 턴에 걸친 상태 의존적 행동을 테스트할 수 있습니다. `thread_id`를 지정하여 같은 대화 컨텍스트를 유지하면서 여러 호출의 누적 상태를 검증합니다.

#code-block(`````python
def search_tool(query: str) -> str:
    """웹에서 정보를 검색합니다."""
    return f"검색 결과: {query}"

def test_search_tool():
    """검색 도구가 예상 형식을 반환하는지 테스트합니다."""
    result = search_tool("test query")
    assert isinstance(result, str) and len(result) > 0
    print("통과: test_search_tool")

test_search_tool()
`````)
#output-block(`````
통과: test_search_tool
`````)

=== HTTP 요청 녹화/재생

CI/CD에서 API 비용을 줄이기 위해 `vcrpy`와 `pytest-recording`으로 HTTP 요청을 녹화하고 재생할 수 있습니다. 첫 실행 시 실제 API 호출을 녹화(cassette 파일로 저장)하고, 이후 실행에서는 녹화된 응답을 재생하여 네트워크 호출 없이 테스트합니다.

이 방식의 장점:
- _첫 실행_: 실제 API와의 통합을 검증 (통합 테스트 역할)
- _이후 실행_: 녹화된 응답으로 빠르고 결정적인 테스트 (단위 테스트 역할)
- _CI/CD_: API 키 없이도 테스트 실행 가능

#code-block(`````python
import pytest

@pytest.fixture(scope="module")
def vcr_config():
    return {"record_mode": "once"}

@pytest.mark.vcr()
def test_agent_with_recorded_responses():
    result = agent.invoke("What is LangGraph?")
    assert "framework" in result.lower()
`````)

테스트는 배포 _전_의 품질 보장입니다. 배포 _후_에는 실제 사용자 트래픽에 대한 지속적 모니터링이 필요합니다. 이를 관측성(Observability)이라 합니다.

테스트는 배포 _전_의 품질 보장 수단입니다. 하지만 에이전트는 실제 사용자의 다양한 입력에 노출되면 예상치 못한 행동을 보일 수 있습니다. 배포 _후_ 지속적으로 에이전트의 건강 상태를 모니터링하는 것이 관측성(Observability)입니다.

== 9.5 관측성 -- LangSmith 트레이싱

LangSmith 트레이싱은 에이전트 실행의 _모든 단계_를 기록합니다.

#tip-box[트레이싱은 환경 변수 2개만으로 활성화되며, 코드 수정이 전혀 필요 없습니다. 프로덕션에서는 항상 트레이싱을 켜두되, `tracing_context`로 _특정 실행만_ 상세 트레이싱하는 것이 비용과 성능의 균형을 맞추는 좋은 전략입니다. 예를 들어, 정상 요청은 기본 트레이싱만, 오류 발생 시에만 상세 트레이싱을 활성화할 수 있습니다.] 트레이스(trace)는 초기 사용자 입력부터 최종 응답까지, 모든 모델 호출, 도구 사용, 의사결정 포인트를 포함하는 에이전트 실행의 완전한 기록입니다.

=== 트레이스에 기록되는 정보

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[설명],
  [_입력/출력_],
  [각 단계의 입력 데이터와 출력 결과],
  [_모델 호출_],
  [프롬프트, 응답, 모델 파라미터],
  [_도구 호출_],
  [호출된 도구, 인자, 반환값],
  [_레이턴시_],
  [각 단계별 소요 시간],
  [_토큰 사용량_],
  [입력/출력 토큰 수],
  [_에러_],
  [실패한 단계와 에러 메시지],
)

=== 활성화 방법

환경 변수 2개만 설정하면 _추가 코드 없이_ 자동 트레이싱됩니다:

#code-block(`````bash
export LANGSMITH_TRACING=true
export LANGSMITH_API_KEY=<your-api-key>
`````)

`create_agent`로 생성한 에이전트는 환경 변수 설정 시 자동으로 실행 데이터를 LangSmith에 전송합니다. LangChain의 모든 컴포넌트(LLM, 체인, 도구 등)가 내장 계측(instrumentation)을 포함하고 있어 별도의 코드 수정이 필요 없습니다.

=== 선택적 트레이싱

`tracing_context`를 사용하면 특정 코드 블록만 선택적으로 트레이싱할 수 있습니다. 이를 통해 디버깅이 필요한 부분만 집중적으로 모니터링하거나, 프로젝트별로 트레이스를 분리할 수 있습니다.

== 9.6 트레이스 분석

LangSmith 대시보드에서 트레이스를 분석하여 프로덕션 에이전트의 품질을 모니터링합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[메트릭],
  text(weight: "bold")[설명],
  text(weight: "bold")[확인 포인트],
  [_Latency_],
  [각 단계별 소요 시간],
  [병목 구간 식별 (어느 노드가 가장 느린지)],
  [_Token Usage_],
  [입력/출력 토큰 수],
  [비용 최적화 (프롬프트 길이 조절, 불필요한 컨텍스트 제거)],
  [_Error Rate_],
  [실패한 실행 비율],
  [안정성 모니터링 (특정 도구의 실패율, LLM 타임아웃 등)],
  [_Tool Call Frequency_],
  [도구별 호출 빈도],
  [에이전트 행동 패턴 분석 (과도한 도구 호출, 미사용 도구 식별)],
)

=== 태그와 메타데이터 활용

`config` 파라미터나 `tracing_context`로 커스텀 태그와 메타데이터를 추가하여 트레이스를 분류하고 필터링할 수 있습니다. 프로덕션 환경에서 유용한 태그/메타데이터 예시:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[태그/메타데이터],
  text(weight: "bold")[용도],
  [_버전 태그_ (`v2.1`)],
  [A/B 테스트, 버전별 성능 비교],
  [_실험 태그_ (`experiment-A`)],
  [프롬프트 변경 등 실험 추적],
  [_사용자 티어_ (`premium`)],
  [사용자 그룹별 품질 모니터링],
  [_리전_ (`kr`)],
  [지역별 레이턴시 분석],
)

=== 프로젝트 관리

프로젝트는 두 가지 방식으로 설정할 수 있습니다:
- _정적_: `LANGSMITH_PROJECT` 환경 변수로 기본 프로젝트 지정
- _동적_: `tracing_context(project_name=...)`으로 코드 블록별 프로젝트 분리

#code-block(`````python
try:
    from langsmith import tracing_context

    with tracing_context(
        project_name="production-agent",
        tags=["v2.1", "experiment-A"],
        metadata={"user_tier": "premium", "region": "kr"},
    ):
        print("태그된 트레이싱 활성화됨")
except Exception as e:
    print(f"LangSmith 트레이싱 사용 불가: {e}")
`````)
#output-block(`````
태그된 트레이싱 활성화됨
`````)

== 9.7 LangGraph Studio -- 시각적 디버깅

LangGraph Studio는 에이전트의 실행 흐름을 _시각적으로_ 디버깅할 수 있는 무료 도구입니다. 로컬 머신에서 에이전트를 개발하고 테스트하는 데 최적화되어 있습니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[설명],
  [_그래프 시각화_],
  [에이전트의 노드/엣지 구조를 실시간 확인. 현재 실행 중인 노드를 하이라이트],
  [_단계별 실행_],
  [각 노드의 입출력 데이터를 검사하며 디버깅. 프롬프트, 도구 호출, 결과를 단계별로 확인],
  [_상태 검사_],
  [에이전트의 전체 상태를 시각적으로 탐색. 메시지 히스토리, 체크포인트 데이터 포함],
  [_실시간 스트리밍_],
  [에이전트 실행 과정을 실시간으로 관찰. 토큰/레이턴시 메트릭 제공],
)

=== 로컬 개발 서버 설정

Studio를 사용하려면 LangGraph CLI로 로컬 개발 서버를 시작합니다:

#code-block(`````bash
# LangGraph CLI 설치 (Python 3.11+ 필요)
pip install --upgrade "langgraph-cli[inmem]"

# 개발 서버 시작
langgraph dev
`````)

서버가 시작되면 `https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024` 에서 Studio UI에 접근할 수 있습니다.

=== Studio에서 확인 가능한 정보

- 에이전트에게 전송되는 프롬프트
- 각 도구 호출과 그 결과
- 최종 출력
- 중간 상태 (검사 및 수정 가능)
- 토큰 사용량과 레이턴시 메트릭

테스트와 관측성이 준비되었다면, 마지막 단계는 실제 배포입니다. 에이전트 배포는 전통적인 웹 애플리케이션 배포와 다른 고려사항이 있습니다.

== 9.8 배포 옵션

에이전트는 _상태를 유지하는 장기 실행 프로세스_이므로 일반 웹앱 호스팅과 다른 접근이 필요합니다.

#tip-box[배포 직전 체크포인트는 4가지만 확인하면 됩니다: `1)` 상태 저장소가 실제 영속적인가, `2)` 트레이싱이 켜져 있는가, `3)` 재시도/타임아웃 정책이 정의되었는가, `4)` 배포 후 동일한 평가셋으로 스모크 테스트를 다시 돌렸는가.] 체크포인터를 통한 상태 영속화, 백그라운드에서의 장시간 실행, WebSocket 기반 스트리밍 등은 전통적인 요청-응답 모델의 웹 호스팅에서는 지원이 어렵습니다. LangGraph Platform은 이러한 에이전트 특유의 요구사항을 처음부터 고려하여 설계된 배포 인프라입니다.

#warning-box[LangGraph Cloud에 배포할 때 `.env` 파일에 포함된 API 키는 Cloud 환경의 환경 변수로 _별도로_ 설정해야 합니다. `langgraph.json`의 `env` 필드는 로컬 개발 시 사용되며, 클라우드 배포 시에는 LangSmith 대시보드의 환경 변수 설정에서 관리합니다. API 키를 GitHub 리포지토리에 커밋하지 않도록 주의하세요.] 전통적인 stateless 웹 애플리케이션 호스팅(예: Vercel, Heroku)은 에이전트의 지속적 상태 관리, 백그라운드 실행, 체크포인팅에 적합하지 않습니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[옵션],
  text(weight: "bold")[설명],
  text(weight: "bold")[적합 대상],
  [_LangGraph Cloud_],
  [LangSmith 관리형 호스팅. GitHub 연결만으로 자동 빌드/배포],
  [빠른 프로토타이핑, 소규모 팀],
  [_Self-Hosted_],
  [자체 인프라에서 Docker 컨테이너로 실행],
  [데이터 주권, 엔터프라이즈, 규제 환경],
  [_Hybrid_],
  [클라우드 관리 + 자체 런타임],
  [관리 편의성 + 데이터 제어 양립],
)

=== 배포 요구사항

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[설명],
  [_GitHub 저장소_],
  [코드 호스팅 (공개/비공개 모두 지원)],
  [_LangSmith 계정_],
  [무료 가입 가능 (smith.langchain.com)],
  [_langgraph.json_],
  [의존성, 그래프, 환경 변수를 정의하는 배포 설정 파일],
)

=== LangGraph Cloud 배포 프로세스

+ LangSmith에 로그인 후 Deployments 페이지로 이동
+ "+ New Deployment" 클릭
+ GitHub 계정 연결 (비공개 저장소의 경우)
+ 저장소 선택 후 제출 (약 15분 소요)
+ 배포 완료 후 API URL 복사하여 클라이언트에서 사용

== 9.9 langgraph.json 설정

`langgraph.json`은 배포의 핵심 설정 파일입니다. 의존성, 그래프 엔트리포인트, 환경 변수를 정의합니다. 이 파일이 프로젝트 루트에 있어야 LangGraph CLI와 Cloud 배포가 정상 동작합니다.

#code-block(`````python
import json

langgraph_config = {
    "dependencies": ["."],
    "graphs": {"agent": "./src/agent.py:graph"},
    "env": ".env",
}
print(json.dumps(langgraph_config, indent=2))
`````)
#output-block(`````
{
  "dependencies": [
    "."
  ],
  "graphs": {
    "agent": "./src/agent.py:graph"
  },
  "env": ".env"
}
`````)

=== 설정 항목 상세

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[타입],
  text(weight: "bold")[설명],
  [`dependencies`],
  [`list[str]`],
  [Python 패키지 의존성. `.`은 현재 디렉터리의 `pyproject.toml`을 참조],
  [`graphs`],
  [`dict`],
  [그래프 이름과 모듈 경로 매핑. `"모듈경로:변수명"` 형식],
  [`env`],
  [`str`],
  [환경 변수 파일 경로 (`.env` 형식). API 키 등 민감 정보 포함],
)

=== 그래프 엔트리포인트

`graphs` 필드의 값은 `"./경로/파일.py:변수명"` 형식입니다. 변수는 `CompiledGraph` 인스턴스여야 합니다. LangGraph의 Graph API(`StateGraph`)와 Functional API(`@entrypoint`) 모두 사용 가능합니다.

==== Graph API 예시

#code-block(`````python
# src/agent.py
from langgraph.prebuilt import create_react_agent

graph = create_react_agent(
    model="claude-sonnet-4-6",
    tools=[search_tool],
    checkpointer=True,
)
`````)

==== Functional API 예시

LangGraph의 Functional API를 사용하면 기존 Python 코드에 최소한의 변경으로 영속성, 메모리, 스트리밍을 통합할 수 있습니다. `@entrypoint` 데코레이터가 워크플로의 시작점을 정의하고, `@task` 데코레이터가 개별 작업 단위를 나타냅니다.

#code-block(`````python
# src/agent.py
from langgraph.func import entrypoint, task

@task
def process_query(query: str) -> str:
    return f"처리 완료: {query}"

@entrypoint(checkpointer=checkpointer)
def graph(inputs: dict) -> str:
    result = process_query(inputs["query"])
    return result.result()
`````)

Functional API의 핵심 특징:
- _표준 Python 제어 흐름_ 사용 (if/for 등) -- 명시적 그래프 구조 불필요
- _함수 스코프 상태 관리_ -- 별도의 State 선언이나 reducer 설정 불필요
- _태스크 결과 체크포인팅_ -- 재실행 시 이전에 완료된 태스크 결과를 자동 재사용
- _입출력 JSON 직렬화 필수_ -- 체크포인터 사용 시 모든 데이터가 직렬화 가능해야 함

== 9.10 배포 명령어

LangGraph CLI를 사용한 빌드, 로컬 서버, 클라우드 배포 명령어입니다.

=== 1. Docker 이미지 빌드

`langgraph.json` 설정을 기반으로 Docker 이미지를 생성합니다:

#code-block(`````bash
langgraph build -t my-agent:latest
`````)

=== 2. 로컬 서버 실행

로컬에서 에이전트를 실행하여 테스트합니다. Studio UI와 연동하여 시각적 디버깅이 가능합니다:

#code-block(`````bash
# 프로덕션 모드 (Docker 기반)
langgraph up --config langgraph.json

# 개발 모드 (인메모리, 빠른 시작)
langgraph dev
`````)

=== 3. 클라우드 배포

LangSmith 대시보드에서:
+ Deployments -\> "+ New Deployment"
+ GitHub 저장소 연결
+ 리포지토리 선택 후 제출 (약 15분 소요)
+ 배포 완료 후 API URL 복사

=== Python SDK로 배포된 에이전트 접근

`langgraph-sdk`를 사용하면 배포된 에이전트와 프로그래밍 방식으로 통신할 수 있습니다. 스트리밍, 스레드 관리, 상태 조회 등 모든 기능을 SDK로 제어합니다.

#code-block(`````python
try:
    from langgraph_sdk import get_sync_client

    api_key = os.environ.get("LANGSMITH_API_KEY", "")
    if not api_key:
        print("LANGSMITH_API_KEY 미설정. 클라이언트 연결 건너뜀.")
    else:
        client = get_sync_client(
            url="https://your-deployment.langsmith.com",
            api_key=api_key,
        )
        print("클라이언트 연결됨:", type(client).__name__)
except Exception as e:
    print(f"LangGraph SDK 클라이언트 사용 불가: {e}")
`````)
#output-block(`````
LANGSMITH_API_KEY 미설정. 클라이언트 연결 건너뜀.
`````)

=== REST API로 접근

배포된 에이전트는 REST API로도 접근할 수 있습니다. 이를 통해 어떤 프로그래밍 언어/프레임워크에서도 에이전트와 통신 가능합니다:

#code-block(`````bash
curl --request POST \
  --url <DEPLOYMENT_URL>/runs/stream \
  --header 'Content-Type: application/json' \
  --header 'X-Api-Key: <LANGSMITH_API_KEY>' \
  --data '{
    "assistant_id": "agent",
    "input": {
      "messages": [
        {"role": "user", "content": "안녕하세요!"}
      ]
    },
    "stream_mode": "updates"
  }'
`````)

주요 엔드포인트:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[엔드포인트],
  text(weight: "bold")[메서드],
  text(weight: "bold")[설명],
  [`/runs/stream`],
  [POST],
  [스트리밍 실행],
  [`/runs`],
  [POST],
  [동기 실행],
  [`/threads`],
  [POST],
  [새 스레드 생성],
  [`/threads/{id}/state`],
  [GET],
  [스레드 상태 조회],
)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[주제],
  text(weight: "bold")[핵심 내용],
  [_테스트 전략_],
  [단위 테스트(`GenericFakeChatModel`) + 통합 테스트(`agentevals`) 병행],
  [_LangSmith 평가_],
  [Trajectory Match (strict/unordered/subset/superset), LLM-as-Judge],
  [_관측성_],
  [`LANGSMITH_TRACING=true` + `LANGSMITH_API_KEY`로 자동 트레이싱],
  [_트레이스 분석_],
  [Latency, Token Usage, Error Rate, Tool Call Frequency],
  [_LangGraph Studio_],
  [시각적 그래프 디버깅, 단계별 상태 검사],
  [_배포 옵션_],
  [Cloud (관리형), Self-Hosted (Docker), Hybrid],
  [_langgraph.json_],
  [`dependencies`, `graphs`, `env` 3가지 핵심 설정],
  [_배포 명령어_],
  [`langgraph build` -\\\> `langgraph up` -\\\> LangSmith Deploy],
)

Part 5를 통해 v1 마이그레이션부터 프로덕션 배포까지, 에이전트 개발의 전체 라이프사이클을 학습했습니다. Part 6에서는 이 모든 지식을 종합하여 RAG, SQL, 데이터 분석, 머신러닝, 딥 리서치 에이전트를 실전 프로젝트로 구현합니다.

