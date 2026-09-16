import 'package:flutter_test/flutter_test.dart';
import 'package:chess/chess.dart' as chess;

void main() {
  test('chess package basic functionality test', () {
    final game = chess.Chess();
    expect(game.turn, chess.Color.WHITE);
    expect(game.in_check, false);

    final moves = game.generate_moves();
    expect(moves.isNotEmpty, true);

    final verboseMoves = game.moves({'verbose': true});
    expect(verboseMoves.length, 20);

    final matched = verboseMoves.firstWhere(
      (m) => m['from'] == 'e2' && m['to'] == 'e4',
    );
    final san = matched['san'] as String;
    expect(san, 'e4');
    
    final success = game.move({'from': 'e2', 'to': 'e4'});
    expect(success, true);
    expect(game.turn, chess.Color.BLACK);
  });
}
