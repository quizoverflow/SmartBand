#pragma once
#include <SoftwareSerial.h>

struct BTData {
    int id;
    float peak;
    int cadence;
    float stepImpulse;
    float totalImpulse;
    unsigned long gct;
    char msg[96];

    BTData() : id(0), peak(0.0f), cadence(0), stepImpulse(0.0f), totalImpulse(0.0f), gct(0) {
        msg[0] = '\0';
    }

    BTData(int id, float peak, int cadence, float stepImpulse, float totalImpulse, unsigned long gct) {
        this->id = id;
        this->peak = peak;
        this->cadence = cadence;
        this->stepImpulse = stepImpulse;
        this->totalImpulse = totalImpulse;
        this->gct = gct;

        // snprintf 는 float 그대로 못보내는 이슈 있음
        char peakStr[10];
        char impulseStr[10];
        dtostrf(peak, 4, 1, peakStr);          // %.1f 대응
        dtostrf(totalImpulse, 6, 2, impulseStr);

        // 순서: ID, 피크,  케이던스, 누적충격량, G:GCT
        snprintf(msg, sizeof(msg), "%d,%s,%d,%s,%lu\n", 
                 id, peakStr, cadence, impulseStr, gct);
    }
};

class ConnectionController {
public:
    ConnectionController() : BtSerial(8, 11) {}

    void begin() {
        BtSerial.begin(57600);
    }

    bool available() {
        return BtSerial.available() > 0;
    }

    char read() {
        return BtSerial.read();
    }

    void send_start() {
        BtSerial.println("Start");
    }

    void send(BTData data) {
        BtSerial.println(data.msg);
    }

private:
    SoftwareSerial BtSerial;
};