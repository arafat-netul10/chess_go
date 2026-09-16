class OnlineMatch {
  final String id;
  final String? whiteId;
  final String? blackId;
  final String fen;
  final String pgn;
  final String? lastMove;
  final String status;
  final String? winnerId;
  final int timeControlSeconds;
  final int whiteTimeLeftMs;
  final int blackTimeLeftMs;
  final String currentTurn;
  final DateTime createdAt;

  const OnlineMatch({
    required this.id,
    this.whiteId,
    this.blackId,
    required this.fen,
    this.pgn = '',
    this.lastMove,
    this.status = 'waiting',
    this.winnerId,
    this.timeControlSeconds = 300,
    this.whiteTimeLeftMs = 300000,
    this.blackTimeLeftMs = 300000,
    this.currentTurn = 'w',
    required this.createdAt,
  });

  factory OnlineMatch.fromJson(Map<String, dynamic> json) {
    return OnlineMatch(
      id: json['id'] as String,
      whiteId: json['white_id'] as String?,
      blackId: json['black_id'] as String?,
      fen: json['fen'] as String? ??
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      pgn: json['pgn'] as String? ?? '',
      lastMove: json['last_move'] as String?,
      status: json['status'] as String? ?? 'waiting',
      winnerId: json['winner_id'] as String?,
      timeControlSeconds: json['time_control_seconds'] as int? ?? 300,
      whiteTimeLeftMs: json['white_time_left_ms'] as int? ?? 300000,
      blackTimeLeftMs: json['black_time_left_ms'] as int? ?? 300000,
      currentTurn: json['current_turn'] as String? ?? 'w',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'white_id': whiteId,
        'black_id': blackId,
        'fen': fen,
        'pgn': pgn,
        'last_move': lastMove,
        'status': status,
        'winner_id': winnerId,
        'time_control_seconds': timeControlSeconds,
        'white_time_left_ms': whiteTimeLeftMs,
        'black_time_left_ms': blackTimeLeftMs,
        'current_turn': currentTurn,
      };
}

class GameRoom {
  final String code;
  final String hostId;
  final String? guestId;
  final int timeControlSeconds;
  final String status;
  final String? matchId;

  const GameRoom({
    required this.code,
    required this.hostId,
    this.guestId,
    this.timeControlSeconds = 300,
    this.status = 'open',
    this.matchId,
  });

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      code: json['code'] as String,
      hostId: json['host_id'] as String,
      guestId: json['guest_id'] as String?,
      timeControlSeconds: json['time_control_seconds'] as int? ?? 300,
      status: json['status'] as String? ?? 'open',
      matchId: json['match_id'] as String?,
    );
  }
}
