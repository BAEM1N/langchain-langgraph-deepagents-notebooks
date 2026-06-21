# Tutorial Update and Addition Backlog from Official Docs — 2026-06-21

## 목적

2026-06-19 공식 LangChain OSS Python 문서 스냅샷 148개 페이지를 `docs/` canonical reference note로 추가한 뒤, **튜토리얼/노트북에 반영해야 할 변경사항 전체**를 정리한다.

요청 조건: 우선순위가 아니라 **모든 변경사항을 반영**한다. 따라서 아래 목록은 “먼저/나중”이 아니라 누락 방지를 위한 전체 백로그다.

## 입력 근거

- 공식 원문 스냅샷: `local/official_langchain_docs_2026-06-19/`
- 공식 페이지 인벤토리: `local/official_langchain_docs_2026-06-19/inventory.csv`
- canonical coverage manifest: `docs/verification/2026-06-21-official-canonical-slug-coverage.md`
- gap assessment: `docs/verification/2026-06-19-official-docs-coverage-assessment.md`
- 페이지별 action matrix: `docs/verification/2026-06-21-official-docs-action-matrix.csv`
- 사람이 읽는 action matrix: `docs/verification/2026-06-21-official-docs-action-matrix.md`
- 대상 파일별 구현 체크리스트: `docs/verification/2026-06-21-tutorial-implementation-checklist.md`

## 반영 방식 구분

| 구분 | 의미 |
|---|---|
| 기존 튜토리얼 업데이트 | 이미 있는 노트북/챕터에 공식 문서 변화나 새 용어를 반영한다. |
| 신규 코어 튜토리얼 | `01`-`07` 기본 학습 트랙에 새 노트북을 추가한다. 기본 smoke 대상이다. |
| 신규 integration 튜토리얼 | `08_integration/`에 추가한다. frontend, CLI, server, protocol, cloud/provider처럼 기본 smoke에 넣기 어려운 항목이다. |
| 레퍼런스/인덱스 반영 | 독립 실습보다 문서 지도, README, cross-reference, migration note가 적합한 항목이다. |

---

# 1. 전역/공통 개념 반영

공식 신규/확장 표면:

- `learn`
- `concepts/products`
- `concepts/providers-and-models`
- `concepts/memory`
- `concepts/context`
- `langchain/academy`
- `langchain/get-help`
- LangChain/LangGraph/Deep Agents `install`, `changelog-py`

## 기존 튜토리얼 업데이트

| 대상 | 반영 내용 |
|---|---|
| `01_beginner/00_setup.ipynb` | 공식 install 문서 기준으로 `uv`, Python 버전, optional provider key, LangSmith/Langfuse 환경 변수 설명 최신화. |
| `01_beginner/06_comparison.ipynb` | `concepts/products` 기준으로 Framework / Runtime / Harness 용어를 명확히 구분. Deep Agents → LangChain → LangGraph 선택 기준 업데이트. |
| `02_langchain/01_introduction.ipynb` | LangChain을 “Model + Harness”로 설명하는 공식 overview/philosophy/component architecture 반영. |
| `03_langgraph/01_introduction.ipynb` | LangGraph를 low-level orchestration runtime으로 설명하고, LangChain/Deep Agents와의 관계를 products 문서 기준으로 업데이트. |
| `04_deepagents/01_introduction.ipynb` | Deep Agents를 batteries-included harness로 설명하고, LangChain agent 및 LangGraph runtime 위에 구성된다는 점 정리. |
| `README.md`, `docs/README.md`, `en/README.md` | `docs/concepts/`, canonical reference note, official Learn mapping 안내 추가. |
| `docs/skills/framework-selection.md` | 공식 `products`, `providers-and-models`, `context`, `memory` 기준으로 선택 규칙 업데이트. |

## 신규 코어 튜토리얼

| 신규 후보 | 위치 | 설명 |
|---|---|---|
| Framework Selection & Product Map | `01_beginner/08_framework_selection_map.ipynb` 또는 기존 `06_comparison` 확장 | 공식 concepts 전체를 실습 전 읽는 orientation 장으로 만들 수 있다. 단, 기존 비교 장을 크게 보강하면 별도 노트북은 생략 가능. |

