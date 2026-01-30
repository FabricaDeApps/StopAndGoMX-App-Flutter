import 'package:flutter/material.dart';
import 'package:stopandgo/core/models/dashboard_models.dart';
import 'package:stopandgo/core/models/games/games.dart';

class PlayerGamesByCategory extends StatelessWidget {
  const PlayerGamesByCategory({
    super.key,
    required this.categories,
    required this.onTapGame,
  });

  final List<PlayerDashboardCategory> categories;
  final void Function(Game g) onTapGame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (categories.isEmpty) {
      return Text('Sin categorías', style: theme.textTheme.bodySmall);
    }

    final categoriesWithGame = categories
        .where((c) => c.nextGame != null)
        .toList();

    if (categoriesWithGame.isEmpty) {
      return Text('Sin juegos próximos', style: theme.textTheme.bodySmall);
    }

    return Column(
      children: categoriesWithGame.map((c) {
        final g = c.nextGame;

        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          leading: const Icon(Icons.groups, size: 20),
          title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            g == null ? 'Sin juego próximo' : 'Ver próximo juego',
            style: theme.textTheme.bodySmall,
          ),
          children: [
            if (g == null)
              Padding(
                padding: const EdgeInsets.only(left: 44, bottom: 8),
                child: Text(
                  'Sin juego próximo',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              ListTile(
                contentPadding: const EdgeInsets.only(left: 44, right: 0),
                dense: true,
                leading: const Icon(Icons.sports_football, size: 20),
                title: Text(
                  g.opponent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${g.startsAt != null ? _fmtDate(g.startsAt!) : 'Fecha por definir'} · ${g.venue ?? 'Por definir'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onTapGame(g),
              ),
          ],
        );
      }).toList(),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
