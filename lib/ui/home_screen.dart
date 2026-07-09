import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/export_service.dart';
import 'main_scaffold.dart';
import 'main_hub_screen.dart';

import 'lab_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _runAutoBackup();
  }

  Future<void> _runAutoBackup() async {
    final didBackup = await ExportService.tryAutoBackup();
    if (didBackup && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("DAILY_DB_BACKUP_COMPLETED"),
          backgroundColor: Colors.greenAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(
      screenKey: 'HOME',
      body: MainHubScreen(),
      bottomNavigationBar: LabFooter(),
    );
  }
}
