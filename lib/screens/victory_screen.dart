import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/garage_themes.dart';
import '../theme/garage_widgets.dart';

/// Victory: red car out on the checkered strip, "YOU DID IT!" tin sign,
/// tally plaque (moves / par / time), tin star badges, wood buttons.
class VictoryScreen extends StatefulWidget {
  final GarageAudio audio;
  final GarageSettings settings;
  final String title;
  final int moves;
  final int par;
  final int elapsedSecs;
  final int stars;
  final bool hintUsed;
  final String? nextLabel;
  final void Function(BuildContext)? onNext;
  final void Function(BuildContext) onReplay;

  const VictoryScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.title,
    required this.moves,
    required this.par,
    required this.elapsedSecs,
    required this.stars,
    required this.hintUsed,
    this.nextLabel,
    this.onNext,
    required this.onReplay,
  });

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
  }

  String get _headline {
    if (widget.stars == 3) return 'Flawless traffic wizard!';
    if (widget.stars == 2) return 'Smooth driving, driver!';
    return 'Freed! Can you beat par ${widget.par}?';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        final t = GarageThemes.byId(widget.settings.themeId,
            custom: widget.settings.customTheme);
        final paints = widget.settings.paintId == 'custom'
            ? widget.settings.customPaint
            : PaintSets.byId(widget.settings.paintId);
        return Scaffold(
          body: GarageBackdrop(
            theme: t,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    TinSign(text: 'YOU DID IT!', theme: t, fontSize: 30),
                    const SizedBox(height: 6),
                    Text(widget.title, style: GarageText.carved(16, t)),
                    const SizedBox(height: 12),
                    // Red car racing out onto the checkered strip.
                    SizedBox(
                      height: 110,
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 18,
                            left: 0,
                            right: 0,
                            child: CustomPaint(
                              size: const Size(double.infinity, 26),
                              painter: _CheckeredPainter(t),
                            ),
                          ),
                          Positioned(
                            left: 40,
                            top: 8,
                            child: SizedBox(
                              width: 170,
                              height: 72,
                              child: DieCastCar(
                                enamel: paints.hero,
                                chrome: t.chrome,
                                horiz: true,
                                hero: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tally plaque.
                    Plaque(
                      theme: t,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _tally(t, 'MOVES', '${widget.moves}'),
                          _tally(t, 'PAR', '${widget.par}'),
                          _tally(
                              t,
                              'TIME',
                              '${widget.elapsedSecs ~/ 60}:${(widget.elapsedSecs % 60).toString().padLeft(2, '0')}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AnimatedStars(stars: widget.stars, theme: t),
                    const SizedBox(height: 8),
                    Text(_headline,
                        style: GarageText.body(15, t),
                        textAlign: TextAlign.center),
                    if (widget.hintUsed)
                      Text('(hint used — stars capped at 2)',
                          style: GarageText.body(12, t)),
                    const SizedBox(height: 18),
                    if (widget.nextLabel != null && widget.onNext != null)
                      SizedBox(
                        width: double.infinity,
                        child: WoodButton(
                          label: widget.nextLabel!,
                          theme: t,
                          onTap: () {
                            widget.audio.click();
                            widget.onNext!(context);
                          },
                        ),
                      ),
                    if (widget.nextLabel != null)
                      const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: WoodButton(
                            label: 'REPLAY',
                            theme: t,
                            fontSize: 17,
                            onTap: () {
                              widget.audio.click();
                              widget.onReplay(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: WoodButton(
                            label: 'MENU',
                            theme: t,
                            fontSize: 17,
                            onTap: () {
                              widget.audio.click();
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
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

  Widget _tally(GarageThemeDef t, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GarageText.carved(11, t)),
        Text(value, style: GarageText.plaqueDigits(22, t)),
      ],
    );
  }
}

/// Star row with per-star elastic pop-in.
class _AnimatedStars extends StatelessWidget {
  final int stars;
  final GarageThemeDef theme;
  const _AnimatedStars({required this.stars, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          _PopStar(
              filled: i < stars,
              theme: theme,
              delayMs: 200 + i * 320),
      ],
    );
  }
}

class _PopStar extends StatefulWidget {
  final bool filled;
  final GarageThemeDef theme;
  final int delayMs;
  const _PopStar(
      {required this.filled, required this.theme, required this.delayMs});

  @override
  State<_PopStar> createState() => _PopStarState();
}

class _PopStarState extends State<_PopStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
        child: StarBadges(
          filled: widget.filled ? 1 : 0,
          theme: widget.theme,
          size: 52,
        ),
      ),
    );
  }
}

class _CheckeredPainter extends CustomPainter {
  final GarageThemeDef t;
  _CheckeredPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    const n = 16;
    final w = size.width / n;
    for (var i = 0; i < n; i++) {
      canvas.drawRect(
          Rect.fromLTWH(i * w, 0, w, size.height / 2),
          Paint()
            ..color = i.isEven ? t.ink : t.signCream);
      canvas.drawRect(
          Rect.fromLTWH(i * w, size.height / 2, w, size.height / 2),
          Paint()
            ..color = i.isEven ? t.signCream : t.ink);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