## 레퍼런스/인덱스 반영

- `docs/concepts/*`를 README와 노트북 참고문서 셀에 연결.
- `academy`, `get-help`, `changelog-py`는 독립 실습보다는 각 파트 마지막 참고문서/유지보수 체크리스트에 연결.

---

# 2. LangChain 코어 튜토리얼 반영

공식 표면:

- `langchain/overview`, `quickstart`, `agents`
- `models`, `messages`, `tools`, `structured-output`
- `middleware/overview`, `middleware/built-in`, `middleware/custom`
- `guardrails`, `runtime`, `context-engineering`
- `short-term-memory`, `long-term-memory`
- `streaming`, `event-streaming`
- `mcp`, `human-in-the-loop`
- `retrieval`, `knowledge-base`, `rag`, `sql-agent`, `voice-agent`
- `deep-agent-from-scratch`

## 기존 튜토리얼 업데이트

| 대상 | 반영 내용 |
|---|---|
| `02_langchain/02_quickstart.ipynb` | 공식 quickstart와 agent overview 예제 구조 재확인. `create_agent` 중심, model/tool/system_prompt 조합을 최신 표현으로 통일. |
| `02_langchain/03_models_and_messages.ipynb` | `models`, `messages`, `providers-and-models` 문서 기준으로 provider/model identifier, message roles, content block 설명 업데이트. |
| `02_langchain/04_tools_and_structured_output.ipynb` | `tools`, `structured-output` 기준으로 tool schema, validation, structured output provider/tool strategy 설명 보강. |
| `02_langchain/05_memory_and_streaming.ipynb` | short-term vs long-term memory, streaming vs event-streaming 구분 추가. |
| `02_langchain/06_middleware.ipynb` | prebuilt/custom middleware 최신 hook, runtime interaction, guardrail 연결 업데이트. |
| `02_langchain/07_hitl_and_runtime.ipynb` | `human-in-the-loop`, `runtime`, middleware interruption/approval 경계 업데이트. |
| `02_langchain/09_custom_workflow_and_rag.ipynb` | `retrieval`, `knowledge-base`, `rag` 공식 튜토리얼 흐름과 semantic search → RAG 순서 연결. |
| `02_langchain/10_production.ipynb` | deploy, observability, studio, test/evals 문서 링크와 운영 체크리스트 업데이트. |
| `02_langchain/11_mcp.ipynb` | 공식 MCP 문서와 Deep Agents MCP 문서 차이 반영. MCP tools는 integration track gate도 명시. |
| `02_langchain/12_frontend_streaming.ipynb` | frontend pages 전체와 event-streaming protocol 반영. `streaming`과 `event-streaming` 용어 분리. |
| `02_langchain/13_guardrails.ipynb` | guardrails + middleware built-in/custom 연결 강화. |
| `05_advanced/00_migration.ipynb` | `changelog-py`, backward compatibility, current v1 idioms 반영. |
| `05_advanced/01_middleware.ipynb` | middleware + guardrails + runtime + context engineering 심화 최신화. |
| `05_advanced/04_context_memory.ipynb` | `concepts/context`, `concepts/memory`, LangChain short/long-term memory 반영. |
| `05_advanced/06_sql_agent.ipynb` | 공식 SQL agent + skills SQL assistant와 연결. HITL/approval 안전규칙 재점검. |
| `05_advanced/08_voice_agent.ipynb` | 공식 voice-agent 튜토리얼의 speak/listen 구성과 현재 local implementation 차이 반영. |

## 신규 코어 튜토리얼

