# Home Guardian Server V2
# FastAPI server with ESP32 integration, face detection, and optional wake word

import asyncio
import serial
import threading
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from pydantic import BaseModel
from enum import Enum
from typing import Optional
from datetime import datetime
import time
import json
import requests
import uvicorn

# Import face detection module
from face_detection_webrtc import FaceDetectionWebRTC

# Import optional wake word module
try:
    from wake_word import WakeWordDetector
    WAKE_WORD_AVAILABLE = True
except ImportError as e:
    print(f"[WakeWord] Optional module not available: {e}")
    WakeWordDetector = None
    WAKE_WORD_AVAILABLE = False

# Import optional Firebase Cloud Messaging module
try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    FCM_AVAILABLE = True
except ImportError as e:
    print(f"[FCM] Optional module not available: {e}")
    firebase_admin = None
    messaging = None
    FCM_AVAILABLE = False

# Configuration
ESP32_PORT = "/dev/ttyUSB0"  # Update for your system
ESP32_BAUD = 115200
SERIAL_TIMEOUT = 1

# Wake word configuration (optional)

# Set your Picovoice access key here
PICOVOICE_ACCESS_KEY = "picovoice_api_key_here"

# Replace with your .ppn file from https://console.picovoice.ai/
WAKE_WORD_KEYWORD_FILES = ["home_guardian_wake_word.ppn"]

# None for default mic, or specific device index (can be checked by running wake_word.py)
WAKE_WORD_DEVICE_INDEX = None

# Firebase Cloud Messaging configuration (optional)

# Set your Firebase project ID here
FIREBASE_PROJECT_ID = "project-id-here"

# Path to your service account JSON file
FCM_SERVICE_ACCOUNT_FILE = "home-guardian_firebase.json"

# Data models
class CameraMode(str, Enum):
    PATROL = "patrol"
    MANUAL = "manual"
    IDLE = "idle"
    INACTIVE = "inactive"
    SMART = "smart"  # Server-side smart patrol mode

class CameraStatus(BaseModel):
    active: bool
    mode: CameraMode
    current_pan: int
    current_tilt: int
    last_update: str


