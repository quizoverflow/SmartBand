#pragma once
// =============================
// 충격량 계산 (적분)
// ============================
// 충격량 계산 관련 변수
float velocityChange = 0.0f;         // 속도 변화량 (m/s) -> 질량을 곱하면 충격량(N·s)
// 실험 필요 변수 
const float ACC_THRESHOLD = 0.5f;   // 충격 감지 문턱값 (m/s²)
const float DAMPING = 0.95f;
const float DT = 1.0f / 500.0f;     // dt = 0.002s
float getImpulse(float acc){
    if (acc < 0) acc *= -1;

    if (acc > ACC_THRESHOLD) {
        // 문턱값 이상의 진동이 유입될 때 적분 수행
        if(acc < 0) acc *= -1;
        velocityChange += acc * DT;
    } else {
        // 충격 이벤트가 끝나면 천천히 감쇠
        velocityChange *= DAMPING;
    }
}

// =====================
// 지면 접촉 시간 감지
// 지면 접촉 시간단위는 ms 
// ====================
// 관련 변수 => 모두 실험 필요 
const float TOUCH_THRESHOLD = 1.2f;    // 접촉 판단 가속도 문턱값 (m/s²)
const unsigned long MIN_CONTACT_TIME_MS = 30; // 노이즈로 인한 오작동 방지 (최소 접촉시간)
const unsigned long RELEASE_DEBOUNCE_MS = 20; // 지면 이탈 시 신호 요동을 견디는 디바운스 시간
bool isGrounded = false;
unsigned long touchStartTimeUs = 0;
unsigned long lastAboveThresholdTimeUs = 0;

class GroundContactDetector {
private:
    // 설정 변수
    float touchThreshold;
    unsigned long minContactTimeUs;
    unsigned long releaseDebounceUs;

    // 상태 변수
    bool isGrounded;
    unsigned long touchStartTimeUs;
    unsigned long lastAboveThresholdTimeUs;
    unsigned long lastContactTimeMs;

public:
    GroundContactDetector(float threshold = 1.2f, 
                           unsigned long minContactMs = 30, 
                           unsigned long debounceMs = 20)
        : touchThreshold(threshold),
          minContactTimeUs(minContactMs * 1000UL),
          releaseDebounceUs(debounceMs * 1000UL),
          isGrounded(false),
          touchStartTimeUs(0),
          lastAboveThresholdTimeUs(0),
          lastContactTimeMs(0) {}

    /**
     * @brief 필터링된 가속도 값을 입력받아 지면 접촉 상태를 업데이트합니다.
     * @param accelValue 필터링된 가속도 크기 (m/s²)
     * @param currentUs 현재 시간 (micros() 값)
     * @return bool 접촉이 완료되어 새로운 지면접촉시간이 측정되었을 때 true 반환
     */
    bool update(float accelValue, unsigned long currentUs) {
        bool isNewMeasurementReady = false;

        if (accelValue >= touchThreshold) {
            lastAboveThresholdTimeUs = currentUs;
            
            // 공중에 있다가 지면에 처음 닿은 순간
            if (!isGrounded) {
                isGrounded = true;
                touchStartTimeUs = currentUs;
            }
        } else {
            // 접촉 중이었지만 가속도가 문턱값 미만으로 떨어진 경우
            if (isGrounded) {
                // 문턱값을 마지막으로 넘겼던 시점으로부터 디바운스 시간이 지났는지 확인
                if (currentUs - lastAboveThresholdTimeUs >= releaseDebounceUs) {
                    // 실제 접촉 유지 시간 계산 (유효 문턱값 마지막 시점 - 시작 시점)
                    unsigned long contactDurationUs = lastAboveThresholdTimeUs - touchStartTimeUs;

                    // 최소 접촉 시간 조건을 만족하는 유효한 걸음인지 검증
                    if (contactDurationUs >= minContactTimeUs) {
                        lastContactTimeMs = contactDurationUs / 1000UL;
                        isNewMeasurementReady = true;
                    }

                    // 상태 리셋
                    isGrounded = false;
                }
            }
        }

        return isNewMeasurementReady;
    }

    // 현재 지면 접촉 여부 확인
    bool getIsGrounded() const {
        return isGrounded;
    }

    // 최근 측정된 지면접촉시간 (ms)
    unsigned long getLastContactTimeMs() const {
        return lastContactTimeMs;
    }
};