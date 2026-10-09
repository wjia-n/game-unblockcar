import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/garage_themes.dart';
import '../theme/garage_widgets.dart';

/// How-to-play: wooden panels explaining the rules (RULES.md, condensed).
class HowToScreen extends StatelessWidget {
  final GarageAudio audio;
  final GarageSettings settings;
  const HowToScreen(
      {super.key, required this.audio, required this.settings});

  @override
  Widget build(BuildContext context) {
    final t = GarageThemes.byId(settings.themeId,
        custom: settings.customTheme);
    return Scaffold(
      body: GarageBackdrop(
        theme: t,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    WoodIconButton(
                      icon: Icons.arrow_back,
                      theme: t,
                      onTap: () {
                        audio.click();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 12),
                    TinSign(
                        text: 'HOW TO PLAY', theme: t, fontSize: 22, hang: false),
                  ],
                ),
                const SizedBox(height: 16),
                _panel(t, '🚗 THE GOAL',
                    'Slide the little RED car out through the exit gap on the right side of the grid. That\'s it — that\'s the whole job.'),
                _panel(t, '👆 SLIDING',
                    'Drag any car along its own lane: horizontal cars go left/right, vertical cars go up/down. One drag = one move, no matter how far it rolls.'),
                _panel(t, '🧱 THE JAM',
                    'Cars can\'t turn, jump or overlap. Push a car and it stops at the last free spot before the next bumper (magnetic snap!).'),
                _panel(t, '↩️ UNDO & RESTART',
                    'Unlimited undo, one step per tap. Restart any time from the pause menu or the thumb rail.'),
                _panel(t, '💡 HINTS',
                    'Stuck? The lightbulb highlights the next car on a winning line — or suggests an undo if you wandered off. Hints cap the level at 2 stars.'),
                _panel(t, '⭐ STARS & PAR',
                    'Each level has a par. Finish within par for 3 stars, within par + 10 for 2 stars. Replaying can only improve your best!'),
                _panel(t, '🏆 MODES',
                    'PAR RUN: beat the par for the cup. TIMED: race your best time. DAILY: a fresh puzzle every day — keep the streak alive! FREE PLAY: a random jam whenever you like.'),
                const SizedBox(height: 16),
                WoodButton(
                  label: 'GOT IT — LET\'S ROLL',
                  theme: t,
                  onTap: () {
                    audio.click();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel(GarageThemeDef t, String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.woodMid, t.woodDark],
        ),
        border: Border.all(color: Colors.black.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 4),
              blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GarageText.carved(15, t)),
          const SizedBox(height: 6),
          Text(body, style: GarageText.body(14, t)),
        ],
      ),
    );
  }
}
