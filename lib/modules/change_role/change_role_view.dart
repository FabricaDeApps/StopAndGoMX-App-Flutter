import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'change_role_controller.dart';

class ChangeRoleView extends GetView<ChangeRoleController> {
  const ChangeRoleView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.95),
              theme.colorScheme.secondary.withOpacity(0.85),
              theme.colorScheme.tertiary.withOpacity(0.75),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: controller.pulseController,
                    builder: (_, __) {
                      final t = controller.pulse.value;
                      return Transform.scale(
                        scale: 0.9 + (t * 0.2),
                        child: Transform.rotate(
                          angle: t * 0.35,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.45),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.swap_horiz_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Obx(
                    () => Text(
                      'Cambiando rol a ${controller.roleLabel}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Actualizando permisos y recargando tu sesión...',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
