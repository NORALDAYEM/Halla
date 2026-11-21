import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halaa/main.dart';

void main() {
  testWidgets('room search survives tab changes and composes with country', (tester) async {
    await tester.pumpWidget(const HalaaApp());
    final field = find.byType(TextField);
    const query = '  لمّة   الاصدقاء  ';
    await tester.enterText(field, query);
    await tester.pumpAndSettle();
    expect(find.text('لمة الأصدقاء'), findsOneWidget);
    expect(find.text('المجلس الملكي'), findsNothing);

    await tester.tap(find.text('الألعاب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الغرف'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, query);
    expect(find.text('لمة الأصدقاء'), findsOneWidget);

    await tester.tap(find.text('السعودية'));
    await tester.pumpAndSettle();
    expect(find.text('لمة الأصدقاء'), findsNothing);
    await tester.enterText(field, '');
    await tester.pumpAndSettle();
    expect(find.text('المجلس الملكي'), findsOneWidget);
    expect(find.text('لمة الأصدقاء'), findsNothing);
  });
}
