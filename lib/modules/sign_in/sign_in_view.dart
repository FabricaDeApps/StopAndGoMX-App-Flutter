// lib/modules/signin/sign_in_view.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:stopandgo/modules/sign_in/sign_in_controller.dart';
import 'package:stopandgo/modules/webview/webview_page.dart';

class SignInView extends GetView<SignInController> {
  const SignInView({super.key});

  void _openPrivacyPolicy() {
    final url = controller.privacyPolicyUrl;
    if (url.isEmpty) {
      Get.snackbar(
        'Privacidad',
        'No se pudo obtener la organización actual.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.to(() => AppWebViewPage(title: 'Políticas de privacidad', url: url));
  }

  Widget _privacyCheckbox(BuildContext context) {
    return Obx(
      () => CheckboxListTile(
        value: controller.privacyAccepted.value,
        onChanged: (v) => controller.privacyAccepted.value = v ?? false,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: Text.rich(
          TextSpan(
            text: 'Acepto las ',
            children: [
              TextSpan(
                text: 'políticas de privacidad',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()..onTap = _openPrivacyPolicy,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de usuario')),
      body: Obx(() {
        return Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Obx(() {
                        final logoUrl = controller.organizationLogoUrl;
                        return Column(
                          children: [
                            if (logoUrl.isNotEmpty)
                              CachedNetworkImage(
                                key: ValueKey(logoUrl),
                                imageUrl: logoUrl,
                                width: 120,
                                height: 120,
                                fit: BoxFit.contain,
                                placeholder: (context, _) => const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, _, __) =>
                                    const Icon(Icons.shield_outlined, size: 52),
                              )
                            else
                              const Icon(Icons.shield_outlined, size: 52),
                            const SizedBox(height: 8),
                            Text(
                              controller.organizationName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Para activar Google y Apple, primero debes aceptar las políticas de privacidad.',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            if (controller.requiresTeamConfirmation) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Asegúrate de que este sea tu equipo',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                      if (!controller.isSocialMode) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                controller.isLoading.value ||
                                    !controller.privacyAccepted.value
                                ? null
                                : controller.submitGoogle,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF202124),
                              side: const BorderSide(color: Color(0xFFDADCE0)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            icon: const Text(
                              'G',
                              style: TextStyle(
                                color: Color(0xFF4285F4),
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            label: const _GoogleButtonLabel(),
                          ),
                        ),
                        if (controller.showAppleButton) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed:
                                  controller.isLoading.value ||
                                      !controller.privacyAccepted.value
                                  ? null
                                  : controller.submitApple,
                              icon: const Icon(Icons.apple),
                              label: const Text('Continuar con Apple'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _privacyCheckbox(context),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                'o regístrate manualmente',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ] else ...[
                        _SocialRegisterSummary(controller: controller),
                        const SizedBox(height: 8),
                        _privacyCheckbox(context),
                        const SizedBox(height: 14),
                      ],

                      TextFormField(
                        controller: controller.nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          hintText: 'Ej. Juan Pérez',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingresa tu nombre'
                            : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      if (controller.isSocialMode) ...[
                        TextFormField(
                          controller: controller.emailCtrl,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText:
                                'Email de ${controller.socialProviderLabel}',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: controller.clearSocialMode,
                              tooltip: 'Usar otro método',
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        TextFormField(
                          controller: controller.emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'ejemplo@correo.com',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'Ingresa tu email';
                            final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                            if (!re.hasMatch(value)) return 'Email inválido';
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => TextFormField(
                            controller: controller.passCtrl,
                            obscureText: controller.isObscure.value,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () => controller.isObscure.toggle(),
                                icon: Icon(
                                  controller.isObscure.value
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.length < 8) {
                                return 'La contraseña debe tener al menos 8 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => TextFormField(
                            controller: controller.confirmPassCtrl,
                            obscureText: controller.isConfirmObscure.value,
                            decoration: InputDecoration(
                              labelText: 'Confirmar contraseña',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    controller.isConfirmObscure.toggle(),
                                icon: Icon(
                                  controller.isConfirmObscure.value
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                            validator: controller.validateConfirmPassword,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (controller.requiresTeamConfirmation) ...[
                        Obx(
                          () => CheckboxListTile(
                            value: controller.teamConfirmed.value,
                            onChanged: (v) =>
                                controller.teamConfirmed.value = v ?? false,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Confirmo que mi equipo es ${controller.organizationName}',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      Obx(() {
                        return DropdownButtonFormField<String>(
                          initialValue: controller.role.value,
                          items: controller.availableRoles.map((r) {
                            return DropdownMenuItem<String>(
                              value: r,
                              child: Text(controller.roleLabel(r)),
                            );
                          }).toList(),
                          onChanged: (v) => controller.role.value = v,
                          decoration: const InputDecoration(
                            labelText: 'Rol',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Selecciona un rol'
                              : null,
                        );
                      }),

                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: _openPrivacyPolicy,
                          child: const Text(
                            'Ver Políticas de Privacidad',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      FilledButton.icon(
                        onPressed:
                            controller.isLoading.value ||
                                !controller.privacyAccepted.value
                            ? null
                            : () => controller.submit(),
                        icon: controller.isLoading.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add_alt_1),
                        label: Text(
                          controller.isLoading.value
                              ? 'Registrando...'
                              : 'Registrar',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Overlay de carga fancy
            if (controller.isLoading.value)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.25),
                  child: const Center(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 12),
                            Text('Procesando...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _GoogleButtonLabel extends StatelessWidget {
  const _GoogleButtonLabel();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Continuar con Google',
      style: TextStyle(fontWeight: FontWeight.w600),
    );
  }
}

class _SocialRegisterSummary extends StatelessWidget {
  const _SocialRegisterSummary({required this.controller});

  final SignInController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            child: Text(controller.socialProviderLabel.characters.first),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registro con ${controller.socialProviderLabel}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(controller.socialEmail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: controller.clearSocialMode,
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
  }
}
