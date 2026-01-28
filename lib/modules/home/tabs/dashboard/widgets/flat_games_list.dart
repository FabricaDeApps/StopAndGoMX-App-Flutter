import 'package:flutter/material.dart';
import 'package:stopandgo/core/models/games.dart';

class FlatGamesList extends StatelessWidget {
  const FlatGamesList({
    super.key,
    required this.games,
    required this.onTapGame,
  });

  final List<Game> games;
  final void Function(Game g) onTapGame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (games.isEmpty) {
      return Text('Sin juegos próximos', style: theme.textTheme.bodySmall);
    }

    return Column(
      children: games.map((g) {
        final fecha = g.startsAt != null
            ? _fmtDate(g.startsAt!)
            : 'Fecha por definir';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.sports_football, size: 20),
          title: Text(g.opponent, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '$fecha · ${g.venue ?? 'Por definir'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => onTapGame(g),
        );
      }).toList(),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
