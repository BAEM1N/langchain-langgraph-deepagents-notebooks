# Lecture Decks

강의용 deck 산출물을 보관하는 폴더입니다.

- 노트북 원본은 repository의 `01_beginner/`~`08_integration/`에 둡니다.
- 강의 배포/촬영/발표 산출물은 `decks/<module>/` 아래에 둡니다.
- 단수형 `deck/` 폴더는 사용하지 않습니다. 모든 배포 산출물은 `decks/`로 통합합니다.

## 현재 산출물

각 모듈 폴더는 다음 4종을 포함합니다.

- `*.pptx` — 강의장 발표용 PowerPoint. 현재 PPTX는 기존 배포 형식을 보존해 각 슬라이드를 전체 화면 이미지로 넣고 발표자 노트를 포함합니다. 슬라이드 안의 텍스트 상자는 PowerPoint 네이티브 편집 대상이 아닙니다.
- `*.pdf` — 슬라이드 PDF
- `*_대본.md` — 강사용 상세 대본 Markdown
- `*_대본.pdf` — 강사용 상세 대본 PDF

| 모듈 | PPTX | 슬라이드 PDF | 대본 MD | 대본 PDF |
|---|---:|---:|---:|---:|
| `01_beginner` | 있음 | 있음 | 있음 | 있음 |
| `02_langchain` | 있음 | 있음 | 있음 | 있음 |
| `03_langgraph` | 있음 | 있음 | 있음 | 있음 |
| `04_deepagents` | 있음 | 있음 | 있음 | 있음 |
| `05_advanced` | 있음 | 있음 | 있음 | 있음 |

파일별 슬라이드/페이지 수는 `decks/manifest.csv`를 기준으로 확인합니다.

## 편집 가능한 원본과 재빌드

편집 가능한 원본은 `decks/source/`입니다. 각 모듈의 `content/*_content.py`, `content/*_speech.py`, `template-navy.css`, `deck-stage.js`, `assets/`를 수정한 뒤 아래 명령으로 PPTX/PDF/대본을 다시 생성합니다.

```bash
uv run --no-project \
  --with playwright --with beautifulsoup4 --with pymupdf --with python-pptx \
  decks/source/build_all_decks.py
```

빌드 중간 산출물은 `.local/deck_source_render/`와 각 소스 모듈의 `_render/`에 생기며 git에 넣지 않습니다. Chrome 실행 파일이 별도로 필요하면 `PLAYWRIGHT_CHROMIUM_EXECUTABLE` 환경 변수로 지정합니다.
