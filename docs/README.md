# Docs — 문서 지도

이 폴더는 노트북과 핸드북을 작성할 때 참조하는 **공개용 로컬 문서 묶음**입니다. GitHub 방문자는 여기서 각 프레임워크의 핵심 개념, 실습 가드레일, 운영 문서, 검증 기록을 빠르게 찾을 수 있습니다.

## 빠른 탐색

| 경로 | 용도 |
|---|---|
| [`langchain/`](langchain/) | LangChain v1 agents, tools, middleware, RAG, streaming, deploy, observability 정리 |
| [`langgraph/`](langgraph/) | LangGraph v1 Graph API, Functional API, persistence, interrupts, subgraphs, deploy 정리 |
| [`deepagents/`](deepagents/) | Deep Agents SDK, backend, subagents, memory, skills, sandbox, production 정리 |
| [`skills/`](skills/) | LangChain/LangGraph/Deep Agents 코딩 에이전트용 SKILL.md 가드레일 |
| [`translation/`](translation/) | 한국어↔영어 mirror 제작을 위한 용어와 번역 기준 |
| [`verification/`](verification/) | 노트북 smoke test, book build, 링크/비밀값 검증 evidence |
| [`releases/`](releases/) | 릴리즈별 변경 요약과 운영 메모 |
| [`OBSERVABILITY.md`](OBSERVABILITY.md) | LangSmith, Langfuse 관측성 설정 |
| [`MODEL_PROVIDERS.md`](MODEL_PROVIDERS.md) | OpenAI 외 provider와 로컬 모델 사용 방식 |
| [`SKILLS.md`](SKILLS.md) | LangChain Skills 설치와 repo 내 활용 방식 |

## 공개 문서 기준

`docs/`에는 GitHub에 공개해도 학습자와 기여자에게 직접 도움이 되는 자료만 둡니다.

포함 대상:

- 노트북 코드와 설명의 근거가 되는 프레임워크 문서
- 커리큘럼 작성·검증·번역 기준
- 실행자가 바로 참고할 provider/observability/skills 안내
- 릴리즈와 검증 evidence처럼 repo 신뢰도를 높이는 기록

제외 대상:

- 개인 작업 메모
- 페이지별 수동 검수 raw log
- 일회성 리서치 초안
- 공개 README에서 바로 탐색할 필요가 없는 내부 제작 메모

이런 내부 자료는 `local/` 또는 `.local/` 아래에 보존합니다.

## 노트북 작성 시 사용법

1. 새 LangChain 코드를 작성하기 전 [`langchain/`](langchain/)과 [`skills/langchain-v1-modern.md`](skills/langchain-v1-modern.md)를 확인합니다.
2. LangGraph 예제를 만들 때는 [`langgraph/`](langgraph/)와 관련 skills 문서를 먼저 확인합니다.
3. Deep Agents 예제를 만들 때는 [`deepagents/`](deepagents/)와 `docs/skills/deep-agents-*.md`를 확인합니다.
4. provider, tracing, 평가, 배포 성격의 예제는 `OBSERVABILITY.md`, `MODEL_PROVIDERS.md`, `verification/` 기록을 함께 확인합니다.

## 유지보수 체크리스트

`docs/`를 수정한 뒤에는 최소한 다음을 확인합니다.

```bash
# 문서 링크가 깨졌는지 확인할 것
rg -n "\]\([^)]*\)" docs/README.md README.md

# 민감정보 placeholder가 실제 값으로 바뀌지 않았는지 확인할 것
rg -n "(sk-[A-Za-z0-9_-]{20,}|lsv2_[A-Za-z0-9_-]{20,}|BEGIN (RSA|OPENSSH|PRIVATE))" docs || true

# Markdown 공백 검증
git diff --check -- docs README.md
```
