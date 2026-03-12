import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/responses/organization_response.dart';
import 'team_selector_controller.dart';

class TeamSelectorView extends GetView<TeamSelectorController> {
  const TeamSelectorView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona tu equipo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              TextField(
                controller: controller.searchCtrl,
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar equipo',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller.searchCtrl,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        onPressed: () {
                          controller.searchCtrl.clear();
                          controller.onSearchChanged('');
                        },
                        icon: const Icon(Icons.close),
                      );
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.error.value != null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.error.value!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: controller.retry,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  final list = controller.filteredOrganizations;
                  if (list.isEmpty) {
                    return const Center(
                      child: Text('No hay equipos que coincidan'),
                    );
                  }

                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final org = list[index];
                      return _OrganizationTile(
                        org: org,
                        logoUrl: controller.logoUrl(org),
                        selectedId: controller.selectedOrganization.value?.id,
                        onTap: () => controller.onSelectOrganization(org),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganizationTile extends StatelessWidget {
  const _OrganizationTile({
    required this.org,
    required this.logoUrl,
    required this.selectedId,
    required this.onTap,
  });

  final OrganizationResponse org;
  final String logoUrl;
  final int? selectedId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selectedId == org.id;
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: logoUrl.isEmpty
                      ? const _FallbackLogo()
                      : CachedNetworkImage(
                          imageUrl: logoUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, _) => const Center(
                            child: SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const _FallbackLogo(),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  org.name.trim().isEmpty ? org.slug : org.name,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.shield_outlined),
    );
  }
}
