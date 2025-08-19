#!/bin/bash
# Home Guardian Setup Script
# Automated installation for fresh machines

set -e  # Exit on any error

echo "🚀 Home Guardian Server Setup"
echo "============================="

# Check Python installation
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 required. Please install Python 3.8+ first."
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
echo "✅ Python $PYTHON_VERSION detected"

# Detect operating system
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Linux detected"
    
    # Ubuntu/Debian package installation
    if command -v apt &> /dev/null; then
        echo "📦 Installing system dependencies (Ubuntu/Debian)..."
        sudo apt update
        sudo apt install -y python3-dev python3-pip python3-venv
        sudo apt install -y libportaudio2 libasound-dev  # Audio libraries
        sudo apt install -y libavcodec-dev libavformat-dev libswscale-dev  # Video libraries  
        sudo apt install -y libopus-dev libvpx-dev pkg-config libavdevice-dev  # WebRTC codecs
    
    # CentOS/RHEL/Fedora package installation
    elif command -v yum &> /dev/null; then
        echo "📦 Installing system dependencies (CentOS/RHEL/Fedora)..."
        sudo yum install -y python3-devel python3-pip
        sudo yum install -y portaudio-devel alsa-lib-devel
        sudo yum install -y ffmpeg-devel opus-devel libvpx-devel
    
    else
        echo "⚠️  Unsupported Linux distribution"
        echo "Please install manually: python3-dev, portaudio, alsa, ffmpeg, opus, libvpx"
    fi
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 macOS detected"
    
    if command -v brew &> /dev/null; then
        echo "📦 Installing dependencies with Homebrew..."
        brew install portaudio opus libvpx ffmpeg
    else
        echo "⚠️  Homebrew required. Install from: https://brew.sh/"
        echo "Or install manually: portaudio, opus, libvpx, ffmpeg"
    fi
    
else
    echo "⚠️  Unsupported OS: $OSTYPE"
    echo "Please install system dependencies manually"
fi

# Python environment setup
echo "🔧 Setting up Python environment..."
if [ -d "venv" ]; then
    echo "Virtual environment exists"
else
    python3 -m venv venv
fi

source venv/bin/activate
echo "⬆️  Upgrading pip..."
pip install --upgrade pip

# Install all dependencies (wake word and FCM are optional at runtime)
echo "📦 Installing complete dependencies..."
echo "   (Wake word and Firebase Cloud Messaging will gracefully fallback if not configured)"

# Additional audio libraries for wake word support
if [[ "$OSTYPE" == "linux-gnu"* ]] && command -v apt &> /dev/null; then
    echo "🔊 Installing audio dependencies for wake word support..."
    sudo apt install -y libportaudio2 libasound-dev
elif [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
    echo "🔊 Installing audio dependencies for wake word support..."
    brew install portaudio
fi

pip install -r requirements.txt

echo ""
echo "✅ Installation complete!"
echo ""
echo "📋 Next Steps:"
echo "=============="
echo "1. Connect your ESP32 to USB (usually /dev/ttyUSB0)"
echo "2. Start MediaMTX server:"
echo "   cd /path/to/mediamtx && ./mediamtx"
echo ""
echo "3. (Optional) Setup Wake Word Detection:"
echo "   - Sign up at: https://console.picovoice.ai/"
echo "   - Create custom wake word and download .ppn file"
echo "   - Edit home_guardian_server_v2.py"
echo "   - Set PICOVOICE_ACCESS_KEY and WAKE_WORD_KEYWORD_FILES"
echo ""
echo "4. (Optional) Setup Firebase Cloud Messaging:"
echo "   - Go to Firebase Console: https://console.firebase.google.com/"
echo "   - Create/select your project"
echo "   - Go to Project Settings > Service Accounts"
echo "   - Generate new private key and save as 'firebase-service-account.json'"
echo "   - Edit home_guardian_server_v2.py"
echo "   - Set FIREBASE_PROJECT_ID and FCM_SERVICE_ACCOUNT_FILE"
echo ""
echo "5. Test the setup:"
echo "   source venv/bin/activate"
echo "   python3 home_guardian_server_v2.py"
echo ""
echo "6. Check health: http://localhost:8234/api/health"
echo ""
echo "🎉 Home Guardian Server is ready!"

# Show installed packages
echo ""
echo "📦 Installed Python packages:"
pip list | grep -E "(fastapi|uvicorn|pyserial|opencv|aiortc|pvporcupine|sounddevice|firebase-admin)"
