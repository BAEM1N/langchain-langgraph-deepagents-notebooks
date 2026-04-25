---
name: deep-research
description: >
  박사급 딥 리서치 에이전트 가이드.
  병렬 서브에이전트 위임, think_tool 반성, 5단계 워크플로를 다룹니다.
license: MIT
compatibility: Python 3.12+
metadata:
  category: research
  difficulty: advanced
allowed-tools: web_search think_tool write_todos task
---

# Deep Research 스킬

## 사용 시기
- 사용자가 특정 주제에 대한 심층 조사를 요청할 때
- 여러 소스에서 정보를 수집하고 종합해야 할 때
- 비교 분석이나 동향 분석이 필요할 때

## 5단계 워크플로
1. **Plan**: `write_todos`로 리서치 계획 작성
   - 조사할 하위 주제 정의
   - 서브에이전트 할당 계획
2. **Delegate**: 서브에이전트에게 병렬 조사 위임
   - 단순 주제: researcher 1명
   - 비교 분석: researcher 2명 (각 관점 담당)
   - 최대 3개 서브에이전트 동시 실행
3. **Synthesize**: 수집된 정보 통합
   - `think_tool`로 정보 충분성 평가
   - 부족하면 추가 조사 요청
4. **Verify**: `fact-checker` 서브에이전트로 사실 검증
   - 핵심 주장의 교차 검증
   - 오류 발견 시 수정
5. **Report**: 최종 보고서 작성
   - 구조화된 섹션 (배경, 분석, 결론)
   - 인용 형식: [1], [2], ... + 출처 섹션

## think_tool 사용 시기
- 검색 결과를 받은 직후 (결과 분석)
- 서브에이전트 결과를 받은 직후 (충분성 평가)
- 최종 보고서 작성 직전 (구조 계획)

## 서브에이전트 구성
| 에이전트 | 역할 | 도구 |
|---------|------|------|
| `researcher-1` | 주제 심층 조사 | web_search, think_tool |
| `researcher-2` | 보완/비교 조사 | web_search, think_tool |
| `fact-checker` | 사실 검증 | web_search |

## 인용 규칙
- 모든 핵심 주장에 인용 번호 부여: [1], [2], ...
- 보고서 끝에 출처 섹션 포함
- URL, 저자, 발행일 명시 (가능한 경우)

## 보고서 템플릿
```markdown
# [주제] 리서치 보고서

## 요약
핵심 발견 3줄 요약

## 1. 배경
## 2. 분석
## 3. 비교 (해당 시)
## 4. 결론 및 시사점

## 출처
[1] 제목, URL, 날짜
[2] ...
```
