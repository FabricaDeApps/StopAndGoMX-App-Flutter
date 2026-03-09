class GazettaModuleUnavailableException implements Exception {
  final String message;

  const GazettaModuleUnavailableException([
    this.message = 'Módulo Gazzetta no disponible para esta organización.',
  ]);

  @override
  String toString() => message;
}
