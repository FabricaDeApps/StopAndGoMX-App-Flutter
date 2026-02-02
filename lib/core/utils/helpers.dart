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
