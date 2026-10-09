import 'package:flutter/material.dart';

/// 1950s toy-garage theme + die-cast paint catalogs for Unblock Car.
///
/// Every theme lives in the warm garage range (cream / enamel / walnut /
/// concrete) — variety comes from different woods, tin-sign enamels,
/// concrete tints and paint palettes. No neon, ever.
class GarageThemeDef {
  final String id;
  final String name;
  final Color woodDark; // walnut frame deep
  final Color woodMid; // toy-box panels
  final Color oak; // button faces, plaques
  final Color signCream; // tin sign face
  final Color signRed; // tin trim / exit arrow
  final Color concrete; // board slab
  final Color bayLine; // painted grid lines
  final Color chrome; // bumpers, glints
  final Color ink; // carved lettering
  final Color backdropA; // backdrop gradient top
  final Color backdropB; // backdrop gradient bottom

  const GarageThemeDef({
    required this.id,
    required this.name,
    required this.woodDark,
    required this.woodMid,
    required this.oak,
    required this.signCream,
    required this.signRed,
    required this.concrete,
    required this.bayLine,
    required this.chrome,
    required this.ink,
    required this.backdropA,
    required this.backdropB,
  });
}

class GarageThemes {
  /// First 4 are FREE. The rest (and custom) are PRO.
  static const List<String> freeThemeIds = [
    'sunset',
    'walnut',
    'seaside',
    'harvest',
  ];

