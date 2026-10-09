import 'package:flutter/material.dart';
import '../engine/levels.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/garage_themes.dart';
import '../theme/garage_widgets.dart';
import 'game_screen.dart';

/// Level-select map: 4 tier sections, 10 levels each, sequential unlocks.
/// Modes: 'levels' (stars), 'par' (par-beaten badges), 'timed' (best times).
class LevelsScreen extends StatelessWidget {
  final GarageAudio audio;
  final GarageSettings settings;
  final String mode; // levels | par | timed
  const LevelsScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.mode,
  });

  String get _title =>
      mode == 'par' ? 'PAR CHALLENGE' : mode == 'timed' ? 'TIMED RUN' : 'LEVELS';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) {
        final t = GarageThemes.byId(settings.themeId,
            custom: settings.customTheme);
        final unlocked = settings.unlockedCount;
        return Scaffold(
          body: GarageBackdrop(
            theme: t,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
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
                        TinSign(text: _title, theme: t, fontSize: 22, hang: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mode == 'par'
                        ? 'Solve within par to earn the cup'
                        : mode == 'timed'
                            ? 'Solve fast — best times are saved'
                            : 'Finish a level to unlock the next',
                    style: GarageText.body(13, t),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: 4,
                      itemBuilder: (_, tier) => _tierSection(
                          context, t, tier, unlocked),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tierSection(
      BuildContext context, GarageThemeDef t, int tier, int unlocked) {
    final start = tier * 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Plaque(
          theme: t,
          child: Text(
            '${tier + 1}. ${LevelPack.tierNames[tier].toUpperCase()}',
            style: GarageText.carved(16, t),
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.92,
          ),
          itemCount: 10,
          itemBuilder: (_, k) {
            final idx = start + k;
            final isOpen = idx < unlocked;
            final lvl = LevelPack.levels[idx];
            return GestureDetector(
              onTap: isOpen
                  ? () {
                      audio.click();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => GameScreen(
                          audio: audio,
                          settings: settings,
                          mode: mode == 'levels' ? 'pack' : mode,
                          levelIndex: idx,
                        ),
                      ));
                    }
                  : null,
              child: Opacity(
                opacity: isOpen ? 1.0 : 0.45,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [t.oak, t.woodMid],
                    ),
                    border: Border.all(color: t.woodDark, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(0, 3),
                          blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${idx + 1}',
                          style: GarageText.carved(19, t)),
                      const SizedBox(height: 2),
                      _badge(t, idx, lvl.par, isOpen),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _badge(GarageThemeDef t, int idx, int par, bool isOpen) {
    if (!isOpen) {
      return Icon(Icons.lock, color: t.signCream.withValues(alpha: 0.7), size: 16);
    }
    if (mode == 'par') {
      final beaten = settings.parBeaten[idx] == 1;
      return Text(beaten ? '🏆' : 'par $par',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: beaten ? const Color(0xFFD9A441) : t.signCream));
    }
    if (mode == 'timed') {
      final bt = settings.bestTimes[idx];
      return Text(
          bt < 0 ? '—' : _fmtTime(bt),
          style: GarageText.body(11, t));
    }
    final s = settings.stars[idx];
    return Text(
      s == 0 ? '· · ·' : '★' * s,
      style: TextStyle(
          fontSize: 11,
          color: s == 0
              ? t.signCream.withValues(alpha: 0.6)
              : const Color(0xFFD9A441)),
    );
  }

  String _fmtTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
