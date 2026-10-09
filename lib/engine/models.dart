import 'dart:convert';

/// Core puzzle model for Unblock Car. Pure data + deterministic rules.
/// The engine (engine.dart) owns all mutation; this file never changes state.
class CarDef {
  int r, c; // top-left cell (mutable: the car's current position)
  final int len;
  final bool horiz;
  final bool red;
  final int paint; // blocker paint index (red ignores this)

  CarDef({
    required this.r,
    required this.c,
    required this.len,
    required this.horiz,
    required this.red,
    this.paint = 0,
  });

  CarDef copy() =>
      CarDef(r: r, c: c, len: len, horiz: horiz, red: red, paint: paint);

  /// Cells occupied by this car.
  Iterable<(int, int)> get cells sync* {
    for (var k = 0; k < len; k++) {
      yield horiz ? (r, c + k) : (r + k, c);
    }
  }

  Map<String, int> toJson() => {'r': r, 'c': c};

  static const int boardSize = 6;
  static const int exitRow = 2; // 0-indexed row of the exit gap (RULES.md)
  static const int winCol = 4; // red car's left end wins at column 4
}

/// One counted move: a single car sliding any distance in one direction.
class SlideMove {
  final int car;
  final int fr, fc, tr, tc;
  const SlideMove(this.car, this.fr, this.fc, this.tr, this.tc);

  Map<String, int> toJson() =>
      {'car': car, 'fr': fr, 'fc': fc, 'tr': tr, 'tc': tc};

  static SlideMove fromJson(Map<String, dynamic> j) => SlideMove(
        (j['car'] as int),
        (j['fr'] as int),
        (j['fc'] as int),
        (j['tr'] as int),
        (j['tc'] as int),
      );
}

enum Phase { idle, dragging, animating, exiting, solved }

enum EngineSfx { slide, bump, win, rev, click, undo, restart, hint, invalid }

/// Parses a 6-string level grid into cars. Red ('R') sorts first for a
/// stable identity across states (hint lookups depend on this).
List<CarDef> parseLevel(List<String> grid, {int Function(int)? paintFor}) {
  final groups = <String, List<(int, int)>>{};
  for (var r = 0; r < 6; r++) {
    for (var c = 0; c < 6; c++) {
      final ch = grid[r][c];
      if (ch == '.') continue;
      groups.putIfAbsent(ch, () => []).add((r, c));
    }
  }
  final cars = <CarDef>[];
  var paintIdx = 0;
  final keys = groups.keys.toList()..sort();
  for (final ch in keys) {
    final cells = groups[ch]!;
    final rs = cells.map((e) => e.$1).toSet();
    final horiz = rs.length == 1;
    final r = cells.map((e) => e.$1).reduce((a, b) => a < b ? a : b);
    final c = cells.map((e) => e.$2).reduce((a, b) => a < b ? a : b);
    final red = ch == 'R';
    cars.add(CarDef(
      r: r,
      c: c,
      len: cells.length,
      horiz: horiz,
      red: red,
      paint: red ? 0 : (paintFor?.call(paintIdx) ?? paintIdx),
    ));
    if (!red) paintIdx++;
  }
  cars.sort((a, b) {
    if (a.red != b.red) return a.red ? -1 : 1;
    if (a.r != b.r) return a.r - b.r;
    return a.c - b.c;
  });
  return cars;
}

/// Canonical hash of the current board state (RULES.md: O(1) hint lookup).
String stateKeyOf(List<CarDef> cars) =>
    cars.map((v) => '${v.r},${v.c}').join(';');

String snapshotToJson(List<CarDef> cars, List<SlideMove> history) =>
    jsonEncode({
      'cars': [for (final v in cars) v.toJson()],
      'history': [for (final m in history) m.toJson()],
    });

void restoreSnapshot(String raw, List<CarDef> cars, List<SlideMove> history) {
  final j = jsonDecode(raw) as Map<String, dynamic>;
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
}
