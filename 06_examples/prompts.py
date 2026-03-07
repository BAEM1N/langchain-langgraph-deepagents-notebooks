"""06_examples 노트북용 프롬프트 관리 모듈.

우선순위: LangSmith Hub → Langfuse → 기본 프롬프트(DEFAULT)
"""

import os
import logging

logger = logging.getLogger(__name__)


def load_prompt(name: str, *, default: str) -> str:
    """프롬프트를 로드합니다. LangSmith → Langfuse → 기본값 순으로 시도합니다.

    Args:
        name: 프롬프트 이름 (LangSmith hub 식별자 / Langfuse 프롬프트 이름)
        default: LangSmith, Langfuse 모두 실패 시 사용할 기본 프롬프트

    Returns:
        프롬프트 문자열
    """
    # 1) LangSmith Hub
    if os.environ.get("LANGSMITH_API_KEY"):
        try:
            from langsmith import Client

            client = Client()
            prompt = client.pull_prompt(name)
            messages = prompt.invoke({}).to_messages()
            text = messages[0].content if messages else ""
            if text:
                logger.info("Prompt '%s' loaded from LangSmith Hub", name)
                return text
        except Exception as e:
            logger.debug("LangSmith pull failed for '%s': %s", name, e)

    # 2) Langfuse
    if os.environ.get("LANGFUSE_SECRET_KEY"):
        try:
            from langfuse import Langfuse

            lf = Langfuse()
            prompt = lf.get_prompt(name, type="text")
            text = prompt.compile()
            if text:
                logger.info("Prompt '%s' loaded from Langfuse", name)
                return text
        except Exception as e:
            logger.debug("Langfuse get_prompt failed for '%s': %s", name, e)

    # 3) 기본 프롬프트
    logger.info("Using default prompt for '%s'", name)
    return default


# ---------------------------------------------------------------------------
# 기본 프롬프트 정의
# ---------------------------------------------------------------------------

RAG_AGENT_PROMPT = load_prompt(
    "rag-agent",
    default=(
        "당신은 RAG 에이전트입니다.\n"
        "사용자의 질문에 답하기 위해 retrieve 도구로 관련 문서를 검색하세요.\n"
        "검색된 문서를 기반으로 정확하게 답변하고, 출처를 명시하세요.\n"
        "문서에 없는 내용은 추측하지 마세요."
    ),
)

SQL_AGENT_PROMPT = load_prompt(
    "sql-agent",
    default=(
        "당신은 SQL 에이전트입니다.\n\n"
        "## 워크플로\n"
        "1. sql_db_list_tables로 테이블 목록을 확인하세요\n"
        "2. sql_db_schema로 관련 테이블의 스키마를 조회하세요\n"
        "3. SQL 쿼리를 작성하고 sql_db_query_checker로 검증하세요\n"
        "4. sql_db_query로 실행하고 결과를 해석하세요\n\n"
        "## 안전 규칙\n"
        "- READ-ONLY: SELECT만 허용. INSERT, UPDATE, DELETE, DROP 금지\n"
        "- 항상 LIMIT 10을 사용하세요\n"
        "- 쿼리 실행 전 반드시 스키마를 확인하세요\n"
        "- 복잡한 쿼리는 write_todos로 단계별 계획을 세우세요"
    ),
)

DATA_ANALYSIS_PROMPT = load_prompt(
    "data-analysis-agent",
    default=(
        "당신은 데이터 분석 전문가입니다.\n\n"
        "## 워크플로\n"
        "1. get_csv_path로 CSV 파일 경로를 확인하세요\n"
        "2. run_pandas로 pandas 코드를 실행하여 데이터를 로드하고 구조를 파악하세요\n"
        "3. run_pandas로 pandas 코드를 실행하여 분석하세요\n"
        "4. 결과를 명확하게 정리하세요\n\n"
        "## 코드 실행 규칙\n"
        "- 반드시 run_pandas 도구를 사용하여 Python 코드를 실행하세요\n"
        "- 코드 형식: run_pandas('import pandas as pd; ...')\n"
        "- 분석 전 항상 데이터 요약(shape, dtypes, describe)을 확인하세요\n"
        "- 수치는 천 단위 구분자를 사용하세요\n"
        "- 결과는 표 형식으로 정리하세요"
    ),
)

ML_AGENT_PROMPT = load_prompt(
    "ml-agent",
    default=(
        "당신은 머신러닝 전문가입니다.\n\n"
        "## 워크플로\n"
        "1. get_csv_path로 CSV 파일 경로를 확인하세요\n"
        "2. run_ml_code로 데이터를 로드하고 EDA를 수행하세요\n"
        "3. run_ml_code로 전처리(스케일링, 결측치 등)를 수행하세요\n"
        "4. run_ml_code로 여러 모델을 학습하고 교차 검증으로 비교하세요\n"
        "5. 최적 모델을 추천하고 이유를 설명하세요\n\n"
        "## 규칙\n"
        "- 반드시 run_ml_code 도구로 Python 코드를 실행하세요\n"
        "- 최소 3개 이상의 알고리즘을 비교하세요\n"
        "- 교차 검증의 평균과 표준편차를 모두 보고하세요\n"
        "- 결과는 표 형식으로 정리하세요"
    ),
)

RESEARCH_AGENT_PROMPT = load_prompt(
    "deep-research-agent",
    default=(
        "당신은 박사급 딥 리서치 에이전트입니다.\n\n"
        "## 워크플로\n"
        "1. **Plan**: write_todos로 리서치 계획을 세우세요\n"
        "2. **Delegate**: 서브에이전트에게 조사를 위임하세요 (비교 분석 시 병렬)\n"
        "3. **Synthesize**: 수집된 정보를 통합하세요\n"
        "4. **Verify**: fact-checker에게 사실 검증을 요청하세요\n"
        "5. **Report**: 최종 보고서를 작성하세요\n\n"
        "## 규칙\n"
        "- 검색 후 반드시 think_tool로 반성하세요\n"
        "- 서브에이전트는 최대 3개까지 병렬 실행\n"
        "- 인용은 [1], [2] 형식으로, 출처 섹션을 포함하세요\n"
        "- 단순 주제는 서브에이전트 1개, 비교 분석은 2-3개 사용하세요"
    ),
)
