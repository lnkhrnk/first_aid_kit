import 'package:flutter/cupertino.dart';
import '../models/medicine.dart';
import '../viewmodels/medicine_viewmodel.dart';

class SeparateScheduleScreen extends StatefulWidget {
  final Medicine medicineA;
  final Medicine medicineB;
  final String dangerDescription;
  final MedicineViewModel viewModel;

  const SeparateScheduleScreen({
    super.key,
    required this.medicineA,
    required this.medicineB,
    required this.dangerDescription,
    required this.viewModel,
  });

  @override
  State<SeparateScheduleScreen> createState() => _SeparateScheduleScreenState();
}

class _SeparateScheduleScreenState extends State<SeparateScheduleScreen> {
  bool _remindMorning = true;
  bool _remindDay = true;
  bool _remindEvening = true;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Раздельный график'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Готово', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            // Предупреждение о причине создания графика
            CupertinoListSection.insetGrouped(
              header: const Text('ПРИЧИНА РАЗДЕЛЕНИЯ ПРИЕМОВ'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(CupertinoIcons.shield_lefthalf_fill, color: CupertinoColors.activeOrange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${widget.medicineA.name} ⚔️ ${widget.medicineB.name}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.dangerDescription,
                        style: const TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '🛡️ Установлен безопасный интервал: не менее 6 часов между приемами',
                          style: TextStyle(color: CupertinoColors.activeGreen, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Таймлайн безопасного графика
            CupertinoListSection.insetGrouped(
              header: const Text('РАСПИСАНИЕ ПРИЕМОВ (БЕЗОПАСНЫЕ ОКНА)'),
              children: [
                // 1. Утренний прием
                CupertinoListTile(
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemFill.resolveFrom(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('08:00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  title: Text(widget.medicineA.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Утренний прием во время еды'),
                  trailing: CupertinoSwitch(
                    value: _remindMorning,
                    onChanged: (val) => setState(() => _remindMorning = val),
                  ),
                ),

                // Разделитель интервала безопасности
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.clock, size: 14, color: CupertinoColors.secondaryLabel),
                      SizedBox(width: 6),
                      Text('Интервал 6 часов (лекарство A выводится из крови)', style: TextStyle(fontSize: 11, color: CupertinoColors.secondaryLabel)),
                    ],
                  ),
                ),

                // 2. Дневной прием второго препарата
                CupertinoListTile(
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemFill.resolveFrom(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('14:00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  title: Text(widget.medicineB.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Дневной прием (окно безопасности выдержано)'),
                  trailing: CupertinoSwitch(
                    value: _remindDay,
                    onChanged: (val) => setState(() => _remindDay = val),
                  ),
                ),

                // Разделитель интервала безопасности
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.clock, size: 14, color: CupertinoColors.secondaryLabel),
                      SizedBox(width: 6),
                      Text('Интервал 6 часов (лекарство B выводится из крови)', style: TextStyle(fontSize: 11, color: CupertinoColors.secondaryLabel)),
                    ],
                  ),
                ),

                // 3. Вечерний прием первого препарата
                CupertinoListTile(
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemFill.resolveFrom(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('20:00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  title: Text(widget.medicineA.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Вечерний прием перед сном'),
                  trailing: CupertinoSwitch(
                    value: _remindEvening,
                    onChanged: (val) => setState(() => _remindEvening = val),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  child: const Text('Сохранить в напоминания'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}