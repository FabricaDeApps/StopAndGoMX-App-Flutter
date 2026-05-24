import 'club_league_overview.dart';
import 'club_league_tournament_data.dart';

class ClubLeagueTeamDetailResponse {
  final ClubLeagueTeam team;
  final List<ClubLeagueTeamTournamentDetail> tournaments;

  const ClubLeagueTeamDetailResponse({
    required this.team,
    required this.tournaments,
  });

  factory ClubLeagueTeamDetailResponse.fromJson(Map<String, dynamic> json) {
    return ClubLeagueTeamDetailResponse(
      team: ClubLeagueTeam.fromJson(_asMap(json['team'])),
      tournaments: _asList(json['tournaments'])
          .map((item) => ClubLeagueTeamTournamentDetail.fromJson(item))
          .toList(),
    );
  }
}

class ClubLeagueTeamTournamentDetail {
  final int id;
  final String name;
  final String slug;
  final String logoUrl;
  final String status;
  final String? rosterDeadlineAt;
  final String? startsAt;
  final String? endsAt;
  final List<ClubLeagueDivisionEntry> divisionEntries;

  const ClubLeagueTeamTournamentDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.logoUrl,
    required this.status,
    required this.rosterDeadlineAt,
    required this.startsAt,
    required this.endsAt,
    required this.divisionEntries,
  });

  factory ClubLeagueTeamTournamentDetail.fromJson(Map<String, dynamic> json) {
    return ClubLeagueTeamTournamentDetail(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
      logoUrl: _asString(json['logo_url']),
      status: _asString(json['status']),
      rosterDeadlineAt: _asNullableString(json['roster_deadline_at']),
      startsAt: _asNullableString(json['starts_at']),
      endsAt: _asNullableString(json['ends_at']),
      divisionEntries: _asList(json['division_entries'])
          .map((item) => ClubLeagueDivisionEntry.fromJson(item))
          .toList(),
    );
  }
}

class ClubLeagueRosterSourceResponse {
  final ClubLeagueRosterTeamSummary team;
  final ClubLeagueCategorySummary? category;
  final List<ClubLeagueRosterSourcePlayer> items;
  final ClubLeagueRosterCatalogs catalogs;

  const ClubLeagueRosterSourceResponse({
    required this.team,
    required this.category,
    required this.items,
    required this.catalogs,
  });

  factory ClubLeagueRosterSourceResponse.fromJson(Map<String, dynamic> json) {
    return ClubLeagueRosterSourceResponse(
      team: ClubLeagueRosterTeamSummary.fromJson(_asMap(json['team'])),
      category: json['category'] == null
          ? null
          : ClubLeagueCategorySummary.fromJson(_asMap(json['category'])),
      items: _asList(json['items'])
          .map((item) => ClubLeagueRosterSourcePlayer.fromJson(item))
          .toList(),
      catalogs: ClubLeagueRosterCatalogs.fromJson(_asMap(json['catalogs'])),
    );
  }
}

class ClubLeagueRosterEntriesResponse {
  final ClubLeagueRosterTeamSummary team;
  final ClubLeagueTeamRosterTournament tournament;
  final List<ClubLeagueRosterEntry> items;

  const ClubLeagueRosterEntriesResponse({
    required this.team,
    required this.tournament,
    required this.items,
  });

  factory ClubLeagueRosterEntriesResponse.fromJson(Map<String, dynamic> json) {
    return ClubLeagueRosterEntriesResponse(
      team: ClubLeagueRosterTeamSummary.fromJson(_asMap(json['team'])),
      tournament: ClubLeagueTeamRosterTournament.fromJson(
        _asMap(json['tournament']),
      ),
      items: _asList(json['items'])
          .map((item) => ClubLeagueRosterEntry.fromJson(item))
          .toList(),
    );
  }
}

class ClubLeagueRosterSyncResponse {
  final String message;
  final ClubLeagueRosterTeamSummary team;
  final ClubLeagueTournamentHeader tournament;
  final ClubLeagueDivision? division;
  final ClubLeagueDivision? subDivision;
  final ClubLeagueRosterSyncSummary summary;

  const ClubLeagueRosterSyncResponse({
    required this.message,
    required this.team,
    required this.tournament,
    required this.division,
    required this.subDivision,
    required this.summary,
  });

