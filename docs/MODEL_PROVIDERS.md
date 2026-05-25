# 다른 모델 프로바이더 사용하기

이 교육 자료는 기본적으로 `ChatOpenAI(model="gpt-5.4")`을 사용합니다.
아래 코드로 교체하면 노트북 내 어디서든 다른 프로바이더를 사용할 수 있습니다.

## OpenRouter

```python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=os.environ["OPENROUTER_API_KEY"],
    model="anthropic/claude-sonnet-4",
)
```

## Ollama (로컬)

```bash
pip install langchain-ollama
```

```python
from langchain_ollama import ChatOllama

model = ChatOllama(model="llama3.1")
```

## vLLM (셀프호스트)

```python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    base_url="http://localhost:8000/v1",
    api_key="dummy",
    model="meta-llama/Llama-3.1-8B-Instruct",
)
```

## LM Studio (로컬)

```python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    base_url="http://localhost:1234/v1",
    api_key="lm-studio",
    model="local-model",
)
```

> 위 모델 객체는 노트북에서 `ChatOpenAI(model="gpt-5.4")`이 사용되는 모든 곳에 그대로 대입할 수 있습니다.
