// Auto-generated from 03_data_analysis_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "데이터 분석 에이전트", subtitle: "코드 실행과 멀티턴 분석")

이전 장의 SQL 에이전트가 정형 쿼리를 실행했다면, 데이터 분석 에이전트는 Python 코드를 직접 작성하고 실행하여 자유로운 분석을 수행합니다. 데이터 분석 에이전트는 사용자의 자연어 요청을 Python 코드로 변환하여 실행하고, 결과를 해석하는 자율 분석 워크플로를 제공합니다. Deep Agents의 코드 실행 샌드박스와 `SummarizationMiddleware`를 활용하여 장시간 분석 세션에서도 컨텍스트를 효율적으로 관리합니다. 이 장에서는 `LocalShellBackend`로 코드 실행 환경을 구성하고, 빌트인 도구(`execute`, `write_todos`)와 커스텀 도구를 조합하여 스트리밍 기반 멀티턴 분석 에이전트를 구축합니다.

#learning-header()
#learning-objectives([LocalShellBackend로 코드 실행 환경을 구성한다], [커스텀 도구와 빌트인 도구(write_todos, execute)를 조합한다], [스트리밍과 멀티턴 대화로 반복적 분석을 수행한다], [v1 미들웨어(SummarizationMiddleware, ModelCallLimitMiddleware)를 적용한다])

== 개요

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [_프레임워크_],
  [Deep Agents],
  [_핵심 컴포넌트_],
  [LocalShellBackend, InMemorySaver],
  [_빌트인 도구_],
  [`execute` (코드 실행), `write_todos` (계획 작성)],
  [_패턴_],
  [스트리밍 (`stream(subgraphs=True)`) + 멀티턴 대화],
  [_스킬_],
  [`skills/data-analysis/SKILL.md` — 분석 체크리스트 + 코드 실행 규칙],
)

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY를 .env에 설정하세요"

`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")

`````)

데이터 분석 에이전트의 핵심 설계 결정은 _코드 실행 환경 선택_입니다. 에이전트가 작성한 Python 코드를 어디서, 어떤 권한으로 실행할 것인지가 보안과 기능성의 트레이드오프를 결정합니다.

== 1단계: 백엔드 비교

Deep Agents는 다양한 백엔드를 지원합니다. 데이터 분석에는 코드 실행이 필요하므로 `LocalShellBackend`를 사용합니다. 각 백엔드의 파일 접근 범위와 코드 실행 가능 여부를 비교하여 사용 사례에 맞는 백엔드를 선택하세요.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[백엔드],
  text(weight: "bold")[파일 접근],
  text(weight: "bold")[코드 실행],
  text(weight: "bold")[용도],
  [`StateBackend`],
  [상태 내 저장],
  [❌],
  [스크래치패드],
  [`FilesystemBackend`],
  [로컬 디스크],
  [❌],
  [파일 읽기/쓰기],
  [`LocalShellBackend`],
  [로컬 디스크],
  [✅ `execute`],
  [데이터 분석, 코드 실행],
  [Sandboxes (Modal 등)],
  [격리 환경],
  [✅],
  [프로덕션],
)

#tip-box[⚠️ `LocalShellBackend`는 호스트 시스템에서 명령을 실행합니다. 반드시 `virtual_mode=True`를 사용하세요.]


#code-block(`````python
from deepagents.backends import LocalShellBackend

backend = LocalShellBackend(root_dir=".", virtual_mode=True)
`````)

백엔드가 준비되었으니, 에이전트가 분석할 데이터를 준비합니다. 실제 환경에서는 사용자가 파일을 업로드하거나, 에이전트가 API에서 데이터를 가져올 수 있습니다.

== 2단계: 분석용 CSV 파일 생성

에이전트가 `execute`로 pandas 코드를 실행하려면, 파일 시스템에 CSV 파일이 있어야 합니다. `write_file` 빌트인 도구를 통해 에이전트가 직접 파일을 쓸 수도 있지만, 여기서는 미리 준비합니다.

#code-block(`````python
import tempfile, os

# 임시 디렉토리에 CSV 파일 생성
tmp_dir = tempfile.mkdtemp()
csv_path = os.path.join(tmp_dir, "sales.csv")

