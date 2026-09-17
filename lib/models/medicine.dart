enum MedicineForm { all, tablet, syrup }

class Medicine {
  final String id;
  final String name;
  final String activeSubstance;
  final MedicineForm form;
  final DateTime expirationDate;
  int count;
  final String dosage;
  final String usageRules;
  final String instruction;

  Medicine({
    required this.id,
    required this.name,
    required this.activeSubstance,
    required this.form,
    required this.expirationDate,
    required this.count,
    required this.dosage,
    required this.usageRules,
    required this.instruction,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'activeSubstance': activeSubstance,
      'form': form.index,
      'expirationDate': expirationDate.toIso8601String(),
      'count': count,
      'dosage': dosage,
      'usageRules': usageRules,
      'instruction': instruction,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'],
      name: map['name'],
      activeSubstance: map['activeSubstance'] ?? 'Не указано',
      form: MedicineForm.values[map['form']],
      expirationDate: DateTime.parse(map['expirationDate']),
      count: map['count'],
      dosage: map['dosage'],
      usageRules: map['usageRules'],
      instruction: map['instruction'],
    );
  }
}

class IntakeLog {
  final int? id;
  final String medicineId;
  final DateTime timestamp;
  final String note;

  IntakeLog({
    this.id,
    required this.medicineId,
    required this.timestamp,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineId': medicineId,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  factory IntakeLog.fromMap(Map<String, dynamic> map) {
    return IntakeLog(
      id: map['id'],
      medicineId: map['medicineId'],
      timestamp: DateTime.parse(map['timestamp']),
      note: map['note'],
    );
  }
}

class ScheduleItem {
  final int? id;
  final String medicineName;
  final String time;
  final String intervalNote;
  bool isEnabled;

  ScheduleItem({
    this.id,
    required this.medicineName,
    required this.time,
    required this.intervalNote,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'time': time,
      'intervalNote': intervalNote,
      'isEnabled': isEnabled ? 1 : 0,
    };
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'],
      medicineName: map['medicineName'],
      time: map['time'],
      intervalNote: map['intervalNote'],
      isEnabled: map['isEnabled'] == 1,
    );
  }
}

class InteractionMatrixItem {
  final String id;
  final String substanceA;
  final String substanceB;
  final String dangerDescription;

  InteractionMatrixItem({
    required this.id,
    required this.substanceA,
    required this.substanceB,
    required this.dangerDescription,
  });

  factory InteractionMatrixItem.fromJson(Map<String, dynamic> json) {
    return InteractionMatrixItem(
      id: json['id'],
      substanceA: json['substanceA'],
      substanceB: json['substanceB'],
      dangerDescription: json['dangerDescription'],
    );
  }
}