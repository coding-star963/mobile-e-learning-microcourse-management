import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/theme_provider.dart';

/// Sun / moon button that switches between light and dark mode.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: AppTheme.goldPrimary,
      ),
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () => context
          .read<ThemeProvider?>()
          ?.toggle(Theme.of(context).brightness),
    );
  }
}

/// Appearance setting: follow the phone (System), Light or Dark.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider?>();
    if (provider == null) return const SizedBox.shrink();

    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto_outlined),
          label: Text('System'),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode_outlined),
          label: Text('Light'),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode_outlined),
          label: Text('Dark'),
        ),
      ],
      selected: {provider.mode},
      onSelectionChanged: (selection) => provider.setMode(selection.first),
    );
  }
}
