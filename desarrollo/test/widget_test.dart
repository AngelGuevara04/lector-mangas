import 'package:flutter_test/flutter_test.dart';
import 'package:amors_reader/main.dart';

void main() {
  testWidgets('MangaFlowApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MangaFlowApp());
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
  });
}
