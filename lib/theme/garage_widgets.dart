import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/garage_themes.dart';

/// 1950s toy-garage widget kit: painted tin signs, wooden toy-box panels,
/// chunky physical toggles, die-cast car painter, concrete board painter.
/// Everything is drawn to feel like real physical objects — bevels, contact
/// shadows, enamel gloss — never flat Material, never neon.

// ------------------------------------------------------------ text styles
class GarageText {
  /// Hand-painted sign-writer headline: cream enamel, red-trim feel.
  static TextStyle display(double size, GarageThemeDef t) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: t.signCream,
        shadows: [
          Shadow(color: t.signRed.withValues(alpha: 0.9), offset: const Offset(1.5, 1.5)),
          Shadow(color: Colors.black.withValues(alpha: 0.45), offset: const Offset(0, 3)),
        ],
      );

  /// Carved-and-painted wood lettering on toy-box panels.
  static TextStyle carved(double size, GarageThemeDef t, {Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: color ?? t.signCream,
        shadows: [
          Shadow(
              color: Colors.black.withValues(alpha: 0.55),
              offset: const Offset(0, 2)),
          Shadow(
              color: Colors.white.withValues(alpha: 0.25),
              offset: const Offset(0, -1)),
        ],
      );

  static TextStyle body(double size, GarageThemeDef t) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: t.signCream.withValues(alpha: 0.92),
      );

  static TextStyle plaqueDigits(double size, GarageThemeDef t) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        color: const Color(0xFF2A1E14),
      );
}

// ------------------------------------------------------------ tin sign
/// Painted tin enamel sign with red trim. [hang] adds little chains.
class TinSign extends StatelessWidget {
  final String text;
  final double fontSize;
  final GarageThemeDef theme;
  final bool hang;
  final EdgeInsets padding;
  const TinSign({
    super.key,
    required this.text,
    required this.theme,
    this.fontSize = 30,
    this.hang = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hang)
          SizedBox(
            height: 26,
            child: CustomPaint(painter: _ChainsPainter(t)),
          ),
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: t.signCream,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: t.signRed, width: 4),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  offset: const Offset(0, 5),
                  blurRadius: 10),
              BoxShadow(
                  color: Colors.white.withValues(alpha: 0.35),
                  offset: const Offset(0, -2),
                  blurRadius: 2),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: t.signRed,
              shadows: [
                Shadow(
                    color: t.ink.withValues(alpha: 0.35),
                    offset: const Offset(1, 1)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChainsPainter extends CustomPainter {
  final GarageThemeDef t;
  _ChainsPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = t.chrome.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final w = size.width;
    // two short chains from the sign top corners
    for (final x in [w * 0.22, w * 0.78]) {
      canvas.drawLine(Offset(x - 8, size.height), Offset(x, 0), p);
      canvas.drawLine(Offset(x + 8, size.height), Offset(x, 0), p);
      canvas.drawCircle(Offset(x, 2), 3, Paint()..color = t.chrome);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ------------------------------------------------------------ wood button
/// Chunky wooden toy-box panel button with carved lettering.
class WoodButton extends StatefulWidget {
  final String label;
  final GarageThemeDef theme;
  final VoidCallback? onTap;
  final double fontSize;
  final Widget? icon;
  final bool small;
  const WoodButton({
    super.key,
    required this.label,
    required this.theme,
    this.onTap,
    this.fontSize = 20,
    this.icon,
    this.small = false,
  });

  @override
  State<WoodButton> createState() => _WoodButtonState();
}

class _WoodButtonState extends State<WoodButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: widget.small ? 14 : 22,
              vertical: widget.small ? 10 : 15),
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
                  color: Colors.black.withValues(alpha: _down ? 0.25 : 0.5),
                  offset: Offset(0, _down ? 2 : 6),
                  blurRadius: _down ? 4 : 10),
              BoxShadow(
                  color: Colors.white.withValues(alpha: 0.28),
                  offset: const Offset(0, -2),
                  blurRadius: 2),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: GarageText.carved(widget.fontSize, t),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round wooden icon button for the thumb rail.
class WoodIconButton extends StatefulWidget {
  final IconData icon;
  final GarageThemeDef theme;
  final VoidCallback? onTap;
  final bool enabled;
  const WoodIconButton({
    super.key,
    required this.icon,
    required this.theme,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<WoodIconButton> createState() => _WoodIconButtonState();
}

class _WoodIconButtonState extends State<WoodIconButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final enabled = widget.enabled && widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: () => setState(() => _down = false),
      onTap: enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _down ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.oak, t.woodMid],
              ),
              border: Border.all(color: t.woodDark, width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 4),
                    blurRadius: 8),
                BoxShadow(
                    color: Colors.white.withValues(alpha: 0.25),
                    offset: const Offset(0, -2),
                    blurRadius: 2),
              ],
            ),
            child: Icon(widget.icon, color: t.signCream, size: 26),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ toggles
