enum PlaySport { flagFootball, americanFootball }

enum PlaySide { offense, defense }

enum PlayType { run, pass, rpo, playAction, screen, trick, blitz, coverage }

String playSportLabel(PlaySport sport) {
  switch (sport) {
    case PlaySport.flagFootball:
      return 'Flag Football';
    case PlaySport.americanFootball:
      return 'Football Americano';
  }
}

String playSideLabel(PlaySide side) {
  switch (side) {
    case PlaySide.offense:
      return 'Ofensiva';
    case PlaySide.defense:
      return 'Defensiva';
  }
}

String playTypeLabel(PlayType type) {
  switch (type) {
    case PlayType.run:
      return 'Carrera';
    case PlayType.pass:
      return 'Pase';
    case PlayType.rpo:
      return 'RPO';
    case PlayType.playAction:
      return 'Play Action';
    case PlayType.screen:
      return 'Screen';
    case PlayType.trick:
      return 'Trick / Engaño';
    case PlayType.blitz:
      return 'Blitz';
    case PlayType.coverage:
      return 'Cobertura';
  }
}

List<PlayType> playTypeOptions({
  required PlaySport? sport,
  required PlaySide? side,
}) {
  if (side == null) return PlayType.values;

  if (side == PlaySide.offense) {
    if (sport == PlaySport.flagFootball) {
      return [
        PlayType.run,
        PlayType.pass,
        PlayType.rpo,
        PlayType.screen,
        PlayType.trick,
      ];
    }

    return [
      PlayType.run,
      PlayType.pass,
      PlayType.rpo,
      PlayType.playAction,
      PlayType.screen,
      PlayType.trick,
    ];
  }

  return [PlayType.blitz, PlayType.coverage];
}

int suggestedPlayersCountForSport(PlaySport? sport) {
  switch (sport) {
    case PlaySport.americanFootball:
      return 11;
    case PlaySport.flagFootball:
    default:
      return 7;
  }
}
