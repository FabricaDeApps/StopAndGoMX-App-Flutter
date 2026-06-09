class SocialAuthCancelledException implements Exception {
  const SocialAuthCancelledException();
}

class SocialAuthConfigurationException implements Exception {
  const SocialAuthConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}
