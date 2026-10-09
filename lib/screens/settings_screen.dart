import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/garage_themes.dart';
import '../theme/garage_widgets.dart';

/// Garage settings: wooden-knob toggles for music/SFX, tin slide for
/// vibration, volume groove, driver name, reset progress.
class SettingsScreen extends StatelessWidget {
  final GarageAudio audio;
  final GarageSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  void _applyAudio() {
    audio.configure(
      musicOn: settings.musicOn,
      sfxOn: settings.sfxOn,
      volume: settings.volume,
    );
    if (settings.musicOn) {
      audio.startMenuMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) {
        final t = GarageThemes.byId(settings.themeId,
            custom: settings.customTheme);
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
                            audio.click();
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(width: 12),
                        TinSign(
                            text: 'GARAGE SETTINGS',
                            theme: t,
                            fontSize: 20,
                            hang: false),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsRow(
                      label: 'MUSIC',
                      theme: t,
                      control: WoodKnob(
                        value: settings.musicOn,
                        theme: t,
                        onChanged: (v) {
                          audio.knob();
                          settings.setMusic(v);
                          _applyAudio();
                        },
                      ),
                    ),
                    SettingsRow(
                      label: 'SOUND FX',
                      theme: t,
                      control: WoodKnob(
                        value: settings.sfxOn,
                        theme: t,
                        onChanged: (v) {
                          settings.setSfx(v);
                          _applyAudio();
                          audio.click();
                        },
                      ),
                    ),
                    SettingsRow(
                      label: 'VIBRATION',
                      theme: t,
                      control: TinSwitch(
                        value: settings.vibrationOn,
                        theme: t,
                        onChanged: (v) {
                          audio.knob();
                          settings.setVibration(v);
                        },
                      ),
                    ),
                    SettingsRow(
                      label: 'VOLUME',
                      theme: t,
                      control: _VolumeGroove(
                        value: settings.volume,
                        theme: t,
                        onChanged: (v) {
                          settings.setVolume(v);
                          _applyAudio();
                        },
                      ),
                    ),
                    SettingsRow(
                      label: 'DRIVER NAME',
                      theme: t,
                      control: GestureDetector(
                        onTap: () => _rename(context, t),
                        child: Plaque(
                          theme: t,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(settings.playerName,
                                  style: GarageText.plaqueDigits(15, t)),
                              const SizedBox(width: 6),
                              Icon(Icons.edit,
                                  size: 16, color: t.ink.withValues(alpha: 0.7)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    WoodButton(
                      label: 'RESET PROGRESS',
                      theme: t,
                      fontSize: 16,
                      onTap: () => _confirmReset(context, t),
                    ),
                    const SizedBox(height: 16),
                    WoodButton(
                      label: 'BACK TO MENU',
                      theme: t,
                      onTap: () {
                        audio.click();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Unblock Car · toy garage edition',
                        style: GarageText.body(12, t),
                      ),
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

  void _rename(BuildContext context, GarageThemeDef t) {
    final ctrl = TextEditingController(text: settings.playerName);
    audio.click();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.woodMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: t.woodDark, width: 3),
        ),
        title: Text('DRIVER NAME', style: GarageText.carved(18, t)),
        content: TextField(
          controller: ctrl,
          maxLength: 16,
          style: TextStyle(
              color: t.ink, fontWeight: FontWeight.w700, fontSize: 18),
          decoration: InputDecoration(
            filled: true,
            fillColor: t.signCream,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: GarageText.carved(14, t)),
          ),
          TextButton(
            onPressed: () {
              settings.setPlayerName(ctrl.text);
              Navigator.pop(ctx);
            },
            child: Text('SAVE',
                style:
                    GarageText.carved(14, t).copyWith(color: t.signRed)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, GarageThemeDef t) {
    audio.click();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.woodMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: t.signRed, width: 3),
        ),
        title: Text('RESET EVERYTHING?', style: GarageText.carved(18, t)),
        content: Text(
          'Stars, best times, streaks and stats go back to zero. This cannot be undone.',
          style: GarageText.body(14, t),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('KEEP', style: GarageText.carved(14, t)),
          ),
          TextButton(
            onPressed: () {
              settings.resetProgress();
              audio.restart();
              Navigator.pop(ctx);
            },
            child: Text('RESET',
                style:
                    GarageText.carved(14, t).copyWith(color: t.signRed)),
          ),
        ],
      ),
    );
  }
}

/// Wooden volume slider: groove + sliding knob.
class _VolumeGroove extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final GarageThemeDef theme;
  const _VolumeGroove({
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return SizedBox(
      width: 150,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 10,
          activeTrackColor: t.woodDark,
          inactiveTrackColor: Colors.black.withValues(alpha: 0.45),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
          thumbColor: t.oak,
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        ),
        child: Slider(value: value, onChanged: onChanged),
      ),
    );
  }
}
