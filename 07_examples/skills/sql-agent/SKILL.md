---
name: sql-agent
description: >
  자연어 SQL 질의 에이전트 가이드.
  SQLDatabaseToolkit 활용, READ-ONLY 안전 규칙, HITL 승인 패턴을 다룹니다.
license: MIT
compatibility: Python 3.12+
metadata:
  category: sql
  difficulty: intermediate
allowed-tools: sql_db_list_tables sql_db_schema sql_db_query sql_db_query_checker
---

# SQL Agent 스킬

## 사용 시기
- 사용자가 자연어로 데이터베이스를 질의할 때
- SQL 쿼리 생성 및 실행을 자동화할 때
- 데이터베이스 스키마를 탐색하고 분석할 때

## 워크플로: query-writing
1. `sql_db_list_tables` — 사용 가능한 테이블 목록 확인
2. `sql_db_schema` — 관련 테이블의 DDL(CREATE TABLE) 조회
3. SQL 쿼리 작성 — 스키마를 기반으로 정확한 쿼리 생성
4. `sql_db_query_checker` — 쿼리 문법 및 안전성 검증
5. `sql_db_query` — 검증된 쿼리 실행

## 워크플로: schema-exploration
1. `sql_db_list_tables` — 전체 테이블 목록
2. `sql_db_schema` — 각 테이블 DDL 조회
3. 관계 매핑 — FK 관계 파악 후 정리

## 안전 규칙 (READ-ONLY)
- **SELECT만 허용**: INSERT, UPDATE, DELETE, DROP, ALTER 금지
- **LIMIT 필수**: 항상 `LIMIT 10` (또는 사용자 지정 값) 사용
- **스키마 확인 필수**: 쿼리 작성 전 반드시 테이블 스키마 확인
- **HITL 승인**: `sql_db_query` 실행 전 사람의 승인 획득 (프로덕션)

## HITL 패턴
```python
# HumanInTheLoopMiddleware로 sql_db_query 실행 전 중단
middleware=[
    HumanInTheLoopMiddleware(interrupt_on={"sql_db_query": True}),
]
# Command(resume="approve")로 재개
```
