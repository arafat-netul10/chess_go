import 'package:flutter/material.dart';
import 'package:chess_go/ui/core/theme/app_theme.dart';

/// Minimalist digital chess clock and player badge
class ChessClockWidget extends StatelessWidget {
  final String playerName;
  final int? rating;
  final int timeRemainingMs;
  final bool isActive;
  final bool isWhite;
  final bool isAi;

  const ChessClockWidget({
    super.key,
    required this.playerName,
    this.rating,
    required this.timeRemainingMs,
    required this.isActive,
    required this.isWhite,
    this.isAi = false,
  });

  String _formatTime(int ms) {
    if (ms <= 0) return '00:00';
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');

    if (minutes == 0 && seconds < 10) {
      final tenths = (ms % 1000) ~/ 100;
      return '$minStr:$secStr.$tenths';
    }
    return '$minStr:$secStr';
  }

  @override
  Widget build(BuildContext context) {
    final isLowTime = timeRemainingMs < 30000;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? (isLowTime
                ? AppColors.danger.withValues(alpha: 0.18)
                : AppColors.surfaceElevated)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? (isLowTime ? AppColors.danger : AppColors.gold)
              : const Color(0xFF262E3E),
          width: isActive ? 2.0 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: (isLowTime ? AppColors.danger : AppColors.gold)
                      .withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Player identity and badge
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isWhite ? Colors.white : const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isWhite
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        playerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isAi) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BOT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (rating != null)
                    Text(
                      '$rating Elo',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Digital Clock Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatTime(timeRemainingMs),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isLowTime ? AppColors.danger : AppColors.textPrimary,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
