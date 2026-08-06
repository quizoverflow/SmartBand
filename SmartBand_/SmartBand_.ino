#include "sensor.h"
#include "calculation.h"
#include "filter.h"
#include "button.h"
#include "config.h"
#include "connection.h"

//블루투스 연결 커넥션 객체
ConnectionController connection;

// 현재 디바이스 상태관리 0은 대기, 1은 측정 
int device_status = 0; 

//가속도 센서 측정 객체
AccelerationSensor mpu;

// 지면 접촉 감지 객체
GroundContactDetector contactDetector(1.2f,30,20);

bool btn_value = false;

// 샘플링 주파수 결정
// Shannon -Nyquist Sampling Therom에 입각한 Nyquist Rate 고려
// 피크값 측정은 보간을 통해 이루어지므로 최저주파수의 2배이상으로 결정해야 함
// 500Hz 로 결정, 따라서 측정주기는 2ms
unsigned long lastSampleTime = 0;
const int sampleInterval = 2000; // 2000마이크로초 == 2ms

// 패킷 순서 관리
int packetNumber = 0;
/*
  아두이노 나노의 메모리 조건에 따른 공간 복잡도 계산
  아두이노 나노 런타임 메모리(SRAM) = 2KB
  
  한번의 주기에서 생성되는 총 데이터량은
  ( 발의최대회전주기 / 측정주기 ) * float데이터크기
  =  400ms / 2ms * 4byte = 800 byte  < 여유 SRAM 크기(1200byte)

]

상태 흐름 (간략히)

1. 아두이노 on (온 오프 스위치로)
2. 측정 시작 (택틱 스위치로)
3. MPU 6050 통신 시작 => 가속도 수집 시작
  2.1 가속도 측정
  2.2 가속도 합성
  2.3 가속도 필터링 / 슬라이딩 윈도우(최대가속도)) / 지면 접촉감지 
4. 요약 정보 블루투스로 송신 (문자열)
  #N ; 패킷 순서
  P10.1g
  C172
  I6.92
5. 측정 끝 (택틱 스위치로)
  블루투스로 러닝 끝을 알려줌
  #END
*/

void checkState(){
  //측정 대기중이고, 버튼이 눌렸다면 상태변경후 측정모드 시작
  if(device_status == 0 && btn_value){
    device_status = 1;
    packetNumber = 0;
  }
  //측정중이고, 버튼이 눌렸다면 대기 모드로 
  else if(device_status == 1 && btn_value){
    device_status = 0;
    packetNumber = 0;
  }
  // 측정 대기중이고, 버튼이 안눌렸다면 계속 대기 진행
  else if(device_status == 0 && btn_value == false){
  }
}


void setup() {
  //Serial.begin(115200);

  // 블루투스 연결
  connection.begin();
  // 가속도 센서 연결
  mpu.begin();
  
}

void loop() {
  btn_value = checkButton();
  checkState();
  if (device_status != 1) return;

  // === 측정 시작 (러닝 시작) ===
  // 샘플링 후 지난 시간 측정
  unsigned long current = micros();
  unsigned long timePassed = current - lastSampleTime;
  // sampleInterval 마이크로초가 아직 지나지 않으면 수행안함.
  if (timePassed < sampleInterval){
    return;
  }
  // sampleInterval 마이크로초 지나면 아래 코드 수행
  // MPU6050 가속도 센서값 업데이트
  // x,y,z축 가속도 합성
  // 필터링으로 잡음, 중력 성분 제거 
  mpu.update();
  float rawAcc = mpu.getAccelMagnitude();
  float acc = lpf.update(hpf.update(rawAcc));

  // 마지막측정타임 업데이트
  lastSampleTime = micros();

  getImpulse(acc);

  //Serial.println(acc);
  connection.sendDebug(acc);

  // if (contactDetector.update(acc, current)) {
  //     // 지면 이탈이 확정되고 유효한 지면접촉시간이 산출된 시점
  //     Serial.print("산출됨 : ");
  //     unsigned long gct = contactDetector.getLastContactTimeMs();
  //     Serial.println(gct);
  //     BTData data(packetNumber,acc,0,gct);
  //     connection.send(data);
  // }
}