/// Chunky wooden knob sliding in a routed groove (never a flat switch).
class WoodKnob extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final GarageThemeDef theme;
  const WoodKnob({
    super.key,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 76,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: t.woodDark,
          border: Border.all(color: Colors.black.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 2),
                blurRadius: 4),
            const BoxShadow(
                color: Colors.white24, offset: Offset(0, -1), blurRadius: 1),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      t.oak,
                      t.woodMid,
                      if (value) t.signRed else t.woodDark
                    ],
                  ),
                  border: Border.all(
                      color: Colors.black.withValues(alpha: 0.45), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(0, 3),
                        blurRadius: 5),
                    BoxShadow(
                        color: Colors.white.withValues(alpha: 0.35),
                        offset: const Offset(-1, -2),
                        blurRadius: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painted tin slide switch (for vibration).
class TinSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final GarageThemeDef theme;
  const TinSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 76,
        height: 40,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: t.signCream,
          border: Border.all(color: t.signRed, width: 3),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                offset: const Offset(0, 3),
                blurRadius: 6),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: Container(
                width: 30,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: value ? t.signRed : t.concrete,
                  border: Border.all(
                      color: Colors.black.withValues(alpha: 0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(0, 2),
                        blurRadius: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ plaque
/// Wooden toy-box plaque for HUD readouts.
class Plaque extends StatelessWidget {
  final Widget child;
  final GarageThemeDef theme;
  final EdgeInsets padding;
  const Plaque({
    super.key,
    required this.child,
    required this.theme,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.oak, t.woodMid],
        ),
        border: Border.all(color: t.woodDark, width: 3),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              offset: const Offset(0, 4),
              blurRadius: 8),
          BoxShadow(
              color: Colors.white.withValues(alpha: 0.22),
              offset: const Offset(0, -2),
              blurRadius: 2),
        ],
      ),
      child: child,
    );
  }
}

// ------------------------------------------------------------ star badges
/// Painted tin star badges: filled gold or empty stamped outline.
class StarBadges extends StatelessWidget {
  final int filled;
  final double size;
  final GarageThemeDef theme;
  const StarBadges({
    super.key,
    required this.filled,
    required this.theme,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CustomPaint(
              size: Size(size, size),
              painter: _StarPainter(
                filled: i < filled,
                theme: theme,
              ),
            ),
          ),
      ],
    );
  }
}

class _StarPainter extends CustomPainter {
  final bool filled;
  final GarageThemeDef theme;
  _StarPainter({required this.filled, required this.theme});

