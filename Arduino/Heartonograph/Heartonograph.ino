#include <Timer.h>
#include <Stepper.h>
#include <AccelStepper.h>
#include <MultiStepper.h>

#define HALFSTEP 8

#define motorPin1 3
#define motorPin2 4
#define motorPin3 5
#define motorPin4 6

#define motorPin5 8
#define motorPin6 9
#define motorPin7 10
#define motorPin8 11

// Define our maximum and minimum speed in steps per second (scale pot to these)
//#define  SPEED_1 1000
//#define  SPEED_2 950
//#define  SPEED_3 900
//#define  SPEED_4 800
//#define  SPEED_5 700
//#define  SPEED_6 600
//#define  SPEED_7 500
//#define  SPEED_8 400
//#define  SPEED_9 300
//#define  SPEED_10 200

#define  SPEED_1 1000
#define  SPEED_2 950
#define  SPEED_3 900
#define  SPEED_4 850
#define  SPEED_5 800
#define  SPEED_6 750
#define  SPEED_7 700
#define  SPEED_8 650
#define  SPEED_9 600
#define  SPEED_10 550

int mic = 4;
int micVal = 0;
unsigned int signalMax;

//int stepsPerSec[]={910,920,930,940,950,960,970,980,990,1000};

Timer t;

AccelStepper stepper1(HALFSTEP, motorPin1, motorPin3, motorPin2, motorPin4);
AccelStepper stepper2(HALFSTEP, motorPin5, motorPin7, motorPin6, motorPin8);

int bpm = 0;

void setup() {

  Serial.begin(9600);
  
  stepper1.setMaxSpeed(1000.0);
  stepper1.setAcceleration(250.0);
  stepper1.setSpeed(500);

  stepper2.setMaxSpeed(1000.0);
  stepper2.setAcceleration(100.0);
  stepper2.setSpeed(1000);

  bpm = 40;

  t.every(1000, takeReading);

  // audio
  pinMode(A0, OUTPUT);
  pinMode(A1, OUTPUT);
  pinMode(A2, OUTPUT);
  pinMode(A3, OUTPUT);
}

void takeReading() {
  
  bpm = Serial.parseInt();

  if (bpm > 100) {
    stepper1.setSpeed(-1 * SPEED_1);
    stepper2.setSpeed(SPEED_3);
  } else if (bpm > 95) {
    stepper1.setSpeed(-1 * SPEED_2);
    stepper2.setSpeed(SPEED_5);
  } else if (bpm > 90) {
    stepper1.setSpeed(-1 * SPEED_3);
    stepper2.setSpeed(SPEED_7);
  } else if (bpm > 85) {
    stepper1.setSpeed(-1 * SPEED_4);
    stepper2.setSpeed(SPEED_9);
  } else if (bpm>83) {
    stepper1.setSpeed(-1 * SPEED_4-20);
    stepper2.setSpeed(SPEED_9);
  } else if (bpm > 80) {
    stepper1.setSpeed(-1 * SPEED_5);
    stepper2.setSpeed(SPEED_10);
  } else if (bpm > 77) {
    stepper1.setSpeed(-1 * SPEED_5 - 20);
    stepper2.setSpeed(SPEED_10);
  } else if (bpm > 75) {
    stepper1.setSpeed(-1 * SPEED_6);
    stepper2.setSpeed(SPEED_1);
  } else if (bpm > 72) {
    stepper1.setSpeed(-1 * SPEED_6 - 20);
    stepper2.setSpeed(SPEED_1);
  } else if (bpm > 70) {
    stepper1.setSpeed(-1 * SPEED_7);
    stepper2.setSpeed(SPEED_2);
  } else if (bpm > 67) {
    stepper1.setSpeed(-1 * SPEED_7 - 20);
    stepper2.setSpeed(SPEED_2);
  } else if (bpm > 65) {
    stepper1.setSpeed(-1 * SPEED_8);
    stepper2.setSpeed(SPEED_4);
  } else if (bpm > 62) {
    stepper1.setSpeed(-1 * SPEED_8 - 20);
    stepper2.setSpeed(SPEED_4);
  } else if (bpm > 60) {
    stepper1.setSpeed(-1 * SPEED_9);
    stepper2.setSpeed(SPEED_6);
  } else {
    stepper1.setSpeed(-1 * SPEED_10);
    stepper2.setSpeed(SPEED_8);
  }
  
}

void loop() {
  t.update();
  // This will run the stepper at a constant speed
  stepper1.runSpeed();
  stepper2.runSpeed();

  // audio

  micVal = analogRead(mic);
  signalMax = micVal;
  if(signalMax <400 ){
    digitalWrite(A0, HIGH);
    digitalWrite(A1,LOW);
    digitalWrite(A2,LOW);
  }
  else if(signalMax <460){
    digitalWrite(A2,HIGH);
    digitalWrite(A1,LOW);
    digitalWrite(A2,HIGH);
    digitalWrite(A3,LOW);
  }
  else if(signalMax< 580){
    digitalWrite(A2,HIGH);
    digitalWrite(A1,LOW);
    digitalWrite(A2,HIGH);
    digitalWrite(A3,HIGH);
  }
  else {
    digitalWrite(A2,HIGH);
    digitalWrite(A1,HIGH);
    digitalWrite(A2,HIGH);
    digitalWrite(A3,HIGH);
 }
}

