import 'package:flutter_test/flutter_test.dart';

import 'package:th5_nhom5/main.dart';

void main() {
  testWidgets('App widget can be created', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentManagerApp());
    expect(find.byType(StudentManagerApp), findsOneWidget);
  });
}
