import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models.dart';

/// Engine-owned puzzle state machine for Unblock Car (RULES.md).
///
/// The engine — not UI timers — owns phases and settles every slide.
/// A watchdog recovers any phase found without forward progress, so stuck
/// states are impossible by construction.
///
/// Phases: idle -> dragging -> animating -> idle; a winning slide goes
/// idle -> dragging -> animating -> exiting -> solved.
///
/// Move counting (RULES.md section 3): one move = sliding one car any number
/// of cells in one continuous drag. The count always equals history length.
class UnblockEngine extends ChangeNotifier {
  final List<CarDef> cars = [];
  final List<SlideMove> history = [];
  Phase phase = Phase.idle;
  int par = 10;
  bool hintUsed = false;
  String mode = 'pack'; // pack | daily | free | timed | par

  // Optimal solution path for hints (RULES.md section 11): state hash ->
  // step index, plus the flattened [carIdx, dr, dc] moves per step.
  final Map<String, int> _solIndex = {};
  final List<List<int>> _solMoves = [];

  // Hint presentation state (consumed by the UI).
  int? hintCar;
  bool hintSuggestUndo = false;

  // Drag bookkeeping.
  int _dragCar = -1;
  int _dragFromR = 0, _dragFromC = 0;

  // Engine-owned clock (pausable). [_baseMs] accumulates elapsed time across
  // pauses/backgrounding so the timer restores exactly (RULES.md 12).
  final Stopwatch _clock = Stopwatch();
  int _baseMs = 0;
  Duration get elapsed => Duration(milliseconds: _baseMs) + _clock.elapsed;

  // Sound hook the UI wires to the audio service.
  void Function(EngineSfx)? onSfx;

  Timer? _watchdog;
  DateTime _phaseSince = DateTime.now();
  String _lastGoodSnapshot = '';

  UnblockEngine() {
    _watchdog = Timer.periodic(const Duration(milliseconds: 500), (_) => _watch());
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _clock.stop();
    super.dispose();
  }

  // ------------------------------------------------------------ loading
  void loadLevel({
    required List<String> grid,
    required int par,
    List<String>? solStates,
    List<int>? solMovesFlat,
    int Function(int)? paintFor,
  }) {
    this.par = par;
    cars
      ..clear()
      ..addAll(parseLevel(grid, paintFor: paintFor));
    history.clear();
    hintUsed = false;
    hintCar = null;
    hintSuggestUndo = false;
    _dragCar = -1;
    _solIndex.clear();
    _solMoves.clear();
    if (solStates != null && solMovesFlat != null) {
      for (var i = 0; i < solStates.length; i++) {
        _solIndex[solStates[i]] = i;
      }
      for (var i = 0; i + 2 < solMovesFlat.length + 1; i += 3) {
        _solMoves.add([solMovesFlat[i], solMovesFlat[i + 1], solMovesFlat[i + 2]]);
      }
    }
    _clock.reset();
    _baseMs = 0;
    _setPhase(Phase.idle);
    _checkpoint();
  }

  // ------------------------------------------------------------ phases
  void _setPhase(Phase p) {
    phase = p;
    _phaseSince = DateTime.now();
    notifyListeners();
  }

  /// Watchdog: any non-idle phase without forward progress for > 2s is
  /// force-settled. Also re-validates the no-overlap invariant and repairs
  /// from the last good snapshot if it ever breaks.
  void _watch() {
    if (phase == Phase.dragging ||
        phase == Phase.animating ||
        phase == Phase.exiting) {
      if (DateTime.now().difference(_phaseSince) >
          const Duration(seconds: 2)) {
        // Recover: cancel the drag/animation, keep the last settled state.
        _dragCar = -1;
        _setPhase(Phase.idle);
      }
    }
    if (!_invariantOk() && _lastGoodSnapshot.isNotEmpty) {
      restoreSnapshot(_lastGoodSnapshot, cars, history);
      _setPhase(Phase.idle);
    }
  }

  bool _invariantOk() {
    final seen = <int>{};
    for (final v in cars) {
      for (final (r, c) in v.cells) {
        if (r < 0 || r > 5 || c < 0 || c > 5) return false;
        final k = r * 6 + c;
        if (!seen.add(k)) return false; // overlap
      }
    }
    return true;
  }

  void _checkpoint() {
    _lastGoodSnapshot = snapshotToJson(cars, history);
  }

