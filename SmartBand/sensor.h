#ifndef SENSOR_H
#define SENSOR_H


#include <Arduino.h>
#include <Wire.h>


//가속도 센서 MPU 6050 클래스
// begin()으로 연결 시작해야하며, update() 호출해야 그 시점에서 측정함
class AccelerationSensor {
    private:

        

        void readRaw();      

    public:

        int16_t ax, ay, az;
        bool begin();

        void update();

        int16_t getAccX();
        int16_t getAccY();
        int16_t getAccZ();

        float getAccelMagnitude();

};

#endif