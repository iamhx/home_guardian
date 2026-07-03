import sys
import os
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))


class TestWakeWordDetectorInit:
    def test_init_with_required_args(self):
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            from wake_word import WakeWordDetector

            detector = WakeWordDetector(
                access_key="test_key",
                keyword_paths=["keyword.ppn"],
            )
            assert detector.access_key == "test_key"
            assert detector.keyword_paths == ["keyword.ppn"]
            assert detector.sensitivities == [0.5]
            assert detector.device_index is None
            assert detector.on_wake_word is None
            assert detector.running is False
            assert detector.health is False
            assert detector.detections_count == 0
            assert detector.last_detection_time is None

    def test_init_with_custom_sensitivities(self):
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            from wake_word import WakeWordDetector

            detector = WakeWordDetector(
                access_key="test_key",
                keyword_paths=["kw1.ppn", "kw2.ppn"],
                sensitivities=[0.7, 0.3],
            )
            assert detector.sensitivities == [0.7, 0.3]

    def test_init_default_sensitivities_match_keywords_count(self):
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            from wake_word import WakeWordDetector

            detector = WakeWordDetector(
                access_key="test_key",
                keyword_paths=["kw1.ppn", "kw2.ppn", "kw3.ppn"],
            )
            assert detector.sensitivities == [0.5, 0.5, 0.5]

    def test_init_with_device_index(self):
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            from wake_word import WakeWordDetector

            detector = WakeWordDetector(
                access_key="key",
                keyword_paths=["kw.ppn"],
                device_index=4,
            )
            assert detector.device_index == 4

    def test_init_with_callback(self):
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            from wake_word import WakeWordDetector

            callback = MagicMock()
            detector = WakeWordDetector(
                access_key="key",
                keyword_paths=["kw.ppn"],
                on_wake_word=callback,
            )
            assert detector.on_wake_word is callback

    def test_init_empty_keyword_paths_raises(self):
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            from wake_word import WakeWordDetector

            with pytest.raises(ValueError, match="keyword_paths is required"):
                WakeWordDetector(
                    access_key="key",
                    keyword_paths=[],
                )

    def test_init_pvporcupine_not_installed(self):
        # Simulate pvporcupine not being installed
        import importlib

        with patch.dict("sys.modules", {"pvporcupine": None}):
            # Force reimport
            if "wake_word" in sys.modules:
                del sys.modules["wake_word"]
            with pytest.raises(ImportError):
                from wake_word import WakeWordDetector

                WakeWordDetector(
                    access_key="key",
                    keyword_paths=["kw.ppn"],
                )


class TestWakeWordDetectorHealth:
    def test_is_healthy_default(self):
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            if "wake_word" in sys.modules:
                del sys.modules["wake_word"]
            from wake_word import WakeWordDetector

            detector = WakeWordDetector(
                access_key="key",
                keyword_paths=["kw.ppn"],
            )
            assert detector.is_healthy() is False

    def test_is_healthy_requires_all_conditions(self):
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            if "wake_word" in sys.modules:
                del sys.modules["wake_word"]
            from wake_word import WakeWordDetector

            detector = WakeWordDetector(
                access_key="key",
                keyword_paths=["kw.ppn"],
            )
            # Only health=True is not enough
            detector.health = True
            assert detector.is_healthy() is False

            # health + running, but no porcupine
            detector.running = True
            detector.porcupine = None
            assert detector.is_healthy() is False

            # All three conditions met
            detector.porcupine = MagicMock()
            assert detector.is_healthy() is True