  // ------------------------------------------------------------ queries
  int get moveCount => history.length;
  bool get canUndo => history.isNotEmpty && phase == Phase.idle;
  CarDef? get redCar {
    for (final v in cars) {
      if (v.red) return v;
    }
    return null;
  }

  String stateKey() => stateKeyOf(cars);

  bool _cellBlocked(int r, int c, int ignore) {
    if (r < 0 || r > 5 || c < 0 || c > 5) return true;
    for (var i = 0; i < cars.length; i++) {
      if (i == ignore) continue;
      for (final (rr, cc) in cars[i].cells) {
        if (rr == r && cc == c) return true;
      }
    }
    return false;
  }

  /// Furthest legal cell for [carIdx] along its axis in direction [dir]
  /// (magnetic snap per RULES.md section 7).
  (int, int) slideLimit(int carIdx, int dir) {
    final v = cars[carIdx];
    var r = v.r, c = v.c;
    while (true) {
      final nr = v.horiz ? r : r + dir;
      final nc = v.horiz ? c + dir : c;
      // leading cell after the step
      final lr = v.horiz ? nr : (dir > 0 ? nr + v.len - 1 : nr);
      final lc = v.horiz ? (dir > 0 ? nc + v.len - 1 : nc) : nc;
      if (_cellBlocked(lr, lc, carIdx)) break;
      r = nr;
      c = nc;
    }
    return (r, c);
  }

  /// Clamp a desired cell to the legal range along the car's axis.
  (int, int) clampTarget(int carIdx, int wantR, int wantC) {
    final v = cars[carIdx];
    if (v.horiz) {
      final lo = slideLimit(carIdx, -1).$2;
      final hi = slideLimit(carIdx, 1).$2;
      return (v.r, wantC.clamp(lo, hi));
    }
    final lo = slideLimit(carIdx, -1).$1;
    final hi = slideLimit(carIdx, 1).$1;
    return (wantR.clamp(lo, hi), v.c);
  }

  // ------------------------------------------------------------ drag input
  /// Begin a drag. Returns false when a drag is already active (RULES.md:
  /// multi-touch second drag is ignored) or the phase forbids input.
  bool dragStart(int carIdx) {
    if (phase != Phase.idle || _dragCar != -1) return false;
    _dragCar = carIdx;
    _dragFromR = cars[carIdx].r;
    _dragFromC = cars[carIdx].c;
    _setPhase(Phase.dragging);
    return true;
  }

  /// Live target while dragging (magnetic snap). Reports whether the car is
  /// pressing against a blocker/edge (for the nudge animation + bump sfx).
  ({int r, int c, bool blocked}) dragTo(int carIdx, int wantR, int wantC) {
    if (_dragCar != carIdx || phase != Phase.dragging) {
      final v = cars[carIdx];
      return (r: v.r, c: v.c, blocked: false);
    }
    final v = cars[carIdx];
    final t = clampTarget(carIdx, wantR, wantC);
    final atRest = t.$1 == v.r && t.$2 == v.c;
    final pushing = v.horiz
        ? (wantC < v.c || wantC > v.c)
        : (wantR < v.r || wantR > v.r);
    return (r: t.$1, c: t.$2, blocked: atRest && pushing);
  }

  /// Commit the drag. Returns the committed move, or null when nothing moved.
  /// The UI animates from (fr,fc) to (tr,tc), then MUST call [settleSlide]
  /// (the watchdog settles it anyway if the UI never does).
  SlideMove? dragEnd(int carIdx, int toR, int toC) {
    if (_dragCar != carIdx || phase != Phase.dragging) {
      _dragCar = -1;
      if (phase == Phase.dragging) _setPhase(Phase.idle);
      return null;
    }
    _dragCar = -1;
    final v = cars[carIdx];
    final t = clampTarget(carIdx, toR, toC);
    if (t.$1 == _dragFromR && t.$2 == _dragFromC) {
      _setPhase(Phase.idle); // no move (RULES.md: not counted)
      return null;
    }
    final move = SlideMove(carIdx, _dragFromR, _dragFromC, t.$1, t.$2);
    v.r = t.$1;
    v.c = t.$2;
    history.add(move);
    hintCar = null;
    hintSuggestUndo = false;
    _kickClock();
    _setPhase(Phase.animating);
    _checkpoint();
    onSfx?.call(EngineSfx.slide);
    return move;
  }

  /// Called by the UI when the slide animation finishes (watchdog-backed).
  void settleSlide() {
    if (phase != Phase.animating) return;
    final red = redCar;
    if (red != null && red.c == CarDef.winCol && red.r == CarDef.exitRow) {
      _setPhase(Phase.exiting);
      onSfx?.call(EngineSfx.rev);
    } else {
      _setPhase(Phase.idle);
    }
  }

