import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stopandgo/core/models/player_full_profile.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'player_file_controller.dart';

class FicheroDeJugadorScreen extends GetView<PlayerFileController> {
  const FicheroDeJugadorScreen({super.key});

  static final NumberFormat _money = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil Jugador'),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: controller.loadProfile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        final data = controller.data;
        final meta = controller.meta;
        final isLoading = controller.isLoading.value;
        final error = controller.error.value;

        if (isLoading && data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (error != null && data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: controller.loadProfile,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        if (data == null || meta == null) {
          return const Center(child: Text('No hay información disponible.'));
        }

        return RefreshIndicator(
          onRefresh: controller.loadProfile,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            children: [
              _ProfileHeader(
                player: data.player,
                viewerRoleLabel: controller.viewerRoleLabel,
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Datos personales',
                child: _KeyValueWrap(
                  items: [
                    _kv('Correo', data.personal.email),
                    _kv('Teléfono', data.personal.phone),
                    _kv('Nacimiento', _formatDateOnly(data.personal.birthdate)),
                    _kv('Lugar de nacimiento', data.personal.birthPlace),
                    _kv('CURP', data.personal.curp),
                    _kv('Dirección', data.personal.address),
                    _kv('CP', data.personal.cp),
                    _kv('Ciudad', data.personal.city),
                    _kv('Estado', data.personal.state),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Deportivo',
                child: _KeyValueWrap(
                  items: [
                    _kv('Posición', data.sport.position),
                    _kv('Catálogo', data.sport.positionCatalogName),
                    _kv('ID posición', data.sport.positionId?.toString() ?? ''),
                    _kv('Talla playera', data.sport.sizeShirt),
                    _kv('Talla pants', data.sport.sizePants),
                    _kv('Talla', data.sport.talla),
                    _kv(
                      'Peso',
                      data.sport.peso == null ? '' : '${data.sport.peso} kg',
                    ),
                    _kv('Tipo de sangre', data.sport.bloodType),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Salud',
                child: _KeyValueWrap(
                  items: [
                    _kv('Alergias', data.health.allergies),
                    _kv('Seguro', data.health.haveInsurance ? 'Sí' : 'No'),
                    _kv('Aseguradora', data.health.insuranceName),
                    _kv(
                      'Jugó en Fademac',
                      data.health.hasPlayedInFademac ? 'Sí' : 'No',
                    ),
                    _kv('Equipo Fademac', data.health.fademacTeamName),
                    _kv('Área de interés', data.health.interestArea),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Familia',
                child: Column(
                  children: [
                    _ContactCard(title: 'Padre', contact: data.family.father),
                    const SizedBox(height: 10),
                    _ContactCard(title: 'Madre', contact: data.family.mother),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Categorías',
                child: data.categories.isEmpty
                    ? const Text('No hay categorías asignadas.')
                    : Column(
                        children: data.categories
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _CategoryCard(item: item),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Documentos',
                trailing: _SummaryBadge(
                  text:
                      '${data.documents.summary.requiredCompleted}/${data.documents.summary.requiredTotal}',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryWrap(
                      items: [
                        _summary(
                          'Requeridos',
                          '${data.documents.summary.requiredTotal}',
                        ),
                        _summary(
                          'Completados',
                          '${data.documents.summary.requiredCompleted}',
                        ),
                        _summary(
                          'Pendientes',
                          '${data.documents.summary.requiredPending}',
                        ),
                        _summary(
                          'Subidos',
                          '${data.documents.summary.uploadedTotal}',
                        ),
                        _summary(
                          'Avance',
                          '${(data.documents.summary.completionRatio * 100).toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Requisitos',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (data.documents.requirements.isEmpty)
                      const Text('No hay requisitos configurados.')
                    else
                      ...data.documents.requirements.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RequirementCard(item: item),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Documentos extra',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (data.documents.extraDocuments.isEmpty)
                      const Text('No hay documentos extra.')
                    else
                      ...data.documents.extraDocuments.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _UploadedDocumentCard(item: item),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Pagos',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryWrap(
                      items: [
                        _summary(
                          'Totales',
                          '${data.payments.summary.totalCount}',
                        ),
                        _summary(
                          'Pendientes',
                          '${data.payments.summary.pendingCount}',
                        ),
                        _summary(
                          'Parciales',
                          '${data.payments.summary.partialCount}',
                        ),
                        _summary(
                          'Pagados',
                          '${data.payments.summary.paidCount}',
                        ),
                        _summary(
                          'Adeudo',
                          _money.format(data.payments.summary.totalDue),
                        ),
                        _summary(
                          'Pagado',
                          _money.format(data.payments.summary.totalPaid),
                        ),
                        _summary(
                          'Saldo',
                          _money.format(data.payments.summary.totalBalance),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Movimientos recientes',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (data.payments.recent.isEmpty)
                      const Text('No hay movimientos recientes.')
                    else
                      ...data.payments.recent.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PaymentCard(item: item),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  static MapEntry<String, String> _kv(String label, String value) {
    return MapEntry(label, value.trim().isEmpty ? '-' : value.trim());
  }

  static MapEntry<String, String> _summary(String label, String value) {
    return MapEntry(label, value.trim().isEmpty ? '-' : value.trim());
  }

  static String _formatDateOnly(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return trimmed;
    return DateFormat('dd/MM/yyyy', 'es_MX').format(parsed.toLocal());
  }

  static String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm', 'es_MX').format(date.toLocal());
  }
}

class _ProfileHeader extends StatelessWidget {
  final OrganizationPlayerIdentity player;
  final String viewerRoleLabel;

  const _ProfileHeader({required this.player, required this.viewerRoleLabel});

  @override
  Widget build(BuildContext context) {
    final name = player.fullName.trim().isEmpty ? 'Jugador' : player.fullName;
    final subtitle = [
      if (player.organization.name.trim().isNotEmpty) player.organization.name,
      if (player.alias.trim().isNotEmpty) 'Alias: ${player.alias}',
    ].join('  ·  ');
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: player.photoUrl.trim().isNotEmpty
                ? NetworkImage(player.photoUrl)
                : null,
            child: player.photoUrl.trim().isEmpty
                ? Text(initials.isEmpty ? '?' : initials)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.isEmpty ? 'Sin organización visible' : subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderChip(text: viewerRoleLabel),
                    _HeaderChip(
                      text: player.confirmed ? 'Confirmado' : 'Pendiente',
                    ),
                    _HeaderChip(text: player.isActive ? 'Activo' : 'Inactivo'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String text;

  const _HeaderChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String text;

  const _SummaryBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _KeyValueWrap extends StatelessWidget {
  final List<MapEntry<String, String>> items;

  const _KeyValueWrap({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => SizedBox(
              width: 160,
              child: _KeyValueTile(label: item.key, value: item.value),
            ),
          )
          .toList(),
    );
  }
}

class _SummaryWrap extends StatelessWidget {
  final List<MapEntry<String, String>> items;

  const _SummaryWrap({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.key, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    item.value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _KeyValueTile extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String title;
  final OrganizationPlayerContact contact;

  const _ContactCard({required this.title, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('Nombre: ${contact.name.trim().isEmpty ? '-' : contact.name}'),
          Text('Correo: ${contact.email.trim().isEmpty ? '-' : contact.email}'),
          Text(
            'Teléfono: ${contact.phone.trim().isEmpty ? '-' : contact.phone}',
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final OrganizationPlayerCategoryAssignment item;

  const _CategoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name.trim().isEmpty ? 'Categoría' : item.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusChip(status: item.status),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text('Slug: ${item.slug.trim().isEmpty ? '-' : item.slug}'),
              Text('Jersey: ${item.jerseyNumber?.toString() ?? '-'}'),
              Text(item.isCaptain ? 'Capitán' : 'No capitán'),
              Text(
                'Asignado: ${FicheroDeJugadorScreen._formatDateTime(item.assignedAt)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequirementCard extends StatelessWidget {
  final OrganizationPlayerDocumentRequirement item;

  const _RequirementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name.trim().isEmpty ? 'Requisito' : item.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusChip(status: item.isUploaded ? 'uploaded' : 'pending'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.description.trim().isEmpty
                ? 'Sin descripción'
                : item.description,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(item.isRequired ? 'Requerido' : 'Opcional'),
              Text(item.isActive ? 'Activo' : 'Inactivo'),
              Text('Orden: ${item.sortOrder}'),
              Text('Expira: ${item.expiresInDays?.toString() ?? '-'} días'),
            ],
          ),
          if (item.document != null) ...[
            const SizedBox(height: 10),
            _UploadedDocumentCard(item: item.document!),
          ],
        ],
      ),
    );
  }
}

class _UploadedDocumentCard extends StatelessWidget {
  final OrganizationPlayerUploadedDocument item;

  const _UploadedDocumentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.originalName.trim().isEmpty ? 'Documento' : item.originalName,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '${item.mimeType.isEmpty ? '-' : item.mimeType}  ·  ${_formatBytes(item.size)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Subido: ${FicheroDeJugadorScreen._formatDateTime(item.uploadedAt)}',
              ),
              if (item.requiredDocumentName.trim().isNotEmpty)
                Text('Requisito: ${item.requiredDocumentName}'),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _openDocument(item.url),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDocument(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      Get.snackbar(
        'Documento',
        'La URL del documento no está disponible.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final ok = await launchUrlString(
      trimmed,
      mode: LaunchMode.externalApplication,
    );

    if (!ok) {
      Get.snackbar(
        'Documento',
        'No se pudo abrir el documento.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _PaymentCard extends StatelessWidget {
  final OrganizationPlayerRecentPayment item;

  const _PaymentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.concept.trim().isEmpty ? 'Pago' : item.concept,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusChip(status: item.status),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Vence: ${item.dueDate == null ? '-' : DateFormat('dd/MM/yyyy', 'es_MX').format(item.dueDate!.toLocal())}',
              ),
              Text(
                'Pagado: ${item.paidAt == null ? '-' : FicheroDeJugadorScreen._formatDateTime(item.paidAt)}',
              ),
              Text(
                'Categoría: ${item.category?.name.trim().isNotEmpty == true ? item.category!.name : '-'}',
              ),
            ],
          ),
          const Divider(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                'Monto: ${FicheroDeJugadorScreen._money.format(item.amount)}',
              ),
              Text(
                'Total: ${FicheroDeJugadorScreen._money.format(item.totalDue)}',
              ),
              Text(
                'Pagado: ${FicheroDeJugadorScreen._money.format(item.amountPaid)}',
              ),
              Text(
                'Saldo: ${FicheroDeJugadorScreen._money.format(item.balance)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase().trim();
    Color color = Colors.blueGrey;
    String label = status.trim().isEmpty ? '-' : status;

    if (lower == 'paid' || lower == 'uploaded' || lower == 'active') {
      color = Colors.green;
    } else if (lower == 'pending' || lower == 'partial') {
      color = Colors.orange;
    } else if (lower == 'inactive' || lower == 'missing') {
      color = Colors.redAccent;
    }

    if (lower == 'uploaded') label = 'Subido';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(1)} ${units[unit]}';
}
