import '../../../core/l10n/generated/app_localizations.dart';
import '../domain/body_type.dart';
import '../domain/fuel_type.dart';
import '../domain/paint_color.dart';

String bodyTypeLabel(AppLocalizations l10n, BodyType type) => switch (type) {
  BodyType.sedan => l10n.bodySedan,
  BodyType.hatchback => l10n.bodyHatchback,
  BodyType.suv => l10n.bodySuv,
  BodyType.coupe => l10n.bodyCoupe,
  BodyType.wagon => l10n.bodyWagon,
  BodyType.pickup => l10n.bodyPickup,
  BodyType.van => l10n.bodyVan,
};

/// "Usually hybrid" (spec S-05 model card subline).
String usualFuelLabel(AppLocalizations l10n, FuelType type) => switch (type) {
  FuelType.petrol => l10n.usuallyPetrol,
  FuelType.diesel => l10n.usuallyDiesel,
  FuelType.hybrid => l10n.usuallyHybrid,
  FuelType.ev => l10n.usuallyEv,
};

String fuelTypeLabel(AppLocalizations l10n, FuelType type) => switch (type) {
  FuelType.petrol => l10n.fuelPetrol,
  FuelType.diesel => l10n.fuelDiesel,
  FuelType.hybrid => l10n.fuelHybrid,
  FuelType.ev => l10n.fuelEv,
};

String paintColorLabel(AppLocalizations l10n, PaintColor paint) => switch (paint) {
  PaintColor.obsidianBlack => l10n.paintObsidianBlack,
  PaintColor.polarWhite => l10n.paintPolarWhite,
  PaintColor.silver => l10n.paintSilver,
  PaintColor.gunmetalGrey => l10n.paintGunmetalGrey,
  PaintColor.desertSand => l10n.paintDesertSand,
  PaintColor.champagne => l10n.paintChampagne,
  PaintColor.midnightBlue => l10n.paintMidnightBlue,
  PaintColor.skyBlue => l10n.paintSkyBlue,
  PaintColor.racingRed => l10n.paintRacingRed,
  PaintColor.sunsetOrange => l10n.paintSunsetOrange,
  PaintColor.forestGreen => l10n.paintForestGreen,
  PaintColor.bronze => l10n.paintBronze,
};
