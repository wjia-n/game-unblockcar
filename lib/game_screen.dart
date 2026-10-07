import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Unblock Car — slide the traffic, free the little red car. 🚗
class UnblockCarScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const UnblockCarScreen(
      {super.key, required this.players, required this.callbacks});

  @override
  State<UnblockCarScreen> createState() => _UnblockCarScreenState();
}

class _Veh {
  int r, c, len;
  bool horiz, red;
  _Veh(this.r, this.c, this.len, this.horiz, this.red);
}

class _UnblockCarScreenState extends State<UnblockCarScreen> {
  int? _level;
  List<_Veh> _cars = [];
  int _moves = 0;
  bool _over = false;
  bool _exiting = false;
  List<int> _stars = []; // best stars per level
  SharedPreferences? _prefs;
  double _cell = 60;

  // drag bookkeeping
  double _acc = 0;
  int _dragR = 0, _dragC = 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      _prefs = p;
      setState(() {
        _stars = List.generate(
            _ucLevels.length, (i) => p.getInt('unblockcar_stars_$i') ?? 0);
      });
      final cur = p.getInt('unblockcar_current');
      if (cur != null && cur >= 0 && cur < _ucLevels.length) {
        _openLevel(cur, silent: true);
      }
    });
  }

  List<_Veh> _parse(List<String> grid) {
    final groups = <String, List<List<int>>>{};
    for (var r = 0; r < 6; r++) {
      for (var c = 0; c < 6; c++) {
        final ch = grid[r][c];
        if (ch == '.') continue;
        groups.putIfAbsent(ch, () => []).add([r, c]);
      }
    }
    final cars = <_Veh>[];
    for (final e in groups.entries) {
      final cells = e.value..sort((a, b) => a[0] * 6 + a[1] - (b[0] * 6 + b[1]));
      final horiz = cells.every((x) => x[0] == cells.first[0]);
      final r = cells.map((x) => x[0]).reduce((a, b) => a < b ? a : b);
      final c = cells.map((x) => x[1]).reduce((a, b) => a < b ? a : b);
      cars.add(_Veh(r, c, cells.length, horiz, e.key == 'R'));
    }
    cars.sort((a, b) => (b.red ? 1 : 0) - (a.red ? 1 : 0));
    return cars;
  }

  void _openLevel(int i, {bool silent = false}) {
    setState(() {
      _level = i;
      _cars = _parse(_ucLevels[i]);
      _moves = 0;
      _over = false;
      _exiting = false;
    });
    _prefs?.setInt('unblockcar_current', i);
    if (!silent) Sfx.click();
  }

  bool _cellFree(int r, int c, _Veh self) {
    if (r < 0 || r > 5 || c < 0 || c > 5) return false;
    for (final v in _cars) {
      if (identical(v, self)) continue;
      for (var k = 0; k < v.len; k++) {
        final rr = v.horiz ? v.r : v.r + k;
        final cc = v.horiz ? v.c + k : v.c;
        if (rr == r && cc == c) return false;
      }
    }
    return true;
  }

  bool _tryMove(_Veh v, int dir) {
    // check the leading cell
    int nr, nc;
    if (v.horiz) {
      nr = v.r;
      nc = dir > 0 ? v.c + v.len : v.c - 1;
    } else {
      nr = dir > 0 ? v.r + v.len : v.r - 1;
      nc = v.c;
    }
    if (!_cellFree(nr, nc, v)) return false;
    if (v.horiz) {
      v.c += dir;
    } else {
      v.r += dir;
    }
    return true;
  }

  void _onPanStart(_Veh v, DragStartDetails _) {
    _acc = 0;
    _dragR = v.r;
    _dragC = v.c;
  }

  void _onPanUpdate(_Veh v, DragUpdateDetails d) {
    if (_over) return;
    _acc += v.horiz ? d.delta.dx : d.delta.dy;
    var step = (_acc / _cell).truncate();
    var moved = 0;
    while (step != 0) {
      final dir = step > 0 ? 1 : -1;
      if (!_tryMove(v, dir)) {
        _acc = 0;
        break;
      }
      moved += dir;
      step -= dir;
      _acc -= dir * _cell;
    }
    if (moved != 0) setState(() {});
  }

  void _onPanEnd(_Veh v, DragEndDetails _) {
    if (_over) return;
    if (v.r != _dragR || v.c != _dragC) {
      setState(() => _moves++);
      Sfx.move();
      _checkWin();
    }
  }

  void _checkWin() {
    final red = _cars.firstWhere((v) => v.red);
    if (red.c == 4 && !_over) {
      setState(() {
        _over = true;
        _exiting = true;
      });
    }
  }

  void _exitDone() {
    if (!mounted) return;
    Sfx.win();
    final par = _ucPars[_level!];
    final s = _moves <= par ? 3 : (_moves <= par + 10 ? 2 : 1);
    if (_stars.length != _ucLevels.length) {
      _stars = List.filled(_ucLevels.length, 0);
    }
    if (s > _stars[_level!]) {
      _stars[_level!] = s;
      _prefs?.setInt('unblockcar_stars_${_level!}', s);
    }
    _prefs?.setInt('unblockcar_current',
        _level! + 1 < _ucLevels.length ? _level! + 1 : _level!);
    final msg = s == 3
        ? 'Flawless traffic wizard! 🧙‍♀️'
        : s == 2
            ? 'Smooth driving! Just a few extra wiggles.'
            : 'Freed! Can you beat par $par next time? 👀';
    widget.callbacks.finish(
      headline: 'Unjammed in $_moves moves! 🚗💨',
      subline: '${'⭐' * s} $msg',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    if (_level == null) return _selectScreen(t);
    return _gameScreen(t);
  }

  Widget _selectScreen(GameTheme t) {
    final total = _stars.fold(0, (a, b) => a + b);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick a traffic jam 🚗',
              style: TextStyle(
                  color: t.text, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('$total/${_ucLevels.length * 3} stars collected',
              style: TextStyle(color: t.muted, fontSize: 14)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10),
              itemCount: _ucLevels.length,
              itemBuilder: (_, i) {
                final s = i < _stars.length ? _stars[i] : 0;
                return GestureDetector(
                  onTap: () => _openLevel(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: s > 0
                          ? t.primary.withValues(alpha: 0.22)
                          : t.surface,
                      borderRadius: t.radius,
                      border: Border.all(
                          color: t.primary.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${i + 1}',
                            style: TextStyle(
                                color: t.text,
                                fontWeight: FontWeight.w900,
                                fontSize: 18)),
                        Text(s == 0 ? '· · ·' : '⭐' * s,
                            style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameScreen(GameTheme t) {
    final par = _ucPars[_level!];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _iconBtn(t, '◀️', () => setState(() => _level = null)),
              const SizedBox(width: 8),
              Text('Level ${_level! + 1}',
                  style: TextStyle(
                      color: t.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: t.surface, borderRadius: t.radius),
                child: Text('$_moves / $par par',
                    style: TextStyle(
                        color: t.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              const SizedBox(width: 8),
              _iconBtn(t, '🔄', () => _openLevel(_level!)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Drag the traffic. Free the red car! ➡️',
              style: TextStyle(color: t.muted, fontSize: 13)),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, c) {
                    _cell = c.maxWidth / 6;
                    return _board(t);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _iconBtn(GameTheme t, String emoji, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: t.surface,
            borderRadius: t.radius,
            border: Border.all(color: t.primary.withValues(alpha: 0.3))),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _board(GameTheme t) {
    final red = _cars.firstWhere((v) => v.red);
    final pal = _carPalette(t);
    return Container(
      decoration: BoxDecoration(
        color: t.surface.withValues(alpha: 0.5),
        borderRadius: t.radius,
        border: Border.all(color: t.primary.withValues(alpha: 0.3), width: 2),
      ),
      child: Stack(
        children: [
          // grid lines
          for (var i = 1; i < 6; i++) ...[
            Positioned(
                left: _cell * i - 1,
                top: 8,
                bottom: 8,
                child: Container(
                    width: 2,
                    color: t.primary.withValues(alpha: 0.08))),
            Positioned(
                top: _cell * i - 1,
                left: 8,
                right: 8,
                child: Container(
                    height: 2,
                    color: t.primary.withValues(alpha: 0.08))),
          ],
          // exit gate
          Positioned(
            right: -2,
            top: red.r * _cell + _cell * 0.12,
            child: Container(
              width: 14,
              height: _cell * 0.76,
              decoration: BoxDecoration(
                color: t.accent,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    bottomLeft: Radius.circular(7)),
              ),
              alignment: Alignment.center,
              child: const Text('➡', style: TextStyle(fontSize: 10)),
            ),
          ),
          // vehicles
          for (var vi = 0; vi < _cars.length; vi++)
            _vehicleWidget(_cars[vi], vi, t, pal),
          // red car exit animation
          if (_exiting)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeIn,
              onEnd: _exitDone,
              builder: (_, v, _) {
                final r = _cars.firstWhere((e) => e.red);
                return Positioned(
                  left: (r.c + 3.2 * v) * _cell + 3,
                  top: r.r * _cell + 3,
                  child: _carBody(r, t, const Color(0xFFE5484D), _cell, true),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Color> _carPalette(GameTheme t) {
    final base = HSLColor.fromColor(t.secondary);
    return List.generate(12, (i) {
      final h = (base.hue + i * 47 + 360) % 360;
      return HSLColor.fromAHSL(1, h, 0.6, t.dark ? 0.55 : 0.5).toColor();
    });
  }

  Widget _vehicleWidget(_Veh v, int vi, GameTheme t, List<Color> pal) {
    if (v.red && _exiting) return const SizedBox.shrink();
    final color = v.red ? const Color(0xFFE5484D) : pal[vi % pal.length];
    final w = (v.horiz ? v.len : 1) * _cell - 6;
    final h = (v.horiz ? 1 : v.len) * _cell - 6;
    return Positioned(
      left: v.c * _cell + 3,
      top: v.r * _cell + 3,
      child: GestureDetector(
        onPanStart: (d) => _onPanStart(v, d),
        onPanUpdate: (d) => _onPanUpdate(v, d),
        onPanEnd: (d) => _onPanEnd(v, d),
        child: _carBody(v, t, color, _cell, false, w: w, h: h),
      ),
    );
  }

  Widget _carBody(_Veh v, GameTheme t, Color color, double cell,
      bool ghost, {double? w, double? h}) {
    final ww = w ?? (v.horiz ? v.len : 1) * cell - 6;
    final hh = h ?? (v.horiz ? 1 : v.len) * cell - 6;
    return Opacity(
      opacity: ghost ? 0.95 : 1,
      child: Container(
        width: ww,
        height: hh,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.black.withValues(alpha: 0.18), width: 2),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Center(
          child: Container(
            width: v.horiz ? ww * 0.45 : ww * 0.55,
            height: v.horiz ? hh * 0.5 : hh * (v.len == 3 ? 0.32 : 0.42),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
// ===== UNBLOCK CAR LEVELS =====
const _ucLevels = [
  ['.GE.FF','.GE...','A..BBB','ADDD..','.RRC..','...CHH'], // optimal 5, par 10
  ['AMGLL.','AMGH.J','KK.H.J','.RRCD.','FF.CD.','EEBBD.'], // optimal 6, par 11
  ['G.LLBB','GCC..H','G.KEEH','RRKF.J','...F.J','AA..DD'], // optimal 6, par 11
  ['K.BB..','K...AA','KRRLDG','.HHLDG','CJJJDF','C.EEEF'], // optimal 7, par 12
  ['...D..','RR.D..','BJJEEF','BHHHGF','BCC.G.','KKAA..'], // optimal 7, par 12
  ['RRJ.D.','..JADH','BBBADH','.GCA.F','EGC..F','E.C...'], // optimal 10, par 15
  ['..D...','RRD..G','EEE..G','.BA..C','.BAFFC','.B..HH'], // optimal 11, par 16
  ['.....H','EEE..H','.B.AAA','.B.FG.','RRCFG.','..CDDD'], // optimal 11, par 16
  ['...AA.','JJG.BL','RRGEBL','CC.EB.','..KDFF','HHKD..'], // optimal 11, par 16
  ['.MCCC.','HM.JBB','HRRJ.A','KLEE.A','KLFFG.','.DD.G.'], // optimal 13, par 18
  ['.MCCC.','HM.JBB','HRRJ..','KLEE.A','KLFFGA','.DD.G.'], // optimal 14, par 19
  ['.M.CCC','.MDJBB','RRDJ..','.LEEGA','.LFFGA','KKHH..'], // optimal 16, par 21
  ['.EEE.H','.B...H','DBCAAA','D.C.G.','DFRRG.','.F....'], // optimal 17, par 22
  ['..DDDH','..C..H','..CAAA','EEE.FB','.RR.FB','..GG..'], // optimal 19, par 24
  ['..D...','RRD..G','.EEEFG','.BBBFC','..AHHC','..A...'], // optimal 20, par 25
  ['.GEEEL','.GBB.L','RRD..A','..DFFA','H.JKCC','H.JK..'], // optimal 22, par 27
  ['.EEE.L','.AAKBL','RRDKB.','.GDFF.','HGJCC.','H.J...'], // optimal 26, par 31
  ['.EEE.L','.AAKBL','RRDKB.','HGDFF.','HGJCC.','..J...'], // optimal 27, par 32
  ['G.EEEL','GBBJ.L','RRDJ.A','..DFFA','...KCC','HH.K..'], // optimal 32, par 37
  ['GEEEH.','GAAJH.','RR.JL.','..FFL.','..DKCC','BBDK..'], // optimal 37, par 42
];
const _ucPars = [10,11,11,12,12,15,16,16,16,18,19,21,22,24,25,27,31,32,37,42];
