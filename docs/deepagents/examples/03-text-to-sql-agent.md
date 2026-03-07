# Text-to-SQL Agent

## Overview

자연어를 SQL로 변환하는 에이전트로, SQLDatabaseToolkit, Skills 기반 워크플로, `write_todos` 계획 도구를 활용한다. Chinook 데모 데이터베이스를 사용한다.

**원본:** [examples/text-to-sql-agent](https://github.com/langchain-ai/deepagents/tree/main/examples/text-to-sql-agent)

## Directory Structure

```
text-to-sql-agent/
├── .env.example
├── AGENTS.md                    # 에이전트 정체성 + SQL 가이드라인
├── README.md
├── agent.py                     # 메인 에이전트 + CLI
├── pyproject.toml
└── skills/
    ├── query-writing/
    │   └── SKILL.md             # SQL 쿼리 작성 워크플로
    └── schema-exploration/
        └── SKILL.md             # DB 구조 탐색 워크플로
```

## Source Code

### AGENTS.md

```markdown
# SQL Database Agent

## Role
- Explore tables and schemas
- Generate SQL queries
- Execute and format results

## Safety Rules
- READ-ONLY: no INSERT, UPDATE, DELETE, DROP
- Always verify schema before querying
- Use write_todos for complex multi-step queries
```

### agent.py

```python
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend
from langchain_anthropic import ChatAnthropic
from langchain_community.utilities import SQLDatabase
from langchain_community.agent_toolkits import SQLDatabaseToolkit

# DB 연결
db = SQLDatabase.from_uri("sqlite:///chinook.db")

# SQL 도구 자동 생성
model = ChatAnthropic(model="claude-sonnet-4-5-20250929")
toolkit = SQLDatabaseToolkit(db=db, llm=model)
sql_tools = toolkit.get_tools()

# 에이전트 생성
agent = create_deep_agent(
    model=model,
    memory=["./AGENTS.md"],
    skills=["./skills/"],
    tools=sql_tools,
    backend=FilesystemBackend(root_dir="./output"),
)
```

### skills/query-writing/SKILL.md

```yaml
---
name: query-writing
description: Write and execute SQL queries against the database
---
```

**단순 쿼리 워크플로:**
1. 테이블 식별
2. 스키마 확인
3. SQL 작성
4. 실행
5. 결과 포맷팅

**복합 쿼리 워크플로:**
1. `write_todos`로 계획 수립
2. 스키마 조사
3. JOIN 구성
4. 검증 및 실행

### skills/schema-exploration/SKILL.md

```yaml
---
name: schema-exploration
description: Discover database structure, tables, and relationships
---
```

워크플로: 테이블 목록 → 스키마 확인 → 관계 매핑. Chinook DB 예시: Artist → Album → Track → InvoiceLine 체인.

## Setup & Usage

```bash
cd text-to-sql-agent
uv sync
export ANTHROPIC_API_KEY=...
python agent.py
# CLI 옵션:
python agent.py --query "가장 많이 팔린 아티스트 5명"
```

## Key Concepts

| 개념 | 설명 |
|------|------|
| `SQLDatabaseToolkit` | DB 연결 → SQL 도구 자동 생성 (`list_tables`, `get_schema`, `query`) |
| `AGENTS.md` | READ-ONLY 안전 규칙 등 에이전트 정체성 |
| `skills/` | 쿼리 작성 / 스키마 탐색 워크플로를 스킬로 분리 |
| `write_todos` | 복합 쿼리 시 계획 수립 내장 도구 |
| `FilesystemBackend` | 쿼리 결과를 파일로 저장 |
