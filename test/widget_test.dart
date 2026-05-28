// Basic smoke test untuk SIBI AI App.
// Memastikan aplikasi dapat di-render tanpa crash.

import 'package:flutter_test/flutter_test.dart';

import 'package:sibi_app/main.dart';

void main() {
  testWidgets('SIBI App smoke test — WelcomeScreen renders correctly',
      (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const SibiApp());
    await tester.pump(const Duration(seconds: 1));

    // Pastikan WelcomeScreen muncul dengan judul aplikasi
    expect(find.text('SIBI Translator AI'), findsOneWidget);
  });
}
