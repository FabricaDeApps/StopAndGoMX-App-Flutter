import 'club_league_overview.dart';

class ClubLeagueTournamentStandingsResponse {
  final ClubLeagueTournamentHeader tournament;
  final List<ClubLeagueStandingItem> items;

  const ClubLeagueTournamentStandingsResponse({
    required this.tournament,
    required this.items,
  });

  factory ClubLeagueTournamentStandingsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClubLeagueTournamentStandingsResponse(
      tournament: ClubLeagueTournamentHeader.fromJson(_asMap(json['tournament'])),
      items: _asList(json['items'])
          .map((item) => ClubLeagueStandingItem.fromJson(item))
          .toList(),
    );
  }
}

class ClubLeagueTournamentFixturesResponse {
  final ClubLeagueTournamentHeader tournament;
  final List<ClubLeagueFixtureItem> items;

  const ClubLeagueTournamentFixturesResponse({
    required this.tournament,
    required this.items,
  });

  factory ClubLeagueTournamentFixturesResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClubLeagueTournamentFixturesResponse(
      tournament: ClubLeagueTournamentHeader.fromJson(_asMap(json['tournament'])),
      items: _asList(json['items'])
          .map((item) => ClubLeagueFixtureItem.fromJson(item))
          .toList(),
    );
  }
}

class ClubLeagueTournamentHeader {
  final int id;
  final int leagueId;
  final String name;
  final String slug;
  final String logoUrl;
  final String status;
  final ClubLeagueSummary? league;

  const ClubLeagueTournamentHeader({
    required this.id,
    required this.leagueId,
    required this.name,
    required this.slug,
    required this.logoUrl,
    required this.status,
    required this.league,
  });

