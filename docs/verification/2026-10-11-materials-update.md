# 교육 자료 업데이트 반영 및 검증 기록

조사 기준과 사용자 승인 범위: `2026-10-11-update-research.md`의 21개 항목을 기존 한국어/영어 교육 자료, Typst 핸드북, 강의 데크 전체에 반영.

## 결과

- 한국어·영어 ipynb 59개 갱신. 전체 241개 노트북 파일 구성 유지.
- 의존성/lock/실제 환경: Deep Agents 0.7.23, LangChain 1.4.4, core 1.6.9, LangGraph 1.2.14, LangSmith 0.14.7, OpenAI 통합 1.7.0, Google 통합 4.4.1, QuickJS 0.3.8.
- `langchain[mcp]` extra로 MCP 통합을 이전하고 기존 adapter 패키지 제거. Interpreter는 선택 extra로 명시.
- 문서/skills/README/AGENTS의 현재 계약, 버전, 수량, 공식 경로와 검증 명령 갱신.
- 노트북에서 생성하는 Typst 장: 한국어 79개·영어 17개 갱신. 별도 편집 장은 서식·그림·내용을 보존하면서 수정.
- 한국어/영어 핸드북 PDF 재생성. 생성기는 언어가 없는 Markdown 블록을 Python 코드로 오인하지 않도록 보완.
- 데크 5종의 PDF/PPTX/발표 대본 Markdown·PDF 갱신. 총 1,206장.
- 편집 가능한 Python/HTML/CSS/자산과 빌더를 `decks/source/`에 저장. 기존 PPTX는 슬라이드 이미지+speaker notes 형식이며 본문 편집은 원본에서 수행.
- 편집 원본에 최종 SLIDES/SPEECH 데이터를 직접 저장하고 오래된 소스를 가리는 runtime overlay 제거.
- 아키텍처 다이어그램의 계획 opt-in 표기와 이미지 자산 동기화.
- `.gitattributes`에 PDF/PPTX/이미지 binary 속성 명시하여 산출물의 바이트와 diff를 보존.

## 조사 항목 반영

| ID | 주제 | 처리 |
|---|---|---|
| D01 | Deep Agents todo opt-in | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| D02 | backend compatibility 제거 | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| D03 | filesystem 기본값·쓰기·삭제 | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| D04 | backend 반환값·출력 포맷 | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| D05 | subagent conversation fork | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| D06 | skill tools·pinned skills | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| D07 | 기본 middleware 대체 | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| D08 | rubric criterion coverage·grader hooks | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| L01 | LangChain MCP | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| L02 | wrap_tool_call state_schema | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| L03 | legacy chat message history deprecation | 기존 교육 코드에 사용되지 않아 유지; 신규 레거시 패턴 추가 없음 |
| G01 | interrupt response_schema | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| G02 | trace_policy | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| S01 | SmithDB run queries | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| S02 | SmithDB feedback·예외·공유 | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| S03 | evaluation tracing 옵션 | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| O01 | OpenAI gateway·Responses·cache | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| P01 | Google thinking 설정 | 해당 문서·노트북·책/데크의 적용 표면 갱신 |
| N01 | Code·dynamic-subagents 경로 이동 | 기존 통합 지도·공식 레퍼런스·책/데크에서 보강; 새 노트북 카테고리 생성 없음 |
| N02 | fault tolerance·multimodal·retrieval/RAG | 기존 통합 지도·공식 레퍼런스·책/데크에서 보강; 새 노트북 카테고리 생성 없음 |
| N03 | Generative UI·AG-UI·Code extensions/plugins | 기존 통합 지도·공식 레퍼런스·책/데크에서 보강; 새 노트북 카테고리 생성 없음 |

## 검증

