import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const UnblockCarApp());

class UnblockCarApp extends StatelessWidget {
  const UnblockCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Unblock Car',
      tagline: 'Slide the traffic and free the red car from the jam',
      emoji: '🚗',
      slug: 'unblockcar',
      howToPlay:
          '• Drag cars and trucks along their lane to slide them out of the way.\n• Free the little red car — slide it out the exit on the right. ➡️\n• Beat the par move count to earn 3 stars per level.\n• 20 traffic jams. Zero road rage allowed. 😌',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          UnblockCarScreen(players: players, callbacks: cb),
    );
  }
}
