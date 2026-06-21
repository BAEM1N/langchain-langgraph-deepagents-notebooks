// Auto-generated from 15_permissions.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(19, "Permissions", subtitle: "Deep Agents 권한 경계를 먼저 설계하기")

== 학습 목표
#learning-objectives([read, write, execute 도구의 위험도를 분리합니다.], [approval/deny/sandbox 정책을 표로 설계합니다.], [권한 정책을 작은 함수로 테스트합니다.])

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

== 15.1 권한 매트릭스

Deep Agent는 파일, shell, sandbox를 다룰 수 있으므로 권한 정책이 먼저 필요합니다.

#code-block(`````python
permission_matrix = {
    "read_file": "allow",
    "write_file": "approve",
    "edit_file": "approve",
    "execute_shell": "sandbox-only",
    "delete_file": "deny",
}

permission_matrix
`````)

== 15.2 정책 evaluator

정책은 문서에만 두지 말고 테스트 가능한 함수로 표현합니다.

#code-block(`````python
def decide(tool_name: str) -> str:
    return permission_matrix.get(tool_name, "deny")

for tool in ["read_file", "write_file", "delete_file", "unknown"]:
    print(tool, "=>", decide(tool))
`````)

== 15.3 approval 메시지

사람 승인이 필요한 도구는 이유와 예상 변경 범위를 함께 보여줘야 합니다.

#code-block(`````python
def approval_message(tool_name: str, target: str) -> str:
    policy = decide(tool_name)
    if policy != "approve":
        return f"{tool_name}: {policy}"
    return f"승인 필요: {tool_name} will modify {target}"

approval_message("write_file", "docs/example.md")
`````)

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
  [permission matrix, policy evaluator, approval message],
  [_핵심 개념_],
  [권한은 agent 실행 후 수습하는 것이 아니라 tool 설계 전에 정합니다.],
)

#references-box[
- `docs/deepagents/permissions.md`
- `docs/deepagents/human-in-the-loop.md`
- `docs/deepagents/sandboxes.md`
]
#chapter-end()
