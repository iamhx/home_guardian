# Home Guardian Server V2

Complete smart surveillance system with ESP32 integration, face detection, manual control, optional wake word detection, and optional Firebase Cloud Messaging (push notifications).

## 🚀 Quick Setup

**Option 1: Automated Setup (Recommended)**
```bash
chmod +x setup_home_guardian.sh
./setup_home_guardian.sh    # Installs all dependencies (wake word and FCM gracefully fallback if not configured)
```

**Option 2: Manual Setup**
```bash
# Install system dependencies (Ubuntu/Debian)
sudo apt update && sudo apt install -y python3-dev python3-pip python3-venv
sudo apt install -y libavcodec-dev libavformat-dev libswscale-dev libopus-dev libvpx-dev

# Create virtual environment and install dependencies
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt          # All dependencies included
```

## 📦 Migration Package

Transfer these files to deploy on fresh machine:
- `home_guardian_server_v2.py` (main server)
- `face_detection_webrtc.py` (face detection module) 
- `wake_word.py` (wake word module)
- `esp32_home_guardian_v2.ino` (ESP32 firmware)
- `requirements.txt` (all dependencies)
- `setup_home_guardian.sh` (automated setup)
- `home-guardian_firebase.json` (if using FCM - rename your service account file)

## ⚙️ Configuration

### Environment Variables

All configuration is loaded from environment variables (no secrets in source code).
Create a `.env` file or export them in your shell:

```bash
# ESP32 serial connection
export ESP32_PORT="/dev/ttyUSB0"        # default: /dev/ttyUSB0
export ESP32_BAUD="115200"               # default: 115200

# Server binding (defaults to localhost for safety)
export SERVER_HOST="127.0.0.1"           # use 0.0.0.0 only on trusted networks
export SERVER_PORT="8234"                # default: 8234

# CORS allowed origins (comma-separated, empty = deny all cross-origin)
export CORS_ORIGINS="http://localhost:3000"

# Wake word (optional)
export PICOVOICE_ACCESS_KEY="your_access_key"
export WAKE_WORD_KEYWORD_FILES="home_guardian_wake_word.ppn"
export WAKE_WORD_DEVICE_INDEX=""         # empty for default mic

# Firebase Cloud Messaging (optional)
export FIREBASE_PROJECT_ID="your-project-id"
export FCM_SERVICE_ACCOUNT_FILE="home-guardian_firebase.json"
```

### ESP32 Setup
1. Flash `esp32_home_guardian_v2.ino` to your ESP32
2. Set `ESP32_PORT` env var if needed (default: `/dev/ttyUSB0`)
3. Servo pins are configured in the .ino file (default: pan=33, tilt=27)
4. ESP32 baud rate: 115200 (configurable via `ESP32_BAUD`)

### Wake Word Setup (Optional)
1. Get free access key from https://console.picovoice.ai/
2. **Create custom wake word**:
   - Go to Porcupine section in console
   - Click "Create Keyword" 
   - Type your custom phrase (e.g., "home guardian", "activate system", "hello computer")
   - Download the `.ppn` file to your project folder
3. Set environment variables:
   ```bash
   export PICOVOICE_ACCESS_KEY="your_access_key_here"
   export WAKE_WORD_KEYWORD_FILES="your_custom_keyword.ppn"
   # export WAKE_WORD_DEVICE_INDEX=4  # optional: specific device index
   ```
4. Test with: `python wake_word.py`

### Firebase Cloud Messaging Setup (Optional)
1. Go to Firebase Console: https://console.firebase.google.com/
2. Create or select your project
3. **Generate service account key**:
   - Go to Project Settings > Service Accounts
   - Click "Generate new private key" 
   - Save as `home-guardian_firebase.json` in your project folder
4. Set environment variables:
   ```bash
   export FIREBASE_PROJECT_ID="your-project-id"
   export FCM_SERVICE_ACCOUNT_FILE="home-guardian_firebase.json"
   ```
