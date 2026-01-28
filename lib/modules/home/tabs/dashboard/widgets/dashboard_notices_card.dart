import 'package:flutter/material.dart';
import 'package:stopandgo/core/widgets/cards.dart';
import 'package:stopandgo/modules/home/models/home_notice_item.dart';

class DashboardNoticesCard extends StatelessWidget {
  const DashboardNoticesCard({
    super.key,
    required this.notices,
    required this.onGoNoticesTab,
    required this.onTapNotice,
  });

  final List<NoticeItem> notices;
  final VoidCallback onGoNoticesTab;
  final void Function(NoticeItem n) onTapNotice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ns = notices.take(2).toList();

    return GestureDetector(
      onTap: onGoNoticesTab,
      child: MiniCard(
        title: 'Último aviso',
        child: ns.isEmpty
            ? Text('Sin avisos', style: theme.textTheme.bodySmall)
            : Column(
                children: ns.map((n) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.campaign, size: 20),
                    title: Text(
                      n.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(_fmtDate(n.date)),
                    onTap: () => onTapNotice(n),
                  );
                }).toList(),
              ),
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
