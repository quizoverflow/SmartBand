import 'package:app/screens/utility/screen_tracking.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/data/DataController.dart';
import 'package:app/utils.dart';

import '../../meta/app_theme.dart';
import '../utility/permission_handler_screen.dart';

class ExerciseMenu extends StatelessWidget {
  const ExerciseMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color : AppTheme.groundColor,
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

          const Text(
            "러닝 준비",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "블루투스 센서를 연결하고\n러닝을 시작해보세요",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BluetoothPermissionScreen(),
                  )
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C7BE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "블루투스 연결 후 시작",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15,),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TrackingScreen(),
                    )
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C7BE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "블루투스 연결없이 시작",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ================ 블루투스 연결 ==============


