import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:intl/intl.dart';

String formatGraphData(List<dynamic> graphData, String weightUnit) {
  StringBuffer graphDataTable = StringBuffer();
  graphDataTable.writeln('\n\nGraph Data:');
  graphDataTable.writeln('Time (s)\tWeight ($weightUnit)');
  for (var spot in graphData) {
    graphDataTable.writeln('${spot['x'].toStringAsFixed(2)}\t\t${spot['y'].toStringAsFixed(2)}');
  }
  return graphDataTable.toString();
}

String formatSessionData(DateTime sessionStartTime, double maxWeight, String weightUnit, String elapsedTime) {
  return '''
Session Time: ${DateFormat('MMM d, yyyy, h:mm a').format(sessionStartTime)}
Max Pull: ${maxWeight.toStringAsFixed(2)} $weightUnit
80% Pull: ${(maxWeight * 0.8).toStringAsFixed(2)} $weightUnit
20% Pull: ${(maxWeight * 0.2).toStringAsFixed(2)} $weightUnit
Elapsed Time: $elapsedTime
''';
}

Future<void> sendEmailSummary(String name, String email, DateTime sessionStartTime, List<dynamic> graphData, double maxWeight, String weightUnit, String elapsedTime, double averageWeight, double totalLoad) async {
  final String sessionData = formatSessionData(sessionStartTime, maxWeight, weightUnit, elapsedTime);
  final String graphDataFormatted = formatGraphData(graphData, weightUnit);
  
  final Email emailToSend = Email(
    body: '''
Name: $name
Max Weight: $maxWeight
Elapsed Time: $elapsedTime
Average Weight: ${averageWeight.toStringAsFixed(1)}
Total Load: ${totalLoad.toStringAsFixed(1)}

Please find attached the screenshot of the weight graph.
$sessionData
$graphDataFormatted
''',
    subject: 'Leaderboard Entry Summary',
    recipients: [email],
  );

  await FlutterEmailSender.send(emailToSend);
}