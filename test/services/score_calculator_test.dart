import 'package:flutter_test/flutter_test.dart';
import 'package:wellx_pets_sdk/src/models/health_models.dart';
import 'package:wellx_pets_sdk/src/models/pet.dart';
import 'package:wellx_pets_sdk/src/services/score_calculator.dart';

void main() {
  group('ScoreCalculator', () {
    group('calculate with biomarkers only', () {
      test('returns 50 when no data is provided', () {
        final result = ScoreCalculator.calculate(biomarkers: []);
        expect(result.overall, 50);
        expect(result.pillars, hasLength(5));
        for (final p in result.pillars) {
          expect(p.score, 50);
        }
      });

      test('returns high score for all-normal biomarkers', () {
        final biomarkers = [
          const Biomarker(
            id: 'b1',
            name: 'Creatinine',
            value: 1.0,
            referenceMin: 0.5,
            referenceMax: 1.5,
            pillar: 'organ',
          ),
          const Biomarker(
            id: 'b2',
            name: 'CRP',
            value: 0.5,
            referenceMin: 0.0,
            referenceMax: 1.0,
            pillar: 'inflammation',
          ),
          const Biomarker(
            id: 'b3',
            name: 'Glucose',
            value: 90.0,
            referenceMin: 70.0,
            referenceMax: 110.0,
            pillar: 'metabolic',
          ),
          const Biomarker(
            id: 'b4',
            name: 'BCS',
            value: 5.0,
            referenceMin: 4.0,
            referenceMax: 6.0,
            pillar: 'body',
          ),
        ];

        final result = ScoreCalculator.calculate(biomarkers: biomarkers);
        // All normal biomarkers → overall should be well above 50
        expect(result.overall, greaterThan(60));
      });

      test('returns low score for out-of-range biomarkers', () {
        final biomarkers = [
          const Biomarker(
            id: 'b1',
            name: 'Creatinine',
            value: 5.0, // severely high
            referenceMin: 0.5,
            referenceMax: 1.5,
            pillar: 'organ',
          ),
          const Biomarker(
            id: 'b2',
            name: 'CRP',
            value: 10.0, // severely high
            referenceMin: 0.0,
            referenceMax: 1.0,
            pillar: 'inflammation',
          ),
        ];

        final result = ScoreCalculator.calculate(biomarkers: biomarkers);
        expect(result.overall, lessThan(50));
      });
    });

    group('calculate with wellness survey', () {
      test('wellness data influences pillar scores', () {
        final wellness = WellnessSurveyResult(
          petId: 'p1',
          date: '2024-01-01',
          answers: {
            'APPETITE': 0, // 100
            'COAT': 0, // 100
            'ACTIVITY': 0, // 100
            'DENTAL': 0, // 100
          },
        );

        final result = ScoreCalculator.calculate(
          biomarkers: [],
          wellnessResult: wellness,
        );

        // With excellent wellness data, should be above default 50
        expect(result.overall, greaterThan(50));
      });
    });

    group('calculate with walk sessions', () {
      test('walk sessions influence Body & Activity pillar', () {
        final now = DateTime.now();
        final walks = List.generate(
          5,
          (i) => WalkSession(
            id: 'w-$i',
            date: now.subtract(Duration(days: i)).toIso8601String(),
            steps: 5000,
            distanceKm: 3.0,
            durationMin: 45,
          ),
        );

        final result = ScoreCalculator.calculate(
          biomarkers: [],
          walkSessions: walks,
        );

        // Body & Activity pillar should benefit from walks
        final bodyPillar =
            result.pillars.firstWhere((p) => p.name == 'Body & Activity');
        expect(bodyPillar.score, greaterThan(50));
      });

      test('breed-adjusted scoring gives different targets', () {
        final now = DateTime.now();
        final walks = List.generate(
          5,
          (i) => WalkSession(
            id: 'w-$i',
            date: now.subtract(Duration(days: i)).toIso8601String(),
            steps: 3000,
            distanceKm: 1.5,
            durationMin: 20,
          ),
        );

        // Small dog — 20 min / 1.5 km are ideal
        const smallDog = Pet(id: '1', name: 'Tiny', breed: 'Chihuahua', weight: 5.0);
        final smallResult = ScoreCalculator.calculate(
          biomarkers: [],
          walkSessions: walks,
          pet: smallDog,
        );

        // Large dog — 20 min / 1.5 km are under-target
        const largeDog = Pet(id: '2', name: 'Rex', breed: 'Lab', weight: 35.0);
        final largeResult = ScoreCalculator.calculate(
          biomarkers: [],
          walkSessions: walks,
          pet: largeDog,
        );

        final smallBody =
            smallResult.pillars.firstWhere((p) => p.name == 'Body & Activity');
        final largeBody =
            largeResult.pillars.firstWhere((p) => p.name == 'Body & Activity');

        // Small dog should score higher with the same walks
        expect(smallBody.score, greaterThanOrEqualTo(largeBody.score));
      });
    });

    group('pillar weights sum to 1.0', () {
      test('all pillar weights add up to 1.0', () {
        // We can verify this indirectly by checking overall is a proper weighted average
        final result = ScoreCalculator.calculate(biomarkers: []);
        // With all pillars at 50, overall should be 50
        expect(result.overall, 50);
      });
    });
  });

  group('HealthScore', () {
    test('weakestPillar returns lowest scoring pillar', () {
      const score = HealthScore(
        overall: 70,
        updatedDate: '2024-01-01',
        pillars: [
          PillarScore(name: 'A', score: 80, icon: 'x', color: 'red'),
          PillarScore(name: 'B', score: 40, icon: 'x', color: 'blue'),
          PillarScore(name: 'C', score: 90, icon: 'x', color: 'green'),
        ],
      );

      expect(score.weakestPillar!.name, 'B');
      expect(score.weakestPillar!.score, 40);
    });

    test('weakestPillar returns null for empty pillars', () {
      const score = HealthScore(
        overall: 0,
        updatedDate: '2024-01-01',
        pillars: [],
      );
      expect(score.weakestPillar, isNull);
    });

    test('pillarsNeedingAttention filters by threshold', () {
      const score = HealthScore(
        overall: 60,
        updatedDate: '2024-01-01',
        pillars: [
          PillarScore(name: 'A', score: 80, icon: 'x', color: 'red'),
          PillarScore(name: 'B', score: 40, icon: 'x', color: 'blue'),
          PillarScore(name: 'C', score: 55, icon: 'x', color: 'green'),
        ],
      );

      final needing = score.pillarsNeedingAttention(threshold: 60);
      expect(needing, hasLength(2));
      expect(needing[0].name, 'B'); // sorted weakest first
      expect(needing[1].name, 'C');
    });
  });

  group('PillarScore', () {
    test('percent returns score / 100', () {
      const pillar =
          PillarScore(name: 'Test', score: 75, icon: 'x', color: 'red');
      expect(pillar.percent, 0.75);
    });

    test('id returns name', () {
      const pillar =
          PillarScore(name: 'Organ Strength', score: 80, icon: 'x', color: 'red');
      expect(pillar.id, 'Organ Strength');
    });
  });
}
