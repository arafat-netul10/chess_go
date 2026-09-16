import 'dart:math';

/// FIDE-standard Elo Rating Calculator
class EloCalculator {
  static const int kFactor = 32;

  /// Calculates expected score for player A given player A and B's ratings
  static double getExpectedScore(int ratingA, int ratingB) {
    return 1.0 / (1.0 + pow(10.0, (ratingB - ratingA) / 400.0));
  }

  /// Calculates new rating for player A
  /// [actualScore]: 1.0 for win, 0.5 for draw, 0.0 for loss
  static int calculateNewRating({
    required int currentRating,
    required int opponentRating,
    required double actualScore,
    int k = kFactor,
  }) {
    final expectedScore = getExpectedScore(currentRating, opponentRating);
    final delta = (k * (actualScore - expectedScore)).round();
    return max(100, currentRating + delta);
  }

  /// Returns rating change delta
  static int getRatingDelta({
    required int currentRating,
    required int opponentRating,
    required double actualScore,
    int k = kFactor,
  }) {
    final newRating = calculateNewRating(
      currentRating: currentRating,
      opponentRating: opponentRating,
      actualScore: actualScore,
      k: k,
    );
    return newRating - currentRating;
  }
}
