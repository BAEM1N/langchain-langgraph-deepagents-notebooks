// Auto-generated from 04_ml_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "머신러닝 에이전트", subtitle: "CSV 기반 자유 ML 워크플로")

== 학습 목표
#learning-objectives([`FilesystemBackend`로 데이터 디렉토리를 설정하고, 에이전트가 자유롭게 파일을 탐색한다], [NB03의 `run_pandas` 패턴을 확장하여 sklearn을 포함하는 `run_ml_code` 도구를 만든다], [에이전트가 빌트인 도구(`ls`, `read_file`, `glob`)로 데이터를 탐색하고, `run_ml_code`로 분석한다], [멀티턴 대화로 EDA → 전처리 → 모델 선택 → 학습 → 평가를 수행한다])

== 개요

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[NB03 (데이터 분석)],
  text(weight: "bold")[NB04 (머신러닝)],
  [_백엔드_],
  [`LocalShellBackend`],
  [`FilesystemBackend`],
  [_데이터_],
  [매출 CSV (8행)],
  [사용자 지정 CSV (데모: 유방암 569행)],
  [_커스텀 도구_],
  [`get_csv_path` + `run_pandas`],
  [`run_ml_code` (sklearn 추가)],
  [_빌트인 도구_],
  [—],
  [`ls`, `read_file`, `glob` (파일 탐색)],
  [_목적_],
  [집계, 통계, 추이 분석],
  [EDA → 전처리 → 모델 학습 → 비교],
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

== NB03 vs NB04: 백엔드와 도구 확장

NB03에서는 `LocalShellBackend` + `run_pandas`로 pandas 코드를 실행했습니다.
NB04에서는 두 가지를 확장합니다:

+ _백엔드_: `FilesystemBackend(root_dir=DATA_DIR)` — 에이전트가 빌트인 도구(`ls`, `read_file`, `glob`)로 데이터 디렉토리를 자유롭게 탐색
+ _도구_: `run_ml_code` — sklearn을 네임스페이스에 추가하여 ML 파이프라인 실행

#code-block(`````python
# NB03: LocalShellBackend + run_pandas
backend = LocalShellBackend(root_dir=tmp_dir, virtual_mode=True)
ns = {"pd": pd, "np": np, "csv_path": csv_path}

# NB04: FilesystemBackend + run_ml_code
backend = FilesystemBackend(root_dir=DATA_DIR, virtual_mode=True)
ns = {"pd": pd, "np": np, "sklearn": sklearn, "DATA_DIR": DATA_DIR}
`````)

#tip-box[`FilesystemBackend`는 `execute` 없이 파일 접근만 제공하므로 `LocalShellBackend`보다 안전합니다.]

== 1단계: 데이터 디렉토리 설정

`DATA_DIR`을 변경하면 _자신의 CSV 데이터_를 사용할 수 있습니다.
에이전트가 `ls`, `glob`, `read_file` 빌트인으로 디렉토리를 탐색하여 어떤 파일이 있는지 파악합니다.

#code-block(`````python
# 예시: 자신의 데이터 디렉토리 사용
DATA_DIR = "/path/to/your/data"
`````)

#code-block(`````python
import tempfile
import pandas as pd
from sklearn.datasets import load_breast_cancer

# ── 데이터 디렉토리 설정 ──────────────────────────────
# 자신의 CSV가 있는 디렉토리로 변경하세요.
# 아래는 데모용으로 breast_cancer 데이터를 CSV로 저장합니다.
DATA_DIR = tempfile.mkdtemp()

# 데모 데이터 생성 (자신의 CSV가 있으면 이 블록을 제거하세요)
data = load_breast_cancer()
df = pd.DataFrame(data.data, columns=data.feature_names)
df["target"] = data.target
df.to_csv(os.path.join(DATA_DIR, "breast_cancer.csv"), index=False)

print(f"DATA_DIR: {DATA_DIR}")
print(f"파일 목록: {os.listdir(DATA_DIR)}")
`````)

== 2단계: FilesystemBackend 생성

`FilesystemBackend`는 `root_dir` 아래의 파일에 대해 빌트인 도구를 제공합니다:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[빌트인 도구],
  text(weight: "bold")[역할],
  [`ls`],
  [디렉토리 목록 조회],
  [`read_file`],
  [파일 내용 읽기],
  [`glob`],
  [패턴 기반 파일 검색],
  [`write_file`],
  [파일 쓰기 (결과 저장)],
)

#tip-box[`virtual_mode=True`로 디렉토리 탈출(`..`, `~`)을 방지합니다.]

#code-block(`````python
from deepagents.backends import FilesystemBackend

