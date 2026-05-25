# Profiles — Deep Agents 0.5.4+

> 모델이나 provider 선택에 따라 Deep Agents harness 설정을 자동으로 겹쳐 적용하는 beta API.

## 개요

`HarnessProfile`은 `create_deep_agent()` 호출부를 바꾸지 않고도 provider/model별 harness 기본값을 패키징한다. 시스템 프롬프트 suffix, 도구 설명 override, 제외할 도구/미들웨어, 일반 목적 서브에이전트 설정, 추가 미들웨어 등을 profile로 등록할 수 있다.

```python
from deepagents import (
    GeneralPurposeSubagentProfile,
    HarnessProfile,
    register_harness_profile,
)

register_harness_profile(
    "openai:gpt-5.4",
    HarnessProfile(
        system_prompt_suffix="Respond in under 100 words.",
        excluded_tools={"execute"},
        excluded_middleware={"SummarizationMiddleware"},
        general_purpose_subagent=GeneralPurposeSubagentProfile(enabled=False),
    ),
)
```

## 적용 키

| 키 | 범위 |
|----|------|
| `"openai"` | provider 전체 |
| `"openai:gpt-5.4"` | 특정 모델 |

provider-level profile과 model-level profile이 모두 있으면 model-level 값이 우선하고, 나머지는 provider-level에서 상속된다. 같은 키에 재등록하면 덮어쓰기보다 **merge**된다.

### HarnessProfile 필드

- `base_system_prompt` — 베이스 system prompt 자체를 교체
- `system_prompt_suffix` — 조립된 베이스 prompt 끝에 텍스트 추가
- `tool_description_overrides` — 도구 이름별 설명 override
- `excluded_tools` — 주입 이후 이름으로 제거할 도구 집합
- `excluded_middleware` — 제거할 middleware 클래스 집합
- `extra_middleware` — 추가로 붙일 middleware 인스턴스 리스트
- `general_purpose_subagent` — `GeneralPurposeSubagentProfile`로 일반 목적 서브에이전트 활성·비활성·커스터마이즈

### Merge semantics

- mapping류 필드(예: `tool_description_overrides`)는 키 단위로 merge
- set류 필드(`excluded_tools`, `excluded_middleware`)는 합집합
- middleware 인스턴스는 같은 구체 클래스가 등장하면 교체, 새 타입은 append

## ProviderProfile

`ProviderProfile`은 harness 동작이 아니라 `init_chat_model()`에 넘길 초기화 인자를 다룬다. credential check, provider별 기본 temperature, runtime header 구성처럼 모델 생성 전후 기본값을 묶을 때 사용한다.

```python
from deepagents import ProviderProfile, register_provider_profile

register_provider_profile(
    "openai",
    ProviderProfile(init_kwargs={"temperature": 0}),
)
```

### ProviderProfile 필드

- `init_kwargs` — `init_chat_model()`에 정적으로 전달할 kwargs
- `pre_init` — 모델 생성 전 실행할 side effect(예: credential 검증)
- `init_kwargs_factory` — runtime 정보 기반으로 kwargs를 동적 생성

## Config 파일에서 로드

`HarnessProfileConfig`로 YAML/JSON 워크플로를 지원한다.

```yaml
# openai.yaml
base_system_prompt: You are helpful.
system_prompt_suffix: Respond briefly.
excluded_tools:
  - execute
  - grep
excluded_middleware:
  - SummarizationMiddleware
  - my_pkg.middleware:TelemetryMiddleware
general_purpose_subagent:
  enabled: false
```

```python
import yaml
from deepagents import HarnessProfileConfig, register_harness_profile

with open("openai.yaml") as f:
    register_harness_profile(
        "openai",
        HarnessProfileConfig.from_dict(yaml.safe_load(f)),
    )
```

`HarnessProfileConfig`는 `from_dict()`, `to_dict()`, `from_harness_profile()` 클래스 메서드를 제공한다.

## Plugin으로 배포

`importlib.metadata` entry point에 등록하면 패키지 설치만으로 자동 로드된다.

```toml
[project.entry-points."deepagents.harness_profiles"]
my_provider = "my_pkg.profiles:register_harness"

[project.entry-points."deepagents.provider_profiles"]
my_provider = "my_pkg.profiles:register_provider"
```

```python
from deepagents import (
    HarnessProfile,
    ProviderProfile,
    register_harness_profile,
    register_provider_profile,
)


def register_harness() -> None:
    register_harness_profile(
        "my_provider",
        HarnessProfile(system_prompt_suffix="Batch independent tool calls in parallel."),
    )


def register_provider() -> None:
    register_provider_profile(
        "my_provider",
        ProviderProfile(init_kwargs={"temperature": 0}),
    )
```

로드 순서는 **built-ins → entry-point plugins → 사용자 코드의 직접 `register_*_profile` 호출** 순이다.

## 언제 쓰나

- provider별로 기본 system prompt suffix나 tool visibility를 다르게 둬야 할 때
- 모델 선택만으로 안전한 기본값을 자동 적용하고 싶을 때
- plugin 형태로 팀 표준 harness 설정을 배포할 때

전역 정책은 profile보다 `create_deep_agent()` 호출부에서 명시하는 편이 낫다. profile은 “선택된 provider/model에 따라 달라지는 설정”에 집중한다.
