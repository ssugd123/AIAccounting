import 'package:flutter_test/flutter_test.dart';
import 'package:aiaccounting/app.dart';

void main() {
  testWidgets('App displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const AIAccountingApp());
    expect(find.text('AI记账'), findsOneWidget);
  });
}
