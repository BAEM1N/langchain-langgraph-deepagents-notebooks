# LangChain Skills와 함께 사용하기

[LangChain Skills](https://github.com/langchain-ai/langchain-skills)는 LangChain, LangGraph, Deep Agents 프레임워크용 **에이전트 스킬 모음**입니다. Claude Code나 Deep Agents Code(`dcode`)와 함께 사용하면 코딩 에이전트가 프레임워크 문서를 참조하여 더 정확한 코드를 작성할 수 있습니다.

## 설치

```bash
# 모든 스킬 한번에 설치 (권장)
npx skills add langchain-ai/langchain-skills --skill '*' --yes

# 글로벌 설치 (모든 프로젝트에서 사용)
npx skills add langchain-ai/langchain-skills --skill '*' --yes --global
```

## 포함된 스킬 (11개)

| 카테고리 | 스킬 | 설명 |
|----------|------|------|
| **시작하기** | Framework Comparison | LangChain vs LangGraph vs Deep Agents 비교 |
| | Dependency Management | Python/TypeScript 의존성 관리 참조 |
| **Deep Agents** | Core Architecture | 아키텍처 및 harness 설정 가이드 |
| | Memory & Persistence | 메모리 및 지속성 패턴 |
| | Subagent Orchestration | 서브에이전트 오케스트레이션 및 작업 계획 |
| **LangChain** | Agent & Tools | 에이전트 생성 및 도구 통합 |
| | Human-in-the-Loop | 사람 승인 워크플로 |
| | RAG Pipeline | 문서 로더, 임베딩, 벡터 스토어 |
| **LangGraph** | StateGraph | 노드, 엣지, 그래프 구성 |
| | Persistence & Memory | 체크포인트 지속성, 크로스 스레드 메모리 |
| | Interrupt & Review | 인터럽트 기반 사람 리뷰 시스템 |

> 이 교육 자료로 학습한 후 LangChain Skills를 설치하면, AI 코딩 에이전트가 프레임워크 API를 정확히 사용하도록 도와줍니다.

## 로컬 참조 문서

스킬 내용은 `docs/skills/` 디렉토리에도 마크다운으로 저장되어 있어 오프라인에서도 참조할 수 있습니다. `npx skills add` 명령으로 설치하면 `.deepagents/skills/`에 SKILL.md 파일이 배치되어 Deep Agents Code가 자동으로 인식합니다.

## langchain-ecosystem-skills (문서 기반 스킬)

[langchain-ecosystem-skills](https://github.com/BAEM1N/langchain-ecosystem-skills)는 LangChain 공식 문서(`llms-full.txt`)를 기반으로 자동 생성된 3종 스킬셋입니다.

| 스킬 | 설명 |
|------|------|
| `deepagents-python` | Deep Agents 아키텍처, 서브에이전트, 백엔드, HITL |
| `langchain-python` | LangChain 모델, 도구, 미들웨어, RAG, 가드레일 |
| `langgraph-python` | LangGraph 그래프/Functional API, 지속성, 인터럽트 |

각 스킬에 `references/docs-digest.md`와 `references/ecosystem-overviews.md`가 포함되어 있어
공식 문서의 최신 스냅샷을 참조할 수 있습니다.

### 설치

```bash
git clone https://github.com/BAEM1N/langchain-ecosystem-skills.git
cp -R langchain-ecosystem-skills/skills/* ~/.agents/skills/
```
