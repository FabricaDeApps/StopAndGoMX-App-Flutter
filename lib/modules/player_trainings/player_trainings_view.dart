// lib/modules/player_trainings/player_trainings_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'player_trainings_controller.dart';

class PlayerTrainingsView extends GetView<PlayerTrainingsController> {
  const PlayerTrainingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.error.value!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: controller.load,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final resp = controller.data.value;
        if (resp == null) {
          return Center(
            child: FilledButton(
              onPressed: controller.load,
              child: const Text('Cargar'),
            ),
          );
        }

        final cats = resp.categories;
        if (cats.isEmpty) {
          return _EmptyState(
            title: resp.player.name ?? 'Jugador',
            onRetry: controller.load,
          );
        }

        return DefaultTabController(
          length: cats.length,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  expandedHeight: 320,
                  title: Text('Entrenamientos'),
                  bottom: TabBar(
                    isScrollable: true,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicator: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: cats.map((c) {
                      final jersey = c.category.jerseyNumber;
                      final label = jersey == null
                          ? (c.category.name ?? 'Categoría')
                          : '${c.category.name ?? 'Categoría'}  #$jersey';

                      return Tab(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: SafeArea(
                      bottom: false,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PlayerHeader(
                                name: resp.player.name,
                                photoUrl: resp.player.photo,
                                organizationId: resp.player.organizationId,
                                firstName: resp.player.firstName,
                                lastName: resp.player.lastName,
                              ),
                              const SizedBox(height: 12),
                              _SummaryChips(
                                total: resp.summary.totalTrainings,
                                marked: resp.summary.markedTrainings,
                                present: resp.summary.present,
                                absent: resp.summary.absent,
                                justified: resp.summary.justified,
                                percent: resp.summary.attendancePercent,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: cats.map((c) {
                return _CategoryTab(
                  categoryName: c.category.name,
                  jersey: c.category.jerseyNumber,
                  summary: c.summary,
                  history: c.history,
                );
              }).toList(),
            ),
          ),
        );
      }),
    );
  }
}

/* =======================
 * Widgets
 * ======================= */

class _PlayerHeader extends StatelessWidget {
  final String? name;
  final String? photoUrl;
  final int organizationId;
  final String? firstName;
  final String? lastName;

  const _PlayerHeader({
    required this.name,
    required this.photoUrl,
    required this.organizationId,
    required this.firstName,
    required this.lastName,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        name ??
        [
          firstName,
          lastName,
        ].where((e) => (e ?? '').trim().isNotEmpty).join(' ').trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
              ? NetworkImage(photoUrl!)
              : null,
          child: (photoUrl == null || photoUrl!.isEmpty)
              ? const Icon(Icons.person, size: 30)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName.isNotEmpty ? displayName : 'Jugador',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryChips extends StatelessWidget {
  final int total;
  final int marked;
  final int present;
  final int absent;
  final int justified;
  final double percent;

  const _SummaryChips({
    required this.total,
    required this.marked,
    required this.present,
    required this.absent,
    required this.justified,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String value, IconData icon) {
      return Chip(
        avatar: Icon(icon, size: 18),
        label: Text('$label: $value'),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Asistencia', '${percent.toStringAsFixed(0)}%', Icons.percent),
        chip('Total', '$total', Icons.event_note),
        chip('Completados', '$marked', Icons.how_to_reg),
        chip('Presentes', '$present', Icons.check_circle_outline),
        chip('Ausentes', '$absent', Icons.cancel_outlined),
        chip('Just.', '$justified', Icons.rule),
      ],
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String? categoryName;
  final int? jersey;
  final dynamic summary; // TrainingSummary
  final List<dynamic> history; // List<TrainingHistoryItem>

  const _CategoryTab({
    required this.categoryName,
    required this.jersey,
    required this.summary,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jersey == null
                      ? (categoryName ?? 'Categoría')
                      : '${categoryName ?? 'Categoría'}  #$jersey',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  total: summary.totalTrainings,
                  marked: summary.markedTrainings,
                  present: summary.present,
                  absent: summary.absent,
                  justified: summary.justified,
                  percent: summary.attendancePercent,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Sin entrenamientos.'),
            ),
          )
        else
          ...history.map((t) => _TrainingCard(item: t)).toList(),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int total;
  final int marked;
  final int present;
  final int absent;
  final int justified;
  final double percent;

  const _SummaryRow({
    required this.total,
    required this.marked,
    required this.present,
    required this.absent,
    required this.justified,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle? s = Theme.of(context).textTheme.bodyMedium;
    TextStyle? b = s?.copyWith(fontWeight: FontWeight.w700);

    Widget item(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: s?.copyWith(color: s.color?.withOpacity(.65))),
        Text(value, style: b),
      ],
    );

    return Row(
      children: [
        Expanded(child: item('Asistencia', '${percent.toStringAsFixed(0)}%')),
        Expanded(child: item('Marcados', '$marked/$total')),
        Expanded(child: item('P/A/J', '$present/$absent/$justified')),
      ],
    );
  }
}

class _TrainingCard extends StatelessWidget {
  final dynamic item; // TrainingHistoryItem

  const _TrainingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final startsAt = item.startsAt as DateTime?;
    final dateStr = startsAt == null ? '—' : _formatDate(startsAt);

    final att = item.attendance; // AttendanceMini?
    final attStatus = att?.status?.toString();
    final statusLabel = attStatus == null
        ? 'Sin marca'
        : (attStatus == 'present'
              ? 'Presente'
              : attStatus == 'absent'
              ? 'Ausente'
              : 'Justificado');

    final checkedBy = att?.checkedBy?.name?.toString();
    final checkedAt = att?.checkedAt as DateTime?;
    final checkedAtStr = checkedAt == null ? null : _formatDateTime(checkedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          item.notes?.toString().isNotEmpty == true
              ? item.notes.toString()
              : 'Entrenamiento',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('$dateStr • ${item.durationMinutes ?? 0} min'),
            if ((item.venue ?? '').toString().isNotEmpty)
              Text('Sede: ${item.venue}'),
            if ((item.city ?? '').toString().isNotEmpty)
              Text('Ciudad: ${item.city}'),
            const SizedBox(height: 6),
            _AttendanceBadge(text: statusLabel, status: attStatus),
            if (checkedBy != null || checkedAtStr != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  [
                    if (checkedBy != null) 'Marcado por: $checkedBy',
                    if (checkedAtStr != null) '($checkedAtStr)',
                  ].join(' '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withOpacity(.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String _formatDateTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${_formatDate(d)} $hh:$mm';
  }
}

class _AttendanceBadge extends StatelessWidget {
  final String text;
  final String? status;

  const _AttendanceBadge({required this.text, required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (status == 'present') {
      icon = Icons.check_circle_outline;
    } else if (status == 'absent') {
      icon = Icons.cancel_outlined;
    } else if (status == 'justified') {
      icon = Icons.rule;
    } else {
      icon = Icons.help_outline;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final VoidCallback onRetry;

  const _EmptyState({required this.title, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Sin categorías asignadas o sin entrenamientos.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Recargar')),
          ],
        ),
      ),
    );
  }
}
