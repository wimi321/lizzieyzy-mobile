import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';

void main() {
  testWidgets('launches the two-destination product shell', (tester) async {
    await tester.pumpWidget(const LizzieYzyApp());
    await tester.pumpAndSettle();

    expect(find.text('棋谱'), findsWidgets);
    expect(find.text('识谱'), findsOneWidget);
    expect(find.text('拍照识谱'), findsOneWidget);
  });
}
