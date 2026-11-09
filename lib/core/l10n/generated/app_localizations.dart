import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Product name. Stays in Latin script in every language.
  ///
  /// In en, this message translates to:
  /// **'TDC-mena Garage'**
  String get appName;

  /// Screen reader label for the launch screen while data loads.
  ///
  /// In en, this message translates to:
  /// **'TDC-mena Garage is loading'**
  String get launchLoadingLabel;

  /// No description provided for @launchErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open your garage'**
  String get launchErrorTitle;

  /// No description provided for @launchErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while loading your data. Your data is safe on this phone.'**
  String get launchErrorBody;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// Button that switches the app to the OTHER language, written in that language.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageSwitchLabel;

  /// No description provided for @languageSwitchSemantic.
  ///
  /// In en, this message translates to:
  /// **'Switch the app to Arabic'**
  String get languageSwitchSemantic;

  /// No description provided for @introSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get introSkip;

  /// No description provided for @introNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get introNext;

  /// No description provided for @introGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get introGetStarted;

  /// No description provided for @introSignIn.
  ///
  /// In en, this message translates to:
  /// **'I already have an account · Sign in'**
  String get introSignIn;

  /// No description provided for @introPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String introPageLabel(int current, int total);

  /// No description provided for @introPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Your car\'s health at a glance'**
  String get introPage1Title;

  /// No description provided for @introPage1Body.
  ///
  /// In en, this message translates to:
  /// **'See what needs attention before it becomes a repair bill.'**
  String get introPage1Body;

  /// No description provided for @introPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Never miss a service'**
  String get introPage2Title;

  /// No description provided for @introPage2Body.
  ///
  /// In en, this message translates to:
  /// **'Reminders before oil, brakes and tires are due, based on typical intervals.'**
  String get introPage2Body;

  /// No description provided for @introPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Start now, no account needed'**
  String get introPage3Title;

  /// No description provided for @introPage3Body.
  ///
  /// In en, this message translates to:
  /// **'Your garage stays on this phone. Back it up whenever you like.'**
  String get introPage3Body;

  /// No description provided for @healthScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Health score'**
  String get healthScoreLabel;

  /// No description provided for @healthBandGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get healthBandGood;

  /// No description provided for @statMileage.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get statMileage;

  /// No description provided for @statMileageSub.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statMileageSub;

  /// No description provided for @statNextService.
  ///
  /// In en, this message translates to:
  /// **'Next service'**
  String get statNextService;

  /// No description provided for @statNextServiceSub.
  ///
  /// In en, this message translates to:
  /// **'Days away'**
  String get statNextServiceSub;

  /// No description provided for @statThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get statThisYear;

  /// No description provided for @statThisYearSub.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get statThisYearSub;

  /// No description provided for @unitKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKm;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get actionClearSearch;

  /// No description provided for @stateSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get stateSelected;

  /// No description provided for @stepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}: {name}'**
  String stepLabel(int current, int total, String name);

  /// No description provided for @stepCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get stepCountry;

  /// No description provided for @stepBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get stepBrand;

  /// No description provided for @stepCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get stepCar;

  /// No description provided for @stepService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get stepService;

  /// No description provided for @unitMi.
  ///
  /// In en, this message translates to:
  /// **'mi'**
  String get unitMi;

  /// No description provided for @countryTitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you drive?'**
  String get countryTitle;

  /// No description provided for @countryBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll set your currency, distance unit and popular brands. You can change these any time.'**
  String get countryBody;

  /// No description provided for @countryCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryCardLabel;

  /// No description provided for @countryChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get countryChange;

  /// No description provided for @countryNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get countryNotSet;

  /// No description provided for @countryOther.
  ///
  /// In en, this message translates to:
  /// **'Other / not set'**
  String get countryOther;

  /// No description provided for @countryOtherHint.
  ///
  /// In en, this message translates to:
  /// **'USD, km and the most popular brands'**
  String get countryOtherHint;

  /// No description provided for @popularListStandard.
  ///
  /// In en, this message translates to:
  /// **'Popular brands'**
  String get popularListStandard;

  /// No description provided for @popularListGulf.
  ///
  /// In en, this message translates to:
  /// **'Gulf brands'**
  String get popularListGulf;

  /// No description provided for @popularListEgypt.
  ///
  /// In en, this message translates to:
  /// **'Egypt brands'**
  String get popularListEgypt;

  /// No description provided for @countryPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your country'**
  String get countryPickerTitle;

  /// No description provided for @countrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search country…'**
  String get countrySearchHint;

  /// No description provided for @countryNoResults.
  ///
  /// In en, this message translates to:
  /// **'No countries found'**
  String get countryNoResults;

  /// No description provided for @countryNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try another spelling, or choose Other / not set.'**
  String get countryNoResultsHint;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Help us improve the app'**
  String get consentTitle;

  /// No description provided for @consentBody.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous usage data. No advertising, no tracking across apps.'**
  String get consentBody;

  /// No description provided for @consentAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get consentAllow;

  /// No description provided for @consentDeny.
  ///
  /// In en, this message translates to:
  /// **'Don\'t allow'**
  String get consentDeny;

  /// No description provided for @consentRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Choose Allow or Don\'t allow to continue.'**
  String get consentRequiredHint;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// Large decorative title on brand selection. Arabic copy to be confirmed by the reviewer.
  ///
  /// In en, this message translates to:
  /// **'Garage'**
  String get garageTitle;

  /// No description provided for @brandPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select your car brand'**
  String get brandPrompt;

  /// No description provided for @brandScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Select your car brand'**
  String get brandScreenTitle;

  /// No description provided for @brandSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search brand…'**
  String get brandSearchHint;

  /// No description provided for @brandSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get brandSelect;

  /// No description provided for @brandOther.
  ///
  /// In en, this message translates to:
  /// **'Other brand'**
  String get brandOther;

  /// No description provided for @brandOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Type your brand'**
  String get brandOtherHint;

  /// No description provided for @brandOtherFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand name'**
  String get brandOtherFieldLabel;

  /// No description provided for @brandContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Continue with {brand}'**
  String brandContinueWith(String brand);

  /// No description provided for @brandNoResults.
  ///
  /// In en, this message translates to:
  /// **'No brands found'**
  String get brandNoResults;

  /// No description provided for @brandFoundInTabs.
  ///
  /// In en, this message translates to:
  /// **'Found in other tabs:'**
  String get brandFoundInTabs;

  /// No description provided for @brandAddAsOther.
  ///
  /// In en, this message translates to:
  /// **'Add “{name}” as other brand'**
  String brandAddAsOther(String name);

  /// No description provided for @tabPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get tabPopular;

  /// No description provided for @tabEuropean.
  ///
  /// In en, this message translates to:
  /// **'European'**
  String get tabEuropean;

  /// No description provided for @tabJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get tabJapanese;

  /// No description provided for @tabKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get tabKorean;

  /// No description provided for @tabChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get tabChinese;

  /// No description provided for @tabAmerican.
  ///
  /// In en, this message translates to:
  /// **'American'**
  String get tabAmerican;

  /// No description provided for @tabSemantic.
  ///
  /// In en, this message translates to:
  /// **'{name}, tab {index} of {count}'**
  String tabSemantic(String name, int index, int count);

  /// No description provided for @discardVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this vehicle?'**
  String get discardVehicleTitle;

  /// No description provided for @discardVehicleBody.
  ///
  /// In en, this message translates to:
  /// **'The brand you chose won\'t be saved.'**
  String get discardVehicleBody;

  /// No description provided for @actionDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get actionDiscard;

  /// No description provided for @actionKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get actionKeepEditing;

  /// No description provided for @modelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your model'**
  String get modelSubtitle;

  /// No description provided for @modelOther.
  ///
  /// In en, this message translates to:
  /// **'Other model'**
  String get modelOther;

  /// No description provided for @modelOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Type your model'**
  String get modelOtherHint;

  /// No description provided for @modelNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Model name'**
  String get modelNameLabel;

  /// No description provided for @bodyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Body type'**
  String get bodyTypeLabel;

  /// No description provided for @bodyTypeHelper.
  ///
  /// In en, this message translates to:
  /// **'Picks the illustration for your car.'**
  String get bodyTypeHelper;

  /// No description provided for @bodySedan.
  ///
  /// In en, this message translates to:
  /// **'Sedan'**
  String get bodySedan;

  /// No description provided for @bodyHatchback.
  ///
  /// In en, this message translates to:
  /// **'Hatchback'**
  String get bodyHatchback;

  /// No description provided for @bodySuv.
  ///
  /// In en, this message translates to:
  /// **'SUV'**
  String get bodySuv;

  /// No description provided for @bodyCoupe.
  ///
  /// In en, this message translates to:
  /// **'Coupe'**
  String get bodyCoupe;

  /// No description provided for @bodyWagon.
  ///
  /// In en, this message translates to:
  /// **'Wagon'**
  String get bodyWagon;

  /// No description provided for @bodyPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get bodyPickup;

  /// No description provided for @bodyVan.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get bodyVan;

  /// No description provided for @usuallyPetrol.
  ///
  /// In en, this message translates to:
  /// **'Usually petrol'**
  String get usuallyPetrol;

  /// No description provided for @usuallyDiesel.
  ///
  /// In en, this message translates to:
  /// **'Usually diesel'**
  String get usuallyDiesel;

  /// No description provided for @usuallyHybrid.
  ///
  /// In en, this message translates to:
  /// **'Usually hybrid'**
  String get usuallyHybrid;

  /// No description provided for @usuallyEv.
  ///
  /// In en, this message translates to:
  /// **'Usually electric'**
  String get usuallyEv;

  /// No description provided for @modelsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Model list for this brand is coming soon.'**
  String get modelsComingSoon;

  /// No description provided for @modelNeedBrandTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a brand first'**
  String get modelNeedBrandTitle;

  /// No description provided for @modelNeedBrandBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find the brand for this car.'**
  String get modelNeedBrandBody;

  /// No description provided for @modelNeedBrandAction.
  ///
  /// In en, this message translates to:
  /// **'Choose brand'**
  String get modelNeedBrandAction;

  /// No description provided for @positionOf.
  ///
  /// In en, this message translates to:
  /// **'{index} of {count}'**
  String positionOf(int index, int count);

  /// No description provided for @detailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your car'**
  String get detailsSubtitle;

  /// No description provided for @fuelTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fuel type'**
  String get fuelTypeLabel;

  /// No description provided for @fuelTypeHelper.
  ///
  /// In en, this message translates to:
  /// **'Sets your maintenance schedule.'**
  String get fuelTypeHelper;

  /// No description provided for @fuelPetrol.
  ///
  /// In en, this message translates to:
  /// **'Petrol'**
  String get fuelPetrol;

  /// No description provided for @fuelDiesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get fuelDiesel;

  /// No description provided for @fuelHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get fuelHybrid;

  /// No description provided for @fuelEv.
  ///
  /// In en, this message translates to:
  /// **'EV'**
  String get fuelEv;

  /// No description provided for @odometerLabel.
  ///
  /// In en, this message translates to:
  /// **'Current odometer'**
  String get odometerLabel;

  /// No description provided for @odometerHelper.
  ///
  /// In en, this message translates to:
  /// **'Check your dashboard.'**
  String get odometerHelper;

  /// No description provided for @odometerMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter your current mileage'**
  String get odometerMissing;

  /// No description provided for @odometerNotNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter numbers only'**
  String get odometerNotNumber;

  /// No description provided for @odometerTooHigh.
  ///
  /// In en, this message translates to:
  /// **'That looks too high. Check the number.'**
  String get odometerTooHigh;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @paintColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Paint colour'**
  String get paintColorLabel;

  /// No description provided for @paintObsidianBlack.
  ///
  /// In en, this message translates to:
  /// **'Obsidian Black'**
  String get paintObsidianBlack;

  /// No description provided for @paintPolarWhite.
  ///
  /// In en, this message translates to:
  /// **'Polar White'**
  String get paintPolarWhite;

  /// No description provided for @paintSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get paintSilver;

  /// No description provided for @paintGunmetalGrey.
  ///
  /// In en, this message translates to:
  /// **'Gunmetal Grey'**
  String get paintGunmetalGrey;

  /// No description provided for @paintDesertSand.
  ///
  /// In en, this message translates to:
  /// **'Desert Sand'**
  String get paintDesertSand;

  /// No description provided for @paintChampagne.
  ///
  /// In en, this message translates to:
  /// **'Champagne'**
  String get paintChampagne;

  /// No description provided for @paintMidnightBlue.
  ///
  /// In en, this message translates to:
  /// **'Midnight Blue'**
  String get paintMidnightBlue;

  /// No description provided for @paintSkyBlue.
  ///
  /// In en, this message translates to:
  /// **'Sky Blue'**
  String get paintSkyBlue;

  /// No description provided for @paintRacingRed.
  ///
  /// In en, this message translates to:
  /// **'Racing Red'**
  String get paintRacingRed;

  /// No description provided for @paintSunsetOrange.
  ///
  /// In en, this message translates to:
  /// **'Sunset Orange'**
  String get paintSunsetOrange;

  /// No description provided for @paintForestGreen.
  ///
  /// In en, this message translates to:
  /// **'Forest Green'**
  String get paintForestGreen;

  /// No description provided for @paintBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get paintBronze;

  /// No description provided for @moreDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add nickname, year, VIN and more'**
  String get moreDetailsTitle;

  /// No description provided for @moreDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get moreDetailsOptional;

  /// No description provided for @nicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nicknameLabel;

  /// No description provided for @yearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearLabel;

  /// No description provided for @plateLabel.
  ///
  /// In en, this message translates to:
  /// **'Licence plate'**
  String get plateLabel;

  /// No description provided for @vinLabel.
  ///
  /// In en, this message translates to:
  /// **'VIN'**
  String get vinLabel;

  /// No description provided for @purchaseDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get purchaseDateLabel;

  /// No description provided for @vinLengthWarning.
  ///
  /// In en, this message translates to:
  /// **'VINs are usually 17 characters. Keep it if your car is older than 1981.'**
  String get vinLengthWarning;

  /// No description provided for @vinInvalid.
  ///
  /// In en, this message translates to:
  /// **'VINs don\'t use the letters I, O or Q.'**
  String get vinInvalid;

  /// No description provided for @duplicateVinTitle.
  ///
  /// In en, this message translates to:
  /// **'You already have a car with this VIN'**
  String get duplicateVinTitle;

  /// No description provided for @duplicateVinBody.
  ///
  /// In en, this message translates to:
  /// **'{name} has the same VIN. Add anyway?'**
  String duplicateVinBody(String name);

  /// No description provided for @duplicateVinAdd.
  ///
  /// In en, this message translates to:
  /// **'Add anyway'**
  String get duplicateVinAdd;

  /// No description provided for @duplicateVinChange.
  ///
  /// In en, this message translates to:
  /// **'Change VIN'**
  String get duplicateVinChange;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get dateClear;

  /// No description provided for @dateDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dateDone;

  /// No description provided for @detailsNeedModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a model first'**
  String get detailsNeedModelTitle;

  /// No description provided for @detailsNeedModelBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find the model for this car.'**
  String get detailsNeedModelBody;

  /// No description provided for @duplicateVinUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Another car in your garage'**
  String get duplicateVinUnnamed;

  /// No description provided for @baselineTitle.
  ///
  /// In en, this message translates to:
  /// **'When were these last done?'**
  String get baselineTitle;

  /// No description provided for @baselineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This makes your health score accurate. Skip anything you don\'t know.'**
  String get baselineSubtitle;

  /// No description provided for @newCarTitle.
  ///
  /// In en, this message translates to:
  /// **'My car is new'**
  String get newCarTitle;

  /// No description provided for @newCarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delivered recently? We\'ll start everything fresh.'**
  String get newCarSubtitle;

  /// No description provided for @deliveryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery date'**
  String get deliveryDateLabel;

  /// No description provided for @startingMileageLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting mileage'**
  String get startingMileageLabel;

  /// No description provided for @newCarNote.
  ///
  /// In en, this message translates to:
  /// **'All items start from your delivery date. Your score starts at 100.'**
  String get newCarNote;

  /// No description provided for @baselineOilService.
  ///
  /// In en, this message translates to:
  /// **'Oil change or service'**
  String get baselineOilService;

  /// No description provided for @baselineBrakes.
  ///
  /// In en, this message translates to:
  /// **'Brakes'**
  String get baselineBrakes;

  /// No description provided for @baselineTires.
  ///
  /// In en, this message translates to:
  /// **'Tires'**
  String get baselineTires;

  /// No description provided for @baselineBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get baselineBattery;

  /// No description provided for @baselineDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get baselineDateLabel;

  /// No description provided for @baselineMileageLabel.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get baselineMileageLabel;

  /// No description provided for @baselineDontKnow.
  ///
  /// In en, this message translates to:
  /// **'I don\'t know'**
  String get baselineDontKnow;

  /// No description provided for @baselineUnknownBadge.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get baselineUnknownBadge;

  /// No description provided for @baselineFooter.
  ///
  /// In en, this message translates to:
  /// **'Other items like filters and coolant start as Unknown. You can set them later in your schedule.'**
  String get baselineFooter;

  /// No description provided for @actionSaveVehicle.
  ///
  /// In en, this message translates to:
  /// **'Save vehicle'**
  String get actionSaveVehicle;

  /// No description provided for @baselineKmAboveOdometer.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be more than your current mileage ({mileage}).'**
  String baselineKmAboveOdometer(String mileage);

  /// No description provided for @baselineCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'{item}, last done'**
  String baselineCardSemantic(String item);

  /// No description provided for @baselineUnknownAnnounce.
  ///
  /// In en, this message translates to:
  /// **'{item} marked as unknown'**
  String baselineUnknownAnnounce(String item);

  /// No description provided for @baselineKnownAnnounce.
  ///
  /// In en, this message translates to:
  /// **'{item} can be filled in again'**
  String baselineKnownAnnounce(String item);

  /// No description provided for @deliveryOldTitle.
  ///
  /// In en, this message translates to:
  /// **'Some items may already be due'**
  String get deliveryOldTitle;

  /// No description provided for @deliveryOldBody.
  ///
  /// In en, this message translates to:
  /// **'Your delivery date is {age}. Items with shorter intervals will show as due or overdue.'**
  String deliveryOldBody(String age);

  /// No description provided for @deliveryOldBodyDistance.
  ///
  /// In en, this message translates to:
  /// **'Your car has been driven past some intervals since delivery. Those items will show as due or overdue.'**
  String get deliveryOldBodyDistance;

  /// No description provided for @deliveryAgeYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago} other{{count} years ago}}'**
  String deliveryAgeYears(int count);

  /// No description provided for @deliveryAgeMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String deliveryAgeMonths(int count);

  /// No description provided for @deliveryKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep this date'**
  String get deliveryKeep;

  /// No description provided for @deliveryChange.
  ///
  /// In en, this message translates to:
  /// **'Change date'**
  String get deliveryChange;

  /// No description provided for @deliveryDateMissing.
  ///
  /// In en, this message translates to:
  /// **'Choose your delivery date'**
  String get deliveryDateMissing;

  /// No description provided for @baselineNeedDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your car\'s details first'**
  String get baselineNeedDetailsTitle;

  /// No description provided for @baselineNeedDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find the details for this car.'**
  String get baselineNeedDetailsBody;

  /// No description provided for @primerTitle.
  ///
  /// In en, this message translates to:
  /// **'Never miss a service'**
  String get primerTitle;

  /// No description provided for @primerBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll remind you 30, 7 and 1 day before something is due, at 9:00. You can turn this off any time.'**
  String get primerBody;

  /// No description provided for @primerDeniedHint.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for TDC Garage. Turn them on in Settings.'**
  String get primerDeniedHint;

  /// No description provided for @primerTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on reminders'**
  String get primerTurnOn;

  /// No description provided for @primerOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get primerOpenSettings;

  /// No description provided for @primerNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get primerNotNow;

  /// No description provided for @primerPreviewApp.
  ///
  /// In en, this message translates to:
  /// **'TDC Garage'**
  String get primerPreviewApp;

  /// No description provided for @primerPreviewTime.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get primerPreviewTime;

  /// No description provided for @primerPreviewText.
  ///
  /// In en, this message translates to:
  /// **'{vehicle} · {item} due in 7 days'**
  String primerPreviewText(String vehicle, String item);

  /// No description provided for @primerPreviewSemantic.
  ///
  /// In en, this message translates to:
  /// **'Example notification: {text}'**
  String primerPreviewSemantic(String text);

  /// No description provided for @primerPillExample.
  ///
  /// In en, this message translates to:
  /// **'Due in 7 days'**
  String get primerPillExample;

  /// No description provided for @remindersOnToast.
  ///
  /// In en, this message translates to:
  /// **'Reminders are on'**
  String get remindersOnToast;

  /// No description provided for @primerPreviewFallbackItem.
  ///
  /// In en, this message translates to:
  /// **'Oil change'**
  String get primerPreviewFallbackItem;

  /// No description provided for @navGarage.
  ///
  /// In en, this message translates to:
  /// **'Garage'**
  String get navGarage;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get navAdd;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @dashboardSwitchVehicle.
  ///
  /// In en, this message translates to:
  /// **'{name}, switch vehicle'**
  String dashboardSwitchVehicle(String name);

  /// No description provided for @dashboardModelYear.
  ///
  /// In en, this message translates to:
  /// **'{model} · {year}'**
  String dashboardModelYear(String model, String year);

  /// No description provided for @dashboardVehicleDots.
  ///
  /// In en, this message translates to:
  /// **'Vehicle {index} of {count}'**
  String dashboardVehicleDots(int index, int count);

  /// No description provided for @actionMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get actionMoreOptions;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @menuSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get menuSchedule;

  /// No description provided for @menuMileageHistory.
  ///
  /// In en, this message translates to:
  /// **'Mileage history'**
  String get menuMileageHistory;

  /// No description provided for @menuEditVehicle.
  ///
  /// In en, this message translates to:
  /// **'Edit vehicle'**
  String get menuEditVehicle;

  /// No description provided for @menuDeleteVehicle.
  ///
  /// In en, this message translates to:
  /// **'Delete vehicle'**
  String get menuDeleteVehicle;

  /// No description provided for @deleteVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteVehicleTitle(String name);

  /// No description provided for @deleteVehicleBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes its schedule, service history and reminders. This can\'t be undone.'**
  String get deleteVehicleBody;

  /// No description provided for @deleteVehicleDone.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String deleteVehicleDone(String name);

  /// No description provided for @bandExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get bandExcellent;

  /// No description provided for @bandGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get bandGood;

  /// No description provided for @bandNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get bandNeedsAttention;

  /// No description provided for @bandUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get bandUrgent;

  /// No description provided for @healthBasedOnTypical.
  ///
  /// In en, this message translates to:
  /// **'Based on typical intervals · {count} unknown'**
  String healthBasedOnTypical(int count);

  /// No description provided for @healthSemantic.
  ///
  /// In en, this message translates to:
  /// **'Health score {score} percent, {band}'**
  String healthSemantic(int score, String band);

  /// No description provided for @statUpdated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Updated today} =1{Updated yesterday} other{Updated {count} days ago}}'**
  String statUpdated(int count);

  /// No description provided for @statDaysAway.
  ///
  /// In en, this message translates to:
  /// **'Days away'**
  String get statDaysAway;

  /// No description provided for @statDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get statDue;

  /// No description provided for @statToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statToday;

  /// No description provided for @statDaysOverdue.
  ///
  /// In en, this message translates to:
  /// **'Days overdue'**
  String get statDaysOverdue;

  /// No description provided for @statSetUpSchedule.
  ///
  /// In en, this message translates to:
  /// **'Set up your schedule'**
  String get statSetUpSchedule;

  /// No description provided for @statDistanceToGo.
  ///
  /// In en, this message translates to:
  /// **'{unit} to go'**
  String statDistanceToGo(String unit);

  /// No description provided for @statItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String statItems(int count);

  /// No description provided for @statDateItems.
  ///
  /// In en, this message translates to:
  /// **'{date} · {items}'**
  String statDateItems(String date, String items);

  /// No description provided for @statSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get statSpent;

  /// No description provided for @statServices.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No costs yet} =1{1 service} other{{count} services}}'**
  String statServices(int count);

  /// No description provided for @statSomeNotIncluded.
  ///
  /// In en, this message translates to:
  /// **'Some records not included'**
  String get statSomeNotIncluded;

  /// No description provided for @statCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'{label}, {value} {sublabel}, {footer}'**
  String statCardSemantic(
    String label,
    String value,
    String sublabel,
    String footer,
  );

  /// No description provided for @statCarouselLabel.
  ///
  /// In en, this message translates to:
  /// **'Stat cards'**
  String get statCarouselLabel;

  /// No description provided for @statCarouselHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe up or down to change'**
  String get statCarouselHint;

  /// No description provided for @unitKmWord.
  ///
  /// In en, this message translates to:
  /// **'kilometres'**
  String get unitKmWord;

  /// No description provided for @unitMiWord.
  ///
  /// In en, this message translates to:
  /// **'miles'**
  String get unitMiWord;

  /// No description provided for @alertOverdueOne.
  ///
  /// In en, this message translates to:
  /// **'{item} overdue'**
  String alertOverdueOne(String item);

  /// No description provided for @alertOverdueMany.
  ///
  /// In en, this message translates to:
  /// **'{count} items overdue'**
  String alertOverdueMany(int count);

  /// No description provided for @alertDueSoon.
  ///
  /// In en, this message translates to:
  /// **'{item} due soon'**
  String alertDueSoon(String item);

  /// No description provided for @alertUnknown.
  ///
  /// In en, this message translates to:
  /// **'Complete your schedule · {count} unknown'**
  String alertUnknown(int count);

  /// No description provided for @alertStaleMileage.
  ///
  /// In en, this message translates to:
  /// **'Update your mileage · {count} days'**
  String alertStaleMileage(int count);

  /// No description provided for @alertAllGood.
  ///
  /// In en, this message translates to:
  /// **'All good'**
  String get alertAllGood;

  /// No description provided for @upcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingTitle;

  /// No description provided for @upcomingInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Due today} =1{In 1 day} other{In {count} days}}'**
  String upcomingInDays(int count);

  /// No description provided for @upcomingOverdueDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Overdue} =1{Overdue by 1 day} other{Overdue by {count} days}}'**
  String upcomingOverdueDays(int count);

  /// No description provided for @upcomingInDistance.
  ///
  /// In en, this message translates to:
  /// **'In {distance}'**
  String upcomingInDistance(String distance);

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @statusDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get statusDueSoon;

  /// No description provided for @statusOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get statusOk;

  /// No description provided for @switcherTitle.
  ///
  /// In en, this message translates to:
  /// **'Your garage'**
  String get switcherTitle;

  /// No description provided for @switcherCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} vehicles'**
  String switcherCount(int count, int max);

  /// No description provided for @switcherAddVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add vehicle'**
  String get switcherAddVehicle;

  /// No description provided for @switcherLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Limit reached. Contact support.'**
  String get switcherLimitReached;

  /// No description provided for @switcherManage.
  ///
  /// In en, this message translates to:
  /// **'Manage vehicles'**
  String get switcherManage;

  /// No description provided for @switcherOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String switcherOverdue(int count);

  /// No description provided for @switcherNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Not set up'**
  String get switcherNotSetUp;

  /// No description provided for @switcherCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current vehicle'**
  String get switcherCurrent;

  /// No description provided for @switcherRowSemantic.
  ///
  /// In en, this message translates to:
  /// **'{name}, {subline}, {status}'**
  String switcherRowSemantic(String name, String subline, String status);

  /// No description provided for @healthSummaryOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item is overdue} other{{count} items are overdue}}'**
  String healthSummaryOverdue(int count);

  /// No description provided for @healthSummarySoon.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item is due within 30 days} other{{count} items are due within 30 days}}'**
  String healthSummarySoon(int count);

  /// No description provided for @healthSummaryJoin.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}.'**
  String healthSummaryJoin(String first, String second);

  /// No description provided for @healthSummarySentence.
  ///
  /// In en, this message translates to:
  /// **'{text}.'**
  String healthSummarySentence(String text);

  /// No description provided for @healthNothingLowering.
  ///
  /// In en, this message translates to:
  /// **'Nothing is lowering your score'**
  String get healthNothingLowering;

  /// No description provided for @healthSectionLowering.
  ///
  /// In en, this message translates to:
  /// **'Lowering your score'**
  String get healthSectionLowering;

  /// No description provided for @healthReasonOverdueKm.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {distance}'**
  String healthReasonOverdueKm(String distance);

  /// No description provided for @healthReasonDueInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Due today} =1{Due in 1 day} other{Due in {count} days}}'**
  String healthReasonDueInDays(int count);

  /// No description provided for @healthReasonDueInKm.
  ///
  /// In en, this message translates to:
  /// **'Due in about {distance}'**
  String healthReasonDueInKm(String distance);

  /// No description provided for @healthDoubleBadge.
  ///
  /// In en, this message translates to:
  /// **'×2'**
  String get healthDoubleBadge;

  /// No description provided for @healthRowSemantic.
  ///
  /// In en, this message translates to:
  /// **'{item}, {reason}, minus {points} points'**
  String healthRowSemantic(String item, String reason, int points);

  /// No description provided for @healthCountsDouble.
  ///
  /// In en, this message translates to:
  /// **'counts double'**
  String get healthCountsDouble;

  /// No description provided for @healthSectionNotCounted.
  ///
  /// In en, this message translates to:
  /// **'Not counted'**
  String get healthSectionNotCounted;

  /// No description provided for @healthUnknownSetLastDone.
  ///
  /// In en, this message translates to:
  /// **'Unknown: set last done'**
  String get healthUnknownSetLastDone;

  /// No description provided for @healthSnoozedUntil.
  ///
  /// In en, this message translates to:
  /// **'Snoozed until {date}'**
  String healthSnoozedUntil(String date);

  /// No description provided for @healthHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How the score works'**
  String get healthHowTitle;

  /// No description provided for @healthHowBody.
  ///
  /// In en, this message translates to:
  /// **'Your score starts at 100. Overdue items lose 5 to 15 points depending on how important they are, and items due within 30 days lose 2. Items more than 30 days or 1,000 km overdue count double.'**
  String get healthHowBody;

  /// No description provided for @healthTemplateLine.
  ///
  /// In en, this message translates to:
  /// **'Typical intervals for {fuel} · template v{version}'**
  String healthTemplateLine(String fuel, int version);

  /// No description provided for @healthSeeSchedule.
  ///
  /// In en, this message translates to:
  /// **'See your schedule'**
  String get healthSeeSchedule;

  /// No description provided for @mileageTitle.
  ///
  /// In en, this message translates to:
  /// **'Update mileage'**
  String get mileageTitle;

  /// No description provided for @mileageLast.
  ///
  /// In en, this message translates to:
  /// **'Last: {reading} · {date}'**
  String mileageLast(String reading, String date);

  /// No description provided for @mileageFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'New odometer reading in {unit}'**
  String mileageFieldLabel(String unit);

  /// No description provided for @mileageChooseVehicle.
  ///
  /// In en, this message translates to:
  /// **'Choose vehicle'**
  String get mileageChooseVehicle;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @mileageViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get mileageViewHistory;

  /// No description provided for @mileageLowerTitle.
  ///
  /// In en, this message translates to:
  /// **'This is lower than your last reading'**
  String get mileageLowerTitle;

  /// No description provided for @mileageLowerBody.
  ///
  /// In en, this message translates to:
  /// **'Your last reading was {last} on {date}. Save {value} as a correction?'**
  String mileageLowerBody(String last, String date, String value);

  /// No description provided for @mileageSaveCorrection.
  ///
  /// In en, this message translates to:
  /// **'Save as correction'**
  String get mileageSaveCorrection;

  /// No description provided for @mileageJumpTitle.
  ///
  /// In en, this message translates to:
  /// **'Is this correct?'**
  String get mileageJumpTitle;

  /// No description provided for @mileageJumpBody.
  ///
  /// In en, this message translates to:
  /// **'That\'s {distance} in {period}.'**
  String mileageJumpBody(String distance, String period);

  /// No description provided for @mileageDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String mileageDays(int count);

  /// No description provided for @mileageJumpConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, save'**
  String get mileageJumpConfirm;

  /// No description provided for @mileageUpdatedToast.
  ///
  /// In en, this message translates to:
  /// **'Mileage updated'**
  String get mileageUpdatedToast;

  /// No description provided for @mileageAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get mileageAverageLabel;

  /// No description provided for @mileageAveragePerMonth.
  ///
  /// In en, this message translates to:
  /// **'{distance} / month'**
  String mileageAveragePerMonth(String distance);

  /// No description provided for @mileageAverageBasis.
  ///
  /// In en, this message translates to:
  /// **'Based on the last 180 days'**
  String get mileageAverageBasis;

  /// No description provided for @mileageAverageNeedMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Add another reading to see your average.} =1{Add another reading tomorrow to see your average.} other{Add another reading in {count} days to see your average.}}'**
  String mileageAverageNeedMore(int count);

  /// No description provided for @mileageSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get mileageSourceManual;

  /// No description provided for @mileageSourceService.
  ///
  /// In en, this message translates to:
  /// **'From service'**
  String get mileageSourceService;

  /// No description provided for @mileageSourceSetup.
  ///
  /// In en, this message translates to:
  /// **'Baseline'**
  String get mileageSourceSetup;

  /// No description provided for @mileageSourceFuel.
  ///
  /// In en, this message translates to:
  /// **'From fill-up'**
  String get mileageSourceFuel;

  /// No description provided for @mileageCorrection.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get mileageCorrection;

  /// No description provided for @mileageDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this reading?'**
  String get mileageDeleteTitle;

  /// No description provided for @mileageDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{reading} on {date} will be removed.'**
  String mileageDeleteBody(String reading, String date);

  /// No description provided for @mileageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reading deleted'**
  String get mileageDeleted;

  /// No description provided for @mileageServiceHint.
  ///
  /// In en, this message translates to:
  /// **'Delete the service record to remove this'**
  String get mileageServiceHint;

  /// No description provided for @mileageEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Only your starting reading so far'**
  String get mileageEmptyTitle;

  /// No description provided for @mileageRowSemantic.
  ///
  /// In en, this message translates to:
  /// **'{reading}, {date}, {source}'**
  String mileageRowSemantic(String reading, String date, String source);

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @scheduleFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get scheduleFilterAll;

  /// No description provided for @scheduleFilterCount.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String scheduleFilterCount(String label, int count);

  /// No description provided for @scheduleUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get scheduleUpcoming;

  /// No description provided for @scheduleNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get scheduleNotApplicable;

  /// No description provided for @scheduleSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get scheduleSnoozed;

  /// No description provided for @scheduleCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get scheduleCritical;

  /// No description provided for @scheduleDueDateOrKm.
  ///
  /// In en, this message translates to:
  /// **'Due {date} or at {distance}'**
  String scheduleDueDateOrKm(String date, String distance);

  /// No description provided for @scheduleDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String scheduleDueDate(String date);

  /// No description provided for @scheduleDueKm.
  ///
  /// In en, this message translates to:
  /// **'Due at {distance}'**
  String scheduleDueKm(String distance);

  /// No description provided for @scheduleAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Add custom item'**
  String get scheduleAddCustom;

  /// No description provided for @scheduleTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Typical intervals'**
  String get scheduleTemplateTitle;

  /// No description provided for @scheduleTemplateBody.
  ///
  /// In en, this message translates to:
  /// **'These are typical intervals reviewed by a qualified mechanic. Your manufacturer\'s schedule may differ. Edit any item to match it.'**
  String get scheduleTemplateBody;

  /// No description provided for @scheduleAllGood.
  ///
  /// In en, this message translates to:
  /// **'All good. Everything is on schedule.'**
  String get scheduleAllGood;

  /// No description provided for @scheduleNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get scheduleNothingHere;

  /// No description provided for @scheduleRowSemantic.
  ///
  /// In en, this message translates to:
  /// **'{item}, {due}, {status}'**
  String scheduleRowSemantic(String item, String due, String status);

  /// No description provided for @scheduleSectionSemantic.
  ///
  /// In en, this message translates to:
  /// **'{section}, {count} items'**
  String scheduleSectionSemantic(String section, int count);

  /// No description provided for @scheduleSelectItem.
  ///
  /// In en, this message translates to:
  /// **'Choose an item to see its details'**
  String get scheduleSelectItem;

  /// No description provided for @itemResetToTypical.
  ///
  /// In en, this message translates to:
  /// **'Reset to typical'**
  String get itemResetToTypical;

  /// No description provided for @itemDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get itemDelete;

  /// No description provided for @itemDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String itemDeleteTitle(String name);

  /// No description provided for @itemDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from your schedule.'**
  String get itemDeleteBody;

  /// No description provided for @itemFactInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get itemFactInterval;

  /// No description provided for @itemFactLastDone.
  ///
  /// In en, this message translates to:
  /// **'Last done'**
  String get itemFactLastDone;

  /// No description provided for @itemFactNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due'**
  String get itemFactNextDue;

  /// No description provided for @itemFactPredicted.
  ///
  /// In en, this message translates to:
  /// **'Predicted'**
  String get itemFactPredicted;

  /// No description provided for @itemFactScore.
  ///
  /// In en, this message translates to:
  /// **'Score impact'**
  String get itemFactScore;

  /// No description provided for @itemEvery.
  ///
  /// In en, this message translates to:
  /// **'Every {interval}'**
  String itemEvery(String interval);

  /// No description provided for @itemMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{month} other{{count} months}}'**
  String itemMonths(int count);

  /// No description provided for @itemOr.
  ///
  /// In en, this message translates to:
  /// **'{first} or {second}'**
  String itemOr(String first, String second);

  /// No description provided for @itemEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get itemEdited;

  /// No description provided for @itemDateKm.
  ///
  /// In en, this message translates to:
  /// **'{date} · {distance}'**
  String itemDateKm(String date, String distance);

  /// No description provided for @itemSourceBaseline.
  ///
  /// In en, this message translates to:
  /// **'Baseline'**
  String get itemSourceBaseline;

  /// No description provided for @itemSourceNewCar.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get itemSourceNewCar;

  /// No description provided for @itemSourceService.
  ///
  /// In en, this message translates to:
  /// **'From your service'**
  String get itemSourceService;

  /// No description provided for @itemSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Set by you'**
  String get itemSourceManual;

  /// No description provided for @itemPredictedValue.
  ///
  /// In en, this message translates to:
  /// **'Around {date} at your usual mileage'**
  String itemPredictedValue(String date);

  /// No description provided for @itemPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} points'**
  String itemPoints(String points);

  /// No description provided for @itemNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get itemNone;

  /// No description provided for @itemNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get itemNotYet;

  /// No description provided for @itemMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get itemMarkDone;

  /// No description provided for @itemSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get itemSnooze;

  /// No description provided for @itemReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get itemReschedule;

  /// No description provided for @itemSnoozeTitle.
  ///
  /// In en, this message translates to:
  /// **'Snooze reminders'**
  String get itemSnoozeTitle;

  /// No description provided for @itemSnoozeDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String itemSnoozeDays(int count);

  /// No description provided for @itemSnoozeOverdueNote.
  ///
  /// In en, this message translates to:
  /// **'Reminders pause, but the score still counts this as overdue.'**
  String get itemSnoozeOverdueNote;

  /// No description provided for @itemRescheduleNote.
  ///
  /// In en, this message translates to:
  /// **'Only this time. Later reminders use the normal interval.'**
  String get itemRescheduleNote;

  /// No description provided for @itemRescheduledToast.
  ///
  /// In en, this message translates to:
  /// **'Due date moved to {date}'**
  String itemRescheduledToast(String date);

  /// No description provided for @itemEditInterval.
  ///
  /// In en, this message translates to:
  /// **'Edit interval'**
  String get itemEditInterval;

  /// No description provided for @itemNotApplicableToggle.
  ///
  /// In en, this message translates to:
  /// **'Not applicable to my car'**
  String get itemNotApplicableToggle;

  /// No description provided for @itemNotApplicableHint.
  ///
  /// In en, this message translates to:
  /// **'Hidden from your score and reminders'**
  String get itemNotApplicableHint;

  /// No description provided for @itemSetLastDone.
  ///
  /// In en, this message translates to:
  /// **'Set last done'**
  String get itemSetLastDone;

  /// No description provided for @itemLastDoneSaved.
  ///
  /// In en, this message translates to:
  /// **'Last done saved'**
  String get itemLastDoneSaved;

  /// No description provided for @itemLastDoneNeedOne.
  ///
  /// In en, this message translates to:
  /// **'Enter a date or a mileage'**
  String get itemLastDoneNeedOne;

  /// No description provided for @itemHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Service history'**
  String get itemHistoryTitle;

  /// No description provided for @itemHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No services logged for this item yet.'**
  String get itemHistoryEmpty;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @itemNotFound.
  ///
  /// In en, this message translates to:
  /// **'This item no longer exists'**
  String get itemNotFound;

  /// No description provided for @intervalEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit interval'**
  String get intervalEditTitle;

  /// No description provided for @customNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customNameLabel;

  /// No description provided for @customNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get customNameRequired;

  /// No description provided for @intervalMonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Every … months'**
  String get intervalMonthsLabel;

  /// No description provided for @intervalDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Every … {unit}'**
  String intervalDistanceLabel(String unit);

  /// No description provided for @intervalMonthsUnit.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get intervalMonthsUnit;

  /// No description provided for @intervalNote.
  ///
  /// In en, this message translates to:
  /// **'Whichever comes first. Leave one empty to use only the other.'**
  String get intervalNote;

  /// No description provided for @intervalNeedOne.
  ///
  /// In en, this message translates to:
  /// **'Set at least one interval.'**
  String get intervalNeedOne;

  /// No description provided for @intervalAboveZero.
  ///
  /// In en, this message translates to:
  /// **'Must be more than 0'**
  String get intervalAboveZero;

  /// No description provided for @importanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Importance'**
  String get importanceLabel;

  /// No description provided for @severityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get severityCritical;

  /// No description provided for @severityMajor.
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get severityMajor;

  /// No description provided for @severityMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get severityMinor;

  /// No description provided for @importanceHelper.
  ///
  /// In en, this message translates to:
  /// **'Overdue: {points}'**
  String importanceHelper(String points);

  /// No description provided for @customLastDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Last done (optional)'**
  String get customLastDoneTitle;

  /// No description provided for @intervalTypical.
  ///
  /// In en, this message translates to:
  /// **'Typical: {interval}'**
  String intervalTypical(String interval);

  /// No description provided for @intervalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Interval updated'**
  String get intervalUpdated;

  /// No description provided for @customItemAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String customItemAdded(String name);

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// No description provided for @templateUpdateBanner.
  ///
  /// In en, this message translates to:
  /// **'Typical intervals updated'**
  String get templateUpdateBanner;

  /// No description provided for @templateUpdateReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get templateUpdateReview;

  /// No description provided for @templateUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Typical intervals updated'**
  String get templateUpdateTitle;

  /// No description provided for @templateUpdateDefaultSummary.
  ///
  /// In en, this message translates to:
  /// **'Some typical intervals changed.'**
  String get templateUpdateDefaultSummary;

  /// One changed month interval, for example 'Every 36 → 24 months'.
  ///
  /// In en, this message translates to:
  /// **'Every {from} → {to} {to, plural, =1{month} other{months}}'**
  String templateUpdateMonths(int from, int to);

  /// A changed distance interval; values include the unit, e.g. '30,000 km'. Arabic uses ← so the arrow points to the new value.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String templateUpdateDistance(String from, String to);

  /// No description provided for @templateUpdateSeverity.
  ///
  /// In en, this message translates to:
  /// **'Importance: {from} → {to}'**
  String templateUpdateSeverity(String from, String to);

  /// No description provided for @templateUpdateNewItem.
  ///
  /// In en, this message translates to:
  /// **'New item · {interval}'**
  String templateUpdateNewItem(String interval);

  /// No description provided for @templateUpdateKept.
  ///
  /// In en, this message translates to:
  /// **'Kept: you edited this'**
  String get templateUpdateKept;

  /// No description provided for @templateUpdateNote.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by a qualified mechanic · template v{version}'**
  String templateUpdateNote(int version);

  /// No description provided for @templateUpdateApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get templateUpdateApply;

  /// No description provided for @templateUpdateKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep current'**
  String get templateUpdateKeep;

  /// No description provided for @templateUpdateApplied.
  ///
  /// In en, this message translates to:
  /// **'Schedule updated'**
  String get templateUpdateApplied;

  /// No description provided for @templateUpdateMenu.
  ///
  /// In en, this message translates to:
  /// **'Review updated intervals'**
  String get templateUpdateMenu;

  /// No description provided for @templateUpdateBadge.
  ///
  /// In en, this message translates to:
  /// **'Updated intervals'**
  String get templateUpdateBadge;

  /// No description provided for @templateUpdateNothingToApply.
  ///
  /// In en, this message translates to:
  /// **'You edited every changed item, so nothing will change.'**
  String get templateUpdateNothingToApply;

  /// No description provided for @nextServiceOverdueDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day overdue} other{{count} days overdue}}'**
  String nextServiceOverdueDays(num count);

  /// No description provided for @nextServiceInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Today} =1{Tomorrow} other{In {count} days}}'**
  String nextServiceInDays(num count);

  /// No description provided for @nextServiceInKm.
  ///
  /// In en, this message translates to:
  /// **'In about {distance}'**
  String nextServiceInKm(String distance);

  /// No description provided for @nextServiceKmNote.
  ///
  /// In en, this message translates to:
  /// **'Update your mileage now and then to get a date.'**
  String get nextServiceKmNote;

  /// No description provided for @nextServiceDueAround.
  ///
  /// In en, this message translates to:
  /// **'Due around then'**
  String get nextServiceDueAround;

  /// No description provided for @nextServiceDoNow.
  ///
  /// In en, this message translates to:
  /// **'To do now'**
  String get nextServiceDoNow;

  /// No description provided for @nextServiceLog.
  ///
  /// In en, this message translates to:
  /// **'Log service'**
  String get nextServiceLog;

  /// No description provided for @nextServiceSeeSchedule.
  ///
  /// In en, this message translates to:
  /// **'See full schedule'**
  String get nextServiceSeeSchedule;

  /// No description provided for @nextServiceNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing is due yet. Set when items were last done to see your next service.'**
  String get nextServiceNothing;

  /// Screen reader label for the S-18 heading block.
  ///
  /// In en, this message translates to:
  /// **'{title}: {value}, {detail}'**
  String nextServiceSemantic(String title, String value, String detail);

  /// No description provided for @spendTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get spendTitle;

  /// No description provided for @spendPreviousYear.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get spendPreviousYear;

  /// No description provided for @spendNextYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get spendNextYear;

  /// No description provided for @spendServicesInYear.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No services in {year}} =1{1 service in {year}} other{{count} services in {year}}}'**
  String spendServicesInYear(int count, String year);

  /// No description provided for @spendOtherCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Records in other currencies aren\'t included.'**
  String get spendOtherCurrencies;

  /// No description provided for @spendChangeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Change currency'**
  String get spendChangeCurrency;

  /// No description provided for @spendRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get spendRecords;

  /// No description provided for @spendNotInTotal.
  ///
  /// In en, this message translates to:
  /// **'Not in total'**
  String get spendNotInTotal;

  /// No description provided for @spendEmpty.
  ///
  /// In en, this message translates to:
  /// **'No costs logged in {year}'**
  String spendEmpty(String year);

  /// No description provided for @spendTotalSemantic.
  ///
  /// In en, this message translates to:
  /// **'Total for {year}: {amount}, {count}'**
  String spendTotalSemantic(String year, String amount, String count);

  /// No description provided for @actionLogService.
  ///
  /// In en, this message translates to:
  /// **'Log service'**
  String get actionLogService;

  /// No description provided for @serviceTypeMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get serviceTypeMaintenance;

  /// No description provided for @serviceTypeRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get serviceTypeRepair;

  /// No description provided for @serviceTypeInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get serviceTypeInspection;

  /// No description provided for @serviceTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get serviceTypeOther;

  /// Screen reader label of a service record row.
  ///
  /// In en, this message translates to:
  /// **'{date}, {title}, {detail}, {cost}'**
  String serviceRecordSemantic(
    String date,
    String title,
    String detail,
    String cost,
  );

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyYearChip.
  ///
  /// In en, this message translates to:
  /// **'Year: {year}'**
  String historyYearChip(String year);

  /// No description provided for @historyAllYears.
  ///
  /// In en, this message translates to:
  /// **'All years'**
  String get historyAllYears;

  /// No description provided for @historyTypeChip.
  ///
  /// In en, this message translates to:
  /// **'Type: {type}'**
  String historyTypeChip(String type);

  /// No description provided for @historyAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyAllTypes;

  /// No description provided for @historyClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get historyClear;

  /// No description provided for @historyChooseYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get historyChooseYear;

  /// No description provided for @historyChooseType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get historyChooseType;

  /// No description provided for @historyVehicleChip.
  ///
  /// In en, this message translates to:
  /// **'Vehicle: {name}. Change vehicle'**
  String historyVehicleChip(String name);

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No services yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Log your first service to build your car\'s history.'**
  String get historyEmptyBody;

  /// No description provided for @historyNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No services match these filters'**
  String get historyNoMatch;

  /// No description provided for @historyClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get historyClearFilters;

  /// No description provided for @historySelectRecord.
  ///
  /// In en, this message translates to:
  /// **'Select a record to see it here.'**
  String get historySelectRecord;

  /// No description provided for @historyLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading history'**
  String get historyLoading;

  /// No description provided for @recordFactOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get recordFactOdometer;

  /// No description provided for @recordFactCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get recordFactCost;

  /// No description provided for @recordFactShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get recordFactShop;

  /// No description provided for @recordItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Items covered'**
  String get recordItemsTitle;

  /// No description provided for @recordNoItems.
  ///
  /// In en, this message translates to:
  /// **'No schedule items. Nothing was reset.'**
  String get recordNoItems;

  /// No description provided for @recordNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get recordNotesTitle;

  /// No description provided for @recordNoNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get recordNoNotes;

  /// No description provided for @recordAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {dateTime}'**
  String recordAdded(String dateTime);

  /// No description provided for @recordDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this service?'**
  String get recordDeleteTitle;

  /// No description provided for @recordDeleteBodyItems.
  ///
  /// In en, this message translates to:
  /// **'{items} will go back to their previous dates.'**
  String recordDeleteBodyItems(String items);

  /// No description provided for @recordDeleteBodyNone.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from your history and spending.'**
  String get recordDeleteBodyNone;

  /// No description provided for @recordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Service deleted'**
  String get recordDeleted;

  /// No description provided for @recordGone.
  ///
  /// In en, this message translates to:
  /// **'This service was deleted.'**
  String get recordGone;

  /// No description provided for @recordItemSemantic.
  ///
  /// In en, this message translates to:
  /// **'{name}. Open item'**
  String recordItemSemantic(String name);

  /// Joins the last two names of a list: 'Engine oil and Oil filter'.
  ///
  /// In en, this message translates to:
  /// **'{first} and {last}'**
  String listAnd(String first, String last);

  /// No description provided for @logTitle.
  ///
  /// In en, this message translates to:
  /// **'Log service'**
  String get logTitle;

  /// No description provided for @logEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit service'**
  String get logEditTitle;

  /// No description provided for @logFor.
  ///
  /// In en, this message translates to:
  /// **'For: {name}'**
  String logFor(String name);

  /// No description provided for @logChooseVehicle.
  ///
  /// In en, this message translates to:
  /// **'Choose the vehicle'**
  String get logChooseVehicle;

  /// No description provided for @logDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get logDate;

  /// No description provided for @logOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get logOdometer;

  /// No description provided for @logOdometerCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current: {value}'**
  String logOdometerCurrent(String value);

  /// No description provided for @logOdometerRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the odometer reading.'**
  String get logOdometerRequired;

  /// No description provided for @logWhatDone.
  ///
  /// In en, this message translates to:
  /// **'What was done?'**
  String get logWhatDone;

  /// No description provided for @logAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Add custom item'**
  String get logAddCustom;

  /// No description provided for @logChipSemantic.
  ///
  /// In en, this message translates to:
  /// **'{name}, {status}'**
  String logChipSemantic(String name, String status);

  /// No description provided for @logType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get logType;

  /// No description provided for @logCost.
  ///
  /// In en, this message translates to:
  /// **'Cost (optional)'**
  String get logCost;

  /// No description provided for @logCostInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount like 120 or 120.50.'**
  String get logCostInvalid;

  /// No description provided for @logCostNegative.
  ///
  /// In en, this message translates to:
  /// **'Cost can\'t be negative.'**
  String get logCostNegative;

  /// No description provided for @logCostDecimals.
  ///
  /// In en, this message translates to:
  /// **'{currency} uses {count, plural, =0{no decimals} =1{1 decimal place} other{{count} decimal places}}.'**
  String logCostDecimals(String currency, int count);

  /// No description provided for @logCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get logCurrency;

  /// No description provided for @logCurrencyButton.
  ///
  /// In en, this message translates to:
  /// **'Currency: {code}. Change'**
  String logCurrencyButton(String code);

  /// No description provided for @logShop.
  ///
  /// In en, this message translates to:
  /// **'Shop (optional)'**
  String get logShop;

  /// No description provided for @logNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get logNotes;

  /// No description provided for @logSave.
  ///
  /// In en, this message translates to:
  /// **'Save service'**
  String get logSave;

  /// No description provided for @logDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this service?'**
  String get logDiscardTitle;

  /// No description provided for @logSaved.
  ///
  /// In en, this message translates to:
  /// **'Service saved · score now {score}'**
  String logSaved(int score);

  /// A backdated record didn't reset items with a newer last-done date (BR-SVC-02).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Saved to history. {items} keeps its newer date.} other{Saved to history. {items} keep their newer dates.}}'**
  String logSavedKept(int count, String items);

  /// No description provided for @addLogServiceSub.
  ///
  /// In en, this message translates to:
  /// **'Record work done on your car'**
  String get addLogServiceSub;

  /// No description provided for @addAddVehicleSub.
  ///
  /// In en, this message translates to:
  /// **'Add another car to your garage'**
  String get addAddVehicleSub;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Your garage is only on this phone'**
  String get profileGuestTitle;

  /// No description provided for @profileGuestBody.
  ///
  /// In en, this message translates to:
  /// **'If you delete the app or lose your phone, your data is gone.'**
  String get profileGuestBody;

  /// No description provided for @profileBackUp.
  ///
  /// In en, this message translates to:
  /// **'Back up your garage'**
  String get profileBackUp;

  /// No description provided for @profileSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get profileSignIn;

  /// No description provided for @profileSyncedMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Synced just now} =1{Synced 1 min ago} other{Synced {count} min ago}}'**
  String profileSyncedMinutes(int count);

  /// No description provided for @profileSyncedAt.
  ///
  /// In en, this message translates to:
  /// **'Synced {date}'**
  String profileSyncedAt(String date);

  /// No description provided for @profileWaitingSync.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync ({count})'**
  String profileWaitingSync(int count);

  /// No description provided for @profileOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get profileOffline;

  /// No description provided for @profileVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email to finish backing up'**
  String get profileVerifyEmail;

  /// No description provided for @profileResendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get profileResendEmail;

  /// No description provided for @profileVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get profileVerificationSent;

  /// No description provided for @profileAccountSemantic.
  ///
  /// In en, this message translates to:
  /// **'{name}, {email}, {sync}. Account details'**
  String profileAccountSemantic(String name, String email, String sync);

  /// No description provided for @profileEnableReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable reminders'**
  String get profileEnableReminders;

  /// No description provided for @profileEnableRemindersBody.
  ///
  /// In en, this message translates to:
  /// **'Get a reminder before something is due.'**
  String get profileEnableRemindersBody;

  /// No description provided for @profileGarage.
  ///
  /// In en, this message translates to:
  /// **'Garage'**
  String get profileGarage;

  /// No description provided for @profileVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get profileVehicles;

  /// No description provided for @profilePreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profilePreferences;

  /// No description provided for @profileCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get profileCountry;

  /// No description provided for @profileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileNotSet;

  /// No description provided for @profileDistanceUnit.
  ///
  /// In en, this message translates to:
  /// **'Distance unit'**
  String get profileDistanceUnit;

  /// No description provided for @profileKilometres.
  ///
  /// In en, this message translates to:
  /// **'Kilometres'**
  String get profileKilometres;

  /// No description provided for @profileMiles.
  ///
  /// In en, this message translates to:
  /// **'Miles'**
  String get profileMiles;

  /// No description provided for @profileCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get profileCurrency;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileDigits.
  ///
  /// In en, this message translates to:
  /// **'Digits'**
  String get profileDigits;

  /// No description provided for @profileDigitsWestern.
  ///
  /// In en, this message translates to:
  /// **'Western 0-9'**
  String get profileDigitsWestern;

  /// No description provided for @profileDigitsArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic-Indic ٠-٩'**
  String get profileDigitsArabic;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profileReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get profileReminders;

  /// No description provided for @profileOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get profileOn;

  /// No description provided for @profileOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get profileOff;

  /// No description provided for @profilePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get profilePrivacy;

  /// No description provided for @profileAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Usage analytics'**
  String get profileAnalytics;

  /// No description provided for @profileAnalyticsSub.
  ///
  /// In en, this message translates to:
  /// **'Anonymous. No advertising.'**
  String get profileAnalyticsSub;

  /// No description provided for @profilePrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get profilePrivacyPolicy;

  /// No description provided for @profileTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get profileTerms;

  /// No description provided for @profileHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get profileHelp;

  /// No description provided for @profileFaq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get profileFaq;

  /// No description provided for @profileContact.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get profileContact;

  /// No description provided for @profileSupportPromise.
  ///
  /// In en, this message translates to:
  /// **'We reply within 2 business days (Sunday to Thursday, Cairo time)'**
  String get profileSupportPromise;

  /// No description provided for @profileAccountActions.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccountActions;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccount;

  /// No description provided for @profileEraseData.
  ///
  /// In en, this message translates to:
  /// **'Erase all data'**
  String get profileEraseData;

  /// No description provided for @profileSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get profileSignOutTitle;

  /// No description provided for @profileSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your garage stays in your account. Sign in again any time to get it back.'**
  String get profileSignOutBody;

  /// No description provided for @profileUnsyncedTitle.
  ///
  /// In en, this message translates to:
  /// **'Some changes haven\'t synced'**
  String get profileUnsyncedTitle;

  /// No description provided for @profileUnsyncedBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change on this phone hasn\'t reached your account yet.} other{{count} changes on this phone haven\'t reached your account yet.}}'**
  String profileUnsyncedBody(int count);

  /// No description provided for @profileSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get profileSyncNow;

  /// No description provided for @profileDiscardSignOut.
  ///
  /// In en, this message translates to:
  /// **'Discard and sign out'**
  String get profileDiscardSignOut;

  /// No description provided for @profileSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get profileSignedOut;

  /// Footer, for example 'TDC-mena Garage 1.0.0 (123)'.
  ///
  /// In en, this message translates to:
  /// **'{name} {version} ({build})'**
  String profileVersion(String name, String version, String build);

  /// No description provided for @profileSelectSetting.
  ///
  /// In en, this message translates to:
  /// **'Choose a setting to see it here.'**
  String get profileSelectSetting;

  /// No description provided for @profileValueSemantic.
  ///
  /// In en, this message translates to:
  /// **'{title}, {value}'**
  String profileValueSemantic(String title, String value);

  /// No description provided for @regionSwitchBothTitle.
  ///
  /// In en, this message translates to:
  /// **'Also switch currency and units?'**
  String get regionSwitchBothTitle;

  /// No description provided for @regionSwitchCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Also switch currency?'**
  String get regionSwitchCurrencyTitle;

  /// No description provided for @regionSwitchUnitTitle.
  ///
  /// In en, this message translates to:
  /// **'Also switch units?'**
  String get regionSwitchUnitTitle;

  /// No description provided for @regionSwitchBoth.
  ///
  /// In en, this message translates to:
  /// **'Switch currency to {currency} and distance to {unit}?'**
  String regionSwitchBoth(String currency, String unit);

  /// No description provided for @regionSwitchCurrency.
  ///
  /// In en, this message translates to:
  /// **'Switch currency to {currency}?'**
  String regionSwitchCurrency(String currency);

  /// No description provided for @regionSwitchUnit.
  ///
  /// In en, this message translates to:
  /// **'Switch distance to {unit}?'**
  String regionSwitchUnit(String unit);

  /// No description provided for @regionSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get regionSwitch;

  /// No description provided for @regionKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep current'**
  String get regionKeep;

  /// No description provided for @regionPopularUpdated.
  ///
  /// In en, this message translates to:
  /// **'Popular brands updated for {country}'**
  String regionPopularUpdated(String country);

  /// No description provided for @regionPopularDefault.
  ///
  /// In en, this message translates to:
  /// **'Popular brands set to the default list'**
  String get regionPopularDefault;

  /// No description provided for @unitKmOption.
  ///
  /// In en, this message translates to:
  /// **'Kilometres (km)'**
  String get unitKmOption;

  /// No description provided for @unitMiOption.
  ///
  /// In en, this message translates to:
  /// **'Miles (mi)'**
  String get unitMiOption;

  /// No description provided for @unitCaption.
  ///
  /// In en, this message translates to:
  /// **'Your readings are converted exactly. Nothing is lost when you switch.'**
  String get unitCaption;

  /// No description provided for @currencyCaption.
  ///
  /// In en, this message translates to:
  /// **'New records use this currency. Existing records keep theirs.'**
  String get currencyCaption;

  /// No description provided for @currencySuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get currencySuggested;

  /// No description provided for @currencyAll.
  ///
  /// In en, this message translates to:
  /// **'All currencies'**
  String get currencyAll;

  /// No description provided for @currencySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search currencies'**
  String get currencySearchHint;

  /// No description provided for @currencyNoResults.
  ///
  /// In en, this message translates to:
  /// **'No currencies match \"{query}\"'**
  String currencyNoResults(String query);

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language & digits'**
  String get languageTitle;

  /// No description provided for @languageDevice.
  ///
  /// In en, this message translates to:
  /// **'Same as device ({language})'**
  String languageDevice(String language);

  /// No description provided for @digitsWesternOption.
  ///
  /// In en, this message translates to:
  /// **'Western (0 1 2 3)'**
  String get digitsWesternOption;

  /// The digits sample is built in code so it reads in order in both directions.
  ///
  /// In en, this message translates to:
  /// **'Arabic-Indic ({digits})'**
  String digitsArabicOption(String digits);

  /// No description provided for @digitsCaption.
  ///
  /// In en, this message translates to:
  /// **'VINs, plates and mileage always use Western digits.'**
  String get digitsCaption;

  /// No description provided for @notifOffInSettings.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off in your phone\'s Settings.'**
  String get notifOffInSettings;

  /// No description provided for @notifOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get notifOpenSettings;

  /// No description provided for @notifNotAsked.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so your reminders can reach you.'**
  String get notifNotAsked;

  /// No description provided for @notifAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get notifAllow;

  /// No description provided for @notifServiceReminders.
  ///
  /// In en, this message translates to:
  /// **'Service reminders'**
  String get notifServiceReminders;

  /// No description provided for @notifServiceRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'Due soon, overdue and mileage reminders'**
  String get notifServiceRemindersSub;

  /// No description provided for @notifSchedule.
  ///
  /// In en, this message translates to:
  /// **'Reminders arrive at 9:00, 30, 7 and 1 day before something is due. Overdue reminders follow on days 1, 3, 7 and 14, and monthly for brakes, tires and brake fluid.'**
  String get notifSchedule;

  /// No description provided for @authBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up and sync your garage'**
  String get authBackupTitle;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeTitle;

  /// No description provided for @authBody.
  ///
  /// In en, this message translates to:
  /// **'Use your account on any device. Your data stays private.'**
  String get authBody;

  /// No description provided for @authApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authApple;

  /// No description provided for @authGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authGoogle;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get authEmail;

  /// No description provided for @authTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get authTerms;

  /// No description provided for @authPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacy;

  /// No description provided for @authEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Your email'**
  String get authEmailTitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authEmailInvalid;

  /// No description provided for @authCreatePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get authCreatePasswordTitle;

  /// No description provided for @authEnterPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authEnterPasswordTitle;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authPasswordHint;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgot;

  /// No description provided for @authWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'That password doesn\'t match.'**
  String get authWrongPassword;

  /// No description provided for @authTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Try again in 5 minutes.'**
  String get authTooMany;

  /// No description provided for @authOffline.
  ///
  /// In en, this message translates to:
  /// **'You need a connection to sign in.'**
  String get authOffline;

  /// No description provided for @authResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authResetTitle;

  /// No description provided for @authResetBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a reset link at {email}.'**
  String authResetBody(String email);

  /// No description provided for @authSendLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get authSendLink;

  /// No description provided for @authResetSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get authResetSentTitle;

  /// No description provided for @authResetSentBody.
  ///
  /// In en, this message translates to:
  /// **'Open the link in the email to choose a new password.'**
  String get authResetSentBody;

  /// No description provided for @authVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email to verify your account.'**
  String get authVerifyTitle;

  /// No description provided for @authVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {email}. Your garage stays on this phone until you verify.'**
  String authVerifyBody(String email);

  /// No description provided for @authResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get authResend;

  /// No description provided for @authResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds} s'**
  String authResendIn(int seconds);

  /// No description provided for @authOpenMail.
  ///
  /// In en, this message translates to:
  /// **'Open Mail app'**
  String get authOpenMail;

  /// No description provided for @authVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get authVerificationSent;

  /// No description provided for @authSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get authSignedIn;

  /// No description provided for @authLegal.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the Terms and Privacy Policy.'**
  String get authLegal;

  /// No description provided for @backupBenefitHistory.
  ///
  /// In en, this message translates to:
  /// **'Keep your history if you lose your phone'**
  String get backupBenefitHistory;

  /// No description provided for @backupBenefitDevices.
  ///
  /// In en, this message translates to:
  /// **'Use it on your iPad too'**
  String get backupBenefitDevices;

  /// No description provided for @backupBenefitPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private to you. No advertising.'**
  String get backupBenefitPrivate;

  /// No description provided for @backupWarning.
  ///
  /// In en, this message translates to:
  /// **'Right now your data is only on this phone.'**
  String get backupWarning;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNow;

  /// No description provided for @backupNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get backupNotNow;

  /// No description provided for @backupVehicles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 vehicle} other{{count} vehicles}}'**
  String backupVehicles(int count);

  /// No description provided for @backupRecords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record} other{{count} records}}'**
  String backupRecords(int count);

  /// No description provided for @backupProgress.
  ///
  /// In en, this message translates to:
  /// **'Backing up {vehicles} and {records}…'**
  String backupProgress(String vehicles, String records);

  /// No description provided for @backupPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String backupPercent(String percent);

  /// No description provided for @backupWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection… Your data is safe on this phone.'**
  String get backupWaiting;

  /// No description provided for @backupFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup didn\'t finish'**
  String get backupFailedTitle;

  /// No description provided for @backupFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is still safe on this phone.'**
  String get backupFailedBody;

  /// No description provided for @backupDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your garage is backed up'**
  String get backupDoneTitle;

  /// No description provided for @backupDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get backupDone;

  /// No description provided for @mergeTitle.
  ///
  /// In en, this message translates to:
  /// **'This account already has a garage'**
  String get mergeTitle;

  /// No description provided for @mergeOption.
  ///
  /// In en, this message translates to:
  /// **'Merge into this account'**
  String get mergeOption;

  /// No description provided for @mergeOptionBody.
  ///
  /// In en, this message translates to:
  /// **'Adds this phone\'s {device} to your account\'s {account}.'**
  String mergeOptionBody(String device, String account);

  /// No description provided for @mergeRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get mergeRecommended;

  /// No description provided for @discardOption.
  ///
  /// In en, this message translates to:
  /// **'Discard this phone\'s data'**
  String get discardOption;

  /// No description provided for @discardOptionBody.
  ///
  /// In en, this message translates to:
  /// **'Removes the {device} on this phone and loads your account.'**
  String discardOptionBody(String device);

  /// No description provided for @discardDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this phone\'s data?'**
  String get discardDialogTitle;

  /// No description provided for @discardDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone. Type {word} to confirm.'**
  String discardDialogBody(String word);

  /// No description provided for @discardWord.
  ///
  /// In en, this message translates to:
  /// **'DISCARD'**
  String get discardWord;

  /// No description provided for @discardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardConfirm;

  /// No description provided for @discardDone.
  ///
  /// In en, this message translates to:
  /// **'This phone now shows your account\'s garage'**
  String get discardDone;

  /// No description provided for @limitTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what to bring'**
  String get limitTitle;

  /// No description provided for @limitBody.
  ///
  /// In en, this message translates to:
  /// **'An account holds up to 25 vehicles. Vehicles you don\'t bring are removed from this phone.'**
  String get limitBody;

  /// No description provided for @limitCounter.
  ///
  /// In en, this message translates to:
  /// **'You can bring {allowed} of {total}'**
  String limitCounter(int allowed, int total);

  /// No description provided for @dupTitle.
  ///
  /// In en, this message translates to:
  /// **'These look like the same car'**
  String get dupTitle;

  /// No description provided for @dupBody.
  ///
  /// In en, this message translates to:
  /// **'Both are kept. Remove one if it\'s a duplicate.'**
  String get dupBody;

  /// No description provided for @dupRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove this phone\'s copy'**
  String get dupRemove;

  /// No description provided for @dupOnPhone.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get dupOnPhone;

  /// No description provided for @dupInAccount.
  ///
  /// In en, this message translates to:
  /// **'In your account'**
  String get dupInAccount;

  /// No description provided for @eraseDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get eraseDeleteTitle;

  /// No description provided for @eraseEraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Erase all data'**
  String get eraseEraseTitle;

  /// No description provided for @eraseOwnerDevices.
  ///
  /// In en, this message translates to:
  /// **'Your vehicles, history and settings are deleted from all devices.'**
  String get eraseOwnerDevices;

  /// No description provided for @eraseOwnerBackups.
  ///
  /// In en, this message translates to:
  /// **'Backups are cleared within 30 days.'**
  String get eraseOwnerBackups;

  /// No description provided for @eraseOwnerFinal.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get eraseOwnerFinal;

  /// No description provided for @eraseGuest.
  ///
  /// In en, this message translates to:
  /// **'Everything on this phone is erased immediately.'**
  String get eraseGuest;

  /// No description provided for @eraseTypeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type {word} to confirm'**
  String eraseTypeToConfirm(String word);

  /// No description provided for @eraseDeleteWord.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get eraseDeleteWord;

  /// No description provided for @eraseEraseWord.
  ///
  /// In en, this message translates to:
  /// **'ERASE'**
  String get eraseEraseWord;

  /// No description provided for @eraseOffline.
  ///
  /// In en, this message translates to:
  /// **'You need a connection to delete your account.'**
  String get eraseOffline;

  /// No description provided for @reauthTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you'**
  String get reauthTitle;

  /// No description provided for @reauthBody.
  ///
  /// In en, this message translates to:
  /// **'For your security, sign in again before deleting your account.'**
  String get reauthBody;

  /// No description provided for @reauthAccount.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String reauthAccount(String email);

  /// No description provided for @reauthOr.
  ///
  /// In en, this message translates to:
  /// **'or use your password'**
  String get reauthOr;

  /// No description provided for @reauthConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get reauthConfirm;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// No description provided for @helpSearch.
  ///
  /// In en, this message translates to:
  /// **'Search help'**
  String get helpSearch;

  /// No description provided for @helpTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get helpTopics;

  /// No description provided for @helpCatGettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get helpCatGettingStarted;

  /// No description provided for @helpCatHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Health score'**
  String get helpCatHealthScore;

  /// No description provided for @helpCatReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get helpCatReminders;

  /// No description provided for @helpCatBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup & sync'**
  String get helpCatBackup;

  /// No description provided for @helpCatPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get helpCatPrivacy;

  /// No description provided for @helpQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String helpQuestionCount(int count);

  /// No description provided for @helpOffline.
  ///
  /// In en, this message translates to:
  /// **'Showing saved answers. Connect for the full help centre.'**
  String get helpOffline;

  /// No description provided for @helpResults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 answer} other{{count} answers}}'**
  String helpResults(int count);

  /// No description provided for @helpNoResults.
  ///
  /// In en, this message translates to:
  /// **'No answers for “{query}”'**
  String helpNoResults(String query);

  /// No description provided for @helpNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try other words, or email us below.'**
  String get helpNoResultsHint;

  /// No description provided for @helpContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get helpContactTitle;

  /// No description provided for @helpContactLanguage.
  ///
  /// In en, this message translates to:
  /// **'We reply in the language you write in.'**
  String get helpContactLanguage;

  /// No description provided for @helpEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'TDC-mena Garage support'**
  String get helpEmailSubject;

  /// No description provided for @helpEmailCopied.
  ///
  /// In en, this message translates to:
  /// **'Email address copied'**
  String get helpEmailCopied;

  /// No description provided for @helpEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Opens your email app'**
  String get helpEmailHint;

  /// No description provided for @helpLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get helpLegal;

  /// No description provided for @helpStillNeed.
  ///
  /// In en, this message translates to:
  /// **'Still need help?'**
  String get helpStillNeed;

  /// No description provided for @legalLoadsFrom.
  ///
  /// In en, this message translates to:
  /// **'This page loads from {address} in the in-app browser.'**
  String legalLoadsFrom(String address);

  /// No description provided for @editVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit vehicle'**
  String get editVehicleTitle;

  /// No description provided for @editBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get editBrand;

  /// No description provided for @editModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get editModel;

  /// No description provided for @editSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get editSaved;

  /// No description provided for @editDeleteVehicle.
  ///
  /// In en, this message translates to:
  /// **'Delete vehicle'**
  String get editDeleteVehicle;

  /// No description provided for @editOdometerLower.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be lower than the last reading ({mileage}). Correct it in Mileage history.'**
  String editOdometerLower(String mileage);

  /// No description provided for @fuelChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Update the schedule for {fuel}?'**
  String fuelChangeTitle(String fuel);

  /// No description provided for @fuelChangeBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll replace the typical items. Your custom items and history stay.'**
  String get fuelChangeBody;

  /// No description provided for @fuelChangeUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update schedule'**
  String get fuelChangeUpdate;

  /// No description provided for @fuelChangeKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep current schedule'**
  String get fuelChangeKeep;

  /// No description provided for @fuelChangeKeepIntervals.
  ///
  /// In en, this message translates to:
  /// **'Keep my edited intervals'**
  String get fuelChangeKeepIntervals;

  /// No description provided for @deleteVehicleBodyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{This deletes its schedule. This can\'t be undone.} =1{This deletes its schedule and 1 service record. This can\'t be undone.} other{This deletes its schedule and {count} service records. This can\'t be undone.}}'**
  String deleteVehicleBodyCount(int count);

  /// No description provided for @alertMileageReview.
  ///
  /// In en, this message translates to:
  /// **'Check a mileage reading'**
  String get alertMileageReview;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check this reading'**
  String get reviewTitle;

  /// No description provided for @reviewBody.
  ///
  /// In en, this message translates to:
  /// **'A reading from your other device is lower than an earlier one.'**
  String get reviewBody;

  /// No description provided for @reviewNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get reviewNeedsReview;

  /// No description provided for @reviewThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get reviewThisDevice;

  /// No description provided for @reviewUseCorrection.
  ///
  /// In en, this message translates to:
  /// **'Use {value} as a correction'**
  String reviewUseCorrection(String value);

  /// No description provided for @reviewDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete {value}'**
  String reviewDelete(String value);

  /// No description provided for @reviewCorrected.
  ///
  /// In en, this message translates to:
  /// **'Saved as a correction'**
  String get reviewCorrected;

  /// No description provided for @reviewCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'{value}, {date}, {device}'**
  String reviewCardSemantic(String value, String date, String device);

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineTitle;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// No description provided for @actionRetryShort.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetryShort;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @syncSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncSyncing;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String syncPending(int count);

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline. Changes will sync when you\'re back online.'**
  String get syncOffline;

  /// No description provided for @syncNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'A mileage reading needs review'**
  String get syncNeedsReview;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateTitle;

  /// No description provided for @updateBody.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer supported.'**
  String get updateBody;

  /// No description provided for @updateSafe.
  ///
  /// In en, this message translates to:
  /// **'Your data on this phone is safe.'**
  String get updateSafe;

  /// No description provided for @updateAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateAction;

  /// No description provided for @notifDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{n} day} other{{n} days}}'**
  String notifDays(int count, String n);

  /// No description provided for @notifDueIn.
  ///
  /// In en, this message translates to:
  /// **'{item} due in {days}'**
  String notifDueIn(String item, String days);

  /// No description provided for @notifDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'{item} due tomorrow'**
  String notifDueTomorrow(String item);

  /// No description provided for @notifOverdue.
  ///
  /// In en, this message translates to:
  /// **'{item} overdue by {days}'**
  String notifOverdue(String item, String days);

  /// No description provided for @notifBundle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{n} items need attention}}'**
  String notifBundle(int count, String n);

  /// No description provided for @notifMileageTitle.
  ///
  /// In en, this message translates to:
  /// **'Update your mileage'**
  String get notifMileageTitle;

  /// No description provided for @notifMileageBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s been {days}. It takes {seconds} seconds.'**
  String notifMileageBody(String days, String seconds);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
