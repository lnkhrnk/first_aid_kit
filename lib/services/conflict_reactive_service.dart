import 'dart:async';
import '../models/medicine.dart';

// Результат реактивного анализа
class ConflictCheckResult {
  final Medicine candidate;
  final bool hasCriticalConflict;
  final String? conflictDescription;
  final String? conflictingMedicineName;

  ConflictCheckResult({
    required this.candidate,
    required this.hasCriticalConflict,
    this.conflictDescription,
    this.conflictingMedicineName,
  });
}

class ConflictReactiveService {
  // Реактивный поток входных данных (аналог Combine PassthroughSubject)
  final _inputController = StreamController<Medicine>.broadcast();

  // Внешний реактивный поток результатов (аналог AnyPublisher)
  Stream<ConflictCheckResult> checkConflictsStream({
    required List<Medicine> existingMedicines,
    required List<InteractionMatrixItem> matrix,
  }) {
    // Реактивная трансформация потока через map / where
    return _inputController.stream.asyncMap((candidate) async {
      // Имитация реактивной асинхронной обработки
      await Future.delayed(const Duration(milliseconds: 300));

      for (var existing in existingMedicines) {
        for (var rule in matrix) {
          final isMatch = (rule.substanceA == candidate.activeSubstance && rule.substanceB == existing.activeSubstance) ||
                          (rule.substanceB == candidate.activeSubstance && rule.substanceA == existing.activeSubstance);
          if (isMatch) {
            return ConflictCheckResult(
              candidate: candidate,
              hasCriticalConflict: true,
              conflictingMedicineName: existing.name,
              conflictDescription: rule.dangerDescription,
            );
          }
        }
      }

      return ConflictCheckResult(
        candidate: candidate,
        hasCriticalConflict: false,
      );
    });
  }

  // Отправка события в поток (Send / Sink)
  void emitCandidate(Medicine medicine) {
    _inputController.add(medicine);
  }

  void dispose() {
    _inputController.close();
  }
}