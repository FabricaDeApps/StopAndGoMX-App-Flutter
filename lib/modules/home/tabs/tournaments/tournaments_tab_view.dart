import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stopandgo/core/models/league/club_league_overview.dart';
import 'package:stopandgo/core/models/league/club_league_roster_models.dart';
import 'package:stopandgo/core/models/league/club_league_tournament_data.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/utils/role_utils.dart';
import 'package:stopandgo/modules/home/home_controller.dart';

class TournamentsTabView extends GetView<HomeController> {
  const TournamentsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final overview = controller.leagueOverview.value;
      final isLoading = controller.isLoadingLeagueModule.value;
      final error = controller.leagueModuleError.value;

      if (isLoading && overview == null) {
        return const Center(child: CircularProgressIndicator());
      }

      if (overview == null) {
        return _StateMessage(
          icon: Icons.emoji_events_outlined,
          title: 'Sin torneos disponibles',
          body: error == null
              ? 'Esta organizacion todavia no tiene torneos activos para mostrar.'
              : 'No se pudo cargar el modulo de torneos.',
          actionLabel: 'Reintentar',
          onPressed: controller.refreshLeagueModule,
        );
      }

      if (overview.items.isEmpty || !overview.hasAvailableTournaments) {
        return _StateMessage(
          icon: Icons.emoji_events_outlined,
          title: 'Sin torneos disponibles',
          body:
              'Cuando la organizacion tenga ligas o torneos enrolados, apareceran aqui.',
          actionLabel: 'Actualizar',
          onPressed: controller.refreshLeagueModule,
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshLeagueModule,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Torneos',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ligas y torneos competitivos disponibles para tu organizacion.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: controller.refreshLeagueModule,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...overview.items.map((item) => _LeagueCard(item: item)),
          ],
        ),
      );
    });
  }
}

class _LeagueCard extends StatelessWidget {
  final ClubLeagueOverviewItem item;

