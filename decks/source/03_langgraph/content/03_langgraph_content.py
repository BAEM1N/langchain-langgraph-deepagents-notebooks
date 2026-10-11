# -*- coding: utf-8 -*-
"""03_langgraph — 슬라이드 콘텐츠.

Portable editable source normalized on 2026-10-11 so SLIDES is literal final content.
Do not reintroduce runtime overlay functions that hide stale base snippets.
"""
BRAND = '© 주식회사 똑똑한청년들 · 배움 에이아이'
SLIDES = [{'type': 'cover',
  'eyebrow': 'LANGGRAPH TRACK',
  'title': 'AI 에이전트 개발 심화',
  'tagline': 'LangGraph로 상태와 흐름 제어하기',
  'credit': '주식회사 똑똑한청년들 · 배움 에이아이'},
 {'type': 'divider',
  'kicker': 'PART 01',
  'title': '오리엔테이션',
  'sub': '입문과 LangChain 기초에서 감춰져 있던 실행 흐름을 StateGraph와 Functional API로 직접 제어합니다.'},
 {'type': 'layers',
  'meta': '01 / 오리엔테이션',
  'title': 'LangGraph는 에이전트의 흐름을 코드가 아니라 그래프로 고정합니다',
  'lead': '상태·노드·엣지를 명시하면 분기, 반복, 중단, 재개를 같은 모델로 설명할 수 있습니다',
  'layers': [{'name': 'State',
              'tag': '공유 데이터',
              'desc': '노드들이 읽고 갱신하는 TypedDict·MessagesState입니다. 리듀서가 누적 방식을 정합니다.',
              'mono': 'TypedDict · Annotated'},
             {'name': 'Node',
              'tag': '작업 단위',
              'desc': '상태 일부를 받아 바뀐 부분만 반환하는 Python 함수입니다. LLM 호출도 하나의 노드가 됩니다.',
              'mono': 'def node(state) -> dict'},
             {'name': 'Edge',
              'tag': '흐름 제어',
              'desc': '고정 연결과 조건부 연결로 다음 노드를 결정합니다. START와 END가 실행 경계를 만듭니다.',
              'mono': 'add_edge · add_conditional_edges'}]},
 {'type': 'flow',
  'meta': '01 / 오리엔테이션',
  'title': '이번 트랙은 그래프 작성에서 운영 배포까지 한 번에 이어집니다',
  'lead': '각 노트북은 LangGraph가 제공하는 제어 지점을 하나씩 넓힙니다',
  'nodes': [{'h': 'GRAPH', 'p': 'StateGraph', 'note': '상태 스키마와 노드·엣지로 기본 실행 흐름을 만듭니다.', 'hl': True},
            {'h': 'FUNC', 'p': 'entrypoint', 'note': '함수형 워크플로와 task checkpoint를 배웁니다.'},
            {'h': 'AGENT', 'p': 'ReAct', 'note': '도구 호출 루프를 직접 구성합니다.'},
            {'h': 'CONTROL', 'p': 'interrupt', 'note': '사람 승인과 타임 트래블로 실행을 조정합니다.'},
            {'h': 'RUN', 'p': 'server', 'note': '테스트, Studio, 로컬 서버, 내구성 실행까지 연결합니다.'}],
  'sum': 'LangGraph 심화의 핵심은 모델이 아니라 <strong>상태 전이</strong>를 설계하는 능력입니다.'},
 {'type': 'table',
  'meta': '01 / 오리엔테이션',
  'title': '03_langgraph는 13개 노트북으로 그래프 제어의 전체 표면을 다룹니다',
  'lead': 'Graph API와 Functional API를 모두 써 보고, 운영에서 필요한 중단·재개·관측까지 확장합니다',
  'cols': [{'t': '구간', 'w': '22%'}, {'t': '노트북', 'w': '38%'}, {'t': '학습 산출', 'accent': True}],
  'rows': [['기본 구조', '01~03 소개·Graph API·Functional API', 'StateGraph와 @entrypoint/@task를 모두 설명할 수 있습니다'],
           ['패턴과 에이전트', '04~05 워크플로·ReAct 에이전트', '분기·병렬·오케스트레이터·도구 루프를 직접 작성합니다'],
           ['상태 제어', '06~09 메모리·스트리밍·인터럽트·서브그래프', '실행 이력, 사람 승인, replay/fork, namespace 격리를 다룹니다'],
           ['운영', '10~13 프로덕션·서버·내구성·Pregel', '테스트, 배포, SDK, fault tolerance, API 선택 기준을 정리합니다']]},
 {'type': 'divider',
  'kicker': 'PART 02',
  'title': 'LangGraph 실행 모델',
  'sub': 'LangChain 위에서 복잡한 에이전트 흐름을 상태 그래프로 설계하는 이유를 정리합니다.',
  'lab': '03_langgraph/01_introduction.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 심화',
  'meta': '02 / 소개',
  'title': 'LangGraph는 상태를 중심으로 실행·중단·재개를 설명합니다',
  'lead': '입문자는 노드보다 먼저 상태가 어떻게 변하는지 추적해야 합니다',
  'cols': [{'t': '개념', 'w': '24%'}, {'t': '의미', 'w': '40%'}, {'t': '학습 포인트', 'accent': True}],
  'rows': [['State', '그래프가 읽고 쓰는 공유 데이터', 'TypedDict와 reducer를 구분합니다'],
           ['Node', '상태를 받아 일부 상태를 반환하는 함수', '노드는 전체 상태가 아니라 변경분을 돌려줍니다'],
           ['Edge', '다음 노드를 결정하는 연결', '조건부 엣지는 라우팅 함수와 함께 봅니다'],
           ['Checkpoint', '실행 중 상태 저장', 'interrupt, time travel, memory의 전제입니다']]},
 {'type': 'cards',
  'course': 'AI 에이전트 개발 심화',
  'meta': '02 / 소개',
  'title': 'Graph API와 Functional API는 표현 방식이 다를 뿐 같은 실행 모델을 공유합니다',
  'lead': '초반에 두 API의 역할을 구분하면 뒤의 노트북을 읽기 쉬워집니다',
  'cards': [{'h': 'Graph API', 'p': '상태 스키마, 노드, 엣지를 명시적으로 선언합니다.', 'm': 'StateGraph'},
            {'h': 'Functional API', 'p': '@entrypoint와 @task로 함수 호출처럼 그래프 기능을 사용합니다.', 'm': 'entrypoint · task'},
            {'h': '공통 기반', 'p': '둘 다 체크포인터, 스트리밍, interrupt 같은 런타임 기능을 사용합니다.', 'm': 'checkpointer'},
            {'h': '선택 기준', 'p': '흐름을 문서화해야 하면 Graph API, 코드 흐름이 자연스러우면 Functional API가 편합니다.', 'm': 'API choice'}]},
 {'type': 'figure',
  'meta': '02 / 소개',
  'title': 'LangChain·LangGraph·Deep Agents는 계층이 다르고 책임도 다릅니다',
  'lead': 'LangGraph는 LangChain의 모델·도구 인터페이스 위에 상태 기반 오케스트레이션을 올립니다',
  'img_src': 'assets/diagrams/langchain_3layer.png',
  'cap': 'LangChain 3계층',
  'points': [{'h': 'LangChain', 'p': '모델과 도구를 연결하는 기본 인터페이스입니다.'},
             {'h': 'LangGraph', 'p': '상태·노드·엣지로 실행 흐름을 직접 제어합니다.'},
             {'h': 'Deep Agents',
              'p': 'LangGraph 위에 파일·서브에이전트·메모리·스킬을 얹는 장기 작업 하네스입니다. 계획은 필요할 때 TodoListMiddleware로 추가합니다.'}]},
 {'type': 'table',
  'meta': '02 / 소개',
  'title': 'Graph API와 Functional API는 같은 런타임을 다른 표면으로 다룹니다',
  'lead': '복잡한 흐름은 Graph API, 직선형 파이프라인은 Functional API가 읽기 쉽습니다',
  'cols': [{'t': 'API', 'w': '24%'}, {'t': '작성 방식', 'w': '32%'}, {'t': '적합한 상황', 'accent': True}],
  'rows': [['Graph API', 'StateGraph에 노드와 엣지를 명시', '분기·반복·시각화·복잡한 에이전트 제어'],
           ['Functional API', '@entrypoint와 @task로 함수형 작성', '작업 파이프라인·병렬 태스크·짧은 워크플로'],
           ['공통점', 'checkpointer와 stream을 공유', '중단·재개·관측을 같은 방식으로 다룸']]},
 {'type': 'code-split',
  'meta': '02 / 소개',
  'title': 'StateGraph의 최소 실행 흐름은 생성·노드·엣지·컴파일·호출입니다',
  'lead': '노드는 전체 상태가 아니라 바뀐 필드만 dict로 반환합니다',
  'points': [{'h': 'StateGraph', 'p': '상태 스키마를 기준으로 그래프 빌더를 만듭니다.'},
             {'h': 'START/END', 'p': '실행의 시작점과 종료점을 명시합니다.'},
             {'h': 'compile', 'p': '연결 오류를 검증하고 실행 가능한 그래프로 바꿉니다.'}],
  'code': 'from typing import TypedDict\n'
          'from langgraph.graph import StateGraph, START, END\n'
          '\n'
          'class State(TypedDict):\n'
          '    text: str\n'
          '    word_count: int\n'
          '\n'
          'def count_words(state: State) -> dict:\n'
          '    return {"word_count": len(state["text"].split())}\n'
          '\n'
          'builder = StateGraph(State)\n'
          'builder.add_node("counter", count_words)\n'
          'builder.add_edge(START, "counter")\n'
          'builder.add_edge("counter", END)\n'
          'graph = builder.compile()\n'
          'print(graph.invoke({"text": "LangGraph 상태 그래프"}))',
  'file': '01_introduction.ipynb',
  'note': '노트북 기준'},
 {'type': 'dense',
  'meta': '02 / 소개',
  'title': "처음에는 그래프를 '제어 가능한 실행 로그'로 보는 편이 쉽습니다",
  'lead': '그래프는 그림이 아니라 실행 중 상태가 어디서 바뀌었는지 추적하는 구조입니다',
  'groups': [{'t': '상태가 명시되면 테스트가 쉬워집니다',
              'kids': [{'t': '각 노드는 입력 상태와 출력 업데이트만 검증하면 됩니다'}, {'t': '조건부 엣지는 라우팅 함수 하나로 분리됩니다'}]},
             {'t': '컴파일된 그래프는 LangGraph 런타임 기능을 얻습니다',
              'kids': [{'t': 'stream, checkpointer, interrupt, get_state_history를 같은 방식으로 사용합니다'},
                       {'t': 'Studio와 서버 배포에서도 같은 그래프 객체를 대상으로 삼습니다'}]}]},
 {'type': 'divider',
  'kicker': 'PART 03',
  'title': 'Graph API',
  'sub': 'StateGraph의 기본 문법과 add_node 고급 옵션, Send·Command를 한 번에 정리합니다.',
  'lab': '03_langgraph/02_graph_api.ipynb'},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 심화',
  'meta': '03 / Graph API',
  'title': '조건부 엣지는 상태 값을 다음 노드 이름으로 바꾸는 라우터입니다',
  'lead': '라우팅 함수는 비즈니스 분류 결과를 그래프 제어 흐름으로 바꿉니다',
  'points': [{'h': 'classify', 'p': '입력 질문을 category로 분류합니다.'},
             {'h': 'route', 'p': 'category 값을 노드 이름으로 반환합니다.'},
             {'h': 'add_conditional_edges', 'p': '분기 가능한 목적지를 그래프에 등록합니다.'}],
  'code': 'from typing import Literal\n'
          '\n'
          'def route(state: RouterState) -> Literal["weather", "math", "general"]:\n'
          '    return state["category"]\n'
          '\n'
          'builder = StateGraph(RouterState)\n'
          'builder.add_node("classify", classify)\n'
          'builder.add_node("weather", handle_weather)\n'
          'builder.add_node("math", handle_math)\n'
          'builder.add_node("general", handle_general)\n'
          'builder.add_edge(START, "classify")\n'
          'builder.add_conditional_edges("classify", route)\n'
          'builder.add_edge("weather", END)',
  'file': '02_graph_api.ipynb',
  'note': 'conditional edges'},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 심화',
  'meta': '03 / Graph API',
  'title': '입출력 스키마를 분리하면 내부 상태를 외부 응답에서 숨길 수 있습니다',
  'lead': '프로덕션 API에서는 내부 중간값과 외부 응답 형식을 분리해야 합니다',
  'points': [{'h': 'InputSchema', 'p': '호출자가 넣는 입력만 정의합니다.'},
             {'h': 'InternalState', 'p': '그래프 내부 계산에 필요한 중간 필드를 포함합니다.'},
             {'h': 'OutputSchema', 'p': '최종 사용자에게 돌려줄 필드만 노출합니다.'}],
  'code': 'class InputSchema(TypedDict):\n'
          '    question: str\n'
          '\n'
          'class OutputSchema(TypedDict):\n'
          '    answer: str\n'
          '\n'
          'class InternalState(TypedDict):\n'
          '    question: str\n'
          '    answer: str\n'
          '    intermediate: str\n'
          '\n'
          'builder = StateGraph(\n'
          '    InternalState,\n'
          '    input_schema=InputSchema,\n'
          '    output_schema=OutputSchema,\n'
          ')',
  'file': '02_graph_api.ipynb',
  'note': 'input/output schema'},
 {'type': 'figure',
  'meta': '03 / Graph API',
  'title': '조건부 엣지는 그래프를 if문 더미가 아니라 라우팅 표면으로 만듭니다',
  'lead': '분기 로직이 함수로 분리되면 테스트와 관측이 쉬워집니다',
  'img_src': 'assets/diagrams/conditional_routing.png',
  'cap': 'Conditional routing',
  'points': [{'h': '분류 노드', 'p': 'state를 읽고 category 같은 라우팅 키를 만듭니다.'},
             {'h': 'route 함수', 'p': '다음 노드 이름을 Literal로 반환합니다.'},
             {'h': '핸들러 노드', 'p': '각 경로는 독립적으로 테스트할 수 있습니다.'}]},
 {'type': 'code-split',
  'meta': '03 / Graph API',
  'title': 'Annotated 리듀서는 상태를 덮어쓸지 누적할지 결정합니다',
  'lead': '노드가 같은 키를 갱신해도 리듀서가 있으면 리스트처럼 안전하게 합쳐집니다',
  'points': [{'h': '기본값', 'p': '리듀서가 없으면 마지막 업데이트가 값을 덮어씁니다.'},
             {'h': 'operator.add', 'p': '리스트를 누적할 때 가장 자주 쓰는 패턴입니다.'},
             {'h': '메시지', 'p': 'MessagesState는 add_messages 리듀서를 미리 제공합니다.'}],
  'code': 'from typing import Annotated, TypedDict\n'
          'import operator\n'
          '\n'
          'class AccState(TypedDict):\n'
          '    items: Annotated[list[str], operator.add]\n'
          '    count: int\n'
          '\n'
          'def step_a(state: AccState) -> dict:\n'
          '    return {"items": ["from_a"], "count": 1}\n'
          '\n'
          'def step_b(state: AccState) -> dict:\n'
          '    return {"items": ["from_b"], "count": 2}\n'
          '\n'
          'builder = StateGraph(AccState)\n'
          'builder.add_node("a", step_a)\n'
          'builder.add_node("b", step_b)\n'
          'builder.add_edge(START, "a")\n'
          'builder.add_edge("a", "b")',
  'file': '02_graph_api.ipynb',
  'note': 'Reducer'},
 {'type': 'table',
  'meta': '03 / Graph API',
  'title': 'Graph API의 운영 옵션은 노드 선언 시점에 붙입니다',
  'lead': 'retry, timeout, cache, error_handler, defer는 실행 정책이지 노드 내부 로직이 아닙니다',
  'cols': [{'t': '옵션', 'w': '24%'}, {'t': '역할', 'w': '32%'}, {'t': '적용 기준', 'accent': True}],
  'rows': [['retry_policy', '일시 장애 자동 재시도', '네트워크·일시적 API 오류'],
           ['timeout', '노드 실행 시간 제한', '외부 호출이 긴 노드'],
           ['cache_policy', '같은 입력 결과 재사용', '비싼 계산·검색'],
           ['error_handler', '실패 후 보정 경로', '결제·파일 쓰기 같은 보정 필요 작업'],
           ['defer', '그래프 종료 직전 지연 실행', '정리·알림·후처리']]},
 {'type': 'code-split',
  'meta': '03 / Graph API',
  'title': 'Send는 동적 fan-out을 만들고 Command는 상태 업데이트와 라우팅을 함께 표현합니다',
  'lead': 'map-reduce처럼 입력 개수에 따라 worker 수가 달라지는 흐름에서 Send가 핵심입니다',
  'points': [{'h': 'Send', 'p': '같은 노드를 여러 입력으로 동적으로 호출합니다.'},
             {'h': 'Command', 'p': 'update와 goto를 한 객체에 담아 라우팅합니다.'},
             {'h': '부모 그래프', 'p': 'Command.PARENT로 서브그래프 밖 라우팅도 표현합니다.'}],
  'code': 'from typing import Annotated, TypedDict\n'
          'import operator\n'
          'from langgraph.types import Send\n'
          '\n'
          'class FanOutState(TypedDict):\n'
          '    items: list[str]\n'
          '    results: Annotated[list[str], operator.add]\n'
          '\n'
          'def dispatch(state: FanOutState) -> list[Send]:\n'
          '    return [Send("worker", {"item": item}) for item in state["items"]]\n'
          '\n'
          'def worker(state: dict) -> dict:\n'
          '    return {"results": [f"처리: {state[\'item\']}"]}\n'
          '\n'
          'builder = StateGraph(FanOutState)\n'
          'builder.add_node("worker", worker)\n'
          'builder.add_conditional_edges(START, dispatch, ["worker"])\n'
          'builder.add_edge("worker", END)',
  'file': '02_graph_api.ipynb',
  'note': 'Send'},
 {'type': 'divider',
  'kicker': 'PART 04',
  'title': 'Functional API',
  'sub': '@entrypoint와 @task로 병렬 작업, previous 메모리, 캐싱, 구조화 interrupt를 다룹니다.',
  'lab': '03_langgraph/03_functional_api.ipynb'},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 심화',
  'meta': '04 / Functional API',
  'title': '@task 결과는 future로 돌아오고 result()를 호출할 때 값이 필요해집니다',
  'lead': 'Functional API의 병렬성은 함수처럼 보이지만 즉시 값이 아니라 future를 다룬다는 점에서 출발합니다',
  'points': [{'h': '@task', 'p': '재시도와 체크포인트가 가능한 작업 단위입니다.'},
             {'h': 'future', 'p': 'task 호출 결과는 나중에 result()로 수집합니다.'},
             {'h': '@entrypoint', 'p': '전체 실행의 진입점과 체크포인터를 정의합니다.'}],
  'code': 'from langgraph.func import entrypoint, task\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '@task\n'
          'def fetch_data(url: str) -> str:\n'
          '    return f"{url}에서 가져온 데이터"\n'
          '\n'
          '@task\n'
          'def process_data(data: str) -> str:\n'
          '    return f"처리 완료: {data.upper()}"\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def data_pipeline(url: str) -> str:\n'
          '    raw = fetch_data(url).result()\n'
          '    return process_data(raw).result()',
  'file': '03_functional_api.ipynb',
  'note': '@task + @entrypoint'},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 심화',
  'meta': '04 / Functional API',
  'title': 'Functional API는 편하지만 결정론성 요구사항을 지켜야 합니다',
  'lead': '재실행 가능한 그래프는 같은 입력과 체크포인트에서 같은 흐름으로 돌아와야 합니다',
  'groups': [{'t': '지켜야 할 것',
              'kids': [{'t': 'entrypoint 안에서 외부 부작용을 무작정 실행하지 않습니다'},
                       {'t': '오래 걸리거나 실패할 수 있는 작업은 @task로 분리합니다'},
                       {'t': '체크포인터를 쓸 때 thread_id를 명시합니다'}]},
             {'t': '헷갈리기 쉬운 것',
              'kids': [{'t': 'print나 임시 변수는 저장되지 않습니다'},
                       {'t': 'entrypoint.final은 반환값과 저장값을 분리할 때 사용합니다'},
                       {'t': 'previous는 같은 thread에서 이전 저장값을 읽을 때 사용합니다'}]}]},
 {'type': 'code-split',
  'meta': '04 / Functional API',
  'title': '@task는 체크포인트되는 비동기 작업 단위입니다',
  'lead': 'task 호출은 Future를 반환하고 .result()로 결과를 수집합니다',
  'points': [{'h': '@task', 'p': '재시도·타임아웃·캐싱을 붙일 수 있는 작업 단위입니다.'},
             {'h': '@entrypoint', 'p': '워크플로 진입점이며 checkpointer를 받습니다.'},
             {'h': 'thread_id', 'p': '같은 entrypoint라도 실행 이력을 구분합니다.'}],
  'code': 'from langgraph.func import entrypoint, task\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '@task\n'
          'def fetch_data(url: str) -> str:\n'
          '    return f"{url}에서 가져온 데이터"\n'
          '\n'
          '@task\n'
          'def process_data(data: str) -> str:\n'
          '    return f"처리 완료: {data.upper()}"\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def data_pipeline(url: str) -> str:\n'
          '    raw = fetch_data(url).result()\n'
          '    return process_data(raw).result()\n'
          '\n'
          'cfg = {"configurable": {"thread_id": "pipe-1"}}\n'
          'print(data_pipeline.invoke("https://example.com/api", cfg))',
  'file': '03_functional_api.ipynb',
  'note': '노트북 기준'},
 {'type': 'table',
  'meta': '04 / Functional API',
  'title': 'Functional API의 핵심은 병렬 시작과 결정론적 재실행입니다',
  'lead': '비결정적 작업은 task 안으로 넣어야 checkpoint 재개 시 결과가 흔들리지 않습니다',
  'cols': [{'t': '기능', 'w': '26%'}, {'t': '코드 표면', 'w': '32%'}, {'t': '의미', 'accent': True}],
  'rows': [['병렬 실행', '여러 task를 먼저 호출 후 result 수집', '독립 작업을 동시에 시작'],
           ['previous', 'entrypoint 인자 previous', '같은 thread의 이전 저장값 접근'],
           ['entrypoint.final', 'value와 save 분리', '사용자 반환값과 다음 실행 저장값 분리'],
           ['결정론성', '시간·LLM·IO는 task 내부', '재개 시 같은 작업을 중복 실행하지 않음']]},
 {'type': 'code-split',
  'meta': '04 / Functional API',
  'title': 'previous와 entrypoint.final은 사용자 반환값과 저장값을 분리합니다',
  'lead': '보이는 답변은 문자열이어도 다음 실행에는 숫자 상태를 저장할 수 있습니다',
  'points': [{'h': 'previous', 'p': '이전 실행의 save 값이 자동 주입됩니다.'},
             {'h': 'value', 'p': '이번 호출자가 받는 반환값입니다.'},
             {'h': 'save', 'p': '다음 호출의 previous로 저장되는 값입니다.'}],
  'codes': [{'file': 'previous.py',
             'note': '단기 메모리',
             'code': '@entrypoint(checkpointer=InMemorySaver())\n'
                     'def counter(increment: int, *, previous: int = 0) -> int:\n'
                     '    return (previous or 0) + increment'},
            {'file': 'final.py',
             'note': '반환/저장 분리',
             'code': '@entrypoint(checkpointer=InMemorySaver())\n'
                     'def smart_counter(n: int, *, previous: int = 0) -> entrypoint.final[str, int]:\n'
                     '    total = (previous or 0) + n\n'
                     '    return entrypoint.final(value=f"현재 합계: {total}", save=total)'}]},
 {'type': 'code-split',
  'meta': '04 / Functional API',
  'title': 'Functional API에서도 interrupt는 Command(resume=...)으로 재개합니다',
  'lead': '사람 검토가 들어가는 작업은 checkpointer가 있어야 중단 지점을 기억합니다',
  'points': [{'h': 'interrupt', 'p': '사람에게 보여줄 질문과 검토 대상을 구조화합니다.'},
             {'h': 'Command', 'p': 'resume 값으로 중단 지점에 답을 전달합니다.'},
             {'h': '재개', 'p': '같은 thread_id를 써야 같은 실행으로 이어집니다.'}],
  'code': 'from langgraph.types import Command, interrupt\n'
          '\n'
          '@task\n'
          'def review(draft: str) -> str:\n'
          '    feedback = interrupt({"question": "승인하시겠어요?", "draft": draft})\n'
          '    if feedback.get("approve"):\n'
          '        return draft\n'
          '    return f"{draft} (수정: {feedback.get(\'comment\', \'\')})"\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def approval_flow(topic: str) -> str:\n'
          '    return review(f"{topic} 초안").result()\n'
          '\n'
          'cfg = {"configurable": {"thread_id": "hitl-1"}}\n'
          'approval_flow.invoke("LangGraph", cfg)\n'
          'approval_flow.invoke(Command(resume={"approve": True}), cfg)',
  'file': '03_functional_api.ipynb',
  'note': 'interrupt'},
 {'type': 'divider',
  'kicker': 'PART 05',
  'title': '워크플로 패턴',
  'sub': 'Prompt chaining, parallelization, routing, orchestrator-worker, evaluator-optimizer를 StateGraph로 구현합니다.',
  'lab': '03_langgraph/04_workflows.ipynb'},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 심화',
  'meta': '05 / 워크플로',
  'title': 'Send는 실행 시점에 워커 수가 정해지는 fan-out 패턴에 사용합니다',
  'lead': '고정된 분기보다 동적으로 여러 작업을 만들어야 할 때 Send가 필요합니다',
  'points': [{'h': 'dispatch', 'p': '입력 리스트를 worker 호출 목록으로 바꿉니다.'},
             {'h': 'worker', 'p': '각 항목을 독립적으로 처리합니다.'},
             {'h': 'reducer', 'p': 'Annotated reducer로 결과를 모읍니다.'}],
  'code': 'from langgraph.types import Send\n'
          '\n'
          'def dispatch(state: FanOutState) -> list[Send]:\n'
          '    return [Send("worker", {"item": it}) for it in state["items"]]\n'
          '\n'
          'def worker(state: dict) -> dict:\n'
          '    return {"results": [f"처리({state[\'item\']})"]}\n'
          '\n'
          'builder.add_conditional_edges(START, dispatch, ["worker"])\n'
          'builder.add_edge("worker", "reduce")',
  'file': '04_workflows.ipynb',
  'note': 'orchestrator-worker'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 심화',
  'meta': '05 / 워크플로',
  'title': '워크플로 패턴은 실패 지점과 비용 구조가 서로 다릅니다',
  'lead': '패턴 이름보다 어떤 운영 문제가 생기는지 기준으로 선택해야 합니다',
  'cols': [{'t': '패턴', 'w': '26%'}, {'t': '적합한 작업', 'w': '40%'}, {'t': '운영 주의점', 'accent': True}],
  'rows': [['Prompt Chaining', '검토 단계를 순서대로 통과하는 작업', '앞 단계 오류가 뒤로 전파됩니다'],
           ['Parallelization', '서로 독립적인 분석 작업', '결과 합성 기준이 필요합니다'],
           ['Routing', '질문 유형별 처리 분기', '분류 오류가 곧 잘못된 경로가 됩니다'],
           ['Orchestrator-Worker', '작업 수가 입력마다 달라지는 경우', 'worker 결과를 줄이는 reducer가 중요합니다'],
           ['Evaluator-Optimizer', '생성·평가 반복 개선', '반복 제한과 종료 기준이 필요합니다']]},
 {'type': 'table',
  'meta': '05 / 워크플로',
  'title': "다섯 패턴은 'LLM을 몇 번 부르나'보다 제어 구조가 다릅니다",
  'lead': '각 패턴은 실패 지점과 테스트 방식이 달라집니다',
  'cols': [{'t': '패턴', 'w': '28%'}, {'t': '흐름', 'w': '32%'}, {'t': '적합한 문제', 'accent': True}],
  'rows': [['Prompt Chaining', 'A 결과를 B 입력으로 전달', '단계별 품질 게이트가 필요한 글쓰기'],
           ['Parallelization', '독립 작업 동시 실행 후 합치기', '요약·분류·검토를 병렬로 처리'],
           ['Routing', '분류 결과로 다음 노드 선택', '문의 유형별 전문 처리'],
           ['Orchestrator-Worker', '계획 후 worker 동적 생성', '섹션 수가 입력마다 달라지는 보고서'],
           ['Evaluator-Optimizer', '생성·평가 반복', '품질 기준을 통과할 때까지 개선']]},
 {'type': 'figure',
  'meta': '05 / 워크플로',
  'title': 'Orchestrator-Worker는 계획 결과만큼 worker를 동적으로 만듭니다',
  'lead': 'StateGraph에서는 Send()가 이 동적 fan-out의 연결점입니다',
  'img_src': 'assets/diagrams/orchestrator_worker.png',
  'cap': 'Orchestrator-Worker',
  'points': [{'h': 'Orchestrator', 'p': '전체 작업을 보고 worker 입력 목록을 만듭니다.'},
             {'h': 'Worker', 'p': '각 작업 단위를 독립적으로 처리합니다.'},
             {'h': 'Reducer', 'p': 'worker 결과를 리스트나 문서로 합칩니다.'}]},
 {'type': 'code-split',
  'meta': '05 / 워크플로',
  'title': 'Routing은 조건부 엣지 하나로 분류와 처리를 분리합니다',
  'lead': '분류 노드를 테스트하면 라우팅 품질을 별도 지표로 볼 수 있습니다',
  'points': [{'h': 'classify', 'p': '입력 질문을 category로 바꿉니다.'},
             {'h': 'route', 'p': 'category를 다음 노드 이름으로 변환합니다.'},
             {'h': 'handler', 'p': '각 경로의 처리는 독립 함수가 맡습니다.'}],
  'code': 'from typing import Literal, TypedDict\n'
          '\n'
          'class RouteState(TypedDict):\n'
          '    query: str\n'
          '    category: str\n'
          '    result: str\n'
          '\n'
          'def classify(state: RouteState) -> dict:\n'
          '    q = state["query"].lower()\n'
          '    if "계산" in q:\n'
          '        return {"category": "math"}\n'
          '    return {"category": "general"}\n'
          '\n'
          'def route(state: RouteState) -> Literal["math", "general"]:\n'
          '    return state["category"]\n'
          '\n'
          'builder.add_conditional_edges("classify", route)',
  'file': '04_workflows.ipynb',
  'note': 'Routing'},
 {'type': 'flow',
  'meta': '05 / 워크플로',
  'title': 'Evaluator-Optimizer는 품질 기준을 그래프의 반복 조건으로 만듭니다',
  'lead': '평가 결과가 통과일 때만 END로 가고, 아니면 optimizer로 되돌립니다',
  'nodes': [{'h': 'GENERATE', 'p': '초안 생성', 'note': '모델이 첫 결과를 만듭니다.', 'hl': True},
            {'h': 'EVALUATE', 'p': '점수화', 'note': '규칙이나 LLM으로 결과를 평가합니다.'},
            {'h': 'ROUTE', 'p': '통과 판단', 'note': '기준 미달이면 개선 경로로 보냅니다.'},
            {'h': 'OPTIMIZE', 'p': '수정', 'note': '피드백을 반영해 다시 생성합니다.'}],
  'sum': '이 패턴은 LLM을 믿는 대신 <strong>검사 가능한 품질 루프</strong>를 그래프에 넣는 방식입니다.'},
 {'type': 'divider',
  'kicker': 'PART 06',
  'title': 'ReAct 에이전트',
  'sub': 'Graph API와 Functional API로 도구 호출 루프를 직접 만들고 스트리밍과 메모리까지 연결합니다.',
  'lab': '03_langgraph/05_agents.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 심화',
  'meta': '06 / ReAct 에이전트',
  'title': 'Graph API 에이전트는 모델 호출과 도구 실행을 명시적으로 나눕니다',
  'lead': 'ReAct를 그래프로 그리면 모델이 언제 도구를 부르고 언제 종료하는지 보입니다',
  'cols': [{'t': '구성', 'w': '24%'}, {'t': '역할', 'w': '42%'}, {'t': '코드 표면', 'accent': True}],
  'rows': [['call_model', '메시지를 보고 다음 AIMessage를 생성합니다', 'model.bind_tools(tools)'],
           ['ToolNode', 'AIMessage의 tool_calls를 실행합니다', 'ToolNode(tools)'],
           ['tools_condition', '도구 호출 여부에 따라 분기합니다', 'tools 또는 END'],
           ['MessagesState', '대화 메시지를 누적하는 상태입니다', 'messages reducer']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 심화',
  'meta': '06 / ReAct 에이전트',
  'title': 'Functional API 에이전트는 while 루프로 ReAct를 직접 표현합니다',
  'lead': '그래프 구조보다 코드 흐름을 읽는 것이 쉬운 팀에서는 Functional API 구현이 더 직관적일 수 있습니다',
  'groups': [{'t': '반복 루프',
              'kids': [{'t': '모델을 호출합니다'},
                       {'t': 'tool_calls가 없으면 최종 답변으로 종료합니다'},
                       {'t': 'tool_calls가 있으면 도구를 실행하고 메시지에 추가합니다'}]},
             {'t': '메모리 연결',
              'kids': [{'t': 'checkpointer가 있으면 같은 thread_id에서 대화가 이어집니다'}, {'t': 'thread_id가 다르면 대화 상태가 분리됩니다'}]}]},
 {'type': 'figure',
  'meta': '06 / 에이전트',
  'title': 'ReAct 루프는 llm 노드와 tools 노드의 조건부 반복입니다',
  'lead': 'create_agent가 감추던 흐름을 StateGraph로 풀어 쓰면 디버깅 지점이 분명해집니다',
  'img_src': 'assets/diagrams/react_loop.png',
  'cap': 'ReAct loop',
  'points': [{'h': 'llm', 'p': '도구 호출 여부를 판단하고 AIMessage를 생성합니다.'},
             {'h': 'tools', 'p': 'tool_calls를 실행해 ToolMessage를 만듭니다.'},
             {'h': 'should_continue', 'p': 'tool_calls가 있으면 tools, 없으면 END로 보냅니다.'}]},
 {'type': 'code-split',
  'meta': '06 / 에이전트',
  'title': 'bind_tools()는 모델이 호출할 수 있는 도구 스키마를 모델에 붙입니다',
  'lead': '도구 함수 자체는 일반 Python 함수지만 모델에는 이름·설명·입력 스키마로 보입니다',
  'points': [{'h': '@tool', 'p': '함수명과 docstring을 도구 설명으로 바꿉니다.'},
             {'h': 'tools_by_name', 'p': 'tool_call name으로 실제 함수를 찾기 위한 매핑입니다.'},
             {'h': 'bind_tools', 'p': '모델 호출 결과에 tool_calls가 생길 수 있게 합니다.'}],
  'code': 'from langchain.tools import tool\n'
          '\n'
          '@tool\n'
          'def add(a: int, b: int) -> int:\n'
          '    """두 수를 더합니다."""\n'
          '    return a + b\n'
          '\n'
          '@tool\n'
          'def multiply(a: int, b: int) -> int:\n'
          '    """두 수를 곱합니다."""\n'
          '    return a * b\n'
          '\n'
          'tools = [add, multiply]\n'
          'tools_by_name = {tool.name: tool for tool in tools}\n'
          'model_with_tools = model.bind_tools(tools)',
  'file': '05_agents.ipynb',
  'note': '노트북 기준'},
 {'type': 'code-split',
  'meta': '06 / 에이전트',
  'title': 'StateGraph ReAct 루프는 조건부 엣지 하나로 반복 여부를 결정합니다',
  'lead': '마지막 AIMessage에 tool_calls가 있으면 도구 노드로, 없으면 종료로 갑니다',
  'points': [{'h': 'messages reducer', 'p': 'Annotated와 operator.add 또는 MessagesState로 메시지를 누적합니다.'},
             {'h': 'ToolMessage', 'p': '각 tool_call_id와 결과를 정확히 매칭해야 합니다.'},
             {'h': 'checkpointer', 'p': '메모리 있는 에이전트는 compile(checkpointer=...)로 만듭니다.'}],
  'code': 'from typing import Literal\n'
          'from langgraph.graph import END\n'
          '\n'
          'def should_continue(state) -> Literal["tools", "__end__"]:\n'
          '    last = state["messages"][-1]\n'
          '    return "tools" if last.tool_calls else END\n'
          '\n'
          'builder.add_node("llm", llm_node)\n'
          'builder.add_node("tools", tool_node)\n'
          'builder.add_edge(START, "llm")\n'
          'builder.add_conditional_edges("llm", should_continue, ["tools", END])\n'
          'builder.add_edge("tools", "llm")\n'
          'agent = builder.compile(checkpointer=InMemorySaver())',
  'file': '05_agents.ipynb',
  'note': 'Graph API ReAct'},
 {'type': 'table',
  'meta': '06 / 에이전트',
  'title': 'Graph API와 Functional API 에이전트는 제어 표면이 다릅니다',
  'lead': '같은 ReAct라도 어디에 복잡성이 드러나는지가 다릅니다',
  'cols': [{'t': '구분', 'w': '24%'}, {'t': 'Graph API', 'w': '34%'}, {'t': 'Functional API', 'accent': True}],
  'rows': [['흐름 표현', '노드·엣지로 시각화', 'while 루프와 task 호출'],
           ['디버깅', '노드별 업데이트가 명확', '함수 호출 흐름이 읽기 쉬움'],
           ['복잡한 분기', '조건부 엣지로 확장 용이', '분기가 많으면 코드가 길어짐'],
           ['간단한 에이전트', '구조가 조금 장황', '짧고 직관적']]},
 {'type': 'divider',
  'kicker': 'PART 07',
  'title': '지속성과 메모리',
  'sub': 'checkpointer, get_state, get_state_history, update_state, InMemoryStore, trimming을 묶어 봅니다.',
  'lab': '03_langgraph/06_persistence_and_memory.ipynb'},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 심화',
  'meta': '07 / 지속성',
  'title': 'get_state와 get_state_history는 실행 상태를 운영자가 조회하는 표면입니다',
  'lead': '체크포인터를 쓰면 현재 상태와 과거 실행 이력을 코드로 확인할 수 있습니다',
  'points': [{'h': 'get_state', 'p': '현재 체크포인트 상태를 조회합니다.'},
             {'h': 'get_state_history', 'p': '노드별 실행 이력을 확인합니다.'},
             {'h': 'config', 'p': 'thread_id가 조회 대상 실행을 정합니다.'}],
  'code': 'config = {"configurable": {"thread_id": "user-1"}}\n'
          '\n'
          'current = graph.get_state(config)\n'
          'print(current.values)\n'
          '\n'
          'for snapshot in graph.get_state_history(config):\n'
          '    print(snapshot.next, snapshot.values)',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'state inspection'},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 심화',
  'meta': '07 / 지속성',
  'title': 'update_state는 저장된 실행 상태를 외부에서 고치는 운영 도구입니다',
  'lead': '오답 수정, 사람 검토, time travel은 저장 상태를 수정할 수 있다는 전제에서 작동합니다',
  'points': [{'h': 'as_node', 'p': '어떤 노드가 수정한 것처럼 기록할지 정합니다.'},
             {'h': 'values', 'p': '덮어쓸 상태 변경분입니다.'},
             {'h': 'thread_id', 'p': '수정 대상 실행을 지정합니다.'}],
  'code': 'config = {"configurable": {"thread_id": "user-1"}}\n'
          '\n'
          'graph.update_state(\n'
          '    config,\n'
          '    {"messages": ["수정된 사용자 입력"]},\n'
          '    as_node="human_review",\n'
          ')\n'
          '\n'
          'print(graph.get_state(config).values)',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'update_state'},
 {'type': 'code-split',
  'meta': '07 / 지속성',
  'title': 'checkpointer를 붙이면 각 단계의 상태가 자동 저장됩니다',
  'lead': 'thread_id가 같으면 같은 실행 이력을 이어가고, 다르면 완전히 독립된 상태가 됩니다',
  'points': [{'h': 'InMemorySaver', 'p': '실습용 체크포인터입니다. 프로세스 종료 시 사라집니다.'},
             {'h': 'thread_id', 'p': '대화 또는 실행 세션을 구분합니다.'},
             {'h': 'get_state', 'p': '현재 저장된 마지막 상태를 조회합니다.'}],
  'code': 'from langgraph.checkpoint.memory import InMemorySaver\n'
          'from langgraph.graph import MessagesState\n'
          '\n'
          'builder = StateGraph(MessagesState)\n'
          'builder.add_node("chatbot", chatbot)\n'
          'builder.add_edge(START, "chatbot")\n'
          'builder.add_edge("chatbot", END)\n'
          '\n'
          'graph = builder.compile(checkpointer=InMemorySaver())\n'
          'config = {"configurable": {"thread_id": "chat-1"}}\n'
          'graph.invoke({"messages": [{"role": "user", "content": "제 이름은 민수입니다."}]}, config)\n'
          'print(graph.get_state(config).values)',
  'file': '06_persistence_and_memory.ipynb',
  'note': '노트북 기준'},
 {'type': 'table',
  'meta': '07 / 지속성',
  'title': '저장된 상태는 조회·이력 확인·수정까지 가능합니다',
  'lead': '운영에서는 실패 분석과 수동 보정의 기본 도구가 됩니다',
  'cols': [{'t': '메서드', 'w': '28%'}, {'t': '반환', 'w': '30%'}, {'t': '사용 장면', 'accent': True}],
  'rows': [['get_state(config)', '현재 체크포인트 상태', '마지막 실행 결과 확인'],
           ['get_state_history(config)', '체크포인트 목록', '어느 노드에서 상태가 바뀌었는지 추적'],
           ['update_state(config, values)', '새 체크포인트', '사람이 상태를 고친 뒤 재개'],
           ['invoke(None, config)', '해당 지점부터 재개', 'Replay 또는 장애 복구']]},
 {'type': 'code-split',
  'meta': '07 / 지속성',
  'title': 'InMemoryStore는 thread를 넘어 공유되는 장기 메모리를 담당합니다',
  'lead': 'LangGraph 1.x 권장 패턴은 context_schema와 Runtime[Context]를 함께 쓰는 것입니다',
  'points': [{'h': 'store', 'p': '사용자 선호 같은 장기 정보를 namespace별로 저장합니다.'},
             {'h': 'context', 'p': 'user_id를 state가 아니라 호출 컨텍스트로 주입합니다.'},
             {'h': 'Runtime', 'p': 'runtime.context와 runtime.store로 타입 안전하게 접근합니다.'}],
  'code': 'from dataclasses import dataclass\n'
          'from langgraph.runtime import Runtime\n'
          'from langgraph.store.memory import InMemoryStore\n'
          '\n'
          '@dataclass\n'
          'class Context:\n'
          '    user_id: str\n'
          '\n'
          'def remember(state: MessagesState, runtime: Runtime[Context]) -> dict:\n'
          '    namespace = (runtime.context.user_id, "memories")\n'
          '    runtime.store.put(namespace, "last", {"data": state["messages"][-1].content})\n'
          '    return {}\n'
          '\n'
          'store = InMemoryStore()\n'
          'builder = StateGraph(MessagesState, context_schema=Context)\n'
          'builder.add_node("remember", remember)\n'
          'graph = builder.compile(checkpointer=InMemorySaver(), store=store)',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'Runtime + Store'},
 {'type': 'dense',
  'meta': '07 / 지속성',
  'title': '긴 대화는 저장만큼 삭제와 압축 전략이 중요합니다',
  'lead': '메시지를 무한히 쌓으면 비용과 품질이 동시에 나빠집니다',
  'groups': [{'t': 'trim_messages는 모델 호출 직전에 컨텍스트를 줄입니다',
              'kids': [{'t': 'system 메시지는 유지하고 최근 메시지를 우선 남기는 전략을 자주 씁니다'}, {'t': '토큰 예산을 기준으로 오래된 메시지를 잘라냅니다'}]},
             {'t': 'RemoveMessage는 저장된 메시지를 명시적으로 제거합니다',
              'kids': [{'t': '실행 이력은 남기되 모델 입력에는 불필요한 과거를 줄일 수 있습니다'},
                       {'t': '요약 메모리와 함께 쓰면 장기 대화를 더 안정적으로 운영할 수 있습니다'}]}]},
 {'type': 'divider',
  'kicker': 'PART 08',
  'title': '스트리밍',
  'sub': 'values, updates, messages, custom, v2 StreamPart, nostream, Event Streaming v3를 정리합니다.',
  'lab': '03_langgraph/07_streaming.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 심화',
  'meta': '08 / 스트리밍',
  'title': 'stream_mode는 누구에게 어떤 실행 정보를 보여줄지 정하는 선택입니다',
  'lead': '사용자 UI와 운영 로그는 필요한 스트림 종류가 다릅니다',
  'cols': [{'t': 'mode', 'w': '24%'}, {'t': '보여주는 것', 'w': '42%'}, {'t': '대표 용도', 'accent': True}],
  'rows': [['values', '각 단계 이후 전체 상태', '디버깅과 상태 스냅샷'],
           ['updates', '노드별 변경분', '운영 로그와 진행 표시'],
           ['messages', 'LLM 토큰 스트림', '채팅 UI'],
           ['custom', '노드가 직접 내보낸 이벤트', '도메인별 진행률'],
           ['multiple', '여러 모드를 함께 반환', 'UI와 로그 동시 처리']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 심화',
  'meta': '08 / 스트리밍',
  'title': 'custom 스트리밍은 그래프 내부 진행률을 사용자 언어로 내보낼 때 사용합니다',
  'lead': '토큰만 보여주면 장기 작업의 실제 진행 상태를 알기 어렵습니다',
  'groups': [{'t': '사용 시점', 'kids': [{'t': '파일 처리, 검색, 분석처럼 중간 단계가 긴 작업입니다'}, {'t': '사용자에게 현재 단계와 남은 작업을 설명해야 합니다'}]},
             {'t': '설계 기준',
              'kids': [{'t': '노드 이름 대신 사용자에게 의미 있는 이벤트명을 씁니다'},
                       {'t': '성공 이벤트와 실패 이벤트를 구분합니다'},
                       {'t': '프런트엔드에서 표시할 최소 필드를 정합니다'}]}]},
 {'type': 'table',
  'meta': '08 / 스트리밍',
  'title': "stream_mode는 '무엇을 밖으로 보여줄지'의 선택입니다",
  'lead': '최종 답만 필요한지, 노드 진행률이 필요한지, 토큰이 필요한지에 따라 모드가 달라집니다',
  'cols': [{'t': '모드', 'w': '22%'}, {'t': '나오는 것', 'w': '32%'}, {'t': '대표 사용', 'accent': True}],
  'rows': [['values', '전체 상태 스냅샷', '상태 전체를 디버깅'],
           ['updates', '노드별 변경분', '실행 진행 로그'],
           ['messages', 'LLM 토큰과 메타데이터', '채팅 UI 토큰 출력'],
           ['custom', 'writer가 보낸 임의 이벤트', '진행률·중간 산출물 표시'],
           ['multi-mode', '여러 모드 튜플', 'UI와 로그를 동시에 구성']]},
 {'type': 'code-split',
  'meta': '08 / 스트리밍',
  'title': 'updates 스트림은 어느 노드가 어떤 상태를 바꿨는지 보여줍니다',
  'lead': '복잡한 그래프에서는 최종값보다 노드별 변경분이 디버깅에 더 유용합니다',
  'points': [{'h': 'stream', 'p': 'invoke와 같은 입력을 받지만 iterator를 반환합니다.'},
             {'h': 'updates', 'p': '각 청크는 노드 이름과 변경된 필드를 담습니다.'},
             {'h': 'UI', 'p': '노드 이름을 단계 표시로 보여줄 수 있습니다.'}],
  'code': 'for chunk in agent.stream(\n'
          '    {"messages": [{"role": "user", "content": "LangGraph를 설명해 주세요."}]},\n'
          '    stream_mode="updates",\n'
          '):\n'
          '    for node_name, update in chunk.items():\n'
          '        print(f"[{node_name}] {list(update.keys())}")',
  'file': '07_streaming.ipynb',
  'note': '노트북 기준'},
 {'type': 'dense',
  'meta': '08 / 스트리밍',
  'title': "version='v2'는 스트림 이벤트를 type·ns·data로 통일합니다",
  'lead': '서브그래프와 메시지 스트림이 섞여도 같은 구조로 분기할 수 있습니다',
  'groups': [{'t': 'StreamPart 구조',
              'kids': [{'t': "<span class='mono'>chunk['type']</span>. values, updates, messages, custom 같은 이벤트 종류입니다"},
                       {'t': "<span class='mono'>chunk['ns']</span>. 서브그래프 namespace가 있을 때 어느 그래프에서 온 이벤트인지 알려줍니다"},
                       {'t': "<span class='mono'>chunk['data']</span>. 실제 상태, 메시지, 커스텀 payload입니다"}]},
             {'t': 'nostream 태그는 백그라운드 모델 토큰을 숨깁니다',
              'kids': [{'t': '내부 분류기나 요약기 토큰이 사용자 채팅 UI에 섞이지 않게 합니다'},
                       {'t': 'metadata의 tags와 chunk_position으로 특정 모델의 마지막 토큰을 감지할 수 있습니다'}]}]},
 {'type': 'flow',
  'meta': '08 / 스트리밍',
  'title': '앱 스트림은 projection을 정해 사용자에게 필요한 상태만 보냅니다',
  'lead': 'Event Streaming v3 관점에서는 그래프 내부 상태 전체가 아니라 화면 상태를 설계합니다',
  'nodes': [{'h': 'GRAPH', 'p': '내부 상태', 'note': '모든 노드 업데이트가 발생합니다.'},
            {'h': 'PROJECT', 'p': '화면 모델', 'note': '사용자에게 보여줄 필드만 추립니다.', 'hl': True},
            {'h': 'EVENT', 'p': '프론트 전송', 'note': '토큰, 진행률, 결과 카드로 나눕니다.'},
            {'h': 'RENDER', 'p': 'UI 반영', 'note': '마지막 청크에서 커서를 정리합니다.'}],
  'sum': '좋은 스트리밍은 많은 데이터를 보내는 것이 아니라 <strong>사용자가 이해할 사건</strong>만 보내는 것입니다.'},
 {'type': 'divider',
  'kicker': 'PART 09',
  'title': 'Interrupt와 Time Travel',
  'sub': '사람 승인, 리뷰·편집, 도구 interrupt, 입력 검증, replay와 fork를 정리합니다.',
  'lab': '03_langgraph/08_interrupts_and_time_travel.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 심화',
  'meta': '09 / Interrupt',
  'title': 'interrupt 패턴은 승인·수정·입력·검증·도구 승인으로 나눠 볼 수 있습니다',
  'lead': '사람 개입은 중단 후 어떤 값을 받아 재개할지의 설계입니다. 새 API는 resume 값의 스키마도 함께 표현할 수 있습니다',
  'cols': [{'t': '패턴', 'w': '25%'}, {'t': 'resume 값', 'w': '32%'}, {'t': '대표 상황', 'accent': True}],
  'rows': [['Approval', 'True 또는 False', '삭제, 결제, 외부 전송 승인'],
           ['Review & Edit', '수정된 문자열 또는 객체', '보고서 초안 검토'],
           ['Input Collection', '사용자 입력 값', '누락 정보 보충'],
           ['Validation', '검증 결과와 수정 요청', '정책 준수 확인'],
           ['Tool Approval', '도구 호출 허용/거절', '위험 도구 실행 전 확인']]},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 심화',
  'meta': '09 / Interrupt',
  'title': 'Command(resume=...)은 중단된 그래프에 사람의 결정을 다시 넣습니다',
  'lead': 'interrupt가 값을 요구하면 Command로 값을 전달해 같은 실행을 이어갑니다',
  'points': [{'h': 'interrupt', 'p': '노드 안에서 실행을 멈추고 값을 요청합니다.'},
             {'h': 'Command', 'p': 'resume 값으로 중단 지점을 재개합니다.'},
             {'h': 'checkpointer', 'p': '중단 지점을 저장하기 위한 필수 전제입니다.'},
             {'h': 'response_schema',
              'p': "LangGraph 1.2.12부터 <span class='mono'>interrupt(value, response_schema=...)</span>로 재개 값의 형태를 명시할 "
                   '수 있습니다.'}],
  'code': 'from typing_extensions import TypedDict\n'
          'from langgraph.types import Command, interrupt\n'
          '\n'
          'class Approval(TypedDict):\n'
          '    approved: bool\n'
          '    reason: str\n'
          '\n'
          'def approval_node(state):\n'
          '    decision = interrupt(\n'
          '        {"question": "계속 진행할까요?"},\n'
          '        response_schema=Approval,\n'
          '    )\n'
          '    return {"approved": decision["approved"]}\n'
          '\n'
          'result = graph.invoke(Command(resume={"approved": True, "reason": "ok"}), config=config)',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'interrupt resume'},
 {'type': 'figure',
  'meta': '09 / 인터럽트',
  'title': 'Human-in-the-loop는 그래프 실행을 승인 가능한 지점에서 멈춥니다',
  'lead': 'interrupt는 예외가 아니라 체크포인트와 함께 쓰는 정상 제어 흐름입니다',
  'img_src': 'assets/diagrams/hitl_flow.png',
  'cap': 'HITL flow',
  'points': [{'h': 'interrupt', 'p': '사람에게 보여줄 값과 질문을 반환합니다.'},
             {'h': 'checkpoint', 'p': '중단 직전 상태가 저장되어 있어야 합니다.'},
             {'h': 'Command(resume)', 'p': '사람의 답을 같은 thread_id로 전달해 재개합니다.'}]},
 {'type': 'table',
  'meta': '09 / 인터럽트',
  'title': '표준 interrupt 패턴은 resume 값의 모양으로 구분됩니다',
  'lead': '승인·편집·도구 승인·입력 검증·다중 interrupt를 모두 같은 재개 원리로 다룹니다',
  'cols': [{'t': '패턴', 'w': '28%'}, {'t': 'resume 값', 'w': '32%'}, {'t': '사용 예', 'accent': True}],
  'rows': [['Approval', 'bool 또는 response_schema에 맞는 객체', '메일 발송 전 승인'],
           ['Review & Edit', '수정된 문자열', '초안 문장 편집'],
           ['Tool Interrupt', 'action dict', '도구 인자 일부 수정 후 승인'],
           ['Input Validation', '스키마 검증을 통과한 새 입력', '나이·금액 같은 값 재입력'],
           ['Multiple Interrupts', 'interrupt_id별 응답', '동시에 여러 승인 처리']]},
 {'type': 'code-split',
  'meta': '09 / 인터럽트',
  'title': '타임 트래블은 replay와 fork를 구분해야 합니다',
  'lead': 'replay는 과거 지점부터 재실행하고, fork는 과거 상태를 수정한 새 분기를 만듭니다',
  'points': [{'h': 'Replay', 'p': '과거 checkpoint config로 invoke(None, config)를 호출합니다.'},
             {'h': 'Fork', 'p': 'update_state로 값을 바꾸고 새 checkpoint를 만듭니다.'},
             {'h': 'as_node', 'p': '어느 노드가 상태를 쓴 것처럼 기록할지 지정합니다.'}],
  'code': 'history = list(graph.get_state_history(config))\n'
          'before_write = next(s for s in history if s.next == ("write_joke",))\n'
          '\n'
          '# Replay: 저장된 topic은 재사용하고 write_joke만 다시 실행\n'
          'replay = graph.invoke(None, before_write.config)\n'
          '\n'
          '# Fork: 과거 상태를 고쳐 새 분기 생성\n'
          'fork_config = graph.update_state(\n'
          '    before_write.config,\n'
          '    values={"topic": "dogs"},\n'
          '    as_node="generate_topic",\n'
          ')\n'
          'forked = graph.invoke(None, fork_config)',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'Replay vs Fork'},
 {'type': 'dense',
  'meta': '09 / 인터럽트',
  'title': 'interrupt는 response_schema와 함께 UI 계약이 됩니다',
  'lead': '완료 여부만 보는 대신, interrupt가 요구하는 입력 형태를 UI와 재개 코드가 공유하도록 설계합니다',
  'groups': [{'t': "완료되지 않았으면 <span class='mono'>out.interrupts</span>에 질문이 들어 있습니다",
              'kids': [{'t': "UI는 <span class='mono'>value</span>와 <span class='mono'>response_schema</span>를 승인 폼이나 "
                             '편집 폼으로 렌더링합니다'},
                       {'t': '재개할 때는 같은 config와 Command(resume=...)을 사용합니다'}]},
             {'t': "완료되었으면 <span class='mono'>out.value</span>가 최종 상태입니다",
              'kids': [{'t': 'v1 호환 dict 접근은 남아 있지만 v2 스타일로 옮기는 편이 명확합니다'},
                       {'t': '서브그래프 타임트래블도 v2에서 더 일관된 분기를 제공합니다'}]}]},
 {'type': 'divider',
  'kicker': 'PART 10',
  'title': '서브그래프',
  'sub': '상태 스키마가 다른 서브그래프 래핑, 직접 노드 추가, 서브그래프 스트리밍과 checkpointer 모드를 다룹니다.',
  'lab': '03_langgraph/09_subgraphs.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 심화',
  'meta': '10 / 서브그래프',
  'title': '서브그래프 연결 방식은 상태 스키마가 같은지에 따라 달라집니다',
  'lead': '큰 그래프를 나눌 때는 코드 재사용보다 상태 경계를 먼저 봐야 합니다',
  'cols': [{'t': '방식', 'w': '28%'}, {'t': '조건', 'w': '36%'}, {'t': '주의점', 'accent': True}],
  'rows': [['직접 추가', '부모와 자식 상태 키가 맞습니다', '공유 키의 reducer 충돌을 확인합니다'],
           ['Wrapper node', '상태 스키마가 다릅니다', '입력 변환과 출력 매핑을 명시합니다'],
           ['LLM subgraph', '전문 흐름을 독립 그래프로 둡니다', '프롬프트와 메시지 경계를 분리합니다'],
           ['stream_subgraphs', '부모·자식 실행을 함께 관찰합니다', 'UI 표시 레벨을 정해야 합니다']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 심화',
  'meta': '10 / 서브그래프',
  'title': '서브그래프는 파일 분리보다 실행 경계 설계가 중요합니다',
  'lead': '서브그래프를 만들면 독립성이 생기지만 상태 변환과 디버깅 복잡도도 늘어납니다',
  'groups': [{'t': '분리하면 좋은 경우',
              'kids': [{'t': '팀이나 도메인이 다른 실행 흐름입니다'}, {'t': '하위 그래프만 따로 테스트하고 싶습니다'}, {'t': '반복 재사용되는 전문 워크플로입니다'}]},
             {'t': '분리하지 않는 편이 나은 경우',
              'kids': [{'t': '상태 키 몇 개만 추가하면 되는 단순 단계입니다'}, {'t': '부모와 자식이 거의 모든 상태를 공유합니다'}]}]},
 {'type': 'layers',
  'meta': '10 / 서브그래프',
  'title': '서브그래프는 그래프 안에 들어가는 독립 그래프입니다',
  'lead': '작은 그래프를 따로 컴파일해 부모 그래프 노드처럼 사용할 수 있습니다',
  'layers': [{'name': 'Call inside node',
              'tag': '상태가 다를 때',
              'desc': '부모 상태를 서브그래프 입력으로 변환하고 결과를 다시 부모 상태로 합칩니다.',
              'mono': 'subgraph.invoke(...)'},
             {'name': 'Add as node',
              'tag': '상태가 맞을 때',
              'desc': '공유 키가 있는 그래프는 add_node(name, subgraph)로 직접 추가합니다.',
              'mono': "builder.add_node('sub', subgraph)"},
             {'name': 'Namespace',
              'tag': '관측과 저장',
              'desc': '서브그래프 스트림과 체크포인트는 namespace로 어느 내부 그래프인지 구분합니다.',
              'mono': 'subgraphs=True'}]},
 {'type': 'code-split',
  'meta': '10 / 서브그래프',
  'title': '상태 스키마가 다르면 래퍼 노드가 부모와 자식 상태를 변환합니다',
  'lead': '서브그래프 내부 구조는 숨기되, 부모 그래프 입출력 계약은 명확히 둡니다',
  'points': [{'h': 'subgraph', 'p': '분석 전용 그래프를 별도 컴파일합니다.'},
             {'h': 'wrapper', 'p': '부모 state를 서브그래프 입력으로 바꿉니다.'},
             {'h': 'merge', 'p': '서브그래프 결과만 부모 state에 되돌립니다.'}],
  'code': 'def run_analysis(state: PipelineState) -> dict:\n'
          '    result = analysis_graph.invoke({"text": state["document"]})\n'
          '    return {"analysis": result["summary"]}\n'
          '\n'
          'parent_builder = StateGraph(PipelineState)\n'
          'parent_builder.add_node("analysis", run_analysis)\n'
          'parent_builder.add_edge(START, "analysis")\n'
          'parent_builder.add_edge("analysis", END)\n'
          'parent = parent_builder.compile()',
  'file': '09_subgraphs.ipynb',
  'note': '노트북 기준'},
 {'type': 'table',
  'meta': '10 / 서브그래프',
  'title': '서브그래프 checkpointer는 세 가지 모드로 생각합니다',
  'lead': '메모리와 interrupt 가능 여부가 모드마다 달라집니다',
  'cols': [{'t': '모드', 'w': '28%'}, {'t': '설정', 'w': '28%'}, {'t': '주의점', 'accent': True}],
  'rows': [['Per-Invocation', 'checkpointer 미지정', '호출마다 fresh, 부모 checkpointer 상속'],
           ['Per-Thread', 'checkpointer=True', 'thread별 누적 메모리, 병렬 tool 호출은 피함'],
           ['Stateless', 'checkpointer=False', 'checkpoint가 없어 interrupt 불가'],
           ['Namespace Isolation', '고유 노드 이름으로 감싸기', '여러 per-thread subagent 상태 충돌 방지']]},
 {'type': 'code-split',
  'meta': '10 / 서브그래프',
  'title': '여러 per-thread 서브그래프는 고유 노드 이름으로 namespace를 격리합니다',
  'lead': 'agent 이름과 StateGraph 노드 이름을 맞추면 checkpoint prefix가 안정적으로 나뉩니다',
  'points': [{'h': 'name', 'p': 'create_agent와 add_node에 같은 고유 이름을 씁니다.'},
             {'h': 'wrap', 'p': '각 서브에이전트를 작은 StateGraph로 감쌉니다.'},
             {'h': 'isolate', 'p': 'fruit_agent와 veggie_agent의 state가 섞이지 않습니다.'}],
  'code': 'from langgraph.graph import MessagesState, StateGraph\n'
          'from langchain.agents import create_agent\n'
          '\n'
          'def create_sub_agent(model: str, *, name: str, **kwargs):\n'
          '    agent = create_agent(model=model, name=name, **kwargs)\n'
          '    return (\n'
          '        StateGraph(MessagesState)\n'
          '        .add_node(name, agent)\n'
          '        .add_edge("__start__", name)\n'
          '        .compile()\n'
          '    )\n'
          '\n'
          'fruit_agent = create_sub_agent(\n'
          '    "gpt-5.4-mini",\n'
          '    name="fruit_agent",\n'
          '    tools=[fruit_info],\n'
          '    checkpointer=True,\n'
          ')',
  'file': '09_subgraphs.ipynb',
  'note': 'Namespace'},
 {'type': 'divider',
  'kicker': 'PART 11',
  'title': '프로덕션 운영',
  'sub': 'langgraph.json, Studio, Agent Chat UI, GenericFakeChatModel, LangSmith tracing을 정리합니다.',
  'lab': '03_langgraph/10_production.ipynb'},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 심화',
  'meta': '11 / 프로덕션',
  'title': 'langgraph.json은 그래프를 서버와 Studio가 찾을 수 있게 하는 배포 계약입니다',
  'lead': '노트북 코드가 앱이 되려면 그래프 경로, 의존성, 환경 변수가 명시돼야 합니다',
  'points': [{'h': 'graphs', 'p': '그래프 이름과 Python 객체 경로를 연결합니다.'},
             {'h': 'dependencies', 'p': '서버가 설치할 패키지나 로컬 경로입니다.'},
             {'h': 'env', 'p': '실행에 필요한 환경 변수 파일입니다.'}],
  'code': '{\n  "dependencies": ["."],\n  "graphs": {\n    "agent": "./agent.py:graph"\n  },\n  "env": ".env"\n}',
  'file': '10_production.ipynb',
  'note': 'langgraph.json'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 심화',
  'meta': '11 / 프로덕션',
  'title': '프로덕션 테스트는 결정론 테스트와 LLM 테스트를 분리해야 합니다',
  'lead': '그래프 구조가 맞는지와 모델 답변이 좋은지는 서로 다른 검증입니다',
  'cols': [{'t': '테스트', 'w': '28%'}, {'t': '확인 대상', 'w': '38%'}, {'t': '도구', 'accent': True}],
  'rows': [['결정론 테스트', '상태 전이, 라우팅, reducer', '일반 unit test'],
           ['LLM 에이전트 테스트', '도구 호출 순서와 최종 메시지', 'GenericFakeChatModel'],
           ['회귀 테스트', '이전 질문 세트의 품질 유지', 'dataset/eval'],
           ['관측성', '실패 지점과 비용 추적', 'trace/Studio']]},
 {'type': 'table',
  'meta': '11 / 프로덕션',
  'title': 'LangGraph 앱 구조는 그래프 객체를 서버와 Studio가 찾을 수 있게 만듭니다',
  'lead': '코드에서 graph를 export하고 langgraph.json이 그 위치를 가리킵니다',
  'cols': [{'t': '항목', 'w': '26%'}, {'t': '역할', 'w': '34%'}, {'t': '확인 기준', 'accent': True}],
  'rows': [['langgraph.json', 'dependencies, graphs, env 선언', '서버가 graph를 import할 수 있음'],
           ['LangGraph Studio', '로컬 그래프 시각 디버깅', '상태와 노드 실행을 눈으로 확인'],
           ['Agent Chat UI', '채팅형 테스트 표면', 'streaming과 thread 상태를 빠르게 점검'],
           ['테스트', '결정론적 노드·fake model', 'LLM 호출 없이 핵심 경로 검증'],
           ['관측성', 'LangSmith tracing', 'run, tag, metadata, anonymizer 확인']]},
 {'type': 'code-split',
  'meta': '11 / 프로덕션',
  'title': 'langgraph.json은 그래프 엔트리포인트를 선언하는 배포 계약입니다',
  'lead': '로컬 개발 서버와 Studio는 이 파일을 기준으로 그래프를 로드합니다',
  'points': [{'h': 'dependencies', 'p': '앱 실행에 필요한 패키지 또는 현재 프로젝트를 지정합니다.'},
             {'h': 'graphs', 'p': '그래프 이름과 Python import 경로를 매핑합니다.'},
             {'h': 'env', 'p': '환경변수 파일을 지정합니다.'}],
  'code': 'import json\n'
          '\n'
          'config = {\n'
          '    "dependencies": ["."],\n'
          '    "graphs": {"agent": "./agent.py:graph"},\n'
          '    "env": ".env",\n'
          '}\n'
          'print(json.dumps(config, indent=2))\n'
          'print("pip install \'langgraph-cli[inmem]\'")\n'
          'print("langgraph dev")',
  'file': '10_production.ipynb',
  'note': 'langgraph.json'},
 {'type': 'code-split',
  'meta': '11 / 프로덕션',
  'title': 'GenericFakeChatModel은 LLM 테스트를 결정론적으로 만듭니다',
  'lead': '모델 답을 고정하면 그래프 라우팅과 상태 업데이트를 자동 테스트할 수 있습니다',
  'points': [{'h': 'fake model', 'p': '예상 메시지 iterator를 모델처럼 씁니다.'},
             {'h': 'assert', 'p': '결과 메시지와 state를 검증합니다.'},
             {'h': '비용 없음', 'p': '실제 API 호출 없이 CI에서 반복 실행할 수 있습니다.'}],
  'code': 'from langchain_core.language_models import GenericFakeChatModel\n'
          'from langchain.messages import AIMessage, HumanMessage\n'
          '\n'
          'fake_model = GenericFakeChatModel(\n'
          '    messages=iter([AIMessage(content="The answer is 42.")])\n'
          ')\n'
          '\n'
          'def chatbot(state: MessagesState) -> dict:\n'
          '    return {"messages": [fake_model.invoke(state["messages"])]}\n'
          '\n'
          'result = test_graph.invoke({"messages": [HumanMessage(content="테스트")]})\n'
          'assert "42" in result["messages"][-1].content',
  'file': '10_production.ipynb',
  'note': '테스트'},
 {'type': 'dense',
  'meta': '11 / 프로덕션',
  'title': '관측성은 trace를 남기는 것보다 민감정보를 남기지 않는 설계가 먼저입니다',
  'lead': 'LangSmith tracing은 강력하지만 anonymizer와 metadata 정책을 함께 정해야 합니다',
  'groups': [{'t': 'Selective tracing',
              'kids': [{'t': 'tracing_context로 특정 호출만 켜고 끌 수 있습니다'},
                       {'t': 'project, tag, metadata를 동적으로 부여해 실험과 운영을 분리합니다'}]},
             {'t': 'Data privacy',
              'kids': [{'t': 'LangChainTracer와 Client anonymizer로 로그 직전 마스킹을 적용합니다'},
                       {'t': '사용자 입력 전체를 남길지, 추출 필드만 남길지 팀 정책을 먼저 정합니다'}]}]},
 {'type': 'divider',
  'kicker': 'PART 12',
  'title': '로컬 서버',
  'sub': 'LangGraph CLI, langgraph dev, Studio, Python SDK, REST API 호출 흐름을 정리합니다.',
  'lab': '03_langgraph/11_local_server.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 심화',
  'meta': '12 / 로컬 서버',
  'title': '로컬 서버는 같은 그래프를 Studio, SDK, REST에서 호출하게 합니다',
  'lead': '강의용 노트북을 서비스 표면으로 바꾸는 중간 단계입니다',
  'cols': [{'t': '표면', 'w': '24%'}, {'t': '용도', 'w': '42%'}, {'t': '확인할 것', 'accent': True}],
  'rows': [['LangGraph CLI', '개발 서버 실행', 'langgraph dev'],
           ['Studio', '그래프 시각 디버깅', '상태와 노드 이동 확인'],
           ['Python SDK', '비동기 클라이언트 호출', 'threads와 runs'],
           ['REST API', '외부 앱 연동', 'stream 응답 형식']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 심화',
  'meta': '12 / 로컬 서버',
  'title': 'SDK 호출은 thread 생성과 run stream을 분리해서 이해해야 합니다',
  'lead': '서버 모드에서는 그래프 실행이 로컬 함수 호출이 아니라 원격 run으로 관리됩니다',
  'groups': [{'t': '기본 순서',
              'kids': [{'t': 'client를 생성합니다'},
                       {'t': 'thread를 만듭니다'},
                       {'t': 'assistant 또는 graph id로 run을 시작합니다'},
                       {'t': 'stream 이벤트를 순서대로 처리합니다'}]},
             {'t': '운영 관점', 'kids': [{'t': 'thread는 대화와 실행 상태의 단위입니다'}, {'t': 'run id는 개별 실행 추적 단위입니다'}]}]},
 {'type': 'table',
  'meta': '12 / 로컬 서버',
  'title': '로컬 서버는 노트북 그래프를 서비스 호출 표면으로 바꿉니다',
  'lead': '개발 중에는 in-memory 서버로 빠르게 돌리고, 배포 전에는 동일 API로 검증합니다',
  'cols': [{'t': '단계', 'w': '26%'}, {'t': '명령·코드', 'w': '34%'}, {'t': '확인', 'accent': True}],
  'rows': [['CLI 설치', "pip install 'langgraph-cli[inmem]'", 'langgraph 명령 사용 가능'],
           ['프로젝트 생성', 'agent.py + langgraph.json', '그래프 import 경로 확인'],
           ['개발 서버', 'langgraph dev', 'localhost:2024 실행'],
           ['Studio', 'smith.langchain.com/studio', 'baseUrl로 로컬 서버 연결'],
           ['SDK/REST', 'get_client, get_sync_client, curl', 'runs.stream 응답 확인']]},
 {'type': 'code-split',
  'meta': '12 / 로컬 서버',
  'title': 'Python SDK는 서버 실행 중인 그래프를 비동기 스트림으로 호출합니다',
  'lead': '노트북의 graph.invoke 감각을 서버 API로 옮기는 단계입니다',
  'points': [{'h': 'get_client', 'p': '로컬 서버 URL을 지정합니다.'},
             {'h': 'runs.stream', 'p': '그래프 이름과 input을 넘기고 이벤트를 순회합니다.'},
             {'h': 'event/data', 'p': '프론트엔드와 백엔드는 같은 event payload를 기준으로 연결됩니다.'}],
  'code': 'from langgraph_sdk import get_client\n'
          'import asyncio\n'
          '\n'
          'client = get_client(url="http://localhost:2024")\n'
          '\n'
          'async def main():\n'
          '    async for chunk in client.runs.stream(\n'
          '        None,\n'
          '        "agent",\n'
          '        input={"messages": [{"role": "human", "content": "What is LangGraph?"}]},\n'
          '    ):\n'
          '        print(chunk.event, chunk.data)\n'
          '\n'
          'asyncio.run(main())',
  'file': '11_local_server.ipynb',
  'note': 'SDK'},
 {'type': 'code-split',
  'meta': '12 / 로컬 서버',
  'title': '동기 SDK와 REST는 같은 실행을 다른 클라이언트 표면으로 부릅니다',
  'lead': '서버를 붙인 뒤에는 SDK, REST, UI가 같은 graph_id와 thread를 공유합니다',
  'points': [{'h': 'sync client', 'p': '스크립트와 테스트에서 간단히 사용합니다.'},
             {'h': 'stream_mode', 'p': 'messages-tuple 같은 UI 친화 모드를 지정합니다.'},
             {'h': 'REST', 'p': '언어와 관계없이 배포된 그래프를 호출할 수 있습니다.'}],
  'code': 'from langgraph_sdk import get_sync_client\n'
          '\n'
          'client = get_sync_client(url="http://localhost:2024")\n'
          'for chunk in client.runs.stream(\n'
          '    None,\n'
          '    "agent",\n'
          '    input={"messages": [{"role": "human", "content": "What is LangGraph?"}]},\n'
          '    stream_mode="messages-tuple",\n'
          '):\n'
          '    print(chunk.event, chunk.data)',
  'file': '11_local_server.ipynb',
  'note': 'Sync client'},
 {'type': 'dense',
  'meta': '12 / 로컬 서버',
  'title': '배포 준비는 서버가 켜지는지보다 호출 계약이 안정적인지를 봅니다',
  'lead': '입력 스키마, graph 이름, env, thread 정책이 흔들리면 UI와 운영 자동화가 함께 깨집니다',
  'groups': [{'t': '배포 전 체크',
              'kids': [{'t': 'langgraph.json의 graph 경로가 실제 객체를 import하는지 확인합니다'},
                       {'t': '필수 환경변수와 선택 환경변수를 분리합니다'},
                       {'t': 'SDK와 REST 모두 같은 샘플 입력으로 성공하는지 확인합니다'}]},
             {'t': '운영 연결',
              'kids': [{'t': 'Studio는 디버깅용, SDK/REST는 앱 연동용으로 역할을 나눕니다'},
                       {'t': 'thread_id와 user context 정책을 문서화해야 상태 격리가 유지됩니다'}]}]},
 {'type': 'divider',
  'kicker': 'PART 13',
  'title': '내구성 실행',
  'sub': '@task, 체크포인터, fault tolerance, graceful shutdown, DeltaChannel을 정리합니다.',
  'lab': '03_langgraph/12_durable_execution.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 심화',
  'meta': '13 / 내구성 실행',
  'title': '내구성 실행은 실패 복구를 위해 side effect와 checkpoint를 분리합니다',
  'lead': '긴 작업은 처음부터 재실행해도 안전한 코드 구조가 필요합니다',
  'cols': [{'t': '요구사항', 'w': '28%'}, {'t': '의미', 'w': '38%'}, {'t': '설계 방법', 'accent': True}],
  'rows': [['Idempotency', '같은 작업을 다시 해도 결과가 망가지지 않습니다', '외부 쓰기 작업은 고유 id로 보호'],
           ['Checkpoint', '어디까지 끝났는지 저장합니다', 'checkpointer와 thread_id 사용'],
           ['Task boundary', '재시도 가능한 단위를 분리합니다', '@task로 외부 작업 분리'],
           ['Resume', '실패 지점 이후부터 이어갑니다', 'durability mode와 상태 확인']]},
 {'type': 'code-split',
  'course': 'AI 에이전트 개발 심화',
  'meta': '13 / 내구성 실행',
  'title': '@task로 외부 작업을 감싸면 재시도와 재개 경계가 선명해집니다',
  'lead': 'entrypoint 안에 모든 작업을 몰아넣으면 실패 후 어디부터 다시 시작할지 불분명합니다',
  'points': [{'h': '@task', 'p': '실패하거나 오래 걸리는 외부 작업 단위입니다.'},
             {'h': 'entrypoint', 'p': '작업 순서를 조립하는 진입점입니다.'},
             {'h': 'checkpointer', 'p': '완료된 task 결과를 저장합니다.'}],
  'code': 'from langgraph.func import entrypoint, task\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '@task\n'
          'def call_external_api(item: str) -> str:\n'
          '    return f"처리 완료: {item}"\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def durable_flow(items: list[str]) -> list[str]:\n'
          '    return [call_external_api(x).result() for x in items]',
  'file': '12_durable_execution.ipynb',
  'note': 'durable task'},
 {'type': 'table',
  'meta': '13 / 내구성',
  'title': 'Graph API와 Functional API는 재개 시작점이 다릅니다',
  'lead': '어디서부터 다시 실행되는지 알아야 중복 결제나 중복 파일 쓰기를 피할 수 있습니다',
  'cols': [{'t': '표면', 'w': '24%'}, {'t': '재개 시작점', 'w': '32%'}, {'t': '주의', 'accent': True}],
  'rows': [['StateGraph', '중단된 노드의 시작', '노드 내부 side effect는 idempotent해야 함'],
           ['Functional API', 'entrypoint에서 시작', '@task 결과는 checkpoint에서 복원'],
           ['@task', '작업 결과 저장', '비결정적 IO와 LLM 호출을 task 안에 둠'],
           ['checkpointer', '단계별 상태 저장', 'thread_id가 재개의 기준']]},
 {'type': 'code-split',
  'meta': '13 / 내구성',
  'title': 'Functional API에서는 LLM 호출과 외부 IO를 @task로 감싸야 재개가 안정적입니다',
  'lead': 'entrypoint가 다시 시작되어도 이미 끝난 task 결과는 저장값에서 복원됩니다',
  'points': [{'h': 'generate_draft', 'p': '비싼 작업 또는 LLM 호출을 task로 둡니다.'},
             {'h': 'checkpointer', 'p': 'entrypoint에 연결합니다.'},
             {'h': 'thread_id', 'p': '장애 후 같은 실행으로 재개합니다.'}],
  'code': 'from langgraph.func import entrypoint, task\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '@task\n'
          'def generate_draft(topic: str) -> str:\n'
          '    return f"Draft about {topic}"\n'
          '\n'
          '@task\n'
          'def review_draft(draft: str) -> str:\n'
          '    return f"Reviewed: {draft}"\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def write_document(topic: str) -> str:\n'
          '    draft = generate_draft(topic).result()\n'
          '    return review_draft(draft).result()',
  'file': '12_durable_execution.ipynb',
  'note': '@task'},
 {'type': 'dense',
  'meta': '13 / 내구성',
  'title': 'LangGraph 1.2 fault tolerance는 timeout, retry, error handler를 더 명시적으로 다룹니다',
  'lead': '장기 작업은 실패를 숨기는 것이 아니라 보정 가능한 상태로 남기는 설계가 필요합니다',
  'groups': [{'t': 'TimeoutPolicy',
              'kids': [{'t': 'idle_timeout으로 노드가 멈춰 있는 시간을 제한합니다'},
                       {'t': 'heartbeat를 쓰면 장기 작업 중에도 살아 있음을 런타임에 알릴 수 있습니다'}]},
             {'t': 'Graceful shutdown',
              'kids': [{'t': 'RunControl로 drain을 요청하고 GraphDrained를 받아 checkpoint 기반 재개를 준비합니다'},
                       {'t': 'runtime.drain_requested를 보고 노드 내부에서 안전하게 중단할 수 있습니다'}]},
             {'t': 'DeltaChannel', 'kids': [{'t': 'append-heavy 메시지나 로그에서 checkpoint 저장량을 줄이는 beta 채널입니다'}]}]},
 {'type': 'flow',
  'meta': '13 / 내구성',
  'title': '장애 복구 시나리오는 체크포인트 확인에서 시작합니다',
  'lead': '실패 후 처음 할 일은 재시작이 아니라 어떤 노드까지 완료됐는지 확인하는 것입니다',
  'nodes': [{'h': 'FAIL', 'p': '노드 실패', 'note': '오류가 발생하고 checkpoint가 남습니다.'},
            {'h': 'INSPECT', 'p': 'get_state', 'note': '마지막 완료 상태와 next 노드를 확인합니다.', 'hl': True},
            {'h': 'FIX', 'p': 'update_state', 'note': '필요하면 사람이나 운영 도구가 상태를 보정합니다.'},
            {'h': 'RESUME', 'p': 'invoke(None)', 'note': '같은 config로 다음 지점부터 이어갑니다.'}],
  'sum': '내구성 실행은 자동 재시도만이 아니라 <strong>상태를 보고 고친 뒤 재개</strong>하는 운영 절차입니다.'},
 {'type': 'divider',
  'kicker': 'PART 14',
  'title': 'API 선택과 Pregel',
  'sub': 'Graph API, Functional API, 두 API 결합, Pregel 채널과 슈퍼스텝 실행 모델을 정리합니다.',
  'lab': '03_langgraph/13_api_guide_and_pregel.ipynb'},
 {'type': 'table',
  'course': 'AI 에이전트 개발 심화',
  'meta': '14 / API 선택과 Pregel',
  'title': 'Graph API와 Functional API 선택은 팀이 읽을 실행 표현을 기준으로 합니다',
  'lead': '둘 중 하나만 맞는 것이 아니라 운영자가 이해할 표현을 고르는 문제입니다',
  'cols': [{'t': '기준', 'w': '24%'}, {'t': 'Graph API', 'w': '36%'}, {'t': 'Functional API', 'accent': True}],
  'rows': [['흐름 가시성', '노드와 엣지가 문서처럼 보입니다', '코드 호출 흐름이 그대로 보입니다'],
           ['복잡한 분기', '조건부 엣지와 Send가 명시적입니다', '일반 Python 제어문으로 표현합니다'],
           ['팀 협업', '다이어그램과 리뷰에 유리합니다', '개발자가 빠르게 읽기 쉽습니다'],
           ['운영 기능', '체크포인트·스트리밍·interrupt 사용', '동일하게 사용 가능'],
           ['Tracing', 'add_node(trace_policy=...)로 노드별 추적 payload를 조정합니다', '미들웨어 trace_policy와 같은 운영 기준으로 봅니다']]},
 {'type': 'dense',
  'course': 'AI 에이전트 개발 심화',
  'meta': '14 / API 선택과 Pregel',
  'title': 'Pregel은 노드가 superstep 단위로 메시지를 주고받는 내부 실행 모델입니다',
  'lead': 'LangGraph를 깊게 디버깅할 때는 그래프가 한 번에 전부 실행되는 것이 아니라 단계별로 동기화된다고 이해해야 합니다',
  'groups': [{'t': '핵심 관점',
              'kids': [{'t': '각 superstep에서 활성 노드가 실행됩니다'},
                       {'t': '노드는 채널에 값을 쓰고 다음 superstep에서 읽힙니다'},
                       {'t': '더 이상 활성 노드가 없으면 실행이 끝납니다'}]},
             {'t': '학습 효과',
              'kids': [{'t': 'reducer와 channel의 의미가 선명해집니다'}, {'t': '병렬 fan-out/fan-in의 실행 순서를 설명할 수 있습니다'}]}]},
 {'type': 'table',
  'meta': '14 / API 가이드',
  'title': 'Graph API와 Functional API 선택은 팀의 디버깅 표면을 고르는 문제입니다',
  'lead': '기능 차이보다 복잡성이 어디에 보이는지가 선택 기준입니다',
  'cols': [{'t': '기준', 'w': '26%'}, {'t': 'Graph API', 'w': '32%'}, {'t': 'Functional API', 'accent': True}],
  'rows': [['복잡한 분기', '노드와 엣지로 드러남', '함수 내부 if/while로 숨어듦'],
           ['간단한 파이프라인', '장황할 수 있음', '읽기 쉽고 짧음'],
           ['시각화', 'Studio에서 구조가 잘 보임', 'task 단위 흐름 중심'],
           ['팀 협업', '노드 소유권 분리 쉬움', '함수 단위로 빠르게 작성'],
           ['내구성', 'compile(checkpointer=...)', '@entrypoint(checkpointer=...)']]},
 {'type': 'code-split',
  'meta': '14 / API 가이드',
  'title': '두 API는 한 앱 안에서 역할을 나눠 함께 쓸 수 있습니다',
  'lead': '복잡한 조정은 Graph API, 단순 데이터 처리 worker는 Functional API로 분리할 수 있습니다',
  'points': [{'h': 'Graph API', 'p': '상위 coordinator와 라우팅을 담당합니다.'},
             {'h': 'Functional API', 'p': '반복 가능한 worker 파이프라인을 담당합니다.'},
             {'h': '계약', 'p': '서로 넘기는 입력과 출력 스키마만 고정합니다.'}],
  'code': '@task\n'
          'def summarize(section: str) -> str:\n'
          '    return f"요약: {section}"\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def summarize_worker(section: str) -> str:\n'
          '    return summarize(section).result()\n'
          '\n'
          'def worker_node(state: dict) -> dict:\n'
          '    result = summarize_worker.invoke(state["section"], state["config"])\n'
          '    return {"summary": result}\n'
          '\n'
          'coordinator = StateGraph(CoordinatorState)\n'
          'coordinator.add_node("worker", worker_node)',
  'file': '13_api_guide_and_pregel.ipynb',
  'note': 'API 결합'},
 {'type': 'table',
  'meta': '14 / API 가이드',
  'title': 'Pregel은 노드가 채널을 읽고 쓰는 슈퍼스텝 실행 모델입니다',
  'lead': 'StateGraph를 쓰면 직접 Pregel을 다루지 않아도 내부 모델을 이해할 수 있습니다',
  'cols': [{'t': '개념', 'w': '26%'}, {'t': '의미', 'w': '34%'}, {'t': '예시', 'accent': True}],
  'rows': [['NodeBuilder', '채널 구독과 쓰기 선언', "subscribe_only('a').write_to('b')"],
           ['Channel', '값 전달과 누적 방식', 'EphemeralValue, LastValue, Topic'],
           ['Superstep', '같은 단계의 노드가 병렬 실행', '업데이트는 다음 step에서 관찰'],
           ['BinaryOperatorAggregate', '리듀서 기반 누적', 'StateGraph의 Annotated 리듀서와 연결'],
           ['DeltaChannel', 'delta checkpoint 최적화', '메시지·로그 누적량 절감']]},
 {'type': 'divider',
  'kicker': 'REFERENCE',
  'title': '개념 근거와 실행 모델',
  'sub': 'LangGraph 개념 설명은 Pregel 논문, LangGraph 공식 문서, ReAct 논문을 기준으로 보강합니다.'},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Reference / LangGraph',
  'title': 'LangGraph의 superstep 관점은 Pregel의 반복 실행 모델로 설명할 수 있습니다',
  'lead': 'Pregel은 그래프 계산을 superstep의 반복으로 설명합니다. LangGraph의 Pregel API와 노드 실행 이해에 유용한 배경입니다.',
  'img_src': 'assets/diagrams/svg_langgraph_superstep.svg',
  'cap': 'Pregel-style superstep model',
  'points': [{'h': 'Superstep', 'p': '활성 노드가 실행되고 값을 채널에 씁니다.'},
             {'h': 'Message/Channel', 'p': '이번 단계의 출력은 다음 단계의 입력이 됩니다.'},
             {'h': 'Halt', 'p': '더 실행할 노드가 없으면 그래프가 종료됩니다.'}]},
 {'type': 'figure',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Reference / LangGraph',
  'title': 'Persistence와 time travel은 checkpoint를 기준으로 실행을 조회·수정·재개합니다',
  'lead': 'LangGraph 공식 문서는 checkpointer를 thread-scoped short-term memory, Store를 cross-thread long-term memory로 '
          '구분합니다.',
  'img_src': 'assets/diagrams/svg_langgraph_checkpoint.svg',
  'cap': 'checkpoint / time travel / resume',
  'points': [{'h': 'Checkpoint', 'p': '각 실행 단계의 상태 스냅샷입니다.'},
             {'h': 'Interrupt', 'p': '사람 입력이 필요한 지점에서 실행을 멈춥니다.'},
             {'h': 'Replay', 'p': '이전 상태를 조회하거나 수정해 다른 경로를 실험합니다.'}]},
 {'type': 'table',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Reference / LangGraph',
  'title': 'LangGraph 개념 보강 출처는 논문과 공식 문서를 기준으로 삼습니다',
  'lead': '덱의 개념 설명은 노트북 코드와 아래 신뢰 출처를 함께 반영합니다.',
  'cols': [{'t': '개념', 'w': '24%'}, {'t': '출처', 'w': '36%'}, {'t': '덱 반영', 'accent': True}],
  'rows': [['ReAct loop', 'Yao et al., ReAct, arXiv:2210.03629', 'reasoning-action-observation 루프 설명'],
           ['RAG', 'Lewis et al., RAG, NeurIPS 2020', '검색 증강 생성과 provenance 설명'],
           ['Pregel', 'Malewicz et al., SIGMOD 2010', 'superstep, message passing, halt 설명'],
           ['LangGraph runtime', 'LangGraph official docs', 'durable execution, streaming, HITL, persistence 설명']]},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '01_introduction.ipynb',
  'sub': '01_introduction.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '03_langgraph/01_introduction.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 01_introduction',
  'title': '01_introduction 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '01_introduction.ipynb',
  'note': 'cell 7',
  'code': 'import importlib\n'
          '\n'
          'packages = {\n'
          '    "langgraph": "langgraph",\n'
          '    "langchain": "langchain",\n'
          '    "langchain_openai": "langchain-openai",\n'
          '}\n'
          '\n'
          'print("=" * 50)\n'
          'print("LangGraph 환경 확인")\n'
          'print("=" * 50)\n'
          '\n'
          'for module_name, package_name in packages.items():\n'
          '    try:\n'
          '        mod = importlib.import_module(module_name)\n'
          '        version = getattr(mod, "__version__", "installed")\n'
          '        print(f"  OK  {package_name}: {version}")\n'
          '    except ImportError:\n'
          '        print(f"  ERR {package_name}: 설치되지 않음")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 01_introduction',
  'title': '01_introduction 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '01_introduction.ipynb',
  'note': 'cell 8',
  'code': 'from dotenv import load_dotenv\n'
          'import os\n'
          'load_dotenv(override=True)\n'
          '\n'
          'required = ["OPENAI_API_KEY"]\n'
          'optional = ["TAVILY_API_KEY", "LANGSMITH_API_KEY"]\n'
          '\n'
          'print("API 키 상태:")\n'
          'for key in required:\n'
          '    print(f"  {\'OK\' if os.environ.get(key) else \'MISSING\'} {key} (필수)")\n'
          'for key in optional:\n'
          '    print(f"  {\'OK\' if os.environ.get(key) else \'--\'} {key} (선택)")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 01_introduction',
  'title': '01_introduction 코드 03',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '01_introduction.ipynb',
  'note': 'cell 9',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    os.environ.setdefault("LANGSMITH_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))\n'
          '    os.environ.setdefault("LANGSMITH_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))\n'
          '    print(f"LangSmith tracing ON — project: {os.environ[\'LANGSMITH_PROJECT\']}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 01_introduction',
  'title': '01_introduction 코드 04',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '01_introduction.ipynb',
  'note': 'cell 10',
  'code': '# Core import verification\n'
          'from langgraph.graph import StateGraph, START, END\n'
          'from langgraph.func import entrypoint, task\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          'from langgraph.types import Command, interrupt\n'
          'from langchain.tools import tool\n'
          'from langchain.messages import HumanMessage, SystemMessage, AIMessage\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          'print("모든 핵심 임포트 완료")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 01_introduction',
  'title': '01_introduction 코드 05',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '01_introduction.ipynb',
  'note': 'cell 12',
  'code': 'from langgraph.graph import StateGraph, START, END\n'
          'from typing import TypedDict\n'
          '\n'
          'class SimpleState(TypedDict):\n'
          '    input: str\n'
          '    output: str\n'
          '\n'
          'def greet(state: SimpleState) -> dict:\n'
          '    return {"output": f"안녕하세요, {state[\'input\']}님!"}\n'
          '\n'
          'builder = StateGraph(SimpleState)\n'
          'builder.add_node("greet", greet)\n'
          'builder.add_edge(START, "greet")\n'
          'builder.add_edge("greet", END)\n'
          '\n'
          'graph = builder.compile()\n'
          'result = graph.invoke({"input": "LangGraph"}, config=lf_config)\n'
          'print("Graph API 결과:", result["output"])'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 01_introduction',
  'title': '01_introduction 코드 06',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '01_introduction.ipynb',
  'note': 'cell 14',
  'code': 'from langgraph.func import entrypoint, task\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '@task\n'
          'def process(text: str) -> str:\n'
          '    return f"처리 완료: {text.upper()}"\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def simple_workflow(text: str) -> str:\n'
          '    result = process(text).result()\n'
          '    return result\n'
          '\n'
          'output = simple_workflow.invoke("안녕하세요 langgraph", {**{"configurable": {"thread_id": "demo"}}, '
          '**lf_config})\n'
          'print("Functional API 결과:", output)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '02_graph_api.ipynb',
  'sub': '02_graph_api.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '03_langgraph/02_graph_api.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          'from langchain_openai import ChatOpenAI\n'
          'model = ChatOpenAI(model="gpt-5.4")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    os.environ.setdefault("LANGSMITH_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))\n'
          '    os.environ.setdefault("LANGSMITH_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))\n'
          '    print(f"LangSmith tracing ON — project: {os.environ[\'LANGSMITH_PROJECT\']}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 03 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 7',
  'code': 'from langgraph.graph import StateGraph, START, END\n'
          'from typing import TypedDict\n'
          '\n'
          '\n'
          'class State(TypedDict):\n'
          '    text: str\n'
          '    word_count: int\n'
          '\n'
          '\n'
          'def count_words(state: State) -> dict:\n'
          '    words = state["text"].split()\n'
          '    return {\n'
          '        "word_count": len(words)\n'
          '    }\n'
          '\n'
          '\n'
          'builder = StateGraph(State)\n'
          '\n'
          'builder.add_node("counter", count_words)\n'
          '\n'
          'builder.add_edge(START, "counter")\n'
          'builder.add_edge("counter", END)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 03 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 7',
  'code': '\n'
          'graph = builder.compile()\n'
          '\n'
          '\n'
          'result = graph.invoke(\n'
          '    {\n'
          '        "text": "LangGraph는 에이전트를 구축하기 위한 강력한 프레임워크입니다."\n'
          '    },\n'
          '    config=lf_config\n'
          ')\n'
          '\n'
          'print(f"텍스트: {result[\'text\']}")\n'
          'print(f"단어 수: {result[\'word_count\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 04 (1/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 9',
  'code': 'from typing import Annotated, TypedDict\n'
          'import operator\n'
          '\n'
          'class AccState(TypedDict):\n'
          '    items: Annotated[list[str], operator.add]  # list append via reducer\n'
          '    count: int  # default: override\n'
          '\n'
          '\n'
          'def step_a(state: AccState) -> dict:\n'
          '    return {\n'
          '        "items": ["from_a"],\n'
          '        "count": 1\n'
          '    }\n'
          '\n'
          '\n'
          'def step_b(state: AccState) -> dict:\n'
          '    return {\n'
          '        "items": ["from_b"],\n'
          '        "count": 2\n'
          '    }\n'
          '\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 04 (2/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 9',
  'code': 'builder = StateGraph(AccState)\n'
          '\n'
          'builder.add_node("a", step_a)\n'
          'builder.add_node("b", step_b)\n'
          '\n'
          'builder.add_edge(START, "a")\n'
          'builder.add_edge("a", "b")\n'
          'builder.add_edge("b", END)\n'
          '\n'
          'graph = builder.compile()\n'
          '\n'
          'result = graph.invoke(\n'
          '    {\n'
          '        "items": [],\n'
          '        "count": 0\n'
          '    },\n'
          '    config=lf_config\n'
          ')\n'
          '\n'
          'print(f"items (리듀서=add): {result[\'items\']}")\n'
          '# ["from_a", "from_b"]\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 04 (3/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 9',
  'code': 'print(f"count (덮어쓰기): {result[\'count\']}")\n# 2'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 05 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 11',
  'code': 'from typing import Literal\n'
          '\n'
          'class RouterState(TypedDict):\n'
          '    query: str\n'
          '    category: str\n'
          '    result: str\n'
          '\n'
          'def classify(state: RouterState) -> dict:\n'
          '    q = state["query"].lower()\n'
          '    if "weather" in q or "날씨" in q:\n'
          '        return {"category": "weather"}\n'
          '    elif "math" in q or "calculate" in q or "계산" in q:\n'
          '        return {"category": "math"}\n'
          '    return {"category": "general"}\n'
          '\n'
          'def handle_weather(state: RouterState) -> dict:\n'
          '    return {"result": f"[날씨] 날씨 확인 중: {state[\'query\']}"}\n'
          '\n'
          'def handle_math(state: RouterState) -> dict:\n'
          '    return {"result": f"[수학] 계산 중: {state[\'query\']}"}\n'
          '\n'
          'def handle_general(state: RouterState) -> dict:'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 05 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 11',
  'code': '    return {"result": f"[일반] 처리 중: {state[\'query\']}"}\n'
          '\n'
          'def route(state: RouterState) -> Literal["weather", "math", "general"]:\n'
          '    return state["category"]\n'
          '\n'
          'builder = StateGraph(RouterState)\n'
          'builder.add_node("classify", classify)\n'
          'builder.add_node("weather", handle_weather)\n'
          'builder.add_node("math", handle_math)\n'
          'builder.add_node("general", handle_general)\n'
          '\n'
          'builder.add_edge(START, "classify")\n'
          'builder.add_conditional_edges("classify", route)\n'
          'builder.add_edge("weather", END)\n'
          'builder.add_edge("math", END)\n'
          'builder.add_edge("general", END)\n'
          '\n'
          'graph = builder.compile()\n'
          '\n'
          'for query in ["오늘 날씨는?", "2+2를 계산해줘", "농담 하나 해줘"]:\n'
          '    result = graph.invoke({"query": query}, config=lf_config)\n'
          '    print(f"  {query} -> {result[\'result\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 06',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 13',
  'code': 'from langgraph.graph import MessagesState\n'
          'from langchain.messages import HumanMessage, SystemMessage\n'
          '\n'
          'def chatbot(state: MessagesState) -> dict:\n'
          '    response = model.invoke(state["messages"], config=lf_config)\n'
          '    return {"messages": [response]}\n'
          '\n'
          'builder = StateGraph(MessagesState)\n'
          'builder.add_node("chatbot", chatbot)\n'
          'builder.add_edge(START, "chatbot")\n'
          'builder.add_edge("chatbot", END)\n'
          '\n'
          'graph = builder.compile()\n'
          '\n'
          'result = graph.invoke({"messages": [HumanMessage(content="2+2는 얼마인가요?")]}, config=lf_config)\n'
          'print("응답:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 07 (1/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 15',
  'code': 'from typing import TypedDict\n'
          '\n'
          'class InputSchema(TypedDict):\n'
          '    question: str\n'
          '\n'
          '\n'
          'class OutputSchema(TypedDict):\n'
          '    answer: str\n'
          '\n'
          '\n'
          'class InternalState(TypedDict):\n'
          '    question: str\n'
          '    answer: str\n'
          '    intermediate: str  # internal only\n'
          '\n'
          '\n'
          'def process(state: InternalState) -> dict:\n'
          '    return {\n'
          '        "intermediate": state["question"].upper()\n'
          '    }\n'
          '\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 07 (2/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 15',
  'code': 'def answer(state: InternalState) -> dict:\n'
          '    return {\n'
          '        "answer": f"\'{state[\'intermediate\']}\'에 대한 답: 42"\n'
          '    }\n'
          '\n'
          '\n'
          'builder = StateGraph(\n'
          '    InternalState,\n'
          '    input_schema=InputSchema,\n'
          '    output_schema=OutputSchema\n'
          ')\n'
          '\n'
          'builder.add_node("process", process)\n'
          'builder.add_node("answer", answer)\n'
          '\n'
          'builder.add_edge(START, "process")\n'
          'builder.add_edge("process", "answer")\n'
          'builder.add_edge("answer", END)\n'
          '\n'
          'graph = builder.compile()\n'
          '\n'
          'result = graph.invoke('},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 07 (3/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 15',
  'code': '    {\n'
          '        "question": "삶의 의미"\n'
          '    },\n'
          '    config=lf_config\n'
          ')\n'
          '\n'
          'print("출력:", result)\n'
          '\n'
          '# intermediate 필드는 출력에 포함되지 않음'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 08 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 17',
  'code': 'from dataclasses import dataclass\n'
          'from langgraph.runtime import Runtime\n'
          '\n'
          '\n'
          '@dataclass\n'
          'class ContextSchema:\n'
          '    user_id: str\n'
          '    llm_provider: str = "openai"\n'
          '\n'
          '\n'
          'class CtxState(TypedDict):\n'
          '    query: str\n'
          '    answer: str\n'
          '\n'
          '\n'
          'def ctx_node(state: CtxState, runtime: Runtime[ContextSchema]) -> dict:\n'
          '    # State와 분리된 호출 시점 의존성\n'
          '    ctx = runtime.context\n'
          '    # 실행 메타데이터 (thread/run/attempt 등)\n'
          '    info = runtime.execution_info\n'
          '    return {\n'
          '        "answer": ('},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 08 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 17',
  'code': '            f"user={ctx.user_id}, provider={ctx.llm_provider}, "\n'
          '            f"attempt={info.node_attempt} -> \'{state[\'query\']}\'"\n'
          '        )\n'
          '    }\n'
          '\n'
          '\n'
          'builder = StateGraph(CtxState, context_schema=ContextSchema)\n'
          'builder.add_node("ctx_node", ctx_node)\n'
          'builder.add_edge(START, "ctx_node")\n'
          'builder.add_edge("ctx_node", END)\n'
          '\n'
          'graph = builder.compile()\n'
          '\n'
          'result = graph.invoke(\n'
          '    {"query": "hello"},\n'
          '    context={"user_id": "alice", "llm_provider": "anthropic"},\n'
          '    config=lf_config,\n'
          ')\n'
          'print(result["answer"])'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 09 (1/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 19',
  'code': 'from langgraph.types import RetryPolicy, CachePolicy\n'
          'from langgraph.cache.memory import InMemoryCache\n'
          '\n'
          '\n'
          'class ReliableState(TypedDict):\n'
          '    payload: str\n'
          '    out: str\n'
          '\n'
          '\n'
          '# 첫 호출은 실패하고 두 번째에 성공 — retry_policy 데모용\n'
          '_calls = {"n": 0}\n'
          '\n'
          '\n'
          'def flaky(state: ReliableState) -> dict:\n'
          '    _calls["n"] += 1\n'
          '    if _calls["n"] < 2:\n'
          '        raise ValueError("일시 장애")\n'
          '    return {"out": f"처리: {state[\'payload\']} (시도 {_calls[\'n\']})"}\n'
          '\n'
          '\n'
          'def heavy(state: ReliableState) -> dict:\n'
          '    # 같은 입력이면 cache_policy(ttl=120)로 결과 재사용'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 09 (2/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 19',
  'code': '    return {"out": state["out"].upper()}\n'
          '\n'
          '\n'
          'builder = StateGraph(ReliableState)\n'
          'builder.add_node(\n'
          '    "flaky",\n'
          '    flaky,\n'
          '    retry_policy=RetryPolicy(max_attempts=3, retry_on=ValueError),\n'
          ')\n'
          'builder.add_node(\n'
          '    "heavy",\n'
          '    heavy,\n'
          '    cache_policy=CachePolicy(ttl=120),\n'
          ')\n'
          'builder.add_edge(START, "flaky")\n'
          'builder.add_edge("flaky", "heavy")\n'
          'builder.add_edge("heavy", END)\n'
          '\n'
          'graph = builder.compile(cache=InMemoryCache())\n'
          '\n'
          'result = graph.invoke({"payload": "hello", "out": ""}, config=lf_config)\n'
          'print(result["out"])'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 09 (3/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 19',
  'code': 'print(f"flaky 호출 횟수: {_calls[\'n\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 10 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 21',
  'code': 'from langgraph.types import Send, Command\n'
          '\n'
          '\n'
          'class FanOutState(TypedDict):\n'
          '    items: list[str]\n'
          '    results: Annotated[list[str], operator.add]\n'
          '\n'
          '\n'
          'def dispatch(state: FanOutState) -> list[Send]:\n'
          '    # map: 각 item마다 worker 인스턴스를 동적으로 생성\n'
          '    return [Send("worker", {"item": it}) for it in state["items"]]\n'
          '\n'
          '\n'
          'def worker(state: dict) -> dict:\n'
          '    return {"results": [f"처리({state[\'item\']})"]}\n'
          '\n'
          '\n'
          'def reduce(state: FanOutState) -> dict:\n'
          '    return {"results": [f"총 {len(state[\'results\'])}건 집계"]}\n'
          '\n'
          '\n'
          'builder = StateGraph(FanOutState)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 02_graph_api',
  'title': '02_graph_api 코드 10 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '02_graph_api.ipynb',
  'note': 'cell 21',
  'code': 'builder.add_node("worker", worker)\n'
          'builder.add_node("reduce", reduce)\n'
          'builder.add_conditional_edges(START, dispatch, ["worker"])\n'
          'builder.add_edge("worker", "reduce")\n'
          'builder.add_edge("reduce", END)\n'
          '\n'
          'graph = builder.compile()\n'
          '\n'
          'result = graph.invoke(\n'
          '    {"items": ["a", "b", "c"], "results": []},\n'
          '    config=lf_config,\n'
          ')\n'
          'for r in result["results"]:\n'
          '    print(r)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '03_functional_api.ipynb',
  'sub': '03_functional_api.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '03_langgraph/03_functional_api.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI\n'
          'model = ChatOpenAI(model="gpt-5.4")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    os.environ.setdefault("LANGSMITH_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))\n'
          '    os.environ.setdefault("LANGSMITH_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))\n'
          '    print(f"LangSmith tracing ON — project: {os.environ[\'LANGSMITH_PROJECT\']}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 03 (1/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 7',
  'code': 'from langgraph.func import entrypoint, task\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '\n'
          '@task\n'
          'def fetch_data(url: str) -> str:\n'
          '    """URL에서 데이터를 가져오는 시뮬레이션입니다."""\n'
          '    return f"{url}에서 가져온 데이터"\n'
          '\n'
          '\n'
          '@task\n'
          'def process_data(data: str) -> str:\n'
          '    """가져온 데이터를 처리합니다."""\n'
          '    return f"처리 완료: {data.upper()}"\n'
          '\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def data_pipeline(url: str) -> str:\n'
          '    raw = fetch_data(url).result()\n'
          '    processed = process_data(raw).result()\n'
          '    return processed\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 03 (2/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 7',
  'code': '\n'
          'config = {\n'
          '    "configurable": {\n'
          '        "thread_id": "pipe-1"\n'
          '    }\n'
          '}\n'
          '\n'
          'result = data_pipeline.invoke(\n'
          '    "https://example.com/api",\n'
          '    {**config, **lf_config}\n'
          ')\n'
          '\n'
          'print("파이프라인 결과:", result)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 04 (1/3)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 9',
  'code': 'from langgraph.func import entrypoint, task\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '\n'
          '@task\n'
          'def analyze_sentiment(text: str) -> str:\n'
          '    return f"감성({text[:20]}...): 긍정적"\n'
          '\n'
          '\n'
          '@task\n'
          'def extract_keywords(text: str) -> str:\n'
          '    words = text.split()\n'
          '    return f"키워드: {\', \'.join(words[:3])}"\n'
          '\n'
          '\n'
          '@task\n'
          'def summarize(text: str) -> str:\n'
          '    return f"요약: {text[:50]}..."\n'
          '\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def parallel_analysis(text: str) -> dict:'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 04 (2/3)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 9',
  'code': '    # 3개 태스크를 병렬로 시작\n'
          '    sentiment_future = analyze_sentiment(text)\n'
          '    keywords_future = extract_keywords(text)\n'
          '    summary_future = summarize(text)\n'
          '\n'
          '    # 결과를 순서대로 수집\n'
          '    return {\n'
          '        "sentiment": sentiment_future.result(),\n'
          '        "keywords": keywords_future.result(),\n'
          '        "summary": summary_future.result(),\n'
          '    }\n'
          '\n'
          '\n'
          'config = {\n'
          '    "configurable": {\n'
          '        "thread_id": "parallel-1"\n'
          '    }\n'
          '}\n'
          '\n'
          'result = parallel_analysis.invoke(\n'
          '    "LangGraph는 상태 기반 에이전트를 구축하기 위한 강력한 프레임워크입니다",\n'
          '    {**config, **lf_config}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 04 (3/3)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 9',
  'code': ')\n\nfor k, v in result.items():\n    print(f"  {k}: {v}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 05',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 11',
  'code': '@entrypoint(checkpointer=InMemorySaver())\n'
          'def counter(increment: int, *, previous: int = 0) -> int:\n'
          '    """호출할 때마다 이전 합계에 더합니다."""\n'
          '    new_total = (previous or 0) + increment\n'
          '    return new_total\n'
          '\n'
          'config = {"configurable": {"thread_id": "counter-1"}}\n'
          'print("호출 1:", counter.invoke(5, {**config, **lf_config}))   # 5\n'
          'print("호출 2:", counter.invoke(3, {**config, **lf_config}))   # 8\n'
          'print("호출 3:", counter.invoke(10, {**config, **lf_config}))  # 18'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 06',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 13',
  'code': '@entrypoint(checkpointer=InMemorySaver())\n'
          'def smart_counter(number: int, *, previous: int = 0) -> entrypoint.final[str, int]:\n'
          '    """포맷된 문자열을 반환하되, 다음 호출을 위해 원시 숫자를 저장합니다."""\n'
          '    new_total = (previous or 0) + number\n'
          '    # value: 사용자에게 반환되는 값\n'
          '    # save: 다음 호출의 previous로 저장되는 값\n'
          '    return entrypoint.final(value=f"현재 합계: {new_total}", save=new_total)\n'
          '\n'
          'config = {"configurable": {"thread_id": "smart-1"}}\n'
          'print(smart_counter.invoke(10, {**config, **lf_config}))   # "현재 합계: 10"\n'
          'print(smart_counter.invoke(5, {**config, **lf_config}))    # "현재 합계: 15"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 07 (1/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 15',
  'code': 'import time\n'
          '\n'
          '# CORRECT: 비결정적 작업을 @task로 감싸기\n'
          '@task\n'
          'def get_timestamp() -> float:\n'
          '    return time.time()\n'
          '\n'
          '\n'
          '@task\n'
          'def call_llm(prompt: str) -> str:\n'
          '    response = model.invoke(prompt, config=lf_config)\n'
          '    return response.content\n'
          '\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def deterministic_workflow(prompt: str) -> dict:\n'
          '    ts = get_timestamp().result()  # 체크포인트에 저장, 재실행 시 동일 값\n'
          '    answer = call_llm(prompt).result()\n'
          '\n'
          '    return {\n'
          '        "timestamp": ts,\n'
          '        "answer": answer'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 07 (2/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 15',
  'code': '    }\n'
          '\n'
          '\n'
          'config = {\n'
          '    "configurable": {\n'
          '        "thread_id": "det-1"\n'
          '    }\n'
          '}\n'
          '\n'
          'result = deterministic_workflow.invoke(\n'
          '    "한 단어로 인사해 주세요",\n'
          '    {**config, **lf_config}\n'
          ')\n'
          '\n'
          'print(f"타임스탬프: {result[\'timestamp\']}")\n'
          'print(f"답변: {result[\'answer\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 08 (1/3)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 17',
  'code': 'from langchain.tools import tool\n'
          'from langchain.messages import HumanMessage, SystemMessage, ToolMessage\n'
          'from langgraph.graph import add_messages\n'
          '\n'
          '@tool\n'
          'def add(a: int, b: int) -> int:\n'
          '    """두 수를 더합니다."""\n'
          '    return a + b\n'
          '\n'
          '@tool\n'
          'def multiply(a: int, b: int) -> int:\n'
          '    """두 수를 곱합니다."""\n'
          '    return a * b\n'
          '\n'
          'tools = [add, multiply]\n'
          'tools_by_name = {t.name: t for t in tools}\n'
          'model_with_tools = model.bind_tools(tools)\n'
          '\n'
          '@task\n'
          'def call_model(messages: list) -> object:\n'
          '    return model_with_tools.invoke(\n'
          '        [SystemMessage(content="당신은 수학 도우미입니다.")] + messages,'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 08 (2/3)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 17',
  'code': '        config=lf_config,\n'
          ')\n'
          '\n'
          '@task\n'
          'def call_tool(tool_call: dict) -> ToolMessage:\n'
          '    tool_fn = tools_by_name[tool_call["name"]]\n'
          '    result = tool_fn.invoke(tool_call["args"], config=lf_config)\n'
          '    return ToolMessage(content=str(result), tool_call_id=tool_call["id"])\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def agent(messages: list) -> list:\n'
          '    llm_response = call_model(messages).result()\n'
          '\n'
          '    while llm_response.tool_calls:\n'
          '        tool_results = [call_tool(tc).result() for tc in llm_response.tool_calls]\n'
          '        messages = add_messages(messages, [llm_response] + tool_results)\n'
          '        llm_response = call_model(messages).result()\n'
          '\n'
          '    return add_messages(messages, llm_response)\n'
          '\n'
          'config = {"configurable": {"thread_id": "agent-1"}}\n'
          'result = agent.invoke([HumanMessage(content="7 * 8 + 3은 얼마인가요?")], {**config, **lf_config})'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 08 (3/3)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 17',
  'code': 'print("에이전트 결과:", result[-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 09',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 19',
  'code': 'from langgraph.types import RetryPolicy\n'
          '\n'
          '# ValueError 만 재시도, 다른 예외는 즉시 전파\n'
          '_attempts = {"n": 0}\n'
          '\n'
          '\n'
          '@task(retry_policy=RetryPolicy(max_attempts=3, retry_on=ValueError))\n'
          'def fetch_with_retry(url: str) -> str:\n'
          '    _attempts["n"] += 1\n'
          '    if _attempts["n"] < 2:\n'
          '        raise ValueError(f"일시 장애 (시도 {_attempts[\'n\']})")\n'
          '    return f"{url} 응답 OK"\n'
          '\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def reliable_pipeline(url: str) -> str:\n'
          '    return fetch_with_retry(url).result()\n'
          '\n'
          '\n'
          'cfg = {"configurable": {"thread_id": "retry-1"}}\n'
          'print(reliable_pipeline.invoke("https://api.example.com", {**cfg, **lf_config}))\n'
          'print(f"총 시도: {_attempts[\'n\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 10 (1/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 21',
  'code': 'import time\n'
          'from langgraph.cache.memory import InMemoryCache\n'
          'from langgraph.types import CachePolicy\n'
          '\n'
          '\n'
          '@task(cache_policy=CachePolicy(ttl=120))\n'
          'def expensive_compute(x: int) -> int:\n'
          '    # 1초 sleep → 같은 x 값으로 두 번째 호출은 캐시 히트로 즉시 반환\n'
          '    time.sleep(1)\n'
          '    return x * 2\n'
          '\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver(), cache=InMemoryCache())\n'
          'def cached_pipeline(x: int) -> dict:\n'
          '    t0 = time.perf_counter()\n'
          '    a = expensive_compute(x).result()\n'
          '    t1 = time.perf_counter()\n'
          '    b = expensive_compute(x).result()  # 같은 입력 → 캐시 히트\n'
          '    t2 = time.perf_counter()\n'
          '    return {"a": a, "b": b, "first_s": round(t1 - t0, 2), "second_s": round(t2 - t1, 2)}\n'
          '\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 10 (2/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 21',
  'code': 'cfg = {"configurable": {"thread_id": "cache-1"}}\nprint(cached_pipeline.invoke(7, {**cfg, **lf_config}))'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 11 (1/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 23',
  'code': 'from langgraph.types import Command, interrupt\n'
          '\n'
          '\n'
          '@task\n'
          'def review(draft: str) -> str:\n'
          '    # 구조화된 interrupt — 사람이 무엇을 검토하고 어떤 형식으로 응답하는지 명시\n'
          '    feedback = interrupt({\n'
          '        "question": "이 초안을 승인하시겠어요?",\n'
          '        "draft": draft,\n'
          '        "expected": "{\'approve\': bool, \'comment\': str}",\n'
          '    })\n'
          '    if feedback.get("approve"):\n'
          '        return draft\n'
          '    return f"{draft} (수정: {feedback.get(\'comment\', \'\')})"\n'
          '\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def approval_flow(topic: str) -> str:\n'
          '    draft = f"\'{topic}\'에 대한 한 문장 초안"\n'
          '    return review(draft).result()\n'
          '\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 03_functional_api',
  'title': '03_functional_api 코드 11 (2/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '03_functional_api.ipynb',
  'note': 'cell 23',
  'code': 'cfg = {"configurable": {"thread_id": "hitl-1"}}\n'
          '\n'
          '# 1차 호출 — interrupt 에서 멈춤\n'
          'state = approval_flow.invoke("LangGraph 입문", {**cfg, **lf_config})\n'
          'print("중단 신호:", state)\n'
          '\n'
          '# 사람이 검토 후 재개\n'
          'final = approval_flow.invoke(\n'
          '    Command(resume={"approve": False, "comment": "출처 추가 요망"}),\n'
          '    {**cfg, **lf_config},\n'
          ')\n'
          'print("최종:", final)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '04_workflows.ipynb',
  'sub': '04_workflows.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '03_langgraph/04_workflows.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          '\n'
          'from langchain_openai import ChatOpenAI\n'
          'model = ChatOpenAI(model="gpt-5.4")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    os.environ.setdefault("LANGSMITH_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))\n'
          '    os.environ.setdefault("LANGSMITH_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))\n'
          '    print(f"LangSmith tracing ON — project: {os.environ[\'LANGSMITH_PROJECT\']}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 03 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 7',
  'code': 'from langgraph.graph import StateGraph, START, END\n'
          'from typing import TypedDict\n'
          '\n'
          'class ChainState(TypedDict):\n'
          '    topic: str\n'
          '    draft: str\n'
          '    improved: str\n'
          '\n'
          'def generate_draft(state: ChainState) -> dict:\n'
          '    response = model.invoke(f"다음에 대한 한 문장 사실을 작성해주세요: {state[\'topic\']}", config=lf_config)\n'
          '    return {"draft": response.content}\n'
          '\n'
          'def improve_draft(state: ChainState) -> dict:\n'
          '    response = model.invoke(f"다음 텍스트를 더 매력적으로 개선해주세요: {state[\'draft\']}", config=lf_config)\n'
          '    return {"improved": response.content}\n'
          '\n'
          'builder = StateGraph(ChainState)\n'
          'builder.add_node("draft", generate_draft)\n'
          'builder.add_node("improve", improve_draft)\n'
          'builder.add_edge(START, "draft")\n'
          'builder.add_edge("draft", "improve")\n'
          'builder.add_edge("improve", END)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 03 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 7',
  'code': '\n'
          'chain = builder.compile()\n'
          'result = chain.invoke({"topic": "Python 프로그래밍"}, config=lf_config)\n'
          'print(f"초안: {result[\'draft\']}")\n'
          'print(f"개선: {result[\'improved\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 04 (1/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 9',
  'code': 'from typing import Annotated, TypedDict\n'
          'import operator\n'
          '\n'
          '\n'
          'class ParallelState(TypedDict):\n'
          '    text: str\n'
          '    analyses: Annotated[list[str], operator.add]\n'
          '\n'
          '\n'
          'def analyze_tone(state: ParallelState) -> dict:\n'
          '    r = model.invoke(\n'
          '        f"한 문장으로 다음의 어조를 설명해주세요: {state[\'text\']}",\n'
          '        config=lf_config\n'
          '    )\n'
          '    return {\n'
          '        "analyses": [f"어조: {r.content}"]\n'
          '    }\n'
          '\n'
          '\n'
          'def analyze_complexity(state: ParallelState) -> dict:\n'
          '    r = model.invoke(\n'
          '        f"한 문장으로 다음의 복잡도를 평가해주세요: {state[\'text\']}",'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 04 (2/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 9',
  'code': '        config=lf_config\n'
          '    )\n'
          '    return {\n'
          '        "analyses": [f"복잡도: {r.content}"]\n'
          '    }\n'
          '\n'
          '\n'
          'def synthesize(state: ParallelState) -> dict:\n'
          '    return {\n'
          '        "analyses": [\n'
          '            f"종합: {len(state[\'analyses\'])}개 분석 완료"\n'
          '        ]\n'
          '    }\n'
          '\n'
          '\n'
          'builder = StateGraph(ParallelState)\n'
          '\n'
          'builder.add_node("tone", analyze_tone)\n'
          'builder.add_node("complexity", analyze_complexity)\n'
          'builder.add_node("synthesize", synthesize)\n'
          '\n'
          '# START에서 두 분석 노드로 병렬 분기'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 04 (3/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 9',
  'code': 'builder.add_edge(START, "tone")\n'
          'builder.add_edge(START, "complexity")\n'
          '\n'
          '# 두 노드 완료 후 합성\n'
          'builder.add_edge("tone", "synthesize")\n'
          'builder.add_edge("complexity", "synthesize")\n'
          'builder.add_edge("synthesize", END)\n'
          '\n'
          'parallel_graph = builder.compile()\n'
          '\n'
          'result = parallel_graph.invoke(\n'
          '    {\n'
          '        "text": "LangGraph는 강력한 에이전트 워크플로를 가능하게 합니다.",\n'
          '        "analyses": []\n'
          '    },\n'
          '    config=lf_config\n'
          ')\n'
          '\n'
          'for a in result["analyses"]:\n'
          '    print(f"  {a}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 05 (1/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 11',
  'code': 'from pydantic import BaseModel, Field\n'
          'from typing import Literal, TypedDict\n'
          '\n'
          '\n'
          'class Classification(BaseModel):\n'
          '    category: Literal["technical", "business", "casual"]\n'
          '\n'
          '\n'
          'class RouteState(TypedDict):\n'
          '    question: str\n'
          '    category: str\n'
          '    answer: str\n'
          '\n'
          '\n'
          'def classify(state: RouteState) -> dict:\n'
          '    structured = model.with_structured_output(Classification)\n'
          '    result = structured.invoke(\n'
          '        f"다음 질문을 분류하세요: {state[\'question\']}",\n'
          '        config=lf_config\n'
          '    )\n'
          '    return {"category": result.category}\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 05 (2/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 11',
  'code': '\n'
          'def handle_technical(state: RouteState) -> dict:\n'
          '    r = model.invoke(\n'
          '        f"기술 전문가로서 답변해주세요: {state[\'question\']}",\n'
          '        config=lf_config\n'
          '    )\n'
          '    return {"answer": r.content}\n'
          '\n'
          '\n'
          'def handle_business(state: RouteState) -> dict:\n'
          '    r = model.invoke(\n'
          '        f"비즈니스 어드바이저로서 답변해주세요: {state[\'question\']}",\n'
          '        config=lf_config\n'
          '    )\n'
          '    return {"answer": r.content}\n'
          '\n'
          '\n'
          'def handle_casual(state: RouteState) -> dict:\n'
          '    r = model.invoke(\n'
          '        f"가볍게 답변해주세요: {state[\'question\']}",\n'
          '        config=lf_config\n'
          '    )'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 05 (3/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 11',
  'code': '    return {"answer": r.content}\n'
          '\n'
          '\n'
          'def route(state: RouteState) -> str:\n'
          '    return state["category"]\n'
          '\n'
          '\n'
          'builder = StateGraph(RouteState)\n'
          '\n'
          'builder.add_node("classify", classify)\n'
          'builder.add_node("technical", handle_technical)\n'
          'builder.add_node("business", handle_business)\n'
          'builder.add_node("casual", handle_casual)\n'
          '\n'
          'builder.add_edge(START, "classify")\n'
          'builder.add_conditional_edges("classify", route)\n'
          '\n'
          'builder.add_edge("technical", END)\n'
          'builder.add_edge("business", END)\n'
          'builder.add_edge("casual", END)\n'
          '\n'
          'router = builder.compile()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 05 (4/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 11',
  'code': '\n'
          'result = router.invoke(\n'
          '    {\n'
          '        "question": "Python에서 가비지 컬렉션은 어떻게 작동하나요?"\n'
          '    },\n'
          '    config=lf_config\n'
          ')\n'
          '\n'
          'print(f"카테고리: {result[\'category\']}")\n'
          'print(f"답변: {result[\'answer\'][:200]}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 06 (1/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 13',
  'code': 'from langgraph.types import Send\n'
          'from typing import Annotated, TypedDict\n'
          'import operator\n'
          '\n'
          '\n'
          'class OrchestratorState(TypedDict):\n'
          '    topic: str\n'
          '    sections: list[str]\n'
          '    results: Annotated[list[str], operator.add]\n'
          '\n'
          '\n'
          'class WorkerState(TypedDict):\n'
          '    section: str\n'
          '\n'
          '\n'
          'def plan_sections(state: OrchestratorState) -> dict:\n'
          '    r = model.invoke(\n'
          '        f"\'{state[\'topic\']}\'에 대한 기사의 짧은 섹션 제목 3개를 나열해주세요. 한 줄에 하나씩, 번호 없이.",\n'
          '        config=lf_config\n'
          '    )\n'
          '\n'
          '    sections = ['},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 06 (2/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 13',
  'code': '        s.strip()\n'
          '        for s in r.content.strip().split("\\n")\n'
          '        if s.strip()\n'
          '    ][:3]\n'
          '\n'
          '    return {"sections": sections}\n'
          '\n'
          '\n'
          'def assign_workers(state: OrchestratorState) -> list[Send]:\n'
          '    return [\n'
          '        Send("worker", {"section": s})\n'
          '        for s in state["sections"]\n'
          '    ]\n'
          '\n'
          '\n'
          'def worker(state: WorkerState) -> dict:\n'
          '    r = model.invoke(\n'
          '        f"다음에 대해 한 문장으로 작성해주세요: {state[\'section\']}",\n'
          '        config=lf_config\n'
          '    )\n'
          '\n'
          '    return {'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 06 (3/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 13',
  'code': '        "results": [\n'
          '            f"## {state[\'section\']}\\n{r.content}"\n'
          '        ]\n'
          '    }\n'
          '\n'
          '\n'
          'builder = StateGraph(OrchestratorState)\n'
          '\n'
          'builder.add_node("plan", plan_sections)\n'
          'builder.add_node("worker", worker)\n'
          '\n'
          'builder.add_edge(START, "plan")\n'
          '\n'
          'builder.add_conditional_edges(\n'
          '    "plan",\n'
          '    assign_workers,\n'
          '    ["worker"]\n'
          ')\n'
          '\n'
          'builder.add_edge("worker", END)\n'
          '\n'
          'orchestrator = builder.compile()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 06 (4/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 13',
  'code': '\n'
          'result = orchestrator.invoke(\n'
          '    {\n'
          '        "topic": "머신러닝",\n'
          '        "sections": [],\n'
          '        "results": []\n'
          '    },\n'
          '    config=lf_config\n'
          ')\n'
          '\n'
          'for r in result["results"]:\n'
          '    print(r)\n'
          '    print()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 07 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 15',
  'code': 'class EvalState(TypedDict):\n'
          '    task: str\n'
          '    draft: str\n'
          '    feedback: str\n'
          '    is_good: bool\n'
          '    iterations: int\n'
          '\n'
          'def generate(state: EvalState) -> dict:\n'
          '    if state.get("feedback"):\n'
          '        prompt = f"피드백을 반영하여 개선해주세요.\\n원본: {state[\'draft\']}\\n피드백: {state[\'feedback\']}"\n'
          '    else:\n'
          '        prompt = f"다음에 대한 한 문장 슬로건을 작성해주세요: {state[\'task\']}"\n'
          '    r = model.invoke(prompt, config=lf_config)\n'
          '    return {"draft": r.content, "iterations": state.get("iterations", 0) + 1}\n'
          '\n'
          'def evaluate(state: EvalState) -> dict:\n'
          '    r = model.invoke(f"이 슬로건을 1-10으로 평가하고 간단한 피드백을 주세요: \'{state[\'draft\']}\'", config=lf_config)\n'
          '    content = r.content\n'
          '    is_good = any(f"{n}/10" in content for n in range(8, 11))\n'
          '    return {"feedback": content, "is_good": is_good}\n'
          '\n'
          'def should_retry(state: EvalState) -> str:'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 04_workflows',
  'title': '04_workflows 코드 07 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '04_workflows.ipynb',
  'note': 'cell 15',
  'code': '    if state["is_good"] or state["iterations"] >= 3:\n'
          '        return END\n'
          '    return "generate"\n'
          '\n'
          'builder = StateGraph(EvalState)\n'
          'builder.add_node("generate", generate)\n'
          'builder.add_node("evaluate", evaluate)\n'
          '\n'
          'builder.add_edge(START, "generate")\n'
          'builder.add_edge("generate", "evaluate")\n'
          'builder.add_conditional_edges("evaluate", should_retry, ["generate", END])\n'
          '\n'
          'optimizer = builder.compile()\n'
          'result = optimizer.invoke({"task": "Python 학습 플랫폼"}, config=lf_config)\n'
          'print(f"최종 초안 ({result[\'iterations\']}번 반복 후): {result[\'draft\']}")'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '05_agents.ipynb',
  'sub': '05_agents.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '03_langgraph/05_agents.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 05_agents',
  'title': '05_agents 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '05_agents.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          'from langchain_openai import ChatOpenAI\n'
          'model = ChatOpenAI(model="gpt-5.4")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 05_agents',
  'title': '05_agents 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '05_agents.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    os.environ.setdefault("LANGSMITH_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))\n'
          '    os.environ.setdefault("LANGSMITH_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))\n'
          '    print(f"LangSmith tracing ON — project: {os.environ[\'LANGSMITH_PROJECT\']}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 05_agents',
  'title': '05_agents 코드 03 (1/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '05_agents.ipynb',
  'note': 'cell 7',
  'code': 'from langchain.tools import tool\n'
          'from langchain.messages import HumanMessage, SystemMessage, ToolMessage, AnyMessage\n'
          '\n'
          '@tool\n'
          'def add(a: int, b: int) -> int:\n'
          '    """두 수를 더합니다."""\n'
          '    return a + b\n'
          '\n'
          '@tool\n'
          'def multiply(a: int, b: int) -> int:\n'
          '    """두 수를 곱합니다."""\n'
          '    return a * b\n'
          '\n'
          '@tool\n'
          'def divide(a: int, b: int) -> float:\n'
          '    """a를 b로 나눕니다."""\n'
          '    return a / b\n'
          '\n'
          'tools = [add, multiply, divide]\n'
          'tools_by_name = {t.name: t for t in tools}\n'
          'model_with_tools = model.bind_tools(tools)\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 05_agents',
  'title': '05_agents 코드 03 (2/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '05_agents.ipynb',
  'note': 'cell 7',
  'code': 'print("모델에 바인딩된 도구:")\nfor t in tools:\n    print(f"  - {t.name}: {t.description}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 05_agents',
  'title': '05_agents 코드 04 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '05_agents.ipynb',
  'note': 'cell 9',
  'code': 'from langgraph.graph import StateGraph, START, END\n'
          'from typing import TypedDict, Annotated, Literal\n'
          'import operator\n'
          '\n'
          'class AgentState(TypedDict):\n'
          '    messages: Annotated[list[AnyMessage], operator.add]\n'
          '\n'
          'SYSTEM_PROMPT = "당신은 유용한 수학 어시스턴트입니다. 제공된 도구를 사용하여 계산하세요."\n'
          '\n'
          'def llm_node(state: AgentState) -> dict:\n'
          '    response = model_with_tools.invoke(\n'
          '        [SystemMessage(content=SYSTEM_PROMPT)] + state["messages"],\n'
          '        config=lf_config,\n'
          ')\n'
          '    return {"messages": [response]}\n'
          '\n'
          'def tool_node(state: AgentState) -> dict:\n'
          '    results = []\n'
          '    for tc in state["messages"][-1].tool_calls:\n'
          '        tool_fn = tools_by_name[tc["name"]]\n'
          '        result = tool_fn.invoke(tc["args"], config=lf_config)\n'
          '        results.append(ToolMessage(content=str(result), tool_call_id=tc["id"]))'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 05_agents',
  'title': '05_agents 코드 04 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '05_agents.ipynb',
  'note': 'cell 9',
  'code': '    return {"messages": results}\n'
          '\n'
          'def should_continue(state: AgentState) -> Literal["tools", "__end__"]:\n'
          '    last = state["messages"][-1]\n'
          '    return "tools" if last.tool_calls else END\n'
          '\n'
          'builder = StateGraph(AgentState)\n'
          'builder.add_node("llm", llm_node)\n'
          'builder.add_node("tools", tool_node)\n'
          'builder.add_edge(START, "llm")\n'
          'builder.add_conditional_edges("llm", should_continue, ["tools", END])\n'
          'builder.add_edge("tools", "llm")\n'
          '\n'
          'agent = builder.compile()\n'
          '\n'
          'result = agent.invoke({"messages": [HumanMessage(content="(7 * 8) + 12는 얼마인가요?")]}, config=lf_config)\n'
          'print("에이전트 답변:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 05_agents',
  'title': '05_agents 코드 05',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '05_agents.ipynb',
  'note': 'cell 11',
  'code': 'print("에이전트 실행 흐름:")\n'
          'print("=" * 60)\n'
          'for chunk in agent.stream(\n'
          '    {"messages": [HumanMessage(content="100 / 4를 계산한 다음 3을 곱하면 얼마인가요?")]},\n'
          '    stream_mode="updates",\n'
          '    config=lf_config,\n'
          '):\n'
          '    for node_name, update in chunk.items():\n'
          '        print(f"\\n[{node_name}]")\n'
          '        for msg in update.get("messages", []):\n'
          "            if hasattr(msg, 'tool_calls') and msg.tool_calls:\n"
          '                for tc in msg.tool_calls:\n'
          '                    print(f"  도구 호출: {tc[\'name\']}({tc[\'args\']})")\n'
          "            elif hasattr(msg, 'content') and msg.content:\n"
          '                print(f"  {msg.content[:200]}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 05_agents',
  'title': '05_agents 코드 06 (1/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '05_agents.ipynb',
  'note': 'cell 13',
  'code': 'from langgraph.func import entrypoint, task\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          'from langgraph.graph import add_messages\n'
          '\n'
          '@task\n'
          'def call_model(messages: list) -> object:\n'
          '    return model_with_tools.invoke(\n'
          '        [SystemMessage(content=SYSTEM_PROMPT)] + messages,\n'
          '        config=lf_config,\n'
          ')\n'
          '\n'
          '@task\n'
          'def execute_tool(tool_call: dict) -> ToolMessage:\n'
          '    tool_fn = tools_by_name[tool_call["name"]]\n'
          '    result = tool_fn.invoke(tool_call["args"], config=lf_config)\n'
          '    return ToolMessage(content=str(result), tool_call_id=tool_call["id"])\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def functional_agent(messages: list) -> list:\n'
          '    response = call_model(messages).result()\n'
          '\n'
          '    while response.tool_calls:'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 05_agents',
  'title': '05_agents 코드 06 (2/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '05_agents.ipynb',
  'note': 'cell 13',
  'code': '        tool_results = [execute_tool(tc).result() for tc in response.tool_calls]\n'
          '        messages = add_messages(messages, [response] + tool_results)\n'
          '        response = call_model(messages).result()\n'
          '\n'
          '    return add_messages(messages, response)\n'
          '\n'
          'config = {"configurable": {"thread_id": "func-agent-1"}}\n'
          'result = functional_agent.invoke(\n'
          '    [HumanMessage(content="15 * 4를 계산한 다음 20을 더하면 얼마인가요?")],\n'
          '    {**config, **lf_config}\n'
          ')\n'
          'print("Functional 에이전트 답변:", result[-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 05_agents',
  'title': '05_agents 코드 07',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '05_agents.ipynb',
  'note': 'cell 15',
  'code': 'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'agent_with_memory = builder.compile(checkpointer=InMemorySaver())\n'
          '\n'
          'config = {"configurable": {"thread_id": "math-session"}}\n'
          '\n'
          'r1 = agent_with_memory.invoke(\n'
          '    {"messages": [HumanMessage(content="6 * 7은 얼마인가요?")]},\n'
          '    {**config, **lf_config}\n'
          ')\n'
          'print("턴 1:", r1["messages"][-1].content)\n'
          '\n'
          'r2 = agent_with_memory.invoke(\n'
          '    {"messages": [HumanMessage(content="이제 그 결과를 2로 나누세요.")]},\n'
          '    {**config, **lf_config}\n'
          ')\n'
          'print("턴 2:", r2["messages"][-1].content)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '06_persistence_and_memory.ipynb',
  'sub': '06_persistence_and_memory.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '03_langgraph/06_persistence_and_memory.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          'from langchain_openai import ChatOpenAI\n'
          '# docs/langgraph 패치 기준 canonical 모델 ID\n'
          'model = ChatOpenAI(model="gpt-5.4-mini")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          '    print(f"LangSmith tracing ON \\u2014 project: {project}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON \\u2014 {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 03 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 7',
  'code': 'from langgraph.graph import StateGraph, START, END, MessagesState\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          'from langchain.messages import HumanMessage\n'
          '\n'
          'def chatbot(state: MessagesState) -> dict:\n'
          '    response = model.invoke(state["messages"], config=lf_config)\n'
          '    return {"messages": [response]}\n'
          '\n'
          'builder = StateGraph(MessagesState)\n'
          'builder.add_node("chatbot", chatbot)\n'
          'builder.add_edge(START, "chatbot")\n'
          'builder.add_edge("chatbot", END)\n'
          '\n'
          '# 체크포인터와 함께 컴파일\n'
          'checkpointer = InMemorySaver()\n'
          'graph = builder.compile(checkpointer=checkpointer)\n'
          '\n'
          'config = {"configurable": {"thread_id": "session-1"}}\n'
          '\n'
          '# 대화 1\n'
          'r1 = graph.invoke({"messages": [HumanMessage(content="제 이름은 앨리스입니다.")]}, {**config, **lf_config})\n'
          'print("턴 1:", r1["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 03 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 7',
  'code': '\n'
          '# 대화 2 — 이전 대화를 기억\n'
          'r2 = graph.invoke({"messages": [HumanMessage(content="제 이름이 뭐였죠?")]}, {**config, **lf_config})\n'
          'print("턴 2:", r2["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 04',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 9',
  'code': 'state = graph.get_state(config)\n'
          'print(f"스레드: {config[\'configurable\'][\'thread_id\']}")\n'
          'print(f"메시지 수: {len(state.values[\'messages\'])}")\n'
          'print(f"체크포인트 ID: {state.config[\'configurable\'][\'checkpoint_id\']}")\n'
          'print(f"다음 노드: {state.next}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 05',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 11',
  'code': 'print("상태 이력 (최신순):")\n'
          'for i, snapshot in enumerate(graph.get_state_history(config)):\n'
          '    msg_count = len(snapshot.values.get("messages", []))\n'
          '    print(f"  [{i}] 체크포인트={snapshot.config[\'configurable\'][\'checkpoint_id\'][:20]}... 메시지={msg_count}")\n'
          '    if i >= 4:\n'
          '        print("  ... (생략)")\n'
          '        break'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 06',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 13',
  'code': 'from langchain.messages import AIMessage\n'
          '\n'
          '# 상태에 메시지 직접 추가\n'
          'graph.update_state(config, {\n'
          '    "messages": [AIMessage(content="(시스템 노트: 사용자는 한국어 응답을 선호합니다.)")]\n'
          '})\n'
          '\n'
          '# 수정된 상태로 계속 대화\n'
          'r3 = graph.invoke({"messages": [HumanMessage(content="재미있는 사실을 알려주세요.")]}, {**config, **lf_config})\n'
          'print("업데이트 후:", r3["messages"][-1].content[:200])'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 07',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 15',
  'code': 'config_b = {"configurable": {"thread_id": "session-2"}}\n'
          'r = graph.invoke({"messages": [HumanMessage(content="제 이름을 아시나요?")]}, {**config_b, **lf_config})\n'
          'print("다른 스레드:", r["messages"][-1].content)\n'
          'print("-> 다른 thread_id이므로 이전 대화를 알 수 없음")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 08',
  'lead': '이 코드는 장기 메모리 Store 또는 저장 계층 사용을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 17',
  'code': 'from langgraph.store.memory import InMemoryStore\n'
          '\n'
          'store = InMemoryStore()\n'
          '\n'
          '# 데이터 저장\n'
          'store.put(("users",), "alice", {"favorite_color": "blue", "city": "Seoul"})\n'
          'store.put(("users",), "bob", {"favorite_color": "red", "city": "Tokyo"})\n'
          '\n'
          '# 데이터 조회\n'
          'alice = store.get(("users",), "alice")\n'
          'print(f"Alice: {alice.value}")\n'
          '\n'
          '# 검색\n'
          'results = store.search(("users",))\n'
          'print(f"\\n전체 사용자 ({len(results)}명):")\n'
          'for item in results:\n'
          '    print(f"  {item.key}: {item.value}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 09 (1/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 19',
  'code': 'import uuid\n'
          'from dataclasses import dataclass\n'
          'from langgraph.graph import StateGraph, START, END, MessagesState\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          'from langgraph.store.memory import InMemoryStore\n'
          'from langgraph.runtime import Runtime\n'
          'from langchain.messages import HumanMessage\n'
          '\n'
          '# --- Context schema: typed namespace for user-level data ---\n'
          '@dataclass\n'
          'class Context:\n'
          '    user_id: str\n'
          '\n'
          '# --- Store and checkpointer ---\n'
          'memory_store = InMemoryStore()\n'
          'memory_checkpointer = InMemorySaver()\n'
          '\n'
          '# --- Node that reads/writes long-term memory via runtime.context + runtime.store ---\n'
          'def chatbot_with_memory(state: MessagesState, runtime: Runtime[Context]):\n'
          '    """runtime.context.user_id로 namespace를 만들고 장기 메모리를 읽고 씁니다."""\n'
          '    user_id = runtime.context.user_id\n'
          '    namespace = (user_id, "memories")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 09 (2/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 19',
  'code': '\n'
          '    # 이 사용자의 기존 메모리를 조회\n'
          '    existing = runtime.store.search(namespace)\n'
          '    memory_text = "\\n".join(f"- {item.value[\'data\']}" for item in existing)\n'
          '\n'
          '    # 메모리에서 시스템 컨텍스트 구성\n'
          '    system_msg = "당신은 유용한 어시스턴트입니다."\n'
          '    if memory_text:\n'
          '        system_msg += f"\\n\\n사용자 메모리:\\n{memory_text}"\n'
          '\n'
          '    messages = [{"role": "system", "content": system_msg}] + state["messages"]\n'
          '    response = model.invoke(messages, config=lf_config)\n'
          '\n'
          '    # 사용자가 자신에 대해 언급한 새로운 사실을 저장\n'
          '    user_msg = state["messages"][-1].content.lower()\n'
          '    if any(kw in user_msg for kw in ["좋아", "사랑", "이름은", "선호", "즐겨"]):\n'
          '        runtime.store.put(namespace, str(uuid.uuid4()), {"data": state["messages"][-1].content})\n'
          '\n'
          '    return {"messages": [response]}\n'
          '\n'
          '# --- Build graph with context_schema ---\n'
          'builder = StateGraph(MessagesState, context_schema=Context)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 09 (3/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 19',
  'code': 'builder.add_node("chatbot", chatbot_with_memory)\n'
          'builder.add_edge(START, "chatbot")\n'
          'builder.add_edge("chatbot", END)\n'
          '\n'
          'graph_with_store = builder.compile(\n'
          '    checkpointer=memory_checkpointer,\n'
          '    store=memory_store,  # <-- store를 그래프에 연결\n'
          ')\n'
          '\n'
          '# --- Thread 1: user shares preferences ---\n'
          'config_1 = {"configurable": {"thread_id": "store-thread-1"}}\n'
          'r1 = graph_with_store.invoke(\n'
          '    {"messages": [HumanMessage(content="저는 등산과 사진 찍기를 좋아합니다.")]},\n'
          '    {**config_1, **lf_config},\n'
          '    context=Context(user_id="user-alice"),\n'
          ')\n'
          'print("스레드 1:", r1["messages"][-1].content[:150])\n'
          '\n'
          '# --- Thread 2 (different thread, same user): memories persist ---\n'
          'config_2 = {"configurable": {"thread_id": "store-thread-2"}}\n'
          'r2 = graph_with_store.invoke(\n'
          '    {"messages": [HumanMessage(content="제 취미가 뭔가요?")]},'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 09 (4/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 19',
  'code': '    {**config_2, **lf_config},\n'
          '    context=Context(user_id="user-alice"),\n'
          ')\n'
          'print("\\n스레드 2 (새 스레드, 같은 사용자):", r2["messages"][-1].content[:150])\n'
          '\n'
          '# --- Verify stored memories ---\n'
          'stored = memory_store.search(("user-alice", "memories"))\n'
          'print(f"\\nuser-alice의 저장된 메모리 ({len(stored)}개):")\n'
          'for item in stored:\n'
          '    print(f"  {item.key[:8]}...: {item.value}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 10 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 21',
  'code': 'from langgraph.graph import StateGraph, START, END, MessagesState\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          'from langchain_core.messages.utils import trim_messages, count_tokens_approximately\n'
          'from langchain.messages import HumanMessage, AIMessage, RemoveMessage\n'
          '\n'
          '# ============================================================\n'
          '# Part 1: trim_messages — LLM 호출 전에 메시지 잘라내기\n'
          '# ============================================================\n'
          '\n'
          'def chatbot_with_trim(state: MessagesState) -> dict:\n'
          '    """토큰 예산에 맞게 메시지를 잘라낸 후 LLM을 호출합니다."""\n'
          '    trimmed = trim_messages(\n'
          '        state["messages"],\n'
          '        strategy="last",\n'
          '        token_counter=count_tokens_approximately,\n'
          '        max_tokens=80,\n'
          '        start_on="human",\n'
          '        end_on=("human", "tool"),\n'
          '    )\n'
          '    print(f"  원본 메시지: {len(state[\'messages\'])}개, 잘라낸 후: {len(trimmed)}개")\n'
          '    response = model.invoke(trimmed, config=lf_config)\n'
          '    return {"messages": [response]}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 10 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 21',
  'code': '\n'
          'builder = StateGraph(MessagesState)\n'
          'builder.add_node("chatbot", chatbot_with_trim)\n'
          'builder.add_edge(START, "chatbot")\n'
          'builder.add_edge("chatbot", END)\n'
          '\n'
          'trim_checkpointer = InMemorySaver()\n'
          'trim_graph = builder.compile(checkpointer=trim_checkpointer)\n'
          'trim_config = {"configurable": {"thread_id": "trim-demo"}}\n'
          '\n'
          '# Build up a long conversation\n'
          'for i, msg in enumerate(["안녕하세요, 제 이름은 앨리스입니다.", "저는 서울에 살고 있습니다.", "저는 엔지니어로 일하고 있습니다.", "제 소개 내용을 정리해 '
          '주세요."]):\n'
          '    print(f"턴 {i+1}: {msg}")\n'
          '    r = trim_graph.invoke({"messages": [HumanMessage(content=msg)]}, {**trim_config, **lf_config})\n'
          '    print(f"  AI: {r[\'messages\'][-1].content[:120]}\\n")\n'
          '\n'
          '# Verify full history is preserved in checkpoint despite trimming\n'
          'full_state = trim_graph.get_state(trim_config)\n'
          'print(f"체크포인트의 총 메시지 수: {len(full_state.values[\'messages\'])}")\n'
          'print("-> trim_messages는 LLM 호출 시에만 잘라내고, 체크포인트에는 전체 이력이 보존됩니다")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 11 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 22',
  'code': '# ============================================================\n'
          '# Part 2: RemoveMessage — 체크포인트에서 메시지 영구 삭제\n'
          '# ============================================================\n'
          'from langgraph.graph import StateGraph, START, END, MessagesState\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          'from langchain.messages import HumanMessage, RemoveMessage\n'
          '\n'
          'def chatbot_node(state: MessagesState) -> dict:\n'
          '    response = model.invoke(state["messages"], config=lf_config)\n'
          '    return {"messages": [response]}\n'
          '\n'
          'def delete_old_messages(state: MessagesState) -> dict:\n'
          '    """최근 2개 메시지만 유지하고 나머지를 체크포인트에서 삭제합니다."""\n'
          '    messages = state["messages"]\n'
          '    if len(messages) > 2:\n'
          '        to_delete = messages[:-2]\n'
          '        print(f"  체크포인트에서 {len(to_delete)}개의 오래된 메시지 삭제 중")\n'
          '        return {"messages": [RemoveMessage(id=m.id) for m in to_delete]}\n'
          '    return {"messages": []}\n'
          '\n'
          'builder = StateGraph(MessagesState)\n'
          'builder.add_node("chatbot", chatbot_node)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 11 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 22',
  'code': 'builder.add_node("cleanup", delete_old_messages)\n'
          'builder.add_edge(START, "chatbot")\n'
          'builder.add_edge("chatbot", "cleanup")\n'
          'builder.add_edge("cleanup", END)\n'
          '\n'
          'rm_checkpointer = InMemorySaver()\n'
          'rm_graph = builder.compile(checkpointer=rm_checkpointer)\n'
          'rm_config = {"configurable": {"thread_id": "remove-demo"}}\n'
          '\n'
          '# Run several turns\n'
          'for msg_text in ["안녕하세요! 저는 Bob입니다.", "저는 요리를 좋아합니다.", "제 이름이 뭐였죠?"]:\n'
          '    r = rm_graph.invoke({"messages": [HumanMessage(content=msg_text)]}, {**rm_config, **lf_config})\n'
          '    state = rm_graph.get_state(rm_config)\n'
          '    print(f"사용자: {msg_text}")\n'
          '    print(f"  AI: {r[\'messages\'][-1].content[:120]}")\n'
          '    print(f"  체크포인트 내 메시지 수: {len(state.values[\'messages\'])}\\n")\n'
          '\n'
          'print("-> RemoveMessage로 오래된 메시지를 체크포인트에서 영구적으로 삭제하여 저장 공간을 절약합니다")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 12 (1/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 24',
  'code': 'import operator\n'
          'from typing import Annotated\n'
          'from typing_extensions import TypedDict\n'
          'from langgraph.graph import StateGraph, START, END\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '# --- State ---\n'
          'class PipelineState(TypedDict):\n'
          '    data: str\n'
          '    log: Annotated[list[str], operator.add]\n'
          '\n'
          '# Track how many times step_3 has been called across invocations\n'
          'attempt_count = {"step_3": 0}\n'
          '\n'
          '# --- Nodes ---\n'
          'def step_1(state: PipelineState) -> dict:\n'
          '    """Step 1: 데이터 수집 — 항상 성공합니다."""\n'
          '    print("  >> step_1 실행됨 (데이터 수집)")\n'
          '    return {\n'
          '        "data": "수집된 원시 데이터",\n'
          '        "log": ["step_1: 데이터 수집 완료"],\n'
          '    }'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 12 (2/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 24',
  'code': '\n'
          'def step_2(state: PipelineState) -> dict:\n'
          '    """Step 2: 데이터 분석 — 항상 성공합니다."""\n'
          '    print("  >> step_2 실행됨 (분석)")\n'
          '    return {\n'
          '        "data": state["data"] + " -> 분석 완료",\n'
          '        "log": ["step_2: 데이터 분석 완료"],\n'
          '    }\n'
          '\n'
          'def step_3(state: PipelineState) -> dict:\n'
          '    """Step 3: 외부 API 호출 — 첫 번째 시도에서 실패하고, 재시도 시 성공합니다."""\n'
          '    attempt_count["step_3"] += 1\n'
          '    print(f"  >> step_3 실행됨 (API 호출, 시도 {attempt_count[\'step_3\']})")\n'
          '    if attempt_count["step_3"] == 1:\n'
          '        raise ConnectionError("시뮬레이션된 API 오류!")\n'
          '    return {\n'
          '        "data": state["data"] + " -> API 결과 수신",\n'
          '        "log": ["step_3: API 호출 성공"],\n'
          '    }\n'
          '\n'
          '# --- Build graph ---\n'
          'builder = StateGraph(PipelineState)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 12 (3/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 24',
  'code': 'builder.add_node("step_1", step_1)\n'
          'builder.add_node("step_2", step_2)\n'
          'builder.add_node("step_3", step_3)\n'
          'builder.add_edge(START, "step_1")\n'
          'builder.add_edge("step_1", "step_2")\n'
          'builder.add_edge("step_2", "step_3")\n'
          'builder.add_edge("step_3", END)\n'
          '\n'
          'durable_checkpointer = InMemorySaver()\n'
          'durable_graph = builder.compile(checkpointer=durable_checkpointer)\n'
          '\n'
          'config = {"configurable": {"thread_id": "durable-1"}}\n'
          '\n'
          '# --- First invocation: step_3 will fail ---\n'
          'print("=== 1차 호출: step_3에서 실패 예상 ===")\n'
          'try:\n'
          '    durable_graph.invoke({"data": "", "log": []}, {**config, **lf_config})\n'
          'except ConnectionError as e:\n'
          '    print(f"  !! 오류 발생: {e}")\n'
          '\n'
          '# Check checkpoint state after failure\n'
          'state_after_fail = durable_graph.get_state(config)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 12 (4/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 24',
  'code': 'print(f"\\n실패 후 체크포인트:")\n'
          'print(f"  다음 실행할 노드: {state_after_fail.next}")\n'
          'print(f"  현재까지 로그: {state_after_fail.values.get(\'log\', [])}")\n'
          '\n'
          '# --- Second invocation: resumes from step_3 only ---\n'
          'print("\\n=== 2차 호출: 마지막 체크포인트에서 재개 ===")\n'
          'result = durable_graph.invoke(None, {**config, **lf_config})\n'
          'print(f"\\n최종 결과:")\n'
          'print(f"  데이터: {result[\'data\']}")\n'
          'print(f"  로그: {result[\'log\']}")\n'
          'print("\\n-> step_1, step_2는 재실행되지 않고 step_3만 재실행되었습니다 (durable execution)")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 13 (1/3)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 26',
  'code': '# =========================================================================\n'
          '# 프로덕션 체크포인터 — API 레퍼런스 (실제 실행은 의존 DB가 있을 때만)\n'
          '# =========================================================================\n'
          '# 모든 체크포인터는 BaseCheckpointSaver 인터페이스를 구현하므로\n'
          '# 그래프 측 코드는 동일하고 compile(checkpointer=...) 한 줄만 바뀝니다.\n'
          '\n'
          "reference_code = r'''\n"
          '# --- PostgreSQL (sync) ---\n'
          'from langgraph.checkpoint.postgres import PostgresSaver\n'
          '\n'
          'DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"\n'
          'with PostgresSaver.from_conn_string(DB_URI) as checkpointer:\n'
          '    checkpointer.setup()  # 최초 1회 — 스키마 생성\n'
          '    graph = builder.compile(checkpointer=checkpointer)\n'
          '\n'
          '# --- PostgreSQL (async) — 비동기 그래프 실행에 사용 ---\n'
          'from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver\n'
          '\n'
          'async with AsyncPostgresSaver.from_conn_string(DB_URI) as checkpointer:\n'
          '    await checkpointer.setup()\n'
          '    graph = builder.compile(checkpointer=checkpointer)\n'
          '    await graph.ainvoke(..., config={"configurable": {"thread_id": "1"}})'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 13 (2/3)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 26',
  'code': '\n'
          '# --- MongoDB ---\n'
          'from langgraph.checkpoint.mongodb import MongoDBSaver\n'
          '\n'
          'with MongoDBSaver.from_conn_string("localhost:27017") as checkpointer:\n'
          '    graph = builder.compile(checkpointer=checkpointer)\n'
          '\n'
          '# --- Redis ---\n'
          'from langgraph.checkpoint.redis import RedisSaver\n'
          '\n'
          'with RedisSaver.from_conn_string("redis://localhost:6379") as checkpointer:\n'
          '    graph = builder.compile(checkpointer=checkpointer)\n'
          '\n'
          '# --- Oracle ---\n'
          'from langgraph.checkpoint.oracle import OracleSaver\n'
          '\n'
          'DB_URI = "oracle://user:password@localhost:1521/?service_name=FREEPDB1"\n'
          'with OracleSaver.from_conn_string(DB_URI) as checkpointer:\n'
          '    graph = builder.compile(checkpointer=checkpointer)\n'
          "'''\n"
          '\n'
          'print(reference_code)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 13 (3/3)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 26',
  'code': 'print("패턴 요약:")\n'
          'print("  1) from_conn_string(DB_URI) 컨텍스트 매니저 진입")\n'
          'print("  2) 최초 1회 setup() 호출 → 스키마/인덱스 생성")\n'
          'print("  3) compile(checkpointer=...) 로 그래프에 연결")\n'
          'print("  4) 동기/비동기 변형: PostgresSaver vs AsyncPostgresSaver, RedisSaver vs AsyncRedisSaver, ...")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 14 (1/2)',
  'lead': '이 코드는 장기 메모리 Store 또는 저장 계층 사용을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 28',
  'code': '# =========================================================================\n'
          '# 프로덕션 Store — API 레퍼런스\n'
          '# =========================================================================\n'
          "store_reference = r'''\n"
          '# --- PostgresStore ---\n'
          'from langgraph.store.postgres import PostgresStore\n'
          '\n'
          'DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"\n'
          'with PostgresStore.from_conn_string(DB_URI) as store:\n'
          '    store.setup()\n'
          '    graph = builder.compile(store=store)\n'
          '\n'
          '# --- RedisStore ---\n'
          'from langgraph.store.redis import RedisStore\n'
          '\n'
          'with RedisStore.from_conn_string("redis://localhost:6379") as store:\n'
          '    graph = builder.compile(store=store)\n'
          '\n'
          '# --- OracleStore (vector search 내장) ---\n'
          'from langgraph.store.oracle import OracleStore\n'
          '\n'
          'DB_URI = "oracle://user:password@localhost:1521/?service_name=FREEPDB1"'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 06_persistence_and_memory',
  'title': '06_persistence_and_memory 코드 14 (2/2)',
  'lead': '이 코드는 장기 메모리 Store 또는 저장 계층 사용을 보여줍니다.',
  'file': '06_persistence_and_memory.ipynb',
  'note': 'cell 28',
  'code': 'with OracleStore.from_conn_string(DB_URI) as store:\n'
          '    graph = builder.compile(store=store)\n'
          '\n'
          '# --- Semantic search 옵션 (모든 store 공통) ---\n'
          'from langchain.embeddings import init_embeddings\n'
          'from langgraph.store.memory import InMemoryStore\n'
          '\n'
          'store = InMemoryStore(\n'
          '    index={\n'
          '        "embed": init_embeddings("openai:text-embedding-3-small"),\n'
          '        "dims": 1536,\n'
          '        "fields": ["food_preference", "$"],\n'
          '    }\n'
          ')\n'
          'memories = store.search(namespace, query="What does the user like to eat?", limit=3)\n'
          "'''\n"
          'print(store_reference)\n'
          'print("setup() 한 번이면 끝 — 이후 노드 코드는 runtime.store.put/search/aput/asearch 그대로.")'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '07_streaming.ipynb',
  'sub': '07_streaming.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '03_langgraph/07_streaming.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 01 (1/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv()\n'
          'from langchain_openai import ChatOpenAI\n'
          'from langchain.tools import tool\n'
          'from langchain.messages import HumanMessage, SystemMessage, ToolMessage, AnyMessage\n'
          'from langgraph.graph import StateGraph, START, END\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          'from typing import TypedDict, Annotated, Literal\n'
          'import operator\n'
          '\n'
          '# docs/langgraph 패치 기준 canonical 모델 ID\n'
          'model = ChatOpenAI(model="gpt-5.4-mini")\n'
          '\n'
          '@tool\n'
          'def search(query: str) -> str:\n'
          '    """정보를 검색합니다."""\n'
          '    return f"\'{query}\' 검색 결과: LangGraph는 상태 기반 에이전트를 구축하는 프레임워크입니다."\n'
          '\n'
          'tools = [search]\n'
          'tools_by_name = {t.name: t for t in tools}\n'
          'model_with_tools = model.bind_tools(tools)\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 01 (2/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 4',
  'code': 'class AgentState(TypedDict):\n'
          '    messages: Annotated[list[AnyMessage], operator.add]\n'
          '\n'
          'def llm_node(state: AgentState) -> dict:\n'
          '    return {"messages": [model_with_tools.invoke(\n'
          '        [SystemMessage(content="당신은 유용한 어시스턴트입니다.")] + state["messages"],\n'
          '        config=lf_config,\n'
          ')]}\n'
          '\n'
          'def tool_node(state: AgentState) -> dict:\n'
          '    results = []\n'
          '    for tc in state["messages"][-1].tool_calls:\n'
          '        result = tools_by_name[tc["name"]].invoke(tc["args"], config=lf_config)\n'
          '        results.append(ToolMessage(content=str(result), tool_call_id=tc["id"]))\n'
          '    return {"messages": results}\n'
          '\n'
          'def should_continue(state: AgentState) -> Literal["tools", "__end__"]:\n'
          '    return "tools" if state["messages"][-1].tool_calls else END\n'
          '\n'
          'builder = StateGraph(AgentState)\n'
          'builder.add_node("llm", llm_node)\n'
          'builder.add_node("tools", tool_node)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 01 (3/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 4',
  'code': 'builder.add_edge(START, "llm")\n'
          'builder.add_conditional_edges("llm", should_continue, ["tools", END])\n'
          'builder.add_edge("tools", "llm")\n'
          'agent = builder.compile(checkpointer=InMemorySaver())\n'
          '\n'
          'print("스트리밍 데모를 위한 에이전트 준비 완료")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          '    print(f"LangSmith tracing ON — project: {project}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 03',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 8',
  'code': 'config = {"configurable": {"thread_id": "stream-values"}}\n'
          'print("=== stream_mode=\'values\' ===")\n'
          'for state in agent.stream(\n'
          '    {"messages": [HumanMessage(content="LangGraph 정보를 검색해 주세요")]},\n'
          '    {**config, **lf_config}, stream_mode="values",\n'
          '):\n'
          '    msg = state["messages"][-1]\n'
          '    print(f"  [{type(msg).__name__}] {str(msg.content)[:100]}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 04',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 10',
  'code': 'config = {"configurable": {"thread_id": "stream-updates"}}\n'
          'print("=== stream_mode=\'updates\' ===")\n'
          'for chunk in agent.stream(\n'
          '    {"messages": [HumanMessage(content="LangGraph 정보를 검색해 주세요")]},\n'
          '    {**config, **lf_config}, stream_mode="updates",\n'
          '):\n'
          '    for node_name, update in chunk.items():\n'
          '        print(f"\\n  [{node_name}]")\n'
          '        for msg in update.get("messages", []):\n'
          "            if hasattr(msg, 'tool_calls') and msg.tool_calls:\n"
          '                for tc in msg.tool_calls:\n'
          '                    print(f"    Tool: {tc[\'name\']}({tc[\'args\']})")\n'
          '            elif msg.content:\n'
          '                print(f"    {msg.content[:150]}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 05',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 12',
  'code': 'config = {"configurable": {"thread_id": "stream-messages"}}\n'
          'print("=== stream_mode=\'messages\' ===")\n'
          'print("응답: ", end="")\n'
          'for msg, metadata in agent.stream(\n'
          '    {"messages": [HumanMessage(content="LangGraph란 무엇인가요? 간단히 답해 주세요.")]},\n'
          '    {**config, **lf_config}, stream_mode="messages",\n'
          '):\n'
          '    if msg.content and metadata.get("langgraph_node") == "llm":\n'
          '        print(msg.content, end="", flush=True)\n'
          'print()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 06',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 14',
  'code': 'config = {"configurable": {"thread_id": "stream-multi"}}\n'
          'print("=== 여러 스트리밍 모드 동시 사용 ===")\n'
          'for event in agent.stream(\n'
          '    {"messages": [HumanMessage(content="Python을 검색해 주세요")]},\n'
          '    {**config, **lf_config}, stream_mode=["updates", "messages"],\n'
          '):\n'
          '    kind = event[0] if isinstance(event, tuple) else "unknown"\n'
          '    print(f"  [{kind}] 수신됨")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 07 (1/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 16',
  'code': 'from langgraph.config import get_stream_writer\n'
          '\n'
          '# --- 커스텀 스트리밍을 사용하는 간단한 그래프 정의 ---\n'
          'class CustomState(TypedDict):\n'
          '    topic: str\n'
          '    result: str\n'
          '\n'
          'def research_node(state: CustomState) -> dict:\n'
          '    """research_node: get_stream_writer()로 중간 진행 상황을 스트리밍합니다."""\n'
          '    writer = get_stream_writer()\n'
          '\n'
          '    # 1단계: 검색 시작 알림\n'
          '    writer({"step": 1, "status": "검색 중", "detail": f"\'{state[\'topic\']}\' 검색 중 ..."})\n'
          '\n'
          '    # 2단계: 분석 중 알림\n'
          '    writer({"step": 2, "status": "분석 중", "detail": "검색 결과 분석 중 ..."})\n'
          '\n'
          '    # 3단계: 완료 알림\n'
          '    writer({"step": 3, "status": "완료", "detail": "조사 완료."})\n'
          '\n'
          '    return {"result": f"\'{state[\'topic\']}\'에 대한 조사가 완료되었습니다."}\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 07 (2/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 16',
  'code': 'custom_builder = StateGraph(CustomState)\n'
          'custom_builder.add_node("research", research_node)\n'
          'custom_builder.add_edge(START, "research")\n'
          'custom_builder.add_edge("research", END)\n'
          'custom_graph = custom_builder.compile()\n'
          '\n'
          '# --- stream_mode="custom" 으로 실행 ---\n'
          'print("=== stream_mode=\'custom\' ===")\n'
          'for chunk in custom_graph.stream(\n'
          '    {"topic": "LangGraph 스트리밍"},\n'
          '    stream_mode="custom",\n'
          '    config=lf_config,\n'
          '):\n'
          '    print(f"  커스텀 이벤트: {chunk}")\n'
          '\n'
          'print("\\n--- updates + custom 동시 사용 ---")\n'
          'for mode, chunk in custom_graph.stream(\n'
          '    {"topic": "LangGraph 스트리밍"},\n'
          '    stream_mode=["updates", "custom"],\n'
          '    config=lf_config,\n'
          '):\n'
          '    if mode == "custom":'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 07 (3/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 16',
  'code': '        print(f"  [custom]  {chunk}")\n    else:\n        print(f"  [updates] {chunk}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 08 (1/2)',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 18',
  'code': '# 앞서 만든 agent에 version="v2"를 그대로 적용\n'
          'config = {"configurable": {"thread_id": "stream-v2"}}\n'
          'print("=== version=\'v2\' + multi-mode ===")\n'
          'for chunk in agent.stream(\n'
          '    {"messages": [HumanMessage(content="LangGraph 정보를 검색해 주세요")]},\n'
          '    {**config, **lf_config},\n'
          '    stream_mode=["updates", "messages"],\n'
          '    version="v2",\n'
          '):\n'
          '    # v1에서는 (mode, payload) tuple — v2는 항상 StreamPart dict\n'
          '    kind = chunk["type"]\n'
          '    ns   = chunk["ns"]\n'
          '    data = chunk["data"]\n'
          '\n'
          '    if kind == "updates":\n'
          '        for node, upd in data.items():\n'
          '            msgs = upd.get("messages", [])\n'
          '            if msgs:\n'
          '                m = msgs[-1]\n'
          '                tag = "tool_call" if getattr(m, \'tool_calls\', None) else type(m).__name__\n'
          '                print(f"  [updates/{node}] {tag}")\n'
          '    elif kind == "messages":'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 08 (2/2)',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 18',
  'code': '        msg, meta = data\n'
          '        if msg.content and meta.get("langgraph_node") == "llm":\n'
          '            # 토큰 단위 출력\n'
          '            print(msg.content, end="", flush=True)\n'
          'print()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 09',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 22',
  'code': '# chunk_position == "last" 라이브 데모 — 앞서 만든 agent에 그대로 적용\n'
          'config = {"configurable": {"thread_id": "stream-chunk-position"}}\n'
          'print("=== chunk_position 감지 (v2 + messages) ===")\n'
          'print("응답: ", end="")\n'
          'for chunk in agent.stream(\n'
          '    {"messages": [HumanMessage(content="LangGraph가 뭔지 한 문장으로만 알려줘.")]},\n'
          '    {**config, **lf_config},\n'
          '    stream_mode="messages",\n'
          '    version="v2",\n'
          '):\n'
          '    if chunk["type"] != "messages":\n'
          '        continue\n'
          '    msg, meta = chunk["data"]\n'
          '    if not msg.content or meta.get("langgraph_node") != "llm":\n'
          '        continue\n'
          '    print(msg.content, end="", flush=True)\n'
          '    if meta.get("chunk_position") == "last":\n'
          '        print("\\n  [last chunk 도착 — 메시지 스트리밍 완료]")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 10',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 24',
  'code': '# GraphOutput 라이브 데모 — agent에 invoke(..., version="v2")\n'
          'config = {"configurable": {"thread_id": "invoke-v2"}}\n'
          'result = agent.invoke(\n'
          '    {"messages": [HumanMessage(content="LangGraph 정보를 검색해 주세요")]},\n'
          '    {**config, **lf_config},\n'
          '    version="v2",\n'
          ')\n'
          '\n'
          'print(f"type(result):    {type(result).__name__}")\n'
          'print(f"interrupts:      {len(result.interrupts)}개")\n'
          'print(f"메시지 수:        {len(result.value[\'messages\'])}")\n'
          'print(f"마지막 응답:      {result.value[\'messages\'][-1].content[:120]}")\n'
          '\n'
          '# dict 스타일 접근 (호환용, deprecated)\n'
          'print(f"\\ndict 스타일 호환: result[\'messages\'] 길이={len(result[\'messages\'])}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 11 (1/2)',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 26',
  'code': '# Event Streaming v3 패턴 — 로컬 설치 버전과 무관하게 안전하게 예시를 출력합니다.\n'
          'from importlib.metadata import version\n'
          '\n'
          'print("설치된 langgraph:", version("langgraph"))\n'
          'print("필요 버전: langgraph>=1.2.0")\n'
          '\n'
          "example = r'''\n"
          '# 1) 기본 사용\n'
          'stream = graph.stream_events(\n'
          '    {"messages": [{"role": "user", "content": "42 * 17은?"}]},\n'
          '    version="v3",\n'
          ')\n'
          '\n'
          'for message in stream.messages:\n'
          '    for token in message.text:\n'
          '        print(token, end="", flush=True)\n'
          '\n'
          'for snapshot in stream.values:\n'
          '    print(snapshot)\n'
          '\n'
          'final_state = stream.output\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 07_streaming',
  'title': '07_streaming 코드 11 (2/2)',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '07_streaming.ipynb',
  'note': 'cell 26',
  'code': '# 2) interrupt 이후 재개 — checkpointer + thread_id 필요\n'
          'from langgraph.types import Command\n'
          '\n'
          'stream = graph.stream_events(input_data, version="v3")\n'
          'for message in stream.messages:\n'
          '    print(message.text)\n'
          '\n'
          'if stream.interrupted:\n'
          '    print(stream.interrupts)\n'
          '    stream = graph.stream_events(\n'
          '        Command(resume={"decisions": [{"type": "approve"}]}),\n'
          '        version="v3",\n'
          '    )\n'
          "'''\n"
          'print(example)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '08_interrupts_and_time_travel.ipynb',
  'sub': '08_interrupts_and_time_travel.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '03_langgraph/08_interrupts_and_time_travel.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          'from langchain_openai import ChatOpenAI\n'
          '\n'
          '# docs/langgraph 패치 기준 canonical 모델 ID\n'
          'model = ChatOpenAI(model="gpt-5.4-mini")\n'
          'print("모델 준비 완료")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          '    print(f"LangSmith tracing ON \\u2014 project: {project}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON \\u2014 {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 03 (1/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 7',
  'code': 'from langgraph.graph import StateGraph, START, END\n'
          'from langgraph.types import interrupt, Command\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          'from typing import TypedDict\n'
          '\n'
          '\n'
          'class ReviewState(TypedDict):\n'
          '    document: str\n'
          '    approved: bool\n'
          '    final_result: str\n'
          '\n'
          '\n'
          'def draft_document(state: ReviewState) -> dict:\n'
          '    return {\n'
          '        "document": f"초안: {state.get(\'document\', \'주제\')}에 대한 중요 문서"\n'
          '    }\n'
          '\n'
          '\n'
          'def human_review(state: ReviewState) -> dict:\n'
          '    # 사람의 승인을 기다립니다\n'
          '    decision = interrupt(\n'
          '        {'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 03 (2/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 7',
  'code': '            "document": state["document"],\n'
          '            "question": "이 문서를 승인하시겠습니까? (yes/no)"\n'
          '        }\n'
          '    )\n'
          '\n'
          '    return {\n'
          '        "approved": decision == "yes"\n'
          '    }\n'
          '\n'
          '\n'
          'def finalize(state: ReviewState) -> dict:\n'
          '    if state["approved"]:\n'
          '        return {\n'
          '            "final_result": f"승인됨: {state[\'document\']}"\n'
          '        }\n'
          '\n'
          '    return {\n'
          '        "final_result": f"거절됨: {state[\'document\']}"\n'
          '    }\n'
          '\n'
          '\n'
          'builder = StateGraph(ReviewState)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 03 (3/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 7',
  'code': '\n'
          'builder.add_node("draft", draft_document)\n'
          'builder.add_node("review", human_review)\n'
          'builder.add_node("finalize", finalize)\n'
          '\n'
          'builder.add_edge(START, "draft")\n'
          'builder.add_edge("draft", "review")\n'
          'builder.add_edge("review", "finalize")\n'
          'builder.add_edge("finalize", END)\n'
          '\n'
          'graph = builder.compile(\n'
          '    checkpointer=InMemorySaver()\n'
          ')\n'
          '\n'
          'config = {\n'
          '    "configurable": {\n'
          '        "thread_id": "review-1"\n'
          '    }\n'
          '}\n'
          '\n'
          '# Step 1: 실행 → review 노드에서 중단\n'
          'result = graph.invoke('},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 03 (4/4)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 7',
  'code': '    {\n'
          '        "document": "AI 안전성"\n'
          '    },\n'
          '    {**config, **lf_config}\n'
          ')\n'
          '\n'
          'print("Step 1 - review에서 중단됨")\n'
          '\n'
          'state = graph.get_state(config)\n'
          '\n'
          'print(f"  다음 노드: {state.next}")\n'
          'print(f"  인터럽트 값: {state.tasks}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 04',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 9',
  'code': '# Step 2: 승인하여 재개\n'
          '\n'
          'result = graph.invoke(\n'
          '    Command(resume="yes"),\n'
          '    {**config, **lf_config}\n'
          ')\n'
          '\n'
          'print(f"Step 2 - 승인으로 재개됨")\n'
          'print(f"  결과: {result[\'final_result\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 05 (1/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 11',
  'code': 'from langgraph.func import entrypoint, task\n'
          '\n'
          '@task\n'
          'def generate_proposal(topic: str) -> str:\n'
          '    response = model.invoke(f"다음에 대한 한 문장 제안을 작성해주세요: {topic}", config=lf_config)\n'
          '    return response.content\n'
          '\n'
          '@entrypoint(checkpointer=InMemorySaver())\n'
          'def proposal_workflow(topic: str) -> dict:\n'
          '    proposal = generate_proposal(topic).result()\n'
          '\n'
          '    # 사람의 승인 대기\n'
          '    approval = interrupt({\n'
          '        "proposal": proposal,\n'
          '        "action": "승인 또는 거절하세요"\n'
          '    })\n'
          '\n'
          '    return {\n'
          '        "proposal": proposal,\n'
          '        "approved": approval,\n'
          '    }\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 05 (2/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 11',
  'code': 'config = {"configurable": {"thread_id": "proposal-1"}}\n'
          '\n'
          '# 실행 → 중단\n'
          'result = proposal_workflow.invoke("재생 에너지", {**config, **lf_config})\n'
          'print("제안 워크플로 중단됨")\n'
          '\n'
          '# 재개\n'
          'result = proposal_workflow.invoke(Command(resume="승인"), {**config, **lf_config})\n'
          'print(f"최종: {result}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 06 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 14',
  'code': 'from typing import Literal, TypedDict\n'
          'from langgraph.graph import StateGraph, START, END\n'
          'from langgraph.types import interrupt, Command\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'class ApprovalState(TypedDict):\n'
          '    action_details: str\n'
          '    outcome: str\n'
          '\n'
          'def approval_node(state: ApprovalState) -> Command[Literal["proceed", "cancel"]]:\n'
          '    decision = interrupt({\n'
          '        "question": "Approve this action?",\n'
          '        "details": state["action_details"],\n'
          '    })\n'
          '    return Command(goto="proceed" if decision else "cancel")\n'
          '\n'
          'def proceed(state: ApprovalState) -> dict:\n'
          '    return {"outcome": f"실행됨: {state[\'action_details\']}"}\n'
          '\n'
          'def cancel(state: ApprovalState) -> dict:\n'
          '    return {"outcome": f"취소됨: {state[\'action_details\']}"}\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 06 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 14',
  'code': 'b = StateGraph(ApprovalState)\n'
          'b.add_node("approval", approval_node)\n'
          'b.add_node("proceed", proceed)\n'
          'b.add_node("cancel", cancel)\n'
          'b.add_edge(START, "approval")\n'
          'b.add_edge("proceed", END)\n'
          'b.add_edge("cancel", END)\n'
          'approval_graph = b.compile(checkpointer=InMemorySaver())\n'
          '\n'
          '# --- 승인 케이스 ---\n'
          'cfg_yes = {"configurable": {"thread_id": "approval-yes"}}\n'
          'out = approval_graph.invoke({"action_details": "결제 처리 $100"}, {**cfg_yes, **lf_config}, version="v2")\n'
          'print(f"[승인 요청] interrupts={len(out.interrupts)}, value={out.interrupts[0].value}")\n'
          'out = approval_graph.invoke(Command(resume=True), {**cfg_yes, **lf_config}, version="v2")\n'
          'print(f"  resume=True  → {out.value[\'outcome\']}")\n'
          '\n'
          '# --- 거부 케이스 ---\n'
          'cfg_no = {"configurable": {"thread_id": "approval-no"}}\n'
          'approval_graph.invoke({"action_details": "결제 처리 $999"}, {**cfg_no, **lf_config}, version="v2")\n'
          'out = approval_graph.invoke(Command(resume=False), {**cfg_no, **lf_config}, version="v2")\n'
          'print(f"  resume=False → {out.value[\'outcome\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 07 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 16',
  'code': 'class ReviewEditState(TypedDict):\n'
          '    topic: str\n'
          '    generated_text: str\n'
          '\n'
          'def generate(state: ReviewEditState) -> dict:\n'
          '    return {"generated_text": f"AI 초안: {state[\'topic\']}에 대한 짧은 글입니다."}\n'
          '\n'
          'def review_edit(state: ReviewEditState) -> dict:\n'
          '    edited = interrupt({\n'
          '        "instruction": "Review and edit this content",\n'
          '        "content": state["generated_text"],\n'
          '    })\n'
          '    return {"generated_text": edited}\n'
          '\n'
          'b = StateGraph(ReviewEditState)\n'
          'b.add_node("generate", generate)\n'
          'b.add_node("review_edit", review_edit)\n'
          'b.add_edge(START, "generate")\n'
          'b.add_edge("generate", "review_edit")\n'
          'b.add_edge("review_edit", END)\n'
          'review_graph = b.compile(checkpointer=InMemorySaver())\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 07 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 16',
  'code': 'cfg = {"configurable": {"thread_id": "review-edit-1"}}\n'
          'out = review_graph.invoke({"topic": "LangGraph"}, {**cfg, **lf_config}, version="v2")\n'
          'print(f"[검토 요청] 원본: {out.interrupts[0].value[\'content\']}")\n'
          '\n'
          '# 사람이 텍스트를 편집해서 resume\n'
          'out = review_graph.invoke(\n'
          '    Command(resume="사람이 수정한 글: LangGraph로 상태 기반 워크플로를 만들 수 있다."),\n'
          '    {**cfg, **lf_config},\n'
          '    version="v2",\n'
          ')\n'
          'print(f"  resume=str  → state.generated_text = {out.value[\'generated_text\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 08 (1/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 18',
  'code': 'from langchain.tools import tool\n'
          '\n'
          '@tool\n'
          'def send_email(to: str, subject: str, body: str) -> str:\n'
          '    """Send an email to a recipient (sample tool with interrupt)."""\n'
          '    response = interrupt({\n'
          '        "action": "send_email",\n'
          '        "to": to,\n'
          '        "subject": subject,\n'
          '        "body": body,\n'
          '        "message": "Approve sending this email?",\n'
          '    })\n'
          '\n'
          '    if response.get("action") == "approve":\n'
          '        # 사람이 일부 필드만 편집했을 수 있음 → 원본 값과 덮어쓰기\n'
          '        final_to      = response.get("to", to)\n'
          '        final_subject = response.get("subject", subject)\n'
          '        final_body    = response.get("body", body)\n'
          '        return f"Email sent to {final_to} (subject={final_subject!r})"\n'
          '    return "Email cancelled by user"\n'
          '\n'
          '# tool을 그래프 노드로 직접 감싸 데모'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 08 (2/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 18',
  'code': 'class ToolState(TypedDict):\n'
          '    args: dict\n'
          '    result: str\n'
          '\n'
          'def email_node(state: ToolState) -> dict:\n'
          '    result = send_email.invoke(state["args"])\n'
          '    return {"result": result}\n'
          '\n'
          'b = StateGraph(ToolState)\n'
          'b.add_node("email", email_node)\n'
          'b.add_edge(START, "email")\n'
          'b.add_edge("email", END)\n'
          'tool_graph = b.compile(checkpointer=InMemorySaver())\n'
          '\n'
          'cfg = {"configurable": {"thread_id": "tool-interrupt-1"}}\n'
          'out = tool_graph.invoke(\n'
          '    {"args": {"to": "alice@example.com", "subject": "Hi", "body": "Hello!"}},\n'
          '    {**cfg, **lf_config},\n'
          '    version="v2",\n'
          ')\n'
          'print(f"[Tool 승인 요청] {out.interrupts[0].value[\'message\']}")\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 08 (3/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 18',
  'code': '# 승인 + subject 편집을 동시에\n'
          'out = tool_graph.invoke(\n'
          '    Command(resume={"action": "approve", "subject": "Updated subject"}),\n'
          '    {**cfg, **lf_config},\n'
          '    version="v2",\n'
          ')\n'
          'print(f"  resume=dict → {out.value[\'result\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 09 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 20',
  'code': 'class AgeState(TypedDict):\n'
          '    age: int\n'
          '\n'
          'def get_age_node(state: AgeState) -> dict:\n'
          '    prompt = "나이를 입력하세요 (양의 정수)."\n'
          '    while True:\n'
          '        answer = interrupt(prompt)\n'
          '        if isinstance(answer, int) and answer > 0:\n'
          '            break\n'
          '        prompt = f"\'{answer}\'은(는) 유효하지 않습니다. 양의 정수를 다시 입력하세요."\n'
          '    return {"age": answer}\n'
          '\n'
          'b = StateGraph(AgeState)\n'
          'b.add_node("ask_age", get_age_node)\n'
          'b.add_edge(START, "ask_age")\n'
          'b.add_edge("ask_age", END)\n'
          'age_graph = b.compile(checkpointer=InMemorySaver())\n'
          '\n'
          'cfg = {"configurable": {"thread_id": "validation-1"}}\n'
          'out = age_graph.invoke({"age": 0}, {**cfg, **lf_config}, version="v2")\n'
          'print(f"  ask    : {out.interrupts[0].value}")\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 09 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 20',
  'code': '# 잘못된 값 — 음수\n'
          'out = age_graph.invoke(Command(resume=-5), {**cfg, **lf_config}, version="v2")\n'
          'print(f"  -5     : {out.interrupts[0].value}")\n'
          '\n'
          '# 잘못된 값 — 문자열\n'
          'out = age_graph.invoke(Command(resume="abc"), {**cfg, **lf_config}, version="v2")\n'
          'print(f"  \'abc\'  : {out.interrupts[0].value}")\n'
          '\n'
          '# 올바른 값\n'
          'out = age_graph.invoke(Command(resume=30), {**cfg, **lf_config}, version="v2")\n'
          'print(f"  30     : 통과 → state.age = {out.value[\'age\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 10 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 23',
  'code': 'from langgraph.graph import StateGraph, START, END, MessagesState\n'
          'from langchain.messages import HumanMessage\n'
          '\n'
          'def chatbot(state: MessagesState) -> dict:\n'
          '    response = model.invoke(state["messages"], config=lf_config)\n'
          '    return {"messages": [response]}\n'
          '\n'
          'builder = StateGraph(MessagesState)\n'
          'builder.add_node("chatbot", chatbot)\n'
          'builder.add_edge(START, "chatbot")\n'
          'builder.add_edge("chatbot", END)\n'
          '\n'
          'graph = builder.compile(checkpointer=InMemorySaver())\n'
          '\n'
          'config = {"configurable": {"thread_id": "timetravel-1"}}\n'
          '\n'
          '# 3번의 대화\n'
          'graph.invoke({"messages": [HumanMessage(content="제가 좋아하는 색은 파랑입니다.")]}, {**config, **lf_config})\n'
          'graph.invoke({"messages": [HumanMessage(content="제가 좋아하는 음식은 피자입니다.")]}, {**config, **lf_config})\n'
          'graph.invoke({"messages": [HumanMessage(content="저는 서울에 살고 있습니다.")]}, {**config, **lf_config})\n'
          '\n'
          '# 히스토리에서 특정 체크포인트 선택'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 10 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 23',
  'code': 'history = list(graph.get_state_history(config))\n'
          'print(f"전체 체크포인트 수: {len(history)}")\n'
          '\n'
          '# 두 번째 대화 시점으로 되돌아가기 (REPLAY 데모)\n'
          'target = history[2]  # older checkpoint\n'
          'target_config = target.config\n'
          'print(f"\\n[Replay] 체크포인트={target_config[\'configurable\'][\'checkpoint_id\'][:20]}...")\n'
          '\n'
          '# 그 시점에서 새로운 대화 시작\n'
          'result = graph.invoke(\n'
          '    {"messages": [HumanMessage(content="제가 좋아하는 음식은 뭔가요?")]},\n'
          '    {**target_config, **lf_config},\n'
          ')\n'
          'print(f"응답: {result[\'messages\'][-1].content[:200]}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 11 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 25',
  'code': 'from typing import TypedDict\n'
          'from langgraph.graph import StateGraph, START, END\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          'class JokeState(TypedDict):\n'
          '    topic: str\n'
          '    joke: str\n'
          '\n'
          'def generate_topic(state: JokeState) -> dict:\n'
          '    """간단한 토픽 생성 (LLM 호출 비용을 절약하려고 결정적 값을 사용)"""\n'
          '    return {"topic": "cats"}\n'
          '\n'
          'def write_joke(state: JokeState) -> dict:\n'
          '    response = model.invoke(\n'
          '        f"{state[\'topic\']}에 대한 한 줄 농담을 만들어주세요.",\n'
          '        config=lf_config,\n'
          '    )\n'
          '    return {"joke": response.content}\n'
          '\n'
          'b = StateGraph(JokeState)\n'
          'b.add_node("generate_topic", generate_topic)\n'
          'b.add_node("write_joke", write_joke)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 11 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 25',
  'code': 'b.add_edge(START, "generate_topic")\n'
          'b.add_edge("generate_topic", "write_joke")\n'
          'b.add_edge("write_joke", END)\n'
          'joke_graph = b.compile(checkpointer=InMemorySaver())\n'
          '\n'
          'cfg = {"configurable": {"thread_id": "joke-replay"}}\n'
          'first_run = joke_graph.invoke({"topic": "", "joke": ""}, {**cfg, **lf_config})\n'
          'print(f"원본:  topic={first_run[\'topic\']!r}, joke={first_run[\'joke\'][:80]!r}")\n'
          '\n'
          '# write_joke 직전 체크포인트 찾기\n'
          'history = list(joke_graph.get_state_history(cfg))\n'
          'before_joke = next(s for s in history if s.next == ("write_joke",))\n'
          'print(f"\\nbefore_joke 체크포인트: next={before_joke.next}, topic={before_joke.values[\'topic\']!r}")\n'
          '\n'
          '# Replay — generate_topic 결과는 재사용, write_joke만 재실행\n'
          'replay = joke_graph.invoke(None, {**before_joke.config, **lf_config})\n'
          'print(f"\\nReplay: topic={replay[\'topic\']!r} (재사용), joke={replay[\'joke\'][:80]!r} (재생성)")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 12',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 27',
  'code': '# before_joke 체크포인트에서 topic을 바꾼 fork branch 생성\n'
          'fork_config = joke_graph.update_state(\n'
          '    before_joke.config,\n'
          '    values={"topic": "chickens"},\n'
          '    as_node="generate_topic",  # 이 update를 generate_topic이 만든 것으로 간주 → write_joke부터 실행\n'
          ')\n'
          'print(f"fork_config checkpoint_id: {fork_config[\'configurable\'][\'checkpoint_id\'][:20]}...")\n'
          '\n'
          '# Fork 실행 — 새 branch에서 write_joke만 실행\n'
          'fork_result = joke_graph.invoke(None, {**fork_config, **lf_config})\n'
          'print(f"\\nFork:  topic={fork_result[\'topic\']!r} (수정됨), joke={fork_result[\'joke\'][:80]!r}")\n'
          '\n'
          '# 원본 thread는 그대로 유지\n'
          'original = joke_graph.get_state(cfg)\n'
          'print(f"\\n원본 유지: topic={original.values[\'topic\']!r}, joke={original.values[\'joke\'][:80]!r}")\n'
          'print("→ update_state는 thread를 롤백하지 않고, 새 branch를 만들어 갈라집니다.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 13',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 29',
  'code': '# 현재 상태에 정보 추가\n'
          'from langchain.messages import AIMessage\n'
          '\n'
          'graph.update_state(config, {\n'
          '    "messages": [AIMessage(content="(업데이트: 사용자는 고양이도 좋아합니다.)")]\n'
          '})\n'
          '\n'
          'result = graph.invoke(\n'
          '    {"messages": [HumanMessage(content="제 선호에 대해 뭘 알고 있나요?")]},\n'
          '    {**config, **lf_config}\n'
          ')\n'
          'print("상태 업데이트 후:", result["messages"][-1].content[:200])'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 14 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 31',
  'code': '# 8.2절에서 만든 리뷰 그래프를 v2로 다시 호출\n'
          'from langgraph.graph import StateGraph, START, END\n'
          'from langgraph.types import interrupt, Command\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          'from typing import TypedDict\n'
          '\n'
          'class ReviewState(TypedDict):\n'
          '    document: str\n'
          '    approved: bool\n'
          '    final_result: str\n'
          '\n'
          'def draft(state):   return {"document": f"초안: {state.get(\'document\',\'주제\')}"}\n'
          'def review(state):  return {"approved": interrupt({"q": "승인?"}) == "yes"}\n'
          'def finalize(state):\n'
          '    verdict = "승인" if state["approved"] else "거절"\n'
          '    return {"final_result": f"{verdict}: {state[\'document\']}"}\n'
          '\n'
          'b = StateGraph(ReviewState)\n'
          'b.add_node("draft", draft); b.add_node("review", review); b.add_node("finalize", finalize)\n'
          'b.add_edge(START, "draft"); b.add_edge("draft", "review"); b.add_edge("review", "finalize"); '
          'b.add_edge("finalize", END)\n'
          'v2_graph = b.compile(checkpointer=InMemorySaver())\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 14 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 31',
  'code': 'cfg = {"configurable": {"thread_id": "v2-review"}}\n'
          '\n'
          '# Step 1: v2로 실행 → GraphOutput 반환\n'
          'out = v2_graph.invoke({"document": "AI 안전성"}, {**cfg, **lf_config}, version="v2")\n'
          '\n'
          'print(f"type: {type(out).__name__}")\n'
          'print(f"interrupts: {len(out.interrupts)}개")\n'
          '\n'
          '# v2는 인터럽트 분기가 한 줄\n'
          'if out.interrupts:\n'
          '    for iq in out.interrupts:\n'
          '        print(f"  질문: {iq.value}")\n'
          'else:\n'
          '    print(f"  완료 state: {out.value}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 08_interrupts_and_time_travel',
  'title': '08_interrupts_and_time_travel 코드 15',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '08_interrupts_and_time_travel.ipynb',
  'note': 'cell 32',
  'code': '# Step 2: resume도 v2로 — 최종 state는 .value\n'
          'out = v2_graph.invoke(Command(resume="yes"), {**cfg, **lf_config}, version="v2")\n'
          '\n'
          'print(f"interrupts: {len(out.interrupts)}개")\n'
          'print(f"최종: {out.value[\'final_result\']}")\n'
          '\n'
          '# v1 호환용 dict-스타일 접근도 여전히 동작 (deprecated)\n'
          '# 마이그레이션 중 섞여 있어도 깨지지 않음\n'
          'print(f"dict 접근(호환): {out[\'final_result\']}")'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '09_subgraphs.ipynb',
  'sub': '09_subgraphs.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '03_langgraph/09_subgraphs.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          'from langchain_openai import ChatOpenAI\n'
          '# docs/langgraph 패치 기준 canonical 모델 ID\n'
          'model = ChatOpenAI(model="gpt-5.4-mini")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    project = os.environ.get("LANGSMITH_PROJECT", "default")\n'
          '    print(f"LangSmith tracing ON \\u2014 project: {project}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON \\u2014 {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 03 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 8',
  'code': 'from langgraph.graph import StateGraph, START, END\n'
          'from typing import TypedDict, Annotated\n'
          'import operator\n'
          '\n'
          '# === Subgraph 1: Text Analysis ===\n'
          'class AnalysisState(TypedDict):\n'
          '    text: str\n'
          '    word_count: int\n'
          '    char_count: int\n'
          '\n'
          'def count_words(state: AnalysisState) -> dict:\n'
          '    return {"word_count": len(state["text"].split())}\n'
          '\n'
          'def count_chars(state: AnalysisState) -> dict:\n'
          '    return {"char_count": len(state["text"])}\n'
          '\n'
          'analysis_builder = StateGraph(AnalysisState)\n'
          'analysis_builder.add_node("words", count_words)\n'
          'analysis_builder.add_node("chars", count_chars)\n'
          'analysis_builder.add_edge(START, "words")\n'
          'analysis_builder.add_edge("words", "chars")\n'
          'analysis_builder.add_edge("chars", END)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 03 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 8',
  'code': 'analysis_subgraph = analysis_builder.compile()\n'
          '\n'
          '# Test subgraph independently\n'
          'result = analysis_subgraph.invoke({"text": "LangGraph에서 보내는 인사"}, config=lf_config)\n'
          'print(f"서브그래프 테스트: 단어={result[\'word_count\']}, 문자={result[\'char_count\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 04 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 10',
  'code': '# === Parent Graph: Text Pipeline ===\n'
          '\n'
          'class PipelineState(TypedDict):\n'
          '    text: str\n'
          '    word_count: int\n'
          '    char_count: int\n'
          '    summary: str\n'
          '\n'
          '\n'
          'def create_summary(state: PipelineState) -> dict:\n'
          '    return {\n'
          '        "summary": f"텍스트는 {state[\'word_count\']}개의 단어와 {state[\'char_count\']}개의 문자를 포함합니다."\n'
          '    }\n'
          '\n'
          '\n'
          'parent_builder = StateGraph(PipelineState)\n'
          '\n'
          '# Add subgraph as a node (shared keys: text, word_count, char_count)\n'
          'parent_builder.add_node("analyze", analysis_subgraph)\n'
          'parent_builder.add_node("summarize", create_summary)\n'
          '\n'
          'parent_builder.add_edge(START, "analyze")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 04 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 10',
  'code': 'parent_builder.add_edge("analyze", "summarize")\n'
          'parent_builder.add_edge("summarize", END)\n'
          '\n'
          'pipeline = parent_builder.compile()\n'
          '\n'
          'result = pipeline.invoke(\n'
          '    {\n'
          '        "text": "LangGraph는 강력한 상태 기반 에이전트 워크플로를 가능하게 합니다"\n'
          '    },\n'
          '    config=lf_config\n'
          ')\n'
          '\n'
          'print(f"요약: {result[\'summary\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 05 (1/7)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 12',
  'code': 'from typing import TypedDict\n'
          'from langgraph.graph import StateGraph, START, END\n'
          '\n'
          '\n'
          '# ── Step 1: 서브그래프 정의 (자체 상태 스키마: SubState) ──\n'
          'class SubState(TypedDict):\n'
          '    log_entry: str\n'
          '    sentiment: str\n'
          '    confidence: float\n'
          '\n'
          '\n'
          'def analyze_sentiment(state: SubState) -> dict:\n'
          '    """간단한 규칙 기반 감성 분석"""\n'
          '    text = state["log_entry"].lower()\n'
          '\n'
          '    positive_words = {\n'
          '        "good", "great", "excellent", "happy", "love", "amazing", "wonderful"\n'
          '    }\n'
          '\n'
          '    negative_words = {\n'
          '        "bad", "terrible", "awful", "hate", "poor", "horrible", "sad"\n'
          '    }'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 05 (2/7)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 12',
  'code': '\n'
          '    pos = sum(1 for w in text.split() if w in positive_words)\n'
          '    neg = sum(1 for w in text.split() if w in negative_words)\n'
          '\n'
          '    total = pos + neg\n'
          '\n'
          '    if total == 0:\n'
          '        return {"sentiment": "neutral", "confidence": 0.5}\n'
          '\n'
          '    elif pos > neg:\n'
          '        return {"sentiment": "positive", "confidence": round(pos / total, 2)}\n'
          '\n'
          '    else:\n'
          '        return {"sentiment": "negative", "confidence": round(neg / total, 2)}\n'
          '\n'
          '\n'
          'sub_builder = StateGraph(SubState)\n'
          '\n'
          'sub_builder.add_node("analyze_sentiment", analyze_sentiment)\n'
          'sub_builder.add_edge(START, "analyze_sentiment")\n'
          'sub_builder.add_edge("analyze_sentiment", END)\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 05 (3/7)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 12',
  'code': 'sentiment_subgraph = sub_builder.compile()\n'
          '\n'
          '\n'
          '# 서브그래프 단독 테스트\n'
          'sub_result = sentiment_subgraph.invoke(\n'
          '    {"log_entry": "The product is great and amazing"},\n'
          '    config=lf_config\n'
          ')\n'
          '\n'
          'print(\n'
          '    f"[서브그래프 단독 테스트] sentiment={sub_result[\'sentiment\']}, confidence={sub_result[\'confidence\']}"\n'
          ')\n'
          '\n'
          '\n'
          '# ── Step 2: 부모 그래프 정의 (다른 상태 스키마: ParentState) ──\n'
          'class ParentState(TypedDict):\n'
          '    customer_name: str\n'
          '    feedback_text: str\n'
          '    analysis_result: str\n'
          '\n'
          '\n'
          '# ── Step 3: 래퍼 함수 — 상태 변환의 핵심 ──'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 05 (4/7)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 12',
  'code': 'def call_sentiment_subgraph(state: ParentState) -> dict:\n'
          '    """\n'
          '    래퍼 함수가 하는 일:\n'
          '\n'
          "    1) 부모 상태의 'feedback_text' → 서브그래프의 'log_entry'로 변환\n"
          '    2) 서브그래프 실행\n'
          "    3) 서브그래프 출력을 부모 상태의 'analysis_result'로 매핑\n"
          '    """\n'
          '\n'
          '    # Parent → Subgraph: 상태 변환\n'
          '    subgraph_input = {\n'
          '        "log_entry": state["feedback_text"]\n'
          '    }\n'
          '\n'
          '    # 서브그래프 실행\n'
          '    subgraph_output = sentiment_subgraph.invoke(\n'
          '        subgraph_input,\n'
          '        config=lf_config\n'
          '    )\n'
          '\n'
          '    # Subgraph → Parent: 결과 매핑\n'
          '    result_str = ('},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 05 (5/7)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 12',
  'code': '        f"{subgraph_output[\'sentiment\']} "\n'
          '        f"(confidence: {subgraph_output[\'confidence\']})"\n'
          '    )\n'
          '\n'
          '    return {"analysis_result": result_str}\n'
          '\n'
          '\n'
          'def generate_report(state: ParentState) -> dict:\n'
          '    """최종 보고서 생성"""\n'
          '    report = (\n'
          '        f"[보고서] {state[\'customer_name\']}: "\n'
          '        f"{state[\'analysis_result\']}"\n'
          '    )\n'
          '\n'
          '    return {"analysis_result": report}\n'
          '\n'
          '\n'
          '# ── Step 4: 부모 그래프 구성 ──\n'
          'parent_builder = StateGraph(ParentState)\n'
          '\n'
          'parent_builder.add_node("sentiment_analysis", call_sentiment_subgraph)\n'
          'parent_builder.add_node("report", generate_report)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 05 (6/7)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 12',
  'code': '\n'
          'parent_builder.add_edge(START, "sentiment_analysis")\n'
          'parent_builder.add_edge("sentiment_analysis", "report")\n'
          'parent_builder.add_edge("report", END)\n'
          '\n'
          'parent_graph = parent_builder.compile()\n'
          '\n'
          '\n'
          '# 실행\n'
          'result = parent_graph.invoke(\n'
          '    {\n'
          '        "customer_name": "Alice",\n'
          '        "feedback_text": "The product is great and the service was excellent",\n'
          '    },\n'
          '    config=lf_config\n'
          ')\n'
          '\n'
          'print(f"\\n[최종 결과] {result[\'analysis_result\']}")\n'
          '\n'
          '\n'
          '# 다른 입력으로 추가 테스트\n'
          'result2 = parent_graph.invoke('},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 05 (7/7)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 12',
  'code': '    {\n'
          '        "customer_name": "Bob",\n'
          '        "feedback_text": "The experience was terrible and the quality is poor",\n'
          '    },\n'
          '    config=lf_config\n'
          ')\n'
          '\n'
          'print(f"[최종 결과] {result2[\'analysis_result\']}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 06 (1/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 14',
  'code': 'from langchain.messages import HumanMessage, AnyMessage\n'
          'from langgraph.graph import MessagesState\n'
          '\n'
          '# Subgraph: Translation Agent\n'
          'def translator(state: MessagesState) -> dict:\n'
          '    response = model.invoke(\n'
          '        state["messages"] + [HumanMessage(content="위 내용을 한국어로 번역해 주세요. 번역만 답해 주세요.")],\n'
          '        config=lf_config,\n'
          ')\n'
          '    return {"messages": [response]}\n'
          '\n'
          'translator_builder = StateGraph(MessagesState)\n'
          'translator_builder.add_node("translate", translator)\n'
          'translator_builder.add_edge(START, "translate")\n'
          'translator_builder.add_edge("translate", END)\n'
          'translator_subgraph = translator_builder.compile()\n'
          '\n'
          '# Subgraph: Summarization Agent\n'
          'def summarizer(state: MessagesState) -> dict:\n'
          '    response = model.invoke(\n'
          '        state["messages"] + [HumanMessage(content="위 내용을 한 문장으로 요약해 주세요.")],\n'
          '        config=lf_config,'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 06 (2/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 14',
  'code': ')\n'
          '    return {"messages": [response]}\n'
          '\n'
          'summarizer_builder = StateGraph(MessagesState)\n'
          'summarizer_builder.add_node("summarize", summarizer)\n'
          'summarizer_builder.add_edge(START, "summarize")\n'
          'summarizer_builder.add_edge("summarize", END)\n'
          'summarizer_subgraph = summarizer_builder.compile()\n'
          '\n'
          '# Parent: Translate-then-Summarize Pipeline\n'
          'parent_builder = StateGraph(MessagesState)\n'
          'parent_builder.add_node("translator", translator_subgraph)\n'
          'parent_builder.add_node("summarizer", summarizer_subgraph)\n'
          'parent_builder.add_edge(START, "translator")\n'
          'parent_builder.add_edge("translator", "summarizer")\n'
          'parent_builder.add_edge("summarizer", END)\n'
          '\n'
          'pipeline = parent_builder.compile()\n'
          '\n'
          'result = pipeline.invoke({\n'
          '    "messages": [HumanMessage(content="LangGraph는 LLM을 사용하여 상태 기반 멀티 액터 애플리케이션을 구축하는 프레임워크입니다.")]\n'
          '}, config=lf_config)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 06 (3/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 14',
  'code': 'print("최종 출력:", result["messages"][-1].content)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 07 (1/2)',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 16',
  'code': 'print("=== v1: (namespace, data) 튜플 ===")\n'
          'for chunk in pipeline.stream(\n'
          '    {"messages": [HumanMessage(content="Python은 범용 프로그래밍 언어입니다.")]},\n'
          '    stream_mode="updates",\n'
          '    subgraphs=True,\n'
          '    config=lf_config,\n'
          '):\n'
          '    if isinstance(chunk, tuple) and len(chunk) == 2:\n'
          '        ns, update = chunk\n'
          '        for node, data in update.items():\n'
          '            prefix = f"[{\'/\'.join(ns)}]" if ns else "[root]"\n'
          '            print(f"  {prefix} {node}")\n'
          '\n'
          'print("\\n=== v2: StreamPart dict ===")\n'
          'for chunk in pipeline.stream(\n'
          '    {"messages": [HumanMessage(content="Python은 범용 프로그래밍 언어입니다.")]},\n'
          '    stream_mode="updates",\n'
          '    subgraphs=True,\n'
          '    version="v2",\n'
          '    config=lf_config,\n'
          '):\n'
          '    # chunk["type"] == "updates", chunk["ns"] = (), 또는 ("translator:<uuid>",) ...'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 07 (2/2)',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 16',
  'code': '    ns = chunk["ns"]\n'
          '    data = chunk["data"]\n'
          '    prefix = f"[{\'/\'.join(ns)}]" if ns else "[root]"\n'
          '    for node, _ in data.items():\n'
          '        print(f"  {prefix} type={chunk[\'type\']!r}, node={node}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 08 (1/3)',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 18',
  'code': '# 3가지 checkpointer 모드 — API 레퍼런스 (create_agent를 subagent로 쓰는 예)\n'
          'from langchain.agents import create_agent\n'
          'from langchain.tools import tool\n'
          'from langgraph.checkpoint.memory import MemorySaver\n'
          '\n'
          '@tool\n'
          'def fruit_info(fruit_name: str) -> str:\n'
          '    """Look up fruit info."""\n'
          '    return f"Info about {fruit_name}"\n'
          '\n'
          '# === 1) Per-Invocation (기본) ===\n'
          '# subagent에 checkpointer 미지정 → 부모로부터 상속, 호출마다 fresh\n'
          'fruit_subagent_per_invocation = create_agent(\n'
          '    model="gpt-5.4-mini",\n'
          '    tools=[fruit_info],\n'
          '    system_prompt="You are a fruit expert.",\n'
          ')\n'
          '\n'
          '# === 2) Per-Thread (stateful) ===\n'
          'fruit_subagent_per_thread = create_agent(\n'
          '    model="gpt-5.4-mini",\n'
          '    tools=[fruit_info],'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 08 (2/3)',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 18',
  'code': '    system_prompt="You are a fruit expert.",\n'
          '    checkpointer=True,  # ← 핵심\n'
          ')\n'
          '\n'
          '# === 3) Stateless ===\n'
          'fruit_subagent_stateless = create_agent(\n'
          '    model="gpt-5.4-mini",\n'
          '    tools=[fruit_info],\n'
          '    system_prompt="You are a fruit expert.",\n'
          '    checkpointer=False,  # ← interrupt 불가\n'
          ')\n'
          '\n'
          '# === Per-Thread를 tool로 노출할 때 — 병렬 호출 차단 ===\n'
          "reference_code = r'''\n"
          'from langchain.agents.middleware import ToolCallLimitMiddleware\n'
          '\n'
          '@tool\n'
          'def ask_fruit_expert(question: str) -> str:\n'
          '    """Ask the fruit expert."""\n'
          '    response = fruit_subagent_per_thread.invoke(\n'
          '        {"messages": [{"role": "user", "content": question}]},\n'
          '    )'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 08 (3/3)',
  'lead': '이 코드는 LangChain create_agent 조립과 실행을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 18',
  'code': '    return response["messages"][-1].content\n'
          '\n'
          'agent = create_agent(\n'
          '    model="gpt-5.4-mini",\n'
          '    tools=[ask_fruit_expert],\n'
          '    middleware=[\n'
          '        ToolCallLimitMiddleware(tool_name="ask_fruit_expert", run_limit=1),\n'
          '    ],\n'
          '    checkpointer=MemorySaver(),\n'
          ')\n'
          "'''\n"
          'print(reference_code)\n'
          'print("3가지 모드 객체 생성 완료:",\n'
          '      type(fruit_subagent_per_invocation).__name__,\n'
          '      type(fruit_subagent_per_thread).__name__,\n'
          '      type(fruit_subagent_stateless).__name__)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 09 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 20',
  'code': 'from langgraph.graph import MessagesState, StateGraph\n'
          'from langchain.agents import create_agent\n'
          'from langchain.tools import tool\n'
          '\n'
          '\n'
          '@tool\n'
          'def veggie_info(veggie_name: str) -> str:\n'
          '    """Look up veggie info."""\n'
          '    return f"Info about {veggie_name}"\n'
          '\n'
          '\n'
          'def create_sub_agent(model: str, *, name: str, **kwargs):\n'
          '    """고유 노드 이름으로 agent를 감싸 namespace를 격리합니다."""\n'
          '    agent = create_agent(model=model, name=name, **kwargs)\n'
          '    return (\n'
          '        StateGraph(MessagesState)\n'
          '        .add_node(name, agent)        # 고유 이름 → 안정적 namespace\n'
          '        .add_edge("__start__", name)\n'
          '        .compile()\n'
          '    )\n'
          '\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 09_subgraphs',
  'title': '09_subgraphs 코드 09 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '09_subgraphs.ipynb',
  'note': 'cell 20',
  'code': '# 서로 다른 두 per-thread subagent — namespace가 격리됨\n'
          'fruit_agent_isolated = create_sub_agent(\n'
          '    "gpt-5.4-mini",\n'
          '    name="fruit_agent",\n'
          '    tools=[fruit_info],\n'
          '    system_prompt="You are a fruit expert.",\n'
          '    checkpointer=True,\n'
          ')\n'
          '\n'
          'veggie_agent_isolated = create_sub_agent(\n'
          '    "gpt-5.4-mini",\n'
          '    name="veggie_agent",\n'
          '    tools=[veggie_info],\n'
          '    system_prompt="You are a veggie expert.",\n'
          '    checkpointer=True,\n'
          ')\n'
          '\n'
          'print("두 per-thread subagent가 서로 다른 namespace로 격리되었습니다.")\n'
          'print("  - fruit_agent: namespace prefix = (\'fruit_agent:<uuid>\',)")\n'
          'print("  - veggie_agent: namespace prefix = (\'veggie_agent:<uuid>\',)")\n'
          'print("→ 두 agent의 checkpoint state가 충돌하지 않습니다.")'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '10_production.ipynb',
  'sub': '10_production.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '03_langgraph/10_production.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '10_production.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          'from langchain_openai import ChatOpenAI\n'
          'model = ChatOpenAI(model="gpt-5.4")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '10_production.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (LANGSMITH_* env vars 사용)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    os.environ.setdefault("LANGSMITH_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))\n'
          '    os.environ.setdefault("LANGSMITH_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))\n'
          '    print(f"LangSmith tracing ON — project: {os.environ[\'LANGSMITH_PROJECT\']}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 03',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '10_production.ipynb',
  'note': 'cell 7',
  'code': 'import json\n'
          '\n'
          'config = {\n'
          '    "dependencies": ["."],\n'
          '    "graphs": {\n'
          '        "agent": "./agent.py:graph"\n'
          '    },\n'
          '    "env": ".env"\n'
          '}\n'
          'print("langgraph.json 예시:")\n'
          'print(json.dumps(config, indent=2))\n'
          'print()\n'
          'print("명령어:")\n'
          'print("  $ pip install \'langgraph-cli[inmem]\'")\n'
          'print("  $ langgraph dev  # http://localhost:2024에서 로컬 서버 시작")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 04 (1/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '10_production.ipynb',
  'note': 'cell 13',
  'code': 'from langgraph.graph import StateGraph, START, END\n'
          'from typing import TypedDict\n'
          '\n'
          '# Graph to test\n'
          'class TestState(TypedDict):\n'
          '    input: str\n'
          '    output: str\n'
          '\n'
          '\n'
          'def process(state: TestState) -> dict:\n'
          '    return {"output": state["input"].upper()}\n'
          '\n'
          '\n'
          'builder = StateGraph(TestState)\n'
          '\n'
          'builder.add_node("process", process)\n'
          'builder.add_edge(START, "process")\n'
          'builder.add_edge("process", END)\n'
          '\n'
          'graph = builder.compile()\n'
          '\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 04 (2/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '10_production.ipynb',
  'note': 'cell 13',
  'code': '# Unit tests\n'
          'def test_process():\n'
          '    result = graph.invoke({"input": "hello"})\n'
          '\n'
          '    assert result["output"] == "HELLO", f"HELLO 예상, {result[\'output\']} 반환됨"\n'
          '\n'
          '    print("  OK test_process")\n'
          '\n'
          '\n'
          'def test_empty_input():\n'
          '    result = graph.invoke({"input": ""})\n'
          '\n'
          '    assert result["output"] == "", f"빈 문자열 예상, {result[\'output\']} 반환됨"\n'
          '\n'
          '    print("  OK test_empty_input")\n'
          '\n'
          '\n'
          'print("테스트 실행 중:")\n'
          '\n'
          'test_process()\n'
          'test_empty_input()\n'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 04 (3/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '10_production.ipynb',
  'note': 'cell 13',
  'code': 'print("모든 테스트 통과!")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 05 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '10_production.ipynb',
  'note': 'cell 15',
  'code': 'from langchain_core.language_models import GenericFakeChatModel\n'
          'from langchain.messages import AIMessage, HumanMessage, AnyMessage\n'
          'from langgraph.graph import StateGraph, START, END, MessagesState\n'
          '\n'
          '# Deterministic fake model\n'
          'fake_model = GenericFakeChatModel(\n'
          '    messages=iter(\n'
          '        [\n'
          '            AIMessage(content="The answer is 42."),\n'
          '        ]\n'
          '    )\n'
          ')\n'
          '\n'
          'def chatbot(state: MessagesState) -> dict:\n'
          '    return {\n'
          '        "messages": [fake_model.invoke(state["messages"])]\n'
          '    }\n'
          '\n'
          'builder = StateGraph(MessagesState)\n'
          '\n'
          'builder.add_node("chatbot", chatbot)\n'
          'builder.add_edge(START, "chatbot")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 05 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '10_production.ipynb',
  'note': 'cell 15',
  'code': 'builder.add_edge("chatbot", END)\n'
          '\n'
          'test_graph = builder.compile()\n'
          '\n'
          'result = test_graph.invoke(\n'
          '    {\n'
          '        "messages": [HumanMessage(content="테스트")]\n'
          '    }\n'
          ')\n'
          '\n'
          'assert "42" in result["messages"][-1].content\n'
          '\n'
          'print("GenericFakeChatModel 테스트 통과!")\n'
          'print(f"  응답: {result[\'messages\'][-1].content}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 10_production',
  'title': '10_production 코드 06',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '10_production.ipynb',
  'note': 'cell 20',
  'code': 'import os\n'
          '\n'
          'tracing = os.environ.get("LANGSMITH_TRACING", "false")\n'
          'api_key = os.environ.get("LANGSMITH_API_KEY", "")\n'
          '\n'
          'print("현재 상태:")\n'
          '\n'
          'print(f"  트레이싱: {\'활성화\' if tracing == \'true\' else \'비활성화\'}")\n'
          'print(f"  API 키: {\'설정됨\' if api_key else \'미설정\'}")'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '11_local_server.ipynb',
  'sub': '11_local_server.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '03_langgraph/11_local_server.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 11_local_server',
  'title': '11_local_server 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '11_local_server.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          'from langchain_openai import ChatOpenAI\n'
          'model = ChatOpenAI(model="gpt-5.4")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 11_local_server',
  'title': '11_local_server 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '11_local_server.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (LANGSMITH_* env vars 사용)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    os.environ.setdefault("LANGSMITH_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))\n'
          '    os.environ.setdefault("LANGSMITH_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))\n'
          '    print(f"LangSmith tracing ON — project: {os.environ[\'LANGSMITH_PROJECT\']}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 11_local_server',
  'title': '11_local_server 코드 03',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '11_local_server.ipynb',
  'note': 'cell 7',
  'code': '# LangGraph CLI 설치 명령어\n'
          'print("=== pip으로 설치 (Python >= 3.11) ===")\n'
          'print(\'  $ pip install -U "langgraph-cli[inmem]"\')\n'
          'print()\n'
          'print("=== uv로 설치 ===")\n'
          'print(\'  $ uv add "langgraph-cli[inmem]"\')\n'
          'print()\n'
          'print("설치 후 확인:")\n'
          'print("  $ langgraph --version")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 11_local_server',
  'title': '11_local_server 코드 04',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '11_local_server.ipynb',
  'note': 'cell 9',
  'code': '# 프로젝트 생성 명령어\n'
          'print("=== 템플릿으로 새 프로젝트 생성 ===")\n'
          'print("  $ langgraph new my-agent --template new-langgraph-project-python")\n'
          'print()\n'
          'print("=== 인터랙티브 메뉴로 생성 ===")\n'
          'print("  $ langgraph new my-agent")\n'
          'print()\n'
          'print("=== 생성 후 의존성 설치 ===")\n'
          'print("  # pip 사용")\n'
          'print("  $ cd my-agent && pip install -e .")\n'
          'print()\n'
          'print("  # uv 사용")\n'
          'print("  $ cd my-agent && uv sync")\n'
          'print()\n'
          'print("=== 생성되는 파일 구조 ===")\n'
          'print("  my-agent/")\n'
          'print("  ├── langgraph.json   # 그래프 설정")\n'
          'print("  ├── .env.example     # 환경 변수 템플릿")\n'
          'print("  ├── pyproject.toml   # 의존성 정의")\n'
          'print("  └── src/")\n'
          'print("      └── agent.py     # 에이전트 코드")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 11_local_server',
  'title': '11_local_server 코드 05',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '11_local_server.ipynb',
  'note': 'cell 11',
  'code': 'import json\n'
          '\n'
          '# langgraph.json 설정 예시\n'
          'config = {\n'
          '    "dependencies": ["."],\n'
          '    "graphs": {\n'
          '        "agent": "./src/agent.py:graph"\n'
          '    },\n'
          '    "env": ".env"\n'
          '}\n'
          '\n'
          'print("langgraph.json 예시:")\n'
          'print(json.dumps(config, indent=2))\n'
          'print()\n'
          'print("주요 필드:")\n'
          "print('  dependencies: 설치할 패키지 경로 목록')\n"
          "print('  graphs:       그래프 이름 → 모듈:변수 매핑')\n"
          "print('  env:          환경 변수 파일 경로')"},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 11_local_server',
  'title': '11_local_server 코드 06 (1/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '11_local_server.ipynb',
  'note': 'cell 15',
  'code': '# 비동기 클라이언트 사용 패턴 (서버 실행 중일 때 사용)\n'
          'print("""from langgraph_sdk import get_client\n'
          'import asyncio\n'
          '\n'
          'client = get_client(url="http://localhost:2024")\n'
          '\n'
          'async def main():\n'
          '    async for chunk in client.runs.stream(\n'
          '        None,\n'
          '        "agent",\n'
          '        input={\n'
          '            "messages": [{\n'
          '                "role": "human",\n'
          '                "content": "What is LangGraph?",\n'
          '            }],\n'
          '        },\n'
          '    ):\n'
          '        print(f"Event type: {chunk.event}...")\n'
          '        print(chunk.data)\n'
          '\n'
          'asyncio.run(main())\n'
          '""")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 11_local_server',
  'title': '11_local_server 코드 06 (2/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '11_local_server.ipynb',
  'note': 'cell 15',
  'code': 'print("# 위 코드는 langgraph dev 서버가 실행 중일 때 사용합니다.")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 11_local_server',
  'title': '11_local_server 코드 07',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '11_local_server.ipynb',
  'note': 'cell 17',
  'code': '# 동기 클라이언트 사용 패턴 (서버 실행 중일 때 사용)\n'
          'print("""from langgraph_sdk import get_sync_client\n'
          '\n'
          'client = get_sync_client(url="http://localhost:2024")\n'
          '\n'
          'for chunk in client.runs.stream(\n'
          '    None,\n'
          '    "agent",\n'
          '    input={\n'
          '        "messages": [{\n'
          '            "role": "human",\n'
          '            "content": "What is LangGraph?",\n'
          '        }],\n'
          '    },\n'
          '    stream_mode="messages-tuple",\n'
          '):\n'
          '    print(f"Event: {chunk.event}...")\n'
          '    print(chunk.data)\n'
          '""")\n'
          'print("# 위 코드는 langgraph dev 서버가 실행 중일 때 사용합니다.")'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '12_durable_execution.ipynb',
  'sub': '12_durable_execution.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '03_langgraph/12_durable_execution.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          'from langchain_openai import ChatOpenAI\n'
          'model = ChatOpenAI(model="gpt-5.4")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (LANGSMITH_* env vars 사용)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    os.environ.setdefault("LANGSMITH_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))\n'
          '    os.environ.setdefault("LANGSMITH_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))\n'
          '    print(f"LangSmith tracing ON — project: {os.environ[\'LANGSMITH_PROJECT\']}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 03',
  'lead': '이 코드는 노트북 실습의 실행 단계를 그대로 확인하기 위한 코드입니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 10',
  'code': '# 문제가 있는 접근 방식: 부수 효과를 직접 호출\n'
          'print("""# BAD: 부수 효과가 태스크로 감싸지지 않음\n'
          'def call_api(state: State):\n'
          '    # 이 API 호출은 재개 시 다시 실행됨!\n'
          "    result = requests.get(state['url']).text[:100]\n"
          '    return {"result": result}\n'
          '""")\n'
          'print("문제점:")\n'
          'print("  1. 장애 후 재개 시 API가 다시 호출됨")\n'
          'print("  2. 비결정적 결과가 달라질 수 있음")\n'
          'print("  3. 중복 요청으로 부작용 발생 가능")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 04',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 12',
  'code': '# 개선된 접근 방식: @task로 부수 효과 래핑\n'
          'print("""# GOOD: @task로 부수 효과를 감쌈\n'
          'from langgraph.func import task\n'
          '\n'
          '@task\n'
          'def _make_request(url: str):\n'
          '    return requests.get(url).text[:100]\n'
          '\n'
          'def call_api(state: State):\n'
          '    # 각 요청이 개별 태스크로 실행됨\n'
          "    requests = [_make_request(url) for url in state['urls']]\n"
          '    results = [req.result() for req in requests]\n'
          '    return {"results": results}\n'
          '""")\n'
          'print("개선 효과:")\n'
          'print("  1. 재개 시 체크포인트에서 결과 복원")\n'
          'print("  2. API 중복 호출 방지")\n'
          'print("  3. 각 태스크가 독립적으로 추적됨")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 05 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 14',
  'code': 'from typing import TypedDict\n'
          'from langgraph.graph import StateGraph, START, END\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '\n'
          'class DocState(TypedDict):\n'
          '    topic: str\n'
          '    draft: str\n'
          '    final: str\n'
          '\n'
          '\n'
          'def write_draft(state: DocState) -> dict:\n'
          '    return {"draft": f"Draft about {state[\'topic\']}"}\n'
          '\n'
          '\n'
          'def finalize(state: DocState) -> dict:\n'
          '    return {"final": f"Final: {state[\'draft\']}"}\n'
          '\n'
          '\n'
          'checkpointer = InMemorySaver()\n'
          '\n'
          'builder = StateGraph(DocState)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 05 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 14',
  'code': 'builder.add_node("write_draft", write_draft)\n'
          'builder.add_node("finalize", finalize)\n'
          'builder.add_edge(START, "write_draft")\n'
          'builder.add_edge("write_draft", "finalize")\n'
          'builder.add_edge("finalize", END)\n'
          '\n'
          'graph = builder.compile(checkpointer=checkpointer)\n'
          '\n'
          '# 실행 (thread_id로 실행 추적)\n'
          'config = {"configurable": {"thread_id": "doc-1"}}\n'
          'result = graph.invoke({"topic": "LangGraph"}, config)\n'
          'print("결과:", result)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 06 (1/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 16',
  'code': 'from langgraph.func import entrypoint, task\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '\n'
          '@task\n'
          'def generate_draft(topic: str) -> str:\n'
          '    return f"Draft about {topic}"\n'
          '\n'
          '\n'
          '@task\n'
          'def review_draft(draft: str) -> str:\n'
          '    return f"Reviewed: {draft}"\n'
          '\n'
          '\n'
          'func_checkpointer = InMemorySaver()\n'
          '\n'
          '\n'
          '@entrypoint(checkpointer=func_checkpointer)\n'
          'def write_document(topic: str) -> str:\n'
          '    draft = generate_draft(topic).result()\n'
          '    reviewed = review_draft(draft).result()\n'
          '    return reviewed'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 06 (2/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 16',
  'code': '\n'
          '\n'
          'config = {"configurable": {"thread_id": "func-1"}}\n'
          'result = write_document.invoke("Durable Execution", config)\n'
          'print("결과:", result)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 07 (1/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 18',
  'code': 'from typing import TypedDict\n'
          'from langgraph.graph import StateGraph, START, END\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '\n'
          'class PipelineState(TypedDict):\n'
          '    data: str\n'
          '    step: int\n'
          '    result: str\n'
          '\n'
          '\n'
          'call_count = 0\n'
          '\n'
          '\n'
          'def step_one(state: PipelineState) -> dict:\n'
          '    global call_count\n'
          '    call_count += 1\n'
          '    print(f"  step_one 실행 (호출 횟수: {call_count})")\n'
          '    return {"data": state["data"].upper(), "step": 1}\n'
          '\n'
          '\n'
          'def step_two(state: PipelineState) -> dict:'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 07 (2/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 18',
  'code': '    print(f"  step_two 실행")\n'
          '    return {"result": f"Processed: {state[\'data\']}", "step": 2}\n'
          '\n'
          '\n'
          'recovery_saver = InMemorySaver()\n'
          '\n'
          'builder = StateGraph(PipelineState)\n'
          'builder.add_node("step_one", step_one)\n'
          'builder.add_node("step_two", step_two)\n'
          'builder.add_edge(START, "step_one")\n'
          'builder.add_edge("step_one", "step_two")\n'
          'builder.add_edge("step_two", END)\n'
          '\n'
          'pipeline = builder.compile(checkpointer=recovery_saver)\n'
          '\n'
          '# 첫 번째 실행\n'
          'config = {"configurable": {"thread_id": "recovery-1"}}\n'
          'print("=== 첫 번째 실행 ===")\n'
          'result = pipeline.invoke(\n'
          '    {"data": "hello", "step": 0, "result": ""},\n'
          '    config\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 07 (3/3)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 18',
  'code': 'print(f"결과: {result}")\n'
          '\n'
          '# 체크포인트 확인\n'
          'print("\\n=== 체크포인트에서 상태 복원 ===")\n'
          'saved = pipeline.get_state(config)\n'
          'print(f"저장된 상태: {saved.values}")\n'
          'print(f"step_one 총 호출 횟수: {call_count}")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 08 (1/2)',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 22',
  'code': '# LangGraph 1.2 fault tolerance 패턴\n'
          'from importlib.metadata import version\n'
          '\n'
          'print("설치된 langgraph:", version("langgraph"))\n'
          'print("필요 버전: langgraph>=1.2.0")\n'
          '\n'
          "example = r'''\n"
          'from langgraph.errors import NodeError\n'
          'from langgraph.types import Command, RetryPolicy, TimeoutPolicy\n'
          'from langgraph.runtime import Runtime  # heartbeat 사용 시\n'
          '\n'
          'def payment_error_handler(state: State, error: NodeError) -> Command:\n'
          '    # retry 모두 소진 후 실행되는 보정 함수\n'
          '    return Command(\n'
          '        update={"status": f"compensated: {error.error}"},\n'
          '        goto="finalize",\n'
          '    )\n'
          '\n'
          'builder.add_node(\n'
          '    "charge_payment",\n'
          '    charge_payment,\n'
          '    timeout=TimeoutPolicy(idle_timeout=30),                     # NodeTimeoutError'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 08 (2/2)',
  'lead': '이 코드는 interrupt와 Command 기반 제어 흐름을 보여줍니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 22',
  'code': '    retry_policy=RetryPolicy(max_attempts=3, retry_on=ConnectionError),\n'
          '    error_handler=payment_error_handler,                        # 보정 트랜잭션\n'
          ')\n'
          '\n'
          '# 장기 작업 노드: heartbeat로 idle timeout 갱신\n'
          'async def long_running_node(state: State, runtime: Runtime) -> dict:\n'
          '    for batch in fetch_batches():\n'
          '        process(batch)\n'
          '        runtime.heartbeat()\n'
          '    return {"result": "done"}\n'
          '\n'
          'builder.add_node(\n'
          '    "long_running_node",\n'
          '    long_running_node,\n'
          '    timeout=TimeoutPolicy(idle_timeout=30, refresh_on="heartbeat"),\n'
          ')\n'
          "'''\n"
          'print(example)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 09 (1/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 24',
  'code': '# Graceful shutdown 패턴 — langgraph>=1.2\n'
          "example = r'''\n"
          'from langgraph.runtime import RunControl, Runtime\n'
          'from langgraph.errors import GraphDrained\n'
          '\n'
          '# 1) 호출 측: 외부 시그널(SIGTERM 등)에 drain 요청\n'
          'control = RunControl()\n'
          'control.request_drain("sigterm")\n'
          '\n'
          'try:\n'
          '    result = graph.invoke(inputs, config, control=control)\n'
          'except GraphDrained as e:\n'
          '    print(f"Drained: {e.reason}")\n'
          '    # checkpoint는 이미 저장됨 — 같은 config로 재개 가능\n'
          '\n'
          '# 같은 config로 재개\n'
          'graph.invoke(None, config)\n'
          '\n'
          '# 2) 노드 내부: drain 신호를 직접 감지\n'
          'async def my_node(state: State, runtime: Runtime) -> dict:\n'
          '    if runtime.drain_requested:\n'
          '        return {"status": "skipped"}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 09 (2/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 24',
  'code': '    # ... 일반 처리\n    return {"status": "done"}\n\'\'\'\nprint(example)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 12_durable_execution',
  'title': '12_durable_execution 코드 10',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '12_durable_execution.ipynb',
  'note': 'cell 26',
  'code': '# DeltaChannel 개념 예시 — 실제 실행은 langgraph>=1.2에서 확인하세요.\n'
          "example = r'''\n"
          'from typing_extensions import Annotated, TypedDict\n'
          'from langgraph.channels.delta import DeltaChannel\n'
          '\n'
          'def append(state: list[str], writes: list[list[str]]) -> list[str]:\n'
          '    return state + [item for batch in writes for item in batch]\n'
          '\n'
          'class State(TypedDict):\n'
          '    # append-heavy 메시지/로그 채널에서 checkpoint delta 저장을 고려\n'
          '    items: Annotated[list[str], DeltaChannel(reducer=append, snapshot_frequency=50)]\n'
          "'''\n"
          'print(example)'},
 {'type': 'divider',
  'kicker': 'CODE',
  'title': '13_api_guide_and_pregel.ipynb',
  'sub': '13_api_guide_and_pregel.ipynb의 실행 코드 셀을 순서대로 훑습니다. ipynb와 덱만으로 코드 흐름을 복습할 수 있게 구성했습니다.',
  'lab': '03_langgraph/13_api_guide_and_pregel.ipynb'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 13_api_guide_and_pregel',
  'title': '13_api_guide_and_pregel 코드 01',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '13_api_guide_and_pregel.ipynb',
  'note': 'cell 4',
  'code': 'from dotenv import load_dotenv\n'
          'load_dotenv(override=True)\n'
          'from langchain_openai import ChatOpenAI\n'
          'model = ChatOpenAI(model="gpt-5.4")'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 13_api_guide_and_pregel',
  'title': '13_api_guide_and_pregel 코드 02',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '13_api_guide_and_pregel.ipynb',
  'note': 'cell 5',
  'code': '# Observability 설정 (선택) - LangSmith 또는 Langfuse\n'
          '# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.\n'
          '# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."\n'
          '# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."\n'
          '# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"\n'
          'import os\n'
          '\n'
          '# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (LANGSMITH_* env vars 사용)\n'
          'if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":\n'
          '    os.environ.setdefault("LANGSMITH_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))\n'
          '    os.environ.setdefault("LANGSMITH_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))\n'
          '    print(f"LangSmith tracing ON — project: {os.environ[\'LANGSMITH_PROJECT\']}")\n'
          '\n'
          '# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달\n'
          'langfuse_handler = None\n'
          'if os.environ.get("LANGFUSE_SECRET_KEY"):\n'
          '    from langfuse.langchain import CallbackHandler\n'
          '    langfuse_handler = CallbackHandler()\n'
          '    print(f"Langfuse tracing ON — {os.environ.get(\'LANGFUSE_HOST\', \'\')}")\n'
          '\n'
          '# Langfuse config: pass to invoke/stream/batch calls\n'
          'lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 13_api_guide_and_pregel',
  'title': '13_api_guide_and_pregel 코드 03 (1/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '13_api_guide_and_pregel.ipynb',
  'note': 'cell 9',
  'code': 'from typing import TypedDict\n'
          'from langgraph.constants import START\n'
          'from langgraph.graph import StateGraph\n'
          '\n'
          '\n'
          'class Essay(TypedDict):\n'
          '    topic: str\n'
          '    content: str | None\n'
          '    score: float | None\n'
          '\n'
          '\n'
          'def write_essay(essay: Essay):\n'
          '    return {"content": f"Essay about {essay[\'topic\']}"}\n'
          '\n'
          '\n'
          'def score_essay(essay: Essay):\n'
          '    return {"score": 10}\n'
          '\n'
          '\n'
          'builder = StateGraph(Essay)\n'
          'builder.add_node(write_essay)\n'
          'builder.add_node(score_essay)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 13_api_guide_and_pregel',
  'title': '13_api_guide_and_pregel 코드 03 (2/2)',
  'lead': '이 코드는 StateGraph 상태, 노드, 엣지 조립을 보여줍니다.',
  'file': '13_api_guide_and_pregel.ipynb',
  'note': 'cell 9',
  'code': 'builder.add_edge(START, "write_essay")\n'
          'builder.add_edge("write_essay", "score_essay")\n'
          '\n'
          'graph_app = builder.compile()\n'
          '\n'
          'result = graph_app.invoke({"topic": "LangGraph"})\n'
          'print("Graph API 결과:", result)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 13_api_guide_and_pregel',
  'title': '13_api_guide_and_pregel 코드 04 (1/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '13_api_guide_and_pregel.ipynb',
  'note': 'cell 11',
  'code': 'from typing import TypedDict\n'
          'from langgraph.func import entrypoint, task\n'
          'from langgraph.checkpoint.memory import InMemorySaver\n'
          '\n'
          '\n'
          'class EssayResult(TypedDict):\n'
          '    topic: str\n'
          '    content: str | None\n'
          '    score: float | None\n'
          '\n'
          '\n'
          '@task\n'
          'def write_essay_func(topic: str) -> str:\n'
          '    return f"Essay about {topic}"\n'
          '\n'
          '\n'
          '@task\n'
          'def score_essay_func(content: str) -> float:\n'
          '    return 10\n'
          '\n'
          '\n'
          'func_saver = InMemorySaver()'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 13_api_guide_and_pregel',
  'title': '13_api_guide_and_pregel 코드 04 (2/2)',
  'lead': '이 코드는 Functional API의 task/entrypoint 실행 단위를 보여줍니다.',
  'file': '13_api_guide_and_pregel.ipynb',
  'note': 'cell 11',
  'code': '\n'
          '\n'
          '@entrypoint(checkpointer=func_saver)\n'
          'def essay_pipeline(topic: str) -> dict:\n'
          '    content = write_essay_func(topic).result()\n'
          '    score = score_essay_func(content).result()\n'
          '    return {"topic": topic, "content": content, "score": score}\n'
          '\n'
          '\n'
          'config = {"configurable": {"thread_id": "essay-1"}}\n'
          'result = essay_pipeline.invoke("LangGraph", config)\n'
          'print("Functional API 결과:", result)'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 13_api_guide_and_pregel',
  'title': '13_api_guide_and_pregel 코드 05 (1/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '13_api_guide_and_pregel.ipynb',
  'note': 'cell 16',
  'code': 'from langgraph.channels import EphemeralValue\n'
          'from langgraph.pregel import Pregel, NodeBuilder\n'
          '\n'
          '# 단일 노드: 입력을 두 번 반복\n'
          'node1 = (\n'
          '    NodeBuilder()\n'
          '    .subscribe_only("a")\n'
          '    .do(lambda x: x + x)\n'
          '    .write_to("b")\n'
          ')\n'
          '\n'
          'app = Pregel(\n'
          '    nodes={"node1": node1},\n'
          '    channels={\n'
          '        "a": EphemeralValue(str),\n'
          '        "b": EphemeralValue(str),\n'
          '    },\n'
          '    input_channels=["a"],\n'
          '    output_channels=["b"],\n'
          ')\n'
          '\n'
          'result = app.invoke({"a": "foo"})'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 13_api_guide_and_pregel',
  'title': '13_api_guide_and_pregel 코드 05 (2/2)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '13_api_guide_and_pregel.ipynb',
  'note': 'cell 16',
  'code': 'print("Pregel 결과:", result)\n# \'foo\' + \'foo\' = \'foofoo\''},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 13_api_guide_and_pregel',
  'title': '13_api_guide_and_pregel 코드 06 (1/4)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '13_api_guide_and_pregel.ipynb',
  'note': 'cell 18',
  'code': 'from langgraph.channels import (\n'
          '    EphemeralValue,\n'
          '    LastValue,\n'
          '    Topic,\n'
          '    BinaryOperatorAggregate,\n'
          ')\n'
          'from langgraph.pregel import Pregel, NodeBuilder\n'
          '\n'
          '# --- 1. LastValue: 최신 값만 유지 ---\n'
          'node_lv = (\n'
          '    NodeBuilder()\n'
          '    .subscribe_only("input")\n'
          '    .do(lambda x: x.upper())\n'
          '    .write_to("output")\n'
          ')\n'
          '\n'
          'app_lv = Pregel(\n'
          '    nodes={"node": node_lv},\n'
          '    channels={\n'
          '        "input": EphemeralValue(str),\n'
          '        "output": LastValue(str),\n'
          '    },'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 13_api_guide_and_pregel',
  'title': '13_api_guide_and_pregel 코드 06 (2/4)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '13_api_guide_and_pregel.ipynb',
  'note': 'cell 18',
  'code': '    input_channels=["input"],\n'
          '    output_channels=["output"],\n'
          ')\n'
          'print("LastValue:", app_lv.invoke({"input": "hello"}))\n'
          '\n'
          '# --- 2. Topic: 여러 값을 누적 ---\n'
          'node_t1 = (\n'
          '    NodeBuilder()\n'
          '    .subscribe_only("a")\n'
          '    .do(lambda x: x + x)\n'
          '    .write_to("b", "c")\n'
          ')\n'
          '\n'
          'node_t2 = (\n'
          '    NodeBuilder()\n'
          '    .subscribe_to("b")\n'
          '    .do(lambda x: x["b"] + x["b"])\n'
          '    .write_to("c")\n'
          ')\n'
          '\n'
          'app_topic = Pregel(\n'
          '    nodes={"node1": node_t1, "node2": node_t2},'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 13_api_guide_and_pregel',
  'title': '13_api_guide_and_pregel 코드 06 (3/4)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '13_api_guide_and_pregel.ipynb',
  'note': 'cell 18',
  'code': '    channels={\n'
          '        "a": EphemeralValue(str),\n'
          '        "b": EphemeralValue(str),\n'
          '        "c": Topic(str, accumulate=True),\n'
          '    },\n'
          '    input_channels=["a"],\n'
          '    output_channels=["c"],\n'
          ')\n'
          'print("Topic:", app_topic.invoke({"a": "foo"}))\n'
          '\n'
          '# --- 3. BinaryOperatorAggregate: 리듀서 적용 ---\n'
          'def reducer(current, update):\n'
          '    if current:\n'
          '        return current + " | " + update\n'
          '    return update\n'
          '\n'
          'node_b1 = (\n'
          '    NodeBuilder()\n'
          '    .subscribe_only("a")\n'
          '    .do(lambda x: x + x)\n'
          '    .write_to("b", "c")\n'
          ')'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 13_api_guide_and_pregel',
  'title': '13_api_guide_and_pregel 코드 06 (4/4)',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '13_api_guide_and_pregel.ipynb',
  'note': 'cell 18',
  'code': '\n'
          'node_b2 = (\n'
          '    NodeBuilder()\n'
          '    .subscribe_only("b")\n'
          '    .do(lambda x: x + x)\n'
          '    .write_to("c")\n'
          ')\n'
          '\n'
          'app_agg = Pregel(\n'
          '    nodes={"node1": node_b1, "node2": node_b2},\n'
          '    channels={\n'
          '        "a": EphemeralValue(str),\n'
          '        "b": EphemeralValue(str),\n'
          '        "c": BinaryOperatorAggregate(str, operator=reducer),\n'
          '    },\n'
          '    input_channels=["a"],\n'
          '    output_channels=["c"],\n'
          ')\n'
          'print("BinaryOperatorAggregate:", app_agg.invoke({"a": "foo"}))'},
 {'type': 'code-only',
  'course': 'AI 에이전트 개발 심화',
  'meta': 'Code / 13_api_guide_and_pregel',
  'title': '13_api_guide_and_pregel 코드 07',
  'lead': '이 코드는 실습에 필요한 패키지와 객체를 준비합니다.',
  'file': '13_api_guide_and_pregel.ipynb',
  'note': 'cell 20',
  'code': '# DeltaChannel 개념 예시 — 실제 실행은 langgraph>=1.2에서 확인하세요.\n'
          "example = r'''\n"
          'from typing import Annotated, Sequence\n'
          'from typing_extensions import TypedDict\n'
          'from langgraph.channels import DeltaChannel\n'
          '\n'
          'def list_reducer(state: list, writes: Sequence[list]) -> list:\n'
          '    # (current_state, sequence_of_writes) -> new_state\n'
          '    result = list(state)\n'
          '    for write in writes:\n'
          '        result.extend(write)\n'
          '    return result\n'
          '\n'
          'class State(TypedDict):\n'
          '    messages: Annotated[\n'
          '        list[str],\n'
          '        DeltaChannel(list_reducer, snapshot_frequency=5),\n'
          '    ]\n'
          "'''\n"
          'print(example)'},
 {'type': 'closing',
  'kicker': 'CLOSING',
  'title': "LangGraph 심화는 '그래프를 그리는 법'보다 '실행을 통제하는 법'입니다",
  'sub': '다음 Deep Agents 실전에서는 이 제어 모델 위에 파일, 서브에이전트, 메모리, 스킬과 선택형 TodoListMiddleware를 얹어 장기 작업 하네스를 만듭니다.'}]
