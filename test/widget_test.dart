import 'package:flutter_test/flutter_test.dart';
import 'package:aiaccounting/main.dart';

void main() {
  testWidgets('App displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const AIAccountingApp());
    expect(find.text('AI Accounting'), findsOneWidget);
  });
}
