import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home_controller.dart';

class NoticesTab extends StatelessWidget {
  const NoticesTab({super.key, required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoadingNotices.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = controller.notices;
      if (list.isEmpty) {
        return Center(
          child: Text('Sin avisos', style: theme.textTheme.bodyMedium),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final n = list[i];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                child: const Icon(Icons.campaign_outlined),
              ),
              title: Text(
                n.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    _fmtDateTime(n.date),
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if ((n.message ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      n.message!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => controller.onTapNotice(n),
            ),
          );
        },
      );
    });
  }

  static String _fmtDateTime(DateTime d) {
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