  static const List<GarageThemeDef> all = [
    GarageThemeDef(
      id: 'sunset',
      name: 'Sunset Garage',
      woodDark: Color(0xFF5B3A26),
      woodMid: Color(0xFF7A5233),
      oak: Color(0xFFA9764B),
      signCream: Color(0xFFF3E9D2),
      signRed: Color(0xFFC0392B),
      concrete: Color(0xFF9A978E),
      bayLine: Color(0xFFEFEDE6),
      chrome: Color(0xFFC9CDD2),
      ink: Color(0xFF2A1E14),
      backdropA: Color(0xFF9A7250),
      backdropB: Color(0xFF4A3423),
    ),
    GarageThemeDef(
      id: 'walnut',
      name: 'Dark Walnut Shop',
      woodDark: Color(0xFF3E2716),
      woodMid: Color(0xFF5B3A26),
      oak: Color(0xFF8A5F38),
      signCream: Color(0xFFF0E4C8),
      signRed: Color(0xFFA93226),
      concrete: Color(0xFF8A877E),
      bayLine: Color(0xFFE8E4D6),
      chrome: Color(0xFFB9BDC4),
      ink: Color(0xFF1E130B),
      backdropA: Color(0xFF6E4F30),
      backdropB: Color(0xFF2E1E12),
    ),
    GarageThemeDef(
      id: 'seaside',
      name: 'Seaside Service',
      woodDark: Color(0xFF4A5A52),
      woodMid: Color(0xFF64766C),
      oak: Color(0xFF9AA892),
      signCream: Color(0xFFF5EFDD),
      signRed: Color(0xFFB7412F),
      concrete: Color(0xFFA3A099),
      bayLine: Color(0xFFF2EEE2),
      chrome: Color(0xFFD2D6DB),
      ink: Color(0xFF23302A),
      backdropA: Color(0xFF7E9A90),
      backdropB: Color(0xFF3A4A44),
    ),
    GarageThemeDef(
      id: 'harvest',
      name: 'Harvest Barn',
      woodDark: Color(0xFF6B4423),
      woodMid: Color(0xFF8A5F33),
      oak: Color(0xFFC08D4F),
      signCream: Color(0xFFF7ECD4),
      signRed: Color(0xFFB03A2E),
      concrete: Color(0xFFA39B8C),
      bayLine: Color(0xFFF4EEDF),
      chrome: Color(0xFFC9CDD2),
      ink: Color(0xFF33200F),
      backdropA: Color(0xFFB08A4E),
      backdropB: Color(0xFF54402A),
    ),
    GarageThemeDef(
      id: 'midnight',
      name: 'Midnight Motorworks',
      woodDark: Color(0xFF2A2A34),
      woodMid: Color(0xFF3E3E4C),
      oak: Color(0xFF6E6E82),
      signCream: Color(0xFFEDE8D8),
      signRed: Color(0xFFC0392B),
      concrete: Color(0xFF7E7C76),
      bayLine: Color(0xFFE0DCCF),
      chrome: Color(0xFFD8DCE2),
      ink: Color(0xFF14141C),
      backdropA: Color(0xFF3E3E52),
      backdropB: Color(0xFF16161E),
    ),
    GarageThemeDef(
      id: 'creamery',
      name: 'Creamery Classic',
      woodDark: Color(0xFF8A6A42),
      woodMid: Color(0xFFAA8757),
      oak: Color(0xFFD4AC72),
      signCream: Color(0xFFFBF3DE),
      signRed: Color(0xFFC0392B),
      concrete: Color(0xFFB0A897),
      bayLine: Color(0xFFFAF4E4),
      chrome: Color(0xFFD2D6DB),
      ink: Color(0xFF3A2A14),
      backdropA: Color(0xFFC49A5E),
      backdropB: Color(0xFF6E4E28),
    ),
    GarageThemeDef(
      id: 'forest',
      name: 'Forest Depot',
      woodDark: Color(0xFF3E4A2E),
      woodMid: Color(0xFF5A6A42),
      oak: Color(0xFF8A9A62),
      signCream: Color(0xFFF1EAD6),
      signRed: Color(0xFFA93226),
      concrete: Color(0xFF94917F),
      bayLine: Color(0xFFECE7D2),
      chrome: Color(0xFFC2C6CC),
      ink: Color(0xFF202A14),
      backdropA: Color(0xFF6E7E4E),
      backdropB: Color(0xFF2E3820),
    ),
    GarageThemeDef(
      id: 'brickworks',
      name: 'Brickworks',
      woodDark: Color(0xFF5E2E1E),
      woodMid: Color(0xFF7E4228),
      oak: Color(0xFFA9683E),
      signCream: Color(0xFFF3E6D0),
      signRed: Color(0xFF922B21),
      concrete: Color(0xFF9C9484),
      bayLine: Color(0xFFEEE8D4),
      chrome: Color(0xFFC9CDD2),
      ink: Color(0xFF2E1408),
      backdropA: Color(0xFF9A5A34),
      backdropB: Color(0xFF40220F),
    ),
    GarageThemeDef(
      id: 'lakeside',
      name: 'Lakeside Garage',
      woodDark: Color(0xFF2E4A52),
      woodMid: Color(0xFF42626A),
      oak: Color(0xFF6E8E96),
      signCream: Color(0xFFF0EBDA),
      signRed: Color(0xFFB7412F),
      concrete: Color(0xFF9AA0A0),
      bayLine: Color(0xFFEFEAD9),
      chrome: Color(0xFFD2D6DB),
      ink: Color(0xFF16262B),
      backdropA: Color(0xFF5E7E88),
      backdropB: Color(0xFF24383E),
    ),
    GarageThemeDef(
      id: 'orchard',
      name: 'Orchard Shed',
      woodDark: Color(0xFF6E4E1E),
      woodMid: Color(0xFF8E6830),
      oak: Color(0xFFBA8E4E),
      signCream: Color(0xFFF6EBD2),
      signRed: Color(0xFFB03A2E),
      concrete: Color(0xFFA69E8A),
      bayLine: Color(0xFFF2ECDB),
      chrome: Color(0xFFC9CDD2),
      ink: Color(0xFF38280E),
      backdropA: Color(0xFFA8823E),
      backdropB: Color(0xFF4E3A18),
    ),
    GarageThemeDef(
      id: 'desert',
      name: 'Desert Route',
      woodDark: Color(0xFF7E5A2E),
      woodMid: Color(0xFF9A743E),
      oak: Color(0xFFC49A58),
      signCream: Color(0xFFFAF0D8),
      signRed: Color(0xFFA93226),
      concrete: Color(0xFFB3A78E),
      bayLine: Color(0xFFFAF2DE),
      chrome: Color(0xFFD2D6DB),
      ink: Color(0xFF40300F),
      backdropA: Color(0xFFC89858),
      backdropB: Color(0xFF6E4A24),
    ),
    GarageThemeDef(
      id: 'harbor',
      name: 'Harbor Workshop',
      woodDark: Color(0xFF33424E),
      woodMid: Color(0xFF4A5E6A),
      oak: Color(0xFF728A94),
      signCream: Color(0xFFF2ECDC),
      signRed: Color(0xFFC0392B),
      concrete: Color(0xFF989DA0),
      bayLine: Color(0xFFEEE9D8),
      chrome: Color(0xFFD8DCE2),
      ink: Color(0xFF18242B),
      backdropA: Color(0xFF607884),
      backdropB: Color(0xFF28343C),
    ),
    GarageThemeDef(
      id: 'canyon',
      name: 'Canyon Gas Stop',
      woodDark: Color(0xFF6B3A24),
      woodMid: Color(0xFF8A4E30),
      oak: Color(0xFFB06E42),
      signCream: Color(0xFFF5E8D2),
      signRed: Color(0xFF922B21),
      concrete: Color(0xFFA2977F),
      bayLine: Color(0xFFF0E9D5),
      chrome: Color(0xFFC9CDD2),
      ink: Color(0xFF331C0D),
      backdropA: Color(0xFFA86238),
      backdropB: Color(0xFF4A2A14),
    ),
    GarageThemeDef(
      id: 'meadow',
      name: 'Meadow Motors',
      woodDark: Color(0xFF4E5E34),
      woodMid: Color(0xFF687E46),
      oak: Color(0xFF92A862),
      signCream: Color(0xFFF4EDD8),
      signRed: Color(0xFFB7412F),
      concrete: Color(0xFF9C9A86),
      bayLine: Color(0xFFF0EBD6),
      chrome: Color(0xFFC9CDD2),
      ink: Color(0xFF28301A),
      backdropA: Color(0xFF7E9252),
      backdropB: Color(0xFF39442A),
    ),
  ];

