import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/players/parents_model.dart';
import '../../../core/network/api_repository.dart';

class ParentsInfoController extends GetxController {
  final _api = Get.find<ApiRepository>();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final error = RxnString();

  // Modelo
  final parents = Rxn<ParentsModel>();

  // Controllers de formulario
  final fatherNameCtrl = TextEditingController();
  final fatherEmailCtrl = TextEditingController();
  final fatherPhoneCtrl = TextEditingController();
  final motherNameCtrl = TextEditingController();
  final motherEmailCtrl = TextEditingController();
  final motherPhoneCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;

      final res = await _api.getMyParents();
      if (res == null) {
        error.value = 'No fue posible cargar la información';
        return;
      }

      parents.value = res;

      // llenar form
      fatherNameCtrl.text = res.fatherName ?? '';
      fatherEmailCtrl.text = res.fatherEmail ?? '';
      fatherPhoneCtrl.text = res.fatherPhone ?? '';
      motherNameCtrl.text = res.motherName ?? '';
      motherEmailCtrl.text = res.motherEmail ?? '';
      motherPhoneCtrl.text = res.motherPhone ?? '';
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> save() async {
    try {
      isSaving.value = true;
      error.value = null;

      final model = ParentsModel(
        fatherName: fatherNameCtrl.text.trim().isEmpty
            ? null
            : fatherNameCtrl.text.trim(),
        fatherEmail: fatherEmailCtrl.text.trim().isEmpty
            ? null
            : fatherEmailCtrl.text.trim(),
        fatherPhone: fatherPhoneCtrl.text.trim().isEmpty
            ? null
            : fatherPhoneCtrl.text.trim(),
        motherName: motherNameCtrl.text.trim().isEmpty
            ? null
            : motherNameCtrl.text.trim(),
        motherEmail: motherEmailCtrl.text.trim().isEmpty
            ? null
            : motherEmailCtrl.text.trim(),
        motherPhone: motherPhoneCtrl.text.trim().isEmpty
            ? null
            : motherPhoneCtrl.text.trim(),
      );

      final ok = await _api.updateMyParents(parents: model);
      if (!ok) {
        error.value = 'No se pudo guardar la información';
        return;
      }

      parents.value = model;
      Get.snackbar(
        'Guardado',
        'Datos actualizados correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      error.value = e.toString();
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    fatherNameCtrl.dispose();
    fatherEmailCtrl.dispose();
    fatherPhoneCtrl.dispose();
    motherNameCtrl.dispose();
    motherEmailCtrl.dispose();
    motherPhoneCtrl.dispose();
    super.onClose();
  }
}
