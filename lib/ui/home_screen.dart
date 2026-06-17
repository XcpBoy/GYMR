import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main_scaffold.dart';
import 'main_hub_screen.dart';

import 'lab_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MainScaffold(
      screenKey: 'HOME',
      body: MainHubScreen(),
      bottomNavigationBar: LabFooter(),
    );
  }
}