| 신규 튜토리얼 | 권장 위치 | 공식 근거 | 내용 |
|---|---|---|---|
| Semantic Search Minimal | `02_langchain/14_semantic_search.ipynb` 또는 `07_examples/08_semantic_search.ipynb` | `langchain/knowledge-base` | PDF/문서 → splitter → embeddings → vector store → retriever. RAG 전에 retrieval-only 학습. |
| LangChain Testing Strategy | `06_langsmith/07_testing_strategy.ipynb` + `en/06_langsmith/07_testing_strategy.ipynb` | `langchain/test/index`, `unit-testing`, `integration-testing`, `evals` | mock model, deterministic unit tests, integration key gates, trajectory evals, replay/cost controls. |
| Deep Agent from Scratch | `05_advanced/10_deep_agent_from_scratch.ipynb` 또는 `07_examples/09_deep_agent_from_scratch.ipynb` | `langchain/deep-agent-from-scratch` | Deep Agents 기능을 LangChain primitives로 직접 조립해 harness 구조를 이해. |

## 신규 integration 튜토리얼

| 신규 튜토리얼 | 권장 위치 | 공식 근거 | 내용 |
|---|---|---|---|
| LangChain Frontend Foundations | `08_integration/14_langchain_frontend_foundations/` | `langchain/frontend/overview`, `markdown-messages`, `tool-calling`, `structured-output`, `reasoning-tokens` | React/useStream 기반 메시지, tool call, structured output 렌더링. |
| Branching / Time Travel Chat UI | `08_integration/15_branching_time_travel_chat/` | `frontend/branching-chat`, `frontend/time-travel` | thread branch, checkpoint rewind, UI state. |
| Human-in-the-loop Frontend | `08_integration/16_frontend_hitl/` | `frontend/human-in-the-loop`, `headless-tools` | approval UX, headless tools, queue/rejoin. |
| Frontend Integrations Survey | `08_integration/17_frontend_integrations/` | `ai-elements`, `assistant-ui`, `copilotkit`, `openui` | 각 UI library 연결 방식 비교. |

## 레퍼런스/인덱스 반영

- `langchain/academy`, `get-help`, `philosophy`, `component-architecture`는 `02_langchain/01_introduction` 참고문서와 docs index에 연결.
- `deploy`, `observability`, `studio`, `ui`는 `06_langsmith` 및 `08_integration` index에 연결.

---

# 3. LangChain Multi-agent 튜토리얼 반영

공식 표면:

- `multi-agent/index`
- `multi-agent/subagents`
- `multi-agent/subagents-personal-assistant`
- `multi-agent/handoffs`
- `multi-agent/handoffs-customer-support`
- `multi-agent/router`
- `multi-agent/router-knowledge-base`
- `multi-agent/skills`
- `multi-agent/skills-sql-assistant`
- `multi-agent/custom-workflow`

## 기존 튜토리얼 업데이트

| 대상 | 반영 내용 |
|---|---|
| `02_langchain/08_multi_agent.ipynb` | multi-agent taxonomy를 공식 index 기준으로 재정리: subagents, handoffs, router, skills, custom workflow. |
| `05_advanced/02_multi_agent_subagents.ipynb` | personal assistant subagents 튜토리얼 패턴 반영. supervisor/subagent tool scope와 context handoff 설명 보강. |
| `05_advanced/03_multi_agent_handoffs_router.ipynb` | handoffs customer support와 router knowledge base를 각각 분리된 패턴으로 더 명확히 설명. |
| `07_examples/07_content_builder_agent.ipynb` | skills composition과 subagent delegation 공식 패턴 링크 추가. |

## 신규 코어 튜토리얼

| 신규 튜토리얼 | 권장 위치 | 공식 근거 | 내용 |
|---|---|---|---|
| Personal Assistant with Subagents | `07_examples/10_personal_assistant_subagents.ipynb` | `multi-agent/subagents-personal-assistant` | calendar/email/research 같은 역할별 subagent delegation. |
| Customer Support Handoffs | `07_examples/11_customer_support_handoffs.ipynb` | `multi-agent/handoffs-customer-support` | 상태/담당자 전환, policy escalation, handoff trace. |
| Multi-source Knowledge Base Router | `07_examples/12_router_knowledge_base.ipynb` | `multi-agent/router-knowledge-base` | source selection, specialized retrievers/agents, routing eval. |
| SQL Assistant with On-demand Skills | `07_examples/13_skills_sql_assistant.ipynb` | `multi-agent/skills-sql-assistant` | SKILL.md progressive disclosure + SQL safety + HITL. |
| Custom Workflow Agent | `05_advanced/11_custom_workflow_agent.ipynb` | `multi-agent/custom-workflow` | agent loop와 deterministic workflow 조합. |

