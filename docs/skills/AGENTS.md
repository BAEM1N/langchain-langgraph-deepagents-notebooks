# LangChain Skills — Master Routing Guide

코딩 에이전트가 LangChain, LangGraph, Deep Agents 코드를 작성할 때 **반드시 관련 스킬을 먼저 참조**해야 한다.

## 스킬 목록

### Getting Started
| 스킬 | 설명 |
|------|------|
| `framework-selection` | LangChain vs LangGraph vs Deep Agents 선택 기준 |
| `langchain-dependencies` | 패키지 버전 관리 |

### LangChain Skills
| 스킬 | 설명 |
|------|------|
| `langchain-fundamentals` | `create_agent`, `@tool`, 미들웨어 |
| `langchain-v1-modern` | LangChain v1 가드레일 (`create_agent` 우선, `create_react_agent`/LCEL 회피) |
| `langchain-rag` | RAG 파이프라인 |
| `langchain-middleware` | HITL, 커스텀 미들웨어 |

### LangGraph Skills
| 스킬 | 설명 |
|------|------|
| `langgraph-fundamentals` | StateGraph, 노드, 엣지 |
| `langgraph-persistence` | 체크포인터, 메모리 |
| `langgraph-human-in-the-loop` | interrupt, Command |
| `langgraph-docs-official` | LangChain 공식 example skill 기반 LangGraph docs fetcher |

### Deep Agents Skills
| 스킬 | 설명 |
|------|------|
| `deep-agents-core` | 하네스 아키텍처, SKILL.md 형식 |
| `deep-agents-memory` | 백엔드, StoreBackend |
| `deep-agents-orchestration` | 서브에이전트, TodoList |

## 필수 환경 변수

```
OPENAI_API_KEY=...
ANTHROPIC_API_KEY=...
```

## 사용 원칙

1. 코드 작성 **전에** 관련 스킬 참조
2. 스킬이 제공하는 패턴과 API를 우선 사용
3. 여러 프레임워크가 관련되면 `framework-selection` 먼저 확인
