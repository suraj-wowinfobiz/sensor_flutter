import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class LoginPreferencesButton extends StatelessWidget {
  const LoginPreferencesButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Preferences',
      onPressed: () => _showPreferences(context),
      icon: const Icon(Icons.tune),
    );
  }

  void _showPreferences(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Login Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ThemeMode>(
                      value: themeProvider.themeMode,
                      decoration: const InputDecoration(
                        labelText: 'Theme mode',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          themeProvider.setThemeMode(mode);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Text Size (${themeProvider.textScale.toStringAsFixed(2)}x)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Slider(
                      value: themeProvider.textScale,
                      min: 0.85,
                      max: 1.4,
                      divisions: 11,
                      label: themeProvider.textScale.toStringAsFixed(2),
                      onChanged: themeProvider.setTextScale,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _presetChip(
                          context,
                          label: 'Default',
                          selected: themeProvider
                              .isUsingPreset(ThemePreset.defaultBlue),
                          onTap: () => themeProvider
                              .applyPreset(ThemePreset.defaultBlue),
                        ),
                        _presetChip(
                          context,
                          label: 'Ocean',
                          selected:
                              themeProvider.isUsingPreset(ThemePreset.ocean),
                          onTap: () =>
                              themeProvider.applyPreset(ThemePreset.ocean),
                        ),
                        _presetChip(
                          context,
                          label: 'Forest',
                          selected:
                              themeProvider.isUsingPreset(ThemePreset.forest),
                          onTap: () =>
                              themeProvider.applyPreset(ThemePreset.forest),
                        ),
                        _presetChip(
                          context,
                          label: 'Sunset',
                          selected:
                              themeProvider.isUsingPreset(ThemePreset.sunset),
                          onTap: () =>
                              themeProvider.applyPreset(ThemePreset.sunset),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _presetChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primary.withValues(alpha: 0.18),
      checkmarkColor: scheme.primary,
      labelStyle: TextStyle(
        color: selected ? scheme.primary : null,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? scheme.primary : Theme.of(context).dividerColor,
      ),
    );
  }
}
