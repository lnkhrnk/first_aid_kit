import 'package:flutter/cupertino.dart';
import '../viewmodels/medicine_viewmodel.dart';

class ScheduleScreen extends StatelessWidget {
  final MedicineViewModel viewModel;

  const ScheduleScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final list = viewModel.schedules;

        return CupertinoPageScaffold(
          backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
          navigationBar: const CupertinoNavigationBar(
            middle: Text('График приемов'),
          ),
          child: SafeArea(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'График пуст.\nНапоминания создаются при сканировании.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: CupertinoColors.secondaryLabel),
                    ),
                  )
                : ListView(
                    children: [
                      CupertinoListSection.insetGrouped(
                        header: const Text('СИСТЕМНЫЕ НАПОМИНАНИЯ (РАЗДЕЛЬНЫЙ ГРАФИК)'),
                        children: list.map((item) {
                          return CupertinoListTile(
                            leading: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemFill.resolveFrom(context),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.time,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            title: Text(item.medicineName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(item.intervalNote, style: const TextStyle(fontSize: 12)),
                            trailing: CupertinoSwitch(
                              value: item.isEnabled,
                              onChanged: (val) => viewModel.toggleSchedule(item, val),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}