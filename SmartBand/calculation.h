#pragma once
#include <Arduino.h>

struct StepResult {
    float peakAcc;       // 피크 가속도 (m/s²)
    int cadence;         // 케이던스 (SPM)
    float stepImpulse;   // 단일 걸음 충격량 (m/s)
    float totalImpulse;  // 최근 15걸음 가중 누적 충격량 (m/s)
    unsigned long gct;   // 지면 접촉 시간 (ms)
};

class StepAnalyzer {
private:
    float peakThreshold;         // 무릎 피크 문턱값 (8.5 m/s²)
    float contactThreshold;      // 지면 접촉 문턱값 (2.0 m/s²)
    unsigned long minIntervalUs; // 걸음 불응기 (450ms)
    unsigned long debounceUs;    // 착지 이탈 디바운스 (25ms)
    unsigned long maxIntervalUs; // 타임아웃 (2.5s)

    enum PeakState { IDLE, IN_PEAK } peakState;
    float currentPeakAcc;
    unsigned long currentPeakTimeUs;
    unsigned long lastPeakTimeUs;
    unsigned long lastEmittedPeakTimeUs;

    bool isGrounded;
    unsigned long touchStartUs;
    unsigned long lastAboveContactUs;
    unsigned long measuredGctMs;

    bool pendingStep;
    float pendingPeakAcc;
    unsigned long pendingPeakTimeUs;

    float currentStepImpulse;
    const float DT = 0.002f;

    float stepHistory[15];
    int historyIndex;
    int recordedSteps;

    float get15StepImpulseSum() {
        float sum = 0.0f;
        int count = (recordedSteps < 15) ? recordedSteps : 15;
        for (int k = 0; k < count; k++) {
            int idx = (historyIndex - 1 - k + 15) % 15;
            int weight = 15 - k;
            sum += stepHistory[idx] * (float)weight;
        }
        return sum;
    }

public:
    StepAnalyzer(float peakThresh = 8.5f, float contactThresh = 2.0f, unsigned long minIntervalMs = 450)
        : peakThreshold(peakThresh),
          contactThreshold(contactThresh),
          minIntervalUs(minIntervalMs * 1000UL),
          debounceUs(25000UL),
          maxIntervalUs(2500000UL),
          peakState(IDLE),
          currentPeakAcc(0.0f),
          currentPeakTimeUs(0),
          lastPeakTimeUs(0),
          lastEmittedPeakTimeUs(0),
          isGrounded(false),
          touchStartUs(0),
          lastAboveContactUs(0),
          measuredGctMs(120),
          pendingStep(false),
          pendingPeakAcc(0.0f),
          pendingPeakTimeUs(0),
          currentStepImpulse(0.0f),
          historyIndex(0),
          recordedSteps(0) {
        for (int i = 0; i < 15; i++) stepHistory[i] = 0.0f;
    }

    bool update(float acc, unsigned long currentUs, StepResult &outResult) {
        bool stepCompleted = false;
        bool toeOffOccurred = false;

        // 1. GCT 추적 (Initial Contact 감지)
        if (acc >= contactThreshold) {
            lastAboveContactUs = currentUs;
            if (!isGrounded) {
                isGrounded = true;
                touchStartUs = currentUs;
                currentStepImpulse = 0.0f;
            }
        } 
        else if (isGrounded) {
            if (currentUs - lastAboveContactUs >= debounceUs) {
                unsigned long durationUs = lastAboveContactUs - touchStartUs;
                // 빠른 무릎 충격(35~55ms)도 정상 수용하도록 30ms 하한선 적용
                if (durationUs >= 30000UL) {
                    unsigned long gct = durationUs / 1000UL;
                    measuredGctMs = (gct > 400UL) ? 400UL : gct;
                    toeOffOccurred = true;
                }
                isGrounded = false;
            }
        }

        if (isGrounded && acc > 1.5f) {
            currentStepImpulse += acc * DT;
        }

        // 2. 피크 검출 FSM
        if (peakState == IDLE) {
            if (acc >= peakThreshold && (lastPeakTimeUs == 0 || (currentUs - lastPeakTimeUs >= minIntervalUs))) {
                peakState = IN_PEAK;
                currentPeakAcc = acc;
                currentPeakTimeUs = currentUs;
            }
        } 
        else if (peakState == IN_PEAK) {
            if (acc > currentPeakAcc) {
                currentPeakAcc = acc;
                currentPeakTimeUs = currentUs;
            }

            if (acc < currentPeakAcc * 0.7f || acc < peakThreshold * 0.7f) {
                peakState = IDLE;
                pendingStep = true;
                pendingPeakAcc = currentPeakAcc;
                pendingPeakTimeUs = currentPeakTimeUs;
                lastPeakTimeUs = currentPeakTimeUs;
            }
        }

        // 3. 걸음 최종 확정 및 동기화
        bool shouldEmit = false;
        if (pendingStep) {
            if (toeOffOccurred || !isGrounded) {
                shouldEmit = true;
            } else if (currentUs - pendingPeakTimeUs > 300000UL) {
                shouldEmit = true;
            }
        }

        if (shouldEmit) {
            pendingStep = false;

            unsigned long deltaUs = (lastEmittedPeakTimeUs > 0) ? (pendingPeakTimeUs - lastEmittedPeakTimeUs) : 0;
            lastEmittedPeakTimeUs = pendingPeakTimeUs;

            stepHistory[historyIndex] = currentStepImpulse;
            historyIndex = (historyIndex + 1) % 15;
            recordedSteps++;

            outResult.peakAcc = pendingPeakAcc;
            outResult.stepImpulse = currentStepImpulse;
            outResult.totalImpulse = get15StepImpulseSum();
            outResult.gct = measuredGctMs; // 매 걸음마다 새로 계산된 GCT 전달

            if (deltaUs == 0 || deltaUs > maxIntervalUs) {
                outResult.cadence = 175;
            } else {
                float strideSec = deltaUs / 1000000.0f;
                outResult.cadence = (int)(120.0f / strideSec);
            }

            stepCompleted = true;
            currentPeakAcc = 0.0f;
            currentStepImpulse = 0.0f;
        }

        return stepCompleted;
    }

    void reset() {
        peakState = IDLE;
        isGrounded = false;
        currentPeakAcc = 0.0f;
        lastPeakTimeUs = 0;
        lastEmittedPeakTimeUs = 0;
        pendingStep = false;
        pendingPeakAcc = 0.0f;
        pendingPeakTimeUs = 0;
        currentStepImpulse = 0.0f;
        historyIndex = 0;
        recordedSteps = 0;
        for (int i = 0; i < 15; i++) stepHistory[i] = 0.0f;
        measuredGctMs = 120;
    }
};