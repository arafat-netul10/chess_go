import 'package:flutter/material.dart';
import 'package:chess_go/ui/core/theme/app_theme.dart';
import 'chess_piece_widget.dart';

/// Compact bar showing captured pieces and material evaluation advantage
class CapturedPiecesWidget extends StatelessWidget {
  final List<String> capturedPieces;
  final int advantage; // Material advantage (+3, etc.)

  const CapturedPiecesWidget({
    super.key,
    required this.capturedPieces,
    required this.advantage,
  });

  @override
  Widget build(BuildContext context) {
    // Sort captured pieces by standard piece value: p < n = b < r < q
    final sorted = List<String>.from(capturedPieces);
    const order = {'p': 1, 'n': 2, 'b': 3, 'r': 4, 'q': 5};
    sorted.sort((a, b) =>
        (order[a.toLowerCase()] ?? 0).compareTo(order[b.toLowerCase()] ?? 0));

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 24,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 2.0),
                  child: ChessPieceWidget(
                    piece: sorted[index],
                    size: 22,
                  ),
                );
              },
            ),
          ),
        ),
        if (advantage > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+$advantage',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
      ],
    );
  }
}
