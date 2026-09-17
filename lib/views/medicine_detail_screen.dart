import 'package:flutter/cupertino.dart';
import '../models/medicine.dart';
import '../viewmodels/medicine_viewmodel.dart';

class MedicineDetailScreen extends StatefulWidget {
  final Medicine medicine;
  final MedicineViewModel viewModel;

  const MedicineDetailScreen({
    super.key,
    required this.medicine,
    required this.viewModel,
  });

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  List<IntakeLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await widget.viewModel.getLogs(widget.medicine.id);
    setState(() => _logs = logs);
  }

  void _confirmDelete() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Удалить "${widget.medicine.name}"?'),
        message: const Text('Препарат и вся история приемов будут безвозвратно удалены из базы данных.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              await widget.viewModel.deleteMedicine(widget.medicine.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Удалить из аптечки'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.medicine;
    final isExpired = med.expirationDate.isBefore(DateTime.now());
    final warnings = widget.viewModel.getWarningsFor(med);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text(med.name),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _confirmDelete,
          child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            // Предупреждение о конфликте (если есть)
            if (warnings.isNotEmpty)
              CupertinoListSection.insetGrouped(
                header: const Text('ОБНАРУЖЕН КОНФЛИКТ В АПТЕЧКЕ'),
                children: warnings.map((w) {
                  return CupertinoListTile(
                    leading: const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: CupertinoColors.destructiveRed),
                    title: Text(w, style: const TextStyle(fontSize: 13, color: CupertinoColors.destructiveRed)),
                  );
                }).toList(),
              ),

            // Основная информация
            CupertinoListSection.insetGrouped(
              header: const Text('ИНФОРМАЦИЯ О ПРЕПАРАТЕ'),
              children: [
                CupertinoListTile(
                  title: const Text('Действующее вещество'),
                  trailing: Text(med.activeSubstance, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
                ),
                CupertinoListTile(
                  title: const Text('Форма выпуска'),
                  trailing: Text(med.form == MedicineForm.tablet ? 'Таблетки' : 'Сироп', style: const TextStyle(color: CupertinoColors.secondaryLabel)),
                ),
                CupertinoListTile(
                  title: const Text('Дозировка'),
                  trailing: Text(med.dosage, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
                ),
                CupertinoListTile(
                  title: const Text('Статус годности'),
                  trailing: Text(
                    isExpired ? 'Просрочен' : 'Годен',
                    style: TextStyle(color: isExpired ? CupertinoColors.destructiveRed : CupertinoColors.activeGreen, fontWeight: FontWeight.w600),
                  ),
                ),
                CupertinoListTile(
                  title: const Text('Остаток'),
                  trailing: Text('${med.count} шт.', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            // Кнопка фиксации приема
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: med.count > 0
                      ? () async {
                          await widget.viewModel.takeDose(med);
                          await _loadLogs();
                        }
                      : null,
                  child: Text(med.count > 0 ? 'Зафиксировать прием (-1 доза)' : 'Препарат закончился'),
                ),
              ),
            ),

            // Журнал приемов
            CupertinoListSection.insetGrouped(
              header: const Text('ЖУРНАЛ ПРИЕМОВ (SQLITE)'),
              children: _logs.isEmpty
                  ? [
                      const CupertinoListTile(
                        title: Text('Приемов не зафиксировано', style: TextStyle(color: CupertinoColors.secondaryLabel)),
                      )
                    ]
                  : _logs.map((log) {
                      return CupertinoListTile(
                        title: Text(log.note),
                        trailing: Text(
                          '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')} (${log.timestamp.day}.${log.timestamp.month})',
                          style: const TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 13),
                        ),
                      );
                    }).toList(),
            ),

            // Инструкция
            CupertinoListSection.insetGrouped(
              header: const Text('ПРАВИЛА И ИНСТРУКЦИЯ'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.usageRules, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(med.instruction, style: const TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}