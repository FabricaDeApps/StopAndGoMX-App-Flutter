import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/player_file.dart';
import 'package:stopandgo/core/network/api_repository.dart';

class PlayerFileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static const tabs = <String>[
    'categories',
    'trainings',
    'payments',
    'documents',
  ];

  final ApiRepository _api = Get.find<ApiRepository>();

  late final int playerId;
  late final String fallbackPlayerName;
  late final TabController tabController;

  final activeTab = 'categories'.obs;
  final player = Rxn<PlayerFilePlayer>();

  final categories = <PlayerFileCategoryItem>[].obs;
  final trainings = <PlayerFileTrainingItem>[].obs;
  final payments = <PlayerFilePaymentItem>[].obs;
  final documents = <PlayerFileDocumentItem>[].obs;

  final loadingByTab = <String, bool>{}.obs;
  final loadingMoreByTab = <String, bool>{}.obs;
  final errorByTab = <String, String?>{}.obs;
  final currentPageByTab = <String, int>{}.obs;
  final lastPageByTab = <String, int>{}.obs;
  final initializedByTab = <String, bool>{}.obs;

  final Map<String, int> _requestTokenByTab = <String, int>{};

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments is Map
        ? Get.arguments as Map
        : <String, dynamic>{};
    final idFromPath = int.tryParse((Get.parameters['playerId'] ?? '').trim());
    playerId = idFromPath ?? (args['playerId'] as int? ?? 0);
    fallbackPlayerName = args['playerName']?.toString() ?? 'Jugador';

    for (final tab in tabs) {
      loadingByTab[tab] = false;
      loadingMoreByTab[tab] = false;
      errorByTab[tab] = null;
      currentPageByTab[tab] = 1;
      lastPageByTab[tab] = 1;
      initializedByTab[tab] = false;
      _requestTokenByTab[tab] = 0;
    }

    tabController = TabController(length: tabs.length, vsync: this);
    tabController.addListener(() {
      if (tabController.indexIsChanging) return;
      final tab = tabs[tabController.index];
      _activateTab(tab);
    });

    _loadTab('categories', reset: true);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  String get playerDisplayName {
    final value = player.value?.fullName ?? fallbackPlayerName;
    return value.trim().isEmpty ? 'Jugador' : value;
  }

  bool isTabLoading(String tab) => loadingByTab[tab] == true;
  bool isTabLoadingMore(String tab) => loadingMoreByTab[tab] == true;
  String? tabError(String tab) => errorByTab[tab];

  bool hasMore(String tab) {
    if (!_isPaginated(tab)) return false;
    final current = currentPageByTab[tab] ?? 1;
    final last = lastPageByTab[tab] ?? 1;
    return current < last;
  }

  List<dynamic> itemsFor(String tab) {
    switch (tab) {
      case 'categories':
        return categories;
      case 'trainings':
        return trainings;
      case 'payments':
        return payments;
      case 'documents':
        return documents;
      default:
        return const <dynamic>[];
    }
  }

  Future<void> onTabTapped(int index) async {
    if (index < 0 || index >= tabs.length) return;
    await _activateTab(tabs[index]);
  }

  Future<void> refreshActiveTab() => _loadTab(activeTab.value, reset: true);

  Future<void> loadMoreActiveTab() => _loadMore(activeTab.value);

  Future<void> _activateTab(String tab) async {
    activeTab.value = tab;
    if (initializedByTab[tab] != true) {
      await _loadTab(tab, reset: true);
    }
  }

  Future<void> _loadTab(String tab, {required bool reset}) async {
    if (isTabLoading(tab)) return;

    final page = 1;
    final token = (_requestTokenByTab[tab] ?? 0) + 1;
    _requestTokenByTab[tab] = token;

    loadingByTab[tab] = true;
    errorByTab[tab] = null;

    if (reset) {
      _clearTabData(tab);
      currentPageByTab[tab] = 1;
      lastPageByTab[tab] = 1;
    }

    try {
      final response = await _api.fetchPlayerFile(
        playerId: playerId,
        tab: tab,
        page: page,
        perPage: 25,
      );

      if (_requestTokenByTab[tab] != token) return;

      player.value = response.player;
      _assignData(tab, response, append: false);
      _applyMeta(tab, response.meta);
      initializedByTab[tab] = true;
    } catch (e) {
      if (_requestTokenByTab[tab] != token) return;
      errorByTab[tab] = _mapError(e);
    } finally {
      if (_requestTokenByTab[tab] == token) {
        loadingByTab[tab] = false;
      }
    }
  }

  Future<void> _loadMore(String tab) async {
    if (!_isPaginated(tab)) return;
    if (isTabLoading(tab) || isTabLoadingMore(tab) || !hasMore(tab)) return;

    final nextPage = (currentPageByTab[tab] ?? 1) + 1;
    final token = (_requestTokenByTab[tab] ?? 0) + 1;
    _requestTokenByTab[tab] = token;

    loadingMoreByTab[tab] = true;

    try {
      final response = await _api.fetchPlayerFile(
        playerId: playerId,
        tab: tab,
        page: nextPage,
        perPage: 25,
      );

      if (_requestTokenByTab[tab] != token) return;

      player.value = response.player;
      _assignData(tab, response, append: true);
      _applyMeta(tab, response.meta);
      initializedByTab[tab] = true;
    } catch (e) {
      if (_requestTokenByTab[tab] != token) return;
      errorByTab[tab] = _mapError(e);
    } finally {
      if (_requestTokenByTab[tab] == token) {
        loadingMoreByTab[tab] = false;
      }
    }
  }

  void _clearTabData(String tab) {
    switch (tab) {
      case 'categories':
        categories.clear();
        break;
      case 'trainings':
        trainings.clear();
        break;
      case 'payments':
        payments.clear();
        break;
      case 'documents':
        documents.clear();
        break;
      default:
        break;
    }
  }

  void _assignData(
    String tab,
    PlayerFileResponse response, {
    required bool append,
  }) {
    switch (tab) {
      case 'categories':
        _appendOrReplaceCategories(response.categories, append: append);
        break;
      case 'trainings':
        _appendOrReplaceTrainings(response.trainings, append: append);
        break;
      case 'payments':
        _appendOrReplacePayments(response.payments, append: append);
        break;
      case 'documents':
        _appendOrReplaceDocuments(response.documents, append: append);
        break;
      default:
        break;
    }
  }

  void _appendOrReplaceCategories(
    List<PlayerFileCategoryItem> incoming, {
    required bool append,
  }) {
    if (!append) {
      categories.assignAll(incoming);
      return;
    }
    final ids = categories.map((e) => e.id).toSet();
    categories.addAll(incoming.where((e) => !ids.contains(e.id)));
  }

  void _appendOrReplaceTrainings(
    List<PlayerFileTrainingItem> incoming, {
    required bool append,
  }) {
    if (!append) {
      trainings.assignAll(incoming);
      return;
    }
    final ids = trainings.map((e) => e.id).toSet();
    trainings.addAll(incoming.where((e) => !ids.contains(e.id)));
  }

  void _appendOrReplacePayments(
    List<PlayerFilePaymentItem> incoming, {
    required bool append,
  }) {
    if (!append) {
      payments.assignAll(incoming);
      return;
    }
    final ids = payments.map((e) => e.id).toSet();
    payments.addAll(incoming.where((e) => !ids.contains(e.id)));
  }

  void _appendOrReplaceDocuments(
    List<PlayerFileDocumentItem> incoming, {
    required bool append,
  }) {
    if (!append) {
      documents.assignAll(incoming);
      return;
    }
    final ids = documents.map((e) => e.id).toSet();
    documents.addAll(incoming.where((e) => !ids.contains(e.id)));
  }

  void _applyMeta(String tab, PlayerFileMeta meta) {
    if (_isPaginated(tab) &&
        meta.currentPage != null &&
        meta.lastPage != null) {
      currentPageByTab[tab] = meta.currentPage!;
      lastPageByTab[tab] = meta.lastPage!;
    } else {
      currentPageByTab[tab] = 1;
      lastPageByTab[tab] = 1;
    }
  }

  bool _isPaginated(String tab) => tab != 'categories';

  String _mapError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final message = _extractApiMessage(error.response?.data);

      if (status == 403) {
        return message ??
            'No tienes permisos para ver el fichero de este jugador.';
      }
      if (status == 404) {
        return message ?? 'No se encontró el jugador solicitado.';
      }
      if (status == 401) {
        return message ?? 'Tu sesión expiró. Vuelve a iniciar sesión.';
      }
      return message ?? 'No se pudo cargar la información del jugador.';
    }

    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '');
    }
    return text;
  }

  String? _extractApiMessage(dynamic data) {
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.trim().isNotEmpty) {
        return msg.trim();
      }
    }
    return null;
  }
}
