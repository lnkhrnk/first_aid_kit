import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../viewmodels/medicine_viewmodel.dart';
import '../services/api_service.dart';
import '../services/conflict_reactive_service.dart';
import 'separate_schedule_screen.dart';

class MockPackageImage {
  final String brandName;
  final String activeSubstance;
  final String dosage;
  final MedicineForm form;
  final String manufacturer;
  final Color packageColor;
  final String barcode;

  MockPackageImage({
    required this.brandName,
    required this.activeSubstance,
    required this.dosage,
    required this.form,
    required this.manufacturer,
    required this.packageColor,
    required this.barcode,
  });
}

class MedicineScanScreen extends StatefulWidget {
  final MedicineViewModel viewModel;

  const MedicineScanScreen({super.key, required this.viewModel});

  @override
  State<MedicineScanScreen> createState() => _MedicineScanScreenState();
}

class _MedicineScanScreenState extends State<MedicineScanScreen> {
  StreamSubscription<ConflictCheckResult>? _subscription;

  final List<MockPackageImage> _packageSamples = [
    // 1. Конфликтный с Нурофеном препарат (для демонстрации 4-й лабы!)
    MockPackageImage(
      brandName: 'Аспирин Комплекс',
      activeSubstance: 'Ацетилсалициловая кислота',
      dosage: '500 мг',
      form: MedicineForm.tablet,
      manufacturer: 'Bayer AG',
      packageColor: CupertinoColors.systemRed,
      barcode: '4607001234567',
    ),
    // 2. Безопасные препараты со скриншота
    MockPackageImage(
      brandName: 'Супрастин Экстра',
      activeSubstance: 'Хлоропирамин',
      dosage: '25 мг',
      form: MedicineForm.tablet,
      manufacturer: 'EGIS Pharmaceuticals',
      packageColor: CupertinoColors.systemTeal,
      barcode: '4601234567890',
    ),
    MockPackageImage(
      brandName: 'Амоксициллин',
      activeSubstance: 'Амоксициллин',
      dosage: '500 мг',
      form: MedicineForm.tablet,
      manufacturer: 'Sandoz',
      packageColor: CupertinoColors.activeOrange,
      barcode: '4609876543211',
    ),
    MockPackageImage(
      brandName: 'Лазолван Раствор',
      activeSubstance: 'Амброксол',
      dosage: '15 мг / 2 мл',
      form: MedicineForm.syrup,
      manufacturer: 'Boehringer Ingelheim',
      packageColor: CupertinoColors.systemIndigo,
      barcode: '4605556667778',
    ),
  ];

  int _selectedPackageIndex = 0;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.viewModel.conflictService
        .checkConflictsStream(
          existingMedicines: widget.viewModel.rawMedicines,
          matrix: widget.viewModel.interactions,
        )
        .listen(_handleConflictStreamEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onScanButtonPressed() {
    setState(() => _isScanning = true);
    final current = _packageSamples[_selectedPackageIndex];
    final candidate = Medicine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: current.brandName,
      activeSubstance: current.activeSubstance,
      form: current.form,
      expirationDate: DateTime.now().add(const Duration(days: 365)),
      count: 10,
      dosage: current.dosage,
      usageRules: 'Принимать строго по назначению врача.',
      instruction: 'Оригинальный препарат (${current.manufacturer}).',
    );
    widget.viewModel.conflictService.emitCandidate(candidate);
  }