---

# 4. LangGraph 튜토리얼 반영

공식 표면:

- `overview`, `quickstart`, `install`
- `thinking-in-langgraph`, `workflows-agents`
- `graph-api`, `use-graph-api`
- `functional-api`, `use-functional-api`
- `choosing-apis`
- `persistence`, `checkpointers`, `stores`, `add-memory`
- `interrupts`, `use-time-travel`, `use-subgraphs`
- `durable execution`, `fault-tolerance`, `backward-compatibility`
- `event-streaming`, `streaming`
- `pregel`
- `local-server`, `studio`, `ui`, `deploy`, `observability`, `test`
- `agentic-rag`, `sql-agent`
- `frontend/overview`, `frontend/graph-execution`, `frontend/custom-stream-channels`
- `case-studies`

## 기존 튜토리얼 업데이트

| 대상 | 반영 내용 |
|---|---|
| `03_langgraph/01_introduction.ipynb` | overview/install/quickstart/thinking-in-langgraph 용어 업데이트. |
| `03_langgraph/02_graph_api.ipynb` | `graph-api`, `use-graph-api` 기준으로 StateGraph 사용 흐름과 state schema 설명 재검토. |
| `03_langgraph/03_functional_api.ipynb` | `functional-api`, `use-functional-api` 기준으로 entrypoint/task semantics 업데이트. |
| `03_langgraph/04_workflows.ipynb` | workflows-agents와 official workflow taxonomy 반영. |
| `03_langgraph/05_agents.ipynb` | LangGraph agentic RAG/SQL tutorials와 ReAct agent 구현 차이 설명. |
| `03_langgraph/06_persistence_and_memory.ipynb` | persistence/checkpointers/stores/add-memory 구분 강화. |
| `03_langgraph/07_streaming.ipynb` | streaming vs event-streaming, frontend custom channels 개념 추가. |
| `03_langgraph/08_interrupts_and_time_travel.ipynb` | interrupts/use-time-travel 공식 경로와 HITL checkpoint semantics 업데이트. |
| `03_langgraph/09_subgraphs.ipynb` | use-subgraphs 공식 guide 반영. |
| `03_langgraph/10_production.ipynb` | test, studio, deploy, observability, backward compatibility 연결. |
| `03_langgraph/11_local_server.ipynb` | local-server, frontend graph execution과 연결. |
| `03_langgraph/12_durable_execution.ipynb` | durable execution과 fault tolerance의 경계 명확화. |
| `03_langgraph/13_api_guide_and_pregel.ipynb` | choosing APIs, Pregel runtime, Graph/Functional API 비교 업데이트. |
| `03_langgraph/14_fault_tolerance.ipynb` | official fault-tolerance page 기준으로 retry/timeout/error_handler/defaults 재검토. |
| `05_advanced/05_agentic_rag.ipynb` | official LangGraph agentic-rag 튜토리얼과 매핑. |
| `05_advanced/06_sql_agent.ipynb` | official LangGraph custom SQL agent와 LangChain SQL agent 차이 반영. |

## 신규 코어 튜토리얼

| 신규 튜토리얼 | 권장 위치 | 공식 근거 | 내용 |
|---|---|---|---|
| LangGraph Backward Compatibility & Migration | `03_langgraph/15_backward_compatibility.ipynb` 또는 `05_advanced/12_langgraph_migration.ipynb` | `langgraph/backward-compatibility`, `changelog-py` | versioning, stable APIs, migration guardrails. |
| LangGraph Case Studies Review | `03_langgraph/16_case_studies.ipynb` | `langgraph/case-studies` | 공식 case study를 읽고 design pattern으로 분해. 실습은 짧은 architecture exercise. |
| LangGraph Testing Deep Dive | `06_langsmith/08_langgraph_testing.ipynb` | `langgraph/test` | graph unit tests, checkpointed integration tests, state assertions. |

