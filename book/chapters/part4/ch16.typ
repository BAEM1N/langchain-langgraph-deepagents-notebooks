// Auto-generated from 12_models_and_tools.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(16, "Models and Tools", subtitle: "Deep Agents의 실행 표면 설계")

== 학습 목표
#learning-objectives([Deep Agents에서 _model_, _tool_, _permission boundary_가 맡는 역할을 구분합니다.], [도구 docstring과 schema가 에이전트 행동에 주는 영향을 확인합니다.], [실제 모델 호출 없이도 도구 명세와 위험도를 점검하는 방법을 익힙니다.])

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
from langchain.tools import tool
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend
`````)

== 12.1 도구는 “함수”가 아니라 “계약”입니다

LLM은 Python 구현이 아니라 이름, 설명, 인자 schema를 보고 도구를 선택합니다.

#code-block(`````python
@tool
def summarize_note(text: str, max_bullets: int = 3) -> str:
    """Summarize a note into a short Korean bullet list."""
    sentences = [s.strip() for s in text.split(".") if s.strip()]
    return "\n".join(f"- {s}" for s in sentences[:max_bullets])

print(summarize_note.invoke({"text": "A. B. C.", "max_bullets": 2}))
`````)

== 12.2 도구 schema 점검

교육 자료에서는 tool schema를 출력해 학습자가 “모델이 무엇을 보는지” 이해하게 합니다.

#code-block(`````python
schema = summarize_note.args_schema.model_json_schema()

print("tool name:", summarize_note.name)
print("description:", summarize_note.description)
print("properties:", sorted(schema["properties"]))
`````)

== 12.3 도구 위험도 분류

도구를 만들 때는 실행 전 approval이 필요한지 먼저 분류합니다.

#code-block(`````python
tool_policy = {
    "summarize_note": "allow",
    "write_file": "approve",
    "execute_shell": "deny-or-sandbox",
}

for name, policy in tool_policy.items():
    print(f"{name:16s} -> {policy}")
`````)

== 12.4 모델 설정은 호출부에서 통일합니다

이 저장소는 교육 기본 모델을 `gpt-5.4`로 둡니다. 실제 실행 전에는 provider key와 비용 정책을 확인합니다.

#code-block(`````python
MODEL_NAME = os.getenv("COURSE_MODEL", "gpt-5.4")
agent_config = {
    "model": MODEL_NAME,
    "tools": [summarize_note],
    "backend": FilesystemBackend(root_dir=".", virtual_mode=True),
}
agent_config["model"]
`````)

== 12.5 에이전트 생성은 실행과 분리합니다

아래 셀은 호출하지 않고 agent 객체만 구성합니다. 실제 `.invoke()`는 API key, 비용, 권한 정책을 확인한 뒤 실행합니다.

#code-block(`````python
agent = create_deep_agent(
    model=agent_config["model"],
    tools=agent_config["tools"],
    backend=agent_config["backend"],
    system_prompt="You are a concise course assistant.",
)

type(agent).__name__
`````)

== 12.6 설계 점검표

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[질문],
  text(weight: "bold")[기준],
  [모델],
  [provider, 비용, latency, context window가 맞는가?],
  [도구],
  [이름과 docstring이 구체적인가?],
  [권한],
  [read/write/execute 위험도가 분리됐는가?],
  [backend],
  [local, store, sandbox 중 목적에 맞는가?],
)

#line(length: 100%, stroke: 0.5pt + luma(200))

== 정리

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [_다룬 기술_],
  [`\@tool`, tool schema, `create_deep_agent`, `FilesystemBackend`],
  [_핵심 개념_],
  [Deep Agent의 품질은 model보다 tool 계약과 권한 경계에서 크게 갈립니다.],
  [_다음 단계_],
  [`13_programmatic_subagents.ipynb`, `14_event_streaming.ipynb`],
)

#references-box[
- `docs/deepagents/models.md`
- `docs/deepagents/tools.md`
- `docs/deepagents/permissions.md`
- `docs/deepagents/backends.md`
]
#chapter-end()
