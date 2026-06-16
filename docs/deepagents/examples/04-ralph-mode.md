# Ralph Mode

## Overview

자율 루핑 패턴으로, 매 반복마다 새로운 컨텍스트로 에이전트를 실행하며 파일시스템을 통해 상태를 유지한다. Geoff Huntley의 "Ralph" 패턴에서 유래.

**원본:** [examples/ralph_mode](https://github.com/langchain-ai/deepagents/tree/main/examples/ralph_mode)

## Directory Structure

```
ralph_mode/
├── README.md
├── ralph_mode.py                # 메인 스크립트 (~200줄)
└── ralph_mode_diagram.png       # 아키텍처 다이어그램
```

## Source Code

### ralph_mode.py

핵심 아이디어: `while` 루프에서 매 반복마다 `dcode -n ...` 비대화형 실행을 호출하여 fresh context로 에이전트를 실행한다. 이전 작업은 파일시스템에 저장되어 다음 반복에서 참조된다.

```python
import argparse
import json
import subprocess
from pathlib import Path

def ralph(
    task: str,
    iterations: int = 10,
    model: str = "openai:gpt-5.5",
    work_dir: str = "./workspace",
    sandbox: str | None = None,
    sandbox_id: str | None = None,
    shell_allow_list: str = "recommended",
    model_params: dict | None = None,
    no_stream: bool = False,
):
    """Ralph Mode: 자율 루핑 에이전트.

    매 반복마다 fresh context로 시작하되,
    파일시스템을 통해 이전 작업을 이어간다.
    """
    root = Path(work_dir)
    root.mkdir(parents=True, exist_ok=True)

    for i in range(iterations):
        prompt = (
            f"Your previous work is in the filesystem. "
            f"Check what exists and keep building. "
            f"TASK: {task}. Make progress. "
            f"You'll be called again."
        )

        cmd = ["dcode", "-n", prompt, "-M", model, "-S", shell_allow_list]
        if sandbox:
            cmd += ["--sandbox", sandbox]
        if sandbox_id:
            cmd += ["--sandbox-id", sandbox_id]
        if no_stream:
            cmd += ["--no-stream"]
        if model_params:
            cmd += ["--model-params", json.dumps(model_params)]
        subprocess.run(cmd, cwd=root, check=True)
        print(f"Iteration {i+1}/{iterations} complete")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("task", help="Task description")
    parser.add_argument("--iterations", type=int, default=10)
    parser.add_argument("--model", default="openai:gpt-5.5")
    parser.add_argument("--work-dir", default="./workspace")
    parser.add_argument("--sandbox", choices=["modal", "daytona", "runloop"])
    parser.add_argument("--sandbox-id")
    parser.add_argument("--shell-allow-list", default="recommended")
    parser.add_argument("--no-stream", action="store_true")
    args = parser.parse_args()
    ralph(**vars(args))
```

### 원래 패턴 (셸)

```bash
while :; do cat PROMPT.md | agent ; done
```

## Setup & Usage

```bash
curl -LsSf https://langch.in/dcode | bash
python ralph_mode.py "Build a REST API with FastAPI" \
    --iterations 5 \
    --model openai:gpt-5.5 \
    --work-dir ./workspace
```

지원 옵션:
- `--iterations N`: 반복 횟수 (기본 10)
- `--model`: 모델 선택 (기본 `openai:gpt-5.5`)
- `--work-dir`: 작업 디렉토리
- `--sandbox`: 샌드박스 종류 (modal/daytona/runloop)
- `--no-stream`: 스트리밍 비활성화

Ctrl+C로 중단 가능.

## Key Concepts

| 개념 | 설명 |
|------|------|
| Fresh Context | 매 반복마다 새 컨텍스트 — 컨텍스트 윈도우 제한 우회 |
| 파일시스템 지속성 | 이전 작업 결과가 디스크에 남아 다음 반복에서 참조 |
| `dcode -n` | Deep Agents Code의 비대화형 단일 태스크 실행 |
| 자율 루핑 | 사람 개입 없이 반복적으로 진행 |
| 샌드박스 지원 | Modal, Daytona, Runloop 등 격리 환경 실행 |
