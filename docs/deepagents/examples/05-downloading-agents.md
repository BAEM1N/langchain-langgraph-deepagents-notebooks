# Downloading Agents

## Overview

에이전트는 폴더다 — `AGENTS.md` + `skills/` 디렉토리를 zip으로 패키징하여 배포하고, 다운로드하여 바로 실행할 수 있다.

**원본:** [examples/downloading_agents](https://github.com/langchain-ai/deepagents/tree/main/examples/downloading_agents)

## Directory Structure

```
downloading_agents/
├── README.md
└── content-writer.zip           # 사전 패키징된 에이전트 (3,246 bytes)
```

## 개념: 에이전트 = 폴더

Deep Agents에서 에이전트의 본질은 **폴더 구조**다:

```
.deepagents/
├── AGENTS.md           # 에이전트 정체성 (항상 로드)
└── skills/
    ├── blog-post/
    │   └── SKILL.md    # 블로그 작성 스킬
    └── social-media/
        └── SKILL.md    # 소셜 미디어 스킬
```

이 폴더를 zip으로 압축하면 **배포 가능한 에이전트**가 된다.

## Usage

### 다운로드 & 실행

```bash
# 1. 프로젝트 초기화
mkdir my-project && cd my-project && git init

# 2. 에이전트 다운로드
curl -L https://github.com/.../content-writer.zip -o agent.zip

# 3. .deepagents/에 압축 해제
unzip agent.zip -d .deepagents

# 4. 에이전트 실행
deepagents
```

### 에이전트 패키징

```bash
# 에이전트 폴더를 zip으로 패키징
cd .deepagents
zip -r ../my-agent.zip AGENTS.md skills/
```

### 공유

```bash
# GitHub Release로 업로드
gh release create v1.0 my-agent.zip

# 또는 직접 URL 공유
# 다른 사용자: curl → unzip → deepagents
```

## content-writer.zip 내용

```
AGENTS.md               # 브랜드 보이스 & 스타일 가이드
skills/
├── blog-post/
│   └── SKILL.md         # 블로그 작성 워크플로
└── social-media/
    └── SKILL.md         # LinkedIn/Twitter 워크플로
```

Content Builder Agent 예제의 메모리와 스킬만 추출한 것이다.

## Key Concepts

| 개념 | 설명 |
|------|------|
| 에이전트 = 폴더 | `AGENTS.md` + `skills/` = 재사용 가능한 에이전트 |
| zip 배포 | 폴더 압축 → URL 공유 → `unzip` → 즉시 실행 |
| `.deepagents/` | 프로젝트 루트의 에이전트 설정 디렉토리 |
| Progressive Disclosure | 스킬은 필요할 때만 로드 (YAML frontmatter 기반) |
| 분리된 관심사 | 코드(tools)와 지식(AGENTS.md/SKILL.md)을 분리 |
