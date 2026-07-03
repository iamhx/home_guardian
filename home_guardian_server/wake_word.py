# Wake Word Detection Module
# Picovoice Porcupine integration with custom wake word support
# Users must create their own wake word at https://console.picovoice.ai/
# Uses laptop microphone (separate from MediaMTX webcam audio)

import threading
import time
import numpy as np
import sounddevice as sd
from typing import Optional, Callable


class WakeWordDetector:
    def __init__(self, 
                 access_key: str, 
                 keyword_paths: list,
                 sensitivities: list = None,
                 device_index: Optional[int] = None,
                 on_wake_word: Optional[Callable] = None):
        """
        Wake Word Detector using custom Picovoice Porcupine keywords
        
        Args:
            access_key: Picovoice access key from console.picovoice.ai
            keyword_paths: List of .ppn keyword files (REQUIRED - create at console.picovoice.ai)
            sensitivities: Detection sensitivities 0.0-1.0 (optional)
            device_index: Audio device index (None for default)
            on_wake_word: Callback when wake word detected
            
        Example:
            detector = WakeWordDetector(
                access_key="your_key",
                keyword_paths=["your_custom_keyword.ppn"],  # Download from Picovoice Console
                on_wake_word=my_callback
            )
        """
        try:
            import pvporcupine
            self.pvporcupine = pvporcupine
        except ImportError:
            raise ImportError("pvporcupine is required. Install with: pip install pvporcupine")
        
        self.access_key = access_key
        self.keyword_paths = keyword_paths
        if not keyword_paths:
            raise ValueError("keyword_paths is required. Create custom wake words at https://console.picovoice.ai/")
        self.sensitivities = sensitivities or [0.5] * len(keyword_paths)
        self.device_index = device_index
        self.on_wake_word = on_wake_word
        
        # Initialize components
        self.porcupine = None
        self.running = False
        self.health = False
        self._thread = None
        self._audio_stream = None
        
        # Detection statistics
        self.detections_count = 0
        self.last_detection_time = None
        
    def start(self):
        """Start wake word detection in background thread"""
        if self.running:
            return
            
        try:
            # Initialize Porcupine with custom keywords only
            self.porcupine = self.pvporcupine.create(
                access_key=self.access_key,
                keyword_paths=self.keyword_paths,
                sensitivities=self.sensitivities
            )
            
            self.running = True
            self._thread = threading.Thread(target=self._run, daemon=True)
            self._thread.start()
            print("[WakeWord] Started wake word detection")
            
        except Exception as e:
            print(f"[WakeWord] Failed to start: {e}")
            self.health = False
            
    def stop(self):
        """Stop wake word detection and cleanup resources"""
        if not self.running:
            return
            
        self.running = False
        self.health = False
        
        # Stop audio stream
        if self._audio_stream:
            try:
                self._audio_stream.stop()
                self._audio_stream.close()
            except Exception as e:
                print(f"[WakeWord] Error closing audio stream: {e}")
            self._audio_stream = None
        
        # Wait for thread to finish
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=2.0)
        
        # Cleanup Porcupine
        if self.porcupine:
            try:
                self.porcupine.delete()
            except Exception as e:
                print(f"[WakeWord] Error deleting Porcupine instance: {e}")
            self.porcupine = None
            
        print("[WakeWord] Stopped wake word detection")
        
    def _run(self):
        """Main detection loop in background thread"""
        try:
            # Setup audio device
            if self.device_index is not None:
                device_info = sd.query_devices(self.device_index)
                print(f"[WakeWord] Using device: {device_info['name']}")
                
                # Warn about hardware ALSA devices
                if 'hw:' in device_info['name']:
                    print(f"[WakeWord] ⚠️  Hardware ALSA device may not support required sample rate ({self.porcupine.sample_rate} Hz)")
                    print(f"[WakeWord] If you get sample rate errors, try virtual devices like 'pulse', 'default', or 'sysdefault'")
            else:
                device_info = sd.query_devices(kind='input')
                print(f"[WakeWord] Using default input: {device_info['name']}")
            
            # Start audio stream with Porcupine settings
            print(f"[WakeWord] Configuring audio: {self.porcupine.sample_rate} Hz, 1 channel, {self.porcupine.frame_length} frames")
            self._audio_stream = sd.InputStream(
                device=self.device_index,
                channels=1,
                samplerate=self.porcupine.sample_rate,
                dtype=np.int16,
                blocksize=self.porcupine.frame_length,
                callback=self._audio_callback
            )
            
            self._audio_stream.start()
            self.health = True
            print(f"[WakeWord] Listening for wake word on device: {device_info['name']}")
            
            # Keep thread alive while running
            while self.running:
                time.sleep(1)
                
        except Exception as e:
            error_msg = str(e)
            print(f"[WakeWord] Error in detection loop: {e}")
            
            # Provide helpful error messages for common issues
            if "Invalid sample rate" in error_msg or "paInvalidSampleRate" in error_msg:
                print(f"[WakeWord] 💡 Sample rate error fix:")
                print(f"[WakeWord] - Porcupine requires {self.porcupine.sample_rate if self.porcupine else '16000'} Hz")
                print(f"[WakeWord] - Try virtual devices: 'pulse' (13), 'default' (17), or 'sysdefault' (5)")
                print(f"[WakeWord] - Avoid hardware ALSA devices like 'hw:X,Y'")
            
            self.health = False
        finally:
            self.health = False
            
    def _audio_callback(self, indata, frames, time, status):
        """Process audio frames for wake word detection"""
        if not self.running or not self.porcupine:
            return
            
        try:
            # Convert audio to Porcupine format
            audio_frame = indata.flatten().astype(np.int16)
            
            # Process frame for wake word
            keyword_index = self.porcupine.process(audio_frame)
            
            if keyword_index >= 0:
                self.detections_count += 1
                self.last_detection_time = time.inputBufferAdcTime
                
                # Execute callback if provided
                if self.on_wake_word:
                    try:
                        self.on_wake_word(keyword_index)
                    except Exception as e:
                        print(f"[WakeWord] Callback error: {e}")
                        
        except Exception as e:
            print(f"[WakeWord] Audio processing error: {e}")
    
    def is_healthy(self):
        """Check if wake word detection is healthy"""
        return self.health and self.running and self.porcupine is not None
    
    def get_stats(self):
        """Get detection statistics"""
        return {
            "running": self.running,
            "healthy": self.is_healthy(),
            "detections_count": self.detections_count,
            "last_detection_time": self.last_detection_time
        }
    
    @staticmethod
    def list_audio_devices():
        """List available audio input devices with recommendations"""
        try:
            devices = sd.query_devices()
            input_devices = []
            for i, device in enumerate(devices):
                if device['max_input_channels'] > 0:
                    # Mark recommended devices
                    is_virtual = not ('hw:' in device['name'])
                    is_recommended = is_virtual or 'USB' in device['name']
                    
                    input_devices.append({
                        'index': i,
                        'name': device['name'],
                        'channels': device['max_input_channels'],
                        'sample_rate': device['default_samplerate'],
                        'recommended': is_recommended,
                        'type': 'virtual' if is_virtual else 'hardware'
                    })
            return input_devices
        except Exception as e:
            print(f"[WakeWord] Device listing error: {e}")
            return []


