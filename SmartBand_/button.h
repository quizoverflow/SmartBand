#ifndef BUTTON_H
#define BUTTON_H

#include "Arduino.h"
#include "config.h"

// 버튼 상태
// 0 : 버튼 신호 리스닝중
// 1 : 버튼 눌리고 대기
int buttonState = 0; 

// 직전에 읽은 버튼 물리 상태
// LOW가 눌림, HIGH는 안눌림
int lastRawState = HIGH;


unsigned long lastDebounceTime = 0;
const unsigned long DEBOUNCE_DELAY = 100; // 0.1초 이내 스위치 여러번 눌리는 것은 무시함


// 스위치가 눌렸는지 체크. 바운싱 현상 제거 위함
// 가장 마지막에 들어온 버튼 신호가 입력된 후, 0.1 초 지나야 버튼 상태 변경으로 인정됨
bool checkButton(){

    //스위치 값 읽기
    int reading = digitalRead(BTN_PIN);

    //바운싱 확인
    if(reading == LOW && buttonState == 0){
        lastDebounceTime = millis();
        buttonState = 1;
    }

    //바운싱 확인
    else if(reading == LOW && buttonState == 1){
        lastDebounceTime = millis();
    }

    if(reading == HIGH && buttonState == 1){
        if((millis() - lastDebounceTime) >  DEBOUNCE_DELAY){
            return true;
        }
    }
    return false;
}



#endif