## 신규 integration 튜토리얼

| 신규 튜토리얼 | 권장 위치 | 공식 근거 | 내용 |
|---|---|---|---|
| LangGraph Frontend Graph Execution | `08_integration/18_langgraph_frontend_graph_execution/` | `langgraph/frontend/graph-execution` | graph run state, command/resume, frontend execution controls. |
| LangGraph Custom Stream Channels | `08_integration/19_langgraph_custom_stream_channels/` | `langgraph/frontend/custom-stream-channels` | custom channel design, frontend event handling. |
| LangGraph Local Server + UI | `08_integration/20_langgraph_local_server_ui/` | `local-server`, `frontend/overview`, `ui` | local server, graph config, UI client. |

---

# 5. Deep Agents 튜토리얼 반영

공식 표면:

- `overview`, `quickstart`, `customization`, `comparison`
- `models`, `tools`
- `context-engineering`, `backends`
- `subagents`, `async-subagents`, `programmatic-subagents`
- `human-in-the-loop`, `permissions`
- `memory`, `skills`, `sandboxes`
- `profiles`, `interpreters`, `rubric`
- `streaming`, `event-streaming`
- `going-to-production`
- `mcp`, `acp`, `a2a`
- Tutorials: `data-analysis`, `deep-research`, `content-builder`
- Deep Agents Code: `code/overview`, `configuration`, `providers`, `mcp-tools`, `memory-and-skills`, `remote-sandboxes`, `subagents`, `data-locations`
- Frontend: `frontend/overview`, `sandbox`, `subagent-streaming`, `todo-list`

## 기존 튜토리얼 업데이트

| 대상 | 반영 내용 |
|---|---|
| `04_deepagents/01_introduction.ipynb` | overview/comparison/models/tools 최신화. Deep Agents와 Claude Agent SDK 비교 범위 재검토. |
| `04_deepagents/02_quickstart.ipynb` | quickstart 공식 코드 흐름, model/tool/basic invocation 최신화. |
| `04_deepagents/03_customization.ipynb` | customization, models, tools, context engineering 반영. |
| `04_deepagents/04_backends.ipynb` | backends, memory, data-locations, Store/Filesystem backend 차이 보강. |
| `04_deepagents/05_subagents.ipynb` | subagents + programmatic subagents + async subagents 관계 설명 추가. |
| `04_deepagents/06_memory_and_skills.ipynb` | memory, skills, code/memory-and-skills 연결. progressive disclosure와 StoreBackend 설명 재검토. |
| `04_deepagents/07_advanced.ipynb` | interpreters, profiles, rubric, programmatic subagents dependency gate, event streaming, mcp/a2a overview 추가. |
| `04_deepagents/08_harness.ipynb` | harness architecture와 going-to-production/rubric/profile 연결. |
| `04_deepagents/09_comparison.ipynb` | comparison with Claude Agent SDK와 products concepts 반영. |
| `04_deepagents/10_sandboxes_and_acp.ipynb` | sandboxes, remote sandboxes, ACP, A2A, MCP 경계 정리. |
| `04_deepagents/11_async_subagents.ipynb` | async subagents + event streaming + frontend subagent streaming 연결. |
| `05_advanced/07_data_analysis.ipynb` | official Deep Agents data-analysis 튜토리얼과 local sandbox policy 매핑. |
| `07_examples/03_data_analysis_agent.ipynb` | Deep Agents data-analysis와 LangChain tool/pandas agent 차이 설명. |
| `07_examples/05_deep_research_agent.ipynb` | official deep-research reflection/subagent flow와 비교. |
| `07_examples/07_content_builder_agent.ipynb` | official content-builder 튜토리얼 최신화, skills/subagents/filesystem artifacts 점검. |

## 신규 코어 튜토리얼

