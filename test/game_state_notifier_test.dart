import 'package:flutter_test/flutter_test.dart';
import 'package:chess_go/domain/models/chess_game_state.dart';
import 'package:chess_go/data/services/audio_service.dart';
import 'package:chess_go/data/services/supabase_service.dart';
import 'package:chess_go/ui/features/game/view_models/game_state_notifier.dart';

void main() {
  group('GameStateNotifier Tests', () {
    late GameStateNotifier notifier;

    setUp(() {
      notifier = GameStateNotifier(
        audio: AudioService(enabled: false),
        supabase: SupabaseService(),
      );
    });

    test('Initial game state is properly initialized', () {
      notifier.startNewGame(
        mode: GameMode.offlinePassAndPlay,
        timeControlSeconds: 300,
      );

      final state = notifier.state;
      expect(state.turn, PlayerColor.white);
      expect(state.status, GameStatus.inProgress);
      expect(state.isCheck, false);
      expect(state.selectedSquare, isNull);
      expect(state.validMoves, isEmpty);
      expect(state.whiteTimeMs, 300000);
      expect(state.blackTimeMs, 300000);
    });

    test('Tapping piece selects it and generates valid legal moves', () {
      notifier.startNewGame(
        mode: GameMode.offlinePassAndPlay,
        timeControlSeconds: 300,
      );

      // Tap e2 pawn
      notifier.onSquareTapped('e2');
      expect(notifier.state.selectedSquare, 'e2');
      expect(notifier.state.validMoves, contains('e3'));
      expect(notifier.state.validMoves, contains('e4'));
    });

    test('Tapping legal destination executes move and switches turn', () {
      notifier.startNewGame(
        mode: GameMode.offlinePassAndPlay,
        timeControlSeconds: 300,
      );

      // White plays 1. e4
      notifier.onSquareTapped('e2');
      notifier.onSquareTapped('e4');

      expect(notifier.state.turn, PlayerColor.black);
      expect(notifier.state.selectedSquare, isNull);
      expect(notifier.state.lastMove?.san, 'e4');
      expect(notifier.state.moveHistory.length, 1);
    });

    test('Resigning awards victory to opponent', () {
      notifier.startNewGame(
        mode: GameMode.offlinePassAndPlay,
        timeControlSeconds: 300,
      );

      // White resigns
      notifier.resign();

      expect(notifier.state.status, GameStatus.resigned);
      expect(notifier.state.winner, PlayerColor.black);
      expect(notifier.state.isGameOver, true);
    });
  });
}