backend = FilesystemBackend(root_dir=DATA_DIR, virtual_mode=True)
`````)

== 3단계: run_ml_code 도구 정의

NB03의 `run_pandas`를 확장하여 `sklearn`을 네임스페이스에 추가합니다.
`DATA_DIR`을 네임스페이스에 전달하여, 에이전트가 디렉토리 내 어떤 CSV든 로드할 수 있습니다.

#tip-box[파일 탐색은 빌트인 `ls`/`read_file`로, 코드 실행은 `run_ml_code`로 — 역할 분리]

#code-block(`````python
from langchain.tools import tool
import io, contextlib

@tool
def run_ml_code(code: str) -> str:
    """sklearn/pandas Python 코드를 실행합니다. print()로 결과를 출력하세요.
    사용 가능: pd, np, sklearn, os. DATA_DIR 변수로 데이터 디렉토리에 접근하세요."""
    import pandas as pd, numpy as np, sklearn
    buf = io.StringIO()
    ns = {"pd": pd, "np": np, "sklearn": sklearn, "os": os, "DATA_DIR": DATA_DIR}
    try:
        with contextlib.redirect_stdout(buf):
            exec(code, ns)
        return buf.getvalue() or "실행 완료 (출력 없음)"
    except Exception as e:
        return f"오류: {e}"
`````)

== 4단계: 에이전트 생성

에이전트의 워크플로:
+ 빌트인 `ls`/`glob`으로 `DATA_DIR` 내 CSV 파일 탐색
+ 빌트인 `read_file`로 데이터 미리보기
+ `run_ml_code`로 EDA → 전처리 → 모델 학습/비교

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[미들웨어],
  text(weight: "bold")[역할],
  [`ToolRetryMiddleware`],
  [도구 실패 시 자동 재시도 (최대 2회)],
  [`ModelCallLimitMiddleware`],
  [무한 루프 방지 — 최대 20회 모델 호출 제한],
)

#code-block(`````python
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import InMemorySaver
from langchain.agents.middleware import (
    ToolRetryMiddleware,
    ModelCallLimitMiddleware,
)
from prompts import ML_AGENT_PROMPT

ml_agent = create_deep_agent(
    model=model,
    tools=[run_ml_code],
    system_prompt=ML_AGENT_PROMPT,
    backend=backend,
    skills=["/skills/"],
    checkpointer=InMemorySaver(),
    middleware=[
        ToolRetryMiddleware(max_retries=2),
        ModelCallLimitMiddleware(run_limit=20),
    ],
)
`````)

== 5단계: 파일 탐색 + EDA 분석

에이전트에게 데이터 디렉토리를 탐색하고 분석하도록 요청합니다.
에이전트는 빌트인 `ls`로 파일 목록을 확인한 뒤, `run_ml_code`로 EDA를 수행합니다.

== 6단계: 모델 학습 + 비교

에이전트에게 적절한 모델 3개 이상을 학습하고 교차 검증으로 성능을 비교하도록 요청합니다.
에이전트가 _스스로 알고리즘을 선택_합니다.

== 7단계: 멀티턴 후속 — Feature Importance 분석

같은 `thread_id`를 써서 이전 대화의 맥락을 유지한 채 후속 분석을 요청합니다.

== 8단계: 스트리밍 — 추가 분석

`stream(subgraphs=True)`으로 에이전트의 실행 과정을 실시간으로 관찰합니다.

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
  [`FilesystemBackend(root_dir=DATA_DIR)` — 사용자 데이터 디렉토리 설정],
  [_빌트인 도구_],
  [`ls`, `read_file`, `glob` — 파일 탐색],
  [_커스텀 도구_],
  [`run_ml_code` (pandas + numpy + sklearn) — ML 코드 실행],
  [_워크플로_],
  [파일 탐색 → EDA → 전처리 → 모델 선택 → 교차 검증 비교],
  [_멀티턴_],
  [`InMemorySaver` + 동일 `thread_id` — 대화 맥락 유지],
)

=== 자신의 데이터 사용하기

#code-block(`````python
# 1단계 셀에서 DATA_DIR만 변경하면 됩니다
DATA_DIR = "/path/to/your/data"  # CSV 파일이 있는 디렉토리
`````)

에이전트가 `ls`로 파일을 탐색하고, `run_ml_code`로 자유롭게 분석합니다.


#references-box[
- `docs/deepagents/06-backends.md`
- `docs/deepagents/tutorials/data-analysis.md`
- #link("https://scikit-learn.org/stable/")[scikit-learn 공식 문서]
_다음 단계:_ → #link("./05_deep_research_agent.ipynb")[05_deep_research_agent.ipynb]: 딥 리서치 에이전트를 구축합니다.
]
#chapter-end()
