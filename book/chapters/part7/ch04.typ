// Auto-generated from 04_ml_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "머신러닝 에이전트", subtitle: "CSV 기반 자유 ML 워크플로")

이전 장의 데이터 분석 에이전트가 pandas를 활용한 집계와 통계에 집중했다면, 머신러닝 에이전트는 그 다음 단계인 예측 모델링으로 나아갑니다. 머신러닝 에이전트는 데이터 분석을 넘어 EDA, 전처리, 모델 선택, 학습, 평가까지의 전체 ML 파이프라인을 자율적으로 수행합니다. 이 장에서는 `FilesystemBackend`로 데이터 디렉토리를 설정하고, `sklearn`을 포함하는 `run_ml_code` 도구를 정의하여 에이전트가 자유롭게 ML 워크플로를 실행할 수 있도록 구성합니다. 멀티턴 대화를 통해 사용자와 협력하며 반복적으로 모델을 개선하는 패턴을 학습합니다.

핵심 설계 철학은 _에이전트가 알고리즘을 선택하게 하는 것_입니다. 사람이 "RandomForest를 학습해"라고 지시하는 대신, "이 데이터에 적합한 모델 3개를 학습하고 비교해"라고 요청하면 에이전트가 데이터 특성을 파악하여 적절한 알고리즘을 스스로 선택합니다. 이를 위해 `run_ml_code` 도구의 네임스페이스에 sklearn 전체를 주입하여 에이전트의 자유도를 최대화합니다.

#learning-header()
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

NB03(데이터 분석 에이전트)과 NB04(머신러닝 에이전트)는 같은 "코드 실행" 패턴을 공유하지만, 백엔드와 도구 범위에서 중요한 차이가 있습니다. NB03에서는 `LocalShellBackend` + `run_pandas`로 pandas 코드를 실행했습니다.
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

백엔드와 도구의 차이를 이해했으니, 실제 데이터를 준비합니다. 데이터 준비 방식에서 NB03과의 핵심 차이는 _디렉토리 기반 접근_입니다.

#tip-box[이 장의 모든 코드는 `DATA_DIR` 변수 하나만 변경하면 _자신의 CSV 데이터_에 그대로 적용할 수 있습니다. 에이전트가 `ls`, `glob`, `read_file` 빌트인으로 디렉토리를 자동 탐색하여 어떤 파일이 있는지 파악하므로, 데이터 구조를 에이전트에게 미리 설명할 필요가 없습니다. 여러 CSV 파일이 있는 경우에도 에이전트가 각 파일의 관계를 자율적으로 분석합니다.] 이 장의 가장 큰 장점은 `DATA_DIR` 경로 하나만 변경하면 _자신의 CSV 데이터_에 대해 동일한 ML 워크플로를 적용할 수 있다는 것입니다. 에이전트가 `ls`, `glob`, `read_file` 빌트인으로 디렉토리를 탐색하여 어떤 파일이 있는지 파악합니다.

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

데이터가 준비되었으니, 에이전트가 해당 디렉토리에 접근할 수 있도록 백엔드를 구성합니다. `FilesystemBackend`는 `LocalShellBackend`와 달리 셸 명령 실행(`execute`)을 제공하지 않으므로, 에이전트가 임의의 시스템 명령을 실행할 위험이 없습니다. 대신 `root_dir` 아래의 파일에 대해 다음 빌트인 도구를 제공합니다:

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

백엔드가 파일 탐색을 담당한다면, 실제 ML 코드 실행은 커스텀 도구의 몫입니다. NB03의 `run_pandas` 도구를 확장하여 `sklearn` 전체를 네임스페이스에 추가합니다. 이것이 ML 에이전트의 핵심 설계 결정입니다 -- 특정 알고리즘만 제공하는 대신, sklearn 전체를 제공하여 에이전트가 데이터 특성에 따라 최적의 알고리즘을 _스스로 선택_할 수 있도록 합니다. NB03의 `run_pandas`를 확장하여 `sklearn`을 네임스페이스에 추가합니다. `DATA_DIR`을 네임스페이스에 전달하여, 에이전트가 디렉토리 내 어떤 CSV든 로드할 수 있습니다.

#warning-box[`run_ml_code`는 `exec()`로 임의의 Python 코드를 실행합니다. 프로덕션에서는 Docker 컨테이너나 Modal Sandbox 같은 격리 환경에서 실행해야 합니다.]

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

도구와 백엔드가 모두 준비되었으니, `create_deep_agent`로 최종 에이전트를 조립합니다. `ToolRetryMiddleware`는 `run_ml_code`가 import 오류 등으로 실패할 때 자동으로 재시도하여, 에이전트가 코드를 수정한 뒤 다시 시도할 기회를 제공합니다. 에이전트의 워크플로:
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

에이전트 생성이 완료되었으니, 실제 ML 워크플로를 시작합니다. ML 파이프라인의 첫 단계는 항상 _탐색적 데이터 분석(Exploratory Data Analysis, EDA)_입니다. EDA 없이 바로 모델을 학습하면 결측치, 이상치, 클래스 불균형 등의 문제로 모델 성능이 저하됩니다.

