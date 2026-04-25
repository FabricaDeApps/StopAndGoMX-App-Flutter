import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/theme/app_theme.dart';
import 'package:stopandgo/modules/home/tabs/dashboard/dashboard_tab_controller.dart';
import 'package:stopandgo/modules/home/tabs/dashboard/widgets/dashboard_attendance_card.dart';
import 'package:stopandgo/modules/home/tabs/dashboard/widgets/dashboard_social_composer.dart';

import 'widgets/dashboard_social_feed.dart';

class DashboardTabView extends GetView<DashboardTabController> {
  const DashboardTabView({
    super.key,
    required this.onTapPay,
    required this.onGoGamesTab,
    required this.onGoNoticesTab,
  });

  final VoidCallback onTapPay;
  final VoidCallback onGoGamesTab;
  final VoidCallback onGoNoticesTab;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final role = controller.role.value;
      final isPlayerOrParent = role == 'player' || role == 'parent';
      final hasAttendance = role == 'player';
      final socialPosts = controller.socialPosts.toList(growable: false);
      final showSocialModule =
          AppStorage.getOrganization()?.socialModule == true;
      final organizationName =
          AppStorage.getOrganization()?.name.trim().isNotEmpty == true
          ? AppStorage.getOrganization()!.name.trim()
          : 'Stop&Go';

      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F1E8), Color(0xFFF7F8FC), Color(0xFFEAF2F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _DashboardHero(
                    role: role,
                    pendingAmount: controller.saldoPendiente.value,
                    upcomingGamesCount: controller.upcomingGames.length,
                    noticesCount: controller.notices.length,
                    attendancePercent: controller.attendance.value.percent,
                    showPayments: isPlayerOrParent,
                    showAttendance: hasAttendance,
                    onTapPay: onTapPay,
                    onGoGamesTab: onGoGamesTab,
                    onGoNoticesTab: onGoNoticesTab,
                  ),
                ),
              ),
              if (showSocialModule)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SectionTitle(
                      eyebrow: '',
                      title: 'Tu día en $organizationName',
                      subtitle:
                          'Revisa tus próximos movimientos, novedades del equipo y actividad reciente en un solo lugar.',
                    ),
                  ),
                ),
              if (hasAttendance)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: DashboardAttendanceCard(
                      attendance: controller.attendance.value,
                    ),
                  ),
                ),
              if (showSocialModule)
                const SliverPadding(padding: EdgeInsets.only(top: 20)),
              if (showSocialModule)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyComposerDelegate(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: DashboardSocialComposerLauncher(
                        onSearchMentions: controller.searchMentionableUsers,
                        onSubmit: (caption, media, mentions) {
                          return controller.createSocialPost(
                            caption: caption,
                            media: media,
                            mentions: mentions,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              if (showSocialModule)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                  sliver: SliverToBoxAdapter(
                    child: DashboardSocialFeed(
                      posts: socialPosts,
                      onLike: controller.toggleLikePost,
                      onDeletePost: controller.deletePost,
                      onLikeComment: controller.toggleLikeComment,
                      onToggleComments: controller.toggleComments,
                      onAddComment: controller.addCommentToPost,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.role,
    required this.pendingAmount,
    required this.upcomingGamesCount,
    required this.noticesCount,
    required this.attendancePercent,
    required this.showPayments,
    required this.showAttendance,
    required this.onTapPay,
    required this.onGoGamesTab,
    required this.onGoNoticesTab,
  });

  final String role;
  final double pendingAmount;
  final int upcomingGamesCount;
  final int noticesCount;
  final double attendancePercent;
  final bool showPayments;
  final bool showAttendance;
  final VoidCallback onTapPay;
  final VoidCallback onGoGamesTab;
  final VoidCallback onGoNoticesTab;

  static final NumberFormat _money = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (primaryColor, secondaryColor) = AppTheme.currentColors;
    final title = switch (role) {
      'manager' => 'Panel de coordinación',
      'coach' => 'Pulso del equipo',
      'staff' => 'Resumen operativo',
      'parent' => 'Actividad de tus jugadores',
      'player' => 'Tu semana deportiva',
      _ => 'Dashboard',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Color.lerp(primaryColor, Colors.black, 0.28) ?? primaryColor,
            Color.lerp(primaryColor, secondaryColor, 0.45) ?? primaryColor,
            Color.lerp(secondaryColor, Colors.white, 0.12) ?? secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 30,
            offset: Offset(0, 18),
            color: Color(0x26122B39),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Dashboard Live',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.auto_awesome, color: Colors.amber.shade200),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroStatChip(
                icon: Icons.sports_football,
                label: 'Próximos juegos',
                value: '$upcomingGamesCount',
                onTap: onGoGamesTab,
              ),
              _HeroStatChip(
                icon: Icons.campaign_outlined,
                label: 'Avisos',
                value: '$noticesCount',
                onTap: onGoNoticesTab,
              ),
              if (showAttendance)
                _HeroStatChip(
                  icon: Icons.fact_check_outlined,
                  label: 'Asistencia',
                  value:
                      '${attendancePercent.isFinite ? attendancePercent.toStringAsFixed(0) : '0'}%',
                ),
            ],
          ),
          if (showPayments) ...[
            const SizedBox(height: 18),
            InkWell(
              onTap: onTapPay,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8E7D8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.wallet_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pagos pendientes',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _money.format(pendingAmount),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow.trim().isNotEmpty) ...[
          Text(
            eyebrow.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              color: const Color(0xFFD66A3C),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

class _StickyComposerDelegate extends SliverPersistentHeaderDelegate {
  _StickyComposerDelegate({required this.child});

  final Widget child;

  static const double _height = 194;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF7F8FC),
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyComposerDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
