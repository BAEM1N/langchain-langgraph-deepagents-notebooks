# 공식 문서 정합성 개선 구현 계획

**목표:** `01`~`06`을 주 대상으로 모든 노트북 셀을 검사하고 현재 공식 계약과 맞춘다. `07`은 최신 정합성만 수정하고 `08`은 완전히 제외한다.

**도구:** Python 3.12+, uv, Jupyter Notebook JSON, LangChain, LangGraph, Deep Agents, Typst

## 제약

- 한국어 설명과 영어 코드를 유지한다.
- 기본 모델은 `gpt-5.4`다.
- 새 외부 의존성을 추가하지 않는다.
- 호스팅 공식 문서와 안정 패키지가 다르면 안정판에서 존재하지 않는 API를 구현하지 않는다.
- `08_integration/`은 읽기·수정·검사·백로그 작성에서 제외한다.

## 완료 작업

- [x] `01`~`06` 한·영 전체 노트북을 셀 단위로 감사하는 도구와 회귀 테스트 추가
- [x] LangGraph `interrupt()` 입력 검증을 노드당 한 번 호출하는 상태 전이 구조로 수정
- [x] 프로덕션 예제를 `create_agent()`로 교체
- [x] HITL의 `reject`와 `respond` 의미를 부작용 도구와 질문형 도구로 분리
- [x] `LocalShellBackend(virtual_mode=True)`가 셸 샌드박스가 아님을 문서와 예제에 반영
- [x] Deep Agents 안정 버전을 `0.6.12`로 올리고 `delete`의 안정판/프리릴리스 차이를 검증·기록
- [x] 현재 import 경로와 결과 타입에 맞게 미들웨어·커스텀 backend 예제 수정
- [x] `01`~`06` 기본 모델을 `gpt-5.4`로 통일하고 깨진 로컬 링크와 Markdown fence 수정
- [x] `07_examples/`의 RAG·SQL·HITL·LocalShell 최신 정합성만 수정
- [x] 변경 노트북에서 Typst 장을 재생성하고 한·영 PDF 빌드
- [x] 오프라인·온라인 드리프트 검사와 CI 경로 추가

## 검증 명령

```bash
uv run python scripts/audit_notebook_cells.py --format markdown
uv run python scripts/check_official_docs_alignment.py --local
uv run python scripts/check_official_docs_alignment.py --online
uv run python -m unittest discover -s tests -v
uv run python book/scripts/build.py --compile-only
uv run python en/book/scripts/build.py
```

## 완료 판정

- 셀 감사: 150개 노트북, 2,973개 셀, 오류 0건
- 결정론적 실행 계약: interrupt 왕복, backend 결과, HITL policy 통과
- `08_integration/`: 변경 0건
- 한·영 PDF: Typst compile 성공
- 남은 항목: 기존 10줄 초과 코드 셀 652개는 스타일 부채로 보고
