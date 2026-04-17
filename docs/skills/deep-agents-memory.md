# Deep Agents Memory

백엔드 시스템, StoreBackend, FilesystemMiddleware.

> **deepagents 0.5+ 기준.** 이전 factory 패턴은 deprecated.

## 백엔드 종류

| 백엔드 | 특성 | 용도 |
|--------|------|------|
| `StateBackend` | 임시, 단일 스레드 | 테스트, 짧은 세션 |
| `StoreBackend` | 영구, 크로스 세션 | 프로덕션 |
| `CompositeBackend` | 하이브리드 라우팅 | 경로별 저장소 분리 |
| `FilesystemBackend` | 파일시스템 기반 | 로컬 개발 |

## 직접 인스턴스화 (0.5+)

`StateBackend()`, `StoreBackend()`는 **직접 생성**한다. 0.4까지 쓰이던 factory 함수 기반 패턴은 deprecated.

```python
from deepagents.backends import StateBackend, StoreBackend
from langgraph.store.memory import InMemoryStore

# 임시(테스트)
state_backend = StateBackend()

# 영구(프로덕션)
store = InMemoryStore()  # 프로덕션에선 PostgresStore
store_backend = StoreBackend(store=store)
```

### 바이너리 파일 (0.5+)

state/store 포맷이 바이너리 파일(PDF, 오디오, 비디오)을 지원하도록 업데이트됐다. `read_file` 도구는 이제 이미지 외에 PDF, 오디오, 비디오까지 멀티모달로 다룬다.

백엔드 내부 에러도 도구까지 더 구체적으로 전파되어 디버깅이 쉬워졌다.

## FilesystemBackend

```python
from deepagents.backends import FilesystemBackend

backend = FilesystemBackend(
    root_dir="./output",
    virtual_mode=True,  # 보안: 실제 파일 시스템 접근 차단
)
```

**`virtual_mode=True` 필수** — 웹 서버에 `FilesystemBackend`를 절대 직접 배포하지 말 것.

## FilesystemMiddleware 도구

| 도구 | 기능 | 비고 |
|------|------|------|
| `ls` | 디렉토리 목록 | |
| `read_file` | 파일 읽기 | 0.5+ PDF/오디오/비디오 지원 |
| `write_file` | 파일 쓰기 | |
| `edit_file` | 파일 수정 | |
| `glob` | 패턴 매칭 | |
| `grep` | 내용 검색 | |

## CompositeBackend

경로 매칭으로 여러 백엔드를 조합:

```python
from deepagents.backends import StateBackend, StoreBackend, CompositeBackend

backend = CompositeBackend(
    backends={
        "/tmp/": StateBackend(),
        "/data/": StoreBackend(store=store),
    }
)
```

경로 매칭은 **longest-prefix-first** 규칙.

## Context Overflow 자동 처리 (0.4+)

`langchain-anthropic` / `langchain-openai` 모델을 사용하면 `ContextOverflowError` 발생 시 자동으로 대화 요약이 트리거된다. 요약은 `wrap_model_call` 훅에서 실행되고, 전체 메시지 히스토리는 그래프 state에 보존된다.

## OpenAI 데이터 보존 옵션 (0.4+)

`openai:` 프리픽스 모델 문자열은 기본적으로 Responses API를 사용한다. 데이터 보존을 원하지 않는 환경에서는 다음과 같이 구성한다.

```python
from langchain.chat_models import init_chat_model
from deepagents import create_deep_agent

agent = create_deep_agent(
    model=init_chat_model(
        "openai:gpt-5",
        use_responses_api=True,
        store=False,                              # OpenAI 측 저장 비활성화
        include=["reasoning.encrypted_content"],  # 암호화된 reasoning 유지
    ),
)
```

## 보안 원칙

1. `FilesystemBackend`는 `virtual_mode=True` 사용
2. 웹 서버에 직접 배포 금지
3. 프로덕션에서는 `PostgresStore` 사용
4. 규제 환경에선 `store=False` + 암호화된 reasoning 포함 옵션 검토
