# 10. Sandboxes — 코드 실행 격리 환경

Deep Agents 0.4에서 추가된 샌드박스 통합 패키지 3종. 에이전트가 코드를 실행할 때 호스트에서 격리된 환경 제공.

## 커버리지 체크리스트

| # | 제공자 | 패키지 | 특징 | 상태 |
|---|--------|--------|------|------|
| 01 | Modal | `langchain-modal` | 서버리스 Python, GPU 선택 | ⬜ |
| 02 | Daytona | `langchain-daytona` | Dev Container 기반 워크스페이스 | ⬜ |
| 03 | Runloop | `langchain-runloop` | 세션형 샌드박스, 파일시스템 지속 | ⬜ |

## 학습 포인트

- **`ShellToolMiddleware`와 차이**: Shell 미들웨어는 host 위주(DockerExecutionPolicy 지원), 샌드박스 패키지는 클라우드 관리형
- **비용·지연 트레이드오프**: 콜드스타트 vs 격리도
- **파일시스템 보존**: Runloop는 세션 유지, Modal은 단발성 실행
- **Deep Agents 사용**: `create_deep_agent(..., backend=<SandboxBackend>)`로 장착
- **보안**: 에이전트가 자유 코드 실행할 땐 샌드박스 필수 — CodexSandboxExecutionPolicy / DockerExecutionPolicy도 대안

## 관련

- `04_deepagents/10_sandboxes_and_acp.ipynb` — 기존 소개
- `docs/deepagents/11-sandboxes.md`
