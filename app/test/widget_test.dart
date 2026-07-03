import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('App renders splash page', (WidgetTester tester) async {
    await tester.pumpWidget(const EduLearnApp());
    expect(find.text('EduLearn AI'), findsOneWidget);
  });
}
