import asyncio
import time
import json
import sys
import os
from unittest.mock import MagicMock, AsyncMock, patch, PropertyMock
from datetime import datetime

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

# Mock heavy dependencies before importing server modules
sys.modules.setdefault("cv2", MagicMock())
sys.modules.setdefault("aiortc", MagicMock())
sys.modules.setdefault("aiohttp", MagicMock())
sys.modules.setdefault("pvporcupine", MagicMock())
sys.modules.setdefault("sounddevice", MagicMock())
sys.modules.setdefault("numpy", MagicMock())
sys.modules.setdefault("firebase_admin", MagicMock())
sys.modules.setdefault("firebase_admin.credentials", MagicMock())
sys.modules.setdefault("firebase_admin.messaging", MagicMock())
sys.modules.setdefault("uvicorn", MagicMock())


class TestCameraMode:
    def test_enum_values(self):
        from home_guardian_server_v2 import CameraMode

        assert CameraMode.PATROL == "patrol"
        assert CameraMode.MANUAL == "manual"
        assert CameraMode.IDLE == "idle"
        assert CameraMode.INACTIVE == "inactive"
        assert CameraMode.SMART == "smart"

    def test_enum_from_string(self):
        from home_guardian_server_v2 import CameraMode

        assert CameraMode("patrol") == CameraMode.PATROL
        assert CameraMode("idle") == CameraMode.IDLE

    def test_enum_invalid_raises(self):
        from home_guardian_server_v2 import CameraMode

        with pytest.raises(ValueError):
            CameraMode("nonexistent")

    def test_all_modes_present(self):
        from home_guardian_server_v2 import CameraMode

        modes = list(CameraMode)
        assert len(modes) == 5


class TestCameraStatusModel:
    def test_create_camera_status(self):
        from home_guardian_server_v2 import CameraStatus, CameraMode

        now = datetime.now().isoformat()
        status = CameraStatus(
            active=True,
            mode=CameraMode.IDLE,
            current_pan=90,
            current_tilt=90,
            last_update=now,
        )
        assert status.active is True
        assert status.mode == CameraMode.IDLE
        assert status.current_pan == 90
        assert status.current_tilt == 90
        assert status.last_update == now

    def test_camera_status_serialization(self):
        from home_guardian_server_v2 import CameraStatus, CameraMode

        status = CameraStatus(
            active=False,
            mode=CameraMode.PATROL,
            current_pan=45,
            current_tilt=120,
            last_update="2025-01-01T00:00:00",
        )
        data = status.model_dump()
        assert data["active"] is False
        assert data["mode"] == "patrol"
        assert data["current_pan"] == 45
        assert data["current_tilt"] == 120

    def test_camera_status_inactive(self):
        from home_guardian_server_v2 import CameraStatus, CameraMode

        status = CameraStatus(
            active=False,
            mode=CameraMode.INACTIVE,
            current_pan=90,
            current_tilt=90,
            last_update="2025-01-01T00:00:00",
        )
        assert status.active is False
        assert status.mode == CameraMode.INACTIVE


