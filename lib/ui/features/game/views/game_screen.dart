import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chess_go/domain/models/chess_game_state.dart';
import 'package:chess_go/ui/core/theme/app_theme.dart';
import 'package:chess_go/data/services/ad_service.dart';
import '../view_models/game_state_notifier.dart';
import '../widgets/chess_board_widget.dart';
import '../widgets/chess_clock_widget.dart';
import '../widgets/captured_pieces_widget.dart';
import '../widgets/game_over_dialog.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    // Listen for game over event to show GameOverDialog
    ref.listen<ChessGameState>(gameStateProvider, (previous, next) {
      if ((previous == null || !previous.isGameOver) && next.isGameOver) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => GameOverDialog(
            state: next,
            onPlayAgain: () {
              notifier.startNewGame(
                mode: next.gameMode,
                difficulty: next.aiDifficulty,
                playerColor: next.playerColor,
              );
            },
            onHome: () {
              context.go('/');
            },
          ),
        );
      }
    });

    final isPlayerBlack = state.playerColor == PlayerColor.black;
    final isWhiteTurn = state.turn == PlayerColor.white;

    // In pass-and-play, top is Black and bottom is White (or vice versa)
    final isTopPlayerWhite = isPlayerBlack;
    final topPlayerName = _getTopPlayerName(state);
    final bottomPlayerName = _getBottomPlayerName(state);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => _confirmExit(context),
        ),
        title: Text(
          _getModeTitle(state),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded,
                color: AppColors.textSecondary),
            onPressed: () => _showMoveHistory(context, state),
            tooltip: 'Move History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
            onPressed: () => _confirmRestart(context, notifier, state),
            tooltip: 'Restart Game',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    // TOP PLAYER (Opponent or Black)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ChessClockWidget(
                          playerName: topPlayerName,
                          timeRemainingMs: isTopPlayerWhite
                              ? state.whiteTimeMs
                              : state.blackTimeMs,
                          isActive: isTopPlayerWhite
                              ? isWhiteTurn
                              : !isWhiteTurn,
                          isWhite: isTopPlayerWhite,
                          isAi: state.gameMode == GameMode.offlineAi &&
                              state.playerColor !=
                                  (isTopPlayerWhite
                                      ? PlayerColor.white
                                      : PlayerColor.black),
                        ),
                        const SizedBox(height: 6),
                        CapturedPiecesWidget(
                          capturedPieces: isTopPlayerWhite
                              ? state.capturedBlackPieces
                              : state.capturedWhitePieces,
                          advantage: isTopPlayerWhite
                              ? state.materialDifference
                              : -state.materialDifference,
                        ),
                      ],
                    ),

                    // CHESS BOARD
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ChessBoardWidget(
                          state: state,
                          game: notifier.game,
                          onSquareTapped: notifier.onSquareTapped,
                          isFlipped: isPlayerBlack,
                        ),
                      ),
                    ),

                    // BOTTOM PLAYER (User or White)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CapturedPiecesWidget(
                          capturedPieces: isTopPlayerWhite
                              ? state.capturedWhitePieces
                              : state.capturedBlackPieces,
                          advantage: isTopPlayerWhite
                              ? -state.materialDifference
                              : state.materialDifference,
                        ),
                        const SizedBox(height: 6),
                        ChessClockWidget(
                          playerName: bottomPlayerName,
                          timeRemainingMs: isTopPlayerWhite
                              ? state.blackTimeMs
                              : state.whiteTimeMs,
                          isActive: isTopPlayerWhite
                              ? !isWhiteTurn
                              : isWhiteTurn,
                          isWhite: !isTopPlayerWhite,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),

            // In-Game Controls Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: Color(0xFF1E2638), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.flag_outlined,
                    label: 'Resign',
                    onPressed: () => _confirmResign(context, notifier),
                  ),
                  _ActionButton(
                    icon: Icons.handshake_outlined,
                    label: 'Draw',
                    onPressed: () => _confirmDraw(context, notifier),
                  ),
                  if (state.gameMode == GameMode.offlinePassAndPlay ||
                      state.gameMode == GameMode.offlineAi)
                    _ActionButton(
                      icon: Icons.replay_rounded,
                      label: 'New Game',
                      onPressed: () =>
                          _confirmRestart(context, notifier, state),
                    ),
                ],
              ),
            ),

            // AdMob Banner Slot (Ready for Play Store)
            const ChessBannerAdSlot(),
          ],
        ),
      ),
    );
  }

  String _getModeTitle(ChessGameState state) {
    switch (state.gameMode) {
      case GameMode.offlinePassAndPlay:
        return 'Pass & Play';
      case GameMode.offlineAi:
        return 'vs AI (${state.aiDifficulty.label})';
      case GameMode.onlineMatchmaking:
        return 'Online Ranked';
      case GameMode.onlinePrivateRoom:
        return 'Room: ${state.roomCode ?? "Friend"}';
    }
  }

  String _getTopPlayerName(ChessGameState state) {
    if (state.gameMode == GameMode.offlineAi) {
      return 'ChessBot (${state.aiDifficulty.label})';
    }
    if (state.gameMode == GameMode.offlinePassAndPlay) {
      return state.playerColor == PlayerColor.white ? 'Black' : 'White';
    }
    return 'Opponent';
  }

  String _getBottomPlayerName(ChessGameState state) {
    if (state.gameMode == GameMode.offlinePassAndPlay) {
      return state.playerColor == PlayerColor.white ? 'White' : 'Black';
    }
    return 'You';
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Leave Game?'),
        content: const Text(
          'Leaving now will abandon the current match.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/');
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _confirmResign(BuildContext context, GameStateNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Resign Game?'),
        content: const Text(
          'Are you sure you want to resign and forfeit this match?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.resign();
            },
            child: const Text('Resign'),
          ),
        ],
      ),
    );
  }

  void _confirmDraw(BuildContext context, GameStateNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Offer Draw?'),
        content: const Text(
          'Do you want to agree on a draw?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.offerDraw();
            },
            child: const Text('Agree Draw'),
          ),
        ],
      ),
    );
  }

  void _confirmRestart(
    BuildContext context,
    GameStateNotifier notifier,
    ChessGameState state,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Restart Match?'),
        content: const Text(
          'This will reset the chess board and clocks.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.startNewGame(
                mode: state.gameMode,
                difficulty: state.aiDifficulty,
                playerColor: state.playerColor,
              );
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _showMoveHistory(BuildContext context, ChessGameState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Move History (PGN)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF2E384D)),
              Expanded(
                child: state.moveHistory.isEmpty
                  ? const Center(
                      child: Text(
                        'No moves played yet.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: (state.moveHistory.length / 2).ceil(),
                      itemBuilder: (context, index) {
                        final moveNumber = index + 1;
                        final whiteMove = state.moveHistory[index * 2];
                        final blackMove = (index * 2 + 1 < state.moveHistory.length)
                            ? state.moveHistory[index * 2 + 1]
                            : null;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                child: Text(
                                  '$moveNumber.',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  whiteMove.san,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  blackMove?.san ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
