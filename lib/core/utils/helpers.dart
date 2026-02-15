String gameStatusLabel(String? status) {
  switch (status) {
    case 'scheduled':
      return 'Programado';
    case 'live':
      return 'En vivo';
    case 'finished':
      return 'Finalizado';
    case 'canceled':
      return 'Cancelado';
    case 'postponed':
      return 'Pospuesto';
    case 'suspended':
      return 'Suspendido';
    default:
      return status?.toUpperCase() ?? '—';
  }
}

String getLabelRol(String? role) {
  final value = (role ?? '').trim().toLowerCase();
  switch (value) {
    case 'manager':
      return 'Manager';
    case 'coach':
      return 'Coach';
    case 'staff':
      return 'Staff';
    case 'parent':
      return 'Padre/Madre';
    case 'player':
      return 'Jugador';
    case 'admin':
      return 'Administrador';
    default:
      if (value.isEmpty) return '';
      return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
