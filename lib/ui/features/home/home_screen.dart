import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chess_go/domain/models/chess_game_state.dart';
import 'package:chess_go/ui/core/theme/app_theme.dart';
import '../game/view_models/game_state_notifier.dart';
import '../game/widgets/chess_piece_widget.dart';
import '../auth/auth_modal.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  AiDifficulty _selectedAiDifficulty = AiDifficulty.medium;
  PlayerColor _selectedPlayerColor = PlayerColor.white;
  final int _selectedTimeControl = 300; // 5 mins

  void _startPassAndPlay() {
    final notifier = ref.read(gameStateProvider.notifier);
    notifier.startNewGame(
      mode: GameMode.offlinePassAndPlay,
      timeControlSeconds: _selectedTimeControl,
      playerColor: PlayerColor.white,
    );
    context.go('/game');
  }

  void _startAiGame() {
    final notifier = ref.read(gameStateProvider.notifier);
    PlayerColor color = _selectedPlayerColor;
    notifier.startNewGame(
      mode: GameMode.offlineAi,
      difficulty: _selectedAiDifficulty,
      timeControlSeconds: _selectedTimeControl,
      playerColor: color,
    );
    context.go('/game');
  }

  @override
  Widget build(BuildContext context) {
    final supabase = ref.watch(supabaseServiceProvider);
    final user = supabase.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Brand + Auth/Profile Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.3)),
                        ),
                        child: const ChessPieceWidget(piece: 'K', size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ChessGo',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Play Offline & Online',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Auth / Profile Button
                  InkWell(
                    onTap: () => AuthModal.show(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: user != null
                              ? AppColors.gold
                              : const Color(0xFF2E384D),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            user != null
                                ? Icons.account_circle_rounded
                                : Icons.login_rounded,
                            size: 18,
                            color: user != null
                                ? AppColors.gold
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user != null
                                ? (user.email?.split('@').first ?? 'Account')
                                : 'Sign In',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: user != null
                                  ? AppColors.gold
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Hero: Online Multiplayer Card
              _buildModeCard(
                context: context,
                title: 'Online Multiplayer',
                subtitle: 'Matchmaking queue & private rooms with friends',
                icon: Icons.public_rounded,
                accentColor: AppColors.gold,
                badgeText: 'ONLINE',
                onTap: () => context.go('/lobby'),
              ),
              const SizedBox(height: 16),

              // Mode 2: Play vs AI Bot
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF262E3E)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.smart_toy_rounded,
                                color: AppColors.goldLight, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Play vs AI Bot',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'OFFLINE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Challenge pure Dart chess engine bots with custom difficulty.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Difficulty selector
                    Row(
                      children: [
                        _buildDifficultyChip(AiDifficulty.easy),
                        const SizedBox(width: 8),
                        _buildDifficultyChip(AiDifficulty.medium),
                        const SizedBox(width: 8),
                        _buildDifficultyChip(AiDifficulty.hard),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Color and Start button
                    Row(
                      children: [
                        // Color choices
                        _buildColorSelector(
                            PlayerColor.white, 'White', Icons.circle),
                        const SizedBox(width: 8),
                        _buildColorSelector(
                            PlayerColor.black, 'Black', Icons.circle_outlined),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _startAiGame,
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text('Start Game'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mode 3: Pass & Play
              _buildModeCard(
                context: context,
                title: 'Pass & Play',
                subtitle: 'Two players on this device (offline friendly)',
                icon: Icons.swap_horizontal_circle_rounded,
                accentColor: const Color(0xFF60A5FA),
                badgeText: 'LOCAL',
                onTap: _startPassAndPlay,
              ),
              const SizedBox(height: 16),

              // Global Leaderboard Card
              _buildModeCard(
                context: context,
                title: 'Leaderboard',
                subtitle: 'View top Grandmasters and global Elo rankings',
                icon: Icons.emoji_events_rounded,
                accentColor: AppColors.gold,
                badgeText: 'TOP 50',
                onTap: () => context.go('/leaderboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF262E3E)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(AiDifficulty difficulty) {
    final isSelected = _selectedAiDifficulty == difficulty;
    return Expanded(
      child: ChoiceChip(
        label: Center(
          child: Text(
            difficulty.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.gold : AppColors.textSecondary,
            ),
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.gold.withValues(alpha: 0.2),
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? AppColors.gold : const Color(0xFF2E384D),
          ),
        ),
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedAiDifficulty = difficulty),
      ),
    );
  }

  Widget _buildColorSelector(PlayerColor color, String label, IconData icon) {
    final isSelected = _selectedPlayerColor == color;
    return InkWell(
      onTap: () => setState(() => _selectedPlayerColor = color),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.gold : const Color(0xFF2E384D),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: color == PlayerColor.white ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
