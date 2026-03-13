import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/admin_player.dart';
import 'package:stopandgo/core/network/api_repository.dart';

class AdminPlayerEditController extends GetxController {
  final ApiRepository _api = Get.find<ApiRepository>();

  final formKey = GlobalKey<FormState>();
  final isSaving = false.obs;

  late final AdminPlayer player;

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final aliasCtrl = TextEditingController();
  final birthdateCtrl = TextEditingController();
  final birthPlaceCtrl = TextEditingController();
  final curpCtrl = TextEditingController();
  final positionCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cpCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final sizeShirtCtrl = TextEditingController();
  final sizePantsCtrl = TextEditingController();
  final tallaCtrl = TextEditingController();
  final pesoCtrl = TextEditingController();
  final fatherNameCtrl = TextEditingController();
  final fatherEmailCtrl = TextEditingController();
  final fatherPhoneCtrl = TextEditingController();
  final motherNameCtrl = TextEditingController();
  final motherEmailCtrl = TextEditingController();
  final motherPhoneCtrl = TextEditingController();
  final interestAreaCtrl = TextEditingController();
  final bloodTypeCtrl = TextEditingController();
  final insuranceNameCtrl = TextEditingController();
  final allergiesCtrl = TextEditingController();

  final haveInsurance = false.obs;
  final isActive = false.obs;
  final confirmed = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? const {};
    final incoming = args['player'];
    if (incoming is! AdminPlayer) {
      throw ArgumentError('player es requerido para editar');
    }
    player = incoming;
    _fillForm();
  }

  void _fillForm() {
    firstNameCtrl.text = player.firstName ?? '';
    lastNameCtrl.text = player.lastName ?? '';
    aliasCtrl.text = player.alias ?? '';
    birthdateCtrl.text = player.birthdate ?? '';
    birthPlaceCtrl.text = player.birthPlace ?? '';
    curpCtrl.text = player.curp ?? '';
    positionCtrl.text = player.position ?? '';
    phoneCtrl.text = player.phone ?? '';
    emailCtrl.text = player.email ?? '';
    addressCtrl.text = player.address ?? '';
    cpCtrl.text = player.cp ?? '';
    cityCtrl.text = player.city ?? '';
    stateCtrl.text = player.state ?? '';
    sizeShirtCtrl.text = player.sizeShirt ?? '';
    sizePantsCtrl.text = player.sizePants ?? '';
    tallaCtrl.text = player.talla ?? '';
    pesoCtrl.text = player.peso?.toString() ?? '';
    fatherNameCtrl.text = player.fatherName ?? '';
    fatherEmailCtrl.text = player.fatherEmail ?? '';
    fatherPhoneCtrl.text = player.fatherPhone ?? '';
    motherNameCtrl.text = player.motherName ?? '';
    motherEmailCtrl.text = player.motherEmail ?? '';
    motherPhoneCtrl.text = player.motherPhone ?? '';
    interestAreaCtrl.text = player.interestArea ?? '';
    bloodTypeCtrl.text = player.bloodType ?? '';
    insuranceNameCtrl.text = player.insuranceName ?? '';
    allergiesCtrl.text = player.allergies ?? '';
    haveInsurance.value = player.haveInsurance;
    isActive.value = player.isActive;
    confirmed.value = player.confirmed;
  }

  Future<void> pickBirthdate(BuildContext context) async {
    final initial =
        _parseDate(birthdateCtrl.text) ?? DateTime(2012, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    birthdateCtrl.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (isSaving.value) return;

    final payload = _buildPayload();
    if (payload.isEmpty) {
      Get.snackbar(
        'Sin cambios',
        'No hay cambios para guardar.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSaving.value = true;
    try {
      final updated = await _api.updateAdminPlayer(
        playerId: player.id,
        data: payload,
      );
      Get.back(result: updated);
      Get.snackbar(
        'Jugador actualizado',
        'Los cambios se guardaron correctamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo actualizar el jugador: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Map<String, dynamic> _buildPayload() {
    final payload = <String, dynamic>{};

    _addString(payload, 'first_name', firstNameCtrl.text, player.firstName);
    _addString(payload, 'last_name', lastNameCtrl.text, player.lastName);
    _addString(payload, 'alias', aliasCtrl.text, player.alias);
    _addString(payload, 'birthdate', birthdateCtrl.text, player.birthdate);
    _addString(payload, 'birth_place', birthPlaceCtrl.text, player.birthPlace);
    _addString(payload, 'curp', curpCtrl.text, player.curp);
    _addString(payload, 'position', positionCtrl.text, player.position);
    _addString(payload, 'phone', phoneCtrl.text, player.phone);
    _addString(payload, 'email', emailCtrl.text, player.email);
    _addString(payload, 'address', addressCtrl.text, player.address);
    _addString(payload, 'cp', cpCtrl.text, player.cp);
    _addString(payload, 'city', cityCtrl.text, player.city);
    _addString(payload, 'state', stateCtrl.text, player.state);
    _addString(payload, 'size_shirt', sizeShirtCtrl.text, player.sizeShirt);
    _addString(payload, 'size_pants', sizePantsCtrl.text, player.sizePants);
    _addString(payload, 'talla', tallaCtrl.text, player.talla);
    _addString(payload, 'father_name', fatherNameCtrl.text, player.fatherName);
    _addString(payload, 'father_email', fatherEmailCtrl.text, player.fatherEmail);
    _addString(payload, 'father_phone', fatherPhoneCtrl.text, player.fatherPhone);
    _addString(payload, 'mother_name', motherNameCtrl.text, player.motherName);
    _addString(payload, 'mother_email', motherEmailCtrl.text, player.motherEmail);
    _addString(payload, 'mother_phone', motherPhoneCtrl.text, player.motherPhone);
    _addString(
      payload,
      'interest_area',
      interestAreaCtrl.text,
      player.interestArea,
    );
    _addString(payload, 'blood_type', bloodTypeCtrl.text, player.bloodType);
    _addString(
      payload,
      'insurance_name',
      insuranceNameCtrl.text,
      player.insuranceName,
    );
    _addString(payload, 'allergies', allergiesCtrl.text, player.allergies);

    final nextPeso = _nullableNumber(pesoCtrl.text);
    if (nextPeso != player.peso) {
      payload['peso'] = nextPeso;
    }

    if (haveInsurance.value != player.haveInsurance) {
      payload['have_insurance'] = haveInsurance.value;
    }
    if (isActive.value != player.isActive) {
      payload['is_active'] = isActive.value;
    }
    if (confirmed.value != player.confirmed) {
      payload['confirmed'] = confirmed.value;
    }

    return payload;
  }

  void _addString(
    Map<String, dynamic> payload,
    String key,
    String currentValue,
    String? originalValue,
  ) {
    final next = _nullableText(currentValue);
    final prev = _nullableText(originalValue);
    if (next != prev) {
      payload[key] = next;
    }
  }

  String? _nullableText(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  num? _nullableNumber(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return num.tryParse(text);
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  String? optionalEmailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!re.hasMatch(text)) return 'Correo inválido';
    return null;
  }

  @override
  void onClose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    aliasCtrl.dispose();
    birthdateCtrl.dispose();
    birthPlaceCtrl.dispose();
    curpCtrl.dispose();
    positionCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    addressCtrl.dispose();
    cpCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    sizeShirtCtrl.dispose();
    sizePantsCtrl.dispose();
    tallaCtrl.dispose();
    pesoCtrl.dispose();
    fatherNameCtrl.dispose();
    fatherEmailCtrl.dispose();
    fatherPhoneCtrl.dispose();
    motherNameCtrl.dispose();
    motherEmailCtrl.dispose();
    motherPhoneCtrl.dispose();
    interestAreaCtrl.dispose();
    bloodTypeCtrl.dispose();
    insuranceNameCtrl.dispose();
    allergiesCtrl.dispose();
    super.onClose();
  }
}
