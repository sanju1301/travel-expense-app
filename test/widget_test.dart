import 'package:flutter_test/flutter_test.dart';
import 'package:travel_expense/main.dart';

void main() {
  testWidgets('shows dashboard shell', (tester) async {
    await tester.pumpWidget(const TravelExpenseApp());
    await tester.pumpAndSettle();

    expect(find.text('Good afternoon'), findsWidgets);
    expect(find.text('Expenses'), findsWidgets);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Profile'), findsWidgets);
  });
}
