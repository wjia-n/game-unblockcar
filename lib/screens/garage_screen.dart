import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/garage_themes.dart';
import '../theme/garage_widgets.dart';
import 'pro_screen.dart';

/// The Garage: MANY garage colorways + die-cast paint sets + a custom
/// creator. Everything is previewed live on a mini board.
class GarageScreen extends StatefulWidget {
  final GarageAudio audio;
  final GarageSettings settings;
  const GarageScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  String? _editingKey;

  static const _swatches = [
    0xFFC0392B, 0xFFD9A441, 0xFFF3E9D2, 0xFF3E7C7B, 0xFF5B3A26, 0xFFA9764B,
    0xFF9A978E, 0xFF2A1E14, 0xFF922B21, 0xFF9AB08A, 0xFF9AB8D4, 0xFF8E8E96,
    0xFF6E4E1E, 0xFF2E4A52, 0xFF4E6E3E, 0xFF7E5A2E, 0xFFEFEDE6, 0xFF1E1E24,
  ];

  GarageThemeDef get _theme => GarageThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  void _pick(String id, bool isTheme) {
    final locked = isTheme
        ? GarageThemes.isProTheme(id)
        : PaintSets.isProPaint(id);
    if (locked && !widget.settings.isPro) {
      widget.audio.invalid();
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProScreen(
              audio: widget.audio, settings: widget.settings)));
      return;
    }
    widget.audio.knob();
    if (isTheme) {
      widget.settings.setTheme(id);
    } else {
      widget.settings.setPaint(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        final t = _theme;
        final s = widget.settings;
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
                            widget.audio.click();
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(width: 12),
                        TinSign(
                            text: 'THE GARAGE',
                            theme: t,
                            fontSize: 24,
                            hang: false),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _miniPreview(t),
                    const SizedBox(height: 12),
                    _sectionTitle(t, 'GARAGE COLORWAYS'),
                    _swatchGrid(
                      t,
                      GarageThemes.all
                          .map((th) => _Swatch(
                                id: th.id,
                                name: th.name,
                                colors: [
                                  th.woodDark,
                                  th.woodMid,
                                  th.signCream,
                                  th.signRed,
                                  th.concrete,
                                ],
                                selected: s.themeId == th.id,
                                locked: GarageThemes.isProTheme(th.id) &&
                                    !s.isPro,
                              ))
                          .toList(),
                      isTheme: true,
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle(t, 'DIE-CAST PAINT SETS'),
                    _swatchGrid(
                      t,
                      PaintSets.all
                          .map((p) => _Swatch(
                                id: p.id,
                                name: p.name,
                                colors: [
                                  p.hero,
                                  ...p.blockers.take(4),
                                ],
                                selected: s.paintId == p.id,
                                locked:
                                    PaintSets.isProPaint(p.id) && !s.isPro,
                              ))
                          .toList(),
                      isTheme: false,
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle(t, 'CUSTOM GARAGE (PRO)'),
                    _customPanel(t, s),
                    const SizedBox(height: 16),
                    WoodButton(
                      label: 'BACK TO MENU',
                      theme: t,
                      onTap: () {
                        widget.audio.click();
                        Navigator.pop(context);
                      },
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

  Widget _sectionTitle(GarageThemeDef t, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Plaque(
        theme: t,
        child: Text(text, style: GarageText.carved(14, t)),
      ),
    );
  }

  Widget _swatchGrid(
      GarageThemeDef t, List<_Swatch> items, {required bool isTheme}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final it = items[i];
        return GestureDetector(
          onTap: () => _pick(it.id, isTheme),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                  colors: [t.oak, t.woodMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              border: Border.all(
                color: it.selected ? t.signRed : t.woodDark,
                width: it.selected ? 3.5 : 2,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 3),
                    blurRadius: 6),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(it.name,
                                style: GarageText.carved(12, t),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (it.locked)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text('🔒',
                                  style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          for (final c in it.colors)
                            Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.black45, width: 1),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (it.selected)
                  Icon(Icons.check_circle,
                      color: t.signRed, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Live mini preview: tiny board with sample cars in the current theme.
  Widget _miniPreview(GarageThemeDef t) {
    final paints = widget.settings.paintId == 'custom'
        ? widget.settings.customPaint
        : PaintSets.byId(widget.settings.paintId);
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.woodDark, width: 4),
        color: t.concrete,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              offset: const Offset(0, 5),
              blurRadius: 10),
        ],
      ),
      child: Stack(
        children: [
          // mini grid lines
          CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _MiniGridPainter(t)),
          Positioned(
            left: 18,
            top: 34,
            child: SizedBox(
              width: 76,
              height: 34,
              child: DieCastCar(
                  enamel: paints.hero,
                  chrome: t.chrome,
                  horiz: true,
                  hero: true),
            ),
          ),
          Positioned(
            left: 110,
            top: 20,
            child: SizedBox(
              width: 34,
              height: 76,
              child: DieCastCar(
                  enamel: paints.blockers[1],
                  chrome: t.chrome,
                  horiz: false),
            ),
          ),
          Positioned(
            right: 16,
            top: 66,
            child: SizedBox(
              width: 60,
              height: 30,
              child: DieCastCar(
                  enamel: paints.blockers[2],
                  chrome: t.chrome,
                  horiz: true),
            ),
          ),
          // exit arrow
          Positioned(
            right: 4,
            top: 44,
            child: Text('→',
                style: TextStyle(
                    color: t.signRed,
                    fontSize: 26,
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _customPanel(GarageThemeDef t, GarageSettings s) {
    if (!s.isPro) {
      return GestureDetector(
        onTap: () {
          widget.audio.click();
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  ProScreen(audio: widget.audio, settings: s)));
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
                colors: [t.woodMid, t.woodDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            border: Border.all(color: t.woodDark, width: 2),
          ),
          child: Row(
            children: [
              const Text('🔒', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Design your own garage colors with Unblock Car PRO.',
                  style: GarageText.body(14, t),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final keys = GarageSettings.customColorKeys;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
            colors: [t.woodMid, t.woodDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        border: Border.all(color: t.woodDark, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('TAP A PART, THEN A COLOR',
                      style: GarageText.carved(13, t))),
              GestureDetector(
                onTap: () {
                  s.setTheme('custom');
                  s.setPaint('custom');
                  widget.audio.knob();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (s.themeId == 'custom')
                        ? t.signRed
                        : t.woodDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      s.themeId == 'custom' ? 'USING ✓' : 'USE MINE',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in keys)
                GestureDetector(
                  onTap: () {
                    widget.audio.click();
                    setState(() => _editingKey = k);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _editingKey == k
                          ? t.signRed.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _editingKey == k
                              ? t.signRed
                              : Colors.transparent,
                          width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Color(s.customColors[k]!),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.black45, width: 1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(_prettyKey(k),
                            style: GarageText.body(12, t)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_editingKey != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _swatches)
                  GestureDetector(
                    onTap: () {
                      s.setCustomColor(_editingKey!, c);
                      widget.audio.knob();
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: s.customColors[_editingKey] == c
                              ? t.signCream
                              : Colors.black45,
                          width: s.customColors[_editingKey] == c
                              ? 3
                              : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            TextButton(
              onPressed: () {
                s.resetCustomColors();
                widget.audio.click();
              },
              child: Text('RESET COLORS',
                  style:
                      GarageText.carved(12, t).copyWith(color: t.signRed)),
            ),
          ],
        ],
      ),
    );
  }

  String _prettyKey(String k) {
    const names = {
      'woodDark': 'Dark wood',
      'woodMid': 'Wood',
      'oak': 'Oak',
      'signCream': 'Sign cream',
      'signRed': 'Sign red',
      'concrete': 'Concrete',
      'hero': 'Hero car',
      'blocker0': 'Paint A',
      'blocker1': 'Paint B',
      'blocker2': 'Paint C',
      'blocker3': 'Paint D',
    };
    return names[k] ?? k;
  }
}

class _Swatch {
  final String id;
  final String name;
  final List<Color> colors;
  final bool selected;
  final bool locked;
  _Swatch({
    required this.id,
    required this.name,
    required this.colors,
    required this.selected,
    required this.locked,
  });
}

class _MiniGridPainter extends CustomPainter {
  final GarageThemeDef t;
  _MiniGridPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = t.bayLine.withValues(alpha: 0.4)
      ..strokeWidth = 2;
    for (var i = 1; i < 6; i++) {
      final x = size.width / 6 * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var i = 1; i < 3; i++) {
      final y = size.height / 3 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
