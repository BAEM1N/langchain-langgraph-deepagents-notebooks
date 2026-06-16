// Auto-generated from 03_functional_api.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "Functional API", subtitle: "@entrypoint와 @task로 워크플로 만들기")

== 학습 목표
Functional API의 `@entrypoint`, `@task` 패턴과 단기 메모리를 이해합니다.

== 3.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 3.2 \@task — 비동기 작업 단위

- `@task` 데코레이터로 감싸면 체크포인팅 가능
- 호출 시 즉시 Future 객체 반환, `.result()`로 대기

== 3.3 병렬 태스크 실행

여러 태스크를 동시에 실행합니다.

== 3.4 previous — 단기 메모리 (이전 실행 결과 접근)

== 3.5 entrypoint.final — 반환값과 체크포인트 저장값 분리

== 3.6 결정론성 요구사항

비결정적 작업은 반드시 `@task`로 감싸야 합니다.

== 3.7 LLM 에이전트 (Functional API)

while 루프로 ReAct 에이전트 구현

== 3.8 RetryPolicy + timeout — `\@task` 신뢰성 강화

`@task(retry_policy=..., timeout=...)` 로 일시 장애 자동 재시도와 타임아웃을 함께 설정합니다.

- `RetryPolicy(retry_on=ValueError)` — 특정 예외만 재시도하도록 좁힐 수 있음
- `RetryPolicy(retry_on=NodeTimeoutError)` — timeout 초과를 재시도로 처리
- `@entrypoint(timeout=5.0)` 으로 워크플로 전체에도 타임아웃 지정 가능

== 3.9 캐싱 — `\@entrypoint(cache=InMemoryCache())` + `\@task(cache_policy=CachePolicy(ttl=120))`

같은 입력으로 호출되는 비싼 태스크의 결과를 재사용합니다.

- 워크플로 전체에 `cache=InMemoryCache()` 또는 `SqliteCache(...)` 부착
- 태스크별로 `cache_policy=CachePolicy(ttl=초)` 지정
- `key_func` 로 캐시 키 생성 로직 커스터마이즈 가능

== 3.10 Human-in-the-loop — 구조화된 `interrupt()`

`interrupt(payload)` 로 실행을 일시 중단하고 사람의 입력을 기다립니다.

- 단순 문자열 대신 `dict` 를 전달해 _질문 + 컨텍스트 + 기대 입력 포맷_을 함께 노출
- 재개는 `Command(resume=...)` — 같은 `thread_id` 에 입력으로 전달
- `interrupt()` 호출은 태스크 내부 다른 작업보다 _먼저_ 와야 함 (재개 시 부수 효과 중복 방지)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[설명],
  [`\@task`],
  [비동기 작업, 체크포인팅, 병렬 실행],
  [`\@entrypoint`],
  [워크플로 진입점, 실행 관리],
  [주입 파라미터],
  [`previous` / `store` / `writer` / `config` 를 자동 주입],
  [`.result()`],
  [Future 결과 동기 대기],
  [`previous`],
  [이전 실행 결과 접근 (단기 메모리)],
  [`entrypoint.final(value=..., save=...)`],
  [반환값 ≠ 저장값 분리],
  [`RetryPolicy(retry_on=...)`],
  [`\@task` 에서 특정 예외만 재시도],
  [`\@entrypoint(cache=InMemoryCache())` + `CachePolicy(ttl=120)`],
  [태스크 결과 캐싱],
  [`interrupt({...})`],
  [구조화된 HITL — 재개는 `Command(resume=...)`],
)