# Example usage and setup instructions
if __name__ == "__main__":
    def on_wake_word_detected(keyword_index):
        print(f"🎉 WAKE WORD DETECTED! Index: {keyword_index}")
    
    # List available devices
    print("Available audio input devices:")
    devices = WakeWordDetector.list_audio_devices()
    for device in devices:
        status = "✅" if device['recommended'] else "⚠️"
        device_type = f"({device['type']})"
        print(f"  {status} {device['index']}: {device['name']} ({device['channels']} ch) {device_type}")
    
    print(f"\n💡 Recommended: Use virtual devices (✅) for best compatibility")
    print(f"⚠️  Hardware ALSA devices (hw:X,Y) may have sample rate issues")
    
    # Configuration - YOU MUST SET THESE:
    ACCESS_KEY = "YOUR_PICOVOICE_ACCESS_KEY"
    KEYWORD_FILES = ["your_custom_keyword.ppn"]  # Replace with your .ppn file

    print("\n" + "="*60)
    print("🔧 WAKE WORD SETUP REQUIRED")
    print("="*60)
    print("1. Get Picovoice access key: https://console.picovoice.ai/")
    print("2. Create custom wake word:")
    print("   - Go to Porcupine section")
    print("   - Click 'Create Keyword'")
    print("   - Type your wake phrase (e.g., 'home guardian', 'activate system', 'hello computer')")
    print("   - Download the .ppn file")
    print("3. Update this file:")
    print(f"   ACCESS_KEY = \"your_actual_key\"")
    print(f"   KEYWORD_FILES = [\"your_custom_keyword.ppn\"]")
    print("="*60)

    if ACCESS_KEY == "YOUR_PICOVOICE_ACCESS_KEY":
        print("\n⚠️  Please complete the setup above before running")
        exit(1)

    # Prompt user to select device index
    print("\nSelect audio input device index (or press Enter for default):")
    try:
        device_index_input = input("Device index: ").strip()
        if device_index_input == "":
            device_index = None
        else:
            device_index = int(device_index_input)
    except Exception:
        device_index = None

    try:
        detector = WakeWordDetector(
            access_key=ACCESS_KEY,
            keyword_paths=KEYWORD_FILES,
            device_index=device_index,
            on_wake_word=on_wake_word_detected
        )

        detector.start()
        print(f"Wake word detector started with custom keyword(s): {KEYWORD_FILES}")
        print("Say your custom wake word to test...")
        print("Press Ctrl+C to stop")

        while True:
            time.sleep(1)
            stats = detector.get_stats()
            if stats['detections_count'] > 0:
                print(f"Stats: {stats}")

    except Exception as e:
        print(f"❌ Error: {e}")
        print("Make sure you've created a custom wake word at https://console.picovoice.ai/")
    except KeyboardInterrupt:
        print("\nStopping wake word detector...")
    finally:
        try:
            detector.stop()
        except Exception as e:
            print(f"[WakeWord] Error stopping detector: {e}")
