import 'package:flutter_test/flutter_test.dart';
import 'package:chess/chess.dart' as chess;
import 'package:chess_go/domain/engine/chess_ai.dart';
import 'package:chess_go/domain/models/chess_game_state.dart';

void main() {
  group('ChessAi Tests', () {
    test('AI finds a legal move from initial position', () async {
      final game = chess.Chess();
      final move = await ChessAi.findBestMove(game, AiDifficulty.medium);
      expect(move, isNotNull);
      expect(move!['from'], isNotNull);
      expect(move['to'], isNotNull);

      // Verify move is legal
      final success = game.move(move);
      expect(success, true);
    });

    test('AI finds checkmate in 1 move if available', () async {
      // Scholar's mate setup: 1. e4 e5 2. Bc4 Nc6 3. Qh5 Nf6?? 4. Qxf7#
      final game = chess.Chess();
      game.move({'from': 'e2', 'to': 'e4'});
      game.move({'from': 'e7', 'to': 'e5'});
      game.move({'from': 'f1', 'to': 'c4'});
      game.move({'from': 'b8', 'to': 'c6'});
      game.move({'from': 'd1', 'to': 'h5'});
      game.move({'from': 'g8', 'to': 'f6'});

      // White's turn - Qxf7# is available
      final move = await ChessAi.findBestMove(game, AiDifficulty.hard);
      expect(move, isNotNull);
      expect(move!['from'], 'h5');
      expect(move['to'], 'f7');

      game.move(move);
      expect(game.in_checkmate, true);
    });
  });
}