  Path _star(Size s) {
    final path = Path();
    final cx = s.width / 2, cy = s.height / 2;
    final rO = s.width / 2, rI = rO * 0.45;
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? rO : rI;
      final a = -3.14159265 / 2 + i * 3.14159265 / 5;
      final x = cx + r * cos(a), y = cy + r * sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final star = _star(size);
    if (filled) {
      canvas.drawPath(
          star,
          Paint()
            ..color = const Color(0xFFD9A441)
            ..style = PaintingStyle.fill);
      canvas.drawPath(
          star,
          Paint()
            ..color = const Color(0xFF8A5F1A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      // enamel glint
      canvas.drawCircle(
          Offset(size.width * 0.38, size.height * 0.36),
          size.width * 0.09,
          Paint()..color = Colors.white.withValues(alpha: 0.55));
    } else {
      canvas.drawPath(
          star,
          Paint()
            ..color = theme.signCream.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill);
      canvas.drawPath(
          star,
          Paint()
            ..color = theme.signCream.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) =>
      old.filled != filled || old.theme != theme;
}

// ------------------------------------------------------------ die-cast car
/// Chunky die-cast toy car, top-down with physical extrusion:
/// contact shadow, side walls, enamel face, gloss, chrome bumpers,
/// glasshouse, whitewall hint. The hero gets a racing stripe.
class DieCastCar extends StatelessWidget {
  final Color enamel;
  final Color chrome;
  final bool horiz;
  final bool hero;
  final bool selected;
  final bool hintPulse;
  const DieCastCar({
    super.key,
    required this.enamel,
    required this.chrome,
    required this.horiz,
    this.hero = false,
    this.selected = false,
    this.hintPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CarPainter(
        enamel: enamel,
        chrome: chrome,
        horiz: horiz,
        hero: hero,
        selected: selected,
        hintPulse: hintPulse,
      ),
    );
  }
}

class _CarPainter extends CustomPainter {
  final Color enamel;
  final Color chrome;
  final bool horiz;
  final bool hero;
  final bool selected;
  final bool hintPulse;
  _CarPainter({
    required this.enamel,
    required this.chrome,
    required this.horiz,
    required this.hero,
    required this.selected,
    required this.hintPulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final radius = (horiz ? h : w) * 0.32;
    final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h), Radius.circular(radius));

    // Contact shadow (soft, offset down-right — warm garage light upper-left).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(3, 5, w, h), Radius.circular(radius)),
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );

    // Side walls (extrusion): darker enamel shifted down.
    final dark = _shade(enamel, 0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 3, w, h), Radius.circular(radius)),
      Paint()..color = dark,
    );

    // Enamel face.
    canvas.drawRRect(body, Paint()..color = enamel);

    // Pooling-paint gloss: soft diagonal highlight upper-left.
    final gloss = Path()
      ..moveTo(w * 0.08, h * 0.28)
      ..quadraticBezierTo(w * 0.3, h * 0.02, w * 0.62, h * 0.10)
      ..quadraticBezierTo(w * 0.34, h * 0.20, w * 0.10, h * 0.44)
      ..close();
    canvas.drawPath(
        gloss, Paint()..color = Colors.white.withValues(alpha: 0.34));

    // Glasshouse: inset rounded rect (positioned toward the rear half).
    final gw = horiz ? w * 0.30 : w * 0.56;
    final gh = horiz ? h * 0.52 : h * 0.26;
    final gx = horiz ? w * 0.30 : (w - gw) / 2;
    final gy = horiz ? (h - gh) / 2 : h * 0.32;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(gx, gy, gw, gh), Radius.circular(6)),
      Paint()..color = const Color(0xFFDCE6EA).withValues(alpha: 0.92),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(gx, gy, gw, gh), Radius.circular(6)),
      Paint()
        ..color = const Color(0xFF2A1E14).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // glass glint
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(gx + 3, gy + 2, gw * 0.4, gh * 0.35),
          Radius.circular(4)),
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );

    // Hero racing stripe along the axis.
    if (hero) {
      final stripe = horiz
          ? Rect.fromLTWH(w * 0.06, h * 0.44, w * 0.88, h * 0.12)
          : Rect.fromLTWH(w * 0.44, h * 0.06, w * 0.12, h * 0.88);
      canvas.drawRect(
          stripe, Paint()..color = Colors.white.withValues(alpha: 0.9));
    }

    // Chrome bumpers at both ends of the axis.
    final bumperPaint = Paint()..color = chrome;
    final bumperGlint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    if (horiz) {
      for (final x in [2.0, w - 8.0]) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x, h * 0.12, 6, h * 0.76),
                const Radius.circular(3)),
            bumperPaint);
        canvas.drawRect(Rect.fromLTWH(x + 1, h * 0.16, 2, h * 0.68), bumperGlint);
      }
      // headlights at the front (+x)
      for (final y in [h * 0.18, h * 0.82]) {
        canvas.drawCircle(Offset(w - 12, y), 3.2, bumperPaint);
        canvas.drawCircle(
            Offset(w - 12, y), 1.4, Paint()..color = Colors.white);
      }
    } else {
      for (final y in [2.0, h - 8.0]) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * 0.12, y, w * 0.76, 6),
                const Radius.circular(3)),
            bumperPaint);
        canvas.drawRect(Rect.fromLTWH(w * 0.16, y + 1, w * 0.68, 2), bumperGlint);
      }
      for (final x in [w * 0.18, w * 0.82]) {
        canvas.drawCircle(Offset(x, 6), 3.2, bumperPaint);
        canvas.drawCircle(Offset(x, 6), 1.4, Paint()..color = Colors.white);
      }
    }

    // Edge definition.
    canvas.drawRRect(
        body,
        Paint()
          ..color = const Color(0xFF2A1E14).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    if (selected) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(-3, -3, w + 6, h + 6),
              Radius.circular(radius + 4)),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
    if (hintPulse) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(-5, -5, w + 10, h + 10),
              Radius.circular(radius + 6)),
          Paint()
            ..color = const Color(0xFFD9A441)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4);
    }
  }

  Color _shade(Color c, double f) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness * f).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(covariant _CarPainter old) =>
      old.enamel != enamel ||
      old.selected != selected ||
      old.hintPulse != hintPulse ||
      old.horiz != horiz;
}

// ------------------------------------------------------------ board
/// Concrete garage-floor slab in a walnut frame with the red exit gap.
class BoardPainter extends CustomPainter {
  final GarageThemeDef theme;
  final double cell; // pixel size of one cell (inside the frame)
  final double frame; // frame thickness
  BoardPainter({required this.theme, required this.cell, required this.frame});