class TestIsWebRTCStreamReady:
    @patch("home_guardian_server_v2.serial.Serial")
    @patch("home_guardian_server_v2.FaceDetectionWebRTC")
    def test_stream_ready(self, mock_fd_cls, mock_serial):
        mock_fd_cls.return_value = MagicMock()
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        with patch("requests.get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.json.return_value = {"ready": True}
            mock_get.return_value = mock_resp

            assert server.is_webrtc_stream_ready("cam") is True

    @patch("home_guardian_server_v2.serial.Serial")
    @patch("home_guardian_server_v2.FaceDetectionWebRTC")
    def test_stream_not_ready(self, mock_fd_cls, mock_serial):
        mock_fd_cls.return_value = MagicMock()
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        with patch("requests.get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 200
            mock_resp.json.return_value = {"ready": False}
            mock_get.return_value = mock_resp

            assert server.is_webrtc_stream_ready("cam") is False

    @patch("home_guardian_server_v2.serial.Serial")
    @patch("home_guardian_server_v2.FaceDetectionWebRTC")
    def test_stream_connection_error(self, mock_fd_cls, mock_serial):
        mock_fd_cls.return_value = MagicMock()
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        with patch("requests.get", side_effect=Exception("connection refused")):
            assert server.is_webrtc_stream_ready("cam") is False

    @patch("home_guardian_server_v2.serial.Serial")
    @patch("home_guardian_server_v2.FaceDetectionWebRTC")
    def test_stream_non_200(self, mock_fd_cls, mock_serial):
        mock_fd_cls.return_value = MagicMock()
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        with patch("requests.get") as mock_get:
            mock_resp = MagicMock()
            mock_resp.status_code = 404
            mock_get.return_value = mock_resp

            assert server.is_webrtc_stream_ready("cam") is False


class TestSendCommand:
    def test_send_command_no_connection(self):
        from home_guardian_server_v2 import HomeGuardianServerV2
        from fastapi import HTTPException

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        server.serial_connection = None

        with pytest.raises(HTTPException) as exc_info:
            server._send_command("TEST")
        assert exc_info.value.status_code == 503

    def test_send_command_writes_to_serial(self):
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        mock_serial = MagicMock()
        server.serial_connection = mock_serial

        server._send_command("MODE_PATROL")
        mock_serial.write.assert_called_once_with(b"MODE_PATROL\n")

    def test_send_command_serial_error(self):
        from home_guardian_server_v2 import HomeGuardianServerV2
        from fastapi import HTTPException

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        mock_serial = MagicMock()
        mock_serial.write.side_effect = Exception("serial write error")
        server.serial_connection = mock_serial

        with pytest.raises(HTTPException) as exc_info:
            server._send_command("TEST")
        assert exc_info.value.status_code == 500


class TestSmartPatrol:
    @pytest.mark.asyncio
    async def test_start_smart_patrol(self):
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        server.smart_patrol_active = False
        server._smart_patrol_task = None
        server.serial_connection = MagicMock()
        server.face_detection = MagicMock()

        # Patch asyncio.create_task to avoid actually running the loop
        with patch("asyncio.create_task") as mock_create_task:
            mock_create_task.return_value = MagicMock()
            await server.start_smart_patrol()

        assert server.smart_patrol_active is True
        server.serial_connection.write.assert_called_with(b"MODE_PATROL\n")

    @pytest.mark.asyncio
    async def test_start_smart_patrol_already_active(self):
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        server.smart_patrol_active = True
        server._smart_patrol_task = MagicMock()
        server.serial_connection = MagicMock()

        await server.start_smart_patrol()
        # Should not send command again since already active
        server.serial_connection.write.assert_not_called()

    @pytest.mark.asyncio
    async def test_stop_smart_patrol(self):
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        server.smart_patrol_active = True
        mock_task = MagicMock()
        mock_task.cancel = MagicMock()
        server._smart_patrol_task = mock_task
        server.serial_connection = MagicMock()

        await server.stop_smart_patrol()

        assert server.smart_patrol_active is False
        assert server._smart_patrol_task is None
        mock_task.cancel.assert_called_once()
        server.serial_connection.write.assert_called_with(b"MODE_IDLE\n")


class TestCleanup:
    @pytest.mark.asyncio
    async def test_cleanup_stops_smart_patrol(self):
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        server.smart_patrol_active = True
        server._smart_patrol_task = MagicMock()
        server._smart_patrol_task.cancel = MagicMock()
        server.serial_connection = MagicMock()
        server.serial_connection.is_open = True
        server.manual_ws = None
        server.manual_mode_active = False
        server.face_detection = AsyncMock()
        server.wake_word = None

        await server.cleanup()
        assert server.smart_patrol_active is False

    @pytest.mark.asyncio
    async def test_cleanup_closes_manual_ws(self):
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        server.smart_patrol_active = False
        server._smart_patrol_task = None
        mock_ws = AsyncMock()
        server.manual_ws = mock_ws
        server.manual_mode_active = True
        server.serial_connection = MagicMock()
        server.serial_connection.is_open = True
        server.face_detection = AsyncMock()
        server.wake_word = None

        await server.cleanup()
        mock_ws.close.assert_called_once()
        assert server.manual_ws is None
        assert server.manual_mode_active is False

    @pytest.mark.asyncio
    async def test_cleanup_closes_serial(self):
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        server.smart_patrol_active = False
        server._smart_patrol_task = None
        server.manual_ws = None
        server.manual_mode_active = False
        mock_serial = MagicMock()
        mock_serial.is_open = True
        server.serial_connection = mock_serial
        server.face_detection = AsyncMock()
        server.wake_word = None

        await server.cleanup()
        mock_serial.close.assert_called_once()

    @pytest.mark.asyncio
    async def test_cleanup_stops_wake_word(self):
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        server.smart_patrol_active = False
        server._smart_patrol_task = None
        server.manual_ws = None
        server.manual_mode_active = False
        server.serial_connection = MagicMock()
        server.serial_connection.is_open = False
        server.face_detection = AsyncMock()
        mock_wake_word = MagicMock()
        server.wake_word = mock_wake_word

        await server.cleanup()
        mock_wake_word.stop.assert_called_once()


class TestOnWakeWordDetected:
    def test_callback_with_fcm_disabled(self):
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        server.fcm_enabled = False

        # Should not raise
        server._on_wake_word_detected(0)

    def test_callback_with_fcm_enabled(self):
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        server.fcm_enabled = True
        server._send_wake_word_notification = MagicMock()

        server._on_wake_word_detected(0)
        server._send_wake_word_notification.assert_called_once_with(0)

    def test_callback_fcm_error_handled(self):
        from home_guardian_server_v2 import HomeGuardianServerV2

        server = HomeGuardianServerV2.__new__(HomeGuardianServerV2)
        server.fcm_enabled = True
        server._send_wake_word_notification = MagicMock(
            side_effect=Exception("FCM error")
        )

        # Should not raise
        server._on_wake_word_detected(0)
