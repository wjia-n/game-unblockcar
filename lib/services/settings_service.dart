import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/garage_themes.dart';

/// Persisted settings + progress for Unblock Car.
///
/// Stores: audio toggles, player name, garage theme / paint choices (incl.
/// custom colors), Pro unlock, per-level stars / par-beaten / best times,
/// daily streak, and lifetime stats. All keys are namespaced `ubc_`.
class GarageSettings extends ChangeNotifier {
  static const _p = 'ubc_';
  static const _kMusic = '${_p}music_on';
  static const _kSfx = '${_p}sfx_on';
  static const _kVib = '${_p}vibration_on';
  static const _kVolume = '${_p}volume';
  static const _kName = '${_p}player_name';
  static const _kTheme = '${_p}theme_id';
  static const _kPaint = '${_p}paint_id';
  static const _kStars = '${_p}stars'; // StringList of 40 ints
  static const _kParBeaten = '${_p}par_beaten'; // StringList of 40 0/1
  static const _kBestTimes = '${_p}best_times'; // StringList of 40 secs (-1 none)
  static const _kLastDaily = '${_p}last_daily'; // yyyy-MM-dd
  static const _kStreak = '${_p}daily_streak';
  static const _kDailyDone = '${_p}daily_done_dates'; // StringList
  static const _kWins = '${_p}wins';
  static const _kGames = '${_p}games_played';
  static const _kBestMoves = '${_p}best_moves'; // fewest moves any level (0 none)
  static const _kIsPro = '${_p}is_pro';
  static const _kCustomPrefix = '${_p}custom_';

  bool musicOn = true;
  bool sfxOn = true;
  bool vibrationOn = true;
  double volume = 0.8;
  String playerName = 'Driver';
  String themeId = 'sunset';
  String paintId = 'showroom';
  List<int> stars = List.filled(40, 0);
  List<int> parBeaten = List.filled(40, 0);
  List<int> bestTimes = List.filled(40, -1);
  String lastDailyDate = '';
  int dailyStreak = 0;
  List<String> dailyDoneDates = [];
  int wins = 0;
  int gamesPlayed = 0;
  int bestMoves = 0;
  bool isPro = false;

  /// Custom theme colors (ARGB ints).
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {    'woodDark': 0xFF5B3A26,
    'woodMid': 0xFF7A5233,
    'oak': 0xFFA9764B,
    'signCream': 0xFFF3E9D2,
    'signRed': 0xFFC0392B,
    'concrete': 0xFF9A978E,
    'hero': 0xFFC0392B,
    'blocker0': 0xFFF3E9D2,
    'blocker1': 0xFFD9A441,
    'blocker2': 0xFF3E7C7B,
    'blocker3': 0xFF9AB08A,
  };

  /// Public list of customizable color keys (for the custom creator UI).
  static List<String> get customColorKeys =>
      _defaultCustomColors.keys.toList();

  GarageThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return GarageThemeDef(
      id: 'custom',
      name: 'My Garage',
      woodDark: c('woodDark'),
      woodMid: c('woodMid'),
      oak: c('oak'),
      signCream: c('signCream'),
      signRed: c('signRed'),
      concrete: c('concrete'),
      bayLine: const Color(0xFFEFEDE6),
      chrome: const Color(0xFFC9CDD2),
      ink: const Color(0xFF2A1E14),
      backdropA: c('woodMid'),
      backdropB: c('woodDark'),
    );
  }

  /// Custom paint set built from the custom colors.
  PaintSet get customPaint => PaintSet(
        id: 'custom',
        name: 'My Paint',
        hero: Color(customColors['hero'] ?? 0xFFC0392B),
        blockers: [
          for (var i = 0; i < 12; i++)
            Color(customColors['blocker${i % 4}'] ?? 0xFFD9A441),
        ],
      );

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    vibrationOn = p.getBool(_kVib) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    playerName = p.getString(_kName) ?? 'Driver';
    themeId = p.getString(_kTheme) ?? 'sunset';
    paintId = p.getString(_kPaint) ?? 'showroom';
    stars = _intList(p.getStringList(_kStars), 40);
    parBeaten = _intList(p.getStringList(_kParBeaten), 40);
    bestTimes = _intList(p.getStringList(_kBestTimes), 40, fill: -1);
    lastDailyDate = p.getString(_kLastDaily) ?? '';
    dailyStreak = p.getInt(_kStreak) ?? 0;
    dailyDoneDates = p.getStringList(_kDailyDone) ?? [];
    wins = p.getInt(_kWins) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    bestMoves = p.getInt(_kBestMoves) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  List<int> _intList(List<String>? raw, int n, {int fill = 0}) {
    final out = List<int>.filled(n, fill);
    if (raw != null) {
      for (var i = 0; i < n && i < raw.length; i++) {
        out[i] = int.tryParse(raw[i]) ?? fill;
      }
    }
    return out;
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setBool(_kVib, vibrationOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kName, playerName);
    await p.setString(_kTheme, themeId);
    await p.setString(_kPaint, paintId);
    await p.setStringList(_kStars, [for (final s in stars) '$s']);
    await p.setStringList(_kParBeaten, [for (final s in parBeaten) '$s']);
    await p.setStringList(_kBestTimes, [for (final s in bestTimes) '$s']);
    await p.setString(_kLastDaily, lastDailyDate);
    await p.setInt(_kStreak, dailyStreak);
    await p.setStringList(_kDailyDone, dailyDoneDates);
    await p.setInt(_kWins, wins);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kBestMoves, bestMoves);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (GarageThemes.isProTheme(themeId)) {
      themeId = 'sunset';
      changed = true;
    }
    if (PaintSets.isProPaint(paintId)) {
      paintId = 'showroom';
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  // ---------------------------------------------------------- progress
  int get totalStars => stars.fold(0, (a, b) => a + b);

  /// Highest unlocked level index (0-based). Level N+1 unlocks when N is done.
  int get unlockedCount {
    var n = 1;
    for (final s in stars) {
      if (s > 0) {
        n++;
      } else {
        break;
      }
    }
    return n.clamp(1, 40);
  }

  /// Record a finished level. Returns true if this is a new best star rating.
  Future<bool> recordLevelWin(int level, int moveCount, int starCount,
      {int? elapsedSecs}) async {
    var improved = false;
    if (starCount > stars[level]) {
      stars[level] = starCount;
      improved = true;
    }
    wins++;
    gamesPlayed++;
    if (bestMoves == 0 || moveCount < bestMoves) bestMoves = moveCount;
    if (elapsedSecs != null) {
      final prev = bestTimes[level];
      if (prev < 0 || elapsedSecs < prev) bestTimes[level] = elapsedSecs;
    }
    notifyListeners();
    await _save();
    return improved;
  }

  Future<void> recordParBeaten(int level) async {
    if (parBeaten[level] == 0) {
      parBeaten[level] = 1;
      notifyListeners();
      await _save();
    }
  }

  Future<void> recordDailyDone(String dateKey) async {
    if (!dailyDoneDates.contains(dateKey)) {
      dailyDoneDates.add(dateKey);
      // streak: consecutive calendar days
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      dailyStreak = (lastDailyDate == yKey) ? dailyStreak + 1 : 1;
      lastDailyDate = dateKey;
      notifyListeners();
      await _save();
    }
  }

  bool dailyDone(String dateKey) => dailyDoneDates.contains(dateKey);

  // ---------------------------------------------------------- setters
  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVibration(bool v) async {
    vibrationOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(String v) async {
    final clean = v.trim();
    playerName = clean.isEmpty ? 'Driver' : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && GarageThemes.isProTheme(id)) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setPaint(String id) async {
    if (!isPro && PaintSets.isProPaint(id)) return;
    paintId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> resetProgress() async {
    stars = List.filled(40, 0);
    parBeaten = List.filled(40, 0);
    bestTimes = List.filled(40, -1);
    dailyStreak = 0;
    lastDailyDate = '';
    dailyDoneDates = [];
    wins = 0;
    gamesPlayed = 0;
    bestMoves = 0;
    notifyListeners();
    await _save();
  }
}
