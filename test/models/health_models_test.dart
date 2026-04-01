import 'package:flutter_test/flutter_test.dart';
import 'package:wellx_pets_sdk/src/models/health_models.dart';

void main() {
  group('TrendPoint', () {
    test('fromJson and toJson round-trip', () {
      final tp = TrendPoint.fromJson({'date': '2024-01-01', 'value': 5.5});
      expect(tp.date, '2024-01-01');
      expect(tp.value, 5.5);
      expect(tp.toJson(), {'date': '2024-01-01', 'value': 5.5});
    });
  });

  group('Biomarker', () {
    test('fromJson parses all fields including nested trend', () {
      final b = Biomarker.fromJson({
        'id': 'b-1',
        'name': 'Creatinine',
        'pet_id': 'pet-1',
        'value': 1.2,
        'unit': 'mg/dL',
        'reference_min': 0.5,
        'reference_max': 1.5,
        'pillar': 'organ',
        'date': '2024-01-01',
        'trend': [
          {'date': '2023-12-01', 'value': 1.0},
          {'date': '2024-01-01', 'value': 1.2},
        ],
        'source': 'lab',
        'created_at': '2024-01-01T00:00:00Z',
      });

      expect(b.id, 'b-1');
      expect(b.name, 'Creatinine');
      expect(b.value, 1.2);
      expect(b.referenceMin, 0.5);
      expect(b.referenceMax, 1.5);
      expect(b.trend, hasLength(2));
      expect(b.trend![0].value, 1.0);
    });

    group('status', () {
      test('returns normal when value is within range', () {
        const b = Biomarker(
          id: '1',
          name: 'Test',
          value: 5.0,
          referenceMin: 3.0,
          referenceMax: 7.0,
        );
        expect(b.status, 'normal');
      });

      test('returns low when value is below range', () {
        const b = Biomarker(
          id: '1',
          name: 'Test',
          value: 2.0,
          referenceMin: 3.0,
          referenceMax: 7.0,
        );
        expect(b.status, 'low');
      });

      test('returns high when value is above range', () {
        const b = Biomarker(
          id: '1',
          name: 'Test',
          value: 8.0,
          referenceMin: 3.0,
          referenceMax: 7.0,
        );
        expect(b.status, 'high');
      });

      test('returns unknown when value is null', () {
        const b = Biomarker(
          id: '1',
          name: 'Test',
          referenceMin: 3.0,
          referenceMax: 7.0,
        );
        expect(b.status, 'unknown');
      });

      test('returns unknown when range is null', () {
        const b = Biomarker(id: '1', name: 'Test', value: 5.0);
        expect(b.status, 'unknown');
      });
    });
  });

  group('Medication', () {
    test('supplyPercentage calculates correctly', () {
      const med = Medication(
        id: '1',
        name: 'Apoquel',
        supplyTotal: 30,
        supplyRemaining: 15,
      );
      expect(med.supplyPercentage, 0.5);
    });

    test('supplyPercentage returns 0 when total is 0', () {
      const med = Medication(
        id: '1',
        name: 'Test',
        supplyTotal: 0,
        supplyRemaining: 5,
      );
      expect(med.supplyPercentage, 0);
    });

    test('supplyPercentage returns 0 when total is null', () {
      const med = Medication(id: '1', name: 'Test');
      expect(med.supplyPercentage, 0);
    });

    group('urgencyColor', () {
      test('returns red for high urgency', () {
        const med = Medication(id: '1', name: 'Test', urgency: 'High');
        expect(med.urgencyColor, 'red');
      });

      test('returns orange for medium urgency', () {
        const med = Medication(id: '1', name: 'Test', urgency: 'Medium');
        expect(med.urgencyColor, 'orange');
      });

      test('returns green for low urgency', () {
        const med = Medication(id: '1', name: 'Test', urgency: 'Low');
        expect(med.urgencyColor, 'green');
      });

      test('defaults to green when urgency is null', () {
        const med = Medication(id: '1', name: 'Test');
        expect(med.urgencyColor, 'green');
      });
    });
  });

  group('WalkSession', () {
    test('fromJson and toJson round-trip', () {
      final json = {
        'id': 'w-1',
        'date': '2024-03-15',
        'pet_id': 'pet-1',
        'steps': 5000,
        'distance_km': 3.2,
        'duration_min': 45,
        'avg_cadence': 110,
      };
      final ws = WalkSession.fromJson(json);
      expect(ws.steps, 5000);
      expect(ws.distanceKm, 3.2);
      expect(ws.durationMin, 45);

      final out = ws.toJson();
      expect(out['steps'], 5000);
      expect(out['distance_km'], 3.2);
    });

    group('durationDisplay', () {
      test('returns minutes for durations under 60', () {
        const ws = WalkSession(id: '1', date: '2024-01-01', durationMin: 45);
        expect(ws.durationDisplay, '45 min');
      });

      test('returns hours and minutes for durations over 60', () {
        const ws = WalkSession(id: '1', date: '2024-01-01', durationMin: 90);
        expect(ws.durationDisplay, '1h 30m');
      });

      test('returns N/A when durationMin is null', () {
        const ws = WalkSession(id: '1', date: '2024-01-01');
        expect(ws.durationDisplay, 'N/A');
      });
    });
  });

  group('InsuranceClaim', () {
    group('statusColor', () {
      test('returns green for approved', () {
        const claim = InsuranceClaim(
          id: '1',
          title: 'Test',
          date: '2024-01-01',
          status: 'approved',
        );
        expect(claim.statusColor, 'green');
      });

      test('returns red for denied', () {
        const claim = InsuranceClaim(
          id: '1',
          title: 'Test',
          date: '2024-01-01',
          status: 'denied',
        );
        expect(claim.statusColor, 'red');
      });

      test('returns red for rejected', () {
        const claim = InsuranceClaim(
          id: '1',
          title: 'Test',
          date: '2024-01-01',
          status: 'rejected',
        );
        expect(claim.statusColor, 'red');
      });

      test('returns orange for pending', () {
        const claim = InsuranceClaim(
          id: '1',
          title: 'Test',
          date: '2024-01-01',
          status: 'pending',
        );
        expect(claim.statusColor, 'orange');
      });

      test('returns gray for unknown status', () {
        const claim = InsuranceClaim(
          id: '1',
          title: 'Test',
          date: '2024-01-01',
          status: 'processing',
        );
        expect(claim.statusColor, 'gray');
      });
    });
  });

  group('HealthAlert', () {
    test('isActive returns true for active status', () {
      const alert = HealthAlert(id: '1', status: 'active');
      expect(alert.isActive, true);
    });

    test('isActive returns false for resolved status', () {
      const alert = HealthAlert(id: '1', status: 'resolved');
      expect(alert.isActive, false);
    });

    test('isActive defaults to true when status is null', () {
      const alert = HealthAlert(id: '1');
      expect(alert.isActive, true);
    });

    group('severityColor', () {
      test('returns red for critical', () {
        const alert = HealthAlert(id: '1', alertType: 'critical');
        expect(alert.severityColor, 'red');
      });

      test('returns orange for warning', () {
        const alert = HealthAlert(id: '1', alertType: 'warning');
        expect(alert.severityColor, 'orange');
      });

      test('returns blue for info/default', () {
        const alert = HealthAlert(id: '1', alertType: 'info');
        expect(alert.severityColor, 'blue');
      });
    });
  });

  group('SymptomLog', () {
    test('symptomName prefers codedTerm over rawText', () {
      const log = SymptomLog(
        id: '1',
        eventType: 'symptom',
        source: 'user',
        status: 'active',
        eventDate: '2024-01-01',
        codedTerm: 'Vomiting',
        rawText: 'my dog threw up',
      );
      expect(log.symptomName, 'Vomiting');
    });

    test('symptomName falls back to rawText', () {
      const log = SymptomLog(
        id: '1',
        eventType: 'symptom',
        source: 'user',
        status: 'active',
        eventDate: '2024-01-01',
        rawText: 'my dog threw up',
      );
      expect(log.symptomName, 'my dog threw up');
    });

    test('symptomName returns Unknown when both are null', () {
      const log = SymptomLog(
        id: '1',
        eventType: 'symptom',
        source: 'user',
        status: 'active',
        eventDate: '2024-01-01',
      );
      expect(log.symptomName, 'Unknown symptom');
    });

    test('severityLabel capitalizes first letter', () {
      const log = SymptomLog(
        id: '1',
        eventType: 'symptom',
        source: 'user',
        status: 'active',
        eventDate: '2024-01-01',
        severity: 'moderate',
      );
      expect(log.severityLabel, 'Moderate');
    });

    test('isActive returns true for active status', () {
      const log = SymptomLog(
        id: '1',
        eventType: 'symptom',
        source: 'user',
        status: 'active',
        eventDate: '2024-01-01',
      );
      expect(log.isActive, true);
    });
  });

  group('WellnessSurveyResult', () {
    test('scoreForCategory maps answer index to score', () {
      const result = WellnessSurveyResult(
        petId: 'p1',
        date: '2024-01-01',
        answers: {'APPETITE': 0, 'COAT': 1, 'DENTAL': 2, 'ACTIVITY': 3},
      );

      expect(result.scoreForCategory('APPETITE'), 100);
      expect(result.scoreForCategory('COAT'), 70);
      expect(result.scoreForCategory('DENTAL'), 40);
      expect(result.scoreForCategory('ACTIVITY'), 10);
    });

    test('scoreForCategory returns null for missing category', () {
      const result = WellnessSurveyResult(
        petId: 'p1',
        date: '2024-01-01',
        answers: {'APPETITE': 0},
      );
      expect(result.scoreForCategory('DENTAL'), isNull);
    });

    test('overallScore averages all answers', () {
      const result = WellnessSurveyResult(
        petId: 'p1',
        date: '2024-01-01',
        answers: {'APPETITE': 0, 'COAT': 0},
      );
      // Both are 100 → average = 100
      expect(result.overallScore, 100);
    });

    test('overallScore returns 50 for empty answers', () {
      const result = WellnessSurveyResult(
        petId: 'p1',
        date: '2024-01-01',
        answers: {},
      );
      expect(result.overallScore, 50);
    });

    test('overallScore mixes different answer levels', () {
      const result = WellnessSurveyResult(
        petId: 'p1',
        date: '2024-01-01',
        answers: {'A': 0, 'B': 3}, // 100 + 10 = 110 / 2 = 55
      );
      expect(result.overallScore, 55);
    });
  });

  group('MedicalRecord', () {
    test('fromJson parses nested diagnoses and prescribed meds', () {
      final record = MedicalRecord.fromJson({
        'id': 'mr-1',
        'title': 'Annual Checkup',
        'date': '2024-06-15',
        'pet_id': 'pet-1',
        'clinic': 'VetCo',
        'vet_name': 'Dr. Smith',
        'diagnoses': [
          {'name': 'Healthy', 'notes': 'All clear'},
        ],
        'prescribed_meds': [
          {'name': 'Heartworm', 'dosage': '1 tablet/month'},
        ],
      });

      expect(record.diagnoses, hasLength(1));
      expect(record.diagnoses![0].name, 'Healthy');
      expect(record.prescribedMeds, hasLength(1));
      expect(record.prescribedMeds![0].dosage, '1 tablet/month');
    });
  });
}
