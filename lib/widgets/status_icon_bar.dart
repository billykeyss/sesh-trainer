import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dyno_data_provider.dart';

class StatusIconBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Consumer<DynoDataProvider>(
      builder: (context, dynoDataProvider, child) {
        int lastDataReceivedTime = dynoDataProvider.lastDataReceivedTime;
        bool isDeviceConnected =
            DateTime.now().millisecondsSinceEpoch - lastDataReceivedTime <
                100000;
        bool isRecording = dynoDataProvider.recordData;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Device connection status
              Expanded(
                child: _buildStatusCard(
                  context,
                  isDeviceConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  isDeviceConnected ? 'Connected' : 'Disconnected',
                  isDeviceConnected ? 'Device linked' : 'No device found',
                  isDeviceConnected ? Colors.green : Colors.red,
                  isDarkMode,
                  isActive: isDeviceConnected,
                ),
              ),
              SizedBox(width: 12),

              // Recording status
              Expanded(
                child: _buildStatusCard(
                  context,
                  isRecording
                      ? Icons.fiber_manual_record
                      : Icons.stop_circle_outlined,
                  isRecording ? 'Recording' : 'Standby',
                  isRecording ? 'Data logging' : 'Ready to start',
                  isRecording ? Colors.blue : Colors.grey,
                  isDarkMode,
                  isActive: isRecording,
                  showPulse: isRecording,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    bool isDarkMode, {
    bool isActive = false,
    bool showPulse = false,
  }) {
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.grey[800];
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isActive ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon with background
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: showPulse
                ? _buildPulsingIcon(icon, color)
                : Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
          ),
          SizedBox(width: 12),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingIcon(IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Icon(
            icon,
            color: color.withOpacity(value),
            size: 20,
          ),
        );
      },
      onEnd: () {
        // This will restart the animation
      },
    );
  }
}
