import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'my_profile_controller.dart';

class MyProfileView extends GetView<MyProfileController> {
  const MyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil'), centerTitle: true),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Datos de perfil ----
                  Text(
                    'Información de perfil',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: controller.nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: controller.emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: controller.birthdateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de nacimiento (opcional)',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    onTap: () async {
                      final now = DateTime.now();
                      final initial =
                          DateTime.tryParse(controller.birthdateCtrl.text) ??
                          DateTime(now.year - 12, now.month, now.day);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(1940, 1, 1),
                        lastDate: now,
                      );
                      if (picked == null) return;
                      final mm = picked.month.toString().padLeft(2, '0');
                      final dd = picked.day.toString().padLeft(2, '0');
                      controller.birthdateCtrl.text = '${picked.year}-$mm-$dd';
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: controller.phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: controller.curpCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'CURP (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: controller.selectedRole.value,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(_roleLabel(r)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      controller.selectedRole.value = value;
                    },
                  ),
                  const SizedBox(height: 16),

                  Obx(() {
                    return ElevatedButton(
                      onPressed: controller.isSavingProfile.value
                          ? null
                          : controller.updateProfile,
                      child: controller.isSavingProfile.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Actualizar perfil'),
                    );
                  }),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ---- Cambiar contraseña ----
                  Text(
                    'Cambiar contraseña',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: controller.currentPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña actual',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: controller.newPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: controller.confirmPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar nueva contraseña',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Obx(() {
                    return ElevatedButton(
                      onPressed: controller.isChangingPassword.value
                          ? null
                          : controller.changePassword,
                      child: controller.isChangingPassword.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Cambiar contraseña'),
                    );
                  }),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ---- Eliminar cuenta ----
                  Text(
                    'Al proceder con la eliminación, tu cuenta será desactivada de manera permanente y tus datos personales serán eliminados o anonimizados conforme a nuestras políticas. Esta acción no se puede deshacer.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Obx(() {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: controller.isDeleting.value
                          ? null
                          : controller.confirmDeleteAccount,
                      child: controller.isDeleting.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Eliminar cuenta'),
                    );
                  }),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  static String _roleLabel(String role) {
    switch (role) {
      case 'parent':
        return 'Padre/Madre';
      case 'player':
        return 'Jugador';
      case 'manager':
        return 'Manager';
      default:
        return role;
    }
  }
}
