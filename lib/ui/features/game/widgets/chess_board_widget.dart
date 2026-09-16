import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'package:chess_go/domain/models/chess_game_state.dart';
import 'package:chess_go/ui/core/theme/app_theme.dart';
import 'chess_piece_widget.dart';

/// Responsive 8x8 Chess Board with move highlights and coordinates
class ChessBoardWidget extends StatelessWidget {
  final ChessGameState state;
  final chess.Chess game;
  final ValueChanged<String> onSquareTapped;
  final bool isFlipped;

  const ChessBoardWidget({
    super.key,
    required this.state,
    required this.game,
    required this.onSquareTapped,
    this.isFlipped = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : constraints.maxWidth;
        final boardSize = max(0.0, min(availableWidth, availableHeight));

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF2A3447),
                width: 3,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(8, (rankIndex) {
                final row = isFlipped ? rankIndex : 7 - rankIndex;
                return Expanded(
                  child: Row(
                    children: List.generate(8, (fileIndex) {
                      final col = isFlipped ? 7 - fileIndex : fileIndex;
                      final isLightSquare = (row + col) % 2 != 0;
                      final squareName = _getSquareName(row, col);

                      final isSelected = state.selectedSquare == squareName;
                      final isLegalMove = state.validMoves.contains(squareName);
                      final isLastMoveOrigin =
                          state.lastMove?.from == squareName;
                      final isLastMoveDest = state.lastMove?.to == squareName;

                      // King in check highlight
                      final piece = game.get(squareName);
                      final isKingInCheck = state.isCheck &&
                          piece != null &&
                          piece.type == chess.PieceType.KING &&
                          piece.color ==
                              (state.turn == PlayerColor.white
                                  ? chess.Color.WHITE
                                  : chess.Color.BLACK);

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onSquareTapped(squareName),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            color: isLightSquare
                                ? AppColors.boardLight
                                : AppColors.boardDark,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Coordinate labels on board edge
                                _buildCoordinateLabels(
                                  row: row,
                                  col: col,
                                  isLightSquare: isLightSquare,
                                  isFlipped: isFlipped,
                                ),

                                // Last move background highlight
                                if (isLastMoveOrigin || isLastMoveDest)
                                  Container(
                                    color: AppColors.lastMoveSquare,
                                  ),

                                // Selected square highlight
                                if (isSelected)
                                  Container(
                                    color: AppColors.selectedSquare,
                                  ),

                                // King in check red danger glow
                                if (isKingInCheck)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.inCheckSquare,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),

                                // Piece rendering
                                if (piece != null)
                                  Center(
                                    child: LayoutBuilder(
                                      builder: (context, sqConstraints) {
                                        final sqSize = min(
                                          sqConstraints.maxWidth,
                                          sqConstraints.maxHeight,
                                        );
                                        return ChessPieceWidget(
                                          piece: _formatPieceChar(piece),
                                          size: sqSize * 0.88,
                                        );
                                      },
                                    ),
                                  ),

                                // Legal Move Indicator (Dot for move, Ring for capture)
                                if (isLegalMove)
                                  Center(
                                    child: LayoutBuilder(
                                      builder: (context, sqConstraints) {
                                        final sqSize = min(
                                          sqConstraints.maxWidth,
                                          sqConstraints.maxHeight,
                                        );
                                        return piece == null
                                            ? Container(
                                                width: sqSize * 0.28,
                                                height: sqSize * 0.28,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.legalMoveDot,
                                                  shape: BoxShape.circle,
                                                ),
                                              )
                                            : Container(
                                                width: sqSize * 0.86,
                                                height: sqSize * 0.86,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: AppColors
                                                        .legalCaptureRing,
                                                    width: 3.5,
                                                  ),
                                                ),
                                              );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoordinateLabels({
    required int row,
    required int col,
    required bool isLightSquare,
    required bool isFlipped,
  }) {
    final labelColor = isLightSquare
        ? AppColors.boardDark.withValues(alpha: 0.65)
        : AppColors.boardLight.withValues(alpha: 0.65);

    final showRank = isFlipped ? col == 7 : col == 0;
    final showFile = isFlipped ? row == 7 : row == 0;

    return Stack(
      children: [
        if (showRank)
          Positioned(
            top: 2,
            left: 3,
            child: Text(
              '${row + 1}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
          ),
        if (showFile)
          Positioned(
            bottom: 2,
            right: 3,
            child: Text(
              String.fromCharCode('a'.codeUnitAt(0) + col),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
          ),
      ],
    );
  }

  static String _getSquareName(int row, int col) {
    final file = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rank = row + 1;
    return '$file$rank';
  }

  static String _formatPieceChar(chess.Piece piece) {
    final char = piece.type.name.toLowerCase();
    return piece.color == chess.Color.WHITE
        ? char.toUpperCase()
        : char.toLowerCase();
  }
}
