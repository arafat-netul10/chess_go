enum GameMode {
  offlinePassAndPlay,
  offlineAi,
  onlineMatchmaking,
  onlinePrivateRoom,
}

enum AiDifficulty {
  easy('Easy', 1),
  medium('Medium', 3),
  hard('Hard', 4);

  final String label;
  final int searchDepth;
  const AiDifficulty(this.label, this.searchDepth);
}

enum PlayerColor {
  white('w', 'White'),
  black('b', 'Black');

  final String code;
  final String label;
  const PlayerColor(this.code, this.label);

  PlayerColor get opposite => this == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
}

enum GameStatus {
  inProgress,
  checkmate,
  stalemate,
  draw,
  resigned,
  timeout,
}

class ChessMove {
  final String from;
  final String to;
  final String san;
  final String piece;
  final String? captured;
  final String? promotion;

  const ChessMove({
    required this.from,
    required this.to,
    required this.san,
    required this.piece,
    this.captured,
    this.promotion,
  });

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'san': san,
        'piece': piece,
        'captured': captured,
        'promotion': promotion,
      };

  factory ChessMove.fromJson(Map<String, dynamic> json) => ChessMove(
        from: json['from'] as String,
        to: json['to'] as String,
        san: json['san'] as String? ?? '',
        piece: json['piece'] as String? ?? 'p',
        captured: json['captured'] as String?,
        promotion: json['promotion'] as String?,
      );
}

class ChessGameState {
  final String fen;
  final PlayerColor turn;
  final PlayerColor playerColor;
  final String? selectedSquare;
  final List<String> validMoves;
  final ChessMove? lastMove;
  final GameStatus status;
  final PlayerColor? winner;
  final bool isCheck;
  final int whiteTimeMs;
  final int blackTimeMs;
  final List<String> capturedWhitePieces;
  final List<String> capturedBlackPieces;
  final List<ChessMove> moveHistory;
  final GameMode gameMode;
  final AiDifficulty aiDifficulty;
  final String? matchId;
  final String? roomCode;
  final bool isThinkingAi;

  const ChessGameState({
    required this.fen,
    required this.turn,
    required this.playerColor,
    this.selectedSquare,
    this.validMoves = const [],
    this.lastMove,
    this.status = GameStatus.inProgress,
    this.winner,
    this.isCheck = false,
    required this.whiteTimeMs,
    required this.blackTimeMs,
    this.capturedWhitePieces = const [],
    this.capturedBlackPieces = const [],
    this.moveHistory = const [],
    required this.gameMode,
    this.aiDifficulty = AiDifficulty.medium,
    this.matchId,
    this.roomCode,
    this.isThinkingAi = false,
  });

  bool get isGameOver => status != GameStatus.inProgress;

  /// Material difference from White's perspective
  int get materialDifference {
    const values = {'p': 1, 'n': 3, 'b': 3, 'r': 5, 'q': 9, 'k': 0};
    int whiteScore = 0;
    int blackScore = 0;
    for (final p in capturedBlackPieces) {
      whiteScore += values[p.toLowerCase()] ?? 0;
    }
    for (final p in capturedWhitePieces) {
      blackScore += values[p.toLowerCase()] ?? 0;
    }
    return whiteScore - blackScore;
  }

  ChessGameState copyWith({
    String? fen,
    PlayerColor? turn,
    PlayerColor? playerColor,
    String? selectedSquare,
    bool clearSelectedSquare = false,
    List<String>? validMoves,
    ChessMove? lastMove,
    GameStatus? status,
    PlayerColor? winner,
    bool? isCheck,
    int? whiteTimeMs,
    int? blackTimeMs,
    List<String>? capturedWhitePieces,
    List<String>? capturedBlackPieces,
    List<ChessMove>? moveHistory,
    GameMode? gameMode,
    AiDifficulty? aiDifficulty,
    String? matchId,
    String? roomCode,
    bool? isThinkingAi,
  }) {
    return ChessGameState(
      fen: fen ?? this.fen,
      turn: turn ?? this.turn,
      playerColor: playerColor ?? this.playerColor,
      selectedSquare:
          clearSelectedSquare ? null : (selectedSquare ?? this.selectedSquare),
      validMoves: validMoves ?? this.validMoves,
      lastMove: lastMove ?? this.lastMove,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      isCheck: isCheck ?? this.isCheck,
      whiteTimeMs: whiteTimeMs ?? this.whiteTimeMs,
      blackTimeMs: blackTimeMs ?? this.blackTimeMs,
      capturedWhitePieces: capturedWhitePieces ?? this.capturedWhitePieces,
      capturedBlackPieces: capturedBlackPieces ?? this.capturedBlackPieces,
      moveHistory: moveHistory ?? this.moveHistory,
      gameMode: gameMode ?? this.gameMode,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      matchId: matchId ?? this.matchId,
      roomCode: roomCode ?? this.roomCode,
      isThinkingAi: isThinkingAi ?? this.isThinkingAi,
    );
  }
}
