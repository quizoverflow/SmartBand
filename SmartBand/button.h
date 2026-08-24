// =====================================



//   Deprecated




// 버튼 방식에서 자동 시작으로 변경으로 인해 Button 관련 메서드 전부 Deprecate





















#ifndef BUTTON_H
#define BUTTON_H

#include "Arduino.h"
#include "config.h"

// 버튼 하강 엣지(Falling Edge) 감지 및 50ms 디바운스
bool checkButton(){
    static int lastRawState = HIGH;       // 직전 물리 핀 상태
    static int stableState = HIGH;        // 디바운스 필터링된 안정 상태
    static unsigned long lastDebounceTime = 0;
    const unsigned long DEBOUNCE_DELAY = 50; // 50ms 디바운스

    bool isPressed = false;
    int reading = digitalRead(BTN_PIN);

    // 노이즈나 물리적 신호 변화 발생 시 타이머 리셋
    if (reading != lastRawState) {
        lastDebounceTime = millis();
    }

    // 50ms 동안 동일한 신호가 유지될 때 상태 인정
    if ((millis() - lastDebounceTime) > DEBOUNCE_DELAY) {
        if (reading != stableState) {
            stableState = reading;
            
            // HIGH에서 LOW로 떨어지는 순간(버튼을 누른 시점)에만 1회 true 반환
            if (stableState == LOW) {
                isPressed = true;
            }
        }
    }

    lastRawState = reading;
    return isPressed;
}

#endif