import 'dart:math';
import 'package:chess/chess.dart' as chess;
import '../models/chess_game_state.dart';

/// Pure Dart Chess AI utilizing Minimax with Alpha-Beta Pruning
/// and Piece-Square Table (PST) positional evaluation.
class ChessAi {
  static final Random _random = Random();

  // Piece Base Values (Centipawns)
  static const int pawnValue = 100;
  static const int knightValue = 320;
  static const int bishopValue = 330;
  static const int rookValue = 500;
  static const int queenValue = 900;
  static const int kingValue = 20000;

  // Piece-Square Tables (From White's perspective, 8x8 flipped for Black)
  static const List<int> pawnPst = [
    0, 0, 0, 0, 0, 0, 0, 0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
    5, 5, 10, 25, 25, 10, 5, 5,
    0, 0, 0, 20, 20, 0, 0, 0,
    5, -5, -10, 0, 0, -10, -5, 5,
    5, 10, 10, -20, -20, 10, 10, 5,
    0, 0, 0, 0, 0, 0, 0, 0,
  ];

  static const List<int> knightPst = [
    -50, -40, -30, -30, -30, -30, -40, -50,
    -40, -20, 0, 0, 0, 0, -20, -40,
    -30, 0, 10, 15, 15, 10, 0, -30,
    -30, 5, 15, 20, 20, 15, 5, -30,
    -30, 0, 15, 20, 20, 15, 0, -30,
    -30, 5, 10, 15, 15, 10, 5, -30,
    -40, -20, 0, 5, 5, 0, -20, -40,
    -50, -40, -30, -30, -30, -30, -40, -50,
  ];

  static const List<int> bishopPst = [
    -20, -10, -10, -10, -10, -10, -10, -20,
    -10, 0, 0, 0, 0, 0, 0, -10,
    -10, 0, 5, 10, 10, 5, 0, -10,
    -10, 5, 5, 10, 10, 5, 5, -10,
    -10, 0, 10, 10, 10, 10, 0, -10,
    -10, 10, 10, 10, 10, 10, 10, -10,
    -10, 5, 0, 0, 0, 0, 5, -10,
    -20, -10, -10, -10, -10, -10, -10, -20,
  ];

  static const List<int> rookPst = [
    0, 0, 0, 0, 0, 0, 0, 0,
    5, 10, 10, 10, 10, 10, 10, 5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    0, 0, 0, 5, 5, 0, 0, 0,
  ];

  static const List<int> queenPst = [
    -20, -10, -10, -5, -5, -10, -10, -20,
    -10, 0, 0, 0, 0, 0, 0, -10,
    -10, 0, 5, 5, 5, 5, 0, -10,
    -5, 0, 5, 5, 5, 5, 0, -5,
    0, 0, 5, 5, 5, 5, 0, -5,
    -10, 5, 5, 5, 5, 5, 0, -10,
    -10, 0, 5, 0, 0, 0, 0, -10,
    -20, -10, -10, -5, -5, -10, -10, -20,
  ];

  static const List<int> kingPst = [
    -30, -40, -40, -50, -50, -40, -40, -30,
    -30, -40, -40, -50, -50, -40, -40, -30,
    -30, -40, -40, -50, -50, -40, -40, -30,
    -30, -40, -40, -50, -50, -40, -40, -30,
    -20, -30, -30, -40, -40, -30, -30, -20,
    -10, -20, -20, -20, -20, -20, -20, -10,
    20, 20, 0, 0, 0, 0, 20, 20,
    20, 30, 10, 0, 0, 10, 30, 20,
  ];

  /// Evaluates board state and returns best move
  static Future<Map<String, String>?> findBestMove(
    chess.Chess game,
    AiDifficulty difficulty,
  ) async {
    final moves = game.moves({'verbose': true});
    if (moves.isEmpty) return null;

    final isWhite = game.turn == chess.Color.WHITE;
    final depth = difficulty.searchDepth;

    // Easy mode: small chance to pick random move or shallow eval
    if (difficulty == AiDifficulty.easy && _random.nextDouble() < 0.35) {
      final randomMove = moves[_random.nextInt(moves.length)];
      return {
        'from': randomMove['from'] as String,
        'to': randomMove['to'] as String,
        'promotion': (randomMove['promotion'] as String?) ?? 'q',
      };
    }

    // Sort moves to optimize alpha-beta pruning (captures first)
    _orderMoves(moves);

    Map<String, dynamic>? bestMove;
    int bestScore = isWhite ? -999999 : 999999;
    int alpha = -999999;
    int beta = 999999;

    for (final move in moves) {
      game.move(move);
      final score = _minimax(game, depth - 1, alpha, beta, !isWhite);
      game.undo();

      if (isWhite) {
        if (score > bestScore) {
          bestScore = score;
          bestMove = move;
        }
        alpha = max(alpha, bestScore);
      } else {
        if (score < bestScore) {
          bestScore = score;
          bestMove = move;
        }
        beta = min(beta, bestScore);
      }

      if (beta <= alpha) {
        break; // Alpha-beta cut
      }
    }

    if (bestMove == null && moves.isNotEmpty) {
      bestMove = moves.first;
    }

    if (bestMove == null) return null;

    return {
      'from': bestMove['from'] as String,
      'to': bestMove['to'] as String,
      'promotion': (bestMove['promotion'] as String?) ?? 'q',
    };
  }