  /// Called by the UI when the win drive-out animation finishes.
  void finishWin() {
    if (phase == Phase.exiting) {
      _clock.stop();
      _setPhase(Phase.solved);
      onSfx?.call(EngineSfx.win);
    }
  }

  // ------------------------------------------------------------ undo / restart
  bool undo() {
    if (!canUndo) return false;
    final m = history.removeLast();
    final v = cars[m.car];
    v.r = m.fr;
    v.c = m.fc;
    hintCar = null;
    hintSuggestUndo = false;
    _checkpoint();
    onSfx?.call(EngineSfx.undo);
    notifyListeners();
    return true;
  }

  void restart() {
    if (phase == Phase.exiting || phase == Phase.solved) return;
    for (final m in history.reversed) {
      final v = cars[m.car];
      v.r = m.fr;
      v.c = m.fc;
    }
    history.clear();
    hintUsed = false;
    hintCar = null;
    hintSuggestUndo = false;
    _dragCar = -1;
    _clock.reset();
    _baseMs = 0;
    _checkpoint();
    _setPhase(Phase.idle);
    onSfx?.call(EngineSfx.restart);
  }

  // ------------------------------------------------------------ hint (RULES.md 7, 11)
  /// O(1) lookup of the current state in the precomputed optimal path.
  /// On-path: highlights the next car to move. Off-path: suggests undo.
  /// Using a hint caps the star rating at 2 (RULES.md section 7).
  void useHint() {
    if (phase != Phase.idle) return;
    final idx = _solIndex[stateKey()];
    if (idx != null && idx < _solMoves.length) {
      final mv = _solMoves[idx];
      hintCar = mv[0];
      hintSuggestUndo = false;
    } else if (history.isNotEmpty) {
      hintCar = history.last.car;
      hintSuggestUndo = true; // "undo to get back on a solvable line"
    } else {
      hintCar = null;
      hintSuggestUndo = false;
      onSfx?.call(EngineSfx.invalid);
      return;
    }
    hintUsed = true;
    onSfx?.call(EngineSfx.hint);
    notifyListeners();
  }

  // ------------------------------------------------------------ scoring (RULES.md 8)
  int starsFor(int moves) {
    if (moves <= par && !hintUsed) return 3;
    if (moves <= par + 10) return 2;
    return 1;
  }

  // ------------------------------------------------------------ clock / persistence
  void pauseClock() {
    if (_clock.isRunning) {
      _baseMs += _clock.elapsedMilliseconds;
      _clock.stop();
    }
    _clock.reset();
  }

  void resumeClock() {
    if (phase == Phase.solved) return;
    if (!_clock.isRunning) _clock.start();
  }

  /// Starts the clock on the first real move.
  void _kickClock() {
    if (!_clock.isRunning) _clock.start();
  }

  /// Cancel an in-flight drag (RULES.md: pause mid-drag cancels, no move).
  void cancelDrag() {
    if (_dragCar != -1) {
      final v = cars[_dragCar];
      v.r = _dragFromR;
      v.c = _dragFromC;
      _dragCar = -1;
    }
    if (phase == Phase.dragging || phase == Phase.animating) {
      _setPhase(Phase.idle);
    }
    notifyListeners();
  }

  /// Full persistable snapshot (RULES.md section 12: background/restore).
  Map<String, dynamic> toJson() => {
        'cars': [for (final v in cars) v.toJson()],
        'history': [for (final m in history) m.toJson()],
        'par': par,
        'hintUsed': hintUsed,
        'elapsedMs': _clock.elapsedMilliseconds,
        'mode': mode,
      };

  void restoreFromJson(Map<String, dynamic> j) {
    final carList = (j['cars'] as List).cast<Map<String, dynamic>>();
    for (var i = 0; i < cars.length && i < carList.length; i++) {
      cars[i].r = carList[i]['r'] as int;
      cars[i].c = carList[i]['c'] as int;
    }
    history
      ..clear()
      ..addAll((j['history'] as List)
          .cast<Map<String, dynamic>>()
          .map(SlideMove.fromJson));
    par = (j['par'] as int?) ?? par;
    hintUsed = (j['hintUsed'] as bool?) ?? false;
    mode = (j['mode'] as String?) ?? mode;
    _baseMs = (j['elapsedMs'] as int?) ?? 0;
    _clock.reset();
    notifyListeners();
  }
}
