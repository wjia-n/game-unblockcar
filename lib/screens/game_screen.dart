import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/engine.dart';
import '../engine/levels.dart';
import '../engine/models.dart';
import '../engine/solutions.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/garage_themes.dart';
import '../theme/garage_widgets.dart';
import 'victory_screen.dart';
import 'howto_screen.dart';

/// Board screen: concrete garage-floor grid in a walnut frame, die-cast cars,
/// wooden thumb rail (undo / restart / hint / pause), plaque HUD.
///
/// Drag model: the finger drags a car; the engine clamps to the legal range
/// (magnetic snap). On release the committed slide animates with weight, a
/// bump nudges + thunks when pressing against a blocker, and the red car
/// drives out through the exit gap on a win.
class GameScreen extends StatefulWidget {
  final GarageAudio audio;
  final GarageSettings settings;
  final String mode; // pack | daily | free | timed | par
  final int levelIndex; // pack/par/timed level, or daily/free pool index

  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.mode,
    required this.levelIndex,
  });

  /// Continue: restore an in-progress snapshot, else the first uncompleted
  /// unlocked level.
  static Widget continueGame({
    required GarageAudio audio,
    required GarageSettings settings,
  }) =>
      _ContinueGame(audio: audio, settings: settings);

  factory GameScreen.daily({
    required GarageAudio audio,
    required GarageSettings settings,
  }) {
    final now = DateTime.now();
    final idx = (now.year * 372 + now.month * 31 + now.day) %
        SolutionData.dailyGrids.length;
    return GameScreen(
        audio: audio, settings: settings, mode: 'daily', levelIndex: idx);
  }

  factory GameScreen.freePlay({
    required GarageAudio audio,
    required GarageSettings settings,
  }) =>
      GameScreen(
        audio: audio,
        settings: settings,
        mode: 'free',
        levelIndex: Random().nextInt(SolutionData.dailyGrids.length),
      );

  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// Helper widget so "continue" can be async (snapshot lookup).
class _ContinueGame extends StatefulWidget {
  final GarageAudio audio;
  final GarageSettings settings;
  const _ContinueGame({required this.audio, required this.settings});

  @override
  State<_ContinueGame> createState() => _ContinueGameState();
}

