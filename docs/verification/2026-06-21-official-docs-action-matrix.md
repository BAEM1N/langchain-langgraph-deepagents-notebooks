# Official Docs Action Matrix — 2026-06-21

One row per official OSS Python page. This complements `2026-06-21-tutorial-update-and-addition-backlog.md` with a machine-checkable mapping.

## Counts

- `new_core`: 17
- `new_core_gated`: 1
- `new_integration`: 34
- `reference_index`: 1
- `update_existing`: 91
- `update_existing_and_new_core`: 1
- `update_existing_and_new_integration`: 1
- `update_existing_or_new_core`: 2

## Matrix

| Action | Official slug | Target | Note |
|---|---|---|---|
| `update_existing` | `concepts/context` | `01_beginner/06_comparison.ipynb; 05_advanced/04_context_memory.ipynb; docs/skills/framework-selection.md` | context engineering 공통 개념 반영 |
| `update_existing` | `concepts/memory` | `01_beginner/06_comparison.ipynb; 03_langgraph/06_persistence_and_memory.ipynb; 05_advanced/04_context_memory.ipynb` | short-term/long-term/checkpoint/store 구분 반영 |
| `update_existing_or_new_core` | `concepts/products` | `01_beginner/06_comparison.ipynb OR 01_beginner/08_framework_selection_map.ipynb` | Framework/Runtime/Harness 제품 지도 반영 |
| `update_existing` | `concepts/providers-and-models` | `01_beginner/00_setup.ipynb; 02_langchain/03_models_and_messages.ipynb; docs/MODEL_PROVIDERS.md` | provider/model identifier와 환경변수 정책 반영 |
| `new_integration` | `deepagents/a2a` | `08_integration/27_agent_protocols/` | A2A/ACP/MCP protocol comparison |
| `update_existing_and_new_integration` | `deepagents/acp` | `04_deepagents/10_sandboxes_and_acp.ipynb; 08_integration/27_agent_protocols/` | ACP 개념과 protocol integration |
| `update_existing` | `deepagents/async-subagents` | `04_deepagents/11_async_subagents.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `deepagents/backends` | `04_deepagents/04_backends.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `deepagents/changelog-py` | `05_advanced/00_migration.ipynb; docs/releases/` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_integration` | `deepagents/code/configuration` | `08_integration/21_deepagents_code_cli/` | DCode configuration |
| `new_integration` | `deepagents/code/data-locations` | `08_integration/21_deepagents_code_cli/` | DCode data locations |
| `new_integration` | `deepagents/code/mcp-tools` | `08_integration/22_deepagents_code_mcp_tools/` | DCode MCP tools |
| `new_integration` | `deepagents/code/memory-and-skills` | `08_integration/23_deepagents_code_memory_skills/` | DCode memory and skills |
| `new_integration` | `deepagents/code/overview` | `08_integration/21_deepagents_code_cli/` | Deep Agents Code CLI overview |
| `new_integration` | `deepagents/code/providers` | `08_integration/21_deepagents_code_cli/` | DCode providers |
| `new_integration` | `deepagents/code/remote-sandboxes` | `08_integration/24_deepagents_code_remote_sandboxes/` | Remote sandboxes |
| `new_integration` | `deepagents/code/subagents` | `08_integration/25_deepagents_code_subagents/` | DCode subagents |
| `update_existing` | `deepagents/comparison` | `04_deepagents/09_comparison.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `deepagents/content-builder` | `07_examples/07_content_builder_agent.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `deepagents/context-engineering` | `04_deepagents/03_customization.ipynb; 05_advanced/04_context_memory.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `deepagents/customization` | `04_deepagents/03_customization.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `deepagents/data-analysis` | `05_advanced/07_data_analysis.ipynb; 07_examples/03_data_analysis_agent.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `deepagents/deep-research` | `07_examples/05_deep_research_agent.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_core` | `deepagents/event-streaming` | `04_deepagents/14_event_streaming.ipynb` | Deep Agents event stream 관찰 |
| `new_integration` | `deepagents/frontend/overview` | `08_integration/26_deepagents_frontend/` | Deep Agents frontend overview |
| `new_integration` | `deepagents/frontend/sandbox` | `08_integration/26_deepagents_frontend/` | Sandbox UI |
| `new_integration` | `deepagents/frontend/subagent-streaming` | `08_integration/26_deepagents_frontend/` | Subagent streaming UI |
| `new_integration` | `deepagents/frontend/todo-list` | `08_integration/26_deepagents_frontend/` | Todo list UI |
| `update_existing` | `deepagents/going-to-production` | `04_deepagents/08_harness.ipynb; 05_advanced/09_production.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `deepagents/human-in-the-loop` | `04_deepagents/10_sandboxes_and_acp.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `deepagents/interpreters` | `04_deepagents/07_advanced.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_integration` | `deepagents/mcp` | `08_integration/22_deepagents_code_mcp_tools/; 08_integration/27_agent_protocols/` | Deep Agents MCP integration |
| `update_existing` | `deepagents/memory` | `04_deepagents/06_memory_and_skills.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_core` | `deepagents/models` | `04_deepagents/12_models_and_tools.ipynb` | Deep Agents model config |
| `update_existing` | `deepagents/overview` | `04_deepagents/01_introduction.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing_or_new_core` | `deepagents/permissions` | `04_deepagents/10_sandboxes_and_acp.ipynb OR 04_deepagents/15_permissions.ipynb` | permissions/HITL/sandbox 위험 제어 |
| `new_core` | `deepagents/profiles` | `04_deepagents/16_quality_profiles_rubric.ipynb` | HarnessProfile 실습 |
| `new_core_gated` | `deepagents/programmatic-subagents` | `04_deepagents/13_programmatic_subagents.ipynb` | dependency-gated programmatic subagents |
| `update_existing` | `deepagents/quickstart` | `04_deepagents/02_quickstart.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_core` | `deepagents/rubric` | `04_deepagents/16_quality_profiles_rubric.ipynb OR 06_langsmith/09_runtime_rubric_evaluation.ipynb` | RubricMiddleware와 runtime self-revision |
| `update_existing` | `deepagents/sandboxes` | `04_deepagents/10_sandboxes_and_acp.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `deepagents/skills` | `04_deepagents/06_memory_and_skills.ipynb; 07_examples/07_content_builder_agent.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `deepagents/streaming` | `04_deepagents/11_async_subagents.ipynb; 04_deepagents/14_event_streaming.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `deepagents/subagents` | `04_deepagents/05_subagents.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_core` | `deepagents/tools` | `04_deepagents/12_models_and_tools.ipynb` | Deep Agents tool schema/permission boundary |
| `update_existing` | `langchain/academy` | `README.md; docs/README.md` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/agents` | `02_langchain/02_quickstart.ipynb; 02_langchain/01_introduction.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/changelog-py` | `05_advanced/00_migration.ipynb; docs/releases/` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/component-architecture` | `02_langchain/01_introduction.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/context-engineering` | `05_advanced/04_context_memory.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_core` | `langchain/deep-agent-from-scratch` | `05_advanced/10_deep_agent_from_scratch.ipynb OR 07_examples/09_deep_agent_from_scratch.ipynb` | Deep Agents harness를 LangChain primitives로 재구성 |
| `update_existing` | `langchain/deploy` | `02_langchain/10_production.ipynb; 06_langsmith/05_production_monitoring.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/event-streaming` | `02_langchain/12_frontend_streaming.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_integration` | `langchain/frontend/branching-chat` | `08_integration/15_branching_time_travel_chat/` | Branching chat |
| `new_integration` | `langchain/frontend/generative-ui` | `08_integration/14_langchain_frontend_foundations/` | Generative UI pattern |
| `new_integration` | `langchain/frontend/headless-tools` | `08_integration/16_frontend_hitl/` | Headless tools |
| `new_integration` | `langchain/frontend/human-in-the-loop` | `08_integration/16_frontend_hitl/` | Frontend HITL |
| `new_integration` | `langchain/frontend/integrations/ai-elements` | `08_integration/17_frontend_integrations/` | AI Elements adapter |
| `new_integration` | `langchain/frontend/integrations/assistant-ui` | `08_integration/17_frontend_integrations/` | assistant-ui adapter |
| `new_integration` | `langchain/frontend/integrations/copilotkit` | `08_integration/17_frontend_integrations/` | CopilotKit adapter |
| `new_integration` | `langchain/frontend/integrations/openui` | `08_integration/17_frontend_integrations/` | OpenUI adapter |
| `new_integration` | `langchain/frontend/integrations/overview` | `08_integration/17_frontend_integrations/` | Frontend integrations survey |
| `new_integration` | `langchain/frontend/join-rejoin` | `08_integration/15_branching_time_travel_chat/` | Join/rejoin streams |
| `new_integration` | `langchain/frontend/markdown-messages` | `08_integration/14_langchain_frontend_foundations/` | Markdown message rendering |
| `new_integration` | `langchain/frontend/message-queues` | `08_integration/15_branching_time_travel_chat/` | Message queue UX |
| `new_integration` | `langchain/frontend/overview` | `08_integration/14_langchain_frontend_foundations/` | LangChain frontend foundation |
| `new_integration` | `langchain/frontend/reasoning-tokens` | `08_integration/14_langchain_frontend_foundations/` | Reasoning token UI |
| `new_integration` | `langchain/frontend/structured-output` | `08_integration/14_langchain_frontend_foundations/` | Structured output UI rendering |
| `new_integration` | `langchain/frontend/time-travel` | `08_integration/15_branching_time_travel_chat/` | Time travel chat |
| `new_integration` | `langchain/frontend/tool-calling` | `08_integration/14_langchain_frontend_foundations/` | Tool call UI rendering |
| `update_existing` | `langchain/get-help` | `README.md; docs/README.md` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/guardrails` | `02_langchain/13_guardrails.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/human-in-the-loop` | `02_langchain/07_hitl_and_runtime.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/install` | `01_beginner/00_setup.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_core` | `langchain/knowledge-base` | `02_langchain/14_semantic_search.ipynb OR 07_examples/08_semantic_search.ipynb` | RAG 전 semantic search 단독 실습 추가 |
| `update_existing` | `langchain/long-term-memory` | `05_advanced/04_context_memory.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/mcp` | `02_langchain/11_mcp.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/messages` | `02_langchain/03_models_and_messages.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/middleware/built-in` | `02_langchain/06_middleware.ipynb; 05_advanced/01_middleware.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/middleware/custom` | `02_langchain/06_middleware.ipynb; 05_advanced/01_middleware.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/middleware/overview` | `02_langchain/06_middleware.ipynb; 05_advanced/01_middleware.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/models` | `02_langchain/03_models_and_messages.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/multi-agent/custom-workflow` | `05_advanced/11_custom_workflow_agent.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/multi-agent/handoffs` | `05_advanced/03_multi_agent_handoffs_router.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_core` | `langchain/multi-agent/handoffs-customer-support` | `07_examples/11_customer_support_handoffs.ipynb` | Customer support handoffs applied example |
| `update_existing` | `langchain/multi-agent/index` | `02_langchain/08_multi_agent.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/multi-agent/router` | `05_advanced/03_multi_agent_handoffs_router.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_core` | `langchain/multi-agent/router-knowledge-base` | `07_examples/12_router_knowledge_base.ipynb` | Multi-source KB router applied example |
| `update_existing` | `langchain/multi-agent/skills` | `07_examples/07_content_builder_agent.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_core` | `langchain/multi-agent/skills-sql-assistant` | `07_examples/13_skills_sql_assistant.ipynb` | On-demand skills SQL assistant applied example |
| `update_existing` | `langchain/multi-agent/subagents` | `05_advanced/02_multi_agent_subagents.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_core` | `langchain/multi-agent/subagents-personal-assistant` | `07_examples/10_personal_assistant_subagents.ipynb` | Personal assistant subagents applied example |
| `update_existing` | `langchain/observability` | `02_langchain/10_production.ipynb; 06_langsmith/02_tracing_agents.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/overview` | `02_langchain/01_introduction.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/philosophy` | `02_langchain/01_introduction.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/quickstart` | `02_langchain/02_quickstart.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/rag` | `07_examples/01_rag_agent.ipynb; 05_advanced/05_agentic_rag.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/retrieval` | `02_langchain/09_custom_workflow_and_rag.ipynb; 07_examples/01_rag_agent.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/runtime` | `02_langchain/07_hitl_and_runtime.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/short-term-memory` | `02_langchain/05_memory_and_streaming.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/sql-agent` | `07_examples/02_sql_agent.ipynb; 05_advanced/06_sql_agent.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/streaming` | `02_langchain/05_memory_and_streaming.ipynb; 02_langchain/12_frontend_streaming.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/structured-output` | `02_langchain/04_tools_and_structured_output.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/studio` | `06_langsmith/01_quickstart.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing_and_new_core` | `langchain/test/evals` | `06_langsmith/06_agent_evals.ipynb; 06_langsmith/07_testing_strategy.ipynb` | Agent Evals와 테스트 전략 연결 |
| `new_core` | `langchain/test/index` | `06_langsmith/07_testing_strategy.ipynb` | 테스트 트랙 overview |
| `new_core` | `langchain/test/integration-testing` | `06_langsmith/07_testing_strategy.ipynb` | API key/service gate와 integration assertions |
| `new_core` | `langchain/test/unit-testing` | `06_langsmith/07_testing_strategy.ipynb` | mock model, deterministic unit test |
| `update_existing` | `langchain/tools` | `02_langchain/04_tools_and_structured_output.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/ui` | `02_langchain/12_frontend_streaming.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langchain/voice-agent` | `05_advanced/08_voice_agent.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/add-memory` | `03_langgraph/06_persistence_and_memory.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/agentic-rag` | `05_advanced/05_agentic_rag.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/application-structure` | `03_langgraph/12_durable_execution.ipynb; 03_langgraph/10_production.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_core` | `langgraph/backward-compatibility` | `03_langgraph/15_backward_compatibility.ipynb OR 05_advanced/12_langgraph_migration.ipynb` | LangGraph compatibility/migration guardrails |
| `new_core` | `langgraph/case-studies` | `03_langgraph/16_case_studies.ipynb` | 공식 case studies를 pattern review로 분해 |
| `update_existing` | `langgraph/changelog-py` | `05_advanced/00_migration.ipynb; docs/releases/` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/checkpointers` | `03_langgraph/06_persistence_and_memory.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/choosing-apis` | `03_langgraph/13_api_guide_and_pregel.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/deploy` | `03_langgraph/10_production.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/event-streaming` | `03_langgraph/07_streaming.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/fault-tolerance` | `03_langgraph/14_fault_tolerance.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_integration` | `langgraph/frontend/custom-stream-channels` | `08_integration/19_langgraph_custom_stream_channels/` | custom stream channels |
| `new_integration` | `langgraph/frontend/graph-execution` | `08_integration/18_langgraph_frontend_graph_execution/` | frontend graph execution controls |
| `new_integration` | `langgraph/frontend/overview` | `08_integration/18_langgraph_frontend_graph_execution/` | LangGraph frontend integration intro |
| `update_existing` | `langgraph/functional-api` | `03_langgraph/03_functional_api.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/graph-api` | `03_langgraph/02_graph_api.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/install` | `01_beginner/00_setup.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/interrupts` | `03_langgraph/08_interrupts_and_time_travel.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/local-server` | `03_langgraph/11_local_server.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/observability` | `03_langgraph/10_production.ipynb; 06_langsmith/02_tracing_agents.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/overview` | `03_langgraph/01_introduction.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/persistence` | `03_langgraph/06_persistence_and_memory.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/pregel` | `03_langgraph/13_api_guide_and_pregel.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/quickstart` | `03_langgraph/01_introduction.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/sql-agent` | `05_advanced/06_sql_agent.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/stores` | `03_langgraph/06_persistence_and_memory.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/streaming` | `03_langgraph/07_streaming.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/studio` | `03_langgraph/10_production.ipynb; 06_langsmith/01_quickstart.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `new_core` | `langgraph/test` | `06_langsmith/08_langgraph_testing.ipynb` | graph state/checkpointer/replay testing |
| `update_existing` | `langgraph/thinking-in-langgraph` | `03_langgraph/01_introduction.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/ui` | `03_langgraph/10_production.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/use-functional-api` | `03_langgraph/03_functional_api.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/use-graph-api` | `03_langgraph/02_graph_api.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/use-subgraphs` | `03_langgraph/09_subgraphs.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/use-time-travel` | `03_langgraph/08_interrupts_and_time_travel.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `update_existing` | `langgraph/workflows-agents` | `03_langgraph/04_workflows.ipynb` | 기존 튜토리얼에 공식 canonical reference를 반영 |
| `reference_index` | `learn` | `README.md; docs/README.md; docs/verification/2026-06-21-tutorial-update-and-addition-backlog.md` | 공식 Learn 허브와 로컬 코스 맵 연결 |
