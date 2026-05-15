import 'package:flutter/material.dart';
import 'package:flutter_fireworks/flutter_fireworks.dart';
import 'package:get/get.dart';
import 'package:stopandgo/modules/birthday_greeting/birthday_greeting_controller.dart';

class BirthdayGreetingView extends GetView<BirthdayGreetingController> {
  const BirthdayGreetingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF091540),
                  Color(0xFF1B2A6B),
                  Color(0xFF3A0F4B),
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFC145).withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -30,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.14),
              ),
            ),
          ),
          FireworksDisplay(controller: controller.fireworksController),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Obx(
                    () => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton.filledTonal(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.12),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.arrow_back),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          controller.title.value,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        CircleAvatar(
                          radius: 64,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          backgroundImage: (controller.avatarUrl.value != null &&
                                  controller.avatarUrl.value!.isNotEmpty)
                              ? NetworkImage(controller.avatarUrl.value!)
                              : null,
                          child: (controller.avatarUrl.value == null ||
                                  controller.avatarUrl.value!.isEmpty)
                              ? Text(
                                  controller.recipientName.value.isNotEmpty
                                      ? controller.recipientName.value
                                          .trim()
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : '?',
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          controller.recipientName.value,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (controller.organizationName.value.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            controller.organizationName.value,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 30,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                controller.body.value,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (controller.dateLabel.value.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  controller.dateLabel.value,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFFFFD166),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
