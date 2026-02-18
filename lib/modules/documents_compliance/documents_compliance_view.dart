import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/models/documents_compliance.dart';

import 'documents_compliance_controller.dart';

class DocumentsComplianceView extends GetView<DocumentsComplianceController> {
  const DocumentsComplianceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cumplimiento - ${controller.categoryName}')),
      body: Obx(() {
        if (controller.isLoading.value && controller.rows.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null && controller.rows.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.error.value!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => controller.load(reset: true),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 220) {
                controller.load(reset: false);
              }
              return false;
            },
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TextField(
                  onChanged: (value) => controller.searchText.value = value,
                  decoration: const InputDecoration(
                    hintText: 'Buscar jugador por nombre o correo',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _statusChip('all', 'Todos'),
                    _statusChip('complete', 'Completos'),
                    _statusChip('incomplete', 'Con faltantes'),
                  ],
                ),
                const SizedBox(height: 12),
                _totalsSection(controller.totals.value),
                const SizedBox(height: 12),
                if (controller.rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text('No se encontraron jugadores.')),
                  )
                else
                  ...controller.rows.map(_rowCard),
                if (controller.isLoadingMore.value)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: OutlinedButton(
                        onPressed: () => controller.load(reset: false),
                        child: const Text('Cargar más'),
                      ),
                    ),
                  ),
                if (controller.error.value != null &&
                    controller.rows.isNotEmpty)
                  Card(
                    color: Colors.red.withOpacity(0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        controller.error.value!,
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _statusChip(String value, String label) {
    return Obx(() {
      final selected = controller.status.value == value;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => controller.onStatusChanged(value),
      );
    });
  }

  Widget _totalsSection(DocumentsComplianceTotals? totals) {
    if (totals == null) {
      return const SizedBox.shrink();
    }

    Widget tile(String title, int value, Color color) {
      return Container(
        width: 170,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.45)),
          color: color.withOpacity(0.09),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        tile('Obligatorios activos', totals.requiredDocuments, Colors.indigo),
        tile('Jugadores listados', totals.listedPlayers, Colors.blue),
        tile('Completos', totals.completePlayers, Colors.green),
        tile('Con faltantes', totals.incompletePlayers, Colors.orange),
      ],
    );
  }

  Widget _rowCard(DocumentsCompliancePlayerItem item) {
    final progress = (item.percentage.clamp(0, 100) / 100).toDouble();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.fullName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            if (item.email.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(item.email, style: const TextStyle(color: Colors.black54)),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                Text('Obligatorios: ${item.requiredTotal}'),
                Text('Completados: ${item.completed}'),
                Text('Faltantes: ${item.missing}'),
                Text('${item.percentage.toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 8),
          ],
        ),
      ),
    );
  }
}
