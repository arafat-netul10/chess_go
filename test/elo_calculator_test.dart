import 'package:flutter_test/flutter_test.dart';
import 'package:chess_go/domain/engine/elo_calculator.dart';

void main() {
  group('EloCalculator Tests', () {
    test('Equal ratings result in 0.5 expected score', () {
      final expected = EloCalculator.getExpectedScore(1200, 1200);
      expect(expected, closeTo(0.5, 0.001));
    });

    test('Higher rating expects win against lower rating', () {
      final expected = EloCalculator.getExpectedScore(1600, 1200);
      expect(expected, greaterThan(0.9));
    });

    test('Winning with equal rating increases by ~16 points (k=32)', () {
      final newRating = EloCalculator.calculateNewRating(
        currentRating: 1200,
        opponentRating: 1200,
        actualScore: 1.0,
      );
      expect(newRating, 1216);
    });

    test('Losing with equal rating decreases by 16 points (k=32)', () {
      final newRating = EloCalculator.calculateNewRating(
        currentRating: 1200,
        opponentRating: 1200,
        actualScore: 0.0,
      );
      expect(newRating, 1184);
    });

    test('Draw with equal rating does not change rating', () {
      final delta = EloCalculator.getRatingDelta(
        currentRating: 1200,
        opponentRating: 1200,
        actualScore: 0.5,
      );
      expect(delta, 0);
    });
  });
}
