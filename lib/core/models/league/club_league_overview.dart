class ClubLeagueOverviewResponse {
  final int organizationId;
  final int viewerId;
  final List<ClubLeagueOverviewItem> items;

  const ClubLeagueOverviewResponse({
    required this.organizationId,
    required this.viewerId,
    required this.items,
  });

  bool get hasAvailableTournaments =>
      items.any((item) => item.tournaments.isNotEmpty);

  factory ClubLeagueOverviewResponse.fromJson(Map<String, dynamic> json) {
    return ClubLeagueOverviewResponse(
      organizationId: _asInt(json['organization_id']),
      viewerId: _asInt(json['viewer_id']),
      items: _asList(json['items'])
          .map((item) => ClubLeagueOverviewItem.fromJson(item))
          .toList(),
    );
  }
}

class ClubLeagueOverviewItem {
  final ClubLeagueSummary league;
  final List<ClubLeagueTeam> teams;
  final List<ClubLeagueTournament> tournaments;

  const ClubLeagueOverviewItem({
    required this.league,
    required this.teams,
    required this.tournaments,
  });

  factory ClubLeagueOverviewItem.fromJson(Map<String, dynamic> json) {
    return ClubLeagueOverviewItem(
      league: ClubLeagueSummary.fromJson(_asMap(json['league'])),
      teams: _asList(json['teams'])
          .map((team) => ClubLeagueTeam.fromJson(team))
          .toList(),
      tournaments: _asList(json['tournaments'])
          .map((tournament) => ClubLeagueTournament.fromJson(tournament))
          .toList(),
    );
  }
}

class ClubLeagueSummary {
  final int id;
  final String name;
  final String slug;
  final String logoUrl;
  final String status;
  final String seasonLabel;

  const ClubLeagueSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.logoUrl,
    required this.status,
    required this.seasonLabel,
  });

  factory ClubLeagueSummary.fromJson(Map<String, dynamic> json) {
    return ClubLeagueSummary(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
      logoUrl: _asString(json['logo_url']),
      status: _asString(json['status']),
      seasonLabel: _asString(json['season_label']),
    );
  }
}

class ClubLeagueOrganizationSummary {
  final int id;
  final String name;
  final String slug;
  final String city;
  final String logoUrl;

  const ClubLeagueOrganizationSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.city,
    required this.logoUrl,
  });

  factory ClubLeagueOrganizationSummary.fromJson(Map<String, dynamic> json) {
    return ClubLeagueOrganizationSummary(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
      city: _asString(json['city']),
      logoUrl: _asString(json['logo_url']),
    );
  }
}

class ClubLeagueTeam {
  final int clubLinkId;
  final String teamName;
  final String teamSlug;
  final ClubLeagueOrganizationSummary? organization;
  final ClubLeagueSummary? league;

  const ClubLeagueTeam({
    required this.clubLinkId,
    required this.teamName,
    required this.teamSlug,
    this.organization,
    this.league,
  });

  factory ClubLeagueTeam.fromJson(Map<String, dynamic> json) {
    return ClubLeagueTeam(
      clubLinkId: _asInt(json['club_link_id']),
      teamName: _asString(json['team_name']),
      teamSlug: _asString(json['team_slug']),
      organization: json['organization'] == null
          ? null
          : ClubLeagueOrganizationSummary.fromJson(
              _asMap(json['organization'])),
      league: json['league'] == null
          ? null
          : ClubLeagueSummary.fromJson(_asMap(json['league'])),
    );
  }
}

class ClubLeagueTournament {
  final int id;
  final String name;
  final String slug;
  final String logoUrl;
  final String status;
  final String? rosterDeadlineAt;
  final String? startsAt;
  final String? endsAt;
  final List<ClubLeagueTournamentTeam> teams;

  const ClubLeagueTournament({
    required this.id,
    required this.name,
    required this.slug,
    required this.logoUrl,
    required this.status,
    required this.rosterDeadlineAt,
    required this.startsAt,
    required this.endsAt,
    required this.teams,
  });

  factory ClubLeagueTournament.fromJson(Map<String, dynamic> json) {
    return ClubLeagueTournament(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
      logoUrl: _asString(json['logo_url']),
      status: _asString(json['status']),
      rosterDeadlineAt: _asNullableString(json['roster_deadline_at']),
      startsAt: _asNullableString(json['starts_at']),
      endsAt: _asNullableString(json['ends_at']),
      teams: _asList(json['teams'])
          .map((team) => ClubLeagueTournamentTeam.fromJson(team))
          .toList(),
    );
  }
}

class ClubLeagueTournamentTeam {
  final ClubLeagueTournamentTeamInfo team;
  final List<ClubLeagueDivisionEntry> divisionEntries;

  const ClubLeagueTournamentTeam({
    required this.team,
    required this.divisionEntries,
  });

  factory ClubLeagueTournamentTeam.fromJson(Map<String, dynamic> json) {
    return ClubLeagueTournamentTeam(
      team: ClubLeagueTournamentTeamInfo.fromJson(_asMap(json['team'])),
      divisionEntries: _asList(json['division_entries'])
          .map((entry) => ClubLeagueDivisionEntry.fromJson(entry))
          .toList(),
    );
  }
}

class ClubLeagueTournamentTeamInfo {
  final int clubLinkId;
  final String teamName;
  final String teamSlug;

  const ClubLeagueTournamentTeamInfo({
    required this.clubLinkId,
    required this.teamName,
    required this.teamSlug,
  });

  factory ClubLeagueTournamentTeamInfo.fromJson(Map<String, dynamic> json) {
    return ClubLeagueTournamentTeamInfo(
      clubLinkId: _asInt(json['club_link_id']),
      teamName: _asString(json['team_name']),
      teamSlug: _asString(json['team_slug']),
    );
  }
}

class ClubLeagueDivisionEntry {
  final ClubLeagueDivision division;
  final ClubLeagueDivision? subDivision;

  const ClubLeagueDivisionEntry({
    required this.division,
    required this.subDivision,
  });

  factory ClubLeagueDivisionEntry.fromJson(Map<String, dynamic> json) {
    return ClubLeagueDivisionEntry(
      division: ClubLeagueDivision.fromJson(_asMap(json['division'])),
      subDivision: json['sub_division'] == null
          ? null
          : ClubLeagueDivision.fromJson(_asMap(json['sub_division'])),
    );
  }
}

class ClubLeagueDivision {
  final int id;
  final String name;
  final String slug;

  const ClubLeagueDivision({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ClubLeagueDivision.fromJson(Map<String, dynamic> json) {
    return ClubLeagueDivision(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _asString(dynamic value) => value?.toString() ?? '';

String? _asNullableString(dynamic value) {
  final parsed = value?.toString().trim();
  if (parsed == null || parsed.isEmpty || parsed == 'null') return null;
  return parsed;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList();
}
