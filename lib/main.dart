import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FirstAidApp());
}

// Перечисление для фильтрации по форме выпуска
enum MedicineForm { all, tablet, syrup }

// Модель данных медикамента
class Medicine {
  final String id;
  final String name;
  final MedicineForm form;
  final DateTime expirationDate;
  final int count;

  Medicine({
    required this.id,
    required this.name,
    required this.form,
    required this.expirationDate,
    required this.count,
  });
}

class FirstAidApp extends StatelessWidget {
  const FirstAidApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Используем стиль iOS (Cupertino)
    return const CupertinoApp(
      title: 'Домашняя аптечка',
      theme: CupertinoThemeData(primaryColor: CupertinoColors.activeBlue),
      home: MedicineListScreen(),
    );
  }
}

// Главный экран каталога
class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  // Исходный список медикаментов в наличии
  final List<Medicine> _medicines = [
    Medicine(
      id: '1',
      name: 'Парацетамол',
      form: MedicineForm.tablet,
      expirationDate: DateTime.now().add(const Duration(days: 12)), // Скоро истечет
      count: 20,
    ),
    Medicine(
      id: '2',
      name: 'Нурофен сироп',
      form: MedicineForm.syrup,
      expirationDate: DateTime.now().subtract(const Duration(days: 3)), // Просрочен
      count: 1,
    ),
    Medicine(
      id: '3',
      name: 'Аспирин Кардио',
      form: MedicineForm.tablet,
      expirationDate: DateTime.now().add(const Duration(days: 400)),
      count: 28,
    ),
    Medicine(
      id: '4',
      name: 'Геделикс сироп',
      form: MedicineForm.syrup,
      expirationDate: DateTime.now().add(const Duration(days: 90)),
      count: 2,
    ),
    Medicine(
      id: '5',
      name: 'Ибупрофен',
      form: MedicineForm.tablet,
      expirationDate: DateTime.now().add(const Duration(days: 5)), // Критический срок
      count: 10,
    ),
  ];

  MedicineForm _selectedFilter = MedicineForm.all;
  bool _sortByCriticalDate = true;

  // Логика фильтрации и сортировки
  List<Medicine> get _processedMedicines {
    var list = _medicines.where((med) {
      if (_selectedFilter == MedicineForm.all) return true;
      return med.form == _selectedFilter;
    }).toList();

    if (_sortByCriticalDate) {
      // Сортировка: сначала просроченные и те, у которых срок быстрее заканчивается
      list.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final list = _processedMedicines;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Домашняя аптечка'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
           child: Icon(
            _sortByCriticalDate
                ? CupertinoIcons.sort_down
                : CupertinoIcons.sort_up,
          ),
          onPressed: () {
            setState(() {
              _sortByCriticalDate = !_sortByCriticalDate;
            });
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Фильтр по форме выпуска (Таблетки, Сиропы, Все)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<MedicineForm>(
                  groupValue: _selectedFilter,
                  children: const {
                    MedicineForm.all: Text('Все'),
                    MedicineForm.tablet: Text('Таблетки'),
                    MedicineForm.syrup: Text('Сиропы'),
                  },
                  onValueChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedFilter = val);
                    }
                  },
                ),
              ),
            ),
            // Список лекарств
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Лекарства не найдены'))
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        final isExpired = item.expirationDate.isBefore(DateTime.now());

                        return CupertinoListTile(
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Форма: ${item.form == MedicineForm.tablet ? "Таблетки" : "Сироп"} • Остаток: ${item.count} шт.',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item.expirationDate.day.toString().padLeft(2, '0')}.${item.expirationDate.month.toString().padLeft(2, '0')}.${item.expirationDate.year}',
                                style: TextStyle(
                                  color: isExpired
                                      ? CupertinoColors.destructiveRed
                                      : CupertinoColors.secondaryLabel,
                                  fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (isExpired)
                                const Text(
                                  'Просрочено',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: CupertinoColors.destructiveRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}