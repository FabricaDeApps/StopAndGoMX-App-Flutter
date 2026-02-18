import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:stopandgo/core/models/player_file.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'player_file_controller.dart';

class FicheroDeJugadorScreen extends GetView<PlayerFileController> {
  const FicheroDeJugadorScreen({super.key});

  static const Map<String, String> _tabTitles = {
    'categories': 'Categorías',
    'trainings': 'Entrenamientos',
    'payments': 'Pagos',
    'documents': 'Documentos',
  };

  static final NumberFormat _money = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fichero de Jugador'),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: controller.refreshActiveTab,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        final activeTab = controller.activeTab.value;

        return Column(
          children: [
            _PlayerHeader(
              player: controller.player.value,
              fallbackName: controller.playerDisplayName,
            ),
            Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: TabBar(
                controller: controller.tabController,
                onTap: controller.onTabTapped,
                isScrollable: true,
                tabs: PlayerFileController.tabs
                    .map((tab) => Tab(text: _tabTitles[tab] ?? tab))
                    .toList(),
              ),
            ),
            Expanded(child: _buildTabContent(context, activeTab)),
          ],
        );
      }),
    );
  }

  Widget _buildTabContent(BuildContext context, String tab) {
    final isLoading = controller.isTabLoading(tab);
    final error = controller.tabError(tab);
    final list = controller.itemsFor(tab);

    if (isLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                onPressed: controller.refreshActiveTab,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refreshActiveTab,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Text(
                'No hay información en ${_tabTitles[tab]?.toLowerCase() ?? tab}.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refreshActiveTab,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 220) {
            controller.loadMoreActiveTab();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          itemCount: list.length + 1,
          itemBuilder: (context, index) {
            if (index == list.length) {
              return _buildPaginationFooter(tab);
            }

            final item = list[index];
            switch (tab) {
              case 'categories':
                return _categoryCard(item as PlayerFileCategoryItem);
              case 'trainings':
                return _trainingCard(item as PlayerFileTrainingItem);
              case 'payments':
                return _paymentCard(item as PlayerFilePaymentItem);
              case 'documents':
                return _documentCard(item as PlayerFileDocumentItem);
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(String tab) {
    final isLoadingMore = controller.isTabLoadingMore(tab);
    final hasMore = controller.hasMore(tab);

    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!hasMore || tab == 'categories') {
      return const SizedBox(height: 8);
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'Desliza para cargar más',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  Widget _categoryCard(PlayerFileCategoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(item.name.isEmpty ? 'Categoría' : item.name),
        subtitle: Text(
          'Jersey: ${item.jerseyNumber?.toString() ?? '-'}'
          '${item.isCaptain ? '  ·  Capitán' : ''}',
        ),
        trailing: _statusChip(item.status),
      ),
    );
  }

  Widget _trainingCard(PlayerFileTrainingItem item) {
    final training = item.training;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(training?.startsAt),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _statusChip(item.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('Categoría: ${training?.category?.name ?? '-'}'),
            const SizedBox(height: 4),
            Text(
              'Sede: ${training?.venue.isNotEmpty == true ? training!.venue : '-'}',
            ),
            if (item.note.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Nota: ${item.note}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _paymentCard(PlayerFilePaymentItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.concept.isEmpty ? 'Pago' : item.concept,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _statusChip(item.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('Vence: ${_formatDate(item.dueDate)}'),
            const SizedBox(height: 4),
            Text('Categoría: ${item.category?.name ?? '-'}'),
            const Divider(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text('Monto: ${_money.format(item.amount)}'),
                Text('Pagado: ${_money.format(item.amountPaid)}'),
                Text('Saldo: ${_money.format(item.balance)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentCard(PlayerFileDocumentItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.originalName.isEmpty ? 'Documento' : item.originalName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '${item.mimeType}  ·  ${_formatBytes(item.size)}  ·  ${_formatDate(item.uploadedAt)}',
              style: const TextStyle(color: Colors.black54),
            ),
            if (item.requiredDocument != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Requisito: ${item.requiredDocument!.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _openDocument(item.downloadUrl),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDocument(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      Get.snackbar(
        'Error',
        'URL de descarga no disponible.',
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
        'Error',
        'No se pudo abrir el documento.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _statusChip(String status) {
    final lower = status.toLowerCase().trim();
    Color color = Colors.blueGrey;
    if (lower == 'paid' || lower == 'completed' || lower == 'present') {
      color = Colors.green;
    } else if (lower == 'pending' || lower == 'partial') {
      color = Colors.orange;
    } else if (lower == 'missing' ||
        lower == 'absent' ||
        lower == 'failed' ||
        lower == 'cancelled' ||
        lower == 'canceled') {
      color = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.isEmpty ? '-' : status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm', 'es_MX').format(date.toLocal());
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
}

class _PlayerHeader extends StatelessWidget {
  final PlayerFilePlayer? player;
  final String fallbackName;

  const _PlayerHeader({required this.player, required this.fallbackName});

  @override
  Widget build(BuildContext context) {
    final name = player?.fullName ?? fallbackName;
    final email = player?.email ?? '';
    final position = player?.position ?? '';
    final photoUrl = player?.photoUrl ?? '';
    final initials = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.07),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl.isEmpty
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email.isEmpty ? 'Sin correo' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  position.isEmpty ? 'Posición: -' : 'Posición: $position',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
