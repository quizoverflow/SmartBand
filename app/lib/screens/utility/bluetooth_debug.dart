import 'package:flutter/material.dart';
import 'bluetooth_manager.dart';

class BluetoothDebugWidget extends StatelessWidget {
  const BluetoothDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final btManager = BluetoothManager();

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📡 Live BT Serial Data',
            style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          _buildDeviceRow('Dev #1', btManager.dataStream1, Colors.lightBlueAccent),
          const SizedBox(height: 2),
          _buildDeviceRow('Dev #2', btManager.dataStream2, Colors.lightGreenAccent),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(String label, Stream<String> stream, Color labelColor) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(color: labelColor, fontSize: 12, fontWeight: FontWeight.bold)),
        Expanded(
          child: StreamBuilder<String>(
            stream: stream,
            builder: (context, snapshot) {
              final text = snapshot.data?.trim() ?? 'No Signal';
              return Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
      ],
    );
  }
}