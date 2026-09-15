import 'package:flutter_test/flutter_test.dart';
import 'package:signature_sync/main.dart';

void main() {
  testWidgets('Splash shows brand then navigates to onboarding',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SignatureSyncApp());
    await tester.pump();

    expect(find.textContaining('Signature'), findsWidgets);
    expect(find.textContaining('Sync'), findsWidgets);
    expect(find.text('SIGN IT. SYNC IT. DONE.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(); // settle one frame after navigation

    expect(find.text('Draw your signature'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
