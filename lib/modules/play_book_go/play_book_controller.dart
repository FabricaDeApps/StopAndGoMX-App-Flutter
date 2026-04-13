import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/playbook/playbook_catalog.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/models/play_book_model.dart';

enum PlayBookMode { play, move, route }

class PlayBookController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final fieldSize = const Size(900, 520);

  // ---------------- VIEW STATE ----------------
  final isLoading = false.obs;
  final error = RxnString();

  // Si viene playId -> estamos viendo/EDITANDO detalle
  final playId = RxnString();
  bool get isEditingExisting =>
      (playId.value != null && playId.value!.isNotEmpty);

  String get primaryCtaLabel => isEditingExisting ? 'Actualizar' : 'Guardar';

  // ---------------- PLAYERS ----------------
  final players = <PlayerToken>[].obs;
  final selectedPlayerId = RxnString();

  // ---------------- MODE ----------------
  final mode = PlayBookMode.play.obs;

  bool get isMoveMode => mode.value == PlayBookMode.move;
  bool get isDrawMode => mode.value == PlayBookMode.route;
  bool get isPlayMode => mode.value == PlayBookMode.play;

  void setMode(PlayBookMode m) {
    if (mode.value == m) return;
    mode.value = m;

    onPanEnd();
    if (!isDrawMode) {
      clearActiveRoute();
    }
  }

  // ---------------- DRAG ----------------
  String? _draggingPlayerId;
  Offset? _dragOffsetFromCenter;

  final isDragging = false.obs;
  final draggingPlayerId = RxnString();

  // ---------------- ROUTES ----------------
  final activeRoutePoints = <Offset>[].obs;
  final routesByPlayer = <String, List<PlayRoute>>{}.obs;

  // ---------------- PLAY META ----------------
  final playAliasCtrl = TextEditingController();

  // ✅ Enum PlayType
  final playSport = Rxn<PlaySport>();
  final playType = Rx<PlayType?>(null);

  // ✅ Nuevos campos (vienen del wizard o default)
  final playSide = RxnString(); // 'offense' | 'defense'
  final playersCount = 0.obs;
  final categoryId = RxnInt();
  final sharedCategoryIds = <int>[].obs;
  final sharedCategories = <PlaybookCategoryRef>[].obs;

  final isSavingPlay = false.obs;
  final isDeletingPlay = false.obs;
  final playError = RxnString();

  final routeEndType = RouteEndType.arrow.obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>?;

    // 1) EDITAR: playId
    final argPlayId = args?['playId']?.toString();
    if (argPlayId != null && argPlayId.isNotEmpty) {
      playId.value = argPlayId;
    }

    // 2) CREAR DESDE WIZARD: side/type/players_count/category_id
    final argSport = args?['sport']?.toString();
    playSport.value = _mapSportFromArg(argSport);

    final argSide = args?['side']?.toString(); // 'offense' | 'defense'
    playSide.value = (argSide == 'defense' || argSide == 'offense')
        ? argSide
        : 'offense';

    final argPlayersCount = args?['players_count'];
    if (argPlayersCount != null) {
      playersCount.value = int.tryParse(argPlayersCount.toString()) ?? 0;
    }

    final argCategoryId = args?['category_id'];
    if (argCategoryId != null) {
      categoryId.value = int.tryParse(argCategoryId.toString());
    }

    final argSharedCategoryIds = (args?['shared_category_ids'] as List?) ?? const [];
    sharedCategoryIds.assignAll(
      argSharedCategoryIds
          .map((e) => int.tryParse(e.toString()))
          .whereType<int>(),
    );

    final argType = args?['type']?.toString(); // pass/run/...
    playType.value = _mapWizardTypeToEnum(argType ?? '') ?? PlayType.run;
  }

  @override
  void onReady() {
    super.onReady();

    if (isEditingExisting) {
      loadPlayFromBackend(playId.value!);
    } else {
      _seedFormationFromArgs();
    }
  }

  @override
  void onClose() {
    playAliasCtrl.dispose();
    super.onClose();
  }

  // ---------------- LABEL ----------------
  String sportLabel(PlaySport sport) => playSportLabel(sport);

  String typeLabel(PlayType t) => playTypeLabel(t);

  List<PlayType> get playTypes {
    final side = _mapSideFromRaw(playSide.value);
    final options = playTypeOptions(sport: playSport.value, side: side);
    final current = playType.value;

    if (current != null && !options.contains(current)) {
      return [...options, current];
    }

    return options;
  }

  // ---------------- TYPE MAPPING (wizard/backend) ----------------
  PlaySport _inferSportFromContext({
    int? playersCount,
    String? type,
  }) {
    final normalizedType = _mapWizardTypeToEnum(type ?? '');
    if (normalizedType == PlayType.playAction) {
      return PlaySport.americanFootball;
    }

    if ((playersCount ?? 0) >= 9) {
      return PlaySport.americanFootball;
    }

    return PlaySport.flagFootball;
  }

  PlaySport _mapSportFromArg(String? raw) {
    final value = raw?.trim().toLowerCase();
    switch (value) {
      case 'americanfootball':
      case 'american_football':
      case 'american-football':
      case 'football_americano':
      case 'football-americano':
        return PlaySport.americanFootball;
      case 'flagfootball':
      case 'flag_football':
      case 'flag-football':
      default:
        return PlaySport.flagFootball;
    }
  }

  PlaySide? _mapSideFromRaw(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'offense':
        return PlaySide.offense;
      case 'defense':
        return PlaySide.defense;
      default:
        return null;
    }
  }

  PlayType? _mapWizardTypeToEnum(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return null;

    // 1) si viene enum name directo: "pass", "run", ...
    for (final t in PlayType.values) {
      if (t.name.toLowerCase() == v) return t;
    }

    // 2) si viene label en español o variantes
    switch (v) {
      case 'pase':
        return PlayType.pass;
      case 'carrera':
        return PlayType.run;
      case 'rpo':
        return PlayType.rpo;
      case 'play action':
      case 'playaction':
        return PlayType.playAction;
      case 'screen':
        return PlayType.screen;
      case 'trick':
      case 'engaño':
      case 'trick / engaño':
        return PlayType.trick;
      case 'blitz':
        return PlayType.blitz;
      case 'cobertura':
        return PlayType.coverage;
    }

    return null;
  }

  // ---------------- LOAD PLAY ----------------
  Future<void> loadPlayFromBackend(String id) async {
    isLoading.value = true;
    error.value = null;

    try {
      final PlaybookPlay play = await _api.getPlaybookPlay(playId: id);

      // Limpia todo antes de setear
      players.clear();
      routesByPlayer.clear();
      activeRoutePoints.clear();

      // Meta
      playAliasCtrl.text = play.alias;

      // type: backend puede mandar "pass" o "Pase"
      playType.value = _mapWizardTypeToEnum(play.type) ?? PlayType.run;

      // side (si tu backend lo manda, úsalo; si no, default)
      final side = (play.side).toString();
      playSide.value = (side == 'defense' || side == 'offense')
          ? side
          : 'offense';

      // playersCount (si tu backend lo manda)
      final pc = play.playersCount;
      playersCount.value = pc;
      playSport.value = _inferSportFromContext(
        playersCount: pc,
        type: play.type,
      );
      categoryId.value = play.categoryId;
      sharedCategories.assignAll(play.sharedCategories);
      sharedCategoryIds.assignAll(play.sharedCategories.map((e) => e.id));

      // Players
      players.assignAll(play.players);

      // Routes
      routesByPlayer.assignAll(play.routesByPlayer);

      // Selección por default: primero
      selectedPlayerId.value = players.isNotEmpty ? players.first.id : null;

      // Asegurar keys en routesByPlayer
      for (final p in players) {
        routesByPlayer.putIfAbsent(p.id, () => <PlayRoute>[]);
      }
      routesByPlayer.refresh();

      // Modo inicial
      mode.value = PlayBookMode.play;
    } catch (e) {
      error.value = 'Error al cargar jugada: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------- INIT FORMATION (FROM WIZARD) ----------------
  void _seedFormationFromArgs() {
    players.clear();
    routesByPlayer.clear();
    activeRoutePoints.clear();

    final count = playersCount.value > 0 ? playersCount.value : 5;
    final side = playSide.value ?? 'offense';
    final isOffense = side == 'offense';

    final list = <PlayerToken>[];

    if (isOffense) {
      // Ofensiva: QB + C + RB + WRs/TE
      if (count >= 1) {
        list.add(
          const PlayerToken(
            id: 'qb',
            name: 'QB',
            pos: Offset(250, 260),
            isOffense: true,
          ),
        );
      }
      if (count >= 2) {
        list.add(
          const PlayerToken(
            id: 'c',
            name: 'C',
            pos: Offset(290, 260),
            isOffense: true,
          ),
        );
      }
      if (count >= 3) {
        list.add(
          const PlayerToken(
            id: 'rb',
            name: 'RB',
            pos: Offset(200, 310),
            isOffense: true,
          ),
        );
      }

      // WR/TE extra
      final slots = <PlayerToken>[
        const PlayerToken(
          id: 'wr1',
          name: 'WR1',
          pos: Offset(140, 170),
          isOffense: true,
        ),
        const PlayerToken(
          id: 'wr2',
          name: 'WR2',
          pos: Offset(140, 350),
          isOffense: true,
        ),
        const PlayerToken(
          id: 'te',
          name: 'TE',
          pos: Offset(220, 210),
          isOffense: true,
        ),
        const PlayerToken(
          id: 'wr3',
          name: 'WR3',
          pos: Offset(160, 260),
          isOffense: true,
        ),
        const PlayerToken(
          id: 'wr4',
          name: 'WR4',
          pos: Offset(160, 440),
          isOffense: true,
        ),
        const PlayerToken(
          id: 'ol1',
          name: 'OL1',
          pos: Offset(320, 220),
          isOffense: true,
        ),
        const PlayerToken(
          id: 'ol2',
          name: 'OL2',
          pos: Offset(320, 300),
          isOffense: true,
        ),
      ];

      for (final p in slots) {
        if (list.length >= count) break;
        list.add(p);
      }

      // Relleno genérico
      int i = 1;
      while (list.length < count) {
        final idx = list.length + 1;
        final id = 'p$idx';
        final y = 120.0 + (i % 5) * 80.0;
        list.add(
          PlayerToken(
            id: id,
            name: 'P$idx',
            pos: Offset(170, y),
            isOffense: true,
          ),
        );
        i++;
      }
    } else {
      // Defensa
      final slots = <PlayerToken>[
        const PlayerToken(
          id: 'dl1',
          name: 'DL1',
          pos: Offset(520, 220),
          isOffense: false,
        ),
        const PlayerToken(
          id: 'dl2',
          name: 'DL2',
          pos: Offset(520, 300),
          isOffense: false,
        ),
        const PlayerToken(
          id: 'lb1',
          name: 'LB1',
          pos: Offset(600, 220),
          isOffense: false,
        ),
        const PlayerToken(
          id: 'lb2',
          name: 'LB2',
          pos: Offset(600, 300),
          isOffense: false,
        ),
        const PlayerToken(
          id: 'cb1',
          name: 'CB1',
          pos: Offset(700, 160),
          isOffense: false,
        ),
        const PlayerToken(
          id: 'cb2',
          name: 'CB2',
          pos: Offset(700, 360),
          isOffense: false,
        ),
        const PlayerToken(
          id: 's',
          name: 'S',
          pos: Offset(760, 260),
          isOffense: false,
        ),
        const PlayerToken(
          id: 'nb',
          name: 'NB',
          pos: Offset(680, 260),
          isOffense: false,
        ),
      ];

      for (final p in slots) {
        if (list.length >= count) break;
        list.add(p);
      }

      int i = 1;
      while (list.length < count) {
        final idx = list.length + 1;
        final id = 'd$idx';
        final y = 120.0 + (i % 5) * 80.0;
        list.add(
          PlayerToken(
            id: id,
            name: 'D$idx',
            pos: Offset(650, y),
            isOffense: false,
          ),
        );
        i++;
      }
    }

    players.assignAll(list);

    selectedPlayerId.value = players.isNotEmpty ? players.first.id : null;

    for (final p in players) {
      routesByPlayer.putIfAbsent(p.id, () => <PlayRoute>[]);
    }
    routesByPlayer.refresh();

    mode.value = PlayBookMode.play;
  }

  void resetFormation() => _seedFormationFromArgs();

  // ---------------- SELECTION ----------------
  void selectPlayer(String id) {
    selectedPlayerId.value = id;
  }

  PlayerToken? get selectedPlayer {
    final id = selectedPlayerId.value;
    if (id == null) return null;
    return players.firstWhereOrNull((p) => p.id == id);
  }

  String? hitTestPlayer(Offset point, {double radius = 22}) {
    for (final p in players) {
      if ((p.pos - point).distance <= radius) return p.id;
    }
    return null;
  }

  // ---------------- MOVE (DRAG) ----------------
  void onPanDown(Offset localPoint) {
    if (!isMoveMode) return;

    final hit = hitTestPlayer(localPoint);
    if (hit == null) return;

    selectPlayer(hit);
    isDragging.value = true;
    draggingPlayerId.value = hit;
  }

  void onPanStart(Offset localPoint) {
    if (!isMoveMode) return;

    final hit = hitTestPlayer(localPoint);
    if (hit == null) return;

    _draggingPlayerId = hit;
    selectPlayer(hit);

    final p = players.firstWhere((e) => e.id == hit);
    _dragOffsetFromCenter = localPoint - p.pos;

    isDragging.value = true;
    draggingPlayerId.value = hit;
  }

  void onPanUpdate(Offset localPoint) {
    if (!isMoveMode) return;
    if (_draggingPlayerId == null) return;

    final offset = _dragOffsetFromCenter ?? Offset.zero;
    final desiredCenter = localPoint - offset;

    _movePlayerClamped(_draggingPlayerId!, desiredCenter);
  }

  void onPanEnd() {
    _draggingPlayerId = null;
    _dragOffsetFromCenter = null;

    isDragging.value = false;
    draggingPlayerId.value = null;
  }

  void _movePlayerClamped(String playerId, Offset pos) {
    const tokenRadius = 18.0;
    final clamped = Offset(
      pos.dx.clamp(tokenRadius, fieldSize.width - tokenRadius),
      pos.dy.clamp(tokenRadius, fieldSize.height - tokenRadius),
    );

    final idx = players.indexWhere((p) => p.id == playerId);
    if (idx == -1) return;

    players[idx] = players[idx].copyWith(pos: clamped);
    players.refresh();
  }

  // ---------------- DRAW (RUTAS) ----------------
  void clearActiveRoute() => activeRoutePoints.clear();

  void addRoutePointFromTap(Offset localPoint) {
    if (!isDrawMode) return;

    final sp = selectedPlayer;
    if (sp == null) return;

    if (activeRoutePoints.isEmpty) {
      activeRoutePoints.add(sp.pos);
    }

    activeRoutePoints.add(localPoint);
    activeRoutePoints.refresh();
  }

  void stepBackActive() {
    if (activeRoutePoints.isEmpty) return;
    activeRoutePoints.removeLast();
    activeRoutePoints.refresh();
  }

  void saveActiveRoute() {
    final pid = selectedPlayerId.value;
    final sp = selectedPlayer;
    if (pid == null || sp == null) return;

    if (activeRoutePoints.length < 2) {
      activeRoutePoints.clear();
      return;
    }

    final origin = sp.pos;
    final rel = activeRoutePoints.map((p) => p - origin).toList();

    final route = PlayRoute(
      id: _id(),
      playerId: pid,
      points: rel,
      origin: origin,
      endType: routeEndType.value,
    );

    final list = routesByPlayer[pid] ?? <PlayRoute>[];
    routesByPlayer[pid] = [...list, route];
    routesByPlayer.refresh();

    activeRoutePoints.clear();
  }

  void deleteLastSavedRoute() {
    final pid = selectedPlayerId.value;
    if (pid == null) return;

    final list = routesByPlayer[pid] ?? <PlayRoute>[];
    if (list.isEmpty) return;

    routesByPlayer[pid] = list.sublist(0, list.length - 1);
    routesByPlayer.refresh();
  }

  void deleteRouteButton() {
    if (activeRoutePoints.isNotEmpty) {
      activeRoutePoints.clear();
      return;
    }
    deleteLastSavedRoute();
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  // ---------------- PAYLOAD (CREATE / UPDATE) ----------------
  Map<String, dynamic> _toPayload() {
    final alias = playAliasCtrl.text.trim();
    final type = playType.value ?? PlayType.run;

    final playersJson = players
        .map(
          (p) => {
            "id": p.id,
            "name": p.name,
            "x": p.pos.dx,
            "y": p.pos.dy,
            "isOffense": p.isOffense,
          },
        )
        .toList();

    final routesJson = <String, dynamic>{};
    routesByPlayer.forEach((playerId, list) {
      routesJson[playerId] = list
          .map(
            (r) => {
              "playerId": r.playerId,
              "origin": {"x": r.origin.dx, "y": r.origin.dy},
              "points": r.points.map((pt) => {"x": pt.dx, "y": pt.dy}).toList(),
              "endType": routeEndTypeToJson(r.endType),
            },
          )
          .toList();
    });

    final catId = categoryId.value ?? AppStorage.getSelectedCategoryId();

    return {
      "category_id": catId,
      "alias": alias,
      // ✅ manda string al backend
      "type": type.name,
      "side": playSide.value ?? 'offense',
      if (!isEditingExisting && sharedCategoryIds.isNotEmpty)
        "shared_category_ids": sharedCategoryIds.toList(),
      "notes": null,
      "players": playersJson,
      "routesByPlayer": routesJson,
    };
  }

  // ---------------- SAVE (CREATE OR UPDATE) ----------------
  Future<void> savePlayToBackend() async {
    playError.value = null;

    final alias = playAliasCtrl.text.trim();
    if (alias.isEmpty) {
      playError.value = 'Escribe un alias para la jugada.';
      return;
    }
    if (playType.value == null) {
      playError.value = 'Selecciona un tipo de jugada.';
      return;
    }

    isSavingPlay.value = true;
    try {
      final payload = _toPayload();

      if (isEditingExisting) {
        final updated = await _api.playbookUpdatePlay(
          playId: playId.value!,
          payload: payload,
        );
        Get.back(result: updated);
      } else {
        final created = await _api.playbookCreatePlayGo(payload: payload);
        Get.back(result: {'refresh': true, 'play': created});
      }
    } catch (e) {
      playError.value = e.toString();
    } finally {
      isSavingPlay.value = false;
    }
  }

  // ---------------- DELETE (OPCIONAL) ----------------
  Future<void> deletePlayFromBackend() async {
    if (!isEditingExisting) return;

    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Eliminar jugada'),
        content: const Text(
          '¿Seguro que quieres eliminar esta jugada? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    isDeletingPlay.value = true;
    playError.value = null;

    try {
      final deleted = await _api.playbookDeletePlay(playId: playId.value!);
      if (!deleted) {
        throw Exception('No se pudo eliminar (ok != true)');
      }
      Get.back(result: {'deleted': true, 'playId': playId.value});
    } catch (e) {
      playError.value = e.toString();
    } finally {
      isDeletingPlay.value = false;
    }
  }

  void renameSelectedPlayer(String newName) {
    final id = selectedPlayerId.value;
    if (id == null) return;

    final name = newName.trim();
    if (name.isEmpty) return;

    final idx = players.indexWhere((p) => p.id == id);
    if (idx == -1) return;

    // 3 chars máx (por si llega más)
    final fixed = name.length > 3 ? name.substring(0, 3) : name;

    players[idx] = players[idx].copyWith(name: fixed.toUpperCase());
    players.refresh();
  }
}
