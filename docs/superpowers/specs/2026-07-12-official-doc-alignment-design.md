# 공식 문서 정합성 개선 설계

## 목표와 범위

한국어·영어 `01_beginner/`~`06_langsmith/`를 주 검증 대상으로 삼아 현재 LangChain·LangGraph·Deep Agents 계약과 충돌하는 설명과 코드를 바로잡는다. `07_examples/`는 최신 API·버전·공식 링크 정합성만 맞추고, `08_integration/`은 읽기·수정·검사 대상에서 완전히 제외한다.

파생 Typst 장과 한·영 PDF를 원본 노트북에서 다시 만들며, 동일한 회귀를 조기에 발견할 수 있도록 오프라인 셀 감사와 선택적 공식 문서 감시를 분리한다.

## 설계 원칙

1. 공식 행동 계약과 설치된 안정 버전의 실제 런타임을 함께 확인한다.
2. 호스팅 문서가 안정 패키지보다 앞선 경우 기능을 지어내지 않고 차이를 명시한다.
3. 한국어 노트북, 영어 미러, Typst 장, PDF를 같은 변경 집합으로 취급한다.
4. 외부 API 키·비용·부작용이 필요한 셀은 정적 검증하고, 결정론적인 계약은 로컬 실행 테스트로 보강한다.
5. `07_examples/`에는 필요한 정합성 수정만 적용하고 `08_integration/`에는 백로그도 만들지 않는다.

## 수정한 계약

### LangGraph 인터럽트 입력 검증

노드 내부 반복문에서 `interrupt()`를 다시 호출하는 패턴을 제거한다. 노드 실행당 한 번 인터럽트하고, 잘못된 입력은 상태에 질문을 기록한 뒤 조건부 엣지가 같은 노드로 재진입한다. 체크포인터를 사용한 invalid→valid 왕복 테스트로 재개 동작을 검증한다.

### LangChain 에이전트와 HITL

프로덕션 예제는 `langchain.agents.create_agent`를 사용한다. 부작용 도구는 `approve/edit/reject`, 질문형 `ask_user` 도구는 `respond`만 허용한다. `respond`를 이메일 전송·삭제·SQL 실행의 성공이나 거절처럼 설명하지 않는다.

### LocalShellBackend 경계

`virtual_mode=True`는 파일 도구 경로 정규화이며 셸 격리가 아니다. 로컬 실습은 전용 `root_dir`, 최소 환경 변수, `inherit_env=False`, 실행 승인을 함께 사용하되 개발용 피해 축소 설정으로 설명한다. 운영 환경은 실제 sandbox backend가 필요하다.

### Deep Agents 안정 버전과 호스팅 문서 차이

안정 버전은 `deepagents==0.6.12`로 맞춘다. 이 버전의 `BackendProtocol`에는 `delete`가 없지만 현재 호스팅 백엔드 문서와 `0.7.0a6` 프리릴리스에는 선택적 `delete(file_path) -> DeleteResult`가 있다. 안정판 교재에서는 삭제 기능을 구현하거나 실행하지 않고 이 버전 차이만 명시한다.

### 링크와 모델

`01`~`06`의 기본 모델 표기는 저장소 정책인 `gpt-5.4`로 통일한다. `07_examples/`의 RAG·SQL 공식 링크는 현재 `docs.langchain.com` 경로로 바꾸며, `08_integration/`은 검색 범위에서도 제외한다.

## 검증 구조

- `scripts/audit_notebook_cells.py`: `01`~`06` 한·영 전체 셀의 JSON, 순차 ID, Python 구문, import symbol, 로컬 링크, Markdown fence를 검사한다.
- `scripts/check_official_docs_alignment.py --local`: 금지 패턴, 대상 계약, 버전, 공식 링크를 오프라인으로 검사한다.
- `scripts/check_official_docs_alignment.py --online`: watchlist의 공식 문서 URL과 짧은 의미 앵커를 확인한다.
- `tests/test_material_contracts.py`: 인터럽트 왕복, HITL 정책, 커스텀 backend, 안정판 `delete` 부재를 실행 검증한다.
- `.github/workflows/official-docs-alignment.yml`: PR에서는 오프라인 검사, 정기·수동 실행에서는 온라인 검사까지 수행한다.

## 성공 기준

- `01`~`06` 한·영 150개 노트북의 모든 셀이 오프라인 감사에서 오류 0건이다.
- 변경한 결정론적 코드 계약이 로컬 실행 테스트를 통과한다.
- `07_examples/`의 대상 API·링크가 최신 경로와 일치한다.
- `08_integration/`에는 변경이 없다.
- 한·영 Typst와 PDF가 원본 노트북에서 재생성되고 빌드된다.
- 로컬·온라인 정합성 검사와 전체 단위 테스트가 통과한다.

## 알려진 한계

- API 키, 네트워크, 비용 또는 외부 부작용이 필요한 모든 셀을 실제 실행하지 않는다. 대신 Python 구문·import·링크를 전수 검사하고 변경 계약은 결정론적 테스트로 실행한다.
- 코드 셀 10줄 지침을 넘는 기존 셀은 스타일 경고로 별도 집계한다. 이번 변경은 API·실행 정합성에 집중하며 652개 기존 장문 셀의 전면 분할은 범위에 포함하지 않는다.
