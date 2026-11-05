import 'package:flutter_test/flutter_test.dart';
import 'package:xclean/main.dart';

void main() {
  testWidgets('XClean app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const XCleanApp());
    expect(find.text('XClean (Oclean X Pro Elite)'), findsOneWidget);
  });
}
