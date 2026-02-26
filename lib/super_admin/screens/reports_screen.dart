import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/super_admin_api_riverpod_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final reportsAsync = ref.watch(superAdminReportsApiProvider);
    final reports = reportsAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color:
                    isLight ? const Color(0xFF0a1a2a) : const Color(0xFFe8f1fc),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View and export monitoring reports.',
              style: TextStyle(
                fontSize: 14,
                color:
                    isLight ? const Color(0xFF4a6b8a) : const Color(0xFF8aaac9),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:
                    isLight ? const Color(0xFFf0f5fd) : const Color(0xFF203a54),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Text(
                reports.isEmpty
                    ? 'No reports generated yet.'
                    : 'Loaded ${reports.length} report(s) from API.',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
