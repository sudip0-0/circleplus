import 'package:circleplus/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows initial CirclePulse shell', (WidgetTester tester) async {
    await tester.pumpWidget(const CirclePulseApp());

    expect(find.text('CirclePulse'), findsOneWidget);
    expect(
      find.text('Private Circles, daily Pulses, and simple Plans.'),
      findsOneWidget,
    );
  });
}
