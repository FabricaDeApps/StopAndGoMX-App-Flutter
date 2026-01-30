import 'package:flutter/material.dart';
import 'package:stopandgo/core/models/dashboard_models.dart';
import 'package:stopandgo/core/widgets/cards.dart';
import 'package:stopandgo/core/models/games/games.dart';

import 'flat_games_list.dart';
import 'player_games_by_category.dart';

class DashboardGamesCard extends StatelessWidget {
  const DashboardGamesCard({
    super.key,
    required this.role,
    required this.playerCategories,
    required this.upcomingGames,
    required this.onGoGamesTab,
    required this.onTapGame,
  });

  final String role;
  final List<PlayerDashboardCategory> playerCategories;
  final List<Game> upcomingGames;

  final VoidCallback onGoGamesTab;
  final void Function(Game g) onTapGame;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onGoGamesTab,
      child: MiniCard(
        title: 'Próximos juegos',
        child: role == 'player'
            ? PlayerGamesByCategory(
                categories: playerCategories,
                onTapGame: onTapGame,
              )
            : FlatGamesList(
                games: upcomingGames.take(3).toList(),
                onTapGame: onTapGame,
              ),
      ),
    );
  }
}