  const _LeagueCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NetworkLogo(
                  url: item.league.logoUrl,
                  size: 52,
                  icon: Icons.shield_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.league.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (item.league.seasonLabel.isNotEmpty)
                            Chip(label: Text(item.league.seasonLabel)),
                          if (item.league.status.isNotEmpty)
                            Chip(label: Text(_labelize(item.league.status))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.teams.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Equipos competitivos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...item.teams.map(
                (team) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NetworkLogo(
                        url:
                            team.organization?.logoUrl ??
                            team.league?.logoUrl ??
                            '',
                        size: 28,
                        icon: Icons.groups_2_outlined,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.teamName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if ((team.organization?.name ?? '').isNotEmpty)
                              Text(
                                team.organization!.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (item.tournaments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Torneos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...item.tournaments.map(
                (tournament) => _TournamentTile(
                  league: item.league,
                  tournament: tournament,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TournamentTile extends StatelessWidget {
  final ClubLeagueSummary league;
  final ClubLeagueTournament tournament;

  const _TournamentTile({
    required this.league,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Get.to(
              () => TournamentDetailPage(
                league: league,
                tournament: tournament,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NetworkLogo(
                      url: tournament.logoUrl,
                      size: 42,
                      icon: Icons.emoji_events_outlined,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (tournament.status.isNotEmpty)
                                Chip(label: Text(_labelize(tournament.status))),
                              if (tournament.startsAt != null)
                                Chip(
                                  label: Text(
                                    'Inicio ${_formatDate(tournament.startsAt)}',
                                  ),
                                ),
                              if (tournament.rosterDeadlineAt != null)
                                Chip(
                                  label: Text(
                                    'Roster ${_formatDate(
                                      tournament.rosterDeadlineAt,
                                    )}',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                if (tournament.teams.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...tournament.teams.map(
                    (team) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _teamSummary(team),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Ver tabla general y calendario del torneo.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _teamSummary(ClubLeagueTournamentTeam team) {
    final divisions = team.divisionEntries
        .map((entry) {
          final subDivision = entry.subDivision?.name.trim();
          if (subDivision != null && subDivision.isNotEmpty) {
            return '${entry.division.name} / $subDivision';
          }
          return entry.division.name;
        })
        .where((value) => value.trim().isNotEmpty)
        .join(', ');

    if (divisions.isEmpty) return team.team.teamName;
    return '${team.team.teamName} • $divisions';
  }
}

class TournamentDetailPage extends StatefulWidget {
  final ClubLeagueSummary league;
  final ClubLeagueTournament tournament;

  const TournamentDetailPage({
    super.key,
    required this.league,
    required this.tournament,
  });

  @override
  State<TournamentDetailPage> createState() => _TournamentDetailPageState();
}

class _TournamentDetailPageState extends State<TournamentDetailPage> {
  final ApiRepository _api = Get.find<ApiRepository>();
  late final String _viewerRole;
  late final String _organizationName;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _rosterSearchController =
      TextEditingController();

  ClubLeagueTournamentStandingsResponse? _standings;
  ClubLeagueTournamentFixturesResponse? _fixtures;
  String? _error;
  bool _isLoading = true;
  int? _selectedClubLinkId;
  String _searchQuery = '';
  String _rosterSearchQuery = '';
  String? _selectedRosterCategoryKey;
  ClubLeagueTeamDetailResponse? _teamDetail;
  ClubLeagueRosterSourceResponse? _rosterSource;
  ClubLeagueRosterEntriesResponse? _rosterEntries;
  String? _rosterError;
  bool _isRosterLoading = false;
  bool _isSendingRoster = false;
  final Map<int, _RosterDraft> _rosterDrafts = {};

  List<ClubLeagueTournamentTeam> get _teams => widget.tournament.teams;
  bool get _canManageRoster => canEditRosterPosition(_viewerRole);
  ClubLeagueTournamentTeam? get _selectedTeam {
    for (final team in _teams) {
      if (team.team.clubLinkId == _selectedClubLinkId) return team;
    }
    return null;
  }

  List<_CategoryOption> get _rosterCategoryOptions {
    final entries = _selectedTeamDivisionEntries;
    return entries
        .map(
          (entry) => _CategoryOption(
            key: _categoryKey(entry.division.id, entry.subDivision?.id),
            label: _divisionLabel(entry.division, entry.subDivision),
            division: entry.division,
            subDivision: entry.subDivision,
          ),
        )
        .toList();
  }

  List<ClubLeagueDivisionEntry> get _selectedTeamDivisionEntries {
    ClubLeagueTeamTournamentDetail? tournamentFromDetail;
    for (final item in _teamDetail?.tournaments ?? const <ClubLeagueTeamTournamentDetail>[]) {
      if (item.id == widget.tournament.id) {
        tournamentFromDetail = item;
        break;
      }
    }

    if (tournamentFromDetail != null && tournamentFromDetail.divisionEntries.isNotEmpty) {
      return tournamentFromDetail.divisionEntries;
    }

    return _selectedTeam?.divisionEntries ?? const <ClubLeagueDivisionEntry>[];
  }

  _CategoryOption? get _selectedRosterCategory {
    if (_selectedRosterCategoryKey == null) return null;
    for (final option in _rosterCategoryOptions) {
      if (option.key == _selectedRosterCategoryKey) return option;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final user = AppStorage.getUser();
    _organizationName = AppStorage.getOrganization()?.name.trim() ?? '';
    _viewerRole = normalizeRole(
      user?.activeRole.isNotEmpty == true ? user!.activeRole : user?.role,
    );
    if (_teams.isNotEmpty) {
      _selectedClubLinkId = _teams.first.team.clubLinkId;
    }
    _syncRosterCategoryWithSelection();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rosterSearchController.dispose();
    _clearRosterDrafts();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getClubLeagueTournamentStandings(
          widget.tournament.id,
          clubLinkId: _selectedClubLinkId,
        ),
        _api.getClubLeagueTournamentFixtures(
          widget.tournament.id,
          clubLinkId: _selectedClubLinkId,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _standings = results[0] as ClubLeagueTournamentStandingsResponse;
        _fixtures = results[1] as ClubLeagueTournamentFixturesResponse;
        _isLoading = false;
      });

      if (_canManageRoster) {
        await _loadRosterData();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRosterData() async {
    if (!_canManageRoster) return;
    final clubLinkId = _selectedClubLinkId;
    final category = _selectedRosterCategory;

    if (clubLinkId == null || category == null) {
      if (!mounted) return;
      setState(() {
        _teamDetail = null;
        _rosterSource = null;
        _rosterEntries = null;
        _rosterError = null;
        _isRosterLoading = false;
      });
      _clearRosterDrafts();
      return;
    }

    setState(() {
      _isRosterLoading = true;
      _rosterError = null;
    });

    try {
      final results = await Future.wait([
        _api.getClubLeagueTeamDetail(clubLinkId),
        _api.getClubLeagueRosterSource(
          clubLinkId,
          tournamentId: widget.tournament.id,
          divisionId: category.division?.id,
          subDivisionId: category.subDivision?.id,
        ),
        _api.getClubLeagueRosterEntries(
          widget.tournament.id,
          clubLinkId,
          divisionId: category.division?.id,
          subDivisionId: category.subDivision?.id,
        ),
      ]);

      if (!mounted) return;

      final rosterSource = results[1] as ClubLeagueRosterSourceResponse;
      setState(() {
        _teamDetail = results[0] as ClubLeagueTeamDetailResponse;
        _rosterSource = rosterSource;
        _rosterEntries = results[2] as ClubLeagueRosterEntriesResponse;
        _isRosterLoading = false;
      });
      _initializeRosterDrafts(rosterSource);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rosterError = e.toString();
        _isRosterLoading = false;
      });
      _clearRosterDrafts();
    }
  }

  void _syncRosterCategoryWithSelection() {
    final options = _rosterCategoryOptions;
    if (options.isEmpty) {
      _selectedRosterCategoryKey = null;
      return;
    }

    final currentKey = _selectedRosterCategoryKey;
    final hasCurrent = currentKey != null &&
        options.any((option) => option.key == currentKey);
    if (!hasCurrent) {
      _selectedRosterCategoryKey = options.first.key;
    }
  }

  void _initializeRosterDrafts(ClubLeagueRosterSourceResponse source) {
    _clearRosterDrafts();

    for (final item in source.items) {
      final preferredJersey =
          item.currentEntry?.jerseyNumber ??
          item.latestLeagueJerseyNumber ??
          item.categoryJerseyNumber;
      final preferredPositionId = item.currentEntry?.positionId ?? item.positionId;
      final preferredCustomPosition =
          preferredPositionId != null
              ? ''
              : item.currentEntry?.position.trim().isNotEmpty == true
              ? item.currentEntry!.position
              : item.position;

      _rosterDrafts[item.playerId] = _RosterDraft(
        selected: item.currentEntry != null,
        jerseyController: TextEditingController(
          text: preferredJersey?.toString() ?? '',
        ),
        positionId: preferredPositionId,
        customPosition: preferredCustomPosition,
      );
    }
  }

  void _clearRosterDrafts() {
    for (final draft in _rosterDrafts.values) {
      draft.dispose();
    }
    _rosterDrafts.clear();
  }

  Future<void> _sendRoster() async {
    final category = _selectedRosterCategory;
    final source = _rosterSource;

    if (category == null || source == null || _selectedClubLinkId == null) {
      return;
    }

    final selectedDrafts = <MapEntry<ClubLeagueRosterSourcePlayer, _RosterDraft>>[];
    for (final player in source.items) {
      final draft = _rosterDrafts[player.playerId];
      if (draft != null && draft.selected) {
        selectedDrafts.add(MapEntry(player, draft));
      }
    }

    if (selectedDrafts.isEmpty) {
      await _showRosterDialog(
        title: 'Roster competitivo',
        message: 'Selecciona al menos un jugador para enviar el roster.',
      );
      return;
    }

    final usedNumbers = <int, String>{};
    final payload = <Map<String, dynamic>>[];

    for (final entry in selectedDrafts) {
      final player = entry.key;
      final draft = entry.value;
      final jerseyText = draft.jerseyController.text.trim();
      final jerseyNumber = int.tryParse(jerseyText);
      if (jerseyNumber == null || jerseyNumber <= 0) {
        await _showRosterDialog(
          title: 'Roster competitivo',
          message: 'Revisa el jersey de ${player.displayName}.',
        );
        return;
      }

      final repeatedOwner = usedNumbers[jerseyNumber];
      if (repeatedOwner != null) {
        await _showRosterDialog(
          title: 'Roster competitivo',
          message:
              'El jersey $jerseyNumber esta repetido entre $repeatedOwner y ${player.displayName}.',
        );
        return;
      }
      usedNumbers[jerseyNumber] = player.displayName;

      final row = <String, dynamic>{
        'player_id': player.playerId,
        'jersey_number': jerseyNumber,
      };

      final customPosition = draft.customPosition.trim();
      if (draft.positionId != null) {
        row['position_id'] = draft.positionId;
      } else if (customPosition.isNotEmpty) {
        row['position'] = customPosition;
      }

      payload.add(row);
    }

    setState(() {
      _isSendingRoster = true;
    });

    try {
      final response = await _api.syncClubLeagueRosterEntries(
        widget.tournament.id,
        _selectedClubLinkId!,
        categoryId: source.category?.id,
        divisionId: category.division!.id,
        subDivisionId: category.subDivision?.id,
        players: payload,
      );

      if (!mounted) return;
      await _showRosterDialog(
        title: 'Roster competitivo',
        message:
            '${response.message}\n\nTotal: ${response.summary.total}\n'
            'Altas: ${response.summary.createdCount}\n'
            'Actualizados: ${response.summary.updatedCount}\n'
            'Eliminados: ${response.summary.deletedCount}',
      );
      await _loadRosterData();
    } catch (e) {
      if (!mounted) return;
      await _showRosterDialog(
        title: 'Roster competitivo',
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingRoster = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabs = <Tab>[
      const Tab(text: 'Standings'),
      const Tab(text: 'Partidos'),
      if (_canManageRoster) const Tab(text: 'Roster'),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.tournament.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.78),
            indicatorColor: Colors.white,
            tabs: tabs,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: TabBarView(
                  children: [
                    _buildScrollableTab(
                      theme: theme,
                      child: _buildStandingsTab(theme),
                    ),
                    _buildScrollableTab(
                      theme: theme,
                      child: _buildFixturesTab(theme),
                    ),
                    if (_canManageRoster)
                      _buildScrollableTab(
                        theme: theme,
                        child: _buildRosterTab(theme),
                        showTopSearch: false,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableTab({
    required ThemeData theme,
    required Widget child,
    bool showTopSearch = true,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        if (showTopSearch) ...[
          _TournamentFiltersCard(
            searchController: _searchController,
            searchQuery: _searchQuery,
            organizationName: _organizationName,
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),
        ],
        if (_isLoading && _standings == null && _fixtures == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _StateMessage(
            icon: Icons.sync_problem_outlined,
            title: 'No se pudo cargar el torneo',
            body: _error!,
            actionLabel: 'Reintentar',
            onPressed: _loadData,
          )
        else
          child,
      ],
    );
  }

  Widget _buildStandingsTab(ThemeData theme) {
    final standings = _standings;
    if (standings == null || standings.items.isEmpty) {
      return _InlineEmptyState(
        icon: Icons.table_chart_outlined,
        title: 'Sin standings disponibles',
        body: 'La tabla general se mostrara aqui cuando el torneo publique posiciones.',
      );
    }

    final items = standings.items.toList()
      ..retainWhere(
        (item) => _matchesSearch(
          teamName: item.team.name,
          categoryLabel: _divisionLabel(item.division, item.subDivision),
        ),
      )
      ..sort((a, b) => a.stats.rankPosition.compareTo(b.stats.rankPosition));

    if (items.isEmpty) {
      return const _InlineEmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'Sin standings para esta categoria',
        body: 'Prueba con otra categoria, equipo o limpia la busqueda.',
      );
    }

    final grouped = <String, List<ClubLeagueStandingItem>>{};
    for (final item in items) {
      final key = _divisionLabel(item.division, item.subDivision).isEmpty
          ? 'Sin categoria'
          : _divisionLabel(item.division, item.subDivision);
      grouped.putIfAbsent(key, () => <ClubLeagueStandingItem>[]).add(item);
    }

    return Column(
      children: grouped.entries.map((entry) {
        final groupItems = entry.value
          ..sort((a, b) => a.stats.rankPosition.compareTo(b.stats.rankPosition));
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _StandingsCategoryTable(
            title: entry.key,
            items: groupItems,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFixturesTab(ThemeData theme) {
    final fixtures = _fixtures;
    if (fixtures == null || fixtures.items.isEmpty) {
      return const _InlineEmptyState(
        icon: Icons.event_note_outlined,
        title: 'Sin partidos disponibles',
        body: 'El calendario y los resultados apareceran aqui cuando la liga publique partidos.',
      );
    }

    final items = fixtures.items.toList()
      ..retainWhere(
        (item) => _matchesSearch(
          teamName: '${item.homeTeam.name} ${item.awayTeam.name}',
          categoryLabel: _divisionLabel(item.division, item.subDivision),
        ),
      )
      ..sort((a, b) => b.kickoffAt.compareTo(a.kickoffAt));

    if (items.isEmpty) {
      return const _InlineEmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'Sin partidos para esta categoria',
        body: 'Prueba con otra categoria competitiva o vuelve a ver todas.',
      );
    }

    final grouped = <String, List<ClubLeagueFixtureItem>>{};
    for (final item in items) {
      final parsed = DateTime.tryParse(item.kickoffAt)?.toLocal();
      final key = parsed == null
          ? item.kickoffAt
          : DateFormat('yyyy-MM-dd').format(parsed);
      grouped.putIfAbsent(key, () => <ClubLeagueFixtureItem>[]).add(item);
    }

    final orderedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final ad = DateTime.tryParse(a);
        final bd = DateTime.tryParse(b);
        if (ad != null && bd != null) {
          return bd.compareTo(ad);
        }
        return b.compareTo(a);
      });

    return Column(
      children: orderedKeys
          .map(
            (key) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _FixturesDayGroup(
                dayKey: key,
                fixtures: grouped[key]!,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildRosterTab(ThemeData theme) {
    final options = _rosterCategoryOptions;
    final source = _rosterSource;
    final entries = _rosterEntries;

    if (options.isEmpty) {
      return const _InlineEmptyState(
        icon: Icons.group_off_outlined,
        title: 'Sin categorias competitivas',
        body: 'Este equipo todavia no tiene categorias/divisiones configuradas en el torneo.',
      );
    }

    if (_selectedRosterCategory == null) {
      return const _InlineEmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'Selecciona una categoria',
        body: 'Elige la categoria competitiva que quieres gestionar para el roster.',
      );
    }

    if (_isRosterLoading && source == null && entries == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_rosterError != null && source == null) {
      return _StateMessage(
        icon: Icons.sync_problem_outlined,
        title: 'No se pudo cargar el roster',
        body: _rosterError!,
        actionLabel: 'Reintentar',
        onPressed: _loadRosterData,
      );
    }

    final rosterEntries = entries?.items ?? const <ClubLeagueRosterEntry>[];
    final rosterPlayers = (source?.items ?? const <ClubLeagueRosterSourcePlayer>[])
        .where(
          (player) => _matchesRosterSearch(player.displayName),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RosterCategoryCard(
          options: options,
          selectedKey: _selectedRosterCategoryKey,
          onSelected: (key) {
            if (_selectedRosterCategoryKey == key) return;
            setState(() {
              _selectedRosterCategoryKey = key;
              _rosterSource = null;
              _rosterEntries = null;
              _rosterError = null;
            });
            _loadRosterData();
          },
        ),
        const SizedBox(height: 12),
        _RosterSummaryCard(
          source: source,
          entriesCount: rosterEntries.length,
          isLoading: _isRosterLoading,
          isSending: _isSendingRoster,
          deadlineAt: widget.tournament.rosterDeadlineAt,
          onRefresh: _loadRosterData,
          onSend: _isSendingRoster || _isRosterLoading ? null : _sendRoster,
        ),
        const SizedBox(height: 12),
        _RosterPlayersSearchCard(
          controller: _rosterSearchController,
          query: _rosterSearchQuery,
          onChanged: (value) {
            setState(() {
              _rosterSearchQuery = value.trim().toLowerCase();
            });
          },
        ),
        const SizedBox(height: 12),
        if (_rosterError != null && source != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _InlineEmptyState(
              icon: Icons.error_outline,
              title: 'Se cargó con advertencias',
              body: _rosterError!,
            ),
          ),
        if (rosterPlayers.isEmpty)
          const _InlineEmptyState(
            icon: Icons.group_add_outlined,
            title: 'Sin jugadores elegibles',
            body: 'Cuando existan jugadores elegibles para esta categoria, apareceran aqui.',
          )
        else
          ...rosterPlayers.map((player) {
            final draft = _rosterDrafts[player.playerId];
            if (draft == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RosterPlayerCard(
                player: player,
                draft: draft,
                positionOptions: source?.catalogs.positions ?? const [],
                isBusy: _isSendingRoster,
                onChanged: () => setState(() {}),
              ),
            );
          }),
        const SizedBox(height: 4),
        Text(
          'Roster enviado',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (rosterEntries.isEmpty)
          const _InlineEmptyState(
            icon: Icons.fact_check_outlined,
            title: 'Aun no hay roster enviado',
            body: 'Selecciona jugadores y usa "Enviar roster" para sincronizar esta categoria.',
          )
        else
          ...rosterEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RosterEntryCard(entry: entry),
            ),
          ),
      ],
    );
  }

  bool _matchesSearch({
    required String teamName,
    required String categoryLabel,
  }) {
    if (_searchQuery.isEmpty) return true;
    final haystack = '${teamName.toLowerCase()} ${categoryLabel.toLowerCase()}';
    return haystack.contains(_searchQuery);
  }

  bool _matchesRosterSearch(String playerName) {
    if (_rosterSearchQuery.isEmpty) return true;
    return playerName.toLowerCase().contains(_rosterSearchQuery);
  }

  Future<void> _showRosterDialog({
    required String title,
    required String message,
  }) async {
    await Get.dialog<void>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}

class _RosterCategoryCard extends StatelessWidget {
  final List<_CategoryOption> options;
  final String? selectedKey;
  final ValueChanged<String> onSelected;

  const _RosterCategoryCard({
    required this.options,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categoria de roster',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige la division/subdivision exacta que vas a enviar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                return ChoiceChip(
                  selected: selectedKey == option.key,
                  label: Text(option.label),
                  onSelected: (_) => onSelected(option.key),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TournamentFiltersCard extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String organizationName;
  final ValueChanged<String> onSearchChanged;

  const _TournamentFiltersCard({
    required this.searchController,
    required this.searchQuery,
    required this.organizationName,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Buscar equipo o categoria',
                hintText:
                    'Ej. ${organizationName.isNotEmpty ? organizationName : 'tu organizacion'}, U14, Femenil',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Busca rapido por nombre de equipo o categoria.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandingsCategoryTable extends StatelessWidget {
  final String title;
  final List<ClubLeagueStandingItem> items;

  const _StandingsCategoryTable({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${items.length} equipos',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 44,
              columnSpacing: 14,
              horizontalMargin: 12,
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Equipo')),
                DataColumn(label: Text('PTS')),
                DataColumn(label: Text('JJ')),
                DataColumn(label: Text('G')),
                DataColumn(label: Text('E')),
                DataColumn(label: Text('P')),
                DataColumn(label: Text('GF')),
                DataColumn(label: Text('GC')),
                DataColumn(label: Text('DG')),
              ],
              rows: items.map((item) {
                final isHighlighted = item.isMyTeam || item.isMyOrganization;
                final rowColor = isHighlighted
                    ? WidgetStatePropertyAll(
                        theme.colorScheme.primary.withValues(alpha: 0.10),
                      )
                    : null;

                return DataRow(
                  color: rowColor,
                  cells: [
                    DataCell(Text('${item.stats.rankPosition}')),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 180),
                        child: Row(
                          children: [
                            _NetworkLogo(
                              url: item.team.logoUrl,
                              size: 28,
                              icon: Icons.shield_outlined,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.team.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isHighlighted
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${item.stats.points}',
                        style: TextStyle(
                          fontWeight: isHighlighted
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(Text('${item.stats.played}')),
                    DataCell(Text('${item.stats.wins}')),
                    DataCell(Text('${item.stats.draws}')),
                    DataCell(Text('${item.stats.losses}')),
                    DataCell(Text('${item.stats.goalsFor}')),
                    DataCell(Text('${item.stats.goalsAgainst}')),
                    DataCell(Text('${item.stats.goalDifference}')),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterSummaryCard extends StatelessWidget {
  final ClubLeagueRosterSourceResponse? source;
  final int entriesCount;
  final bool isLoading;
  final bool isSending;
  final String? deadlineAt;
  final VoidCallback onRefresh;
  final VoidCallback? onSend;

  const _RosterSummaryCard({
    required this.source,
    required this.entriesCount,
    required this.isLoading,
    required this.isSending,
    required this.deadlineAt,
    required this.onRefresh,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryName = source?.category?.name.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion de roster competitivo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if ((source?.team.teamName ?? '').trim().isNotEmpty)
                            source!.team.teamName,
                          if (categoryName != null && categoryName.isNotEmpty)
                            categoryName,
                        ].join(' • '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isLoading ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar roster',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Elegibles ${source?.items.length ?? 0}')),
                Chip(label: Text('Enviados $entriesCount')),
                if (deadlineAt != null)
                  Chip(label: Text('Cierre ${_formatDate(deadlineAt)}')),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSend,
                icon: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(isSending ? 'Enviando roster...' : 'Enviar roster'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RosterPlayersSearchCard extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;

  const _RosterPlayersSearchCard({
    required this.controller,
    required this.query,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Buscar jugador',
            hintText: 'Escribe el nombre del jugador',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: const Icon(Icons.close),
                  ),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

class _RosterPlayerCard extends StatelessWidget {
  final ClubLeagueRosterSourcePlayer player;
  final _RosterDraft draft;
  final List<ClubLeaguePositionOption> positionOptions;
  final bool isBusy;
  final VoidCallback onChanged;

  const _RosterPlayerCard({
    required this.player,
    required this.draft,
    required this.positionOptions,
    required this.isBusy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestedJersey =
        player.latestLeagueJerseyNumber ?? player.categoryJerseyNumber;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: draft.selected,
                  onChanged: isBusy
                      ? null
                      : (value) {
                          draft.selected = value ?? false;
                          onChanged();
                        },
                ),
                _PlayerAvatar(
                  imageUrl: player.avatarUrl,
                  initials: _initials(player.displayName),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (suggestedJersey != null)
                            Chip(label: Text('Sugerido #$suggestedJersey')),
                          if ((player.currentEntry?.jerseyNumber) != null)
                            Chip(
                              label: Text(
                                'Actual #${player.currentEntry!.jerseyNumber}',
                              ),
                            ),
                          if ((player.position.trim()).isNotEmpty)
                            Chip(label: Text(player.position)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: draft.jerseyController,
                    enabled: draft.selected && !isBusy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jersey',
                      hintText: 'Ej. 12',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: draft.positionId,
                    decoration: const InputDecoration(
                      labelText: 'Posicion',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin catalogo'),
                      ),
                      ...positionOptions.map(
                        (option) => DropdownMenuItem<int?>(
                          value: option.id,
                          child: Text(option.label),
                        ),
                      ),
                    ],
                    onChanged: draft.selected && !isBusy
                        ? (value) {
                            draft.positionId = value;
                            if (value != null) {
                              draft.customPosition = '';
                              draft.customPositionController.text = '';
                            }
                            onChanged();
                          }
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: draft.customPositionController,
              enabled: draft.selected && !isBusy && draft.positionId == null,
              decoration: const InputDecoration(
                labelText: 'Posicion libre',
                hintText: 'Ej. WR, Safety, Ala',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                draft.customPosition = value;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RosterEntryCard extends StatelessWidget {
  final ClubLeagueRosterEntry entry;

  const _RosterEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      child: ListTile(
        leading: _PlayerAvatar(
          imageUrl: entry.player.avatarUrl,
          initials: _initials(entry.player.displayName),
        ),
        title: Text(
          entry.player.displayName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            if (entry.jerseyNumber != null) '#${entry.jerseyNumber}',
            if (entry.position.trim().isNotEmpty) entry.position,
            if (entry.status.trim().isNotEmpty) _labelize(entry.status),
          ].join(' • '),
        ),
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  final String imageUrl;
  final String initials;

  const _PlayerAvatar({
    required this.imageUrl,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundImage: imageUrl.trim().isEmpty ? null : NetworkImage(imageUrl),
      child: imageUrl.trim().isEmpty ? Text(initials) : null,
    );
  }
}

class _FixturesDayGroup extends StatelessWidget {
  final String dayKey;
  final List<ClubLeagueFixtureItem> fixtures;

  const _FixturesDayGroup({
    required this.dayKey,
    required this.fixtures,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsed = DateTime.tryParse(dayKey);
    final title = parsed == null
        ? dayKey
        : DateFormat('EEEE d MMMM yyyy', 'es_MX').format(parsed);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _capitalize(title),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${fixtures.length} partido${fixtures.length == 1 ? '' : 's'}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          children: fixtures
              .map(
                (fixture) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FixtureCard(fixture: fixture),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _FixtureMetaPill extends StatelessWidget {
  final String label;

  const _FixtureMetaPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FixtureCard extends StatelessWidget {
  final ClubLeagueFixtureItem fixture;

  const _FixtureCard({required this.fixture});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = fixture.score;
    final meta = <String>[
      if ((fixture.matchday?.name ?? '').isNotEmpty) fixture.matchday!.name,
      if (fixture.status.isNotEmpty) _labelize(fixture.status),
      if (_divisionLabel(fixture.division, fixture.subDivision).isNotEmpty)
        _divisionLabel(fixture.division, fixture.subDivision),
    ];

    return Card(
      color: fixture.isMyTeamMatch
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: meta
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FixtureMetaPill(label: item),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDateTime(fixture.kickoffAt),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (fixture.venueName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  fixture.venueName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FixtureSide(
                    team: fixture.homeTeam,
                    score: score?.home,
                    alignment: CrossAxisAlignment.start,
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    'VS',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FixtureSide(
                    team: fixture.awayTeam,
                    score: score?.away,
                    alignment: CrossAxisAlignment.end,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FixtureSide extends StatelessWidget {
  final ClubLeagueFixtureTeam team;
  final int? score;
  final CrossAxisAlignment alignment;
  final TextAlign textAlign;

  const _FixtureSide({
    required this.team,
    required this.score,
    required this.alignment,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: team.isMyTeam ? FontWeight.w700 : FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: alignment,
      children: [
        _NetworkLogo(
          url: team.logoUrl,
          size: 56,
          icon: Icons.shield_outlined,
        ),
        const SizedBox(height: 10),
        Text(
          team.name,
          textAlign: textAlign,
          style: textStyle,
        ),
        if (team.isMyTeam)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Mi equipo',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const SizedBox(height: 10),
        Text(
          score?.toString() ?? '-',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NetworkLogo extends StatelessWidget {
  final String url;
  final double size;
  final IconData icon;

  const _NetworkLogo({
    required this.url,
    required this.size,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: url.trim().isEmpty
          ? Icon(icon, size: size * 0.48, color: theme.colorScheme.primary)
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Icon(
                icon,
                size: size * 0.48,
                color: theme.colorScheme.primary,
              ),
              placeholder: (_, __) => Center(
                child: SizedBox(
                  width: size * 0.35,
                  height: size * 0.35,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InlineEmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryOption {
  final String key;
  final String label;
  final ClubLeagueDivision? division;
  final ClubLeagueDivision? subDivision;

  const _CategoryOption({
    required this.key,
    required this.label,
    this.division,
    this.subDivision,
  });
}

class _RosterDraft {
  bool selected;
  final TextEditingController jerseyController;
  final TextEditingController customPositionController;
  int? positionId;
  String customPosition;

  _RosterDraft({
    required this.selected,
    required this.jerseyController,
    required this.positionId,
    required this.customPosition,
  }) : customPositionController = TextEditingController(text: customPosition);

  void dispose() {
    jerseyController.dispose();
    customPositionController.dispose();
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onPressed;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(String? iso) {
  if (iso == null || iso.trim().isEmpty) return '-';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return DateFormat('dd MMM yyyy', 'es_MX').format(parsed.toLocal());
}

String _formatDateTime(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return DateFormat('EEE dd MMM • HH:mm', 'es_MX').format(parsed.toLocal());
}

String _divisionLabel(ClubLeagueDivision? division, ClubLeagueDivision? subDivision) {
  final values = <String>[
    if ((division?.name ?? '').trim().isNotEmpty) division!.name,
    if ((subDivision?.name ?? '').trim().isNotEmpty) subDivision!.name,
  ];
  return values.join(' / ');
}

String _labelize(String raw) {
  final normalized = raw.trim().replaceAll('_', ' ');
  if (normalized.isEmpty) return raw;
  return normalized[0].toUpperCase() + normalized.substring(1);
}

String _categoryKey(int? divisionId, int? subDivisionId) {
  return '${divisionId ?? 0}:${subDivisionId ?? 0}';
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

String _capitalize(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return value;
  return trimmed[0].toUpperCase() + trimmed.substring(1);
}