  static int _minimax(
    chess.Chess game,
    int depth,
    int alpha,
    int beta,
    bool isMaximizing,
  ) {
    if (depth == 0 || game.game_over) {
      return _evaluateBoard(game);
    }

    final moves = game.moves({'verbose': true});
    _orderMoves(moves);

    if (isMaximizing) {
      int maxEval = -999999;
      for (final move in moves) {
        game.move(move);
        final evaluation = _minimax(game, depth - 1, alpha, beta, false);
        game.undo();
        maxEval = max(maxEval, evaluation);
        alpha = max(alpha, evaluation);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 999999;
      for (final move in moves) {
        game.move(move);
        final evaluation = _minimax(game, depth - 1, alpha, beta, true);
        game.undo();
        minEval = min(minEval, evaluation);
        beta = min(beta, evaluation);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  /// Evaluates the board static evaluation in centipawns
  /// Positive = White advantage, Negative = Black advantage
  static int _evaluateBoard(chess.Chess game) {
    if (game.in_checkmate) {
      return game.turn == chess.Color.WHITE ? -90000 : 90000;
    }
    if (game.in_draw || game.in_stalemate || game.insufficient_material) {
      return 0;
    }

    int evaluation = 0;

    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final squareIndex = rank * 8 + file;
        final squareName = _squareFromIndex(rank, file);
        final piece = game.get(squareName);
        if (piece == null) continue;

        final isWhitePiece = piece.color == chess.Color.WHITE;
        final pieceType = piece.type.toLowerCase();

        int pieceScore = 0;
        int pstScore = 0;

        switch (pieceType) {
          case 'p':
            pieceScore = pawnValue;
            pstScore = isWhitePiece
                ? pawnPst[squareIndex]
                : pawnPst[_flipSquare(squareIndex)];
            break;
          case 'n':
            pieceScore = knightValue;
            pstScore = isWhitePiece
                ? knightPst[squareIndex]
                : knightPst[_flipSquare(squareIndex)];
            break;
          case 'b':
            pieceScore = bishopValue;
            pstScore = isWhitePiece
                ? bishopPst[squareIndex]
                : bishopPst[_flipSquare(squareIndex)];
            break;
          case 'r':
            pieceScore = rookValue;
            pstScore = isWhitePiece
                ? rookPst[squareIndex]
                : rookPst[_flipSquare(squareIndex)];
            break;
          case 'q':
            pieceScore = queenValue;
            pstScore = isWhitePiece
                ? queenPst[squareIndex]
                : queenPst[_flipSquare(squareIndex)];
            break;
          case 'k':
            pieceScore = kingValue;
            pstScore = isWhitePiece
                ? kingPst[squareIndex]
                : kingPst[_flipSquare(squareIndex)];
            break;
        }

        final totalScore = pieceScore + pstScore;
        evaluation += isWhitePiece ? totalScore : -totalScore;
      }
    }

    return evaluation;
  }

  static void _orderMoves(List<dynamic> moves) {
    // Captures first to maximize alpha-beta cutoffs
    moves.sort((a, b) {
      final aCaptured = a['captured'] != null ? 1 : 0;
      final bCaptured = b['captured'] != null ? 1 : 0;
      return bCaptured.compareTo(aCaptured);
    });
  }

  static int _flipSquare(int index) {
    final rank = index ~/ 8;
    final file = index % 8;
    return (7 - rank) * 8 + file;
  }

  static String _squareFromIndex(int rank, int file) {
    // 0 is rank 8, 7 is rank 1
    final actualRank = 8 - rank;
    final fileLetter = String.fromCharCode('a'.codeUnitAt(0) + file);
    return '$fileLetter$actualRank';
  }
}
