import 'package:flutter_test/flutter_test.dart';
import 'package:sesh_trainer/screens/home_screen.dart';

void main() {
  group('ScaleHomePage Tests', () {
    testWidgets('Widget Initialization Test', (WidgetTester tester) async {
      await tester.pumpWidget(ScaleHomePage());

      // Verify that the weight card is displayed
      expect(find.text('Weight'), findsOneWidget);

      // Verify that the max card is displayed
      expect(find.text('Max'), findsOneWidget);

      // Verify that the elapsed time card is displayed
      expect(find.text('Elapsed Time'), findsOneWidget);
    });

    testWidgets('Start Data Test', (WidgetTester tester) async {
      await tester.pumpWidget(ScaleHomePage());

      // Tap the start button
      await tester.tap(find.text('Start'));
      await tester.pump();

      // Verify that the recording data text is displayed
      expect(find.text('Recording Data'), findsOneWidget);
    });

    testWidgets('Stop Data Test', (WidgetTester tester) async {
      await tester.pumpWidget(ScaleHomePage());

      // Tap the stop button
      await tester.tap(find.text('Stop'));
      await tester.pump();

      // Verify that the view details button is displayed
      expect(find.text('View Details'), findsOneWidget);
    });

    testWidgets('Reset Data Test', (WidgetTester tester) async {
      await tester.pumpWidget(ScaleHomePage());

      // Tap the reset button
      await tester.tap(find.text('Reset'));
      await tester.pump();

      // Verify that the weight is null
      expect(find.text('0.0'), findsNWidgets(2));
    });
  });
}