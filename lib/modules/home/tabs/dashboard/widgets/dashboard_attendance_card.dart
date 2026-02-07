import 'package:flutter/material.dart';
import 'package:stopandgo/core/models/attendance_dashboard.dart';
import 'package:stopandgo/core/widgets/cards.dart';

class DashboardAttendanceCard extends StatelessWidget {
  const DashboardAttendanceCard({super.key, required this.attendance});

  final AttendanceDashboard attendance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final percent = attendance.percent;
    final safePercent = percent.isFinite ? percent.clamp(0.0, 100.0) : 0.0;
    final marked = attendance.trainingsMarkedTotal;

    String subtitle;
    if (marked <= 0) {
      subtitle = 'Aún no hay asistencias registradas';
    } else {
      subtitle =
          'Presente: ${attendance.present} · Falta: ${attendance.absent} · Justificada: ${attendance.justified}';
    }

    return MiniCard(
      title: 'Asistencia a entrenamientos',
      withNext: false,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marked <= 0 ? '0%' : '${safePercent.toStringAsFixed(1)}%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
                if (marked > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: safePercent / 100,
                      minHeight: 8,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.fact_check_outlined, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}
