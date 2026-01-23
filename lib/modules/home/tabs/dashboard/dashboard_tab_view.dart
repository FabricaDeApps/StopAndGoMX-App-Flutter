import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/widgets/cards.dart';
import 'package:stopandgo/modules/home/models/home_notice_item.dart';
import 'package:stopandgo/modules/home/tabs/dashboard/dashboard_tab_controller.dart';
import 'package:stopandgo/core/models/games.dart';
import 'package:stopandgo/modules/home/tabs/dashboard/widgets/dashboard_attendance_card.dart';

import 'widgets/dashboard_games_card.dart';
import 'widgets/dashboard_notices_card.dart';

class DashboardTabView extends GetView<DashboardTabController> {
  const DashboardTabView({
    super.key,
    required this.onTapPay,
    required this.onTapGame,
    required this.onTapNotice,
    required this.onGoGamesTab,
    required this.onGoNoticesTab,
  });

  final VoidCallback onTapPay;
  final void Function(Game g) onTapGame;
  final void Function(NoticeItem n) onTapNotice;

  final VoidCallback onGoGamesTab;
  final VoidCallback onGoNoticesTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Obx(() {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(.10),
                theme.colorScheme.secondary.withOpacity(.10),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(.4),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),

            child: Column(
              children: [
                if (controller.role.value == 'parent' ||
                    controller.role.value == 'player') ...[
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Pagos pendientes:',
                          value:
                              '\$${controller.saldoPendiente.value.toStringAsFixed(2)}',
                          onTap: onTapPay,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                DashboardGamesCard(
                  role: controller.role.value,
                  upcomingGames: controller.upcomingGames,
                  playerCategories: controller.playerCategories,
                  onGoGamesTab: onGoGamesTab,
                  onTapGame: onTapGame,
                ),

                const SizedBox(height: 12),

                DashboardNoticesCard(
                  notices: controller.notices,
                  onGoNoticesTab: onGoNoticesTab,
                  onTapNotice: onTapNotice,
                ),

                if (controller.role.value == 'player') ...[
                  DashboardAttendanceCard(
                    attendance: controller.attendance.value,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}