class TestWakeWordDetectorStats:
    def test_get_stats_initial(self):
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            if "wake_word" in sys.modules:
                del sys.modules["wake_word"]
            from wake_word import WakeWordDetector

            detector = WakeWordDetector(
                access_key="key",
                keyword_paths=["kw.ppn"],
            )
            stats = detector.get_stats()
            assert stats["running"] is False
            assert stats["healthy"] is False
            assert stats["detections_count"] == 0
            assert stats["last_detection_time"] is None

    def test_get_stats_after_detection(self):
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            if "wake_word" in sys.modules:
                del sys.modules["wake_word"]
            from wake_word import WakeWordDetector

            detector = WakeWordDetector(
                access_key="key",
                keyword_paths=["kw.ppn"],
            )
            detector.running = True
            detector.health = True
            detector.porcupine = MagicMock()
            detector.detections_count = 5
            detector.last_detection_time = 1234567890.0

            stats = detector.get_stats()
            assert stats["running"] is True
            assert stats["healthy"] is True
            assert stats["detections_count"] == 5
            assert stats["last_detection_time"] == 1234567890.0


class TestWakeWordDetectorStartStop:
    def test_start_already_running(self):
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            if "wake_word" in sys.modules:
                del sys.modules["wake_word"]
            from wake_word import WakeWordDetector

            detector = WakeWordDetector(
                access_key="key",
                keyword_paths=["kw.ppn"],
            )
            detector.running = True
            detector.start()  # Should be a no-op

    def test_stop_when_not_running(self):
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            if "wake_word" in sys.modules:
                del sys.modules["wake_word"]
            from wake_word import WakeWordDetector

            detector = WakeWordDetector(
                access_key="key",
                keyword_paths=["kw.ppn"],
            )
            detector.stop()  # Should not raise

    def test_stop_cleans_up_resources(self):
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            if "wake_word" in sys.modules:
                del sys.modules["wake_word"]
            from wake_word import WakeWordDetector

            detector = WakeWordDetector(
                access_key="key",
                keyword_paths=["kw.ppn"],
            )
            detector.running = True
            detector.health = True
            mock_stream = MagicMock()
            detector._audio_stream = mock_stream
            mock_porcupine = MagicMock()
            detector.porcupine = mock_porcupine

            detector.stop()

            assert detector.running is False
            assert detector.health is False
            mock_stream.stop.assert_called_once()
            mock_stream.close.assert_called_once()
            assert detector._audio_stream is None
            mock_porcupine.delete.assert_called_once()
            assert detector.porcupine is None


class TestWakeWordDetectorListDevices:
    def test_list_audio_devices(self):
        mock_devices = [
            {"name": "pulse", "max_input_channels": 2, "default_samplerate": 44100.0},
            {"name": "hw:0,0", "max_input_channels": 2, "default_samplerate": 48000.0},
            {"name": "USB Mic", "max_input_channels": 1, "default_samplerate": 16000.0},
            {"name": "HDMI Output", "max_input_channels": 0, "default_samplerate": 48000.0},
        ]
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            if "wake_word" in sys.modules:
                del sys.modules["wake_word"]
            from wake_word import WakeWordDetector

            with patch("sounddevice.query_devices", return_value=mock_devices):
                devices = WakeWordDetector.list_audio_devices()

            # Should exclude HDMI Output (0 input channels)
            assert len(devices) == 3

            # pulse is virtual, recommended
            assert devices[0]["name"] == "pulse"
            assert devices[0]["recommended"] is True
            assert devices[0]["type"] == "virtual"

            # hw:0,0 is hardware, not recommended
            assert devices[1]["name"] == "hw:0,0"
            assert devices[1]["recommended"] is False
            assert devices[1]["type"] == "hardware"

            # USB Mic is recommended (has USB in name)
            assert devices[2]["name"] == "USB Mic"
            assert devices[2]["recommended"] is True

    def test_list_audio_devices_error(self):
        with patch.dict("sys.modules", {"pvporcupine": MagicMock()}):
            if "wake_word" in sys.modules:
                del sys.modules["wake_word"]
            from wake_word import WakeWordDetector

            with patch("sounddevice.query_devices", side_effect=Exception("no audio")):
                devices = WakeWordDetector.list_audio_devices()
            assert devices == []
