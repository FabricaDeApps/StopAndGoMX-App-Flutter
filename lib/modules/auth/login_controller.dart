import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/models/responses/login_response.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';
import 'package:stopandgo/core/theme/theme_controller.dart';
import 'package:stopandgo/routes/app_routes.dart';

class LoginController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final bool isMultiOrg = FlavorConfig.I.organizationId == 1;

  final organizations = <OrganizationResponse>[].obs;
  final selectedOrganization = Rxn<OrganizationResponse>();
  final isLoadingOrganizations = false.obs;

  // --- Branding (logo para la vista)
  final url = RxnString();

  // Form
  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final emailFocus = FocusNode();
  final passFocus = FocusNode();

  // UI state
  final isLoading = false.obs;
  final obscure = true.obs;

  // Resultado (opcional para UI)
  final loginResponse = Rxn<LoginResponse>();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    if (isMultiOrg) {
      _loadOrganizations();
    } else {
      _loadBrandingFromStorage();
    }
  }

  /// Carga catálogo de organizaciones públicas
  Future<void> _loadOrganizations() async {
    isLoadingOrganizations.value = true;
    try {
      final list = await _api.getPublicOrganizations();
      organizations.assignAll(list);

      // Si ya tenías algo guardado en storage, recupéralo como selección
      final cached = AppStorage.getOrganization();
      if (cached != null) {
        final match = list.firstWhereOrNull((o) => o.id == cached.id);
        if (match != null) {
          onSelectOrganization(match);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo cargar el catálogo de organizaciones',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingOrganizations.value = false;
    }
  }

  /// Cuando el usuario elige una organización en el combo
  Future<void> onSelectOrganization(OrganizationResponse org) async {
    selectedOrganization.value = org;

    // 1) Actualiza FlavorConfig para que todos los endpoints usen esta org
    FlavorConfig.I.updateOrganizationId(org.id!);

    // 2) Guarda en storage para branding y futuros inicios
    await AppStorage.setOrganization(org);

    // 3) Actualiza logo y tema
    url.value = org.logo;
    Get.find<ThemeController>().refreshTheme();
  }

  void _loadBrandingFromStorage() {
    final OrganizationResponse? org = AppStorage.getOrganization();
    url.value = org?.logo;
    Get.find<ThemeController>().refreshTheme();
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Ingresa tu email';
    final hasAt = value.contains('@') && value.contains('.');
    if (!hasAt) return 'Email inválido';
    return null;
  }

  String? _validatePassword(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Ingresa tu contraseña';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Future<void> submit() async {
    final current = formKey.currentState;
    if (current == null || !current.validate()) return;

    FocusScope.of(Get.context!).unfocus();

    isLoading.value = true;
    try {
      final res = await _api.login(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      loginResponse.value = res;

      Get.snackbar(
        'Bienvenido',
        res.user.name,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      Get.offAllNamed(Routes.home);
    } catch (e) {
      Get.snackbar(
        'Error de autenticación',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /*
  Future<void> _persistSession(LoginResponse res) async {
    // 1) Tokens (en GetStorage). Si tu ApiRepository ya lo hace, no pasa nada por sobrescribir.
    await _box.write(_kAccessToken, res.accessToken);
    await _box.write(_kRefreshToken, res.refreshToken);
    await _box.write(_kTokenType, res.tokenType);
    await _box.write(_kRefreshExp, res.refreshExpiresAt);
    await _box.write(_kAccessTTLMin, res.accessExpiresInMinutes);
  }
*/

  String? validateEmailPublic(String? v) => _validateEmail(v);
  String? validatePasswordPublic(String? v) => _validatePassword(v);

  @override
  void onClose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    super.onClose();
  }
}