  factory ClubLeagueRosterSyncResponse.fromJson(Map<String, dynamic> json) {
    return ClubLeagueRosterSyncResponse(
      message: _asString(json['message']),
      team: ClubLeagueRosterTeamSummary.fromJson(_asMap(json['team'])),
      tournament: ClubLeagueTournamentHeader.fromJson(_asMap(json['tournament'])),
      division: json['division'] == null
          ? null
          : ClubLeagueDivision.fromJson(_asMap(json['division'])),
      subDivision: json['sub_division'] == null
          ? null
          : ClubLeagueDivision.fromJson(_asMap(json['sub_division'])),
      summary: ClubLeagueRosterSyncSummary.fromJson(_asMap(json['summary'])),
    );
  }
}

class ClubLeagueRosterSyncSummary {
  final int total;
  final int createdCount;
  final int updatedCount;
  final int deletedCount;

  const ClubLeagueRosterSyncSummary({
    required this.total,
    required this.createdCount,
    required this.updatedCount,
    required this.deletedCount,
  });

  factory ClubLeagueRosterSyncSummary.fromJson(Map<String, dynamic> json) {
    return ClubLeagueRosterSyncSummary(
      total: _asInt(json['total']),
      createdCount: _asInt(json['created_count']),
      updatedCount: _asInt(json['updated_count']),
      deletedCount: _asInt(json['deleted_count']),
    );
  }
}

class ClubLeagueRosterTeamSummary {
  final int clubLinkId;
  final String teamName;

  const ClubLeagueRosterTeamSummary({
    required this.clubLinkId,
    required this.teamName,
  });

  factory ClubLeagueRosterTeamSummary.fromJson(Map<String, dynamic> json) {
    return ClubLeagueRosterTeamSummary(
      clubLinkId: _asInt(json['club_link_id']),
      teamName: _asString(json['team_name']),
    );
  }
}

class ClubLeagueCategorySummary {
  final int id;
  final String name;
  final String slug;

