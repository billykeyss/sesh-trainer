import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dyno_data_provider.dart';

class StatusIconBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DynoDataProvider>(
      builder: (context, dynoDataProvider, child) {
        int lastDataReceivedTime = dynoDataProvider.lastDataReceivedTime;

        bool isDeviceConnected = DateTime.now().millisecondsSinceEpoch - lastDataReceivedTime < 100000;
        bool isRecording = dynoDataProvider.recordData;

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Device connection status
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0), // Padding inside the border
                margin: const EdgeInsets.only(
                    right: 8.0), // Margin to separate the two sections
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isDeviceConnected ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown, // Scale text to fit within the container
                        child: Text(
                          isDeviceConnected ? 'Device Connected' : 'Device Not Connected',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDeviceConnected ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0), // Space between text and dot
                      child: Icon(
                        Icons.circle,
                        color: isDeviceConnected ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Recording status
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0), // Padding inside the border
                margin: const EdgeInsets.only(
                    left: 8.0), // Margin to separate the two sections
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isRecording ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown, // Scale text to fit within the container
                        child: Text(
                          isRecording ? 'Recording Data' : 'Not Recording Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isRecording ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0), // Space between text and icon
                      child: isRecording
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                              ),
                            )
                          : Icon(
                              Icons.circle,
                              color: Colors.red,
                              size: 20,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
