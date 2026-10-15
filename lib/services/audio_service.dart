import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Procedural 1950s-garage audio for Unblock Car — all clips synthesized in
/// code as WAV bytes. No asset files.
///
/// Reliability (copied from the proven Ludo pattern):
/// - Clips synthesized ONCE and cached; starting music never blocks UI.
/// - A [_musicGen] generation counter serializes track changes; the latest
///   request always wins, overlapping calls can never desync the music.
/// - Lifecycle uses pause()/resume() so interruptions resume in place.
/// - Every public method catches player errors; audio can never crash the app.
class GarageAudio {
  /// Per-game pitch character (unblockcar): 1.06x. Makes SFX unique.
  static const double _pitchMul = 1.060;

  static const int _rate = 22050;
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();
  final _rand = Random();

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;

  final Map<String, Uint8List> _cache = {};
  int _musicGen = 0;
  bool _musicBusy = false;
  String? _currentTrack; // 'menu' | 'game' | null
  bool _pausedByLifecycle = false;
  bool _disposed = false;

  GarageAudio() {
    _music.setReleaseMode(ReleaseMode.loop);
  }

  void configure(
      {required bool musicOn, required bool sfxOn, required double volume}) {
    this.musicOn = musicOn;
    this.sfxOn = sfxOn;
    this.volume = volume.clamp(0.0, 1.0);
    _music.setVolume(musicOn ? this.volume * 0.5 : 0.0);
    _sfx.setVolume(sfxOn ? this.volume : 0.0);
    if (!musicOn) stopMusic();
  }

  /// Pre-build music clips off the critical path. Safe to call any time.
  Future<void> prewarm() async {
    if (_disposed) return;
    await Future(() {});
    _menuBytes();
    _gameBytes();
  }

