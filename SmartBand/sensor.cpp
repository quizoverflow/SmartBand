#include "sensor.h"


#define MPU_ADDR 0x68 // mpu 주소
#define PWR_MGMT_1 0x6B  // power on 주소
#define ACCEL_CONFIG 0x1C // 가속도 측정 범위
#define ACCEL_XOUT_H 0x3B // 가속도 값이 존재하는 주소
                          // 3B == X High, 3C == X Low....0x40 Z low
// 1g = 2048 로 센서값이 읽히므로 변환 필요 
const float G_TO_MS2 = 0.004788f; // 단위 변환용 상수 9.80665f / 2048.0f 

// 통신 시작 메서드
// 통신 시작 결과에 따라 true / false 반환
bool AccelerationSensor::begin()
{
    Wire.begin();
    Wire.setClock(400000);

    Wire.beginTransmission(MPU_ADDR);
    Wire.write(PWR_MGMT_1);
    Wire.write(0); // wake up

    if (Wire.endTransmission() != 0) return false;

    Wire.beginTransmission(MPU_ADDR);
    Wire.write(ACCEL_CONFIG);
    Wire.write(0x18); // +- 16G 
    if (Wire.endTransmission() != 0) return false;

    return true;

}

// 측정 메서드 (외부 호출)
void AccelerationSensor::update()
{
    readRaw();
}

// 측정메서드 (내부 호출)
void AccelerationSensor::readRaw()
{
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(ACCEL_XOUT_H);
    Wire.endTransmission(false);

    //x,y,z축 값 읽기 (각 축은 2개의 값으로 분할 저장되어있음)
    Wire.requestFrom(MPU_ADDR, 6);

    // 분리된 값 합치기
    ax = Wire.read()<<8 | Wire.read();
    ay = Wire.read()<<8 | Wire.read();
    az = Wire.read()<<8 | Wire.read();
}

//3 축 벡터 합성 후, m/s^2 로 단위 변환 
float AccelerationSensor::getAccelMagnitude(){
    float x = (float)ax;
    float y = (float)ay;
    float z = (float)az;
    return sqrt(x*x + y*y + z*z) * G_TO_MS2;
}


// 각 축에 대한 가속도 값.. 추후 사용 위해서 
int16_t AccelerationSensor::getAccX() { return ax; }
int16_t AccelerationSensor::getAccY() { return ay; }
int16_t AccelerationSensor::getAccZ() { return az; }