| 신규 튜토리얼 | 권장 위치 | 공식 근거 | 내용 |
|---|---|---|---|
| Deep Agents Models and Tools | `04_deepagents/12_models_and_tools.ipynb` | `deepagents/models`, `deepagents/tools` | model config, provider policy, tool schema, permission boundary. |
| Programmatic Subagents | `04_deepagents/13_programmatic_subagents.ipynb` | `deepagents/programmatic-subagents` | dependency gate 포함. 미설치 시 fallback section. |
| Deep Agents Event Streaming | `04_deepagents/14_event_streaming.ipynb` | `deepagents/event-streaming`, `streaming`, `frontend/subagent-streaming` | task/subagent/todo/tool/filesystem events 관찰. |
| Permissions Deep Dive | `04_deepagents/15_permissions.ipynb` 또는 기존 10 확장 | `deepagents/permissions`, `human-in-the-loop` | allow/deny/approval policy와 sandbox/filesystem 위험 제어. |
| Rubric and Profiles in Practice | `04_deepagents/16_quality_profiles_rubric.ipynb` | `profiles`, `rubric` | model/profile별 harness config와 LLM-as-judge revision loop. |

## 신규 integration 튜토리얼

| 신규 튜토리얼 | 권장 위치 | 공식 근거 | 내용 |
|---|---|---|---|
| Deep Agents Code CLI | `08_integration/21_deepagents_code_cli/` | `deepagents/code/overview`, `configuration`, `providers`, `data-locations` | `dcode` 설정, provider config, local data locations. |
| Deep Agents Code MCP Tools | `08_integration/22_deepagents_code_mcp_tools/` | `code/mcp-tools`, `deepagents/mcp` | MCP server/tool 연결. |
| Deep Agents Code Memory & Skills | `08_integration/23_deepagents_code_memory_skills/` | `code/memory-and-skills` | Code 환경의 persistent memory와 skills. |
| Deep Agents Code Remote Sandboxes | `08_integration/24_deepagents_code_remote_sandboxes/` | `code/remote-sandboxes` | remote sandbox key/cost gate 포함. |
| Deep Agents Code Subagents | `08_integration/25_deepagents_code_subagents/` | `code/subagents` | CLI/TUI에서 subagent 사용. |
| Deep Agents Frontend Todo/Sandbox/Subagent Streaming | `08_integration/26_deepagents_frontend/` | `frontend/overview`, `sandbox`, `todo-list`, `subagent-streaming` | UI state, todo rendering, sandbox/file previews, subagent event visualization. |
| Agent Protocols: ACP / A2A / MCP | `08_integration/27_agent_protocols/` | `acp`, `a2a`, `mcp` | 프로토콜 비교, 서버/클라이언트 연결, security gate. |

---

# 6. LangSmith / 평가 트랙 반영

공식 표면은 LangChain test/evals, LangChain/LangGraph observability, studio, deploy, Deep Agents rubric과 겹친다.

## 기존 튜토리얼 업데이트

| 대상 | 반영 내용 |
|---|---|
| `06_langsmith/01_quickstart.ipynb` | observability/studio/deploy 문서 링크 최신화. |
| `06_langsmith/02_tracing_agents.ipynb` | LangChain/LangGraph/Deep Agents trace 차이와 event streaming trace 해석 추가. |
| `06_langsmith/03_datasets_and_evaluation.ipynb` | Agent Evals와 rubric 차이를 연결. |
| `06_langsmith/04_prompt_hub.ipynb` | provider/model/version 관리와 providers-and-models 문서 연결. |
| `06_langsmith/05_production_monitoring.ipynb` | deploy/observability/runtime/changelog monitor checklist 추가. |
| `06_langsmith/06_agent_evals.ipynb` | `langchain/test/evals` 공식 문서와 trajectory judge 최신화. |

## 신규 코어 튜토리얼

