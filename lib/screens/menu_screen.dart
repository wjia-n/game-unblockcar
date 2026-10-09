import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/garage_themes.dart';
import '../theme/garage_widgets.dart';
import 'game_screen.dart';
import 'levels_screen.dart';
import 'settings_screen.dart';
import 'howto_screen.dart';
import 'garage_screen.dart';
import 'pro_screen.dart';

/// Main menu: painted tin sign, wooden toy-box buttons, mode grid.
class MenuScreen extends StatefulWidget {
  final GarageAudio audio;
  final GarageSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  StoreService? _store;

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    // Pro unlocks coming back from the store (fire-and-forget is fine).
    _store = StoreService();
    _store!.init().then((_) {
      if (!mounted) return;
      _store!.proPurchased.addListener(_applyPro);
      _applyPro();
    });
  }

  void _applyPro() {
    if (_store!.proPurchased.value && !widget.settings.isPro) {
      widget.settings.setPro(true);
    }
  }

  @override
  void dispose() {
    _store?.proPurchased.removeListener(_applyPro);
    _store?.dispose();
    super.dispose();
  }

  void _go(Widget screen) {
    widget.audio.click();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _rename() {
    final ctrl = TextEditingController(text: widget.settings.playerName);
    widget.audio.click();
    showDialog(
      context: context,
      builder: (ctx) {
        final t = _theme;
        return AlertDialog(
          backgroundColor: t.woodMid,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: t.woodDark, width: 3),
          ),
          title: Text('DRIVER NAME', style: GarageText.carved(18, t)),
          content: TextField(
            controller: ctrl,
            maxLength: 16,
            style: TextStyle(
                color: t.ink, fontWeight: FontWeight.w700, fontSize: 18),
            decoration: InputDecoration(
              filled: true,
              fillColor: t.signCream,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCEL', style: GarageText.carved(14, t)),
            ),
            TextButton(
              onPressed: () {
                widget.settings.setPlayerName(ctrl.text);
                Navigator.pop(ctx);
              },
              child: Text('SAVE',
                  style: GarageText.carved(14, t)
                      .copyWith(color: t.signRed)),
            ),
          ],
        );
      },
    );
  }

  GarageThemeDef get _theme => GarageThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        final t = _theme;
        return Scaffold(
          body: GarageBackdrop(
            theme: t,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  children: [
                    TinSign(text: 'UNBLOCK CAR', theme: t, fontSize: 32),
                    const SizedBox(height: 10),
                    // Driver plaque: renameable profile + star tally.
                    GestureDetector(
                      onTap: _rename,
                      child: Plaque(
                        theme: t,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, color: t.signCream, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Howdy, ${widget.settings.playerName}!',
                                style: GarageText.carved(16, t),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('★',
                                style: TextStyle(
                                    color: Color(0xFFD9A441), fontSize: 18)),
                            Text(
                              ' ${widget.settings.totalStars}/120',
                              style: GarageText.carved(16, t),
                            ),
                            if (widget.settings.isPro) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: t.signRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('PRO',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ModeButton(
                      label: 'PLAY',
                      sub: 'Continue the jam',
                      icon: Icons.play_arrow,
                      theme: t,
                      onTap: () => _go(GameScreen.continueGame(
                          audio: widget.audio, settings: widget.settings)),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.15,
                      children: [
                        _ModeButton(
                          label: 'LEVELS',
                          sub: '4 packs of 10',
                          icon: Icons.map,
                          theme: t,
                          onTap: () => _go(LevelsScreen(
                              audio: widget.audio,
                              settings: widget.settings,
                              mode: 'levels')),
                        ),
                        _ModeButton(
                          label: 'PAR RUN',
                          sub: 'Beat the par',
                          icon: Icons.emoji_events,
                          theme: t,
                          onTap: () => _go(LevelsScreen(
                              audio: widget.audio,
                              settings: widget.settings,
                              mode: 'par')),
                        ),
                        _ModeButton(
                          label: 'TIMED',
                          sub: 'Race the clock',
                          icon: Icons.timer,
                          theme: t,
                          onTap: () => _go(LevelsScreen(
                              audio: widget.audio,
                              settings: widget.settings,
                              mode: 'timed')),
                        ),
                        _ModeButton(
                          label: 'DAILY',
                          sub:
                              'Streak ${widget.settings.dailyStreak} 🔥',
                          icon: Icons.calendar_today,
                          theme: t,
                          onTap: () => _go(GameScreen.daily(
                              audio: widget.audio,
                              settings: widget.settings)),
                        ),
                        _ModeButton(
                          label: 'FREE PLAY',
                          sub: 'Random jam',
                          icon: Icons.shuffle,
                          theme: t,
                          onTap: () => _go(GameScreen.freePlay(
                              audio: widget.audio,
                              settings: widget.settings)),
                        ),
                        _ModeButton(
                          label: 'GARAGE',
                          sub: 'Paint & themes',
                          icon: Icons.palette,
                          theme: t,
                          onTap: () => _go(GarageScreen(
                              audio: widget.audio,
                              settings: widget.settings)),
                        ),
                        _ModeButton(
                          label: 'HOW TO',
                          sub: 'Learn the ropes',
                          icon: Icons.help_outline,
                          theme: t,
                          onTap: () => _go(HowToScreen(
                              audio: widget.audio,
                              settings: widget.settings)),
                        ),
                        _ModeButton(
                          label: 'PRO',
                          sub: widget.settings.isPro
                              ? 'You are PRO!'
                              : 'Unlock the works',
                          icon: Icons.workspace_premium,
                          theme: t,
                          onTap: () => _go(ProScreen(
                              audio: widget.audio,
                              settings: widget.settings)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: WoodButton(
                        label: 'SETTINGS',
                        theme: t,
                        fontSize: 18,
                        icon: Icon(Icons.settings,
                            color: t.signCream, size: 22),
                        onTap: () => _go(SettingsScreen(
                            audio: widget.audio,
                            settings: widget.settings)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Decorative red die-cast car by the exit arrow bay.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 56,
                          child: DieCastCar(
                            enamel: PaintSets.byId(widget.settings.paintId)
                                .hero,
                            chrome: t.chrome,
                            horiz: true,
                            hero: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('EXIT →',
                            style: GarageText.display(20, t)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final String sub;
  final IconData icon;
  final GarageThemeDef theme;
  final VoidCallback onTap;
  const _ModeButton({
    required this.label,
    required this.sub,
    required this.icon,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.oak, t.woodMid],
          ),
          border: Border.all(color: t.woodDark, width: 3),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                offset: const Offset(0, 4),
                blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: t.signCream, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GarageText.carved(15, t),
                      overflow: TextOverflow.ellipsis),
                  Text(sub,
                      style: GarageText.body(11, t),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