  // ---------------------------------------------------------- WAV synthesis
  Uint8List _wav(List<double> samples) {
    final n = samples.length;
    final data = ByteData(44 + n * 2);
    void writeStr(int o, String s) {
      for (int i = 0; i < s.length; i++) {
        data.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    writeStr(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, _rate, Endian.little);
    data.setUint32(28, _rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeStr(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    for (int i = 0; i < n; i++) {
      final v = samples[i].clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  double _env(int i, int n, {double attack = 0.02}) {
    final t = i / n;
    final a = (t / attack).clamp(0.0, 1.0);
    final d = pow(1 - t, 2.2).toDouble();
    return a * d;
  }

  List<double> _tone(double freq, double secs,
      {double freqEnd = 0, double attack = 0.02, double harmonics = 0.25}) {
    freq *= _pitchMul;
    freqEnd *= _pitchMul;
    final n = (_rate * secs).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      final f = freqEnd > 0 ? freq + (freqEnd - freq) * (i / n) : freq;
      final ph = 2 * pi * f * t;
      out[i] = _env(i, n, attack: attack) *
          (sin(ph) + harmonics * sin(2 * ph) + harmonics * 0.5 * sin(3 * ph));
    }
    return out;
  }

  /// Wooden rolling clunk: low thump + rolling noise.
  List<double> _slideClunk() {
    final n = (_rate * 0.22).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      out[i] = _env(i, n, attack: 0.008) *
          (0.7 * sin(2 * pi * 140 * t) * exp(-t * 28) +
              0.4 * sin(2 * pi * 280 * t) * exp(-t * 45) +
              0.3 * (_rand.nextDouble() * 2 - 1) * exp(-t * 60));
    }
    return out;
  }

  /// Dull bumper thunk.
  List<double> _thunk() {
    final n = (_rate * 0.12).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      out[i] = _env(i, n, attack: 0.004) *
          (0.9 * sin(2 * pi * 95 * t) * exp(-t * 40) +
              0.35 * (_rand.nextDouble() * 2 - 1) * exp(-t * 110));
    }
    return out;
  }

  /// Engine rev: rising saw-ish sweep with wobble, 0.8s.
  List<double> _rev() {
    final n = (_rate * 0.8).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      final f = 70 + 260 * pow(i / n, 1.6) + 8 * sin(2 * pi * 9 * t);
      final ph = 2 * pi * f * t;
      // saw-ish via harmonic stack, gentle envelope
      final v = sin(ph) + 0.5 * sin(2 * ph) + 0.25 * sin(3 * ph);
      out[i] = _env(i, n, attack: 0.05) * v * 0.5;
    }
    return out;
  }

  /// Ignition crank + catch for game start.
  List<double> _ignition() {
    final n = (_rate * 0.9).round();
    final out = List<double>.filled(n, 0);
    for (int c = 0; c < 3; c++) {
      final start = (n * c / 4).round();
      final len = (_rate * 0.12).round();
      for (int i = 0; i < len && start + i < n; i++) {
        final t = i / _rate;
        out[start + i] += _env(i, len, attack: 0.01) *
            (0.6 * sin(2 * pi * (55 + c * 20) * t) +
                0.3 * (_rand.nextDouble() * 2 - 1)) *
            0.4;
      }
    }
    // catch: quick rev tail
    final tail = _rev();
    final off = (n * 0.55).round();
    for (int i = 0; i < tail.length && off + i < n; i++) {
      out[off + i] += tail[i] * 0.8;
    }
    return out;
  }

  List<double> _arp(List<double> freqs, double noteSecs, double gapSecs,
      {double harmonics = 0.3}) {
    final out = <double>[];
    for (final f in freqs) {
      out.addAll(_tone(f, noteSecs, harmonics: harmonics));
      out.addAll(List<double>.filled((_rate * gapSecs).round(), 0));
    }
    return out;
  }

  List<double> _padChord(List<double> freqs, double secs) {
    final n = (_rate * secs).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      double v = 0;
      for (final f in freqs) {
        final t = i / _rate;
        v += sin(2 * pi * f * t) + 0.3 * sin(2 * pi * f * 2 * t);
      }
      v /= freqs.length * 1.3;
      final t = i / n;
      out[i] = v * (0.35 + 0.65 * sin(pi * t.clamp(0.0, 1.0)));
    }
    return out;
  }

  /// Walking upright-bass-ish line under soft chords (1950s garage menu).
  List<double> _walkingBass(List<double> roots, double secsPerBar) {
    final out = <double>[];
    const pattern = [0, 4, 5, 7]; // root, third-ish walk
    for (final root in roots) {
      for (final step in pattern) {
        final f = root * pow(2, step / 12);
        final n = (_rate * secsPerBar / 4).round();
        for (int i = 0; i < n; i++) {
          final t = i / _rate;
          out.add(_env(i, n, attack: 0.01) *
              (sin(2 * pi * f * t) + 0.4 * sin(4 * pi * f * t)) *
              0.5);
        }
      }
    }
    return out;
  }

  Uint8List _clip(String key, List<double> Function() build) =>
      _cache.putIfAbsent(key, () => _wav(build()));

  Uint8List _menuBytes() => _clip('music_menu', () {
        // G# arpeggiated 5 – 3 – 0 – 4, 16s loop. Unique to unblockcar.
        final notes = [349.22, 415.30, 523.25, 415.30, 277.18, 349.22, 415.30, 349.22, 207.65, 261.62, 311.12, 261.62, 311.12, 391.99, 466.16, 391.99];
        final out = <double>[];
        final noteLen = 16.0 / notes.length;
        for (final n in notes) {
          out.addAll(_tone(n, noteLen * 0.9, harmonics: 0.3));
          final gap = List<double>.filled((_rate * noteLen * 0.1).round(), 0);
          out.addAll(gap);
        }
        // Soft pad underneath
        final pad = _padChord([349.22, 415.30, 523.25], 16.0);
        for (int i = 0; i < out.length && i < pad.length; i++) {
          out[i] += pad[i] * 0.3;
        }
        return out;
      });


  Uint8List _gameBytes() => _clip('music_game', () {
        // G# 5 – 3 – 0 – 4 warm pad, 16s loop. Unique to unblockcar.
        final seq = [
          [349.22, 415.30, 523.25],
          [277.18, 349.22, 415.30],
          [207.65, 261.62, 311.12],
          [311.12, 391.99, 466.16]
        ];
        final out = <double>[];
        for (final chord in seq) {
          out.addAll(_padChord(chord, 4.0));
        }
        return out;
      });


  // ------------------------------------------------------------------ SFX
  Future<void> _play(Uint8List bytes) async {
    if (!sfxOn || _disposed) return;
    try {
      await _sfx.play(BytesSource(bytes));
    } catch (_) {}
  }

  Future<void> click() => _play(_clip('click', () => _tone(900, 0.05)));
  Future<void> knob() => _play(_clip('knob', () => _tone(420, 0.07, freqEnd: 640)));
  Future<void> slide() => _play(_clip('slide', _slideClunk));
  Future<void> bump() => _play(_clip('bump', _thunk));
  Future<void> undo() =>
      _play(_clip('undo', () => _tone(500, 0.12, freqEnd: 260)));
  Future<void> restart() =>
      _play(_clip('restart', () => _tone(300, 0.15, freqEnd: 520)));
  Future<void> hint() =>
      _play(_clip('hint', () => _tone(1320, 0.12, harmonics: 0.4)));
  Future<void> invalid() =>
      _play(_clip('invalid', () => _tone(140, 0.16, harmonics: 0.5)));
  Future<void> gameStart() => _play(_clip('start', _ignition));
  Future<void> rev() => _play(_clip('rev', _rev));
  Future<void> win() => _play(_clip('win',
      () => _arp([392.0, 523.25, 659.25, 783.99, 1046.5], 0.16, 0.03,
          harmonics: 0.45)));
  Future<void> star() =>
      _play(_clip('star', () => _tone(1568, 0.2, harmonics: 0.4)));

  // ----------------------------------------------------------------- music
  Future<void> _startTrack(String track, Uint8List Function() bytes) async {
    if (_disposed) return;
    final gen = ++_musicGen;
    if (_currentTrack == track && !_pausedByLifecycle) {
      try {
        await _music.resume();
      } catch (_) {}
      return;
    }
    while (_musicBusy) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (gen != _musicGen || _disposed || !musicOn) return;
    _musicBusy = true;
    try {
      await _music.stop();
      if (gen != _musicGen || _disposed || !musicOn) return;
      _currentTrack = track;
      _pausedByLifecycle = false;
      await _music.play(BytesSource(bytes()));
    } catch (_) {
      if (gen == _musicGen) _currentTrack = null;
    } finally {
      _musicBusy = false;
    }
  }

  Future<void> startMenuMusic() => _startTrack('menu', _menuBytes);
  Future<void> startGameMusic() => _startTrack('game', _gameBytes);

  /// App-scoped stop: only when the user turns music OFF.
  Future<void> stopMusic() async {
    ++_musicGen;
    while (_musicBusy) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (_disposed) return;
    try {
      await _music.stop();
    } catch (_) {}
    _currentTrack = null;
    _pausedByLifecycle = false;
  }

  Future<void> onAppPaused() async {
    if (_disposed || _currentTrack == null) return;
    try {
      await _music.pause();
      _pausedByLifecycle = true;
    } catch (_) {}
  }

  Future<void> onAppResumed() async {
    if (_disposed || !musicOn || !_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    try {
      await _music.resume();
    } catch (_) {
      final track = _currentTrack;
      _currentTrack = null;
      if (track == 'menu') {
        await startMenuMusic();
      } else if (track == 'game') {
        await startGameMusic();
      }
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    try {
      await _sfx.dispose();
      await _music.dispose();
    } catch (_) {}
  }
}
