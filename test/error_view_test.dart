import 'package:circleplus/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ErrorView retry invokes callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            message: 'Network failed',
            onRetry: () => taps += 1,
          ),
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Network failed'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(taps, 1);
  });
}
