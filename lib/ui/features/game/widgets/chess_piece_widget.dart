import 'package:flutter/material.dart';

/// Modern minimalist chess piece widget
/// Renders crisp, elegant pieces with soft shadows and tactile contrast.
class ChessPieceWidget extends StatelessWidget {
  final String piece; // 'p', 'n', 'b', 'r', 'q', 'k' (upper = White, lower = Black)
  final double size;

  const ChessPieceWidget({
    super.key,
    required this.piece,
    this.size = 42,
  });

  bool get isWhite => piece == piece.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final type = piece.toLowerCase();

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.85, size * 0.85),
          painter: _PiecePainter(
            type: type,
            isWhite: isWhite,
          ),
        ),
      ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  final String type;
  final bool isWhite;

  _PiecePainter({required this.type, required this.isWhite});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fill paint: Pearl White vs Deep Obsidian
    final fillPaint = Paint()
      ..color = isWhite ? const Color(0xFFF8FAFC) : const Color(0xFF181B22)
      ..style = PaintingStyle.fill;

    // Outline paint for crisp definition on any background
    final strokePaint = Paint()
      ..color = isWhite ? const Color(0xFF475569) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.048
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Subtle drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = _getPiecePath(type, w, h);

    // Draw shadow first
    canvas.save();
    canvas.translate(0, h * 0.04);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Draw piece body
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // Optional interior accent line for Knights and King cross
    if (type == 'k') {
      _drawKingCross(canvas, w, h, strokePaint);
    } else if (type == 'n') {
      _drawKnightEye(canvas, w, h, strokePaint);
    } else if (type == 'b') {
      _drawBishopSlit(canvas, w, h, strokePaint);
    }
  }

  Path _getPiecePath(String type, double w, double h) {
    final path = Path();

    switch (type) {
      case 'p': // Pawn
        // Base
        path.moveTo(w * 0.25, h * 0.88);
        path.lineTo(w * 0.75, h * 0.88);
        path.quadraticBezierTo(w * 0.72, h * 0.82, w * 0.65, h * 0.76);
        // Body taper
        path.quadraticBezierTo(w * 0.60, h * 0.58, w * 0.58, h * 0.50);
        // Collar
        path.lineTo(w * 0.64, h * 0.48);
        path.lineTo(w * 0.36, h * 0.48);
        path.lineTo(w * 0.42, h * 0.50);
        // Left body taper
        path.quadraticBezierTo(w * 0.40, h * 0.58, w * 0.35, h * 0.76);
        path.quadraticBezierTo(w * 0.28, h * 0.82, w * 0.25, h * 0.88);
        path.close();

        // Head (circle added to path)
        path.addOval(Rect.fromCircle(
          center: Offset(w * 0.50, h * 0.32),
          radius: w * 0.18,
        ));
        break;

      case 'r': // Rook
        // Base
        path.moveTo(w * 0.20, h * 0.90);
        path.lineTo(w * 0.80, h * 0.90);
        path.lineTo(w * 0.76, h * 0.80);
        // Body
        path.lineTo(w * 0.72, h * 0.42);
        // Battlements / Crenellations
        path.lineTo(w * 0.82, h * 0.38);
        path.lineTo(w * 0.82, h * 0.22);
        path.lineTo(w * 0.69, h * 0.22);
        path.lineTo(w * 0.69, h * 0.30);
        path.lineTo(w * 0.57, h * 0.30);
        path.lineTo(w * 0.57, h * 0.22);
        path.lineTo(w * 0.43, h * 0.22);
        path.lineTo(w * 0.43, h * 0.30);
        path.lineTo(w * 0.31, h * 0.30);
        path.lineTo(w * 0.31, h * 0.22);
        path.lineTo(w * 0.18, h * 0.22);
        path.lineTo(w * 0.18, h * 0.38);
        // Left body
        path.lineTo(w * 0.28, h * 0.42);
        path.lineTo(w * 0.24, h * 0.80);
        path.close();
        break;

      case 'n': // Knight
        path.moveTo(w * 0.22, h * 0.90);
        path.lineTo(w * 0.78, h * 0.90);
        path.lineTo(w * 0.75, h * 0.80);
        // Back of head & mane
        path.quadraticBezierTo(w * 0.75, h * 0.55, w * 0.70, h * 0.38);
        path.lineTo(w * 0.68, h * 0.20); // Ear peak
        path.lineTo(w * 0.58, h * 0.26);
        // Forehead and snout
        path.lineTo(w * 0.40, h * 0.30);
        path.quadraticBezierTo(w * 0.20, h * 0.45, w * 0.22, h * 0.55);
        // Mouth & chin
        path.lineTo(w * 0.35, h * 0.54);
        path.quadraticBezierTo(w * 0.42, h * 0.64, w * 0.40, h * 0.74);
        path.lineTo(w * 0.25, h * 0.80);
        path.close();
        break;

      case 'b': // Bishop
        // Base
        path.moveTo(w * 0.24, h * 0.90);
        path.lineTo(w * 0.76, h * 0.90);
        path.lineTo(w * 0.70, h * 0.80);
        path.quadraticBezierTo(w * 0.65, h * 0.68, w * 0.62, h * 0.55);
        // Mitre head
        path.quadraticBezierTo(w * 0.72, h * 0.42, w * 0.52, h * 0.20);
        // Finial bead
        path.lineTo(w * 0.50, h * 0.14);
        path.lineTo(w * 0.48, h * 0.20);
        // Left head & body
        path.quadraticBezierTo(w * 0.28, h * 0.42, w * 0.38, h * 0.55);
        path.quadraticBezierTo(w * 0.35, h * 0.68, w * 0.30, h * 0.80);
        path.close();
        break;

      case 'q': // Queen
        // Base
        path.moveTo(w * 0.20, h * 0.90);
        path.lineTo(w * 0.80, h * 0.90);
        path.lineTo(w * 0.75, h * 0.80);
        // Body flare
        path.lineTo(w * 0.70, h * 0.50);
        // Crown points
        path.lineTo(w * 0.84, h * 0.32);
        path.lineTo(w * 0.65, h * 0.38);
        path.lineTo(w * 0.50, h * 0.24); // Center tip
        path.lineTo(w * 0.35, h * 0.38);
        path.lineTo(w * 0.16, h * 0.32);
        // Left body
        path.lineTo(w * 0.30, h * 0.50);
        path.lineTo(w * 0.25, h * 0.80);
        path.close();
        break;

      case 'k': // King
        // Base
        path.moveTo(w * 0.20, h * 0.90);
        path.lineTo(w * 0.80, h * 0.90);
        path.lineTo(w * 0.74, h * 0.80);
        path.quadraticBezierTo(w * 0.70, h * 0.60, w * 0.68, h * 0.48);
        // Crown arches
        path.quadraticBezierTo(w * 0.75, h * 0.36, w * 0.50, h * 0.32);
        path.quadraticBezierTo(w * 0.25, h * 0.36, w * 0.32, h * 0.48);
        path.quadraticBezierTo(w * 0.30, h * 0.60, w * 0.26, h * 0.80);
        path.close();
        break;
    }

    return path;
  }

  void _drawKingCross(Canvas canvas, double w, double h, Paint stroke) {
    final crossPaint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;

    // Vertical bar
    canvas.drawLine(
      Offset(w * 0.50, h * 0.16),
      Offset(w * 0.50, h * 0.32),
      crossPaint,
    );
    // Horizontal bar
    canvas.drawLine(
      Offset(w * 0.42, h * 0.22),
      Offset(w * 0.58, h * 0.22),
      crossPaint,
    );
  }

  void _drawKnightEye(Canvas canvas, double w, double h, Paint stroke) {
    final eyePaint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.45, h * 0.40), w * 0.04, eyePaint);
  }

  void _drawBishopSlit(Canvas canvas, double w, double h, Paint stroke) {
    final slitPaint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.44, h * 0.34),
      Offset(w * 0.56, h * 0.46),
      slitPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PiecePainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.isWhite != isWhite;
  }
}
