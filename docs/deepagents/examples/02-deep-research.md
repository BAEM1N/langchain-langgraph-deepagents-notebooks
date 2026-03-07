# Deep Research Agent

## Overview

다단계 웹 리서치 에이전트로, Tavily URL 탐색, 병렬 서브에이전트, think 도구를 활용한 전략적 반성, 5단계 워크플로를 구현한다.

**원본:** [examples/deep_research](https://github.com/langchain-ai/deepagents/tree/main/examples/deep_research)

## Directory Structure

```
deep_research/
├── .env.example
├── README.md
├── agent.py                     # 메인 에이전트 정의
├── langgraph.json               # LangGraph 서버 설정
├── pyproject.toml
├── research_agent.ipynb         # Jupyter 노트북 워크스루
├── utils.py                     # Rich 디스플레이 유틸리티
└── research_agent/
    ├── __init__.py
    ├── prompts.py               # 3개 프롬프트 템플릿
    └── tools.py                 # tavily_search + think_tool
```

## Source Code

### agent.py

```python
from deepagents import create_deep_agent
from langchain import init_chat_model
from research_agent.prompts import (
    RESEARCH_WORKFLOW_INSTRUCTIONS,
    RESEARCHER_INSTRUCTIONS,
)
from research_agent.tools import tavily_search, think_tool

model = init_chat_model("anthropic:claude-sonnet-4-5-20250929")

research_sub_agent = {
    "name": "research-agent",
    "model": model,
    "description": "A research agent that can search the web",
    "system_prompt": RESEARCHER_INSTRUCTIONS,
    "tools": [tavily_search, think_tool],
}

agent = create_deep_agent(
    model=model,
    tools=[tavily_search, think_tool],
    system_prompt=RESEARCH_WORKFLOW_INSTRUCTIONS,
    subagents=[research_sub_agent],
)
```

### research_agent/prompts.py

**RESEARCH_WORKFLOW_INSTRUCTIONS** — 5단계 워크플로:
1. Plan: 주제 분석 및 리서치 계획 수립
2. Save Request: `write_todos`로 작업 계획 저장
3. Delegate: 서브에이전트에 병렬 위임 (기본 1개, 비교 시 최대 3개)
4. Synthesize: 결과 통합 및 분석
5. Write Report: `/final_report.md`에 최종 보고서 작성

인용 형식: `[1], [2]` 인라인 + `### Sources` 섹션

**SUBAGENT_DELEGATION_INSTRUCTIONS**:
- 기본 서브에이전트 1개, 비교 분석 시만 병렬화
- 최대 동시 실행 3개, 최대 라운드 3회

**RESEARCHER_INSTRUCTIONS**:
- 단순 주제: 2-3회 검색, 복잡한 주제: 최대 5회
- 매 검색 후 `think_tool`로 반성

### research_agent/tools.py

```python
from langchain_core.tools import tool, InjectedToolArg
from tavily import TavilyClient
import httpx
from markdownify import markdownify

@tool
def tavily_search(
    query: str,
    max_results: Annotated[int, InjectedToolArg] = 5,
    topic: Annotated[str, InjectedToolArg] = "general",
) -> str:
    """Search the web using Tavily for URL discovery,
    then fetch full page content."""
    client = TavilyClient()
    results = client.search(query, max_results=max_results, topic=topic)
    # httpx로 전체 페이지 가져오기
    for r in results["results"]:
        resp = httpx.get(r["url"], timeout=10)
        r["full_content"] = markdownify(resp.text)
    return results

@tool
def think_tool(thought: str) -> str:
    """Strategic reflection — record your thinking
    for better decision-making."""
    return f"Reflection recorded: {thought}"
```

### langgraph.json

```json
{
  "dependencies": ["."],
  "graphs": {"research": "./agent.py:agent"},
  "env": ".env"
}
```

## Setup & Usage

```bash
cd deep_research
uv sync
export ANTHROPIC_API_KEY=...
export TAVILY_API_KEY=...
python agent.py
# 또는 LangGraph 서버:
langgraph dev
```

## Key Concepts

| 개념 | 설명 |
|------|------|
| 병렬 서브에이전트 | `task` 도구로 여러 리서처를 동시 실행 |
| `think_tool` | 검색 후 전략적 반성 — 다음 행동 결정에 활용 |
| `tavily_search` | URL 발견 → `httpx`로 전체 페이지 → `markdownify`로 변환 |
| `InjectedToolArg` | 에이전트가 아닌 시스템이 주입하는 파라미터 |
| `write_todos` | 내장 도구 — 리서치 계획을 파일로 저장 |
| 5단계 워크플로 | Plan → Save → Delegate → Synthesize → Report |
