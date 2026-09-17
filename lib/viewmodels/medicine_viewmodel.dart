import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/conflict_reactive_service.dart';

class MedicineViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ConflictReactiveService conflictService = ConflictReactiveService();

  List<Medicine> _medicines = [];
  List<ScheduleItem> _schedules = [];
  List<InteractionMatrixItem> _interactions = [];
  MedicineForm _selectedFilter = MedicineForm.all;
  bool _sortByCriticalDate = true;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  MedicineForm get selectedFilter => _selectedFilter;
  bool get sortByCriticalDate => _sortByCriticalDate;
  List<InteractionMatrixItem> get interactions => _interactions;
  List<Medicine> get rawMedicines => _medicines;
  List<ScheduleItem> get schedules => _schedules;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _medicines = await DatabaseService.instance.getAllMedicines();
    _schedules = await DatabaseService.instance.getSchedules();
    await _loadInteractionsJson();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadInteractionsJson() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/interactions.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _interactions = jsonList.map((item) => InteractionMatrixItem.fromJson(item)).toList();
    } catch (e) {
      debugPrint('JSON Error: $e');
    }
  }

  List<Medicine> get medicines {
    var list = _medicines.where((med) {
      if (_selectedFilter == MedicineForm.all) return true;
      return med.form == _selectedFilter;
    }).toList();

    list.sort((a, b) {
      if (_sortByCriticalDate) {
        return a.expirationDate.compareTo(b.expirationDate);
      } else {
        return b.expirationDate.compareTo(a.expirationDate);
      }
    });

    return list;
  }

  void setFilter(MedicineForm filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void toggleSort() {
    _sortByCriticalDate = !_sortByCriticalDate;
    notifyListeners();
  }

  Future<ApiMedicineInfo> verifyOnline(String name) async {
    return await _apiService.verifyMedicineOnline(name);
  }

  Future<void> addScannedMedicine(Medicine medicine) async {
    await DatabaseService.instance.insertMedicine(medicine);
    _medicines = await DatabaseService.instance.getAllMedicines();
    notifyListeners();
  }

  // Удаление лекарства из базы
  Future<void> deleteMedicine(String id) async {
    await DatabaseService.instance.deleteMedicine(id);
    _medicines = await DatabaseService.instance.getAllMedicines();
    notifyListeners();
  }

  // Создание раздельного графика безопасности при конфликте
  Future<void> createSeparatedSchedule(Medicine candidate, String conflictingName) async {
    await addScannedMedicine(candidate);

    final schedule1 = ScheduleItem(
      medicineName: conflictingName,
      time: '08:00',
      intervalNote: 'Окно безопасности: 6 часов до ${candidate.name}',
    );
    final schedule2 = ScheduleItem(
      medicineName: candidate.name,
      time: '14:00',
      intervalNote: 'Раздельный прием (интервал выдержан)',
    );

    await DatabaseService.instance.insertSchedule(schedule1);
    await DatabaseService.instance.insertSchedule(schedule2);

    _schedules = await DatabaseService.instance.getSchedules();
    notifyListeners();
  }

  Future<void> toggleSchedule(ScheduleItem item, bool val) async {
    if (item.id != null) {
      await DatabaseService.instance.updateScheduleStatus(item.id!, val);
      item.isEnabled = val;
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(int id) async {
    await DatabaseService.instance.deleteSchedule(id);
    _schedules = await DatabaseService.instance.getSchedules();
    notifyListeners();
  }

  Future<void> takeDose(Medicine medicine) async {
    if (medicine.count <= 0) return;
    medicine.count -= 1;
    await DatabaseService.instance.updateCount(medicine.id, medicine.count);

    final log = IntakeLog(
      medicineId: medicine.id,
      timestamp: DateTime.now(),
      note: 'Принята 1 доза (${medicine.dosage})',
    );
    await DatabaseService.instance.logIntake(log);
    notifyListeners();
  }

  Future<List<IntakeLog>> getLogs(String medicineId) async {
    return await DatabaseService.instance.getLogsForMedicine(medicineId);
  }

  List<String> getWarningsFor(Medicine med) {
    List<String> warnings = [];
    for (var other in _medicines) {
      if (other.id == med.id) continue;
      for (var rule in _interactions) {
        if ((rule.substanceA == med.activeSubstance && rule.substanceB == other.activeSubstance) ||
            (rule.substanceB == med.activeSubstance && rule.substanceA == other.activeSubstance)) {
          warnings.add('Несовместим с "${other.name}": ${rule.dangerDescription}');
        }
      }
    }
    return warnings;
  }

  @override
  void dispose() {
    conflictService.dispose();
    super.dispose();
  }
}