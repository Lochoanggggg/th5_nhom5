import 'package:flutter_test/flutter_test.dart';

import 'package:th5_nhom5/main.dart';

void main() {
  testWidgets('AppInitError renders error details', (WidgetTester tester) async {
    await tester.pumpWidget(const AppInitError(error: 'sample error'));
    expect(find.text('Firebase setup required'), findsOneWidget);
    expect(find.textContaining('sample error'), findsOneWidget);
  });
}