# Main server class
class HomeGuardianServerV2:
    # Smart patrol state management
    smart_patrol_active = False
    _smart_patrol_task = None

    async def _smart_patrol_loop(self, idle_timeout=10):
        try:
            while self.smart_patrol_active:
                # Start patrol
                self._send_command("MODE_PATROL")
                await asyncio.sleep(0.2)
                # Wait for face detection
                while self.smart_patrol_active and not self.face_detection.last_detected:
                    await asyncio.sleep(1)
                if not self.smart_patrol_active:
                    break
                # Face detected, go idle
                self._send_command("MODE_IDLE")
                await asyncio.sleep(0.2)
                # Wait for no face for idle_timeout seconds
                idle_time = 0
                while self.smart_patrol_active and self.face_detection.last_detected:
                    await asyncio.sleep(1)
                    idle_time += 1
                    if idle_time >= idle_timeout:
                        break
                # If still active, loop will restart and patrol again
        except Exception as e:
            print(f"[SmartPatrol] Error: {e}")

    async def start_smart_patrol(self):
        if not self.smart_patrol_active:
            self.smart_patrol_active = True
            # Send initial patrol command immediately
            self._send_command("MODE_PATROL")
            await asyncio.sleep(0.2)
            self._smart_patrol_task = asyncio.create_task(self._smart_patrol_loop())

    async def stop_smart_patrol(self):
        self.smart_patrol_active = False
        if self._smart_patrol_task:
            self._smart_patrol_task.cancel()
            self._smart_patrol_task = None
        # Send command to put ESP32 back to idle mode
        self._send_command("MODE_IDLE")
        await asyncio.sleep(0.2)

    async def cleanup(self):
        """Clean shutdown of all server components"""
        # Stop smart patrol if running
        if self.smart_patrol_active:
            await self.stop_smart_patrol()
        # Close manual WebSocket if active
        if self.manual_ws:
            try:
                await self.manual_ws.close(code=1001, reason="Server shutting down")
            except:
                pass
            self.manual_ws = None
            self.manual_mode_active = False
        # Stop face detection
        await self.face_detection.stop()
        # Stop wake word detection (optional)
        if self.wake_word:
            self.wake_word.stop()
        # Close serial connection
        if self.serial_connection and self.serial_connection.is_open:
            self.serial_connection.close()

    def _on_wake_word_detected(self, keyword_index):
        """Callback when wake word is detected"""
        print(f"[WakeWord] Wake word detected! Index: {keyword_index}")
        # TODO: Add other wake word actions below
        if self.fcm_enabled:
            try:
                self._send_wake_word_notification(keyword_index)
            except Exception as e:
                print(f"[FCM] Error sending wake word notification: {e}")
        

    def is_webrtc_stream_ready(self, path_name="cam"):
        import requests
        try:
            resp = requests.get(f"http://localhost:9997/v3/paths/get/{path_name}", timeout=2)
            if resp.status_code == 200:
                data = resp.json()
                return data.get("ready", False)
            return False
        except Exception:
            return False

    def _send_wake_word_notification(self, keyword_index):
        """Send high-priority FCM notification to 'wake-word' topic when wake word is detected"""
        if not self.fcm_enabled:
            return
        
        try:
            message = messaging.Message(
                topic='wake-word',
                notification=messaging.Notification(
                    title='🚨 Home Guardian Alert',
                    body=f'Wake word detected! System activated at {datetime.now().strftime("%H:%M:%S")}'
                ),
                data={
                    'type': 'wake_word',
                    'keyword_index': str(keyword_index),
                    'timestamp': datetime.now().isoformat(),
                    'server_status': 'active'
                },
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        icon='ic_notification',
                        color='#FF5722',
                        channel_id='wake_word_alerts'
                    )
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            alert=messaging.ApsAlert(
                                title='🚨 Home Guardian Alert',
                                body=f'Wake word detected! System activated at {datetime.now().strftime("%H:%M:%S")}'
                            ),
                            sound='default',
                            badge=1
                        )
                    ),
                    headers={'apns-priority': '10'}
                )
            )
            
            response = messaging.send(message)
            print(f"[FCM] Wake word notification sent successfully: {response}")
            
        except Exception as e:
            print(f"[FCM] Error sending wake word notification: {e}")


    def __init__(self, port=ESP32_PORT, baud=ESP32_BAUD):
        self.app = FastAPI(title="Home Guardian API v2")
        self.serial_port = port
        self.baud_rate = baud
        self.serial_connection = None
        self.serial_thread = None
        self.status_lock = threading.Lock()
        self.manual_mode_active = False
        self.manual_ws = None
        self.camera_status = CameraStatus(
            active=False,
            mode=CameraMode.INACTIVE,
            current_pan=90,
            current_tilt=90,
            last_update=datetime.now().isoformat()
        )
        # --- Face Detection (WebRTC/aiortc) ---
        self.face_detection = FaceDetectionWebRTC()
        
        # --- Wake Word Detection (Optional) ---
        self.wake_word = None
        if WAKE_WORD_AVAILABLE and PICOVOICE_ACCESS_KEY and WAKE_WORD_KEYWORD_FILES:
            try:
                self.wake_word = WakeWordDetector(
                    access_key=PICOVOICE_ACCESS_KEY,
                    keyword_paths=WAKE_WORD_KEYWORD_FILES,
                    device_index=WAKE_WORD_DEVICE_INDEX,
                    on_wake_word=self._on_wake_word_detected
                )
                print(f"[WakeWord] Wake word detector initialized with keywords: {WAKE_WORD_KEYWORD_FILES}")
            except Exception as e:
                print(f"[WakeWord] Failed to initialize wake word detector: {e}")
                print("[WakeWord] Make sure you've created custom wake word files at https://console.picovoice.ai/")
                self.wake_word = None
        elif WAKE_WORD_AVAILABLE and not PICOVOICE_ACCESS_KEY:
            print("[WakeWord] Wake word available but no access key provided")
        elif WAKE_WORD_AVAILABLE and not WAKE_WORD_KEYWORD_FILES:
            print("[WakeWord] Wake word available but no keyword files specified")
            print("[WakeWord] Set WAKE_WORD_KEYWORD_FILES = ['your_keyword.ppn'] after creating at https://console.picovoice.ai/")
        
        # --- Firebase Cloud Messaging (Optional) ---
        self.fcm_enabled = False
        if FCM_AVAILABLE and FIREBASE_PROJECT_ID and FCM_SERVICE_ACCOUNT_FILE:
            try:
                import os
                if os.path.exists(FCM_SERVICE_ACCOUNT_FILE):
                    cred = credentials.Certificate(FCM_SERVICE_ACCOUNT_FILE)
                    firebase_admin.initialize_app(cred, {
                        'projectId': FIREBASE_PROJECT_ID,
                    })
                    self.fcm_enabled = True
                    print(f"[FCM] Firebase Cloud Messaging initialized for project: {FIREBASE_PROJECT_ID}")
                else:
                    print(f"[FCM] Service account file not found: {FCM_SERVICE_ACCOUNT_FILE}")
                    print("[FCM] Download service account JSON from Firebase Console > Project Settings > Service Accounts")
            except Exception as e:
                print(f"[FCM] Failed to initialize Firebase Cloud Messaging: {e}")
                self.fcm_enabled = False
        elif FCM_AVAILABLE and not FIREBASE_PROJECT_ID:
            print("[FCM] Firebase Cloud Messaging available but no project ID provided")
        elif FCM_AVAILABLE and not FCM_SERVICE_ACCOUNT_FILE:
            print("[FCM] Firebase Cloud Messaging available but no service account file specified")
        elif not FCM_AVAILABLE:
            print("[FCM] Firebase Cloud Messaging not available - install firebase-admin to enable")
        
        self._connect_serial()
        self._setup_routes()
        # Set event loop after FastAPI is running using lifespan
        from contextlib import asynccontextmanager

        @asynccontextmanager
        async def lifespan(app):
            # Startup
            loop = asyncio.get_running_loop()
            self.face_detection.set_event_loop(loop)
            # Start face detection as a background task
            self.face_detection.start()
            # Start wake word detection (optional)
            if self.wake_word:
                self.wake_word.start()
            yield
            # Shutdown cleanup
            print("[HomeGuardianServer] Shutting down...")
            await self.cleanup()
            print("[HomeGuardianServer] Shutdown complete")

        self.app.router.lifespan_context = lifespan

    def _connect_serial(self):
        try:
            self.serial_connection = serial.Serial(self.serial_port, self.baud_rate, timeout=SERIAL_TIMEOUT)
        except Exception as e:
            self.serial_connection = None

    def _send_command(self, cmd: str):
        if not self.serial_connection:
            raise HTTPException(status_code=503, detail="ESP32 not connected")
        try:
            self.serial_connection.write(f"{cmd}\n".encode())
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Serial error: {e}")

    def _read_status(self, timeout=1.0):
        # Send STATUS command and parse response
        try:
            self._send_command("STATUS")
            start = time.time()
            while time.time() - start < timeout:
                if self.serial_connection.in_waiting > 0:
                    line = self.serial_connection.readline().decode('utf-8').strip()
                    if line.startswith("STATUS:"):
                        parts = line[7:].split(',')
                        if len(parts) >= 4:
                            pan = int(parts[0])
                            tilt = int(parts[1])
                            mode = parts[2].lower()
                            servos = parts[3]
                            with self.status_lock:
                                self.camera_status.current_pan = pan
                                self.camera_status.current_tilt = tilt
                                self.camera_status.active = (servos == "ATTACHED")
                                
                                # Override mode if smart patrol is active
                                if self.smart_patrol_active and mode == "patrol":
                                    self.camera_status.mode = CameraMode.SMART
                                else:
                                    self.camera_status.mode = CameraMode(mode) if mode in CameraMode.__members__.values() else CameraMode.INACTIVE
                                
                                self.camera_status.last_update = datetime.now().isoformat()
                            return self.camera_status
                time.sleep(0.05)  # Small delay to prevent busy waiting
            raise HTTPException(status_code=504, detail="ESP32 status timeout - device may be busy")
        except Exception as e:
            if isinstance(e, HTTPException):
                raise e
            raise HTTPException(status_code=500, detail=f"Status read error: {e}")


    async def _execute_command(self, command: str, delay: float = 0.2):
        """Stop smart patrol if active, send a command, wait, and return status.

        Consolidates the repeated pattern used across servo/patrol endpoints.
        """
        if self.smart_patrol_active:
            await self.stop_smart_patrol()
        self._send_command(command)
        await asyncio.sleep(delay)
        return self._read_status()

    def _setup_routes(self):
        app = self.app
        server = self

        @app.post("/api/smart_patrol/start")
        async def start_smart_patrol():
            await server.start_smart_patrol()
            return server._read_status()

        @app.post("/api/smart_patrol/stop")
        async def stop_smart_patrol():
            await server.stop_smart_patrol()
            return server._read_status()

        @app.get("/api/health")
        async def health_check():
            # Check ESP32 connection
            esp32_connected = server.serial_connection is not None and server.serial_connection.is_open
            # Check MediaMTX WebRTC/camera stream readiness
            webrtc_connected = server.is_webrtc_stream_ready("cam")
            # Check face detection health
            face_detection_healthy = server.face_detection.is_healthy()
            # Check wake word health (optional - doesn't affect ready status)
            wake_word_healthy = server.wake_word.is_healthy() if server.wake_word else None
            # Check FCM health (optional - doesn't affect ready status)
            fcm_healthy = server.fcm_enabled
            # Ready only if CORE modules are connected/healthy (wake word and FCM are optional)
            ready = esp32_connected and webrtc_connected and face_detection_healthy
            
            health_status = {
                "home_guardian": True,
                "version": "2.0",
                "esp32_connected": esp32_connected,
                "webrtc_connected": webrtc_connected,
                "face_detection_healthy": face_detection_healthy,
                "ready": ready
            }
            
            # Add wake word status if available
            if server.wake_word:
                health_status["wake_word_healthy"] = wake_word_healthy
                health_status["wake_word_stats"] = server.wake_word.get_stats()
            else:
                health_status["wake_word_healthy"] = None
                health_status["wake_word_message"] = "Wake word module not available or not configured"
            
            # Add FCM status if available
            health_status["fcm_healthy"] = fcm_healthy
            if not fcm_healthy:
                if not FCM_AVAILABLE:
                    health_status["fcm_message"] = "Firebase Cloud Messaging not available - install firebase-admin to enable"
                elif not FIREBASE_PROJECT_ID:
                    health_status["fcm_message"] = "Firebase project ID not configured"
                elif not FCM_SERVICE_ACCOUNT_FILE:
                    health_status["fcm_message"] = "Firebase service account file not specified"
                else:
                    health_status["fcm_message"] = "Firebase Cloud Messaging not configured or failed to initialize"
            else:
                health_status["fcm_message"] = f"Firebase Cloud Messaging ready for project: {FIREBASE_PROJECT_ID}"
            
            return health_status

        @app.get("/api/status")
        async def get_status():
            if server.manual_mode_active:
                # Don't poll status in manual mode
                return server.camera_status
            return server._read_status()

        @app.post("/api/servos/attach")
        async def attach_servos():
            return await server._execute_command("ATTACH", delay=0.5)

        @app.post("/api/servos/detach")
        async def detach_servos():
            return await server._execute_command("DETACH", delay=0.5)

        @app.post("/api/servos/center")
        async def center_servos():
            return await server._execute_command("CENTER")

        @app.post("/api/patrol/start")
        async def start_patrol():
            return await server._execute_command("MODE_PATROL")

        @app.post("/api/patrol/stop")
        async def stop_patrol():
            return await server._execute_command("MODE_IDLE")


        @app.websocket("/ws/manual")
        async def manual_mode_ws(websocket: WebSocket):
            await websocket.accept()
            if server.manual_mode_active:
                await websocket.close(code=4000)
                return
            if server.smart_patrol_active:
                await server.stop_smart_patrol()
            server.manual_mode_active = True
            server.manual_ws = websocket
            try:
                # Enter manual mode
                server._send_command("MODE_MANUAL")
                with server.status_lock:
                    server.camera_status.mode = CameraMode.MANUAL
                    server.camera_status.last_update = datetime.now().isoformat()
                
                # Send initial status to client
                initial_status = {
                    "type": "status",
                    "active": server.camera_status.active,
                    "mode": server.camera_status.mode,
                    "current_pan": server.camera_status.current_pan,
                    "current_tilt": server.camera_status.current_tilt,
                    "last_update": server.camera_status.last_update
                }
                await websocket.send_text(json.dumps(initial_status))
                
                while True:
                    data = await websocket.receive_text()
                    try:
                        msg = json.loads(data)
                        pan = int(msg.get("pan", 90))
                        tilt = int(msg.get("tilt", 90))
                        pan = max(0, min(170, pan))
                        tilt = max(0, min(150, tilt))
                        server._send_command(f"PANTILT{pan},{tilt}")
                        with server.status_lock:
                            server.camera_status.current_pan = pan
                            server.camera_status.current_tilt = tilt
                            server.camera_status.last_update = datetime.now().isoformat()
                    except Exception as e:
                        await websocket.send_text(json.dumps({"error": str(e)}))
            except WebSocketDisconnect:
                pass
            finally:
                # Exit manual mode
                server._send_command("MODE_IDLE")
                await asyncio.sleep(0.3)  # Give ESP32 time to process mode change
                with server.status_lock:
                    server.camera_status.mode = CameraMode.IDLE
                    server.camera_status.last_update = datetime.now().isoformat()
                server.manual_mode_active = False
                server.manual_ws = None

        @app.websocket("/ws/face_detection")
        async def face_detection_ws(websocket: WebSocket):
            await websocket.accept()
            server.face_detection.add_ws(websocket)
            try:
                while True:
                    await asyncio.sleep(60)
            except WebSocketDisconnect:
                pass
            finally:
                server.face_detection.remove_ws(websocket)

# --- Run Server ---
server = HomeGuardianServerV2()
app = server.app

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8234)
