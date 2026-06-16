// Auto-generated from 07_content_builder_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "Content Builder Agent", subtitle: "AGENTS.md + Skills + Subagents")

== 학습 목표
#learning-objectives([공식 Deep Agents Content Builder 예제의 _메모리·스킬·서브에이전트_ 구조를 이해한다], [`AGENTS.md`로 브랜드 보이스를 주입하고, `SKILL.md`로 콘텐츠 워크플로를 온디맨드 로드한다], [`FilesystemBackend(virtual_mode=True)`로 결과물을 안전하게 파일로 남긴다], [외부 검색·이미지 생성 의존성을 선택 기능으로 분리해 OpenAI만으로 실행 가능한 텍스트 파이프라인을 만든다])

== 개요

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [_공식 패턴_],
  [Content Builder Agent — memory(`AGENTS.md`), skills, subagents],
  [_실행 범위_],
  [텍스트 전용 LinkedIn/블로그 초안 생성],
  [_안전 장치_],
  [`local/` 하위 출력, `virtual_mode=True`, 외부 이미지 생성은 reference-only],
  [_검증 방식_],
  [gpt-4.1 harness에서 실제 1회 실행],
)

공식 예제는 Tavily 검색과 Gemini 이미지 생성을 포함하지만, 이 노트북은 01~07 실행 harness에 맞춰 _OpenAI + 로컬 파일시스템_만 필수로 둡니다.

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY를 .env에 설정하세요"
`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4", temperature=0)
`````)

== 1) Content Builder 작업 공간

공식 예제의 핵심은 “코드에 모든 지침을 박아넣지 않고, 파일 시스템에 지침을 둔다”입니다.

- `AGENTS.md` — 브랜드 보이스와 작성 원칙, 항상 로드
- `skills/content-builder/SKILL.md` — 콘텐츠 작성 절차, 필요할 때 로드
- `research/`, `linkedin/`, `blogs/` — 에이전트가 산출물을 저장하는 폴더

#code-block(`````python
from pathlib import Path
import shutil

WORK_DIR = Path("local/content_builder_demo")
if WORK_DIR.exists():
    shutil.rmtree(WORK_DIR)
(WORK_DIR / "skills/content-builder").mkdir(parents=True)
(WORK_DIR / "research").mkdir()
`````)

#code-block(`````python
brand_voice = """# BAEUM.AI Content Voice
Write in Korean, professional but approachable.
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

== 2) 로컬 리서치 도구와 researcher 서브에이전트

라이브 강의·자동 테스트에서는 외부 검색 API 키가 항상 있지 않습니다. 그래서 여기서는 _로컬 knowledge base_를 검색 도구처럼 감싼 뒤, researcher 서브에이전트가 이를 요약해 파일로 저장하게 합니다.

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

== 3) Deep Agent 구성

`create_deep_agent()`는 아래 구성을 한 번에 연결합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[구성],
  text(weight: "bold")[역할],
  [`memory=["/AGENTS.md"]`],
  [브랜드 보이스를 시스템 프롬프트에 주입],
  [`skills=["/skills/"]`],
  [필요 시 `SKILL.md`를 읽어 작업 절차를 가져옴],
  [`subagents=[researcher]`],
  [`task` 도구로 리서치 작업을 위임],
  [`FilesystemBackend`],
  [`write_file`, `read_file` 등 파일 도구 제공],
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

== 4) 실행 — LinkedIn 포스트 생성

요청에는 네 가지를 명시합니다.

+ researcher 서브에이전트 사용
+ 리서치 저장 위치
+ 콘텐츠 저장 위치
+ 짧고 검증 가능한 산출물 범위

#code-block(`````python
request = """Use the researcher subagent to research Deep Agents content workflows.
Save research to research/content-workflows.md.
Then write a Korean LinkedIn post with one hook, three bullets, and one CTA.
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

== 5) 이미지·외부 검색은 선택 기능으로 분리

프로덕션 Content Builder는 Tavily 검색과 이미지 생성 도구를 붙일 수 있습니다. 다만 01~07 기본 실행 테스트에서는 비용·키 의존성을 피하기 위해 reference-only로 둡니다.

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

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[핵심 내용],
  [_Memory_],
  [`AGENTS.md`로 브랜드 보이스를 항상 주입],
  [_Skills_],
  [`SKILL.md`로 블로그/소셜 작성 절차를 온디맨드 로드],
  [_Subagents_],
  [researcher가 리서치를 분리 수행해 메인 컨텍스트를 절약],
  [_FilesystemBackend_],
  [콘텐츠 산출물을 `local/` 아래 파일로 보존],
  [_실행 정책_],
  [OpenAI만 필수, 검색·이미지는 optional],
)


#references-box[
- Deep Agents Content Builder: https://docs.langchain.com/oss/python/deepagents/content-builder
- Deep Agents Skills: ../docs/deepagents/10-skills.md
- Deep Agents Subagents: ../docs/deepagents/07-subagents.md
- Local reference: ../docs/deepagents/examples/01-content-builder-agent.md
]
#chapter-end()