CSV_DATA = """date,product,region,sales,quantity
2024-01-15,Widget A,서울,150000,30
2024-01-15,Widget B,부산,89000,18
2024-02-10,Widget A,서울,175000,35
2024-02-10,Widget C,대구,62000,12
2024-03-05,Widget B,서울,134000,27
2024-03-05,Widget A,부산,98000,20
2024-03-20,Widget C,서울,71000,14
2024-04-01,Widget A,대구,112000,22"""

with open(csv_path, "w", encoding="utf-8") as f:
    f.write(CSV_DATA.strip())
print(f"CSV 저장: {csv_path}")
`````)
#output-block(`````
CSV 저장: C:\Users\HEESU\AppData\Local\Temp\tmpspv1awp9\sales.csv
`````)

데이터가 준비되었으니, 에이전트가 데이터를 분석할 수 있는 도구를 정의합니다. 데이터 분석 에이전트의 도구 설계에서 핵심은 _에이전트가 자유롭게 코드를 작성하고 실행할 수 있는 환경_을 제공하는 것입니다.

== 3단계: 분석 도구 정의

두 가지 커스텀 도구를 정의합니다:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도구],
  text(weight: "bold")[역할],
  [`get_csv_path`],
  [CSV 파일 경로 반환],
  [`run_pandas`],
  [pandas 코드를 직접 실행하고 결과 반환],
)

#tip-box[`run_pandas`는 에이전트가 작성한 pandas 코드를 `exec()`로 실행합니다. `execute` 빌트인보다 venv 환경에서 안정적입니다.]

#code-block(`````python
from langchain.tools import tool
import io, contextlib

@tool
def get_csv_path() -> str:
    """분석 대상 CSV 파일의 경로를 반환합니다."""
    return csv_path

@tool
def run_pandas(code: str) -> str:
    """pandas Python 코드를 실행합니다. print()로 결과를 출력하세요."""
    import pandas as pd, numpy as np
    buf = io.StringIO()
    ns = {"pd": pd, "np": np, "csv_path": csv_path}
    try:
        with contextlib.redirect_stdout(buf):
            exec(code, ns)
        return buf.getvalue() or "실행 완료 (출력 없음)"
    except Exception as e:
        return f"오류: {e}"
`````)

== 4단계: 에이전트 생성 (v1 미들웨어)

도구와 백엔드가 준비되었으니, `create_deep_agent`로 에이전트를 조립합니다. `SummarizationMiddleware`는 분석 대화가 길어질 때 이전 메시지를 자동으로 요약하여 컨텍스트 윈도우 초과를 방지합니다. `ModelCallLimitMiddleware`는 에이전트가 무한 루프에 빠지는 것을 방지합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[미들웨어],
  text(weight: "bold")[역할],
  [`SummarizationMiddleware`],
  [대화가 길어지면 이전 메시지를 자동 요약하여 컨텍스트 절약],
  [`ModelCallLimitMiddleware`],
  [무한 루프 방지 — 최대 20회 모델 호출 제한],
)

#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import LocalShellBackend
from langgraph.checkpoint.memory import InMemorySaver
from langchain.agents.middleware import (
    SummarizationMiddleware,
    ModelCallLimitMiddleware,
)
from prompts import DATA_ANALYSIS_PROMPT

agent = create_deep_agent(
    model=model,
    tools=[get_csv_path, run_pandas],
    system_prompt=DATA_ANALYSIS_PROMPT,
    backend=LocalShellBackend(root_dir=tmp_dir, virtual_mode=True),
    skills=["/skills/"],
    checkpointer=InMemorySaver(),
    middleware=[
        SummarizationMiddleware(model=model, trigger=("messages", 10)),
        ModelCallLimitMiddleware(run_limit=20),
    ],
)
`````)
#output-block(`````
Prompt 'rag-agent-label:production' not found during refresh, evicting from cache.

Prompt 'sql-agent-label:production' not found during refresh, evicting from cache.

Prompt 'data-analysis-agent-label:production' not found during refresh, evicting from cache.

Prompt 'ml-agent-label:production' not found during refresh, evicting from cache.

