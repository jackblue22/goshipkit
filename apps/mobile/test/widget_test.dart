import 'package:flutter_test/flutter_test.dart';
import 'package:goshipkit_mobile/main.dart';

void main() {
  testWidgets('renders the product name', (tester) async {
    await tester.pumpWidget(const GoShipKitApp());
    expect(find.text('GoShipKit mobile'), findsOneWidget);
  });
}
