import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/modules/admin_player_edit/admin_player_edit_controller.dart';

class AdminPlayerEditView extends GetView<AdminPlayerEditController> {
  const AdminPlayerEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.player.displayName),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: controller.formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Section(
                          title: 'Datos básicos',
                          children: [
                            _textField(
                              controller: controller.firstNameCtrl,
                              label: 'Nombre',
                            ),
                            _textField(
                              controller: controller.lastNameCtrl,
                              label: 'Apellidos',
                            ),
                            _textField(
                              controller: controller.aliasCtrl,
                              label: 'Alias',
                            ),
                            _dateField(context),
                            const SizedBox(height: 8),
                            _textField(
                              controller: controller.birthPlaceCtrl,
                              label: 'Lugar de nacimiento',
                            ),
                            _textField(
                              controller: controller.curpCtrl,
                              label: 'CURP',
                            ),
                            _textField(
                              controller: controller.positionCtrl,
                              label: 'Posición',
                            ),
                            _textField(
                              controller: controller.pesoCtrl,
                              label: 'Peso',
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ],
                        ),
                        _Section(
                          title: 'Contacto',
                          children: [
                            _textField(
                              controller: controller.phoneCtrl,
                              label: 'Teléfono',
                              keyboardType: TextInputType.phone,
                            ),
                            _textField(
                              controller: controller.emailCtrl,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: controller.optionalEmailValidator,
                            ),
                            _textField(
                              controller: controller.addressCtrl,
                              label: 'Dirección',
                            ),
                            _textField(
                              controller: controller.cpCtrl,
                              label: 'Código postal',
                              keyboardType: TextInputType.number,
                            ),
                            _textField(
                              controller: controller.cityCtrl,
                              label: 'Ciudad',
                            ),
                            _textField(
                              controller: controller.stateCtrl,
                              label: 'Estado',
                            ),
                          ],
                        ),
                        _Section(
                          title: 'Uniforme',
                          children: [
                            _textField(
                              controller: controller.sizeShirtCtrl,
                              label: 'Talla playera',
                            ),
                            _textField(
                              controller: controller.sizePantsCtrl,
                              label: 'Talla pants',
                            ),
                            _textField(
                              controller: controller.tallaCtrl,
                              label: 'Talla general',
                            ),
                          ],
                        ),
                        _Section(
                          title: 'Padre o tutor',
                          children: [
                            _textField(
                              controller: controller.fatherNameCtrl,
                              label: 'Nombre del padre',
                            ),
                            _textField(
                              controller: controller.fatherEmailCtrl,
                              label: 'Email del padre',
                              keyboardType: TextInputType.emailAddress,
                              validator: controller.optionalEmailValidator,
                            ),
                            _textField(
                              controller: controller.fatherPhoneCtrl,
                              label: 'Teléfono del padre',
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                        _Section(
                          title: 'Madre o tutora',
                          children: [
                            _textField(
                              controller: controller.motherNameCtrl,
                              label: 'Nombre de la madre',
                            ),
                            _textField(
                              controller: controller.motherEmailCtrl,
                              label: 'Email de la madre',
                              keyboardType: TextInputType.emailAddress,
                              validator: controller.optionalEmailValidator,
                            ),
                            _textField(
                              controller: controller.motherPhoneCtrl,
                              label: 'Teléfono de la madre',
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                        _Section(
                          title: 'Salud y extras',
                          children: [
                            _textField(
                              controller: controller.interestAreaCtrl,
                              label: 'Área de interés',
                            ),
                            _textField(
                              controller: controller.bloodTypeCtrl,
                              label: 'Tipo de sangre',
                            ),
                            Obx(
                              () => SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Tiene seguro'),
                                value: controller.haveInsurance.value,
                                onChanged: (value) =>
                                    controller.haveInsurance.value = value,
                              ),
                            ),
                            _textField(
                              controller: controller.insuranceNameCtrl,
                              label: 'Nombre del seguro',
                            ),
                            _textField(
                              controller: controller.allergiesCtrl,
                              label: 'Alergias',
                              maxLines: 3,
                            ),
                          ],
                        ),
                        _Section(
                          title: 'Estado del jugador',
                          children: [
                            Obx(
                              () => SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Activo'),
                                value: controller.isActive.value,
                                onChanged: (value) =>
                                    controller.isActive.value = value,
                              ),
                            ),
                            Obx(
                              () => SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Confirmado'),
                                value: controller.confirmed.value,
                                onChanged: (value) =>
                                    controller.confirmed.value = value,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Obx(
                      () => SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: controller.isSaving.value
                              ? null
                              : controller.save,
                          icon: controller.isSaving.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            controller.isSaving.value
                                ? 'Guardando...'
                                : 'Guardar cambios',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateField(BuildContext context) {
    return TextFormField(
      controller: controller.birthdateCtrl,
      readOnly: true,
      onTap: () => controller.pickBirthdate(context),
      decoration: const InputDecoration(
        labelText: 'Fecha de nacimiento',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today_outlined),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
