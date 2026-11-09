// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'TDC-mena Garage';

  @override
  String get launchLoadingLabel => 'TDC-mena Garage is loading';

  @override
  String get launchErrorTitle => 'We couldn\'t open your garage';

  @override
  String get launchErrorBody =>
      'Something went wrong while loading your data. Your data is safe on this phone.';

  @override
  String get actionRetry => 'Try again';

  @override
  String get languageSwitchLabel => 'العربية';

  @override
  String get languageSwitchSemantic => 'Switch the app to Arabic';

  @override
  String get introSkip => 'Skip';

  @override
  String get introNext => 'Next';

  @override
  String get introGetStarted => 'Get started';

  @override
  String get introSignIn => 'I already have an account · Sign in';

  @override
  String introPageLabel(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get introPage1Title => 'Your car\'s health at a glance';

  @override
  String get introPage1Body =>
      'See what needs attention before it becomes a repair bill.';

  @override
  String get introPage2Title => 'Never miss a service';

  @override
  String get introPage2Body =>
      'Reminders before oil, brakes and tires are due, based on typical intervals.';

  @override
  String get introPage3Title => 'Start now, no account needed';

  @override
  String get introPage3Body =>
      'Your garage stays on this phone. Back it up whenever you like.';

  @override
  String get healthScoreLabel => 'Health score';

  @override
  String get healthBandGood => 'Good';

  @override
  String get statMileage => 'Mileage';

  @override
  String get statMileageSub => 'Total';

  @override
  String get statNextService => 'Next service';

  @override
  String get statNextServiceSub => 'Days away';

  @override
  String get statThisYear => 'This year';

  @override
  String get statThisYearSub => 'Spent';

  @override
  String get unitKm => 'km';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionClose => 'Close';

  @override
  String get actionClearSearch => 'Clear search';

  @override
  String get stateSelected => 'Selected';

  @override
  String stepLabel(int current, int total, String name) {
    return 'Step $current of $total: $name';
  }

  @override
  String get stepCountry => 'Country';

  @override
  String get stepBrand => 'Brand';

  @override
  String get stepCar => 'Car';

  @override
  String get stepService => 'Service';

  @override
  String get unitMi => 'mi';

  @override
  String get countryTitle => 'Where do you drive?';

  @override
  String get countryBody =>
      'We\'ll set your currency, distance unit and popular brands. You can change these any time.';

  @override
  String get countryCardLabel => 'Country';

  @override
  String get countryChange => 'Change';

  @override
  String get countryNotSet => 'Not set';

  @override
  String get countryOther => 'Other / not set';

  @override
  String get countryOtherHint => 'USD, km and the most popular brands';

  @override
  String get popularListStandard => 'Popular brands';

  @override
  String get popularListGulf => 'Gulf brands';

  @override
  String get popularListEgypt => 'Egypt brands';

  @override
  String get countryPickerTitle => 'Choose your country';

  @override
  String get countrySearchHint => 'Search country…';

  @override
  String get countryNoResults => 'No countries found';

  @override
  String get countryNoResultsHint =>
      'Try another spelling, or choose Other / not set.';

  @override
  String get consentTitle => 'Help us improve the app';

  @override
  String get consentBody =>
      'Share anonymous usage data. No advertising, no tracking across apps.';

  @override
  String get consentAllow => 'Allow';

  @override
  String get consentDeny => 'Don\'t allow';

  @override
  String get consentRequiredHint => 'Choose Allow or Don\'t allow to continue.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get garageTitle => 'Garage';

  @override
  String get brandPrompt => 'Select your car brand';

  @override
  String get brandScreenTitle => 'Select your car brand';

  @override
  String get brandSearchHint => 'Search brand…';

  @override
  String get brandSelect => 'Select';

  @override
  String get brandOther => 'Other brand';

  @override
  String get brandOtherHint => 'Type your brand';

  @override
  String get brandOtherFieldLabel => 'Brand name';

  @override
  String brandContinueWith(String brand) {
    return 'Continue with $brand';
  }

  @override
  String get brandNoResults => 'No brands found';

  @override
  String get brandFoundInTabs => 'Found in other tabs:';

  @override
  String brandAddAsOther(String name) {
    return 'Add “$name” as other brand';
  }

  @override
  String get tabPopular => 'Popular';

  @override
  String get tabEuropean => 'European';

  @override
  String get tabJapanese => 'Japanese';

  @override
  String get tabKorean => 'Korean';

  @override
  String get tabChinese => 'Chinese';

  @override
  String get tabAmerican => 'American';

  @override
  String tabSemantic(String name, int index, int count) {
    return '$name, tab $index of $count';
  }

  @override
  String get discardVehicleTitle => 'Discard this vehicle?';

  @override
  String get discardVehicleBody => 'The brand you chose won\'t be saved.';

  @override
  String get actionDiscard => 'Discard';

  @override
  String get actionKeepEditing => 'Keep editing';

  @override
  String get modelSubtitle => 'Choose your model';

  @override
  String get modelOther => 'Other model';

  @override
  String get modelOtherHint => 'Type your model';

  @override
  String get modelNameLabel => 'Model name';

  @override
  String get bodyTypeLabel => 'Body type';

  @override
  String get bodyTypeHelper => 'Picks the illustration for your car.';

  @override
  String get bodySedan => 'Sedan';

  @override
  String get bodyHatchback => 'Hatchback';

  @override
  String get bodySuv => 'SUV';

  @override
  String get bodyCoupe => 'Coupe';

  @override
  String get bodyWagon => 'Wagon';

  @override
  String get bodyPickup => 'Pickup';

  @override
  String get bodyVan => 'Van';

  @override
  String get usuallyPetrol => 'Usually petrol';

  @override
  String get usuallyDiesel => 'Usually diesel';

  @override
  String get usuallyHybrid => 'Usually hybrid';

  @override
  String get usuallyEv => 'Usually electric';

  @override
  String get modelsComingSoon => 'Model list for this brand is coming soon.';

  @override
  String get modelNeedBrandTitle => 'Choose a brand first';

  @override
  String get modelNeedBrandBody => 'We couldn\'t find the brand for this car.';

  @override
  String get modelNeedBrandAction => 'Choose brand';

  @override
  String positionOf(int index, int count) {
    return '$index of $count';
  }

  @override
  String get detailsSubtitle => 'Tell us about your car';

  @override
  String get fuelTypeLabel => 'Fuel type';

  @override
  String get fuelTypeHelper => 'Sets your maintenance schedule.';

  @override
  String get fuelPetrol => 'Petrol';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelHybrid => 'Hybrid';

  @override
  String get fuelEv => 'EV';

  @override
  String get odometerLabel => 'Current odometer';

  @override
  String get odometerHelper => 'Check your dashboard.';

  @override
  String get odometerMissing => 'Enter your current mileage';

  @override
  String get odometerNotNumber => 'Enter numbers only';

  @override
  String get odometerTooHigh => 'That looks too high. Check the number.';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get paintColorLabel => 'Paint colour';

  @override
  String get paintObsidianBlack => 'Obsidian Black';

  @override
  String get paintPolarWhite => 'Polar White';

  @override
  String get paintSilver => 'Silver';

  @override
  String get paintGunmetalGrey => 'Gunmetal Grey';

  @override
  String get paintDesertSand => 'Desert Sand';

  @override
  String get paintChampagne => 'Champagne';

  @override
  String get paintMidnightBlue => 'Midnight Blue';

  @override
  String get paintSkyBlue => 'Sky Blue';

  @override
  String get paintRacingRed => 'Racing Red';

  @override
  String get paintSunsetOrange => 'Sunset Orange';

  @override
  String get paintForestGreen => 'Forest Green';

  @override
  String get paintBronze => 'Bronze';

  @override
  String get moreDetailsTitle => 'Add nickname, year, VIN and more';

  @override
  String get moreDetailsOptional => 'Optional';

  @override
  String get nicknameLabel => 'Nickname';

  @override
  String get yearLabel => 'Year';

  @override
  String get plateLabel => 'Licence plate';

  @override
  String get vinLabel => 'VIN';

  @override
  String get purchaseDateLabel => 'Purchase date';

  @override
  String get vinLengthWarning =>
      'VINs are usually 17 characters. Keep it if your car is older than 1981.';

  @override
  String get vinInvalid => 'VINs don\'t use the letters I, O or Q.';

  @override
  String get duplicateVinTitle => 'You already have a car with this VIN';

  @override
  String duplicateVinBody(String name) {
    return '$name has the same VIN. Add anyway?';
  }

  @override
  String get duplicateVinAdd => 'Add anyway';

  @override
  String get duplicateVinChange => 'Change VIN';

  @override
  String get dateToday => 'Today';

  @override
  String get dateClear => 'Clear';

  @override
  String get dateDone => 'Done';

  @override
  String get detailsNeedModelTitle => 'Choose a model first';

  @override
  String get detailsNeedModelBody =>
      'We couldn\'t find the model for this car.';

  @override
  String get duplicateVinUnnamed => 'Another car in your garage';

  @override
  String get baselineTitle => 'When were these last done?';

  @override
  String get baselineSubtitle =>
      'This makes your health score accurate. Skip anything you don\'t know.';

  @override
  String get newCarTitle => 'My car is new';

  @override
  String get newCarSubtitle =>
      'Delivered recently? We\'ll start everything fresh.';

  @override
  String get deliveryDateLabel => 'Delivery date';

  @override
  String get startingMileageLabel => 'Starting mileage';

  @override
  String get newCarNote =>
      'All items start from your delivery date. Your score starts at 100.';

  @override
  String get baselineOilService => 'Oil change or service';

  @override
  String get baselineBrakes => 'Brakes';

  @override
  String get baselineTires => 'Tires';

  @override
  String get baselineBattery => 'Battery';

  @override
  String get baselineDateLabel => 'Date';

  @override
  String get baselineMileageLabel => 'Mileage';

  @override
  String get baselineDontKnow => 'I don\'t know';

  @override
  String get baselineUnknownBadge => 'Unknown';

  @override
  String get baselineFooter =>
      'Other items like filters and coolant start as Unknown. You can set them later in your schedule.';

  @override
  String get actionSaveVehicle => 'Save vehicle';

  @override
  String baselineKmAboveOdometer(String mileage) {
    return 'Can\'t be more than your current mileage ($mileage).';
  }

  @override
  String baselineCardSemantic(String item) {
    return '$item, last done';
  }

  @override
  String baselineUnknownAnnounce(String item) {
    return '$item marked as unknown';
  }

  @override
  String baselineKnownAnnounce(String item) {
    return '$item can be filled in again';
  }

  @override
  String get deliveryOldTitle => 'Some items may already be due';

  @override
  String deliveryOldBody(String age) {
    return 'Your delivery date is $age. Items with shorter intervals will show as due or overdue.';
  }

  @override
  String get deliveryOldBodyDistance =>
      'Your car has been driven past some intervals since delivery. Those items will show as due or overdue.';

  @override
  String deliveryAgeYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String deliveryAgeMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String get deliveryKeep => 'Keep this date';

  @override
  String get deliveryChange => 'Change date';

  @override
  String get deliveryDateMissing => 'Choose your delivery date';

  @override
  String get baselineNeedDetailsTitle => 'Add your car\'s details first';

  @override
  String get baselineNeedDetailsBody =>
      'We couldn\'t find the details for this car.';

  @override
  String get primerTitle => 'Never miss a service';

  @override
  String get primerBody =>
      'We\'ll remind you 30, 7 and 1 day before something is due, at 9:00. You can turn this off any time.';

  @override
  String get primerDeniedHint =>
      'Notifications are off for TDC Garage. Turn them on in Settings.';

  @override
  String get primerTurnOn => 'Turn on reminders';

  @override
  String get primerOpenSettings => 'Open Settings';

  @override
  String get primerNotNow => 'Not now';

  @override
  String get primerPreviewApp => 'TDC Garage';

  @override
  String get primerPreviewTime => 'now';

  @override
  String primerPreviewText(String vehicle, String item) {
    return '$vehicle · $item due in 7 days';
  }

  @override
  String primerPreviewSemantic(String text) {
    return 'Example notification: $text';
  }

  @override
  String get primerPillExample => 'Due in 7 days';

  @override
  String get remindersOnToast => 'Reminders are on';

  @override
  String get primerPreviewFallbackItem => 'Oil change';

  @override
  String get navGarage => 'Garage';

  @override
  String get navHistory => 'History';

  @override
  String get navAdd => 'Add';

  @override
  String get navProfile => 'Profile';

  @override
  String dashboardSwitchVehicle(String name) {
    return '$name, switch vehicle';
  }

  @override
  String dashboardModelYear(String model, String year) {
    return '$model · $year';
  }

  @override
  String dashboardVehicleDots(int index, int count) {
    return 'Vehicle $index of $count';
  }

  @override
  String get actionMoreOptions => 'More options';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get menuSchedule => 'Schedule';

  @override
  String get menuMileageHistory => 'Mileage history';

  @override
  String get menuEditVehicle => 'Edit vehicle';

  @override
  String get menuDeleteVehicle => 'Delete vehicle';

  @override
  String deleteVehicleTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteVehicleBody =>
      'This deletes its schedule, service history and reminders. This can\'t be undone.';

  @override
  String deleteVehicleDone(String name) {
    return '$name deleted';
  }

  @override
  String get bandExcellent => 'Excellent';

  @override
  String get bandGood => 'Good';

  @override
  String get bandNeedsAttention => 'Needs attention';

  @override
  String get bandUrgent => 'Urgent';

  @override
  String healthBasedOnTypical(int count) {
    return 'Based on typical intervals · $count unknown';
  }

  @override
  String healthSemantic(int score, String band) {
    return 'Health score $score percent, $band';
  }

  @override
  String statUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Updated $count days ago',
      one: 'Updated yesterday',
      zero: 'Updated today',
    );
    return '$_temp0';
  }

  @override
  String get statDaysAway => 'Days away';

  @override
  String get statDue => 'Due';

  @override
  String get statToday => 'Today';

  @override
  String get statDaysOverdue => 'Days overdue';

  @override
  String get statSetUpSchedule => 'Set up your schedule';

  @override
  String statDistanceToGo(String unit) {
    return '$unit to go';
  }

  @override
  String statItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String statDateItems(String date, String items) {
    return '$date · $items';
  }

  @override
  String get statSpent => 'Spent';

  @override
  String statServices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services',
      one: '1 service',
      zero: 'No costs yet',
    );
    return '$_temp0';
  }

  @override
  String get statSomeNotIncluded => 'Some records not included';

  @override
  String statCardSemantic(
    String label,
    String value,
    String sublabel,
    String footer,
  ) {
    return '$label, $value $sublabel, $footer';
  }

  @override
  String get statCarouselLabel => 'Stat cards';

  @override
  String get statCarouselHint => 'Swipe up or down to change';

  @override
  String get unitKmWord => 'kilometres';

  @override
  String get unitMiWord => 'miles';

  @override
  String alertOverdueOne(String item) {
    return '$item overdue';
  }

  @override
  String alertOverdueMany(int count) {
    return '$count items overdue';
  }

  @override
  String alertDueSoon(String item) {
    return '$item due soon';
  }

  @override
  String alertUnknown(int count) {
    return 'Complete your schedule · $count unknown';
  }

  @override
  String alertStaleMileage(int count) {
    return 'Update your mileage · $count days';
  }

  @override
  String get alertAllGood => 'All good';

  @override
  String get upcomingTitle => 'Upcoming';

  @override
  String upcomingInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count days',
      one: 'In 1 day',
      zero: 'Due today',
    );
    return '$_temp0';
  }

  @override
  String upcomingOverdueDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Overdue by $count days',
      one: 'Overdue by 1 day',
      zero: 'Overdue',
    );
    return '$_temp0';
  }

  @override
  String upcomingInDistance(String distance) {
    return 'In $distance';
  }

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get statusDueSoon => 'Due soon';

  @override
  String get statusOk => 'OK';

  @override
  String get switcherTitle => 'Your garage';

  @override
  String switcherCount(int count, int max) {
    return '$count of $max vehicles';
  }

  @override
  String get switcherAddVehicle => 'Add vehicle';

  @override
  String get switcherLimitReached => 'Limit reached. Contact support.';

  @override
  String get switcherManage => 'Manage vehicles';

  @override
  String switcherOverdue(int count) {
    return '$count overdue';
  }

  @override
  String get switcherNotSetUp => 'Not set up';

  @override
  String get switcherCurrent => 'Current vehicle';

  @override
  String switcherRowSemantic(String name, String subline, String status) {
    return '$name, $subline, $status';
  }

  @override
  String healthSummaryOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items are overdue',
      one: '1 item is overdue',
    );
    return '$_temp0';
  }

  @override
  String healthSummarySoon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items are due within 30 days',
      one: '1 item is due within 30 days',
    );
    return '$_temp0';
  }

  @override
  String healthSummaryJoin(String first, String second) {
    return '$first and $second.';
  }

  @override
  String healthSummarySentence(String text) {
    return '$text.';
  }

  @override
  String get healthNothingLowering => 'Nothing is lowering your score';

  @override
  String get healthSectionLowering => 'Lowering your score';

  @override
  String healthReasonOverdueKm(String distance) {
    return 'Overdue by $distance';
  }

  @override
  String healthReasonDueInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Due in $count days',
      one: 'Due in 1 day',
      zero: 'Due today',
    );
    return '$_temp0';
  }

  @override
  String healthReasonDueInKm(String distance) {
    return 'Due in about $distance';
  }

  @override
  String get healthDoubleBadge => '×2';

  @override
  String healthRowSemantic(String item, String reason, int points) {
    return '$item, $reason, minus $points points';
  }

  @override
  String get healthCountsDouble => 'counts double';

  @override
  String get healthSectionNotCounted => 'Not counted';

  @override
  String get healthUnknownSetLastDone => 'Unknown: set last done';

  @override
  String healthSnoozedUntil(String date) {
    return 'Snoozed until $date';
  }

  @override
  String get healthHowTitle => 'How the score works';

  @override
  String get healthHowBody =>
      'Your score starts at 100. Overdue items lose 5 to 15 points depending on how important they are, and items due within 30 days lose 2. Items more than 30 days or 1,000 km overdue count double.';

  @override
  String healthTemplateLine(String fuel, int version) {
    return 'Typical intervals for $fuel · template v$version';
  }

  @override
  String get healthSeeSchedule => 'See your schedule';

  @override
  String get mileageTitle => 'Update mileage';

  @override
  String mileageLast(String reading, String date) {
    return 'Last: $reading · $date';
  }

  @override
  String mileageFieldLabel(String unit) {
    return 'New odometer reading in $unit';
  }

  @override
  String get mileageChooseVehicle => 'Choose vehicle';

  @override
  String get actionSave => 'Save';

  @override
  String get actionEdit => 'Edit';

  @override
  String get mileageViewHistory => 'View history';

  @override
  String get mileageLowerTitle => 'This is lower than your last reading';

  @override
  String mileageLowerBody(String last, String date, String value) {
    return 'Your last reading was $last on $date. Save $value as a correction?';
  }

  @override
  String get mileageSaveCorrection => 'Save as correction';

  @override
  String get mileageJumpTitle => 'Is this correct?';

  @override
  String mileageJumpBody(String distance, String period) {
    return 'That\'s $distance in $period.';
  }

  @override
  String mileageDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get mileageJumpConfirm => 'Yes, save';

  @override
  String get mileageUpdatedToast => 'Mileage updated';

  @override
  String get mileageAverageLabel => 'Average';

  @override
  String mileageAveragePerMonth(String distance) {
    return '$distance / month';
  }

  @override
  String get mileageAverageBasis => 'Based on the last 180 days';

  @override
  String mileageAverageNeedMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add another reading in $count days to see your average.',
      one: 'Add another reading tomorrow to see your average.',
      zero: 'Add another reading to see your average.',
    );
    return '$_temp0';
  }

  @override
  String get mileageSourceManual => 'Manual';

  @override
  String get mileageSourceService => 'From service';

  @override
  String get mileageSourceSetup => 'Baseline';

  @override
  String get mileageSourceFuel => 'From fill-up';

  @override
  String get mileageCorrection => 'Correction';

  @override
  String get mileageDeleteTitle => 'Delete this reading?';

  @override
  String mileageDeleteBody(String reading, String date) {
    return '$reading on $date will be removed.';
  }

  @override
  String get mileageDeleted => 'Reading deleted';

  @override
  String get mileageServiceHint => 'Delete the service record to remove this';

  @override
  String get mileageEmptyTitle => 'Only your starting reading so far';

  @override
  String mileageRowSemantic(String reading, String date, String source) {
    return '$reading, $date, $source';
  }

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String get scheduleFilterAll => 'All';

  @override
  String scheduleFilterCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get scheduleUpcoming => 'Upcoming';

  @override
  String get scheduleNotApplicable => 'Not applicable';

  @override
  String get scheduleSnoozed => 'Snoozed';

  @override
  String get scheduleCritical => 'Critical';

  @override
  String scheduleDueDateOrKm(String date, String distance) {
    return 'Due $date or at $distance';
  }

  @override
  String scheduleDueDate(String date) {
    return 'Due $date';
  }

  @override
  String scheduleDueKm(String distance) {
    return 'Due at $distance';
  }

  @override
  String get scheduleAddCustom => 'Add custom item';

  @override
  String get scheduleTemplateTitle => 'Typical intervals';

  @override
  String get scheduleTemplateBody =>
      'These are typical intervals reviewed by a qualified mechanic. Your manufacturer\'s schedule may differ. Edit any item to match it.';

  @override
  String get scheduleAllGood => 'All good. Everything is on schedule.';

  @override
  String get scheduleNothingHere => 'Nothing here';

  @override
  String scheduleRowSemantic(String item, String due, String status) {
    return '$item, $due, $status';
  }

  @override
  String scheduleSectionSemantic(String section, int count) {
    return '$section, $count items';
  }

  @override
  String get scheduleSelectItem => 'Choose an item to see its details';

  @override
  String get itemResetToTypical => 'Reset to typical';

  @override
  String get itemDelete => 'Delete item';

  @override
  String itemDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get itemDeleteBody => 'It will be removed from your schedule.';

  @override
  String get itemFactInterval => 'Interval';

  @override
  String get itemFactLastDone => 'Last done';

  @override
  String get itemFactNextDue => 'Next due';

  @override
  String get itemFactPredicted => 'Predicted';

  @override
  String get itemFactScore => 'Score impact';

  @override
  String itemEvery(String interval) {
    return 'Every $interval';
  }

  @override
  String itemMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: 'month',
    );
    return '$_temp0';
  }

  @override
  String itemOr(String first, String second) {
    return '$first or $second';
  }

  @override
  String get itemEdited => 'Edited';

  @override
  String itemDateKm(String date, String distance) {
    return '$date · $distance';
  }

  @override
  String get itemSourceBaseline => 'Baseline';

  @override
  String get itemSourceNewCar => 'Delivery';

  @override
  String get itemSourceService => 'From your service';

  @override
  String get itemSourceManual => 'Set by you';

  @override
  String itemPredictedValue(String date) {
    return 'Around $date at your usual mileage';
  }

  @override
  String itemPoints(String points) {
    return '$points points';
  }

  @override
  String get itemNone => 'None';

  @override
  String get itemNotYet => 'Not yet';

  @override
  String get itemMarkDone => 'Mark as done';

  @override
  String get itemSnooze => 'Snooze';

  @override
  String get itemReschedule => 'Reschedule';

  @override
  String get itemSnoozeTitle => 'Snooze reminders';

  @override
  String itemSnoozeDays(int count) {
    return '$count days';
  }

  @override
  String get itemSnoozeOverdueNote =>
      'Reminders pause, but the score still counts this as overdue.';

  @override
  String get itemRescheduleNote =>
      'Only this time. Later reminders use the normal interval.';

  @override
  String itemRescheduledToast(String date) {
    return 'Due date moved to $date';
  }

  @override
  String get itemEditInterval => 'Edit interval';

  @override
  String get itemNotApplicableToggle => 'Not applicable to my car';

  @override
  String get itemNotApplicableHint => 'Hidden from your score and reminders';

  @override
  String get itemSetLastDone => 'Set last done';

  @override
  String get itemLastDoneSaved => 'Last done saved';

  @override
  String get itemLastDoneNeedOne => 'Enter a date or a mileage';

  @override
  String get itemHistoryTitle => 'Service history';

  @override
  String get itemHistoryEmpty => 'No services logged for this item yet.';

  @override
  String get actionUndo => 'Undo';

  @override
  String get itemNotFound => 'This item no longer exists';

  @override
  String get intervalEditTitle => 'Edit interval';

  @override
  String get customNameLabel => 'Name';

  @override
  String get customNameRequired => 'Enter a name';

  @override
  String get intervalMonthsLabel => 'Every … months';

  @override
  String intervalDistanceLabel(String unit) {
    return 'Every … $unit';
  }

  @override
  String get intervalMonthsUnit => 'months';

  @override
  String get intervalNote =>
      'Whichever comes first. Leave one empty to use only the other.';

  @override
  String get intervalNeedOne => 'Set at least one interval.';

  @override
  String get intervalAboveZero => 'Must be more than 0';

  @override
  String get importanceLabel => 'Importance';

  @override
  String get severityCritical => 'Critical';

  @override
  String get severityMajor => 'Major';

  @override
  String get severityMinor => 'Minor';

  @override
  String importanceHelper(String points) {
    return 'Overdue: $points';
  }

  @override
  String get customLastDoneTitle => 'Last done (optional)';

  @override
  String intervalTypical(String interval) {
    return 'Typical: $interval';
  }

  @override
  String get intervalUpdated => 'Interval updated';

  @override
  String customItemAdded(String name) {
    return '$name added';
  }

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get templateUpdateBanner => 'Typical intervals updated';

  @override
  String get templateUpdateReview => 'Review';

  @override
  String get templateUpdateTitle => 'Typical intervals updated';

  @override
  String get templateUpdateDefaultSummary => 'Some typical intervals changed.';

  @override
  String templateUpdateMonths(int from, int to) {
    String _temp0 = intl.Intl.pluralLogic(
      to,
      locale: localeName,
      other: 'months',
      one: 'month',
    );
    return 'Every $from → $to $_temp0';
  }

  @override
  String templateUpdateDistance(String from, String to) {
    return '$from → $to';
  }

  @override
  String templateUpdateSeverity(String from, String to) {
    return 'Importance: $from → $to';
  }

  @override
  String templateUpdateNewItem(String interval) {
    return 'New item · $interval';
  }

  @override
  String get templateUpdateKept => 'Kept: you edited this';

  @override
  String templateUpdateNote(int version) {
    return 'Reviewed by a qualified mechanic · template v$version';
  }

  @override
  String get templateUpdateApply => 'Apply';

  @override
  String get templateUpdateKeep => 'Keep current';

  @override
  String get templateUpdateApplied => 'Schedule updated';

  @override
  String get templateUpdateMenu => 'Review updated intervals';

  @override
  String get templateUpdateBadge => 'Updated intervals';

  @override
  String get templateUpdateNothingToApply =>
      'You edited every changed item, so nothing will change.';

  @override
  String nextServiceOverdueDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String nextServiceInDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count days',
      one: 'Tomorrow',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String nextServiceInKm(String distance) {
    return 'In about $distance';
  }

  @override
  String get nextServiceKmNote =>
      'Update your mileage now and then to get a date.';

  @override
  String get nextServiceDueAround => 'Due around then';

  @override
  String get nextServiceDoNow => 'To do now';

  @override
  String get nextServiceLog => 'Log service';

  @override
  String get nextServiceSeeSchedule => 'See full schedule';

  @override
  String get nextServiceNothing =>
      'Nothing is due yet. Set when items were last done to see your next service.';

  @override
  String nextServiceSemantic(String title, String value, String detail) {
    return '$title: $value, $detail';
  }

  @override
  String get spendTitle => 'Spending';

  @override
  String get spendPreviousYear => 'Previous year';

  @override
  String get spendNextYear => 'Next year';

  @override
  String spendServicesInYear(int count, String year) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services in $year',
      one: '1 service in $year',
      zero: 'No services in $year',
    );
    return '$_temp0';
  }

  @override
  String get spendOtherCurrencies =>
      'Records in other currencies aren\'t included.';

  @override
  String get spendChangeCurrency => 'Change currency';

  @override
  String get spendRecords => 'Records';

  @override
  String get spendNotInTotal => 'Not in total';

  @override
  String spendEmpty(String year) {
    return 'No costs logged in $year';
  }

  @override
  String spendTotalSemantic(String year, String amount, String count) {
    return 'Total for $year: $amount, $count';
  }

  @override
  String get actionLogService => 'Log service';

  @override
  String get serviceTypeMaintenance => 'Maintenance';

  @override
  String get serviceTypeRepair => 'Repair';

  @override
  String get serviceTypeInspection => 'Inspection';

  @override
  String get serviceTypeOther => 'Other';

  @override
  String serviceRecordSemantic(
    String date,
    String title,
    String detail,
    String cost,
  ) {
    return '$date, $title, $detail, $cost';
  }

  @override
  String get historyTitle => 'History';

  @override
  String historyYearChip(String year) {
    return 'Year: $year';
  }

  @override
  String get historyAllYears => 'All years';

  @override
  String historyTypeChip(String type) {
    return 'Type: $type';
  }

  @override
  String get historyAllTypes => 'All';

  @override
  String get historyClear => 'Clear';

  @override
  String get historyChooseYear => 'Year';

  @override
  String get historyChooseType => 'Type';

  @override
  String historyVehicleChip(String name) {
    return 'Vehicle: $name. Change vehicle';
  }

  @override
  String get historyEmptyTitle => 'No services yet';

  @override
  String get historyEmptyBody =>
      'Log your first service to build your car\'s history.';

  @override
  String get historyNoMatch => 'No services match these filters';

  @override
  String get historyClearFilters => 'Clear filters';

  @override
  String get historySelectRecord => 'Select a record to see it here.';

  @override
  String get historyLoading => 'Loading history';

  @override
  String get recordFactOdometer => 'Odometer';

  @override
  String get recordFactCost => 'Cost';

  @override
  String get recordFactShop => 'Shop';

  @override
  String get recordItemsTitle => 'Items covered';

  @override
  String get recordNoItems => 'No schedule items. Nothing was reset.';

  @override
  String get recordNotesTitle => 'Notes';

  @override
  String get recordNoNotes => 'No notes';

  @override
  String recordAdded(String dateTime) {
    return 'Added $dateTime';
  }

  @override
  String get recordDeleteTitle => 'Delete this service?';

  @override
  String recordDeleteBodyItems(String items) {
    return '$items will go back to their previous dates.';
  }

  @override
  String get recordDeleteBodyNone =>
      'It will be removed from your history and spending.';

  @override
  String get recordDeleted => 'Service deleted';

  @override
  String get recordGone => 'This service was deleted.';

  @override
  String recordItemSemantic(String name) {
    return '$name. Open item';
  }

  @override
  String listAnd(String first, String last) {
    return '$first and $last';
  }

  @override
  String get logTitle => 'Log service';

  @override
  String get logEditTitle => 'Edit service';

  @override
  String logFor(String name) {
    return 'For: $name';
  }

  @override
  String get logChooseVehicle => 'Choose the vehicle';

  @override
  String get logDate => 'Date';

  @override
  String get logOdometer => 'Odometer';

  @override
  String logOdometerCurrent(String value) {
    return 'Current: $value';
  }

  @override
  String get logOdometerRequired => 'Enter the odometer reading.';

  @override
  String get logWhatDone => 'What was done?';

  @override
  String get logAddCustom => 'Add custom item';

  @override
  String logChipSemantic(String name, String status) {
    return '$name, $status';
  }

  @override
  String get logType => 'Type';

  @override
  String get logCost => 'Cost (optional)';

  @override
  String get logCostInvalid => 'Enter an amount like 120 or 120.50.';

  @override
  String get logCostNegative => 'Cost can\'t be negative.';

  @override
  String logCostDecimals(String currency, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count decimal places',
      one: '1 decimal place',
      zero: 'no decimals',
    );
    return '$currency uses $_temp0.';
  }

  @override
  String get logCurrency => 'Currency';

  @override
  String logCurrencyButton(String code) {
    return 'Currency: $code. Change';
  }

  @override
  String get logShop => 'Shop (optional)';

  @override
  String get logNotes => 'Notes (optional)';

  @override
  String get logSave => 'Save service';

  @override
  String get logDiscardTitle => 'Discard this service?';

  @override
  String logSaved(int score) {
    return 'Service saved · score now $score';
  }

  @override
  String logSavedKept(int count, String items) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved to history. $items keep their newer dates.',
      one: 'Saved to history. $items keeps its newer date.',
    );
    return '$_temp0';
  }

  @override
  String get addLogServiceSub => 'Record work done on your car';

  @override
  String get addAddVehicleSub => 'Add another car to your garage';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileGuestTitle => 'Your garage is only on this phone';

  @override
  String get profileGuestBody =>
      'If you delete the app or lose your phone, your data is gone.';

  @override
  String get profileBackUp => 'Back up your garage';

  @override
  String get profileSignIn => 'Sign in';

  @override
  String profileSyncedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synced $count min ago',
      one: 'Synced 1 min ago',
      zero: 'Synced just now',
    );
    return '$_temp0';
  }

  @override
  String profileSyncedAt(String date) {
    return 'Synced $date';
  }

  @override
  String profileWaitingSync(int count) {
    return 'Waiting to sync ($count)';
  }

  @override
  String get profileOffline => 'Offline';

  @override
  String get profileVerifyEmail => 'Verify your email to finish backing up';

  @override
  String get profileResendEmail => 'Resend email';

  @override
  String get profileVerificationSent => 'Verification email sent';

  @override
  String profileAccountSemantic(String name, String email, String sync) {
    return '$name, $email, $sync. Account details';
  }

  @override
  String get profileEnableReminders => 'Enable reminders';

  @override
  String get profileEnableRemindersBody =>
      'Get a reminder before something is due.';

  @override
  String get profileGarage => 'Garage';

  @override
  String get profileVehicles => 'Vehicles';

  @override
  String get profilePreferences => 'Preferences';

  @override
  String get profileCountry => 'Country';

  @override
  String get profileNotSet => 'Not set';

  @override
  String get profileDistanceUnit => 'Distance unit';

  @override
  String get profileKilometres => 'Kilometres';

  @override
  String get profileMiles => 'Miles';

  @override
  String get profileCurrency => 'Currency';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileDigits => 'Digits';

  @override
  String get profileDigitsWestern => 'Western 0-9';

  @override
  String get profileDigitsArabic => 'Arabic-Indic ٠-٩';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileReminders => 'Reminders';

  @override
  String get profileOn => 'On';

  @override
  String get profileOff => 'Off';

  @override
  String get profilePrivacy => 'Privacy';

  @override
  String get profileAnalytics => 'Usage analytics';

  @override
  String get profileAnalyticsSub => 'Anonymous. No advertising.';

  @override
  String get profilePrivacyPolicy => 'Privacy policy';

  @override
  String get profileTerms => 'Terms of use';

  @override
  String get profileHelp => 'Help';

  @override
  String get profileFaq => 'FAQ';

  @override
  String get profileContact => 'Contact support';

  @override
  String get profileSupportPromise =>
      'We reply within 2 business days (Sunday to Thursday, Cairo time)';

  @override
  String get profileAccountActions => 'Account';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileEraseData => 'Erase all data';

  @override
  String get profileSignOutTitle => 'Sign out?';

  @override
  String get profileSignOutBody =>
      'Your garage stays in your account. Sign in again any time to get it back.';

  @override
  String get profileUnsyncedTitle => 'Some changes haven\'t synced';

  @override
  String profileUnsyncedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes on this phone haven\'t reached your account yet.',
      one: '1 change on this phone hasn\'t reached your account yet.',
    );
    return '$_temp0';
  }

  @override
  String get profileSyncNow => 'Sync now';

  @override
  String get profileDiscardSignOut => 'Discard and sign out';

  @override
  String get profileSignedOut => 'Signed out';

  @override
  String profileVersion(String name, String version, String build) {
    return '$name $version ($build)';
  }

  @override
  String get profileSelectSetting => 'Choose a setting to see it here.';

  @override
  String profileValueSemantic(String title, String value) {
    return '$title, $value';
  }

  @override
  String get regionSwitchBothTitle => 'Also switch currency and units?';

  @override
  String get regionSwitchCurrencyTitle => 'Also switch currency?';

  @override
  String get regionSwitchUnitTitle => 'Also switch units?';

  @override
  String regionSwitchBoth(String currency, String unit) {
    return 'Switch currency to $currency and distance to $unit?';
  }

  @override
  String regionSwitchCurrency(String currency) {
    return 'Switch currency to $currency?';
  }

  @override
  String regionSwitchUnit(String unit) {
    return 'Switch distance to $unit?';
  }

  @override
  String get regionSwitch => 'Switch';

  @override
  String get regionKeep => 'Keep current';

  @override
  String regionPopularUpdated(String country) {
    return 'Popular brands updated for $country';
  }

  @override
  String get regionPopularDefault => 'Popular brands set to the default list';

  @override
  String get unitKmOption => 'Kilometres (km)';

  @override
  String get unitMiOption => 'Miles (mi)';

  @override
  String get unitCaption =>
      'Your readings are converted exactly. Nothing is lost when you switch.';

  @override
  String get currencyCaption =>
      'New records use this currency. Existing records keep theirs.';

  @override
  String get currencySuggested => 'Suggested';

  @override
  String get currencyAll => 'All currencies';

  @override
  String get currencySearchHint => 'Search currencies';

  @override
  String currencyNoResults(String query) {
    return 'No currencies match \"$query\"';
  }

  @override
  String get languageTitle => 'Language & digits';

  @override
  String languageDevice(String language) {
    return 'Same as device ($language)';
  }

  @override
  String get digitsWesternOption => 'Western (0 1 2 3)';

  @override
  String digitsArabicOption(String digits) {
    return 'Arabic-Indic ($digits)';
  }

  @override
  String get digitsCaption =>
      'VINs, plates and mileage always use Western digits.';

  @override
  String get notifOffInSettings =>
      'Notifications are off in your phone\'s Settings.';

  @override
  String get notifOpenSettings => 'Open Settings';

  @override
  String get notifNotAsked =>
      'Allow notifications so your reminders can reach you.';

  @override
  String get notifAllow => 'Allow';

  @override
  String get notifServiceReminders => 'Service reminders';

  @override
  String get notifServiceRemindersSub =>
      'Due soon, overdue and mileage reminders';

  @override
  String get notifSchedule =>
      'Reminders arrive at 9:00, 30, 7 and 1 day before something is due. Overdue reminders follow on days 1, 3, 7 and 14, and monthly for brakes, tires and brake fluid.';

  @override
  String get authBackupTitle => 'Back up and sync your garage';

  @override
  String get authWelcomeTitle => 'Welcome back';

  @override
  String get authBody =>
      'Use your account on any device. Your data stays private.';

  @override
  String get authApple => 'Continue with Apple';

  @override
  String get authGoogle => 'Continue with Google';

  @override
  String get authEmail => 'Continue with email';

  @override
  String get authTerms => 'Terms';

  @override
  String get authPrivacy => 'Privacy Policy';

  @override
  String get authEmailTitle => 'Your email';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailInvalid => 'Enter a valid email address.';

  @override
  String get authCreatePasswordTitle => 'Create a password';

  @override
  String get authEnterPasswordTitle => 'Enter your password';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authPasswordHint => 'At least 8 characters';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authForgot => 'Forgot password?';

  @override
  String get authWrongPassword => 'That password doesn\'t match.';

  @override
  String get authTooMany => 'Too many tries. Try again in 5 minutes.';

  @override
  String get authOffline => 'You need a connection to sign in.';

  @override
  String get authResetTitle => 'Reset your password';

  @override
  String authResetBody(String email) {
    return 'We\'ll email you a reset link at $email.';
  }

  @override
  String get authSendLink => 'Send link';

  @override
  String get authResetSentTitle => 'Check your inbox';

  @override
  String get authResetSentBody =>
      'Open the link in the email to choose a new password.';

  @override
  String get authVerifyTitle => 'Check your email to verify your account.';

  @override
  String authVerifyBody(String email) {
    return 'We sent a link to $email. Your garage stays on this phone until you verify.';
  }

  @override
  String get authResend => 'Resend';

  @override
  String authResendIn(int seconds) {
    return 'Resend in $seconds s';
  }

  @override
  String get authOpenMail => 'Open Mail app';

  @override
  String get authVerificationSent => 'Verification email sent';

  @override
  String get authSignedIn => 'Signed in';

  @override
  String get authLegal =>
      'By continuing you agree to the Terms and Privacy Policy.';

  @override
  String get backupBenefitHistory => 'Keep your history if you lose your phone';

  @override
  String get backupBenefitDevices => 'Use it on your iPad too';

  @override
  String get backupBenefitPrivate => 'Private to you. No advertising.';

  @override
  String get backupWarning => 'Right now your data is only on this phone.';

  @override
  String get backupNow => 'Back up now';

  @override
  String get backupNotNow => 'Not now';

  @override
  String backupVehicles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vehicles',
      one: '1 vehicle',
    );
    return '$_temp0';
  }

  @override
  String backupRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return '$_temp0';
  }

  @override
  String backupProgress(String vehicles, String records) {
    return 'Backing up $vehicles and $records…';
  }

  @override
  String backupPercent(String percent) {
    return '$percent%';
  }

  @override
  String get backupWaiting =>
      'Waiting for connection… Your data is safe on this phone.';

  @override
  String get backupFailedTitle => 'Backup didn\'t finish';

  @override
  String get backupFailedBody => 'Your data is still safe on this phone.';

  @override
  String get backupDoneTitle => 'Your garage is backed up';

  @override
  String get backupDone => 'Done';

  @override
  String get mergeTitle => 'This account already has a garage';

  @override
  String get mergeOption => 'Merge into this account';

  @override
  String mergeOptionBody(String device, String account) {
    return 'Adds this phone\'s $device to your account\'s $account.';
  }

  @override
  String get mergeRecommended => 'Recommended';

  @override
  String get discardOption => 'Discard this phone\'s data';

  @override
  String discardOptionBody(String device) {
    return 'Removes the $device on this phone and loads your account.';
  }

  @override
  String get discardDialogTitle => 'Discard this phone\'s data?';

  @override
  String discardDialogBody(String word) {
    return 'This can\'t be undone. Type $word to confirm.';
  }

  @override
  String get discardWord => 'DISCARD';

  @override
  String get discardConfirm => 'Discard';

  @override
  String get discardDone => 'This phone now shows your account\'s garage';

  @override
  String get limitTitle => 'Choose what to bring';

  @override
  String get limitBody =>
      'An account holds up to 25 vehicles. Vehicles you don\'t bring are removed from this phone.';

  @override
  String limitCounter(int allowed, int total) {
    return 'You can bring $allowed of $total';
  }

  @override
  String get dupTitle => 'These look like the same car';

  @override
  String get dupBody => 'Both are kept. Remove one if it\'s a duplicate.';

  @override
  String get dupRemove => 'Remove this phone\'s copy';

  @override
  String get dupOnPhone => 'On this phone';

  @override
  String get dupInAccount => 'In your account';

  @override
  String get eraseDeleteTitle => 'Delete account';

  @override
  String get eraseEraseTitle => 'Erase all data';

  @override
  String get eraseOwnerDevices =>
      'Your vehicles, history and settings are deleted from all devices.';

  @override
  String get eraseOwnerBackups => 'Backups are cleared within 30 days.';

  @override
  String get eraseOwnerFinal => 'This can\'t be undone.';

  @override
  String get eraseGuest => 'Everything on this phone is erased immediately.';

  @override
  String eraseTypeToConfirm(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get eraseDeleteWord => 'DELETE';

  @override
  String get eraseEraseWord => 'ERASE';

  @override
  String get eraseOffline => 'You need a connection to delete your account.';

  @override
  String get reauthTitle => 'Confirm it\'s you';

  @override
  String get reauthBody =>
      'For your security, sign in again before deleting your account.';

  @override
  String reauthAccount(String email) {
    return 'Signed in as $email';
  }

  @override
  String get reauthOr => 'or use your password';

  @override
  String get reauthConfirm => 'Confirm';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpSearch => 'Search help';

  @override
  String get helpTopics => 'Topics';

  @override
  String get helpCatGettingStarted => 'Getting started';

  @override
  String get helpCatHealthScore => 'Health score';

  @override
  String get helpCatReminders => 'Reminders';

  @override
  String get helpCatBackup => 'Backup & sync';

  @override
  String get helpCatPrivacy => 'Privacy';

  @override
  String helpQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String get helpOffline =>
      'Showing saved answers. Connect for the full help centre.';

  @override
  String helpResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count answers',
      one: '1 answer',
    );
    return '$_temp0';
  }

  @override
  String helpNoResults(String query) {
    return 'No answers for “$query”';
  }

  @override
  String get helpNoResultsHint => 'Try other words, or email us below.';

  @override
  String get helpContactTitle => 'Contact us';

  @override
  String get helpContactLanguage => 'We reply in the language you write in.';

  @override
  String get helpEmailSubject => 'TDC-mena Garage support';

  @override
  String get helpEmailCopied => 'Email address copied';

  @override
  String get helpEmailHint => 'Opens your email app';

  @override
  String get helpLegal => 'Legal';

  @override
  String get helpStillNeed => 'Still need help?';

  @override
  String legalLoadsFrom(String address) {
    return 'This page loads from $address in the in-app browser.';
  }

  @override
  String get editVehicleTitle => 'Edit vehicle';

  @override
  String get editBrand => 'Brand';

  @override
  String get editModel => 'Model';

  @override
  String get editSaved => 'Changes saved';

  @override
  String get editDeleteVehicle => 'Delete vehicle';

  @override
  String editOdometerLower(String mileage) {
    return 'Can\'t be lower than the last reading ($mileage). Correct it in Mileage history.';
  }

  @override
  String fuelChangeTitle(String fuel) {
    return 'Update the schedule for $fuel?';
  }

  @override
  String get fuelChangeBody =>
      'We\'ll replace the typical items. Your custom items and history stay.';

  @override
  String get fuelChangeUpdate => 'Update schedule';

  @override
  String get fuelChangeKeep => 'Keep current schedule';

  @override
  String get fuelChangeKeepIntervals => 'Keep my edited intervals';

  @override
  String deleteVehicleBodyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This deletes its schedule and $count service records. This can\'t be undone.',
      one: 'This deletes its schedule and 1 service record. This can\'t be undone.',
      zero: 'This deletes its schedule. This can\'t be undone.',
    );
    return '$_temp0';
  }

  @override
  String get alertMileageReview => 'Check a mileage reading';

  @override
  String get reviewTitle => 'Check this reading';

  @override
  String get reviewBody =>
      'A reading from your other device is lower than an earlier one.';

  @override
  String get reviewNeedsReview => 'Needs review';

  @override
  String get reviewThisDevice => 'This device';

  @override
  String reviewUseCorrection(String value) {
    return 'Use $value as a correction';
  }

  @override
  String reviewDelete(String value) {
    return 'Delete $value';
  }

  @override
  String get reviewCorrected => 'Saved as a correction';

  @override
  String reviewCardSemantic(String value, String date, String device) {
    return '$value, $date, $device';
  }

  @override
  String get offlineTitle => 'You\'re offline';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get actionRetryShort => 'Retry';

  @override
  String get loading => 'Loading';

  @override
  String get syncSyncing => 'Syncing';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String get syncOffline =>
      'Offline. Changes will sync when you\'re back online.';

  @override
  String get syncNeedsReview => 'A mileage reading needs review';

  @override
  String get updateTitle => 'Update required';

  @override
  String get updateBody => 'This version is no longer supported.';

  @override
  String get updateSafe => 'Your data on this phone is safe.';

  @override
  String get updateAction => 'Update';

  @override
  String notifDays(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n days',
      one: '$n day',
    );
    return '$_temp0';
  }

  @override
  String notifDueIn(String item, String days) {
    return '$item due in $days';
  }

  @override
  String notifDueTomorrow(String item) {
    return '$item due tomorrow';
  }

  @override
  String notifOverdue(String item, String days) {
    return '$item overdue by $days';
  }

  @override
  String notifBundle(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n items need attention',
    );
    return '$_temp0';
  }

  @override
  String get notifMileageTitle => 'Update your mileage';

  @override
  String notifMileageBody(String days, String seconds) {
    return 'It\'s been $days. It takes $seconds seconds.';
  }
}
