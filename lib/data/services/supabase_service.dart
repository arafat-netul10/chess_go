import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/online_match.dart';

/// Backend service providing Supabase Auth, Realtime multiplayer,
/// Leaderboard data, and seamless offline-first fallbacks.
class SupabaseService {
  static SupabaseClient? _client;

  static SupabaseClient? get client {
    if (_client != null) return _client;
    if (AppConfig.isSupabaseConfigured) {
      try {
        _client = Supabase.instance.client;
      } catch (_) {}
    }
    return _client;
  }

  static bool get isOnlineSupported =>
      AppConfig.isSupabaseConfigured && client != null;

  /// Initialize Supabase if configured
  static Future<void> initialize() async {
    if (AppConfig.isSupabaseConfigured) {
      try {
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          // ignore: deprecated_member_use
          anonKey: AppConfig.supabaseAnonKey,
        );
        _client = Supabase.instance.client;
      } catch (e) {
        debugPrint('Supabase init error: $e');
      }
    }
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  User? get currentUser => client?.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;

  Future<AuthResponse?> signInWithEmail(String email, String password) async {
    if (!isOnlineSupported) {
      throw Exception(
        'Supabase is not configured. Please add SUPABASE_URL and SUPABASE_ANON_KEY to app_config.dart or compile with --dart-define.',
      );
    }
    return await client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    if (!isOnlineSupported) {
      throw Exception('Supabase is not configured.');
    }
    return await client!.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'username': username.trim(), 'full_name': username.trim()},
    );
  }

  Future<bool> signInWithGoogle() async {
    if (!isOnlineSupported) {
      throw Exception('Supabase is not configured.');
    }
    return await client!.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'com.antigravity.chessgo://login-callback',
    );
  }

  Future<void> signOut() async {
    if (client != null) {
      await client!.auth.signOut();
    }
  }

  // ==========================================
  // USER PROFILES & STATS
  // ==========================================

  Future<UserProfile?> fetchProfile(String userId) async {
    if (!isOnlineSupported) return null;
    try {
      final res = await client!
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (res != null) {
        return UserProfile.fromJson(res);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
    return null;
  }

  Future<void> updateProfile(UserProfile profile) async {
    if (!isOnlineSupported) return;
    try {
      await client!.from('profiles').upsert(profile.toJson());
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  Future<List<UserProfile>> fetchLeaderboard({int limit = 50}) async {
    if (!isOnlineSupported) {
      return _getFallbackLeaderboard();
    }

    try {
      final res = await client!
          .from('profiles')
          .select()
          .order('elo_rating', ascending: false)
          .limit(limit);

      final list = (res as List)
          .map((item) => UserProfile.fromJson(item as Map<String, dynamic>))
          .toList();

      if (list.isEmpty) {
        return _getFallbackLeaderboard();
      }
      return list;
    } catch (e) {
      debugPrint('Error fetching leaderboard from Supabase: $e');
      return _getFallbackLeaderboard();
    }
  }

  /// Curated fallback leaderboard data for offline/demo mode
  static List<UserProfile> _getFallbackLeaderboard() {
    return const [
      UserProfile(
        id: 'gm-1',
        username: 'MagnusK',
        displayName: 'Magnus K.',
        eloRating: 2850,
        wins: 342,
        losses: 41,
        draws: 85,
      ),
      UserProfile(
        id: 'gm-2',
        username: 'HikaruN',
        displayName: 'Hikaru N.',
        eloRating: 2815,
        wins: 310,
        losses: 48,
        draws: 72,
      ),
      UserProfile(
        id: 'gm-3',
        username: 'GukeshD',
        displayName: 'Gukesh D.',
        eloRating: 2795,
        wins: 215,
        losses: 35,
        draws: 50,
      ),
      UserProfile(
        id: 'gm-4',
        username: 'ArjunE',
        displayName: 'Arjun E.',
        eloRating: 2780,
        wins: 198,
        losses: 40,
        draws: 45,
      ),
      UserProfile(
        id: 'gm-5',
        username: 'FabianoC',
        displayName: 'Fabiano C.',
        eloRating: 2775,
        wins: 290,
        losses: 52,
        draws: 68,
      ),
      UserProfile(
        id: 'gm-6',
        username: 'DingL',
        displayName: 'Ding L.',
        eloRating: 2760,
        wins: 250,
        losses: 58,
        draws: 60,
      ),
      UserProfile(
        id: 'gm-7',
        username: 'AlirezaF',
        displayName: 'Alireza F.',
        eloRating: 2750,
        wins: 230,
        losses: 60,
        draws: 40,
      ),
      UserProfile(
        id: 'gm-8',
        username: 'PraggR',
        displayName: 'Praggnanandhaa R.',
        eloRating: 2740,
        wins: 210,
        losses: 50,
        draws: 55,
      ),
    ];
  }

  // ==========================================
  // MATCHMAKING & PRIVATE ROOMS
  // ==========================================

  /// Generate a readable 6-character room code (e.g. "GO8429")
  static String generateRoomCode() {
    final rand = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<GameRoom> createRoom({
    required String hostId,
    int timeControlSeconds = 300,
  }) async {
    final code = generateRoomCode();
    if (isOnlineSupported) {
      await client!.from('rooms').insert({
        'code': code,
        'host_id': hostId,
        'time_control_seconds': timeControlSeconds,
        'status': 'open',
      });
    }
    return GameRoom(
      code: code,
      hostId: hostId,
      timeControlSeconds: timeControlSeconds,
      status: 'open',
    );
  }

  Future<GameRoom?> joinRoom({
    required String code,
    required String guestId,
  }) async {
    if (!isOnlineSupported) return null;
    try {
      final roomData = await client!
          .from('rooms')
          .select()
          .eq('code', code.toUpperCase())
          .eq('status', 'open')
          .maybeSingle();

      if (roomData == null) return null;

      // Create a match for this room
      final matchRes = await client!.from('matches').insert({
        'white_id': roomData['host_id'],
        'black_id': guestId,
        'time_control_seconds': roomData['time_control_seconds'],
        'status': 'in_progress',
      }).select().single();

      // Update room to playing
      await client!.from('rooms').update({
        'guest_id': guestId,
        'status': 'playing',
        'match_id': matchRes['id'],
      }).eq('code', code.toUpperCase());

      return GameRoom.fromJson(roomData);
    } catch (e) {
      debugPrint('Error joining room: $e');
      return null;
    }
  }

  // ==========================================
  // REALTIME MOVE BROADCASTING
  // ==========================================

  RealtimeChannel? _activeMatchChannel;

  /// Subscribe to Realtime channel for an active match
  RealtimeChannel? subscribeToMatchChannel({
    required String matchId,
    required void Function(Map<String, dynamic> payload) onMoveReceived,
    required void Function(Map<String, dynamic> payload) onGameEnded,
  }) {
    if (!isOnlineSupported) return null;

    _activeMatchChannel?.unsubscribe();
    _activeMatchChannel = client!.channel('match:$matchId');

    _activeMatchChannel!
        .onBroadcast(
          event: 'chess_move',
          callback: (payload) => onMoveReceived(payload),
        )
        .onBroadcast(
          event: 'game_ended',
          callback: (payload) => onGameEnded(payload),
        )
        .subscribe();

    return _activeMatchChannel;
  }

  Future<void> broadcastMove({
    required String matchId,
    required Map<String, dynamic> moveData,
  }) async {
    if (_activeMatchChannel != null) {
      await _activeMatchChannel!.sendBroadcastMessage(
        event: 'chess_move',
        payload: moveData,
      );
    }

    if (isOnlineSupported) {
      try {
        await client!.from('matches').update({
          'last_move': moveData['san'],
          'fen': moveData['fen'],
          'white_time_left_ms': moveData['white_time_ms'],
          'black_time_left_ms': moveData['black_time_ms'],
        }).eq('id', matchId);
      } catch (e) {
        debugPrint('Error updating match record: $e');
      }
    }
  }

  Future<void> broadcastGameEnd({
    required String matchId,
    required String reason,
    required String? winnerId,
  }) async {
    if (_activeMatchChannel != null) {
      await _activeMatchChannel!.sendBroadcastMessage(
        event: 'game_ended',
        payload: {'reason': reason, 'winner_id': winnerId},
      );
    }

    if (isOnlineSupported) {
      try {
        await client!.from('matches').update({
          'status': reason,
          'winner_id': winnerId,
        }).eq('id', matchId);
      } catch (e) {
        debugPrint('Error updating game end: $e');
      }
    }
  }

  void unsubscribeFromMatch() {
    _activeMatchChannel?.unsubscribe();
    _activeMatchChannel = null;
  }
}
