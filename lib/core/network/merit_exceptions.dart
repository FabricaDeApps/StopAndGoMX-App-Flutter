class MeritModuleUnavailableException implements Exception {
  final String message;

  const MeritModuleUnavailableException([
    this.message = 'El Programa de Meritos no esta habilitado para esta organizacion.',
  ]);

  @override
  String toString() => message;
}
