import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/garage_themes.dart';
import '../theme/garage_widgets.dart';

/// Free-vs-Pro comparison + tip jar. Honest store states: until Wajiha
/// creates the products in Play Console, the buttons show
/// "Available after store setup" — never a fake buy button.
class ProScreen extends StatefulWidget {
  final GarageAudio audio;
  final GarageSettings settings;
  const ProScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  final StoreService _store = StoreService();

  @override
  void initState() {
    super.initState();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.proPurchased.addListener(_applyPro);
    _store.lastThanks.addListener(_thanks);
  }

  void _applyPro() {
    if (_store.proPurchased.value) {
      widget.settings.setPro(true);
      widget.audio.win();
    }
  }

  void _thanks() {
    final msg = _store.lastThanks.value;
    if (msg != null && mounted) {
      widget.audio.star();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFF5B3A26),
        ),
      );
      _store.lastThanks.value = null;
    }
  }

  @override
  void dispose() {
    _store.proPurchased.removeListener(_applyPro);
    _store.lastThanks.removeListener(_thanks);
    _store.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        final t = GarageThemes.byId(widget.settings.themeId,
            custom: widget.settings.customTheme);
        final ready = _store.storeReady;
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
                            text: 'GO PRO',
                            theme: t,
                            fontSize: 24,
                            hang: false),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Plaque(
                        theme: t,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🏆 ',
                                style: GarageText.carved(16, t)),
                            Text('YOU ARE PRO — enjoy the full garage!',
                                style: GarageText.carved(14, t)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    _sectionTitle(t, 'TIP JAR ☕'),
                    Text(
                      'Unblock Car is made by one indie maker. Tips keep the garage lights on!',
                      style: GarageText.body(13, t),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _tipButton(
                                t,
                                _store.coffeeProduct,
                                '☕',
                                'COFFEE',
                                ready)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _tipButton(
                                t,
                                _store.chocolateProduct,
                                '🍫',
                                'CHOCOLATE',
                                ready)),
                      ],
                    ),
                    if (_store.purchaseError.value != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_store.purchaseError.value!,
                            style: GarageText.body(12, t)
                                .copyWith(color: t.signRed),
                            textAlign: TextAlign.center),
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'One-time unlock. No subscriptions, no ads, no nonsense.',
                        style: GarageText.body(12, t),
                        textAlign: TextAlign.center,
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

  Widget _sectionTitle(GarageThemeDef t, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Plaque(
        theme: t,
        child: Text(text, style: GarageText.carved(14, t)),
      ),
    );
  }

  Widget _tipButton(GarageThemeDef t, ProductDetails? product,
      String emoji, String label, bool ready) {
    final enabled = ready && product != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: () {
          if (product == null || !ready) {
            widget.audio.invalid();
            return;
          }
          widget.audio.click();
          _store.buyTip(product);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
                colors: [t.oak, t.woodMid],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            border: Border.all(color: t.woodDark, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 3),
                  blurRadius: 6),
            ],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(label, style: GarageText.carved(13, t)),
              Text(
                  product != null ? product.price : '—',
                  style: GarageText.body(12, t)),
            ],
          ),
        ),
      ),
    );
  }
}
