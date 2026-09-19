import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess/chess.dart' as chess;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../domain/models/chess_game_state.dart';
import '../../../../domain/models/user_profile.dart';
import '../../../../domain/engine/chess_ai.dart';
import '../../../../data/services/audio_service.dart';
import '../../../../data/services/supabase_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final audio = AudioService();
  // Initialize asynchronously; first sound play is always ahead of UI
  audio.init();
  ref.onDispose(audio.dispose);
  return audio;
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService());

final supabaseAuthStateProvider = StreamProvider<AuthState>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.authStateChanges ?? const Stream.empty();
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  // Watch authState to trigger re-fetch on login status changes
  ref.watch(supabaseAuthStateProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  final user = supabase.currentUser;
  if (user == null) return null;

  try {
    var profile = await supabase.fetchProfile(user.id);
    if (profile == null) {
      final metadataName = user.userMetadata?['username'] ?? user.userMetadata?['full_name'];
      final fallbackUsername = metadataName ?? user.email?.split('@').first ?? 'Player';
      
      final newProfile = UserProfile(
        id: user.id,
        username: fallbackUsername,
        displayName: fallbackUsername,
      );
      await supabase.updateProfile(newProfile);
      return newProfile;
    }
    return profile;
  } catch (_) {
    final fallbackUsername = user.email?.split('@').first ?? 'Player';
    return UserProfile(
      id: user.id,
      username: fallbackUsername,
      displayName: fallbackUsername,
    );
  }
});

