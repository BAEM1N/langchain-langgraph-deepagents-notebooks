---
name: content-builder
description: >
  Deep Agents Content Builder workflow. Use for blog posts, LinkedIn posts,
  technical content drafts, brand-voice guided writing, and content workflows
  that combine AGENTS.md memory, SKILL.md progressive disclosure, subagents,
  and filesystem outputs.
license: MIT
compatibility: Python 3.12+
metadata:
  category: content
  difficulty: intermediate
allowed-tools: topic_brief task write_file read_file
---

# Content Builder 스킬

## 사용 시기

- 사용자가 블로그 글, LinkedIn 글, 기술 튜토리얼, 소셜 포스트를 요청할 때
- 브랜드 보이스와 작성 기준을 `AGENTS.md`로 고정하고 싶을 때
- 조사 → 초안 → 파일 저장으로 이어지는 반복 가능한 콘텐츠 워크플로가 필요할 때

## 워크플로

1. **브랜드 보이스 로드**: `AGENTS.md`의 톤, 독자, 작성 원칙 확인
2. **리서치 위임**: `task`로 researcher 서브에이전트에 조사 요청
3. **조사 파일 저장**: `research/<slug>.md`에 근거와 핵심 포인트 정리
4. **초안 작성**: 플랫폼에 맞는 hook, 핵심 인사이트, CTA 작성
5. **파일 저장**: `linkedin/<slug>/post.md` 또는 `blogs/<slug>/post.md`
6. **검토**: 브랜드 보이스, 구체성, 과장 표현, CTA를 점검

## 출력 구조

```text
local/content_builder_demo/
├── AGENTS.md
├── skills/content-builder/SKILL.md
├── research/<slug>.md
├── linkedin/<slug>/post.md
└── blogs/<slug>/post.md
```

## 안전 규칙

- 외부 검색이나 이미지 생성은 API 키와 비용 정책이 있을 때만 사용한다.
- 출처가 없는 통계·수치·최신 뉴스는 단정하지 않는다.
- 기본 실행 경로는 OpenAI + 로컬 파일시스템만으로 통과해야 한다.
