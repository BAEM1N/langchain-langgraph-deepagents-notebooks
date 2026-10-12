"""Offline provider SDK compatibility checks for authored voice/observability material."""

from __future__ import annotations

import inspect
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOICE_MATERIALS = [
    ROOT / "05_advanced/08_voice_agent.ipynb",
    ROOT / "en/05_advanced/08_voice_agent.ipynb",
    ROOT / "docs/langchain/tutorials/voice-agent.md",
    ROOT / "book/chapters/part5/ch08.typ",
    ROOT / "en/book/chapters/part5/ch08.typ",
]


def read_material(path: Path) -> str:
    if path.suffix == ".ipynb":
        notebook = json.loads(path.read_text())
        return "\n".join("".join(cell.get("source", [])) for cell in notebook["cells"])
    return path.read_text()


class VoiceProviderContracts(unittest.TestCase):
    def test_assemblyai_v1_streaming_contract(self):
        import assemblyai as aai
        from assemblyai.streaming.v3 import (
            Encoding,
            RealTimeError,
            RealTimeEvents,
            RealTimeTranscriber,
            StreamingParameters,
            TurnEvent,
        )

        self.assertEqual(aai.__version__, "1.6.1")
        self.assertFalse(hasattr(aai, "RealtimeTranscriber"))
        self.assertIn("api_key", inspect.signature(RealTimeTranscriber).parameters)
        self.assertEqual(
            inspect.signature(RealTimeTranscriber.connect)
            .parameters["params"]
            .annotation,
            StreamingParameters,
        )
        self.assertEqual(Encoding.pcm_s16le.value, "pcm_s16le")
        self.assertEqual(RealTimeEvents.Turn.value, "Turn")
        self.assertIn("end_of_turn", inspect.signature(TurnEvent).parameters)
        self.assertIn("transcript", inspect.signature(TurnEvent).parameters)
        self.assertEqual(
            inspect.signature(RealTimeError).parameters["message"].annotation, str
        )

    def test_cartesia_v4_websocket_context_contract(self):
        import cartesia
        import cartesia.lib._tts as tts

        self.assertEqual(cartesia.__version__, "4.2.0")
        client = cartesia.AsyncCartesia(api_key="placeholder")
        self.assertTrue(hasattr(client.tts, "websocket_connect"))
        manager = client.tts.websocket_connect()
        self.assertTrue(hasattr(manager, "__aenter__"))
        self.assertIn(
            "event", inspect.signature(tts.AsyncTTSResourceConnection.send).parameters
        )
        self.assertIn(
            "model_id",
            inspect.signature(tts.AsyncTTSResourceConnection.context).parameters,
        )
        self.assertIn(
            "voice",
            inspect.signature(tts.AsyncTTSResourceConnection.context).parameters,
        )
        self.assertTrue(inspect.iscoroutinefunction(tts.AsyncWebSocketContext.push))
        self.assertTrue(
            inspect.iscoroutinefunction(tts.AsyncWebSocketContext.no_more_inputs)
        )

    def test_voice_materials_do_not_teach_removed_provider_apis(self):
        banned = [
            "aai.RealtimeTranscriber",
            "aai.RealtimeFinalTranscript",
            "aai.RealtimeTranscript",
            "cartesia_client.tts.websocket()",
            "voice_id=",
        ]
        required = [
            "RealTimeTranscriber",
            "RealTimeEvents.Turn",
            "StreamingParameters(sample_rate=16000, encoding=Encoding.pcm_s16le)",
            "tts.websocket_connect()",
            'voice={"id": "your-voice-id"}',
        ]
        for path in VOICE_MATERIALS:
            with self.subTest(path=path.relative_to(ROOT)):
                content = read_material(path)
                for token in banned:
                    self.assertNotIn(token, content)
                for token in required:
                    self.assertIn(token, content)


class LangfuseV4Contracts(unittest.TestCase):
    def test_langfuse_v4_langchain_and_scoring_contracts(self):
        import langfuse
        from langfuse.langchain import CallbackHandler

        self.assertEqual(langfuse.__version__, "4.17.0")
        self.assertIn("public_key", inspect.signature(CallbackHandler).parameters)
        self.assertNotIn("update_trace", inspect.signature(CallbackHandler).parameters)
        self.assertEqual(
            list(inspect.signature(langfuse.get_client).parameters), ["public_key"]
        )

        client = langfuse.Langfuse(
            public_key="pk-test",
            secret_key="sk-test",
            host="http://127.0.0.1:1",
            tracing_enabled=False,
        )
        for name in [
            "create_dataset",
            "create_dataset_item",
            "create_score",
            "score_current_trace",
            "flush",
            "shutdown",
        ]:
            self.assertTrue(hasattr(client, name), name)

        self.assertIn(
            "dataset_name", inspect.signature(client.create_dataset_item).parameters
        )
        self.assertIn("value", inspect.signature(client.score_current_trace).parameters)

    def test_langfuse_notebook_matches_v4_contract(self):
        notebook = read_material(
            ROOT / "08_integration/12_observability/01_langfuse.ipynb"
        )
        self.assertIn("from langfuse.langchain import CallbackHandler", notebook)
        self.assertIn("handler = CallbackHandler()", notebook)
        self.assertIn("from langfuse import get_client", notebook)
        self.assertIn("client.create_dataset(", notebook)
        self.assertIn("client.create_dataset_item(", notebook)
        self.assertIn("client.score_current_trace(", notebook)
        self.assertNotIn("CallbackHandler(update_trace=", notebook)