Prompt 'deep-research-agent-label:production' not found during refresh, evicting from cache.
`````)

에이전트가 생성되었으니, 실제 분석을 수행합니다. 에이전트에게 자연어로 분석 요청을 하면, 에이전트는 자율적으로 코드를 작성하고 실행합니다. 이 과정에서 에이전트의 _계획-실행-반성_ 루프를 관찰할 수 있습니다.

== 5단계: pandas 코드 실행으로 분석

에이전트에게 분석을 요청하면, `get_csv_path`로 파일 경로를 확인한 뒤 `run_pandas`로 pandas 코드를 직접 작성하고 실행합니다. 에이전트는 데이터의 구조를 먼저 파악한 후, 적절한 집계/통계 코드를 생성합니다. 코드 실행 결과에 오류가 발생하면 에이전트가 오류 메시지를 분석하여 코드를 수정하고 재시도합니다.

#tip-box[에이전트가 생성하는 pandas 코드의 품질을 높이려면, 시스템 프롬프트에 "코드 실행 전 항상 `df.head()`와 `df.dtypes`로 데이터 구조를 확인하세요"라는 지시를 추가하세요. 데이터 구조를 모르고 바로 분석 코드를 실행하면 컬럼명 오류, 타입 불일치 등이 자주 발생합니다.]

#code-block(`````python
에이전트 실행 흐름:
1. get_csv_path() → CSV 파일 경로 확인
2. run_pandas("import pandas as pd; ...") → pandas 코드 실행
3. 결과 해석 및 답변 생성
`````)

== 6단계: 멀티턴 후속 질문

같은 `thread_id`를 사용하면 이전 대화의 맥락을 유지한 채 후속 질문을 할 수 있습니다. 에이전트는 이전 분석 결과를 기억합니다. 예를 들어, "지역별 매출 합계를 보여줘" 후에 "가장 높은 지역의 분기별 추이는?"이라고 물으면, 에이전트는 이전 결과에서 최고 매출 지역이 서울이었음을 기억하고 서울의 분기별 데이터를 분석합니다.

#warning-box[`SummarizationMiddleware`를 사용하지 않으면 멀티턴 대화가 길어질수록 메시지 히스토리가 누적되어 컨텍스트 윈도우를 초과할 수 있습니다. 특히 `run_pandas` 도구의 코드와 결과가 매 턴마다 추가되므로, 10턴 이상의 분석 세션에서는 `SummarizationMiddleware(trigger=("messages", 10))`로 이전 메시지를 자동 요약하여 토큰 사용량을 관리하세요.]

멀티턴 대화의 기반이 되는 빌트인 도구들을 정리합니다. 이 도구들은 백엔드 유형에 따라 자동으로 에이전트에 제공됩니다.

== 빌트인 도구 정리

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[빌트인 도구],
  text(weight: "bold")[백엔드],
  text(weight: "bold")[설명],
  [`read_file`],
  [모든 백엔드],
  [파일 읽기 (이미지 포함)],
  [`write_file`],
  [모든 백엔드],
  [파일 쓰기],
  [`edit_file`],
  [모든 백엔드],
  [파일 편집 (find-and-replace)],
  [`ls`],
  [모든 백엔드],
  [디렉토리 목록],
  [`glob`],
  [모든 백엔드],
  [패턴 기반 파일 검색],
  [`grep`],
  [모든 백엔드],
  [파일 내용 검색],
  [`execute`],
  [LocalShell, Sandbox],
  [셸 명령 실행],
  [`write_todos`],
  [모든 백엔드],
  [작업 계획 작성/업데이트],
)


== 데이터 분석 실행 흐름

#code-block(`````python
1. [Planning]    write_todos — 분석 계획 작성
2. [Reading]     read_file — CSV 구조 파악
3. [Execution]   execute — pandas 코드 실행
4. [Iteration]   추가 분석, 후속 질문
5. [Delivery]    결과 정리 및 보고
`````)


#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[핵심],
  [_백엔드_],
  [`LocalShellBackend(virtual_mode=True)` — 코드 실행 가능],
  [_빌트인 도구_],
  [`execute` (코드 실행) + `write_todos` (계획)],
  [_스트리밍_],
  [`stream(subgraphs=True)` — 실행 과정 실시간 관찰],
  [_멀티턴_],
  [`InMemorySaver` + 동일 `thread_id` — 대화 맥락 유지],
)


#references-box[
- `docs/deepagents/tutorials/data-analysis.md`
- `docs/deepagents/06-backends.md`
_다음 단계:_ → #link("./04_ml_agent.ipynb")[04_ml_agent.ipynb]: 머신러닝 에이전트를 구축합니다.
]
#chapter-end()
