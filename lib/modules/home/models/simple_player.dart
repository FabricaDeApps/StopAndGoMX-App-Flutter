class SimplePlayer {
  final int id;
  final String name;
  final String? avatarUrl;
  SimplePlayer({required this.id, required this.name, this.avatarUrl});
}

/// Restores a parent selection only when it is one of the Player records
/// returned by `/player/my-players`.
int? resolveAuthorizedPlayerId(
  List<SimplePlayer> players,
  int? persistedPlayerId,
) {
  if (players.isEmpty) return null;

  final isAuthorized = players.any((player) => player.id == persistedPlayerId);
  return isAuthorized ? persistedPlayerId : players.first.id;
}
