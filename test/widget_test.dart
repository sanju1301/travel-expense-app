import 'package:flutter_test/flutter_test.dart';
import 'package:travel_expense/main.dart';

void main() {
  testWidgets('shows dashboard shell', (tester) async {
    await tester.pumpWidget(const TravelExpenseApp());
    expect(find.text('Good afternoon'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });
}