5. Test FCM connectivity in health endpoint

### MediaMTX Setup
1. Download MediaMTX server from https://github.com/bluenviron/mediamtx
2. Configure for port 8889 (default for face detection)
3. Connect webcam for face detection
4. **Note**: Face detection uses MediaMTX WebRTC endpoint at `http://localhost:9997/v3/paths/get/cam`
5. If you change MediaMTX ports, update `face_detection_webrtc.py` accordingly

## 🔧 Development & Testing

This is a **development/testing system**, not production-ready. Perfect for:
- Learning IoT integration patterns
- Experimenting with WebRTC + face detection  
- Building custom surveillance solutions
- Rapid prototyping with ESP32 + servos

### Simple Startup
```bash
# After setup, just activate and run
source venv/bin/activate
python3 home_guardian_server_v2.py
```

### Manual Installation (Alternative)
```bash
# Skip the automated setup if you prefer manual control
sudo pip3 install -r requirements.txt  # or requirements_full.txt
python3 home_guardian_server_v2.py
```

## 🌐 API Endpoints

### REST API Endpoints
| Endpoint | Method | Purpose | Response |
|----------|--------|---------|----------|
| `/api/health` | GET | System health check | Health status of all components |
| `/api/status` | GET | Current camera status | Camera position, mode, active state |
| `/api/servos/attach` | POST | Attach/power on servos | Updated camera status |
| `/api/servos/detach` | POST | Detach/power off servos | Updated camera status |
| `/api/servos/center` | POST | Center camera position | Updated camera status |
| `/api/patrol/start` | POST | Start basic patrol mode | Updated camera status |
| `/api/patrol/stop` | POST | Stop patrol (idle mode) | Updated camera status |
| `/api/smart_patrol/start` | POST | Start AI-powered smart patrol | Updated camera status |
| `/api/smart_patrol/stop` | POST | Stop smart patrol | Updated camera status |

### WebSocket Endpoints
| Endpoint | Purpose | Data Format |
|----------|---------|-------------|
| `/ws/manual` | Real-time manual camera control | `{"pan": 90, "tilt": 90}` |
| `/ws/face_detection` | Face detection event stream | Face detection status updates |

### Health Check Response
```json
{
  "home_guardian": true,
  "version": "2.0",
  "esp32_connected": true,
  "webrtc_connected": true,
  "face_detection_healthy": true,
  "wake_word_healthy": true,
  "wake_word_stats": {
    "detections": 0,
    "uptime": "00:05:23"
  },
  "fcm_healthy": true,
  "fcm_message": "Firebase Cloud Messaging ready for project: your-project-id",
  "ready": true
}
```

### Camera Status Response
```json
{
  "active": true,
  "mode": "idle",
  "current_pan": 90,
  "current_tilt": 90,
  "last_update": "2025-08-19T14:30:25.123456"
}
```

### Camera Modes
- `inactive` - Servos detached/powered off
- `idle` - Servos attached but stationary
- `patrol` - Basic patrol mode (predefined pattern)
- `smart` - AI-powered smart patrol (face detection driven)
- `manual` - Real-time manual control via WebSocket

## 🏗️ Architecture

### Core Components
- **FastAPI Server**: REST API + WebSocket endpoints
- **ESP32 Integration**: Serial communication for servo control
- **Face Detection**: WebRTC with aiortc + MediaMTX integration  
- **Manual Control**: Real-time WebSocket sliders
- **Wake Word**: Optional Picovoice Porcupine integration
- **Firebase Cloud Messaging**: Optional push notifications

### Dependencies
**Dependencies (requirements.txt):**
- `fastapi` - Web framework
- `uvicorn` - ASGI server  
- `pyserial` - ESP32 communication
- `aiortc` - WebRTC for face detection
- `opencv-python` - Computer vision
- `pvporcupine` - Wake word detection (optional)
- `sounddevice` - Audio input (optional)
- `firebase-admin` - Push notifications (optional)

