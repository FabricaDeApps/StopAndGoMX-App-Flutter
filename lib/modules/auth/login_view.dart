import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/config/flavor_config.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';
import 'package:stopandgo/modules/webview/webview_page.dart';
import 'package:stopandgo/routes/app_routes.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text('Iniciar sesión'), centerTitle: true),
      body: LayoutBuilder(
        builder: (context, viewportConstraints) {
          final keyboard = MediaQuery.of(context).viewInsets.bottom > 0;
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  (bottomInset > 0 ? bottomInset : 20) + 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        viewportConstraints.maxHeight -
                        (MediaQuery.of(context).padding.top + kToolbarHeight),
                  ),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (controller.isMultiOrg) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Selecciona tu club',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Obx(() {
                            if (controller.isLoadingOrganizations.value) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final orgs = controller.organizations;
                            return DropdownButtonFormField<
                              OrganizationResponse
                            >(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.sports_football),
                                border: OutlineInputBorder(),
                              ),
                              hint: const Text('Elige tu organización'),
                              value: controller.selectedOrganization.value,
                              items: orgs
                                  .map(
                                    (o) =>
                                        DropdownMenuItem<OrganizationResponse>(
                                          value: o,
                                          child: Text(
                                            o.name ?? o.slug ?? 'Org #${o.id}',
                                          ),
                                        ),
                                  )
                                  .toList(),
                              onChanged: (org) {
                                if (org != null) {
                                  controller.onSelectOrganization(org);
                                }
                              },
                              validator: (value) {
                                if (controller.isMultiOrg &&
                                    controller.selectedOrganization.value ==
                                        null) {
                                  return 'Selecciona una organización';
                                }
                                return null;
                              },
                            );
                          }),
                          const SizedBox(height: 20),
                        ],
                        Obx(() {
                          final imageUrl = controller.url.value ?? '';

                          if (imageUrl.isEmpty) {
                            return Icon(
                              Icons.image_not_supported_outlined,
                              color: theme.colorScheme.primary,
                              size: keyboard ? 40 : 64,
                            );
                          }

                          return CachedNetworkImage(
                            key: ValueKey(imageUrl),
                            imageUrl: imageUrl,
                            width: keyboard ? 140 : 200,
                            height: keyboard ? 140 : 200,
                            fit: BoxFit.contain,
                            fadeInDuration: const Duration(milliseconds: 250),
                            placeholder: (context, _) => const SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                            errorWidget: (context, _, __) => Icon(
                              Icons.image_not_supported_outlined,
                              color: theme.colorScheme.primary,
                              size: keyboard ? 40 : 64,
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        Text(
                          'Bienvenido',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controller.emailCtrl,
                          focusNode: controller.emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'tu@email.com',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: controller.validateEmailPublic,
                          onFieldSubmitted: (_) {
                            controller.passFocus.requestFocus();
                          },
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => TextFormField(
                            controller: controller.passCtrl,
                            focusNode: controller.passFocus,
                            obscureText: controller.obscure.value,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => controller.obscure.toggle(),
                                icon: Icon(
                                  controller.obscure.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                tooltip: controller.obscure.value
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                              ),
                            ),
                            validator: controller.validatePasswordPublic,
                            onFieldSubmitted: (_) => controller.submit(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Get.toNamed(Routes.forgotPassword),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(44, 44),
                            ),
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: Obx(
                            () => FilledButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.submit,
                              child: controller.isLoading.value
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Ingresar'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Get.toNamed(Routes.signIn);
                            },
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Crear cuenta'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'Zona de jugador',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: () async {
                              final orgName =
                                  controller.selectedOrganization.value?.name;
                              final clubLabel =
                                  (orgName != null && orgName.trim().isNotEmpty)
                                  ? orgName
                                  : 'este club';

                              if (!FlavorConfig.I.isCustom) {
                                final confirm = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: const Text('Confirmar club'),
                                    content: Text(
                                      '¿Confirmas que "$clubLabel" es tu club?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Get.back(result: false),
                                        child: const Text('No'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Get.back(result: true),
                                        child: const Text('Sí'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm != true) return;
                              }

                              final slug = controller
                                  .selectedOrganization
                                  .value
                                  ?.slug
                                  .trim();
                              if (slug == null || slug.isEmpty) {
                                Get.snackbar(
                                  'Pre-registro',
                                  'No se encontró el club. Selecciónalo de nuevo.',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }

                              final url =
                                  'https://$slug.stopandgomx.app/pre-register';

                              Get.to(
                                () => AppWebViewPage(
                                  title: 'Registrar jugador',
                                  url: url,
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              textStyle: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            icon: const Icon(Icons.app_registration_rounded),
                            label: const Text('Pre-Registro de Jugador'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
