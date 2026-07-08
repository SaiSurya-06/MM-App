import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/widgets/common/premium_error_widget.dart';

void main() {
  testWidgets('PremiumErrorWidget Golden UI Test', (WidgetTester tester) async {
    // Set a fixed screen size/viewport for deterministic screenshot comparison
    tester.binding.window.physicalSizeTestValue = const Size(1080, 1920);
    tester.binding.window.devicePixelRatioTestValue = 2.0;

    final errorDetails = FlutterErrorDetails(
      exception: Exception('Database migration failed: SQLite error 1 (no such table: transaction_log)'),
      stack: StackTrace.current,
      library: 'core/database',
      context: ErrorDescription('while upgrading database schema from version 7 to 8'),
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PremiumErrorWidget(details: errorDetails),
      ),
    );

    await tester.pumpAndSettle();

    // Verify UI components are loaded
    expect(find.byType(PremiumErrorWidget), findsOneWidget);
    expect(find.text('Oops! Something went wrong'), findsOneWidget);

    // Perform golden image screenshot comparison
    await expectLater(
      find.byType(PremiumErrorWidget),
      matchesGoldenFile('goldens/premium_error_widget.png'),
    );

    // Reset window settings after the test runs
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });
  });
}