  void _handleConflictStreamEvent(ConflictCheckResult result) async {
    final ApiMedicineInfo apiInfo = await widget.viewModel.verifyOnline(result.candidate.name);
    if (!mounted) return;
    setState(() => _isScanning = false);

    if (result.hasCriticalConflict) {
      // Поиск существующего конфликтующего лекарства
      final conflictingMed = widget.viewModel.rawMedicines.firstWhere(
        (m) => m.name == result.conflictingMedicineName,
        orElse: () => Medicine(
          id: '0',
          name: result.conflictingMedicineName ?? 'Препарат из аптечки',
          activeSubstance: 'Ибупрофен',
          form: MedicineForm.tablet,
          expirationDate: DateTime.now(),
          count: 1,
          dosage: '100 мг',
          usageRules: '',
          instruction: '',
        ),
      );

      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('⚠️ КРИТИЧЕСКИЙ КОНФЛИКТ'),
          content: Text(
            'Препарат "${result.candidate.name}" опасен при одновременном приеме с "${result.conflictingMedicineName}":\n\n'
            '${result.conflictDescription}\n\n'
            '🌐 REST API (Dio): ${apiInfo.safetyStatus}',
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Заблокировать'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Создать раздельный график'),
              onPressed: () async {
                await widget.viewModel.createSeparatedSchedule(result.candidate, result.conflictingMedicineName!);
                Navigator.pop(ctx); // Закрыть диалог
                Navigator.pop(context); // Закрыть сканер

                // Мгновенно открываем экран созданного раздельного графика!
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => SeparateScheduleScreen(
                      medicineA: conflictingMed,
                      medicineB: result.candidate,
                      dangerDescription: result.conflictDescription ?? '',
                      viewModel: widget.viewModel,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    } else {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Препарат проверен'),
          content: Text('"${result.candidate.name}" безопасен.\n🌐 REST API: ${apiInfo.safetyStatus}'),
          actions: [
            CupertinoDialogAction(child: const Text('Отмена'), onPressed: () => Navigator.pop(ctx)),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Добавить в базу'),
              onPressed: () async {
                await widget.viewModel.addScannedMedicine(result.candidate);
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePackage = _packageSamples[_selectedPackageIndex];

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Сканер упаковок'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. ТОТ САМЫЙ ВИДОИСКАТЕЛЬ СО СКРИНШОТА
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: CupertinoColors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Пачка лекарства
                    Container(
                      width: 250,
                      height: 155,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: activePackage.packageColor, width: 3.5),
                        boxShadow: [
                          BoxShadow(color: activePackage.packageColor.withOpacity(0.3), blurRadius: 12),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: activePackage.packageColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  activePackage.dosage,
                                  style: const TextStyle(color: CupertinoColors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(activePackage.manufacturer, style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey)),
                            ],
                          ),
                          Center(
                            child: Text(
                              activePackage.brandName,
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: CupertinoColors.black),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Форма: ${activePackage.form == MedicineForm.tablet ? "Таблетки" : "Сироп"}',
                                style: const TextStyle(fontSize: 11, color: CupertinoColors.black),
                              ),
                              const Icon(CupertinoIcons.barcode, size: 24, color: CupertinoColors.black),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Рамка видоискателя
                    Container(
                      width: 275,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isScanning ? CupertinoColors.activeGreen : CupertinoColors.activeBlue,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    // Бейдж снизу
                    Positioned(
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: CupertinoColors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _isScanning ? 'Реактивный анализ Combine...' : 'Упаковка в фокусе камеры',
                          style: const TextStyle(color: CupertinoColors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. ГОРИЗОНТАЛЬНЫЙ ВЫБОР УПАКОВОК СО СКРИНШОТА
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ВЫБЕРИТЕ УПАКОВКУ ДЛЯ СКАНИРОВАНИЯ (MOCK):',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CupertinoColors.secondaryLabel),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _packageSamples.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedPackageIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPackageIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  _packageSamples[index].brandName,
                                  style: TextStyle(
                                    color: isSelected ? CupertinoColors.white : CupertinoColors.label,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. СИНЯЯ КНОПКА СКАНИРОВАНИЯ СО СКРИНШОТА
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: _isScanning ? null : _onScanButtonPressed,
                  child: _isScanning
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.viewfinder),
                            SizedBox(width: 8),
                            Text('Считать текст с упаковки', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}