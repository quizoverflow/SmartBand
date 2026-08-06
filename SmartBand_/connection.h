#pragma once

#include <SoftwareSerial.h>


struct BTData {
    int id;
    int cadence;
    float peak;
    float impact;
    char msg[64];

    // 1. 기본 생성자 (인자 없이 선언할 때 필요)
    BTData() : id(0), cadence(0), peak(0.0f), impact(0.0f) {
        msg[0] = '\0'; // 빈 문자열 초기화
    }

    // 2. 매개변수가 있는 생성자
    BTData(int id, float peak, int cadence, float impact) {
        this->id = id;
        this->peak = peak;
        this->cadence = cadence;
        this->impact = impact;

        // snprintf 수정: 서식지정자에 들어갈 변수들을 순서대로 전달해야 합니다.
        snprintf(msg, sizeof(msg), "#%d\nP%.1f\nC%d\nI%.2f", id, peak, cadence, impact);
    }
};

class ConnectionController {
public:
    ConnectionController()
        : BtSerial(8, 11)
    {
    }

    void begin() {
        BtSerial.begin(57600);
    }

    void send_start(){
        BtSerial.println("Start");
    }
    void send_end(){
        BtSerial.println("END");
    }

    void send(BTData data) {
        BtSerial.println(data.msg);
    }
    
    void sendDebug(float data){
        BtSerial.println(data);
    }

private:
    SoftwareSerial BtSerial;
};