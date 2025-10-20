import 'package:flutter_test/flutter_test.dart';
import 'package:mygamelist/main.dart';
import 'package:mygamelist/managers/game_manager.dart';
import 'package:mygamelist/managers/theme_manager.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GameManager()),
          ChangeNotifierProvider(create: (_) => ThemeManager()),
        ],
        child: const MyGameListApp(),
      ),
    );

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
  });
}