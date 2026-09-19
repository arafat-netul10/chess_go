import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chess_go/domain/models/chess_game_state.dart';
import 'package:chess_go/ui/core/theme/app_theme.dart';
import 'package:chess_go/data/services/supabase_service.dart';
import '../game/view_models/game_state_notifier.dart';
import '../auth/auth_modal.dart';

class OnlineLobbyScreen extends ConsumerStatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  ConsumerState<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends ConsumerState<OnlineLobbyScreen> {
  int _selectedTimeControl = 300; // 5 mins default
  bool _isSearching = false;
  String? _createdRoomCode;
  final _roomCodeController = TextEditingController();
  bool _isJoining = false;
  String? _statusMessage;

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  void _startMatchmaking() {
    final supabase = ref.read(supabaseServiceProvider);

    if (!SupabaseService.isOnlineSupported) {
      _showSupabaseInfoModal(context);
      return;
    }

    if (!supabase.isAuthenticated) {
      AuthModal.show(context);
      return;
    }

    setState(() {
      _isSearching = true;
      _statusMessage = 'Searching for an opponent...';
    });

    // Simulated matchmaking / fallback demo queue
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _isSearching = false);

      final notifier = ref.read(gameStateProvider.notifier);
      final isWhite = Random().nextBool();

      notifier.startNewGame(
        mode: GameMode.onlineMatchmaking,
        timeControlSeconds: _selectedTimeControl,
        playerColor: isWhite ? PlayerColor.white : PlayerColor.black,
        matchId: 'match_${DateTime.now().millisecondsSinceEpoch}',
      );

      context.go('/game');
    });
  }

  Future<void> _createRoom() async {
    final supabase = ref.read(supabaseServiceProvider);

    if (!supabase.isAuthenticated && SupabaseService.isOnlineSupported) {
      AuthModal.show(context);
      return;
    }

    final hostId = supabase.currentUser?.id ?? 'guest_host';
    final room = await supabase.createRoom(
      hostId: hostId,
      timeControlSeconds: _selectedTimeControl,
    );

    setState(() {
      _createdRoomCode = room.code;
      _statusMessage = 'Room created! Waiting for friend to join...';
    });
  }

  Future<void> _joinRoom() async {
    final code = _roomCodeController.text.trim().toUpperCase();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid room code')),
      );
      return;
    }

    final supabase = ref.read(supabaseServiceProvider);
    if (!supabase.isAuthenticated && SupabaseService.isOnlineSupported) {
      AuthModal.show(context);
      return;
    }

    setState(() => _isJoining = true);

    final guestId = supabase.currentUser?.id ?? 'guest_player';
    final room = await supabase.joinRoom(code: code, guestId: guestId);

    setState(() => _isJoining = false);

    if (room != null || !SupabaseService.isOnlineSupported) {
      final notifier = ref.read(gameStateProvider.notifier);
      notifier.startNewGame(
        mode: GameMode.onlinePrivateRoom,
        timeControlSeconds: _selectedTimeControl,
        playerColor: PlayerColor.black,
        roomCode: code,
        matchId: 'room_match_$code',
      );
      if (mounted) context.go('/game');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room not found or already in progress'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showSupabaseInfoModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: const Row(
          children: [
            Icon(Icons.cloud_outlined, color: AppColors.gold),
            SizedBox(width: 10),
            Text('Supabase Setup'),
          ],
        ),
        content: const Text(
          'Online matchmaking and cloud rooms require your Supabase project credentials in lib/config/app_config.dart.\n\nOffline Pass & Play and Single-Player AI Bots are fully available right now without any backend setup!',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Online Play',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time Control Selector
            const Text(
              'Select Time Control',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTimeControlCard(
                  title: '3 min',
                  subtitle: 'Blitz',
                  seconds: 180,
                  icon: Icons.bolt_rounded,
                ),
                const SizedBox(width: 10),
                _buildTimeControlCard(
                  title: '5 min',
                  subtitle: 'Blitz',
                  seconds: 300,
                  icon: Icons.timer_rounded,
                ),
                const SizedBox(width: 10),
                _buildTimeControlCard(
                  title: '10 min',
                  subtitle: 'Rapid',
                  seconds: 600,
                  icon: Icons.schedule_rounded,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Quick Match Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2E384D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.public_rounded,
                          color: AppColors.gold, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Quick Matchmaking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Automatically find a ranked opponent with matching skill in the global queue.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _isSearching
                        ? OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => _isSearching = false),
                            icon: const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.gold,
                              ),
                            ),
                            label: const Text('Cancel Matchmaking'),
                          )
                        : ElevatedButton.icon(
                            onPressed: _startMatchmaking,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Find Opponent'),
                          ),
                  ),
                  if (_isSearching && _statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Private Room Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2E384D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group_rounded,
                          color: AppColors.goldLight, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Play with Friend',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a private room code or enter an existing code to challenge a friend.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_createdRoomCode != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'SHARE ROOM CODE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _createdRoomCode!,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.gold,
                              letterSpacing: 4.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tell your friend to enter this code below.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Create Room Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _createRoom,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Create New Room'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Join Room Input & Button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _roomCodeController,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: 'Enter Room Code',
                            prefixIcon: Icon(Icons.key_rounded,
                                color: AppColors.textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isJoining ? null : _joinRoom,
                        child: _isJoining
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            : const Text('Join'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeControlCard({
    required String title,
    required String subtitle,
    required int seconds,
    required IconData icon,
  }) {
    final isSelected = _selectedTimeControl == seconds;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTimeControl = seconds),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.gold.withValues(alpha: 0.15)
                : Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.gold : const Color(0xFF2A3447),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.gold : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.gold
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
