import 'package:flutter/material.dart';
import 'package:chess_go/domain/models/chess_game_state.dart';
import 'package:chess_go/ui/core/theme/app_theme.dart';
import 'package:chess_go/data/services/ad_service.dart';

/// Modal dialog displayed when game reaches terminal state
class GameOverDialog extends StatelessWidget {
  final ChessGameState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  const GameOverDialog({
    super.key,
    required this.state,
    required this.onPlayAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    // Show AdMob interstitial hook if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.showPostMatchInterstitial(context);
    });

    String title;
    String subtitle;
    IconData icon;
    Color iconColor;

    switch (state.status) {
      case GameStatus.checkmate:
        final winnerStr = state.winner == PlayerColor.white ? 'White' : 'Black';
        title = 'Checkmate!';
        subtitle = '$winnerStr wins by checkmate';
        icon = Icons.emoji_events_rounded;
        iconColor = AppColors.gold;
        break;
      case GameStatus.resigned:
        final winnerStr = state.winner == PlayerColor.white ? 'White' : 'Black';
        title = 'Resignation';
        subtitle = '$winnerStr wins by resignation';
        icon = Icons.flag_rounded;
        iconColor = AppColors.warning;
        break;
      case GameStatus.timeout:
        final winnerStr = state.winner == PlayerColor.white ? 'White' : 'Black';
        title = 'Time Out';
        subtitle = '$winnerStr wins on time';
        icon = Icons.timer_off_rounded;
        iconColor = AppColors.danger;
        break;
      case GameStatus.stalemate:
        title = 'Stalemate';
        subtitle = 'Game drawn due to stalemate';
        icon = Icons.handshake_rounded;
        iconColor = AppColors.textSecondary;
        break;
      case GameStatus.draw:
        title = 'Draw';
        subtitle = 'Game drawn by agreement or rule';
        icon = Icons.handshake_rounded;
        iconColor = AppColors.textSecondary;
        break;
      default:
        title = 'Game Over';
        subtitle = 'Match concluded';
        icon = Icons.sports_score_rounded;
        iconColor = AppColors.gold;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2E384D), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onHome();
                    },
                    child: const Text('Menu'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onPlayAgain();
                    },
                    child: const Text('Play Again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
