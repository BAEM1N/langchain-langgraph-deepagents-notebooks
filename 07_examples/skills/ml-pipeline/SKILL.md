---
name: ml-pipeline
description: >
  머신러닝 파이프라인 에이전트 가이드.
  sklearn 기반 모델 비교, 교차 검증, 서브에이전트 위임 패턴을 다룹니다.
license: MIT
compatibility: Python 3.12+
metadata:
  category: ml
  difficulty: advanced
allowed-tools: data_loader train_model evaluate_model
---

# ML Pipeline 스킬

## 사용 시기
- 사용자가 머신러닝 모델 학습 및 비교를 요청할 때
- 데이터셋 로드 → 학습 → 평가 파이프라인을 자동화할 때
- 최적 모델 추천이 필요할 때

## 워크플로
1. **Load**: `data_loader`로 데이터셋 로드 (iris, wine 등)
2. **Train**: 최소 2개 이상 알고리즘으로 `train_model` 실행
3. **Evaluate**: `evaluate_model`로 5-fold 교차 검증
4. **Compare**: 평균 정확도와 표준편차를 비교
5. **Recommend**: 최적 모델 추천 및 근거 설명

## 지원 알고리즘
| 알고리즘 | 키 | 특징 |
|---------|-----|------|
| Random Forest | `random_forest` | 앙상블, 과적합 방지 |
| SVM | `svm` | 고차원 데이터에 강함 |
| Logistic Regression | `logistic` | 해석 가능, 빠름 |

## 모델 비교 기준
- **평균 CV 점수**: 일반화 성능의 주요 지표
- **표준편차**: 안정성 지표 (낮을수록 좋음)
- **Trade-off**: 정확도 vs 해석 가능성 vs 학습 시간

## 서브에이전트 위임
전처리가 필요하면 `data-preprocessor` 서브에이전트에게 위임:
- 결측치 처리
- 스케일링 (StandardScaler, MinMaxScaler)
- 범주형 인코딩 (OneHotEncoder, LabelEncoder)

## 보고 형식
```
| 알고리즘 | 테스트 정확도 | CV 평균 | CV 표준편차 |
|---------|-------------|---------|-----------|
| random_forest | 0.9667 | 0.9600 | 0.0163 |
| svm | 0.9333 | 0.9533 | 0.0249 |
| logistic | 0.9333 | 0.9467 | 0.0327 |

추천: random_forest (가장 높은 CV 평균, 가장 낮은 표준편차)
```