  static GarageThemeDef byId(String id, {GarageThemeDef? custom}) {
    if (id == 'custom') return custom ?? all.first;
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';
}

/// Die-cast paint sets for the blocker cars (and the red hero's finish).
/// Each set holds 12 enamel colors; the hero red is always candy-apple
/// unless a set overrides it.
class PaintSet {
  final String id;
  final String name;
  final List<Color> blockers; // 12 enamel colors, cycled per car
  final Color hero; // the red car's finish

  const PaintSet({
    required this.id,
    required this.name,
    required this.blockers,
    required this.hero,
  });
}

class PaintSets {
  /// First 4 are FREE. The rest are PRO.
  static const List<String> freePaintIds = [
    'showroom',
    'pastel',
    'workshop',
    'diner',
  ];

  static const List<PaintSet> all = [
    PaintSet(
      id: 'showroom',
      name: 'Showroom Stock',
      hero: Color(0xFFC0392B),
      blockers: [
        Color(0xFFF3E9D2), // cream
        Color(0xFFD9A441), // mustard
        Color(0xFF3E7C7B), // teal
        Color(0xFF9AB08A), // pale green
        Color(0xFF9AB8D4), // baby blue
        Color(0xFF8E8E96), // grey
        Color(0xFFB7412F), // brick
        Color(0xFF5E7E96), // steel blue
        Color(0xFFC48A3E), // caramel
        Color(0xFF6E8E5E), // moss
        Color(0xFFE0D0A8), // sand
        Color(0xFF7E5E6E), // mauve
      ],
    ),
    PaintSet(
      id: 'pastel',
      name: 'Pastel Toys',
      hero: Color(0xFFC0392B),
      blockers: [
        Color(0xFFF2D8C8),
        Color(0xFFF2E8B8),
        Color(0xFFC8E0D8),
        Color(0xFFD8E4F0),
        Color(0xFFE8D0D8),
        Color(0xFFD8D8C8),
        Color(0xFFF0C8A8),
        Color(0xFFC8D8E8),
        Color(0xFFE0E0B8),
        Color(0xFFD0C8E0),
        Color(0xFFF0D8B8),
        Color(0xFFC8E8D0),
      ],
    ),
    PaintSet(
      id: 'workshop',
      name: 'Workshop Muted',
      hero: Color(0xFFA93226),
      blockers: [
        Color(0xFF8E8E96),
        Color(0xFF6E6E78),
        Color(0xFFA8A094),
        Color(0xFF7E8A92),
        Color(0xFF9A8A72),
        Color(0xFFB0A898),
        Color(0xFF6E7E6A),
        Color(0xFF8A7E8E),
        Color(0xFFA89880),
        Color(0xFF787E88),
        Color(0xFF98897A),
        Color(0xFF86827A),
      ],
    ),
    PaintSet(
      id: 'diner',
      name: 'Diner Brights',
      hero: Color(0xFFD43A2A),
      blockers: [
        Color(0xFFD9A441),
        Color(0xFF3E7C7B),
        Color(0xFFF3E9D2),
        Color(0xFF5E9E5E),
        Color(0xFF5E8ABE),
        Color(0xFFC46E3E),
        Color(0xFF9E5E8A),
        Color(0xFF6E9E9E),
        Color(0xFFD4BE5E),
        Color(0xFF8A6EAE),
        Color(0xFFBE8A5E),
        Color(0xFF6EAE7E),
      ],
    ),
    PaintSet(
      id: 'cherry',
      name: 'Cherry Picked',
      hero: Color(0xFFC0392B),
      blockers: [
        Color(0xFF922B21),
        Color(0xFFB03A2E),
        Color(0xFF7E2A1E),
        Color(0xFFC46E5E),
        Color(0xFFA85242),
        Color(0xFF8A3A30),
        Color(0xFFD48A72),
        Color(0xFF6E2A20),
        Color(0xFFBE5A48),
        Color(0xFF9E4A38),
        Color(0xFFE0A882),
        Color(0xFF5E2018),
      ],
    ),
    PaintSet(
      id: 'ocean',
      name: 'Ocean Drive',
      hero: Color(0xFFC0392B),
      blockers: [
        Color(0xFF2E5E6E),
        Color(0xFF3E7C8E),
        Color(0xFF4E9EAE),
        Color(0xFF6EBECE),
        Color(0xFF2A4A5E),
        Color(0xFF3A6A7E),
        Color(0xFF8ECEDE),
        Color(0xFF24424E),
        Color(0xFF5E8E9E),
        Color(0xFF7EAECE),
        Color(0xFFAEDEEE),
        Color(0xFF1E3844),
      ],
    ),
    PaintSet(
      id: 'orchardpaint',
      name: 'Orchard Fruits',
      hero: Color(0xFFC0392B),
      blockers: [
        Color(0xFF9E5E2E),
        Color(0xFFBE7E3E),
        Color(0xFFDE9E4E),
        Color(0xFF8A4E28),
        Color(0xFFCE8E4A),
        Color(0xFF7E5E2E),
        Color(0xFFE8AE62),
        Color(0xFF6E4422),
        Color(0xFFAE7E42),
        Color(0xFF9E6E38),
        Color(0xFFF2BE72),
        Color(0xFF5E3A1E),
      ],
    ),
    PaintSet(
      id: 'garden',
      name: 'Victory Garden',
      hero: Color(0xFFB7412F),
      blockers: [
        Color(0xFF4E6E3E),
        Color(0xFF5E7E4E),
        Color(0xFF6E8E5E),
        Color(0xFF3E5E32),
        Color(0xFF7E9E6E),
        Color(0xFF8EAE7E),
        Color(0xFF34522A),
        Color(0xFF9EBE8E),
        Color(0xFFAECE9E),
        Color(0xFF2E4A24),
        Color(0xFFBEDEAE),
        Color(0xFF26401E),
      ],
    ),
    PaintSet(
      id: 'skyline',
      name: 'Skyline Blues',
      hero: Color(0xFFC0392B),
      blockers: [
        Color(0xFF2E4E7E),
        Color(0xFF3E5E8E),
        Color(0xFF4E6E9E),
        Color(0xFF243E68),
        Color(0xFF5E7EAE),
        Color(0xFF6E8EBE),
        Color(0xFF1E3458),
        Color(0xFF7E9ECE),
        Color(0xFF8EAEDE),
        Color(0xFF183048),
        Color(0xFF9EBEEE),
        Color(0xFF142A40),
      ],
    ),
    PaintSet(
      id: 'sunsetpaint',
      name: 'Desert Sunset',
      hero: Color(0xFFD43A2A),
      blockers: [
        Color(0xFFC46E3E),
        Color(0xFFD47E4E),
        Color(0xFFE48E5E),
        Color(0xFFA85E34),
        Color(0xFFF49E6E),
        Color(0xFF98542E),
        Color(0xFFFFAE7E),
        Color(0xFF884A28),
        Color(0xFFE08A58),
        Color(0xFFB86A3A),
        Color(0xFFFFBE8E),
        Color(0xFF783E22),
      ],
    ),
    PaintSet(
      id: 'monochrome',
      name: 'Newsprint',
      hero: Color(0xFFB0B0B0),
      blockers: [
        Color(0xFF2E2E2E),
        Color(0xFF4E4E4E),
        Color(0xFF6E6E6E),
        Color(0xFF8E8E8E),
        Color(0xFFAEAEAE),
        Color(0xFFCECECE),
        Color(0xFF3E3E3E),
        Color(0xFF5E5E5E),
        Color(0xFF7E7E7E),
        Color(0xFF9E9E9E),
        Color(0xFFBEBEBE),
        Color(0xFFDEDEDE),
      ],
    ),
    PaintSet(
      id: 'royal',
      name: 'Royal Enamel',
      hero: Color(0xFF922B21),
      blockers: [
        Color(0xFF4E2E6E),
        Color(0xFF5E3E7E),
        Color(0xFF6E4E8E),
        Color(0xFF3E245E),
        Color(0xFF7E5E9E),
        Color(0xFF8E6EAE),
        Color(0xFF341E4E),
        Color(0xFF9E7EBE),
        Color(0xFFAE8ECE),
        Color(0xFF2A1840),
        Color(0xFFBE9EDE),
        Color(0xFF201436),
      ],
    ),
  ];

  static PaintSet byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);

  static bool isProPaint(String id) => !freePaintIds.contains(id);
}
