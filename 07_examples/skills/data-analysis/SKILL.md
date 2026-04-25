---
name: data-analysis
description: >
  데이터 분석 에이전트 가이드.
  LocalShellBackend로 pandas 코드를 실행하고, 멀티턴 분석을 수행합니다.
license: MIT
compatibility: Python 3.12+
metadata:
  category: analysis
  difficulty: intermediate
allowed-tools: execute write_todos data_summary
---

# Data Analysis 스킬

## 사용 시기
- 사용자가 CSV, Excel 등 데이터 분석을 요청할 때
- pandas 코드를 실행하여 통계, 집계, 시각화를 생성할 때
- 반복적 분석(멀티턴)이 필요할 때

## 워크플로
1. **Plan**: `write_todos`로 분석 계획 작성
2. **Explore**: 데이터 구조 파악 (행 수, 컬럼, 타입, 결측치)
3. **Analyze**: `execute`로 pandas 코드 실행
4. **Iterate**: 후속 질문으로 심화 분석
5. **Deliver**: 결과를 표 형식으로 정리

## 분석 체크리스트
- [ ] 데이터 요약 (shape, dtypes, describe)
- [ ] 결측치 확인 및 처리
- [ ] 그룹별 집계 (groupby)
- [ ] 수치는 천 단위 구분자 사용 (예: 1,234,567)
- [ ] 결과는 마크다운 표로 정리

## 코드 실행 규칙
- `LocalShellBackend(virtual_mode=True)` 사용 필수
- `execute` 도구로 Python/pandas 코드 실행
- 한 번에 너무 많은 코드를 실행하지 않기 — 단계별 실행
- 에러 발생 시 원인 분석 후 수정된 코드 재실행

## 멀티턴 패턴
```python
# InMemorySaver + 동일 thread_id → 대화 맥락 유지
checkpointer=InMemorySaver()
config = {"configurable": {"thread_id": "analysis-1"}}
```