  @override
  void paint(Canvas canvas, Size size) {
    final t = theme;
    final fw = frame;
    final board = Rect.fromLTWH(fw, fw, cell * 6, cell * 6);

    // Walnut frame with bevel.
    final frameRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(14));
    canvas.drawRRect(
        frameRect, Paint()..color = Colors.black.withValues(alpha: 0.5));
    canvas.drawRRect(frameRect, Paint()..color = t.woodDark);
    // inner bevel highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
          const Radius.circular(10)),
      Paint()
        ..color = t.woodMid.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // corner dowels
    final dowel = Paint()..color = t.oak;
    const dr = 7.0;
    for (final off in [
      Offset(fw / 2, fw / 2),
      Offset(size.width - fw / 2, fw / 2),
      Offset(fw / 2, size.height - fw / 2),
      Offset(size.width - fw / 2, size.height - fw / 2),
    ]) {
      canvas.drawCircle(off, dr, dowel);
      canvas.drawCircle(
          off,
          dr,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawCircle(
          off + const Offset(-2, -2), 2, Paint()..color = Colors.white38);
    }

    // Concrete slab.
    canvas.drawRect(board, Paint()..color = t.concrete);
    // subtle concrete speckle
    final speck = Paint()..color = Colors.black.withValues(alpha: 0.05);
    for (var i = 0; i < 90; i++) {
      final x = board.left + (i * 37 % 100) / 100 * board.width;
      final y = board.top + (i * 53 % 100) / 100 * board.height;
      canvas.drawCircle(Offset(x, y), 1.1, speck);
    }

    // Faded painted parking-bay grid lines.
    final line = Paint()
      ..color = t.bayLine.withValues(alpha: 0.55)
      ..strokeWidth = 2.5;
    for (var i = 1; i < 6; i++) {
      final x = board.left + cell * i;
      canvas.drawLine(Offset(x, board.top + 4), Offset(x, board.bottom - 4), line);
      final y = board.top + cell * i;
      canvas.drawLine(Offset(board.left + 4, y), Offset(board.right - 4, y), line);
    }

    // Ambient occlusion: soft inner edge around the slab.
    canvas.drawRect(
        board,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);

    // EXIT gap: red-painted break in the frame on row 2, right side.
    final exitTop = board.top + cell * 2 + cell * 0.14;
    final exitH = cell * 0.72;
    // paint over the frame with concrete (the "break")
    canvas.drawRect(
        Rect.fromLTWH(size.width - fw - 2, exitTop, fw + 2, exitH),
        Paint()..color = t.concrete);
    // red trim around the gap
    final redPaint = Paint()..color = t.signRed;
    canvas.drawRect(
        Rect.fromLTWH(size.width - fw - 2, exitTop - 4, fw + 2, 5), redPaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width - fw - 2, exitTop + exitH - 1, fw + 2, 5),
        redPaint);
    // stenciled arrow
    final arrowY = exitTop + exitH / 2;
    final arrowPaint = Paint()
      ..color = t.signRed
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final ax = size.width - fw - 16;
    canvas.drawLine(Offset(ax - 14, arrowY), Offset(ax + 10, arrowY), arrowPaint);
    canvas.drawLine(Offset(ax + 10, arrowY),
        Offset(ax + 1, arrowY - 8), arrowPaint);
    canvas.drawLine(Offset(ax + 10, arrowY),
        Offset(ax + 1, arrowY + 8), arrowPaint);
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.theme != theme || old.cell != cell;
}

// ------------------------------------------------------------ backdrop
/// Warm garage backdrop: gradient + faint painted bay lines + vignette.
class GarageBackdrop extends StatelessWidget {
  final GarageThemeDef theme;
  final Widget child;
  const GarageBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.backdropA, t.backdropB],
        ),
      ),
      child: CustomPaint(
        painter: _BackdropPainter(t),
        child: child,
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final GarageThemeDef t;
  _BackdropPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    // faint painted parking bays
    final p = Paint()
      ..color = t.bayLine.withValues(alpha: 0.10)
      ..strokeWidth = 3;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.62 + i * 0.1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    // warm light wash upper-left
    final wash = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.8, size.height * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), wash);
    // vignette
    final vig = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 1.1,
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vig);
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) => old.t != t;
}

// ------------------------------------------------------------ settings row
/// One wooden settings row: label + control.
class SettingsRow extends StatelessWidget {
  final String label;
  final Widget control;
  final GarageThemeDef theme;
  const SettingsRow({
    super.key,
    required this.label,
    required this.control,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: GarageText.carved(16, t)),
          ),
          control,
        ],
      ),
    );
  }
}
