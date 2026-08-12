import 'package:app/meta/app_theme.dart';
import 'package:app/screens/utility/permission_handler_screen.dart';
import 'package:app/screens/screen_tracking.dart';
import 'package:flutter/material.dart';

class ExerciseMenu extends StatelessWidget {
  const ExerciseMenu({super.key});

  void _navigateTo(BuildContext context, Widget targetScreen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.groundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 블루투스 아이콘
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.secondaryColor,
            ),
            child: const Icon(
              Icons.bluetooth,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),

          // 타이틀
          const Text(
            "러닝 준비",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),

          // 서브타이틀
          const Text(
            "블루투스 센서를 연결하고\n러닝을 시작해보세요",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          // 블루투스 연결 버튼
          _ActionButton(
            label: "블루투스 연결하기",
            onPressed: () => _navigateTo(context, const BluetoothPermissionScreen()),
          ),
          const SizedBox(height: 12),

          // 시작 버튼 (블루투스 연결 없이도 가능은 함)
          _ActionButton(
            label: "시작 하기",
            backgroundColor: const Color(0xFF00C7BE), // 또는 AppTheme 색상 사용
            onPressed: () => _navigateTo(context, const TrackingScreen()),
          ),
        ],
      ),
    );
  }
}

/// 공통 액션 버튼 컴포넌트
class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF00C7BE),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}