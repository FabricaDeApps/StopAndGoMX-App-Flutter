// lib/modules/signin/sign_in_view.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/modules/sign_in/sign_in_controller.dart';

class SignInView extends GetView<SignInController> {
  const SignInView({super.key});

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
                              'Asegúrate de que este sea tu equipo',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),

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

                      Obx(() {
                        return DropdownButtonFormField<String>(
                          value: controller.role.value,
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

                      FilledButton.icon(
                        onPressed: controller.isLoading.value
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
                  color: Colors.black.withOpacity(.25),
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