| 신규 튜토리얼 | 권장 위치 | 공식 근거 | 내용 |
|---|---|---|---|
| Testing Strategy | `06_langsmith/07_testing_strategy.ipynb` + EN mirror | LangChain unit/integration/evals, LangGraph test | unit, integration, eval, smoke, replay를 한 장에서 정리. |
| LangGraph Testing | `06_langsmith/08_langgraph_testing.ipynb` + EN mirror | `langgraph/test` | graph state assertion, checkpointer, interrupts, replay test. |
| Runtime Rubric Evaluation | `06_langsmith/09_runtime_rubric_evaluation.ipynb` 또는 `04_deepagents/16...` | `deepagents/rubric`, Agent Evals | runtime self-revision과 offline eval의 차이. |

---

# 7. Integration track 전체 반영

공식 문서 중 다음은 기본 코어 노트북보다 `08_integration/`이 맞다.

## 신규 integration 패키지/폴더 제안

| 폴더 | 포함 공식 문서 |
|---|---|
| `08_integration/14_langchain_frontend_foundations/` | LangChain frontend overview, markdown messages, tool calling, structured output, reasoning tokens |
| `08_integration/15_branching_time_travel_chat/` | branching chat, time travel, join/rejoin streams, message queues |
| `08_integration/16_frontend_hitl/` | frontend HITL, headless tools |
| `08_integration/17_frontend_integrations/` | AI Elements, assistant-ui, CopilotKit, OpenUI |
| `08_integration/18_langgraph_frontend_graph_execution/` | LangGraph frontend overview, graph execution |
| `08_integration/19_langgraph_custom_stream_channels/` | LangGraph custom stream channels |
| `08_integration/20_langgraph_local_server_ui/` | LangGraph local server + UI |
| `08_integration/21_deepagents_code_cli/` | Deep Agents Code overview/config/providers/data locations |
| `08_integration/22_deepagents_code_mcp_tools/` | Deep Agents Code MCP tools + Deep Agents MCP |
| `08_integration/23_deepagents_code_memory_skills/` | Code memory and skills |
| `08_integration/24_deepagents_code_remote_sandboxes/` | remote sandboxes |
| `08_integration/25_deepagents_code_subagents/` | Code subagents |
| `08_integration/26_deepagents_frontend/` | Deep Agents frontend overview/sandbox/todo/subagent streaming |
| `08_integration/27_agent_protocols/` | ACP, A2A, MCP protocol comparison |

## Integration 공통 규칙

- `08_integration/README.md`에 각 폴더의 required keys, services, estimated cost/risk를 표로 추가한다.
- 기본 01~07 smoke harness에서는 제외한다.
- 실행 셀은 가능하면 dry-run/config-validation 셀과 live 셀을 분리한다.
- 외부 서버, React dev server, MCP server, cloud sandbox는 명시적 opt-in 플래그를 둔다.

---

# 8. Book / README / Skills 반영

## README / book config

| 대상 | 반영 내용 |
|---|---|
| `README.md`, `en/README.md` | 새 공식 coverage, docs/concepts, 새 튜토리얼 목록, integration 제외 정책 업데이트. |
| `book/scripts/config.yaml`, `en/book/scripts/config.yaml` | 신규 코어 노트북만 추가. `08_integration`은 별도 appendix 정책 결정 전까지 제외. |
| `book/main.typ`, `en/book/main.typ` | 신규 파트/챕터 추가 시 목차 반영. |
| `docs/README.md` | canonical reference note 구조, frontend/test/code/protocol 경로 설명 추가. |

## Skills / AGENTS 반영

| 대상 | 반영 내용 |
|---|---|
| `docs/skills/framework-selection.md` | concepts/products 기준 framework selection 업데이트. |
| `docs/skills/langchain-v1-modern.md` | event streaming, testing, frontend/integration gate 추가. |
| `docs/skills/langchain-rag.md` | semantic search prerequisite와 RAG agent 구분 추가. |
| `docs/skills/langchain-middleware.md` | guardrails/runtime/HITL 최신 연결. |
| `docs/skills/langgraph-fundamentals.md` | Graph/Functional API, fault tolerance, event streaming, frontend channels 반영. |
| `docs/skills/langgraph-persistence.md` | checkpointers/stores/add-memory 구분 보강. |
| `docs/skills/deep-agents-core.md` | models/tools/context/streaming/protocols 추가. |
| `docs/skills/deep-agents-memory.md` | memory + code memory/skills + backend updates. |
| `docs/skills/deep-agents-orchestration.md` | async/programmatic subagents, A2A/ACP/MCP, permissions 반영. |
| `.codex/skills/*` repo-local mirrors | 필요한 경우 docs/skills 변경과 sync. |