| 검증 | 결과 |
|---|---|
| 노트북 JSON/순차 cell ID/bytecode·AST/현재 API 계약 | 전체 241개 통과 |
| 고위험 migration 주제의 한국어/영어 대응 | 통과 |
| Typst Python 예제 계약/중복 keyword | 통과 |
| literal deck source 코드 계약/SmithDB async loop·파라미터 | 통과 |
| SDK 및 authored helper 동작 테스트 | 16개 통과 |
| deterministic full nbclient 실행 | 한국어 5개 + 영어 대응 5개 통과 |
| Ruff | 신규 검증 스크립트/테스트 통과 |
| Pyright | 신규 검증 스크립트/테스트 0 errors |
| uv lock consistency | 통과 |
| Typst 전체 빌드 | 한국어/영어 모두 통과 |
| PPTX ZIP/package 및 slide/PDF/script 수량 | 5종 통과 |
| 변경 본문·코드·이미지의 대표 페이지/슬라이드 시각 검토 | 기존 디자인 유지, pass |
| 변경 텍스트 whitespace 및 문서 로컬 링크 | 통과 |

동작 테스트는 기본/선택 planning, filesystem overwrite/delete/path restriction, Store namespace 격리, tool allowlist, pinned skill 도구 노출, fork 제약, Pydantic interrupt 재개, MCP 호출 및 현대 InputRequiredResult 중단·재개, SmithDB pagination/projection, OpenAI·Google 설정, notebook→Typst 언어 보존을 포함한다. Authored SmithDB helper 테스트는 ID-only 기본 응답을 모사하여 실제 소비 필드가 요청되는지 검사한다.

실행한 deterministic 노트북: `04_deepagents/13_programmatic_subagents`, `15_permissions`, `16_quality_profiles_rubric`, `05_advanced/10_deep_agent_from_scratch`, `07_examples/13_skills_sql_assistant` 및 영어 대응 파일.

독립 검토에서 발견한 ReadResult 필드, MCP auth/elicitation, mirror 누락, SkillsMiddleware backend/중복 keyword, SmithDB 필드 projection 오류를 수정했다. 재검토 결과 승인. 이후 데크 raw source와 async loop도 추가 검사·수정하여 출력과 일치시켰다.

## 최종 산출물

| 산출물 | 페이지/슬라이드 |
|---|---:|
| `book/agent-handbook.pdf` | 577 |
| `en/book/agent-handbook-en.pdf` | 616 |
| `decks/01_beginner/01_beginner.pptx` | 40 |
| `decks/02_langchain/02_langchain.pptx` | 328 |
| `decks/03_langgraph/03_langgraph.pptx` | 324 |
| `decks/04_deepagents/04_deepagents.pptx` | 231 |
| `decks/05_advanced/05_advanced.pptx` | 283 |

책: `book/main.typ`, `en/book/main.typ` 및 두 PDF. 데크: `decks/01_beginner`~`05_advanced`, 빌더 `decks/source/build_all_decks.py`. 상세 목록은 `decks/manifest.csv`.

## 재현 명령

```bash
uv sync --all-extras
uv run --all-extras python scripts/validate_materials.py
uv run --all-extras python -m unittest discover -s tests -v
uv run --all-extras python book/scripts/build.py --skip-diagrams
uv run --all-extras python book/scripts/nb2typ.py --config en/book/scripts/config.yaml
uv run --all-extras python en/book/scripts/build.py
uv run --no-project --with playwright --with beautifulsoup4 --with pymupdf --with python-pptx decks/source/build_all_decks.py
```

## 검증 한계와 작업 상태

- 외부 모델 호출, LangSmith 데이터셋/평가 쓰기, provider별 실제 서비스·DB·cloud sandbox의 전수 실행은 수행하지 않았다. 전체 241개 Run All 성공을 주장하지 않는다.
- Pydantic v1/Python 3.14 경고와 upstream beta 경고는 환경/SDK에서 발생하며 검증을 막지 않았다.
- 시각 검토는 수정된 대표 페이지/슬라이드 중심이며 모든 기존 페이지를 수동 검토한 것은 아니다.
- 로컬 main의 두 고유 커밋은 보존했다. origin의 기존 데크 파일은 백업 후 작업 트리에 가져왔으며 merge/reset하지 않았다.
- 커밋·푸시·외부 게시 없음. 변경은 현재 작업 트리에 있다.
- 원문·실행 로그·검증 JSON·산출물 SHA256은 `.local/implementation-2026-10-11/`에 저장.
