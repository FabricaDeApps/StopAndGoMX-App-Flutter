import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/combines/combine_metric_leaderboard_response.dart';
import 'package:stopandgo/modules/combine_metric_leader_board/combine_metric_leader_board_controller.dart';

class CombineMetricLeaderBoardView
    extends GetView<CombineMetricLeaderBoardController> {
  const CombineMetricLeaderBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Leaderboard • ${controller.metric.name}')),
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: controller.load,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final resp = controller.data.value;
        final rows = resp?.leaderboard ?? const <CombineLeaderboardEntry>[];

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: rows.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [
                    SizedBox(height: 80),
                    Center(child: Text('Sin resultados todavía.')),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = rows[i];
                    final valueStr = _formatValue(
                      e.value,
                      controller.metric.decimals ?? 2,
                    );
                    final unit = e.unit ?? controller.metric.unit ?? '';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          _RankBadge(rank: e.rank),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.player.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$valueStr $unit',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      }),
    );
  }

  String _formatValue(num v, int decimals) {
    if (v is double) return v.toStringAsFixed(decimals);
    return v.toString();
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        '$rank',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
