import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/theme/theme_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';

class TeamSelectorController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final organizations = <OrganizationResponse>[].obs;
  final searchCtrl = TextEditingController();
  final searchQuery = ''.obs;
  final isLoading = false.obs;
  final error = RxnString();
  final selectedOrganization = Rxn<OrganizationResponse>();

  bool get isMultiOrg => !FlavorConfig.I.isCustom;

  List<OrganizationResponse> get filteredOrganizations {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return organizations;
    return organizations.where((org) {
      final name = org.name.toLowerCase();
      final slug = org.slug.toLowerCase();
      return name.contains(q) || slug.contains(q);
    }).toList();
  }

  @override
  void onReady() {
    super.onReady();
    if (!isMultiOrg) {
      Get.offAllNamed(Routes.login);
      return;
    }
    _loadOrganizations();
  }

  Future<void> _loadOrganizations() async {
    isLoading.value = true;
    error.value = null;
    try {
      final list = await _api.getPublicOrganizations();
      organizations.assignAll(list);

      final cached = AppStorage.getOrganization();
      if (cached != null) {
        final match = list.firstWhereOrNull((o) => o.id == cached.id);
        if (match != null) {
          selectedOrganization.value = match;
        }
      }
    } catch (e) {
      error.value = 'No se pudo cargar el catálogo de equipos';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onSelectOrganization(OrganizationResponse org) async {
    selectedOrganization.value = org;
    final id = org.id;
    if (id <= 0) {
      Get.snackbar(
        'Equipo inválido',
        'No se pudo identificar el equipo seleccionado',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    FlavorConfig.I.updateOrganizationId(id);
    await AppStorage.setPendingOrganizationId(id);
    await AppStorage.setOrganization(org);
    Get.find<ThemeController>().refreshTheme();

    Get.offAllNamed(Routes.login);
  }

  String logoUrl(OrganizationResponse org) {
    final path = org.logo.trim();
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return 'https://stopandgomx.app/storage/$cleanPath';
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  Future<void> retry() => _loadOrganizations();

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}
