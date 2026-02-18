import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/documents_compliance.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class DocumentsComplianceController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  late final int categoryId;
  late final String categoryName;

  static const int _perPage = 15;

  final rows = <DocumentsCompliancePlayerItem>[].obs;
  final meta = Rxn<DocumentsComplianceMeta>();
  final totals = Rxn<DocumentsComplianceTotals>();

  final searchText = ''.obs;
  final status = 'all'.obs; // all | complete | incomplete

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();

  int _requestToken = 0;
  Worker? _searchWorker;

  bool get hasMore {
    final m = meta.value;
    if (m == null) return false;
    return m.currentPage < m.lastPage;
  }

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments is Map
        ? Get.arguments as Map
        : <String, dynamic>{};
    categoryId =
        args['categoryId'] as int? ?? AppStorage.getSelectedCategoryId() ?? 0;
    categoryName =
        args['categoryName']?.toString() ??
        AppStorage.getSelectedCategoryName() ??
        'Categoría';

    _searchWorker = debounce<String>(
      searchText,
      (_) => load(reset: true),
      time: const Duration(milliseconds: 450),
    );

    load(reset: true);
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    super.onClose();
  }

  Future<void> refreshData() => load(reset: true);

  Future<void> onStatusChanged(String next) async {
    if (status.value == next) return;
    status.value = next;
    await load(reset: true);
  }

  Future<void> load({required bool reset}) async {
    if (categoryId <= 0) {
      error.value = 'No se encontró una categoría seleccionada.';
      rows.clear();
      totals.value = null;
      meta.value = null;
      return;
    }

    if (reset) {
      if (isLoading.value) return;
    } else {
      if (isLoading.value || isLoadingMore.value || !hasMore) return;
    }

    final token = ++_requestToken;
    final nextPage = reset ? 1 : (meta.value?.currentPage ?? 1) + 1;

    if (reset) {
      isLoading.value = true;
      error.value = null;
    } else {
      isLoadingMore.value = true;
    }

    try {
      final response = await _api.fetchDocumentsCompliance(
        categoryId: categoryId,
        q: searchText.value.trim(),
        status: status.value,
        page: nextPage,
        perPage: _perPage,
      );

      if (_requestToken != token) return;

      totals.value = response.totals;
      meta.value = response.meta;

      if (reset) {
        rows.assignAll(response.data);
      } else {
        final ids = rows.map((e) => e.playerId).toSet();
        rows.addAll(response.data.where((e) => !ids.contains(e.playerId)));
      }
    } catch (e) {
      if (_requestToken != token) return;
      error.value = _mapError(e);
    } finally {
      if (_requestToken == token) {
        isLoading.value = false;
        isLoadingMore.value = false;
      }
    }
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      final msg = _extractMessage(error.response?.data);

      if (code == 403) {
        return msg ?? 'No tienes permisos para ver este cumplimiento.';
      }
      if (code == 401) {
        return msg ?? 'Tu sesión expiró. Vuelve a iniciar sesión.';
      }
      if (code == 404) {
        return msg ?? 'No se encontró la categoría solicitada.';
      }
      return msg ?? 'No se pudo cargar el cumplimiento de documentos.';
    }

    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '');
    }
    return text;
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }
}