  factory ClubLeagueTournamentHeader.fromJson(Map<String, dynamic> json) {
    return ClubLeagueTournamentHeader(
      id: _asInt(json['id']),
      leagueId: _asInt(json['league_id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
      logoUrl: _asString(json['logo_url']),
      status: _asString(json['status']),
      league: json['league'] == null
          ? null
          : ClubLeagueSummary.fromJson(_asMap(json['league'])),
    );
  }
}

class ClubLeagueStandingItem {
  final int id;
  final bool isMyOrganization;
  final bool isMyTeam;
  final ClubLeagueStandingTeam team;
  final ClubLeagueDivision? division;
  final ClubLeagueDivision? subDivision;
  final ClubLeagueStandingStats stats;

  const ClubLeagueStandingItem({
    required this.id,
    required this.isMyOrganization,
    required this.isMyTeam,
    required this.team,
    required this.division,
    required this.subDivision,
    required this.stats,
  });

  factory ClubLeagueStandingItem.fromJson(Map<String, dynamic> json) {
    return ClubLeagueStandingItem(
      id: _asInt(json['id']),
      isMyOrganization: _asBool(json['is_my_organization']),
      isMyTeam: _asBool(json['is_my_team']),
      team: ClubLeagueStandingTeam.fromJson(_asMap(json['team'])),
      division: json['division'] == null
          ? null
          : ClubLeagueDivision.fromJson(_asMap(json['division'])),
      subDivision: json['sub_division'] == null
          ? null
          : ClubLeagueDivision.fromJson(_asMap(json['sub_division'])),
      stats: ClubLeagueStandingStats.fromJson(_asMap(json['stats'])),
    );
  }
}

class ClubLeagueStandingTeam {
  final int clubLinkId;
  final String name;
  final String teamSlug;
  final int organizationId;
  final String logoUrl;

  const ClubLeagueStandingTeam({
    required this.clubLinkId,
    required this.name,
    required this.teamSlug,
    required this.organizationId,
    required this.logoUrl,
  });

  factory ClubLeagueStandingTeam.fromJson(Map<String, dynamic> json) {
    return ClubLeagueStandingTeam(
      clubLinkId: _asInt(json['club_link_id']),
      name: _asString(json['name']),
      teamSlug: _asString(json['team_slug']),
      organizationId: _asInt(json['organization_id']),
      logoUrl: _asString(json['logo_url']),
    );
  }
}

class ClubLeagueStandingStats {
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final int rankPosition;

  const ClubLeagueStandingStats({
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    required this.rankPosition,
  });

  factory ClubLeagueStandingStats.fromJson(Map<String, dynamic> json) {
    return ClubLeagueStandingStats(
      played: _asInt(json['played']),
      wins: _asInt(json['wins']),
      draws: _asInt(json['draws']),
      losses: _asInt(json['losses']),
      goalsFor: _asInt(json['goals_for']),
      goalsAgainst: _asInt(json['goals_against']),
      goalDifference: _asInt(json['goal_difference']),
      points: _asInt(json['points']),
      rankPosition: _asInt(json['rank_position']),
    );
  }
}

class ClubLeagueFixtureItem {
  final int id;
  final String status;
  final String kickoffAt;
  final String venueName;
  final String venueAddress;
  final bool isMyOrganizationMatch;
  final bool isMyTeamMatch;
  final ClubLeagueMatchday? matchday;
  final ClubLeagueDivision? division;
  final ClubLeagueDivision? subDivision;
  final ClubLeagueFixtureTeam homeTeam;
  final ClubLeagueFixtureTeam awayTeam;
  final ClubLeagueFixtureScore? score;

  const ClubLeagueFixtureItem({
    required this.id,
    required this.status,
    required this.kickoffAt,
    required this.venueName,
    required this.venueAddress,
    required this.isMyOrganizationMatch,
    required this.isMyTeamMatch,
    required this.matchday,
    required this.division,
    required this.subDivision,
    required this.homeTeam,
    required this.awayTeam,
    required this.score,
  });

  factory ClubLeagueFixtureItem.fromJson(Map<String, dynamic> json) {
    return ClubLeagueFixtureItem(
      id: _asInt(json['id']),
      status: _asString(json['status']),
      kickoffAt: _asString(json['kickoff_at']),
      venueName: _asString(json['venue_name']),
      venueAddress: _asString(json['venue_address']),
      isMyOrganizationMatch: _asBool(json['is_my_organization_match']),
      isMyTeamMatch: _asBool(json['is_my_team_match']),
      matchday: json['matchday'] == null
          ? null
          : ClubLeagueMatchday.fromJson(_asMap(json['matchday'])),
      division: json['division'] == null
          ? null
          : ClubLeagueDivision.fromJson(_asMap(json['division'])),
      subDivision: json['sub_division'] == null
          ? null
          : ClubLeagueDivision.fromJson(_asMap(json['sub_division'])),
      homeTeam: ClubLeagueFixtureTeam.fromJson(_asMap(json['home_team'])),
      awayTeam: ClubLeagueFixtureTeam.fromJson(_asMap(json['away_team'])),
      score: json['score'] == null
          ? null
          : ClubLeagueFixtureScore.fromJson(_asMap(json['score'])),
    );
  }
}

class ClubLeagueMatchday {
  final int id;
  final int roundNumber;
  final String name;
  final String matchDate;

  const ClubLeagueMatchday({
    required this.id,
    required this.roundNumber,
    required this.name,
    required this.matchDate,
  });

  factory ClubLeagueMatchday.fromJson(Map<String, dynamic> json) {
    return ClubLeagueMatchday(
      id: _asInt(json['id']),
      roundNumber: _asInt(json['round_number']),
      name: _asString(json['name']),
      matchDate: _asString(json['match_date']),
    );
  }
}

class ClubLeagueFixtureTeam {
  final int clubLinkId;
  final String name;
  final int organizationId;
  final String logoUrl;
  final bool isMyTeam;
  final bool isMyOrganizationTeam;

  const ClubLeagueFixtureTeam({
    required this.clubLinkId,
    required this.name,
    required this.organizationId,
    required this.logoUrl,
    required this.isMyTeam,
    required this.isMyOrganizationTeam,
  });

  factory ClubLeagueFixtureTeam.fromJson(Map<String, dynamic> json) {
    return ClubLeagueFixtureTeam(
      clubLinkId: _asInt(json['club_link_id']),
      name: _asString(json['name']),
      organizationId: _asInt(json['organization_id']),
      logoUrl: _asString(json['logo_url']),
      isMyTeam: _asBool(json['is_my_team']),
      isMyOrganizationTeam: _asBool(json['is_my_organization_team']),
    );
  }
}

class ClubLeagueFixtureScore {
  final int? home;
  final int? away;

  const ClubLeagueFixtureScore({
    required this.home,
    required this.away,
  });

  factory ClubLeagueFixtureScore.fromJson(Map<String, dynamic> json) {
    return ClubLeagueFixtureScore(
      home: _asNullableInt(json['home']),
      away: _asNullableInt(json['away']),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), val),
    );
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, val) => MapEntry(key.toString(), val),
          ),
        )
        .toList();
  }
  return const <Map<String, dynamic>>[];
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _asString(dynamic value) => value?.toString() ?? '';
