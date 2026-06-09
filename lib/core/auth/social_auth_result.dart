enum SocialAuthProvider {
  google,
  apple;

  String get apiValue => switch (this) {
    SocialAuthProvider.google => 'google',
    SocialAuthProvider.apple => 'apple',
  };
}

class SocialAuthResult {
  const SocialAuthResult({
    required this.provider,
    required this.firebaseIdToken,
    required this.email,
    required this.displayName,
    this.authorizationCode,
  });

  final SocialAuthProvider provider;
  final String firebaseIdToken;
  final String email;
  final String displayName;
  final String? authorizationCode;
}