class _ContinueGameState extends State<_ContinueGame> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('ubc_snapshot');
    String mode = 'pack';
    var idx = 0;
    var useSnapshot = false;
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        mode = j['kind'] as String? ?? 'pack';
        idx = (j['idx'] as int?) ?? 0;
        useSnapshot = true;
      } catch (_) {}
    }
    if (!useSnapshot) {
      final s = widget.settings;
      idx = 0;
      for (var i = 0; i < s.unlockedCount; i++) {
        if (s.stars[i] == 0) {
          idx = i;
          break;
        }
        idx = i;
      }
      idx = idx.clamp(0, s.unlockedCount - 1).toInt();
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: widget.audio,
          settings: widget.settings,
          mode: mode,
          levelIndex: idx,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final UnblockEngine _engine;
  late final AnimationController _slideCtrl;
  late final AnimationController _exitCtrl;
  late final AnimationController _nudgeCtrl;
  late final AnimationController _hintCtrl;
  Timer? _clockTick;
  Timer? _hintClear;
  DateTime _lastBump = DateTime.fromMillisecondsSinceEpoch(0);

  // visual state
  int _dragCar = -1;
  double _dragAcc = 0;
  int _dragFromR = 0, _dragFromC = 0;
  (int, int)? _dragPos;
  int _animCar = -1;
  Animation<Offset>? _slideAnim; // in cell units
  int _nudgeCar = -1;
  int _nudgeDir = 1; // +1/-1 along axis
  bool _navigated = false;
  bool _pausedOverlay = false;

  String get _snapshotKey => 'ubc_snapshot';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = UnblockEngine();
    _engine.onSfx = _onEngineSfx;
    _engine.addListener(_onEngine);
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 230));
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _nudgeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _hintCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _animCar = -1;
        _engine.settleSlide();
      }
    });
    _exitCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _engine.finishWin();
    });
    _loadLevel();
    _clockTick =
        Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  void _loadLevel() {
    int paintFor(int i) => i; // paint index cycles in the car widget
    late List<String> grid;
    late int par;
    List<String>? solStates;
    List<int>? solMoves;
    switch (widget.mode) {
      case 'daily':
      case 'free':
        grid = SolutionData.dailyGrids[widget.levelIndex];
        par = SolutionData.dailyPars[widget.levelIndex];
        solStates = SolutionData.dailyStates[widget.levelIndex];
        solMoves = SolutionData.dailyMoves[widget.levelIndex];
      default:
        final def = LevelPack.levels[widget.levelIndex];
        grid = def.grid;
        par = def.par;
        solStates = SolutionData.packStates[widget.levelIndex];
        solMoves = SolutionData.packMoves[widget.levelIndex];
    }
    _engine.mode = widget.mode;
    _engine.loadLevel(
      grid: grid,
      par: par,
      solStates: solStates,
      solMovesFlat: solMoves,
      paintFor: paintFor,
    );
    widget.audio.startGameMusic();
    widget.audio.gameStart();
    _restoreSnapshotIfAny();
  }

  Future<void> _restoreSnapshotIfAny() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_snapshotKey);
    if (raw == null || !mounted) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['kind'] != widget.mode || j['idx'] != widget.levelIndex) return;
      _engine.restoreFromJson(
          (j['engine'] as Map).cast<String, dynamic>());
      _engine.resumeClock();
      setState(() {});
    } catch (_) {}
  }

  Future<void> _persist() async {
    if (_engine.phase == Phase.solved || !mounted) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _snapshotKey,
        jsonEncode({
          'kind': widget.mode,
          'idx': widget.levelIndex,
          'engine': _engine.toJson(),
        }));
  }

  Future<void> _clearSnapshot() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_snapshotKey);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _engine.pauseClock();
      _persist();
    } else if (state == AppLifecycleState.resumed) {
      _engine.resumeClock();
    }
  }

  void _onEngineSfx(EngineSfx sfx) {
    final a = widget.audio;
    switch (sfx) {
      case EngineSfx.slide:
        a.slide();
        _buzz(HapticFeedback.lightImpact);
      case EngineSfx.bump:
        a.bump();
        _buzz(HapticFeedback.mediumImpact);
      case EngineSfx.win:
        a.win();
      case EngineSfx.rev:
        a.rev();
        _buzz(HapticFeedback.heavyImpact);
      case EngineSfx.click:
        a.click();
      case EngineSfx.undo:
        a.undo();
      case EngineSfx.restart:
        a.restart();
      case EngineSfx.hint:
        a.hint();
      case EngineSfx.invalid:
        a.invalid();
    }
  }

  void _buzz(Future<void> Function() f) {
    if (widget.settings.vibrationOn) {
      try {
        f();
      } catch (_) {}
    }
  }

  void _onEngine() {
    if (_engine.phase == Phase.exiting && !_exitCtrl.isAnimating) {
      _exitCtrl.forward(from: 0);
    }
    if (_engine.phase == Phase.solved && !_navigated) {
      _navigated = true;
      _goVictory();
    }
    if (mounted) setState(() {});
  }

  void _goVictory() {
    _clearSnapshot();
    final moves = _engine.moveCount;
    final stars = _engine.starsFor(moves);
    final secs = _engine.elapsed.inSeconds;
    final s = widget.settings;
    String label;
    switch (widget.mode) {
      case 'daily':
        label = 'DAILY PUZZLE';
      case 'free':
        label = 'FREE PLAY';
      case 'timed':
        label = 'TIMED · LEVEL ${widget.levelIndex + 1}';
      case 'par':
        label = 'PAR RUN · LEVEL ${widget.levelIndex + 1}';
      default:
        label = 'LEVEL ${widget.levelIndex + 1}';
    }
    // record stats (fire and forget)
    if (widget.mode == 'pack' ||
        widget.mode == 'timed' ||
        widget.mode == 'par') {
      s.recordLevelWin(widget.levelIndex, moves, stars,
          elapsedSecs: widget.mode == 'timed' ? secs : null);
      if (widget.mode == 'par' && moves <= _engine.par) {
        s.recordParBeaten(widget.levelIndex);
      }
    }
    if (widget.mode == 'daily') {
      final now = DateTime.now();
      s.recordDailyDone(
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');
    }
    widget.audio.star();

    String? nextLabel;
    void Function(BuildContext)? onNext;
    if (widget.mode == 'pack' || widget.mode == 'timed' || widget.mode == 'par') {
      if (widget.levelIndex + 1 < 40) {
        nextLabel = 'NEXT LEVEL';
        onNext = (ctx) => Navigator.of(ctx).pushReplacement(
              MaterialPageRoute(
                builder: (_) => GameScreen(
                  audio: widget.audio,
                  settings: widget.settings,
                  mode: widget.mode,
                  levelIndex: widget.levelIndex + 1,
                ),
              ),
            );
      }
    } else if (widget.mode == 'free') {
      nextLabel = 'NEW PUZZLE';
      onNext = (ctx) => Navigator.of(ctx).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GameScreen.freePlay(
                  audio: widget.audio, settings: widget.settings),
            ),
          );
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VictoryScreen(
          audio: widget.audio,
          settings: widget.settings,
          title: label,
          moves: moves,
          par: _engine.par,
          elapsedSecs: secs,
          stars: stars,
          hintUsed: _engine.hintUsed,
          nextLabel: nextLabel,
          onNext: onNext,
          onReplay: (ctx) => Navigator.of(ctx).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GameScreen(
                audio: widget.audio,
                settings: widget.settings,
                mode: widget.mode,
                levelIndex: widget.levelIndex,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTick?.cancel();
    _hintClear?.cancel();
    _engine.removeListener(_onEngine);
    _engine.dispose();
    _slideCtrl.dispose();
    _exitCtrl.dispose();
    _nudgeCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ drag input
  void _onPanStart(int i, DragStartDetails d) {
    if (_engine.dragStart(i)) {
      _dragCar = i;
      _dragAcc = 0;
      _dragFromR = _engine.cars[i].r;
      _dragFromC = _engine.cars[i].c;
      _dragPos = (_dragFromR, _dragFromC);
      _hintClear?.cancel();
      _engine.hintCar = null;
      setState(() {});
    }
  }

  void _onPanUpdate(int i, DragUpdateDetails d, double cell) {
    if (_dragCar != i || _engine.phase != Phase.dragging) return;
    final v = _engine.cars[i];
    _dragAcc += v.horiz ? d.delta.dx : d.delta.dy;
    final steps = (_dragAcc / cell).truncate();
    final wantR = v.horiz ? _dragFromR : _dragFromR + steps;
    final wantC = v.horiz ? _dragFromC + steps : _dragFromC;
    final res = _engine.dragTo(i, wantR, wantC);
    _dragPos = (res.r, res.c);
    if (res.blocked) {
      final now = DateTime.now();
      if (now.difference(_lastBump) > const Duration(milliseconds: 450)) {
        _lastBump = now;
        _nudgeCar = i;
        _nudgeDir = (v.horiz ? (wantC - v.c) : (wantR - v.r)) >= 0 ? 1 : -1;
        _nudgeCtrl.forward(from: 0);
        _onEngineSfx(EngineSfx.bump);
      }
    }
    setState(() {});
  }

  void _onPanEnd(int i, double cell) {
    if (_dragCar != i) return;
    _dragCar = -1;
    final target = _dragPos ?? (_dragFromR, _dragFromC);
    _dragPos = null;
    final move = _engine.dragEnd(i, target.$1, target.$2);
    if (move != null) {
      // weighted slide animation with a soft settle
      _animCar = move.car;
      _slideAnim = Tween<Offset>(
        begin: Offset(move.fc.toDouble(), move.fr.toDouble()),
        end: Offset(move.tc.toDouble(), move.tr.toDouble()),
      ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
      _slideCtrl.forward(from: 0);
    }
    setState(() {});
  }

  // ------------------------------------------------------------ HUD actions
  void _doUndo() {
    if (_engine.undo()) setState(() {});
  }

  void _doRestart() {
    _engine.restart();
    setState(() {});
  }

  void _doHint() {
    _engine.useHint();
    if (_engine.hintCar != null) {
      _hintCtrl.repeat(reverse: true);
      _hintClear?.cancel();
      _hintClear = Timer(const Duration(seconds: 4), () {
        _hintCtrl.stop();
        _engine.hintCar = null;
        if (mounted) setState(() {});
      });
    }
    setState(() {});
  }

  void _showPause() {
    if (_pausedOverlay) return;
    _pausedOverlay = true;
    _engine.cancelDrag();
    _engine.pauseClock();
    _persist();
    final t = _theme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                colors: [t.woodMid, t.woodDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            border: Border.all(color: Colors.black54, width: 3),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 24,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TinSign(text: 'PAUSED', theme: t, fontSize: 26, hang: false),
              const SizedBox(height: 16),
              WoodButton(
                  label: 'RESUME',
                  theme: t,
                  onTap: () {
                    widget.audio.click();
                    Navigator.pop(ctx);
                  }),
              const SizedBox(height: 10),
              WoodButton(
                  label: 'RESTART',
                  theme: t,
                  onTap: () {
                    Navigator.pop(ctx);
                    _doRestart();
                  }),
              const SizedBox(height: 10),
              WoodButton(
                  label: 'HOW TO PLAY',
                  theme: t,
                  fontSize: 16,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => HowToScreen(
                            audio: widget.audio,
                            settings: widget.settings)));
                  }),
              const SizedBox(height: 10),
              WoodButton(
                  label: 'QUIT TO MENU',
                  theme: t,
                  fontSize: 16,
                  onTap: () {
                    widget.audio.click();
                    Navigator.pop(ctx);
                    Navigator.of(context).pop();
                  }),
            ],
          ),
        ),
      ),
    ).then((_) {
      _pausedOverlay = false;
      _engine.resumeClock();
    });
  }

  GarageThemeDef get _theme => GarageThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  PaintSet get _paints {
    final id = widget.settings.paintId;
    if (id == 'custom') return widget.settings.customPaint;
    return PaintSets.byId(id);
  }

  String _fmtTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

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
              child: Column(
                children: [
                  _hud(t),
                  const SizedBox(height: 8),
                  Expanded(child: _boardArea(t)),
                  const SizedBox(height: 10),
                  _thumbRail(t),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _hud(GarageThemeDef t) {
    String levelLabel;
    switch (widget.mode) {
      case 'daily':
        levelLabel = 'DAILY';
      case 'free':
        levelLabel = 'FREE PLAY';
      default:
        levelLabel = 'LEVEL ${widget.levelIndex + 1}';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          WoodIconButton(
            icon: Icons.arrow_back,
            theme: t,
            onTap: () {
              widget.audio.click();
              _persist();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Plaque(
              theme: t,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _hudCell(t, levelLabel, null),
                  _hudCell(t, 'MOVES', '${_engine.moveCount}'),
                  _hudCell(t, 'PAR', '${_engine.par}'),
                  _hudCell(t, 'TIME', _fmtTime(_engine.elapsed)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudCell(GarageThemeDef t, String label, String? value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: GarageText.carved(10, t)
                .copyWith(color: t.signCream.withValues(alpha: 0.8))),
        if (value != null)
          Text(value, style: GarageText.plaqueDigits(16, t)),
      ],
    );
  }

  Widget _thumbRail(GarageThemeDef t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        WoodIconButton(
          icon: Icons.undo,
          theme: t,
          enabled: _engine.canUndo,
          onTap: _doUndo,
        ),
        WoodIconButton(
          icon: Icons.refresh,
          theme: t,
          onTap: _doRestart,
        ),
        WoodIconButton(
          icon: Icons.lightbulb_outline,
          theme: t,
          onTap: _doHint,
        ),
        WoodIconButton(
          icon: Icons.pause,
          theme: t,
          onTap: _showPause,
        ),
      ],
    );
  }

  Widget _boardArea(GarageThemeDef t) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);
        const frame = 14.0;
        final cell = (side - frame * 2 - 16) / 6;
        return Center(
          child: SizedBox(
            width: cell * 6 + frame * 2,
            height: cell * 6 + frame * 2,
            child: CustomPaint(
              painter: BoardPainter(theme: t, cell: cell, frame: frame),
              child: Padding(
                padding: const EdgeInsets.all(frame),
                child: Stack(
                  clipBehavior: Clip.none, // red car drives out past the edge
                  children: [
                    for (var i = 0; i < _engine.cars.length; i++)
                      _carWidget(i, cell, t),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _carWidget(int i, double cell, GarageThemeDef t) {
    final v = _engine.cars[i];
    // visual position in cell units
    late double cr, cc;
    if (i == _animCar && _slideAnim != null) {
      cc = _slideAnim!.value.dx;
      cr = _slideAnim!.value.dy;
    } else if (i == _dragCar && _dragPos != null) {
      cr = _dragPos!.$1.toDouble();
      cc = _dragPos!.$2.toDouble();
    } else {
      cr = v.r.toDouble();
      cc = v.c.toDouble();
    }

    // win drive-out: red car keeps sliding right past the exit
    double extraX = 0;
    if (v.red && _exitCtrl.isAnimating) {
      extraX = Curves.easeIn.transform(_exitCtrl.value) * cell * 3.2;
    }

    // nudge shake when pressing against a blocker
    double nudgeX = 0, nudgeY = 0;
    if (i == _nudgeCar && _nudgeCtrl.isAnimating) {
      final k = _nudgeCtrl.value;
      final amp = sin(k * pi * 3) * 5 * (1 - k);
      if (v.horiz) {
        nudgeX = amp * _nudgeDir;
      } else {
        nudgeY = amp * _nudgeDir;
      }
      if (k >= 1) _nudgeCar = -1;
    }

    final w = (v.horiz ? v.len : 1) * cell - 7;
    final h = (v.horiz ? 1 : v.len) * cell - 7;
    final enamel = v.red ? _paints.hero : _paints.blockers[v.paint % 12];
    final hinting = _engine.hintCar == i;

    Widget car = SizedBox(
      width: w,
      height: h,
      child: hinting
          ? AnimatedBuilder(
              animation: _hintCtrl,
              builder: (_, _) => Transform.scale(
                scale: 1.0 + 0.07 * _hintCtrl.value,
                child: DieCastCar(
                  enamel: enamel,
                  chrome: t.chrome,
                  horiz: v.horiz,
                  hero: v.red,
                  selected: i == _dragCar,
                  hintPulse: true,
                ),
              ),
            )
          : DieCastCar(
              enamel: enamel,
              chrome: t.chrome,
              horiz: v.horiz,
              hero: v.red,
              selected: i == _dragCar,
            ),
    );

    // dust puffs behind the exiting red car
    final dust = (v.red && _exitCtrl.isAnimating)
        ? AnimatedBuilder(
            animation: _exitCtrl,
            builder: (_, _) => CustomPaint(
              size: Size(w, h),
              painter: _DustPainter(_exitCtrl.value, t),
            ),
          )
        : const SizedBox.shrink();

    return Positioned(
      left: cc * cell + 3.5 + extraX + nudgeX,
      top: cr * cell + 3.5 + nudgeY,
      child: GestureDetector(
        onPanStart: (d) => _onPanStart(i, d),
        onPanUpdate: (d) => _onPanUpdate(i, d, cell),
        onPanEnd: (_) => _onPanEnd(i, cell),
        onPanCancel: () => _onPanEnd(i, cell),
        behavior: HitTestBehavior.opaque,
        child: Stack(children: [car, dust]),
      ),
    );
  }
}

class _DustPainter extends CustomPainter {
  final double t;
  final GarageThemeDef theme;
  _DustPainter(this.t, this.theme);
  @override
  void paint(Canvas canvas, Size size) {
    for (var k = 0; k < 4; k++) {
      final p = ((t * 1.4 - k * 0.18).clamp(0.0, 1.0));
      if (p <= 0) continue;
      canvas.drawCircle(
        Offset(-10 - p * 46 - k * 8, size.height * (0.3 + 0.15 * k)),
        4 + p * 9,
        Paint()
            ..color = theme.bayLine.withValues(alpha: 0.5 * (1 - p)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter old) => old.t != t;
}
