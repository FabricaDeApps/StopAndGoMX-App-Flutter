import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stopandgo/core/network/api_repository.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class PlayerPickerSheet extends StatefulWidget {
  const PlayerPickerSheet({super.key});

  @override
  State<PlayerPickerSheet> createState() => _PlayerPickerSheetState();
}

class _PlayerPickerSheetState extends State<PlayerPickerSheet> {
  final ApiRepository _api = Get.find<ApiRepository>();

  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final players = await _api.parentMyPlayers();

      // Normaliza a List<Map<String,dynamic>>
      _all = players;
      _filtered = players;
    } catch (e) {
      _error = 'No se pudieron cargar jugadores: $e';
    } finally {
      setState(() => _loading = false);
    }
  }

  String _playerName(Map<String, dynamic> p) {
    // Ajusta keys si tu API usa otros nombres
    final first = (p['first_name'] ?? p['firstName'] ?? '').toString();
    final last = (p['last_name'] ?? p['lastName'] ?? '').toString();
    final name = (p['name'] ?? '').toString();

    final full = ('$first $last').trim();
    return full.isNotEmpty ? full : (name.isNotEmpty ? name : 'Jugador');
  }

  int _playerId(Map<String, dynamic> p) {
    final raw = p['id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();

    setState(() {
      if (q.isEmpty) {
        _filtered = _all;
      } else {
        _filtered = _all.where((p) {
          final name = _playerName(p).toLowerCase();
          return name.contains(q);
        }).toList();
      }
    });
  }

  void _pick(Map<String, dynamic> p) {
    final id = _playerId(p);
    if (id <= 0) {
      Get.snackbar('Error', 'Jugador inválido');
      return;
    }

    final name = _playerName(p);

    Get.back(result: {'id': id, 'name': name});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Selecciona un jugador',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
            else if (_filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No hay jugadores para seleccionar.'),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = _filtered[i];
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(_playerName(p)),
                      onTap: () => _pick(p),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
