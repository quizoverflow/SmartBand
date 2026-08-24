#include "sensor.h"
#include "calculation.h"
#include "filter.h"
#include "config.h"
#include "connection.h"

ConnectionController connection;
AccelerationSensor mpu;

// 무릎 최적화 파라미터 적용 (피크 8.5 m/s², 접촉 2.0 m/s², 불응기 450ms)
StepAnalyzer stepAnalyzer(8.5f, 2.0f, 450); 

unsigned long lastSampleTime = 0;
const int sampleInterval = 2000; // 2ms 주기 (500Hz)
int packetNumber = 0;

void setup() {
  connection.begin(); // SoftwareSerial 57600bps 시작
  mpu.begin();        // MPU6050 센서 초기화

  stepAnalyzer.reset();
  connection.send_start(); // 시작 알림
}

void loop() {
  // PC 파이썬 연결 시 전송되는 시작/초기화 명령('S') 수신
  if (connection.available()) {
      char cmd = connection.read();
      if (cmd == 'S' || cmd == 'R') {
          stepAnalyzer.reset();
          packetNumber = 0;
          connection.send_start(); // PC에 준비 완료 응답
      }
  }

  unsigned long current = micros();
  if (current - lastSampleTime < sampleInterval) return;
  lastSampleTime = current;

  // 1. 센서 측정 및 Biquad 필터링
  mpu.update();
  float rawAcc = mpu.getAccelMagnitude();
  float acc = lpf.update(hpf.update(rawAcc));

  // 2. 실시간 피크 감지 & 15걸음 누적/GCT 연산
  StepResult step;
  if (stepAnalyzer.update(acc, current, step)) {
      packetNumber++;

      // 3. 한 걸음 완성 시 블루투스 패킷 송신
      BTData data(packetNumber, step.peakAcc, step.cadence, step.stepImpulse, step.totalImpulse, step.gct);
      connection.send(data);
  }
}