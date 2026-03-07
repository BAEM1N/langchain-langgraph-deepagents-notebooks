# Content Builder Agent

## Overview

콘텐츠 작성 에이전트로, AGENTS.md(메모리), Skills, Subagents, FilesystemBackend를 활용하여 블로그 포스트, LinkedIn 포스트, 트윗을 자동 생성한다.

**원본:** [examples/content-builder-agent](https://github.com/langchain-ai/deepagents/tree/main/examples/content-builder-agent)

## Directory Structure

```
content-builder-agent/
├── AGENTS.md                    # 브랜드 보이스 & 스타일 가이드 (항상 로드)
├── README.md
├── content_writer.py            # 메인 에이전트 스크립트
├── pyproject.toml
├── subagents.yaml               # 서브에이전트 정의
└── skills/
    ├── blog-post/
    │   └── SKILL.md             # 블로그 작성 워크플로
    └── social-media/
        └── SKILL.md             # LinkedIn/Twitter 워크플로
```

## Source Code

### AGENTS.md

브랜드 보이스와 콘텐츠 기준을 정의한다. `memory=["./AGENTS.md"]`로 매 호출 시 시스템 프롬프트에 로드된다.

```markdown
# Brand Voice & Style Guide

## Voice
- Professional but approachable
- Active voice, one idea per paragraph

## Content Pillars
- AI agents, developer tools

## Formatting
- Headers: sentence case
- Code blocks: always specify language
```

### content_writer.py

```python
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend
from langchain_anthropic import ChatAnthropic
from tavily import TavilyClient

# 도구 정의
def web_search(query: str) -> str:
    """Tavily를 사용한 웹 검색."""
    client = TavilyClient()
    return client.search(query)

def generate_cover(prompt: str) -> str:
    """Gemini를 사용한 커버 이미지 생성."""
    ...

def generate_social_image(prompt: str) -> str:
    """소셜 미디어용 이미지 생성."""
    ...

# 서브에이전트 로드
def load_subagents(path="subagents.yaml"):
    import yaml
    with open(path) as f:
        return yaml.safe_load(f)

subagents = load_subagents()

# 에이전트 생성
agent = create_deep_agent(
    model=ChatAnthropic(model="claude-sonnet-4-5-20250929"),
    memory=["./AGENTS.md"],
    skills=["./skills/"],
    tools=[web_search, generate_cover, generate_social_image],
    subagents=subagents,
    backend=FilesystemBackend(root_dir="./output"),
)
```

### subagents.yaml

```yaml
- name: researcher
  model: anthropic:claude-haiku-4-5-20251001
  description: "Researches topics using web search"
  tools:
    - web_search
```

### skills/blog-post/SKILL.md

```yaml
---
name: blog-post
description: Write a comprehensive blog post with research, SEO, and cover image
---
```

워크플로: 리서치 → `blogs/<slug>/` 디렉토리에 출력 → 구조(hook/context/main/practical/CTA) → 커버 이미지 → SEO 최적화 → 품질 체크리스트

### skills/social-media/SKILL.md

```yaml
---
name: social-media
description: Create LinkedIn posts and Twitter threads with images
---
```

LinkedIn: 1300자 제한, 해시태그. Twitter/X: 280자, 스레드 지원. 플랫폼별 이미지 생성.

## Setup & Usage

```bash
cd content-builder-agent
uv sync
export ANTHROPIC_API_KEY=...
export TAVILY_API_KEY=...
python content_writer.py
```

## Key Concepts

| 개념 | 설명 |
|------|------|
| `memory` | `AGENTS.md` — 항상 시스템 프롬프트에 포함되는 영구 지침 |
| `skills` | 디렉토리 경로 → YAML frontmatter로 설명, 필요 시 로드 (progressive disclosure) |
| `subagents` | YAML 파일로 정의, `task` 도구로 위임 |
| `FilesystemBackend` | 파일 시스템에 결과물 저장 (`write_file`, `read_file` 등) |
| `tools` | `@tool` 데코레이터 또는 함수로 정의, 에이전트에 전달 |
