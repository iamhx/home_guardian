import asyncio
import json
import sys
import os
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

# Mock heavy dependencies before importing the module
sys.modules.setdefault("cv2", MagicMock())
sys.modules.setdefault("aiortc", MagicMock())
sys.modules.setdefault("aiohttp", MagicMock())

from face_detection_webrtc import FaceDetectionWebRTC


class TestFaceDetectionWebRTCInit:
    def test_default_whep_url(self):
        fd = FaceDetectionWebRTC()
        assert fd.whep_url == "http://localhost:8889/cam/whep"

    def test_custom_whep_url(self):
        fd = FaceDetectionWebRTC(whep_url="http://example.com:9999/stream/whep")
        assert fd.whep_url == "http://example.com:9999/stream/whep"

    def test_initial_state(self):
        fd = FaceDetectionWebRTC()
        assert fd.last_face_count == 0
        assert fd.last_detected is False
        assert fd.health is False
        assert fd.ws_connections == []
        assert fd.event_loop is None
        assert fd.running is False
        assert fd._task is None
        assert fd._pc is None


class TestFaceDetectionWebRTCHealth:
    def test_is_healthy_default(self):
        fd = FaceDetectionWebRTC()
        assert fd.is_healthy() is False

    def test_is_healthy_when_set(self):
        fd = FaceDetectionWebRTC()
        fd.health = True
        assert fd.is_healthy() is True


class TestFaceDetectionWebRTCSetEventLoop:
    def test_set_event_loop(self):
        fd = FaceDetectionWebRTC()
        mock_loop = MagicMock()
        fd.set_event_loop(mock_loop)
        assert fd.event_loop is mock_loop


class TestFaceDetectionWebRTCWebSocketManagement:
    def test_add_ws(self):
        fd = FaceDetectionWebRTC()
        ws = MagicMock()
        fd.add_ws(ws)
        assert ws in fd.ws_connections

    def test_add_ws_duplicate(self):
        fd = FaceDetectionWebRTC()
        ws = MagicMock()
        fd.add_ws(ws)
        fd.add_ws(ws)
        assert fd.ws_connections.count(ws) == 1

    def test_add_multiple_ws(self):
        fd = FaceDetectionWebRTC()
        ws1 = MagicMock()
        ws2 = MagicMock()
        fd.add_ws(ws1)
        fd.add_ws(ws2)
        assert len(fd.ws_connections) == 2

    def test_remove_ws(self):
        fd = FaceDetectionWebRTC()
        ws = MagicMock()
        fd.add_ws(ws)
        fd.remove_ws(ws)
        assert ws not in fd.ws_connections

    def test_remove_ws_not_present(self):
        fd = FaceDetectionWebRTC()
        ws = MagicMock()
        fd.remove_ws(ws)  # Should not raise
        assert len(fd.ws_connections) == 0

    def test_remove_ws_from_multiple(self):
        fd = FaceDetectionWebRTC()
        ws1 = MagicMock()
        ws2 = MagicMock()
        fd.add_ws(ws1)
        fd.add_ws(ws2)
        fd.remove_ws(ws1)
        assert ws1 not in fd.ws_connections
        assert ws2 in fd.ws_connections


class TestFaceDetectionWebRTCBroadcast:
    def test_broadcast_with_event_loop(self):
        fd = FaceDetectionWebRTC()
        mock_loop = MagicMock()
        fd.set_event_loop(mock_loop)
        ws = MagicMock()
        ws.send_json = AsyncMock()
        fd.ws_connections.append(ws)

        with patch("face_detection_webrtc.asyncio.run_coroutine_threadsafe") as mock_rcts:
            fd._broadcast(2, True)
            mock_rcts.assert_called_once()

    def test_broadcast_without_event_loop(self):
        fd = FaceDetectionWebRTC()
        ws = MagicMock()
        fd.ws_connections.append(ws)
        # Should not raise even without event loop
        fd._broadcast(1, True)

    def test_broadcast_updates_nothing_on_empty_connections(self):
        fd = FaceDetectionWebRTC()
        mock_loop = MagicMock()
        fd.set_event_loop(mock_loop)
        fd._broadcast(0, False)
        # No error, no calls

    def test_broadcast_handles_exception_in_ws(self):
        fd = FaceDetectionWebRTC()
        mock_loop = MagicMock()
        fd.set_event_loop(mock_loop)
        ws = MagicMock()
        ws.send_json = AsyncMock(side_effect=Exception("send failed"))
        fd.ws_connections.append(ws)
        # Should not raise
        fd._broadcast(1, True)


class TestFaceDetectionWebRTCStartStop:
    def test_start_sets_running(self):
        fd = FaceDetectionWebRTC()
        # Can't fully start without an event loop, but we can test the guard
        fd.running = True
        fd._task = MagicMock()
        fd.start()  # Should be a no-op since running + task already set

    @pytest.mark.asyncio
    async def test_stop_resets_state(self):
        fd = FaceDetectionWebRTC()
        fd.running = True
        fd.health = True
        fd._task = None
        fd._pc = None

        await fd.stop()
        assert fd.running is False
        assert fd.health is False

    @pytest.mark.asyncio
    async def test_stop_cancels_task(self):
        fd = FaceDetectionWebRTC()
        fd.running = True

        # Create a real coroutine-like future that can be awaited after cancel
        loop = asyncio.get_event_loop()
        future = loop.create_future()
        future.cancel()
        fd._task = future
        fd._pc = None

        await fd.stop()
        assert fd._task is None

    @pytest.mark.asyncio
    async def test_stop_closes_peer_connection(self):
        fd = FaceDetectionWebRTC()
        fd.running = True
        fd._task = None
        mock_pc = AsyncMock()
        fd._pc = mock_pc

        await fd.stop()
        mock_pc.close.assert_called_once()
        assert fd._pc is None


class TestFaceDetectionWebRTCStateTracking:
    def test_face_count_tracking(self):
        fd = FaceDetectionWebRTC()
        assert fd.last_face_count == 0
        fd.last_face_count = 3
        assert fd.last_face_count == 3

    def test_detected_tracking(self):
        fd = FaceDetectionWebRTC()
        assert fd.last_detected is False
        fd.last_detected = True
        assert fd.last_detected is True
