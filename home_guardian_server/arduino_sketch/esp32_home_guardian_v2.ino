// ESP32 Home Guardian V2 - Servo Control Firmware
#include <ESP32Servo.h>

// Servo configuration - modify pins here if needed
Servo panServo;
Servo tiltServo;
const int panPin = 33;   // Pan servo pin
const int tiltPin = 27;  // Tilt servo pin

// Operating modes
enum SystemMode {
  MODE_INACTIVE,  // Servos detached
  MODE_IDLE,      // Servos attached, no movement
  MODE_MANUAL,    // Manual control via WebSocket
  MODE_PATROL     // Autonomous patrol movement
};

// State management
SystemMode currentMode = MODE_INACTIVE;
bool servosAttached = false;

// Patrol configuration
int patrolPosition = 90;
int patrolDirection = 1;  // 1=right, -1=left
unsigned long lastPatrolMove = 0;
const unsigned long patrolDelay = 150;   // Movement interval (ms)
const int patrolStep = 1;                // Step size (degrees)
const int patrolMinAngle = 0;            // Left limit
const int patrolMaxAngle = 170;          // Right limit

// Current positions
int currentPan = 90;
int currentTilt = 90;

// Serial communication
String inputString = "";
bool stringComplete = false;

void setup() {
  Serial.begin(115200);
  Serial.println("Home Guardian ESP32 v2.0");
  Serial.println("Commands: MODE_INACTIVE, MODE_IDLE, MODE_MANUAL, MODE_PATROL, PANTILT<pan>,<tilt>, ATTACH, DETACH, CENTER, STATUS");
  
  panServo.setPeriodHertz(50);
  tiltServo.setPeriodHertz(50);
  inputString.reserve(200);
}

void loop() {
  handleSerialInput();
  if (currentMode == MODE_PATROL) {
    executePatrolMode();
  }
  delay(10);
}

void handleSerialInput() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    if (inChar == '\n') {
      stringComplete = true;
    } else {
      inputString += inChar;
    }
  }
  if (stringComplete) {
    processCommand(inputString);
    inputString = "";
    stringComplete = false;
  }
}

void processCommand(String command) {
  command.trim();
  command.toUpperCase();
  if (command == "MODE_INACTIVE") {
    setMode(MODE_INACTIVE);
  }
  else if (command == "MODE_IDLE") {
    setMode(MODE_IDLE);
  }
  else if (command == "MODE_MANUAL") {
    setMode(MODE_MANUAL);
  }
  else if (command == "MODE_PATROL") {
    setMode(MODE_PATROL);
  }
  else if (command == "ATTACH") {
    attachServos();
  }
  else if (command == "DETACH") {
    detachServos();
  }
  else if (command == "STATUS") {
    sendStatusUpdate();
  }
  else if (command.startsWith("PANTILT")) {
    handlePanTiltCommand(command);
  }
  else if (command == "CENTER") {
    centerServos();
  }
}

// Combined pan/tilt command: PANTILT<pan>,<tilt>
void handlePanTiltCommand(String command) {
  if (!servosAttached || currentMode == MODE_PATROL) return;
  
  String args = command.substring(7);  // Remove "PANTILT" prefix
  int commaIdx = args.indexOf(',');
  if (commaIdx == -1) return;  // Invalid format
  
  int pan = args.substring(0, commaIdx).toInt();
  int tilt = args.substring(commaIdx + 1).toInt();
  
  // Clamp to safe ranges
  pan = constrain(pan, 0, 170);
  tilt = constrain(tilt, 0, 150);
  
  // Update only if changed (prevent unnecessary servo commands)
  if (pan != currentPan) {
    currentPan = pan;
    panServo.write(currentPan);
  }
  if (tilt != currentTilt) {
    currentTilt = tilt;
    tiltServo.write(currentTilt);
  }
}

void setMode(SystemMode newMode) {
  if (!servosAttached && (newMode == MODE_IDLE || newMode == MODE_MANUAL || newMode == MODE_PATROL)) {
    return;
  }
  currentMode = newMode;
  switch(newMode) {
    case MODE_INACTIVE:
      break;
    case MODE_IDLE:
      break;
    case MODE_MANUAL:
      break;
    case MODE_PATROL:
      patrolPosition = currentPan;
      currentTilt = 90;
      if (servosAttached) {
        tiltServo.write(currentTilt);
      }
      lastPatrolMove = millis();
      break;
  }
}

void attachServos() {
  if (!servosAttached) {
    panServo.attach(panPin, 600, 2200);
    tiltServo.attach(tiltPin, 600, 2200);
    servosAttached = true;
    
    // Initialize to center position
    currentTilt = 90;
    tiltServo.write(currentTilt);
    delay(500);
    currentPan = 90;
    panServo.write(currentPan);
    delay(500);
    
    currentMode = MODE_IDLE;
  }
}

void detachServos() {
  if (servosAttached) {
    // Move tilt to safe position before detaching
    currentTilt = 150;
    tiltServo.write(currentTilt);
    delay(1000);
    
    panServo.detach();
    tiltServo.detach();
    servosAttached = false;
    currentMode = MODE_INACTIVE;
  }
}

void centerServos() {
  if (!servosAttached) return;
  
  // Move to center position if not already there
  if (currentPan != 90) {
    currentPan = 90;
    panServo.write(currentPan);
  }
  if (currentTilt != 90) {
    currentTilt = 90;
    tiltServo.write(currentTilt);
  }
}

void executePatrolMode() {
  if (!servosAttached || currentMode != MODE_PATROL) return;
  
  unsigned long currentTime = millis();
  if (currentTime - lastPatrolMove >= patrolDelay) {
    // Update patrol position
    patrolPosition += (patrolDirection * patrolStep);
    
    // Reverse direction at limits
    if (patrolPosition >= patrolMaxAngle) {
      patrolPosition = patrolMaxAngle;
      patrolDirection = -1;
    } else if (patrolPosition <= patrolMinAngle) {
      patrolPosition = patrolMinAngle;
      patrolDirection = 1;
    }
    
    currentPan = patrolPosition;
    panServo.write(currentPan);
    lastPatrolMove = currentTime;
  }
}

void sendStatusUpdate() {
  Serial.print("STATUS:");
  Serial.print(currentPan);
  Serial.print(",");
  Serial.print(currentTilt);
  Serial.print(",");
  switch(currentMode) {
    case MODE_INACTIVE:
      Serial.print("INACTIVE");
      break;
    case MODE_IDLE:
      Serial.print("IDLE");
      break;
    case MODE_MANUAL:
      Serial.print("MANUAL");
      break;
    case MODE_PATROL:
      Serial.print("PATROL");
      break;
  }
  Serial.print(",");
  Serial.print(servosAttached ? "ATTACHED" : "DETACHED");
  Serial.println();
}
