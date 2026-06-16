// Auto-generated from 07_content_builder_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "Content Builder Agent", subtitle: "AGENTS.md + Skills + Subagents")

== Learning goals

- Understand the official Deep Agents Content Builder pattern: _memory, skills, and subagents_
- Inject brand voice with `AGENTS.md` and load writing workflows on demand with `SKILL.md`
- Persist outputs safely with `FilesystemBackend(virtual_mode=True)`
- Keep search and image generation optional so the core text pipeline runs with OpenAI only

== Overview

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Details],
  [_Official pattern_],
  [Content Builder Agent — memory(`AGENTS.md`), skills, subagents],
  [_Runtime scope_],
  [Text-only LinkedIn/blog draft generation],
  [_Safety_],
  [`local/` outputs, `virtual_mode=True`, image generation as reference-only],
  [_Verification_],
  [One live gpt-4.1 harness run],
)

The official example includes Tavily search and Gemini image generation. This notebook keeps those as optional adapters and makes _OpenAI + local filesystem_ the only required runtime path.

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "Set OPENAI_API_KEY in .env"
`````)

#code-block(`````python
# LangSmith — automatic logging when LANGSMITH_TRACING=true
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGSMITH_PROJECT", "langchain-langgraph-deepagents-notebooks")
`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4", temperature=0)
`````)

== 1) Content Builder workspace

The official example keeps agent instructions on disk rather than hard-coding everything in Python.

- `AGENTS.md` — brand voice and writing standards, loaded every run
- `skills/content-builder/SKILL.md` — writing workflow, loaded on demand
- `research/`, `linkedin/`, `blogs/` — output folders created by the agent

#code-block(`````python
from pathlib import Path
import shutil

WORK_DIR = Path("local/content_builder_demo_en")
if WORK_DIR.exists():
    shutil.rmtree(WORK_DIR)
(WORK_DIR / "skills/content-builder").mkdir(parents=True)
(WORK_DIR / "research").mkdir()
`````)

#code-block(`````python
brand_voice = """# BAEUM.AI Content Voice
Write in English, professional but approachable.
Lead with practical value, keep paragraphs short, and end with action.
Focus on AI agents, developer productivity, and production reliability.
"""
(WORK_DIR / "AGENTS.md").write_text(brand_voice, encoding="utf-8")
`````)

#code-block(`````python
skill_text = """---
name: content-builder
description: Use for blog, LinkedIn, or technical content drafts.
---
# Content Builder
Research first, then write a hook, 3 concise insights, and a CTA.
Save LinkedIn posts to linkedin/<slug>/post.md.
Save blog posts to blogs/<slug>/post.md.
"""
(WORK_DIR / "skills/content-builder/SKILL.md").write_text(skill_text, encoding="utf-8")
`````)

== 2) Local research tool and researcher subagent

Live classrooms and automated smoke tests do not always have external search keys. Here we wrap a small local knowledge base as a tool, then let a researcher subagent save concise findings to disk.

#code-block(`````python
from langchain.tools import tool

@tool
def topic_brief(topic: str) -> str:
    """Return a concise local research brief for a content topic."""
    return (
        f"{topic}: Deep Agents combine memory, skills, filesystem tools, "
        "and subagents so content workflows become repeatable."
    )
`````)

#code-block(`````python
researcher = {
    "name": "researcher",
    "description": "Research a topic and save concise findings before writing.",
    "system_prompt": "Use topic_brief, then write findings to the requested path.",
    "tools": [topic_brief],
}
`````)

== 3) Configure the Deep Agent

`create_deep_agent()` wires the content-building pieces together.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Configuration],
  text(weight: "bold")[Role],
  [`memory=["/AGENTS.md"]`],
  [Injects brand voice into the system prompt],
  [`skills=["/skills/"]`],
  [Loads `SKILL.md` workflow guidance on demand],
  [`subagents=[researcher]`],
  [Delegates research through the `task` tool],
  [`FilesystemBackend`],
  [Provides file tools such as `write_file` and `read_file`],
)

#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend

agent = create_deep_agent(
    model=model, tools=[topic_brief], subagents=[researcher],
    backend=FilesystemBackend(root_dir=str(WORK_DIR), virtual_mode=True),
    memory=["/AGENTS.md"], skills=["/skills/"],
    system_prompt="You are a content builder. Use files for durable outputs.",
)
`````)

== 4) Run — create a LinkedIn post

The request states four things explicitly: use the researcher, where to save research, where to save the content, and the bounded output shape.

#code-block(`````python
request = """Use the researcher subagent to research Deep Agents content workflows.
Save research to research/content-workflows.md.
Then write an English LinkedIn post with one hook, three bullets, and one CTA.
Save it to linkedin/content-workflows/post.md."""
result = agent.invoke({"messages": [{"role": "user", "content": request}]})
print(result["messages"][-1].content[:800])
`````)

#code-block(`````python
post_path = WORK_DIR / "linkedin/content-workflows/post.md"
research_path = WORK_DIR / "research/content-workflows.md"
print("research exists:", research_path.exists())
print("post exists:", post_path.exists())
print(post_path.read_text(encoding="utf-8")[:900])
`````)

== 5) Search and images are optional adapters

A production Content Builder can add Tavily search and image generation tools. For the core 01~07 notebook harness, keep those adapters reference-only unless the matching keys and cost policy are available.

#code-block(`````python
optional_tools_example = r"""
# Optional production tools — not required for this notebook smoke run.
# Add Tavily or image generation only when the matching API keys exist.
agent = create_deep_agent(
    model=model,
    tools=[web_search, generate_cover, generate_social_image],
    memory=["/AGENTS.md"], skills=["/skills/"],
)
"""
print(optional_tools_example)
`````)

== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Key idea],
  [_Memory_],
  [`AGENTS.md` always injects brand voice],
  [_Skills_],
  [`SKILL.md` loads blog/social workflows on demand],
  [_Subagents_],
  [A researcher separates evidence gathering from drafting],
  [_FilesystemBackend_],
  [Durable outputs are saved under `local/`],
  [_Runtime policy_],
  [OpenAI is required; search and images stay optional],
)

#line(length: 100%, stroke: 0.5pt + luma(200))

_References:_
- Deep Agents Content Builder: https://docs.langchain.com/oss/python/deepagents/content-builder
- Deep Agents Skills: ../../docs/deepagents/10-skills.md
- Deep Agents Subagents: ../../docs/deepagents/07-subagents.md
- Local reference: ../../docs/deepagents/examples/01-content-builder-agent.md
