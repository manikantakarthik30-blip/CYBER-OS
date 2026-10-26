import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/main.dart';

void main() {
  testWidgets('CyberOSApp launches splash boot screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CyberOSApp(),
      ),
    );

    expect(find.byType(CyberOSApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 500));
  });
}