## 🚨 Troubleshooting

**Serial Port Issues:**
```bash
ls /dev/ttyUSB*                          # Find ESP32 port
sudo usermod -a -G dialout $USER         # Add user to group
# Reboot after group change
```

**Audio Device Issues:**
```bash
python wake_word.py                      # List audio devices
# Try different WAKE_WORD_DEVICE_INDEX
```

**WebRTC Connection Issues:**
- Ensure MediaMTX is running on port 8889
- Check webcam permissions
- Verify firewall settings

**Import Errors:**
```bash
source venv/bin/activate                 # Activate virtual environment
pip install --upgrade pip               # Update pip
pip install -r requirements_full.txt    # Reinstall dependencies
```

## 🔐 Development Notes

- Server binds to localhost:8234 by default (set `SERVER_HOST=0.0.0.0` for network access)
- ESP32 communicates via USB serial 
- MediaMTX handles WebRTC video streaming
- Wake word detection uses laptop microphone
- Flutter app connects via HTTP/WebSocket

## 📱 Flutter Integration

Connect your Flutter app to these endpoints:
- **Base URL**: `http://localhost:8234`
- **Health Check**: `GET /api/health`
- **Camera Status**: `GET /api/status`
- **Servo Control**: `POST /api/servos/{attach|detach|center}`
- **Patrol Control**: `POST /api/patrol/{start|stop}`
- **Smart Patrol**: `POST /api/smart_patrol/{start|stop}`
- **Manual Control**: `WebSocket /ws/manual`
- **Face Detection**: `WebSocket /ws/face_detection`

### Example API Usage
```python
import requests

# Check system health
response = requests.get("http://localhost:8234/api/health")
health = response.json()

# Start smart patrol
response = requests.post("http://localhost:8234/api/smart_patrol/start")
status = response.json()

# Center camera
response = requests.post("http://localhost:8234/api/servos/center")
status = response.json()
```

## 🎯 Wake Word Customization

When wake word is detected, the system automatically:
1. **Logs detection** with timestamp and keyword index
2. **Sends FCM notification** (if configured) to `wake-word` topic
3. **Triggers custom actions** (modify `_on_wake_word_detected()` method)

```python
def _on_wake_word_detected(self, keyword_index):
    """Callback when wake word is detected"""
    print(f"[WakeWord] Wake word detected! Index: {keyword_index}")
    if self.fcm_enabled:
        try:
            self._send_wake_word_notification(keyword_index)
        except Exception as e:
            print(f"[FCM] Error sending wake word notification: {e}")
    
    # Add your custom logic here:
    # - await self.start_smart_patrol()
    # - Custom servo patterns
    # - External API calls
    # - Database logging
```

## 📱 Firebase Cloud Messaging

When both wake word detection and FCM are configured, the system automatically sends high-priority push notifications on wake word detection.

**Automatic Wake Word Notifications:**
- **Topic**: `wake-word` (clients must subscribe)
- **Priority**: High (bypasses Android battery optimization)
- **Payload**: 
  ```json
  {
    "type": "wake_word",
    "keyword_index": "0",
    "timestamp": "2025-08-19T14:30:25.123456",
    "server_status": "active"
  }
  ```

**FCM Configuration Steps:**
1. Create Firebase project at https://console.firebase.google.com/
2. Generate service account key (Project Settings > Service Accounts)
3. Save as `home-guardian_firebase.json` in project folder
4. Update server configuration:
   ```python
   FIREBASE_PROJECT_ID = "your-project-id"
   FCM_SERVICE_ACCOUNT_FILE = "home-guardian_firebase.json"
   ```
5. Flutter app must subscribe to `wake-word` topic

**Notification Features:**
- Cross-platform (Android & iOS)
- High priority delivery
- Custom notification channel for wake word alerts
- Rich notification with timestamp and system status

---

*For detailed technical documentation, check the source code comments in each Python file.*
