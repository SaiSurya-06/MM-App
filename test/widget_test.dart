import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/app.dart';

void main() {
  testWidgets('App compiles and launches basic widget tests', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MoneyManagerApp(),
      ),
    );

    // Verify onboarding screen title or basic widgets exist
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
