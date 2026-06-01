import 'package:flutter_test/flutter_test.dart';

import 'package:fingate_app_mobile/main.dart';

void main() {
  testWidgets('Fingate app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FingateApp());

    expect(find.text('Fingate'), findsOneWidget);
  });
}