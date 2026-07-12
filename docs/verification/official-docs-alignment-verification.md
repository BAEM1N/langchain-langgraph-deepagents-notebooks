# 공식 문서 정합성 검증 결과

## 적용 범위

- 주 검증: 한국어·영어 `01_beginner/`~`06_langsmith/`
- 제한 검증: `07_examples/`의 최신 API·버전·공식 링크
- 제외: `08_integration/`

## 셀 감사 결과

| 항목 | 결과 |
|---|---:|
| 노트북 | 150 |
| 전체 셀 | 2,973 |
| 코드 셀 | 1,356 |
| 오류 | 0 |
| 10줄 초과 스타일 경고 | 652 |

각 셀에서 노트북 JSON, 순차 셀 ID, Python 구문, 설치 모듈과 import symbol, 로컬 Markdown 링크, Markdown code fence를 검사했다. 외부 API 키·네트워크·비용·부작용이 필요한 셀은 실제 호출하지 않았다.

## 실행 검증

- LangGraph interrupt 입력 검증: 한·영 예제 모두 invalid 응답 뒤 재중단, valid 응답 뒤 완료
- LangChain HITL: 부작용 도구는 `approve/edit/reject`, 질문형 도구는 `respond`
- Deep Agents custom backend: `ls`, `read`, `grep` 결과 계약 실행 성공
- Deep Agents 버전: 안정 `0.6.12`에는 `BackendProtocol.delete` 없음, 격리 설치한 `0.7.0a6`에는 존재
- 에이전트 생성: `create_agent()`가 배포 가능한 `CompiledStateGraph` 반환

## 실제 노트북 실행 상태

- 전체 의존성을 갱신한 Python 3.14.3 전용 커널에서 `01`~`06` 한·영 150개 노트북을 Restart & Run All 방식으로 다시 실행했다. 원본은 수정하지 않고 gitignored 로컬 복사본만 사용했다.
- 저장소의 직접 OpenAI 키는 401이었지만, 내부 OpenAI 호환 LiteLLM 게이트웨이와 전용 키는 인증 및 채팅 호출에 성공했다. 게이트웨이에 `gpt-5.4`가 없어 실행 복사본에서만 채팅 모델을 `gpt-5.5`, 임베딩 모델을 `bge-m3`로 치환했다.
- 1차 `gpt-5.5` 실행 결과는 150개 중 141개 통과, 9개 실패다. 실패는 Tavily 플랜 사용량 초과 6개, 구조화 출력 셀의 360초 타임아웃 2개, `checkpointer=True`를 루트 그래프로 직접 호출한 교육 코드 1개다. 이전 실행과 달리 전수 실행 중 게이트웨이 쿨다운은 발생하지 않았다.
- 루트 그래프 checkpointer 예제는 `InMemorySaver()`를 명시하도록 수정했다. 수정본 `02_langchain/08_multi_agent.ipynb`는 `gpt-5.5`로 71.9초에 전 셀 통과했다. `checkpointer=True`는 checkpointer가 있는 부모에 내장된 서브그래프의 continuations 모드로만 설명하도록 노트북·문서·핸드북 원본을 함께 갱신했다.
- 구조화 출력 한·영 노트북은 같은 게이트웨이의 `qwen3.6-35b`로 재실행해 각각 26.1초, 144.1초에 통과했다. LangChain/Pydantic 스키마 오류가 아니라 현재 `gpt-5.5` 프록시 경로의 ToolStrategy 지연으로 판정했다.
- 실제 Tavily 호출이 막힌 6개는 검색 반환값만 결정적 로컬 스텁으로 바꾼 실행 복사본에서 재검증했다. 에이전트 호출, 스트리밍, 서브에이전트, 후속 셀은 실제 게이트웨이 LLM을 사용했고 한·영 6개 모두 끝까지 통과했다. 마지막 영어 subagents 재실행은 `gpt-5.5` 쿨다운 후 `qwen3.6-35b`로 완료했다.
- 종합하면 150개 노트북 경로 모두에서 셀 흐름을 끝까지 검증했다. 144개는 외부 LLM 호출까지 원형대로 통과했고, 6개는 Tavily 검색 호출만 스텁으로 격리했다. 현재까지 노트북 소스의 Python 예외로 판정된 실패는 없다.
- 전체 실행 중 10개 셀은 실행 복사본에서 의도적으로 제외했다. 패키지 설치 매직 2개, 비-OpenAI 공급자 호출 6개, 로컬 서버 실행 2개다. 이 셀들은 정적 구문·import 감사는 통과했지만 외부 공급자 또는 상주 프로세스의 실제 동작까지 보증하지 않는다.
- 실행 산출물과 오류 원문은 gitignored `local/notebook_execution_01_06_py314_latest/` 및 재실행 디렉터리에 보관했다. 프록시 키와 기타 비밀값은 리포트와 산출물에 기록하지 않았다.

