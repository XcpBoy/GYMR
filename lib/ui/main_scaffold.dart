import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import 'styles.dart';

class MainScaffold extends ConsumerWidget {
  final Widget body;
  final String title;
  final String? screenKey;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const MainScaffold({
    super.key,
    required this.body,
    this.title = '',
    this.screenKey,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the wallpaper but we don't block the build if it's loading or has error
    String? wallpaperPath;
    if (screenKey != null) {
      try {
        wallpaperPath = ref.watch(wallpaperProvider(screenKey!)).asData?.value;
      } catch (_) {
        wallpaperPath = null;
      }
    }

    return Scaffold(
      backgroundColor: LabColors.background,
      appBar: title.isEmpty
          ? null
          : AppBar(
              backgroundColor: LabColors.background,
              elevation: 0,
              centerTitle: true,
              title: Text(
                title.toUpperCase(),
                style: LabStyles.mono(context, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              actions: actions,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: LabColors.cyanBorder,
                  height: 0.5,
                ),
              ),
            ),
      body: Stack(
        children: [
          if (wallpaperPath != null && wallpaperPath.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: Image.file(
                  File(wallpaperPath),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const SizedBox(),
                ),
              ),
            ),
          body,
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