#warning-box[에이전트가 `run_ml_code`로 실행하는 코드는 `exec()`를 사용하므로, _임의의 Python 코드가 실행될 수 있습니다_. 학습/개발 환경에서는 `virtual_mode=True`로 파일시스템 접근을 제한하고, 프로덕션에서는 반드시 Docker 컨테이너나 Modal Sandbox 같은 격리 환경에서 실행하세요. `exec()` 내에서 `os.system()`, `subprocess` 등의 시스템 호출을 차단하는 커스텀 namespace 설정도 고려할 수 있습니다.] 첫 번째 단계는 항상 데이터 탐색입니다. 에이전트에게 데이터 디렉토리를 탐색하고 분석하도록 요청하면, 빌트인 `ls`로 파일 목록을 확인한 뒤, `run_ml_code`로 EDA를 수행합니다. 에이전트는 결측치, 데이터 분포, 피처 간 상관관계 등을 자율적으로 분석합니다.

EDA가 완료되면 데이터의 특성(피처 수, 클래스 분포, 결측치 비율 등)이 파악됩니다. 이 정보를 바탕으로 에이전트가 적합한 모델을 선택하고 학습하는 단계로 넘어갑니다.

== 6단계: 모델 학습 + 비교

EDA 결과를 바탕으로 에이전트가 모델링 단계에 진입합니다. 에이전트에게 적절한 모델 3개 이상을 학습하고 교차 검증으로 성능을 비교하도록 요청합니다. 에이전트가 _스스로 알고리즘을 선택_합니다. 예를 들어, 이진 분류 데이터에 대해 LogisticRegression, RandomForest, GradientBoosting을 선택하고 `cross_val_score`로 비교하는 코드를 작성할 수 있습니다.

#tip-box[에이전트가 알고리즘을 선택하는 것이 핵심입니다. 데이터의 크기, 피처 수, 클래스 불균형 등을 고려하여 적합한 모델을 제안하므로, ML 경험이 적은 사용자도 합리적인 모델 선택이 가능합니다.]

== 7단계: 멀티턴 후속 -- Feature Importance 분석

모델 학습이 완료된 후, 같은 `thread_id`를 사용하여 이전 대화의 맥락을 유지한 채 후속 분석을 요청합니다. 에이전트는 이전 단계에서 어떤 모델을 학습했는지 기억하고 있으므로, "가장 성능이 좋은 모델의 Feature Importance를 분석해"와 같은 후속 질문에 즉시 대응할 수 있습니다.

모델 학습과 Feature Importance 분석이 완료된 후에도, 추가 분석(하이퍼파라미터 튜닝, 학습 곡선 시각화 등)을 스트리밍으로 관찰하면서 수행할 수 있습니다.

== 8단계: 스트리밍 -- 추가 분석

`stream(subgraphs=True)`으로 에이전트의 실행 과정을 실시간으로 관찰합니다. ML 워크플로에서 스트리밍은 특히 유용합니다 -- 모델 학습이 오래 걸리거나 에이전트가 복잡한 전처리 파이프라인을 구성할 때, 중간 과정을 실시간으로 확인하여 잘못된 방향으로 가고 있는지 조기에 감지할 수 있습니다.

#tip-box[ML 에이전트의 스트리밍에서 `run_ml_code` 도구의 실행 결과를 관찰하세요. 에이전트가 `cross_val_score`를 실행하면 결과에 교차 검증 점수가 포함됩니다. 점수가 낮거나 과적합 징후(학습 정확도 높고 검증 정확도 낮음)가 보이면, 다음 턴에서 "정규화를 추가해" 또는 "다른 모델을 시도해"라고 지시할 수 있습니다.] ML 모델 학습은 시간이 오래 걸릴 수 있으므로, 스트리밍으로 에이전트가 어떤 코드를 실행하는지, 중간 결과가 어떤지 확인하는 것이 특히 유용합니다.

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

이 장에서는 `FilesystemBackend`와 `run_ml_code` 도구를 결합하여 에이전트가 전체 ML 파이프라인을 자율적으로 수행하는 패턴을 학습했습니다. 다음 장에서는 Part 6의 캡스톤 프로젝트로, 병렬 서브에이전트 3개를 활용한 딥 리서치 에이전트를 구축합니다. 지금까지 학습한 서브에이전트, 미들웨어, 스트리밍 패턴이 모두 종합됩니다.

#references-box[
- `docs/deepagents/06-backends.md`
- `docs/deepagents/tutorials/data-analysis.md`
- #link("https://scikit-learn.org/stable/")[scikit-learn 공식 문서]
_다음 단계:_ → #link("./05_deep_research_agent.ipynb")[05_deep_research_agent.ipynb]: 딥 리서치 에이전트를 구축합니다.
]
#chapter-end()
