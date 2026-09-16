import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess_go/main.dart';

void main() {
  testWidgets('ChessGoApp smoke test loads Home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ChessGoApp(),
      ),
    );

    // Initial pump and settle
    await tester.pumpAndSettle();

    // Verify brand header
    expect(find.text('ChessGo'), findsOneWidget);
    expect(find.text('Play vs AI Bot'), findsOneWidget);
    expect(find.text('Pass & Play'), findsOneWidget);
    expect(find.text('Leaderboard'), findsOneWidget);
  });
}
