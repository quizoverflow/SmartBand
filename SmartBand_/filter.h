#pragma once
// Biquad 필터 구조체 정의
struct BiquadFilter {
    float b0, b1, b2;
    float a1, a2;
    float x1, x2; // 이전 입력값 (x[n-1], x[n-2])
    float y1, y2; // 이전 출력값 (y[n-1], y[n-2])

    // 기본 생성자 (초기화)
    BiquadFilter() 
        : b0(0), b1(0), b2(0), a1(0), a2(0), x1(0), x2(0), y1(0), y2(0) {}

    // 계수 매개변수를 받는 생성자
    BiquadFilter(float b0_val, float b1_val, float b2_val, float a1_val, float a2_val)
        : b0(b0_val), b1(b1_val), b2(b2_val), a1(a1_val), a2(a2_val),
          x1(0.0f), x2(0.0f), y1(0.0f), y2(0.0f) {}

    float update(float x) {
        float y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
        
        // 상태 업데이트
        x2 = x1;
        x1 = x;
        y2 = y1;
        y1 = y;

        return y;
    }

    // 상태 리셋 (필요시 호출)
    void reset() {
        x1 = x2 = y1 = y2 = 0.0f;
    }
};

// inline 키워드를 붙여 헤더 중복 include 시 발생하는 Multiple Definition 에러 방지
// 1. HPF (fc = 0.5 Hz)
inline BiquadFilter hpf(0.995567f, -1.991134f, 0.995567f, -1.991114f, 0.991154f);

// 2. LPF (fc = 20 Hz)
inline BiquadFilter lpf(0.013359f, 0.026718f, 0.013359f, -1.647457f, 0.700894f);

