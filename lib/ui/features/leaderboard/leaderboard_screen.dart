import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chess_go/domain/models/user_profile.dart';
import 'package:chess_go/ui/core/theme/app_theme.dart';
import '../game/view_models/game_state_notifier.dart';

final leaderboardProvider =
    FutureProvider.autoDispose<List<UserProfile>>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);
  return await supabase.fetchLeaderboard(limit: 50);
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Global Leaderboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.gold),
            onPressed: () => ref.invalidate(leaderboardProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Unable to load leaderboard: $err',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
        data: (players) {
          return RefreshIndicator(
            color: AppColors.gold,
            backgroundColor: AppColors.surfaceCard,
            onRefresh: () async {
              ref.invalidate(leaderboardProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: players.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final player = players[index];
                final rank = index + 1;
                return _LeaderboardRow(rank: rank, player: player);
              },
            ),
          );
        },
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final UserProfile player;

  const _LeaderboardRow({required this.rank, required this.player});

  @override
  Widget build(BuildContext context) {
    Widget rankBadge;
    if (rank == 1) {
      rankBadge = const CircleAvatar(
        radius: 14,
        backgroundColor: Color(0xFFFFD700),
        child: Icon(Icons.emoji_events_rounded, color: Colors.black, size: 16),
      );
    } else if (rank == 2) {
      rankBadge = const CircleAvatar(
        radius: 14,
        backgroundColor: Color(0xFFC0C0C0),
        child: Icon(Icons.military_tech_rounded, color: Colors.black, size: 16),
      );
    } else if (rank == 3) {
      rankBadge = const CircleAvatar(
        radius: 14,
        backgroundColor: Color(0xFFCD7F32),
        child: Icon(Icons.military_tech_rounded, color: Colors.black, size: 16),
      );
    } else {
      rankBadge = SizedBox(
        width: 28,
        child: Text(
          '#$rank',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank <= 3
              ? AppColors.gold.withValues(alpha: 0.3)
              : const Color(0xFF262E3E),
          width: rank <= 3 ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          rankBadge,
          const SizedBox(width: 14),

          // Player Avatar Circle
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceElevated,
            child: Text(
              player.displayName.isNotEmpty
                  ? player.displayName[0].toUpperCase()
                  : 'P',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.wins}W • ${player.losses}L • ${player.draws}D  (${player.winRate.toStringAsFixed(0)}%)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Elo Rating Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF333E54)),
            ),
            child: Text(
              '${player.eloRating}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
