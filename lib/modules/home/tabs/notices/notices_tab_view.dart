// lib/modules/home/tabs/notices/notices_tab_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/routes/app_routes.dart';

import 'notices_tab_controller.dart';

class NoticesTabView extends GetView<NoticesTabController> {
  const NoticesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = controller.listNotices;
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
          final notice = list[i];

          String title = "";
          if (notice.categoryId != null) {
            title = "${notice.title} - ${notice.categoryName}";
          } else {
            title = notice.title;
          }

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
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    _fmtDateTime(notice.publishedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if ((notice.message ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      notice.message!.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Get.toNamed(
                  Routes.noticeDetail,
                  arguments: {'notice': notice},
                );
              },
            ),
          );
        },
      );
    });
  }

  static String _fmtDateTime(DateTime? d) {
    if (d == null) return 'Sin fecha';
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