## 의존성 갱신

- `uv lock --upgrade`로 lockfile의 전체 호환 버전을 다시 해석하고 Python 3.14 환경을 `uv sync --all-extras`로 동기화했다.
- 직접 의존성 기준 주요 버전은 `langchain 1.3.13`, `langchain-core 1.4.9`, `langgraph 1.2.9`, `deepagents 0.6.12`, `langchain-openai 1.3.5`, `langsmith 0.10.2`, `langfuse 4.14.0`, `pydantic 2.13.4`다.
- `langchain-community`는 비-semver 패키지이므로 `>=0.4.2,<0.5.0` 범위를 유지했다. 나머지 직접 의존성의 최소 버전도 이번 lockfile 검증 기준으로 올렸다.

## 환경 경고 판정

- 기존 Python 3.14 경고는 `pydantic 2.12.5`에 포함된 v1 호환 namespace가 Python 3.14를 지원하지 않아 발생했다. `pydantic 2.13.4`와 `pydantic-core 2.46.4`로 올린 뒤 Python 3.14.3에서 `langchain-core`, FAISS, SQLDatabase import와 11개 회귀 테스트가 해당 경고 없이 통과했다. 프로젝트 기본 버전은 `.python-version`의 3.14로 복구했다.
- `langchain-community 0.4.2` 경고는 패키지 최상위 `__init__.py`가 import될 때마다 직접 출력하는 sunset 안내다. 이번 감사에서는 FAISS와 SQLDatabase 심볼 검증이 해당 import를 유발했다. 실행 실패는 아니지만 패키지가 더 이상 적극 유지보수되지 않으므로 해당 구성요소의 독립 통합 패키지 또는 직접 구현 전환을 추적해야 한다.
- `ipykernel 7.3.0`은 로컬 테스트 커널이 암호화되지 않은 TCP transport를 사용한다는 경고를 출력했다. 현재 커널은 loopback 개발 실행에만 사용하며, 원격/공유 호스트에서는 CurveZMQ 키 또는 IPC transport를 사용해야 한다.

## 산출물

- 한국어 핸드북: `book/agent-handbook.pdf` (629쪽)
- 영어 핸드북: `en/book/agent-handbook-en.pdf` (614쪽)
- 로컬 검사: `scripts/check_official_docs_alignment.py`
- 셀 감사: `scripts/audit_notebook_cells.py`
- CI: `.github/workflows/official-docs-alignment.yml`

두 PDF는 표지, HITL, LangGraph 인터럽트, 마지막 페이지를 PNG로 렌더링해 잘림·빈 페이지·코드 블록 붕괴가 없는지 확인했다.

## 남은 리스크

652개 장문 코드 셀은 기존 스타일 부채다. 게이트웨이가 원본 기본 모델인 `gpt-5.4`를 제공하지 않아 실행 복사본은 `gpt-5.5`와 `qwen3.6-35b`를 사용했다. Tavily 의존 노트북 6개는 사용량 한도가 복구되기 전까지 실제 검색 성공을 보증하지 않으며, 의도적으로 제외한 10개 런타임 셀도 각 공급자 키 또는 별도 서버 환경에서 확인해야 한다. `langchain-community` 사용부는 sunset 일정에 맞춘 마이그레이션 추적이 필요하다.
