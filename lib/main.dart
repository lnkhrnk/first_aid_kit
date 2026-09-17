import 'package:flutter/cupertino.dart';
import 'viewmodels/medicine_viewmodel.dart';
import 'views/medicine_list_screen.dart';
import 'views/schedule_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final viewModel = MedicineViewModel();
  await viewModel.init();

  runApp(FirstAidApp(viewModel: viewModel));
}

class FirstAidApp extends StatelessWidget {
  final MedicineViewModel viewModel;
  const FirstAidApp({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Аптечка',
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.archivebox_fill),
              label: 'Аптечка',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.calendar_today),
              label: 'График',
            ),
          ],
        ),
        tabBuilder: (context, index) {
          switch (index) {
            case 0:
              return MedicineListScreen(viewModel: viewModel);
            case 1:
              return ScheduleScreen(viewModel: viewModel);
            default:
              return MedicineListScreen(viewModel: viewModel);
          }
        },
      ),
    );
  }
}