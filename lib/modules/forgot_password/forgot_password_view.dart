import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/modules/forgot_password/forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('¿Olvidaste tu contraseña?')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Obx(() {
                    if (controller.hasSuccess) {
                      return _SuccessContent(
                        message: controller.successMessage.value,
                        onBack: controller.backToLogin,
                      );
                    }

                    return Form(
                      key: controller.formKey,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 40,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Recuperar acceso',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            Semantics(
                              label: 'Campo correo electrónico',
                              textField: true,
                              child: TextFormField(
                                controller: controller.emailCtrl,
                                focusNode: controller.emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  hintText: 'usuario@dominio.com',
                                  prefixIcon: Icon(Icons.alternate_email),
                                ),
                                validator: controller.validateEmail,
                                onFieldSubmitted: (_) => controller.submit(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Obx(() {
                              final error = controller.errorMessage.value;
                              if (error == null) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  error,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              );
                            }),
                            SizedBox(
                              width: double.infinity,
                              child: Obx(
                                () => FilledButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : controller.submit,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                  ),
                                  child: controller.isLoading.value
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Enviar enlace'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: controller.backToLogin,
                              style: TextButton.styleFrom(
                                minimumSize: const Size(double.infinity, 44),
                              ),
                              child: const Text('Volver a iniciar sesión'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _SuccessContent({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onBack,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Volver a iniciar sesión'),
        ),
      ],
    );
  }
}
