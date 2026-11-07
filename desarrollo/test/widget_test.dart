import 'package:flutter_test/flutter_test.dart';
import 'package:amors_reader/main.dart';

void main() {
  testWidgets('AmorsReaderApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AmorsReaderApp());
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
  });
}