  const ClubLeagueCategorySummary({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ClubLeagueCategorySummary.fromJson(Map<String, dynamic> json) {
    return ClubLeagueCategorySummary(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
    );
  }
}

class ClubLeagueRosterCatalogs {
  final List<ClubLeaguePositionOption> positions;

  const ClubLeagueRosterCatalogs({
    required this.positions,
  });

  factory ClubLeagueRosterCatalogs.fromJson(Map<String, dynamic> json) {
    return ClubLeagueRosterCatalogs(
      positions: _asList(json['positions'])
          .map((item) => ClubLeaguePositionOption.fromJson(item))
          .toList(),
    );
  }
}

class ClubLeaguePositionOption {
  final int id;
  final String code;
  final String name;

  const ClubLeaguePositionOption({
    required this.id,
    required this.code,
    required this.name,
  });

  factory ClubLeaguePositionOption.fromJson(Map<String, dynamic> json) {
    return ClubLeaguePositionOption(
      id: _asInt(json['id']),
      code: _asString(json['code']),
      name: _asString(json['name']),
    );
  }

  String get label {
    if (code.trim().isEmpty) return name;
    if (name.trim().isEmpty) return code;
    return '$code • $name';
  }
}

class ClubLeagueRosterSourcePlayer {
  final int playerId;
  final String firstName;
  final String lastName;
  final String displayName;
  final String email;
  final String phone;
  final String avatarUrl;
  final String position;
  final int? positionId;
  final int? categoryJerseyNumber;
  final int? latestLeagueJerseyNumber;
  final ClubLeagueRosterCurrentEntry? currentEntry;

  const ClubLeagueRosterSourcePlayer({
    required this.playerId,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.position,
    required this.positionId,
    required this.categoryJerseyNumber,
    required this.latestLeagueJerseyNumber,
    required this.currentEntry,
  });

  factory ClubLeagueRosterSourcePlayer.fromJson(Map<String, dynamic> json) {
    return ClubLeagueRosterSourcePlayer(
      playerId: _asInt(json['player_id']),
      firstName: _asString(json['first_name']),
      lastName: _asString(json['last_name']),
      displayName: _asString(json['display_name']),
      email: _asString(json['email']),
      phone: _asString(json['phone']),
      avatarUrl: _asString(json['avatar_url']),
      position: _asString(json['position']),
      positionId: _asNullableInt(json['position_id']),
      categoryJerseyNumber: _asNullableInt(json['category_jersey_number']),
      latestLeagueJerseyNumber: _asNullableInt(json['latest_league_jersey_number']),
      currentEntry: json['current_entry'] == null
          ? null
          : ClubLeagueRosterCurrentEntry.fromJson(_asMap(json['current_entry'])),
    );
  }
}

class ClubLeagueRosterCurrentEntry {
  final int? jerseyNumber;
  final String position;
  final int? positionId;

  const ClubLeagueRosterCurrentEntry({
    required this.jerseyNumber,
    required this.position,
    required this.positionId,
  });

  factory ClubLeagueRosterCurrentEntry.fromJson(Map<String, dynamic> json) {
    return ClubLeagueRosterCurrentEntry(
      jerseyNumber: _asNullableInt(json['jersey_number']),
      position: _asString(json['position']),
      positionId: _asNullableInt(json['position_id']),
    );
  }
}

class ClubLeagueTeamRosterTournament {
  final int id;
  final String name;
  final String slug;
  final String logoUrl;
  final String status;
  final String? rosterDeadlineAt;
  final ClubLeagueSummary? league;

  const ClubLeagueTeamRosterTournament({
    required this.id,
    required this.name,
    required this.slug,
    required this.logoUrl,
    required this.status,
    required this.rosterDeadlineAt,
    required this.league,
  });

  factory ClubLeagueTeamRosterTournament.fromJson(Map<String, dynamic> json) {
    return ClubLeagueTeamRosterTournament(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
      logoUrl: _asString(json['logo_url']),
      status: _asString(json['status']),
      rosterDeadlineAt: _asNullableString(json['roster_deadline_at']),
      league: json['league'] == null
          ? null
          : ClubLeagueSummary.fromJson(_asMap(json['league'])),
    );
  }
}

class ClubLeagueRosterEntry {
  final int id;
  final int leagueId;
  final int tournamentId;
  final ClubLeagueDivision? division;
  final ClubLeagueDivision? subDivision;
  final int clubLinkId;
  final ClubLeagueRosterEntryPlayer player;
  final int? jerseyNumber;
  final String position;
  final int? positionId;
  final String status;
  final String source;
  final String createdAt;
  final String updatedAt;

  const ClubLeagueRosterEntry({
    required this.id,
    required this.leagueId,
    required this.tournamentId,
    required this.division,
    required this.subDivision,
    required this.clubLinkId,
    required this.player,
    required this.jerseyNumber,
    required this.position,
    required this.positionId,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClubLeagueRosterEntry.fromJson(Map<String, dynamic> json) {
    return ClubLeagueRosterEntry(
      id: _asInt(json['id']),
      leagueId: _asInt(json['league_id']),
      tournamentId: _asInt(json['tournament_id']),
      division: json['division'] == null
          ? null
          : ClubLeagueDivision.fromJson(_asMap(json['division'])),
      subDivision: json['sub_division'] == null
          ? null
          : ClubLeagueDivision.fromJson(_asMap(json['sub_division'])),
      clubLinkId: _asInt(json['club_link_id']),
      player: ClubLeagueRosterEntryPlayer.fromJson(_asMap(json['player'])),
      jerseyNumber: _asNullableInt(json['jersey_number']),
      position: _asString(json['position']),
      positionId: _asNullableInt(json['position_id']),
      status: _asString(json['status']),
      source: _asString(json['source']),
      createdAt: _asString(json['created_at']),
      updatedAt: _asString(json['updated_at']),
    );
  }
}

class ClubLeagueRosterEntryPlayer {
  final int id;
  final String firstName;
  final String lastName;
  final String displayName;
  final String email;
  final String phone;
  final String avatarUrl;

  const ClubLeagueRosterEntryPlayer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
  });

  factory ClubLeagueRosterEntryPlayer.fromJson(Map<String, dynamic> json) {
    return ClubLeagueRosterEntryPlayer(
      id: _asInt(json['id']),
      firstName: _asString(json['first_name']),
      lastName: _asString(json['last_name']),
      displayName: _asString(json['display_name']),
      email: _asString(json['email']),
      phone: _asString(json['phone']),
      avatarUrl: _asString(json['avatar_url']),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => item.map((key, val) => MapEntry(key.toString(), val)))
        .toList();
  }
  return const <Map<String, dynamic>>[];
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

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
