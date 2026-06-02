import 'package:flutter_test/flutter_test.dart';

import 'package:wuthering_wares_flutter/main.dart';

void main() {
  testWidgets('shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WutheringWaresApp());
    await tester.pump();

    expect(find.text('MASUK'), findsAtLeastNWidgets(1));
    expect(find.text('EMAIL'), findsOneWidget);
  });
}