final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, ChessGameState>((ref) {
  final audio = ref.watch(audioServiceProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  return GameStateNotifier(audio: audio, supabase: supabase);
});

class GameStateNotifier extends StateNotifier<ChessGameState> {
  final AudioService _audio;
  final SupabaseService _supabase;
  late chess.Chess _game;
  Timer? _clockTimer;

  GameStateNotifier({
    required AudioService audio,
    required SupabaseService supabase,
  })  : _audio = audio,
        _supabase = supabase,
        super(_createInitialState()) {
    _game = chess.Chess();
  }

  static ChessGameState _createInitialState({
    GameMode mode = GameMode.offlinePassAndPlay,
    AiDifficulty difficulty = AiDifficulty.medium,
    int timeControlSeconds = 300,
    PlayerColor playerColor = PlayerColor.white,
    String? matchId,
    String? roomCode,
  }) {
    final ms = timeControlSeconds * 1000;
    return ChessGameState(
      fen: chess.Chess.DEFAULT_POSITION,
      turn: PlayerColor.white,
      playerColor: playerColor,
      whiteTimeMs: ms,
      blackTimeMs: ms,
      gameMode: mode,
      aiDifficulty: difficulty,
      matchId: matchId,
      roomCode: roomCode,
    );
  }

  chess.Chess get game => _game;

  void startNewGame({
    required GameMode mode,
    AiDifficulty difficulty = AiDifficulty.medium,
    int timeControlSeconds = 300,
    PlayerColor playerColor = PlayerColor.white,
    String? matchId,
    String? roomCode,
  }) {
    _clockTimer?.cancel();
    _game = chess.Chess();

    state = _createInitialState(
      mode: mode,
      difficulty: difficulty,
      timeControlSeconds: timeControlSeconds,
      playerColor: playerColor,
      matchId: matchId,
      roomCode: roomCode,
    );

    if (timeControlSeconds > 0) {
      _startClock();
    }

    // If vs AI and player chose Black, AI (White) makes the first move
    if (mode == GameMode.offlineAi && playerColor == PlayerColor.black) {
      _triggerAiMove();
    }

    // If online match, subscribe to realtime channel
    if ((mode == GameMode.onlineMatchmaking ||
            mode == GameMode.onlinePrivateRoom) &&
        matchId != null) {
      _supabase.subscribeToMatchChannel(
        matchId: matchId,
        onMoveReceived: (data) => _handleRemoteMove(data),
        onGameEnded: (data) => _handleRemoteGameEnd(data),
      );
    }
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (state.isGameOver) {
        timer.cancel();
        return;
      }

      if (state.turn == PlayerColor.white) {
        final newTime = state.whiteTimeMs - 100;
        if (newTime <= 0) {
          timer.cancel();
          _handleTimeout(PlayerColor.white);
        } else {
          state = state.copyWith(whiteTimeMs: newTime);
        }
      } else {
        final newTime = state.blackTimeMs - 100;
        if (newTime <= 0) {
          timer.cancel();
          _handleTimeout(PlayerColor.black);
        } else {
          state = state.copyWith(blackTimeMs: newTime);
        }
      }
    });
  }

  void _handleTimeout(PlayerColor timedOutPlayer) {
    _audio.playGameOver();
    state = state.copyWith(
      status: GameStatus.timeout,
      winner: timedOutPlayer.opposite,
      whiteTimeMs: timedOutPlayer == PlayerColor.white ? 0 : state.whiteTimeMs,
      blackTimeMs: timedOutPlayer == PlayerColor.black ? 0 : state.blackTimeMs,
    );
  }

  void onSquareTapped(String square) {
    if (state.isGameOver || state.isThinkingAi) return;

    // In single player vs AI or online, prevent moving opponent's pieces
    if (state.gameMode == GameMode.offlineAi &&
        state.turn != state.playerColor) {
      return;
    }
    if ((state.gameMode == GameMode.onlineMatchmaking ||
            state.gameMode == GameMode.onlinePrivateRoom) &&
        state.turn != state.playerColor) {
      return;
    }

    final pieceAtSquare = _game.get(square);
    final currentTurnCode =
        state.turn == PlayerColor.white ? chess.Color.WHITE : chess.Color.BLACK;

    // Case 1: A square is already selected
    if (state.selectedSquare != null) {
      final from = state.selectedSquare!;

      // Case 1a: Tap selected square again -> Deselect
      if (from == square) {
        state = state.copyWith(clearSelectedSquare: true, validMoves: []);
        return;
      }

      // Case 1b: Tap a legal destination square -> Make Move
      if (state.validMoves.contains(square)) {
        _executeMove(from: from, to: square);
        return;
      }

      // Case 1c: Tap another own piece -> Switch selection
      if (pieceAtSquare != null && pieceAtSquare.color == currentTurnCode) {
        _selectSquare(square);
        return;
      }

      // Case 1d: Tap empty or illegal square -> Deselect
      state = state.copyWith(clearSelectedSquare: true, validMoves: []);
      return;
    }

    // Case 2: No square selected -> Select piece if it's current player's
    if (pieceAtSquare != null && pieceAtSquare.color == currentTurnCode) {
      _selectSquare(square);
    }
  }

  void _selectSquare(String square) {
    final moves = _game.moves({'square': square, 'verbose': true});
    final validDests = moves.map<String>((m) => m['to'] as String).toList();

    state = state.copyWith(
      selectedSquare: square,
      validMoves: validDests,
    );
  }

  void _executeMove({
    required String from,
    required String to,
    String promotion = 'q',
  }) {
    final capturedPiece = _game.get(to);
    final movedPiece = _game.get(from);

    // Capture standard algebraic notation (SAN) before state update
    final verboseMoves = _game.moves({'verbose': true});
    final matched = verboseMoves.firstWhere(
      (m) => m['from'] == from && m['to'] == to,
      orElse: () => null,
    );
    final san = matched != null ? (matched['san'] as String) : '$from$to';

    // Make move in chess engine
    final success = _game.move({
      'from': from,
      'to': to,
      'promotion': promotion,
    });

    if (!success) return;

    // Update captured piece lists
    final capturedWhite = List<String>.from(state.capturedWhitePieces);
    final capturedBlack = List<String>.from(state.capturedBlackPieces);

    if (capturedPiece != null) {
      final pChar = capturedPiece.type.name;
      if (capturedPiece.color == chess.Color.WHITE) {
        capturedWhite.add(pChar.toUpperCase());
      } else {
        capturedBlack.add(pChar.toLowerCase());
      }
      _audio.playCapture();
    } else {
      _audio.playMove();
    }

    if (_game.in_check) {
      _audio.playCheck();
    }

    final moveObj = ChessMove(
      from: from,
      to: to,
      san: san,
      piece: movedPiece?.type.name ?? 'p',
      captured: capturedPiece?.type.name,
      promotion: promotion,
    );

    final newHistory = List<ChessMove>.from(state.moveHistory)..add(moveObj);
    final nextTurn =
        _game.turn == chess.Color.WHITE ? PlayerColor.white : PlayerColor.black;

    // Check terminal conditions
    GameStatus status = GameStatus.inProgress;
    PlayerColor? winner;

    if (_game.in_checkmate) {
      status = GameStatus.checkmate;
      winner = state.turn; // Current mover delivered checkmate
      _audio.playGameOver();
    } else if (_game.in_stalemate) {
      status = GameStatus.stalemate;
      _audio.playGameOver();
    } else if (_game.in_draw || _game.insufficient_material) {
      status = GameStatus.draw;
      _audio.playGameOver();
    }

    state = state.copyWith(
      fen: _game.fen,
      turn: nextTurn,
      clearSelectedSquare: true,
      validMoves: [],
      lastMove: moveObj,
      status: status,
      winner: winner,
      isCheck: _game.in_check,
      capturedWhitePieces: capturedWhite,
      capturedBlackPieces: capturedBlack,
      moveHistory: newHistory,
    );

    // Broadcast move if online
    if ((state.gameMode == GameMode.onlineMatchmaking ||
            state.gameMode == GameMode.onlinePrivateRoom) &&
        state.matchId != null) {
      _supabase.broadcastMove(
        matchId: state.matchId!,
        moveData: {
          'from': from,
          'to': to,
          'san': moveObj.san,
          'fen': _game.fen,
          'white_time_ms': state.whiteTimeMs,
          'black_time_ms': state.blackTimeMs,
        },
      );
    }

    // Trigger AI move if single player vs AI and game not over
    if (state.gameMode == GameMode.offlineAi &&
        !state.isGameOver &&
        nextTurn != state.playerColor) {
      _triggerAiMove();
    }
  }

  void _triggerAiMove() {
    state = state.copyWith(isThinkingAi: true);

    // Small artificial delay for natural feel
    Future.delayed(const Duration(milliseconds: 400), () async {
      if (state.isGameOver) return;
      final bestMove =
          await ChessAi.findBestMove(_game, state.aiDifficulty);

      state = state.copyWith(isThinkingAi: false);

      if (bestMove != null && !state.isGameOver) {
        _executeMove(
          from: bestMove['from']!,
          to: bestMove['to']!,
          promotion: bestMove['promotion'] ?? 'q',
        );
      }
    });
  }

  void _handleRemoteMove(Map<String, dynamic> data) {
    final from = data['from'] as String?;
    final to = data['to'] as String?;
    if (from != null && to != null) {
      _executeMove(from: from, to: to);
    }
  }

  void _handleRemoteGameEnd(Map<String, dynamic> data) {
    final reason = data['reason'] as String?;
    final winnerId = data['winner_id'] as String?;
    _clockTimer?.cancel();

    GameStatus status = GameStatus.draw;
    if (reason == 'resigned') {
      status = GameStatus.resigned;
    } else if (reason == 'checkmate') {
      status = GameStatus.checkmate;
    }

    PlayerColor? winner;
    if (winnerId != null) {
      winner = winnerId == _supabase.currentUser?.id
          ? state.playerColor
          : state.playerColor.opposite;
    }

    state = state.copyWith(
      status: status,
      winner: winner,
    );
  }

  void resign() {
    _clockTimer?.cancel();
    _audio.playGameOver();
    state = state.copyWith(
      status: GameStatus.resigned,
      winner: state.turn.opposite,
    );

    if (state.matchId != null) {
      _supabase.broadcastGameEnd(
        matchId: state.matchId!,
        reason: 'resigned',
        winnerId: state.turn.opposite.code,
      );
    }
  }

  void offerDraw() {
    _clockTimer?.cancel();
    _audio.playGameOver();
    state = state.copyWith(
      status: GameStatus.draw,
    );

    if (state.matchId != null) {
      _supabase.broadcastGameEnd(
        matchId: state.matchId!,
        reason: 'draw',
        winnerId: null,
      );
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _supabase.unsubscribeFromMatch();
    super.dispose();
  }
}
