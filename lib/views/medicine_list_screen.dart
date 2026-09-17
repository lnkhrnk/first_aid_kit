import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../viewmodels/medicine_viewmodel.dart';
import 'medicine_detail_screen.dart';
import 'medicine_scan_screen.dart';
import 'schedule_screen.dart';

class MedicineListScreen extends StatelessWidget {
  final MedicineViewModel viewModel;

  const MedicineListScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final list = viewModel.medicines;

        return CupertinoPageScaffold(
          backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
          navigationBar: CupertinoNavigationBar(
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.camera_viewfinder),
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => MedicineScanScreen(viewModel: viewModel),
                  ),
                );
              },
            ),
            middle: const Text('Аптечка'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Иконка быстрого перехода в график
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.calendar_today),
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => ScheduleScreen(viewModel: viewModel),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    viewModel.sortByCriticalDate ? CupertinoIcons.sort_down : CupertinoIcons.sort_up,
                  ),
                  onPressed: viewModel.toggleSort,
                ),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Плашка активного раздельного графика (если созданы напоминания)
                if (viewModel.schedules.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(builder: (_) => ScheduleScreen(viewModel: viewModel)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: CupertinoColors.activeBlue.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.clock_fill, color: CupertinoColors.activeBlue, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Активен раздельный график (${viewModel.schedules.length} приемов)',
                                style: const TextStyle(color: CupertinoColors.activeBlue, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.activeBlue, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<MedicineForm>(
                      groupValue: viewModel.selectedFilter,
                      children: const {
                        MedicineForm.all: Text('Все'),
                        MedicineForm.tablet: Text('Таблетки'),
                        MedicineForm.syrup: Text('Сиропы'),
                      },
                      onValueChanged: (val) {
                        if (val != null) viewModel.setFilter(val);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text('Препараты не найдены', style: TextStyle(color: CupertinoColors.secondaryLabel)))
                      : ListView(
                          children: [
                            CupertinoListSection.insetGrouped(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              children: list.map((item) {
                                final isExpired = item.expirationDate.isBefore(DateTime.now());

                                return Dismissible(
                                  key: Key(item.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: CupertinoColors.destructiveRed,
                                    child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
                                  ),
                                  onDismissed: (_) => viewModel.deleteMedicine(item.id),
                                  child: CupertinoListTile(
                                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text('${item.activeSubstance} • ${item.count} шт.'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${item.expirationDate.day.toString().padLeft(2, '0')}.${item.expirationDate.month.toString().padLeft(2, '0')}.${item.expirationDate.year}',
                                          style: TextStyle(
                                            color: isExpired ? CupertinoColors.destructiveRed : CupertinoColors.secondaryLabel,
                                            fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(CupertinoIcons.chevron_forward, size: 14, color: CupertinoColors.systemGrey3),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        CupertinoPageRoute(
                                          builder: (_) => MedicineDetailScreen(
                                            medicine: item,
                                            viewModel: viewModel,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}