---

# 9. 전체 신규 코어 노트북 후보 목록

우선순위가 아니라 전체 반영 후보다.

| Track | New notebook |
|---|---|
| Beginner | `01_beginner/08_framework_selection_map.ipynb` 또는 `06_comparison` 대규모 업데이트 |
| LangChain | `02_langchain/14_semantic_search.ipynb` |
| LangChain advanced | `05_advanced/10_deep_agent_from_scratch.ipynb` |
| LangChain advanced | `05_advanced/11_custom_workflow_agent.ipynb` |
| LangGraph | `03_langgraph/15_backward_compatibility.ipynb` |
| LangGraph | `03_langgraph/16_case_studies.ipynb` |
| Deep Agents | `04_deepagents/12_models_and_tools.ipynb` |
| Deep Agents | `04_deepagents/13_programmatic_subagents.ipynb` |
| Deep Agents | `04_deepagents/14_event_streaming.ipynb` |
| Deep Agents | `04_deepagents/15_permissions.ipynb` 또는 기존 10 확장 |
| Deep Agents | `04_deepagents/16_quality_profiles_rubric.ipynb` |
| LangSmith | `06_langsmith/07_testing_strategy.ipynb` |
| LangSmith | `06_langsmith/08_langgraph_testing.ipynb` |
| LangSmith/Deep Agents | `06_langsmith/09_runtime_rubric_evaluation.ipynb` 또는 Deep Agents track로 이동 |
| Examples | `07_examples/08_semantic_search.ipynb` if not placed in `02_langchain` |
| Examples | `07_examples/09_deep_agent_from_scratch.ipynb` if not placed in `05_advanced` |
| Examples | `07_examples/10_personal_assistant_subagents.ipynb` |
| Examples | `07_examples/11_customer_support_handoffs.ipynb` |
| Examples | `07_examples/12_router_knowledge_base.ipynb` |
| Examples | `07_examples/13_skills_sql_assistant.ipynb` |

중복 후보는 실제 구현 단계에서 한 위치만 선택한다. 예: Semantic Search는 `02_langchain/14` 또는 `07_examples/08` 중 하나.

# 10. 전체 업데이트 대상 기존 노트북 목록

| Track | Update notebooks |
|---|---|
| Beginner | `00_setup`, `06_comparison`, possibly `07_mini_project` |
| LangChain | `01` through `13` 전체 |
| LangGraph | `01` through `14` 전체 |
| Deep Agents | `01` through `11` 전체 |
| Advanced | `00`, `01`, `02`, `03`, `04`, `05`, `06`, `07`, `08`, `09` |
| LangSmith | `01` through `06` KO/EN |
| Examples | `01`, `02`, `03`, `05`, `07` 중심, 필요 시 `06_multimodal_pdf_rag` 참고문서만 업데이트 |
| Integration | `08_integration/README.md`와 관련 provider/frontend/server folders |

# 11. 구현 시 검증 계약

모든 신규/업데이트 튜토리얼은 다음을 만족해야 한다.

1. 관련 공식 canonical note를 마지막 참고문서 셀에 포함한다.
2. 코드 셀은 가능한 10줄 이내를 유지한다.
3. 기본 모델 정책은 repo 규칙(`gpt-5.4`)을 유지하되, harness 교체 정책과 충돌하지 않게 한다.
4. 외부 서비스가 필요한 셀은 environment gate 또는 opt-in flag를 둔다.
5. 변경 노트북은 JSON parse, sequential `cell-0...`, changed-only smoke를 통과해야 한다.
6. book에 들어가는 코어 노트북은 KO/EN mirror와 Typst build까지 확인한다.
7. `08_integration`은 기본 smoke 제외를 명시하고, required keys/services/cost/risk를 README에 기록한다.
