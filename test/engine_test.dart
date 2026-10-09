import 'package:flutter_test/flutter_test.dart';
import 'package:unblockcar/engine/engine.dart';
import 'package:unblockcar/engine/levels.dart';
import 'package:unblockcar/engine/models.dart';
import 'package:unblockcar/engine/solutions.dart';

void main() {
  test('all 40 levels: red on row 2, len 2, horizontal, not starting solved',
      () {
    for (var i = 0; i < 40; i++) {
      final cars = parseLevel(LevelPack.levels[i].grid);
      final reds = cars.where((c) => c.red).toList();
      expect(reds.length, 1, reason: 'level $i red count');
      final red = reds.first;
      expect(red.r, CarDef.exitRow, reason: 'level $i red row');
      expect(red.len, 2, reason: 'level $i red len');
      expect(red.horiz, isTrue, reason: 'level $i red horiz');
      expect(red.c, isNot(4), reason: 'level $i starts solved');
      expect(red.c, inInclusiveRange(0, 3), reason: 'level $i red col');
    }
  });

  test('no overlaps in any level', () {
    for (var i = 0; i < 40; i++) {
      final cars = parseLevel(LevelPack.levels[i].grid);
      final seen = <int>{};
      for (final v in cars) {
        for (final (r, c) in v.cells) {
          expect(seen.add(r * 6 + c), isTrue,
              reason: 'level $i overlap at $r,$c');
        }
      }
    }
  });

  test('par follows RULES.md formula max(10, ceil(optimal/5)*5)', () {
    for (var i = 0; i < 40; i++) {
      final def = LevelPack.levels[i];
      final expected = def.optimal <= 10 ? 10 : ((def.optimal + 4) ~/ 5) * 5;
      expect(def.par, expected.clamp(10, 1 << 30),
          reason: 'level $i par ${def.par} vs optimal ${def.optimal}');
    }
  });

  test('solution paths are consistent (each step legal, ends at win)', () {
    for (var i = 0; i < 40; i++) {
      final cars = parseLevel(LevelPack.levels[i].grid);
      final states = SolutionData.packStates[i]!;
      final moves = SolutionData.packMoves[i]!;
      expect(states.first, stateKeyOf(cars), reason: 'level $i path start');
      expect(moves.length % 3, 0);
      expect(moves.length ~/ 3, states.length - 1,
          reason: 'level $i moves/steps');
      // replay the path
      for (var s = 0; s < moves.length ~/ 3; s++) {
        final ci = moves[s * 3], dr = moves[s * 3 + 1], dc = moves[s * 3 + 2];
        cars[ci].r += dr;
        cars[ci].c += dc;
        expect(stateKeyOf(cars), states[s + 1],
            reason: 'level $i step $s');
      }
      final red = cars.firstWhere((c) => c.red);
      expect(red.c, 4, reason: 'level $i path ends at win');
    }
  });

  test('engine: one drag any distance counts exactly one move', () {
    final e = UnblockEngine();
    // trivial level: red at (2,0), clear path
    e.loadLevel(
      grid: const [
        '......',
        '......',
        'RR....',
        '......',
        '......',
        '......',
      ],
      par: 10,
    );
    expect(e.dragStart(0), isTrue);
    // second drag while first active is ignored (multi-touch rule)
    expect(e.dragStart(0), isFalse);
    final move = e.dragEnd(0, 2, 4);
    expect(move, isNotNull);
    expect(e.moveCount, 1);
    expect(e.phase, Phase.animating);
    e.settleSlide();
    expect(e.phase, Phase.exiting);
    e.finishWin();
    expect(e.phase, Phase.solved);
    expect(e.starsFor(1), 3);
    e.dispose();
  });

  test('engine: undo restores state and decrements count', () {
    final e = UnblockEngine();
    e.loadLevel(
      grid: LevelPack.levels[0].grid,
      par: LevelPack.levels[0].par,
    );
    final before = e.stateKey();
    // find any car with a legal move
    var movedCar = -1;
    var target = (0, 0);
    for (var i = 0; i < e.cars.length && movedCar < 0; i++) {
      final v = e.cars[i];
      for (final dir in [-1, 1]) {
        final t = e.slideLimit(i, dir);
        if (t.$1 != v.r || t.$2 != v.c) {
          movedCar = i;
          target = t;
          break;
        }
      }
    }
    expect(movedCar, isNot(-1), reason: 'level 0 has a legal move');
    expect(e.dragStart(movedCar), isTrue);
    final move = e.dragEnd(movedCar, target.$1, target.$2);
    expect(move, isNotNull);
    expect(e.moveCount, 1);
    e.settleSlide(); // animation completes -> back to idle
    expect(e.undo(), isTrue);
    expect(e.moveCount, 0);
    expect(e.stateKey(), before);
    expect(e.canUndo, isFalse);
    e.dispose();
  });

  test('engine: star boundaries per RULES.md', () {
    final e = UnblockEngine();
    e.loadLevel(grid: LevelPack.levels[0].grid, par: 10);
    expect(e.starsFor(10), 3);
    expect(e.starsFor(20), 2);
    expect(e.starsFor(21), 1);
    e.hintUsed = true;
    expect(e.starsFor(10), 2); // hint caps at 2
    expect(e.starsFor(21), 1);
    e.dispose();
  });

  test('engine: restart clears history', () {
    final e = UnblockEngine();
    e.loadLevel(grid: LevelPack.levels[0].grid, par: 10);
    final before = e.stateKey();
    var movedCar = -1;
    var target = (0, 0);
    for (var i = 0; i < e.cars.length && movedCar < 0; i++) {
      final v = e.cars[i];
      for (final dir in [-1, 1]) {
        final t = e.slideLimit(i, dir);
        if (t.$1 != v.r || t.$2 != v.c) {
          movedCar = i;
          target = t;
          break;
        }
      }
    }
    e.dragStart(movedCar);
    e.dragEnd(movedCar, target.$1, target.$2);
    expect(e.moveCount, 1);
    e.restart();
    expect(e.moveCount, 0);
    expect(e.stateKey(), before);
    expect(e.canUndo, isFalse);
    e.dispose();
  });

  test('engine: hint finds on-path car from start', () {
    final e = UnblockEngine();
    e.loadLevel(
      grid: LevelPack.levels[0].grid,
      par: LevelPack.levels[0].par,
      solStates: SolutionData.packStates[0],
      solMovesFlat: SolutionData.packMoves[0],
    );
    e.useHint();
    expect(e.hintCar, isNotNull);
    expect(e.hintSuggestUndo, isFalse);
    expect(e.hintUsed, isTrue);
    expect(e.moveCount, 0); // hint counts no move
    e.dispose();
  });

  test('daily pool has 30 entries with pars', () {
    expect(SolutionData.dailyGrids.length, 30);
    expect(SolutionData.dailyPars.length, 30);
    for (var i = 0; i < 30; i++) {
      final cars = parseLevel(SolutionData.dailyGrids[i]);
      expect(cars.where((c) => c.red).length, 1);
      expect(cars.firstWhere((c) => c.red).r, 2);
    }
  });
}
