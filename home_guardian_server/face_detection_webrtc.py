# Face Detection WebRTC Module
# Uses aiortc + MediaMTX for real-time face detection via WebSocket broadcasting

import cv2
import asyncio
import aiohttp
from aiortc import RTCPeerConnection, RTCSessionDescription


class FaceDetectionWebRTC:
    def __init__(self, whep_url="http://localhost:8889/cam/whep"):
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        self.last_face_count = 0
        self.last_detected = False
        self.health = False
        self.ws_connections = []  # WebSocket connections for broadcasting
        self.event_loop = None    # Set after FastAPI startup
        self.whep_url = whep_url  # MediaMTX WebRTC endpoint
        self._task = None
        self.running = False
        self._pc = None  # RTCPeerConnection for cleanup

    def set_event_loop(self, loop):
        self.event_loop = loop

    def start(self):
        # Start face detection as background task
        if self._task is None and not self.running:
            self.running = True
            self._task = asyncio.create_task(self._run())

    async def stop(self):
        """Clean shutdown of face detection"""
        self.running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
            self._task = None
        if self._pc:
            await self._pc.close()
            self._pc = None
        self.health = False

    async def _run(self):
        try:
            pc = RTCPeerConnection()
            self._pc = pc  # Store for cleanup
            pc.addTransceiver("video", direction="recvonly")

            @pc.on("track")
            def on_track(track):
                if track.kind == "video":
                    asyncio.create_task(self._on_video_track(track))

            offer = await pc.createOffer()
            await pc.setLocalDescription(offer)

            async with aiohttp.ClientSession() as session:
                async with session.post(
                    self.whep_url,
                    data=pc.localDescription.sdp,
                    headers={"Content-Type": "application/sdp"}
                ) as resp:
                    answer_sdp = await resp.text()

            await pc.setRemoteDescription(
                RTCSessionDescription(sdp=answer_sdp, type="answer")
            )
            
            # Keep connection alive while running
            while self.running:
                await asyncio.sleep(1)
                
        except Exception as e:
            print(f"[FaceDetectionWebRTC] Error in _run: {e}")
            self.health = False
        finally:
            if self._pc:
                try:
                    await self._pc.close()
                except Exception as e:
                    print(f"[FaceDetectionWebRTC] Error closing peer connection: {e}")
                self._pc = None

    async def _on_video_track(self, track):
        self.health = True
        try:
            while self.running:
                frame = await track.recv()
                img = frame.to_ndarray(format="bgr24")
                gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
                faces = self.face_cascade.detectMultiScale(gray, 1.3, 5)
                face_count = len(faces)
                detected = face_count > 0
                # Always broadcast at least once per connection
                if face_count != self.last_face_count or detected != self.last_detected:
                    self.last_face_count = face_count
                    self.last_detected = detected
                    self._broadcast(face_count, detected)
        except Exception as e:
            print(f"[FaceDetectionWebRTC] Error in _on_video_track: {e}")
            self.health = False
        finally:
            self.health = False


    def _broadcast(self, face_count: int, detected: bool):
        data = {"face_count": face_count, "detected": detected}
        dead_connections = []
        for ws in self.ws_connections[:]:  # Use slice to create a copy
            try:
                if self.event_loop is not None:
                    asyncio.run_coroutine_threadsafe(ws.send_json(data), self.event_loop)
            except Exception as e:
                print(f"[FaceDetectionWebRTC] Failed to broadcast to WebSocket client: {e}")
                dead_connections.append(ws)
        for ws in dead_connections:
            self.remove_ws(ws)

    def add_ws(self, ws):
        if ws not in self.ws_connections:
            self.ws_connections.append(ws)
            # Always send the current state immediately
            self._broadcast(self.last_face_count, self.last_detected)

    def remove_ws(self, ws):
        if ws in self.ws_connections:
            self.ws_connections.remove(ws)

    def is_healthy(self):
        return self.health
