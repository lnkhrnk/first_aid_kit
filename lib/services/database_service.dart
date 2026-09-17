import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medicine.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('first_aid_kit_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medicines (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        activeSubstance TEXT NOT NULL,
        form INTEGER NOT NULL,
        expirationDate TEXT NOT NULL,
        count INTEGER NOT NULL,
        dosage TEXT NOT NULL,
        usageRules TEXT NOT NULL,
        instruction TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE intake_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicineId TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        note TEXT NOT NULL,
        FOREIGN KEY (medicineId) REFERENCES medicines (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicineName TEXT NOT NULL,
        time TEXT NOT NULL,
        intervalNote TEXT NOT NULL,
        isEnabled INTEGER NOT NULL
      )
    ''');

    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    final initialList = [
      Medicine(
        id: '1',
        name: 'Парацетамол',
        activeSubstance: 'Парацетамол',
        form: MedicineForm.tablet,
        expirationDate: DateTime.now().add(const Duration(days: 12)),
        count: 20,
        dosage: '500 мг',
        usageRules: 'По 1 таблетке до 3 раз в сутки после еды.',
        instruction: 'Обезболивающее и жаропонижающее средство.',
      ),
      Medicine(
        id: '2',
        name: 'Нурофен сироп',
        activeSubstance: 'Ибупрофен',
        form: MedicineForm.syrup,
        expirationDate: DateTime.now().subtract(const Duration(days: 3)),
        count: 1,
        dosage: '100 мг / 5 мл',
        usageRules: 'Внутрь мерным шприцем 3 раза в сутки.',
        instruction: 'НПВП для симптоматической терапии.',
      ),
      Medicine(
        id: '3',
        name: 'Аспирин Кардио',
        activeSubstance: 'Ацетилсалициловая кислота',
        form: MedicineForm.tablet,
        expirationDate: DateTime.now().add(const Duration(days: 400)),
        count: 28,
        dosage: '100 мг',
        usageRules: 'По 1 таблетке в сутки перед едой.',
        instruction: 'Антиагрегантное средство.',
      ),
    ];

    for (var med in initialList) {
      await db.insert('medicines', med.toMap());
    }

    await db.insert('schedules', ScheduleItem(
      medicineName: 'Нурофен сироп',
      time: '09:00',
      intervalNote: 'Утренний прием во время еды',
      isEnabled: true,
    ).toMap());
  }

  Future<List<Medicine>> getAllMedicines() async {
    final db = await instance.database;
    final result = await db.query('medicines');
    return result.map((json) => Medicine.fromMap(json)).toList();
  }

  Future<void> insertMedicine(Medicine medicine) async {
    final db = await instance.database;
    await db.insert('medicines', medicine.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMedicine(String id) async {
    final db = await instance.database;
    await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
    await db.delete('intake_logs', where: 'medicineId = ?', whereArgs: [id]);
  }

  Future<void> updateCount(String id, int newCount) async {
    final db = await instance.database;
    await db.update('medicines', {'count': newCount}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> logIntake(IntakeLog log) async {
    final db = await instance.database;
    await db.insert('intake_logs', log.toMap());
  }

  Future<List<IntakeLog>> getLogsForMedicine(String medicineId) async {
    final db = await instance.database;
    final result = await db.query('intake_logs', where: 'medicineId = ?', whereArgs: [medicineId], orderBy: 'timestamp DESC');
    return result.map((json) => IntakeLog.fromMap(json)).toList();
  }

  Future<List<ScheduleItem>> getSchedules() async {
    final db = await instance.database;
    final result = await db.query('schedules', orderBy: 'time ASC');
    return result.map((json) => ScheduleItem.fromMap(json)).toList();
  }

  Future<void> insertSchedule(ScheduleItem item) async {
    final db = await instance.database;
    await db.insert('schedules', item.toMap());
  }

  Future<void> updateScheduleStatus(int id, bool isEnabled) async {
    final db = await instance.database;
    await db.update('schedules', {'isEnabled': isEnabled ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSchedule(int id) async {
    final db = await instance.database;
    await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }
}