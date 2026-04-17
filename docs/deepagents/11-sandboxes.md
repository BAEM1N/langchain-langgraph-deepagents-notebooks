# Sandboxes

## Overview

샌드박스는 에이전트가 **호스트 시스템·자격증명·네트워크에 접근하지 않고** 코드 실행, 파일 작업, 셸 명령을 안전하게 수행하는 격리 환경이다. Deep Agents 0.4부터 공식 샌드박스 통합 패키지 3종이 제공된다.

## 지원 공급자 (공식 패키지, 0.4+)

| 패키지 | 공급자 | 특징 |
|--------|--------|------|
| `langchain-modal` | Modal | ML/AI 워크로드, GPU 지원 |
| `langchain-daytona` | Daytona | TypeScript/Python, 빠른 콜드 스타트 |
| `langchain-runloop` | Runloop | 일회용 devbox 기반 격리 |

## 통합 패턴

### Agent in Sandbox
에이전트 자체가 샌드박스 내부에서 실행되고, 외부와는 네트워크 프로토콜로 통신.
- 장점: 개발/프로덕션 패리티
- 단점: 자격증명 노출 위험, 인프라 복잡도

### Sandbox as Tool (권장)
에이전트는 외부에서 실행, 샌드박스 API만 호출해 코드를 실행.
- 장점: 에이전트 상태와 실행 환경 분리, 시크릿은 샌드박스 밖에 보관, 병렬 실행 용이
- 단점: 네트워크 레이턴시

---

## 1. Modal

```bash
pip install langchain-modal
```

```python
import modal
from deepagents import create_deep_agent
from langchain_anthropic import ChatAnthropic
from langchain_modal import ModalSandbox

app = modal.App.lookup("your-app")
modal_sandbox = modal.Sandbox.create(app=app)
backend = ModalSandbox(sandbox=modal_sandbox)

agent = create_deep_agent(
    model=ChatAnthropic(model="claude-sonnet-4-6"),
    system_prompt="You are a Python coding assistant with sandbox access.",
    backend=backend,
)

try:
    result = agent.invoke({
        "messages": [{"role": "user", "content": "Create a small Python package and run pytest"}],
    })
finally:
    modal_sandbox.terminate()    # 필수: 리소스 해제
```

Modal은 GPU 가속이 필요한 워크로드(ML 학습, 임베딩 배치 등)에 적합하다.

---

## 2. Daytona

```bash
pip install langchain-daytona
```

```python
from daytona import Daytona
from deepagents import create_deep_agent
from langchain_anthropic import ChatAnthropic
from langchain_daytona import DaytonaSandbox

sandbox = Daytona().create()
backend = DaytonaSandbox(sandbox=sandbox)

agent = create_deep_agent(
    model=ChatAnthropic(model="claude-sonnet-4-6"),
    system_prompt="You are a Python coding assistant with sandbox access.",
    backend=backend,
)

try:
    result = agent.invoke({
        "messages": [{"role": "user", "content": "Create a small Python package and run pytest"}],
    })
finally:
    sandbox.stop()
```

Daytona는 콜드 스타트가 빠르고 TS/Python 개발 환경에 최적화되어 있다.

---

## 3. Runloop

```bash
pip install langchain-runloop
```

환경변수 `RUNLOOP_API_KEY` 필요.

```python
import os
from deepagents import create_deep_agent
from langchain_anthropic import ChatAnthropic
from langchain_runloop import RunloopSandbox
from runloop_api_client import RunloopSDK

client = RunloopSDK(bearer_token=os.environ["RUNLOOP_API_KEY"])

devbox = client.devbox.create()
backend = RunloopSandbox(devbox=devbox)

agent = create_deep_agent(
    model=ChatAnthropic(model="claude-sonnet-4-6"),
    system_prompt="You are a Python coding assistant with sandbox access.",
    backend=backend,
)

try:
    result = agent.invoke({
        "messages": [{"role": "user", "content": "Create a small Python package and run pytest"}],
    })
finally:
    devbox.shutdown()
```

Runloop은 일회용 devbox 패턴으로, 세션별 완전 격리가 기본값이다.

---

## 공통 패턴

세 공급자 모두 동일한 흐름:

1. 공급자 SDK로 **샌드박스 인스턴스 생성**
2. LangChain 통합 패키지의 `*Sandbox` 래퍼로 감싸 **backend** 만들기
3. `create_deep_agent(backend=...)`에 전달
4. **`try/finally`로 반드시 정리** (`terminate` / `stop` / `shutdown`)

## 제공되는 도구

샌드박스 backend를 전달하면 에이전트에 다음 도구가 자동 노출된다:

| 도구 | 용도 |
|------|------|
| `ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep` | 파일시스템 |
| `execute` | 셸 명령 실행 |

파일 전송 API(`uploadFiles()`, `downloadFiles()`)는 샌드박스를 초기화하거나 산출물을 회수할 때 사용한다.

---

## 보안 원칙

### 절대 금지
- 샌드박스 내부에 **시크릿을 넣지 않는다**. 컨텍스트 주입형 공격으로 환경변수/마운트 파일을 읽어 유출될 수 있다.

### 안전한 운영
- 자격증명은 **샌드박스 밖의 외부 도구**에 보관
- 민감한 작업은 **HITL 승인** (`interrupt_on`) 경유
- 불필요한 네트워크 아웃바운드 차단
- 모든 샌드박스 출력은 **신뢰하지 말고 검증** 후 사용
- 예상치 못한 외부 연결 모니터링

---

## 라이프사이클 관리

샌드박스는 **명시적으로 종료**해야 비용이 누적되지 않는다.

- 단발성 작업: `try/finally`로 즉시 종료
- 채팅/장기 세션: 대화 스레드당 고유 샌드박스를 두고 **TTL로 자동 정리**
- LangSmith Deployment에서 운영할 때는 세션 종료 훅에 종료 로직을 연결

## 관련 문서

- `06-backends.md` — `backend` 매개변수 일반
- `10-skills.md` — 스킬 + 샌드박스 조합
- Deep Agents 0.5 `StateBackend()` / `StoreBackend()` 직접 생성은 `docs/skills/deep-agents-memory.md` 참고
