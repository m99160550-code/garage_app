// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'TDC-mena Garage';

  @override
  String get launchLoadingLabel => 'جارٍ تحميل TDC-mena Garage';

  @override
  String get launchErrorTitle => 'تعذّر فتح كراجك';

  @override
  String get launchErrorBody =>
      'حدث خطأ أثناء تحميل بياناتك. بياناتك محفوظة على هذا الهاتف.';

  @override
  String get actionRetry => 'حاول مرة أخرى';

  @override
  String get languageSwitchLabel => 'English';

  @override
  String get languageSwitchSemantic => 'تبديل التطبيق إلى الإنجليزية';

  @override
  String get introSkip => 'تخطٍّ';

  @override
  String get introNext => 'التالي';

  @override
  String get introGetStarted => 'ابدأ الآن';

  @override
  String get introSignIn => 'لدي حساب بالفعل · تسجيل الدخول';

  @override
  String introPageLabel(int current, int total) {
    return 'الصفحة $current من $total';
  }

  @override
  String get introPage1Title => 'صحة سيارتك في لمحة';

  @override
  String get introPage1Body =>
      'اعرف ما يحتاج إلى انتباهك قبل أن يتحوّل إلى فاتورة إصلاح.';

  @override
  String get introPage2Title => 'لا تفوّت أي صيانة';

  @override
  String get introPage2Body =>
      'تذكيرات قبل موعد الزيت والفرامل والإطارات، بحسب الفترات المعتادة.';

  @override
  String get introPage3Title => 'ابدأ الآن دون حساب';

  @override
  String get introPage3Body =>
      'يبقى كراجك على هذا الهاتف. احفظ نسخة احتياطية متى شئت.';

  @override
  String get healthScoreLabel => 'مؤشر الحالة';

  @override
  String get healthBandGood => 'جيد';

  @override
  String get statMileage => 'المسافة';

  @override
  String get statMileageSub => 'الإجمالي';

  @override
  String get statNextService => 'الصيانة القادمة';

  @override
  String get statNextServiceSub => 'أيام متبقية';

  @override
  String get statThisYear => 'هذا العام';

  @override
  String get statThisYearSub => 'المصروف';

  @override
  String get unitKm => 'كم';

  @override
  String get actionContinue => 'متابعة';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get actionClearSearch => 'مسح البحث';

  @override
  String get stateSelected => 'محدد';

  @override
  String stepLabel(int current, int total, String name) {
    return 'الخطوة $current من $total: $name';
  }

  @override
  String get stepCountry => 'الدولة';

  @override
  String get stepBrand => 'العلامة';

  @override
  String get stepCar => 'السيارة';

  @override
  String get stepService => 'الصيانة';

  @override
  String get unitMi => 'ميل';

  @override
  String get countryTitle => 'أين تقود سيارتك؟';

  @override
  String get countryBody =>
      'سنضبط العملة ووحدة المسافة والعلامات الشائعة. يمكنك تغييرها في أي وقت.';

  @override
  String get countryCardLabel => 'الدولة';

  @override
  String get countryChange => 'تغيير';

  @override
  String get countryNotSet => 'غير محددة';

  @override
  String get countryOther => 'أخرى / غير محددة';

  @override
  String get countryOtherHint => 'الدولار وكم والعلامات الأكثر شيوعًا';

  @override
  String get popularListStandard => 'العلامات الشائعة';

  @override
  String get popularListGulf => 'علامات الخليج';

  @override
  String get popularListEgypt => 'علامات مصر';

  @override
  String get countryPickerTitle => 'اختر دولتك';

  @override
  String get countrySearchHint => 'ابحث عن دولة…';

  @override
  String get countryNoResults => 'لا توجد دول مطابقة';

  @override
  String get countryNoResultsHint =>
      'جرّب كتابة أخرى، أو اختر أخرى / غير محددة.';

  @override
  String get consentTitle => 'ساعدنا في تحسين التطبيق';

  @override
  String get consentBody =>
      'شارك بيانات استخدام مجهولة الهوية. لا إعلانات ولا تتبّع عبر التطبيقات.';

  @override
  String get consentAllow => 'السماح';

  @override
  String get consentDeny => 'عدم السماح';

  @override
  String get consentRequiredHint => 'اختر السماح أو عدم السماح للمتابعة.';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get garageTitle => 'كراجي';

  @override
  String get brandPrompt => 'اختر علامة سيارتك';

  @override
  String get brandScreenTitle => 'اختر علامة سيارتك';

  @override
  String get brandSearchHint => 'ابحث عن العلامة…';

  @override
  String get brandSelect => 'اختيار';

  @override
  String get brandOther => 'علامة أخرى';

  @override
  String get brandOtherHint => 'اكتب اسم العلامة';

  @override
  String get brandOtherFieldLabel => 'اسم العلامة';

  @override
  String brandContinueWith(String brand) {
    return 'المتابعة مع $brand';
  }

  @override
  String get brandNoResults => 'لم يتم العثور على علامات';

  @override
  String get brandFoundInTabs => 'موجودة في تبويبات أخرى:';

  @override
  String brandAddAsOther(String name) {
    return 'إضافة «$name» كعلامة أخرى';
  }

  @override
  String get tabPopular => 'الشائعة';

  @override
  String get tabEuropean => 'أوروبية';

  @override
  String get tabJapanese => 'يابانية';

  @override
  String get tabKorean => 'كورية';

  @override
  String get tabChinese => 'صينية';

  @override
  String get tabAmerican => 'أمريكية';

  @override
  String tabSemantic(String name, int index, int count) {
    return '$name، تبويب $index من $count';
  }

  @override
  String get discardVehicleTitle => 'تجاهل هذه السيارة؟';

  @override
  String get discardVehicleBody => 'لن يتم حفظ العلامة التي اخترتها.';

  @override
  String get actionDiscard => 'تجاهل';

  @override
  String get actionKeepEditing => 'متابعة التعديل';

  @override
  String get modelSubtitle => 'اختر طراز سيارتك';

  @override
  String get modelOther => 'طراز آخر';

  @override
  String get modelOtherHint => 'اكتب اسم الطراز';

  @override
  String get modelNameLabel => 'اسم الطراز';

  @override
  String get bodyTypeLabel => 'نوع الهيكل';

  @override
  String get bodyTypeHelper => 'يحدد رسم سيارتك.';

  @override
  String get bodySedan => 'سيدان';

  @override
  String get bodyHatchback => 'هاتشباك';

  @override
  String get bodySuv => 'رياضية (SUV)';

  @override
  String get bodyCoupe => 'كوبيه';

  @override
  String get bodyWagon => 'ستيشن';

  @override
  String get bodyPickup => 'بيك أب';

  @override
  String get bodyVan => 'فان';

  @override
  String get usuallyPetrol => 'عادةً بنزين';

  @override
  String get usuallyDiesel => 'عادةً ديزل';

  @override
  String get usuallyHybrid => 'عادةً هايبرد';

  @override
  String get usuallyEv => 'عادةً كهربائية';

  @override
  String get modelsComingSoon => 'قائمة طرازات هذه العلامة قادمة قريبًا.';

  @override
  String get modelNeedBrandTitle => 'اختر العلامة أولًا';

  @override
  String get modelNeedBrandBody => 'لم نجد علامة هذه السيارة.';

  @override
  String get modelNeedBrandAction => 'اختيار العلامة';

  @override
  String positionOf(int index, int count) {
    return '$index من $count';
  }

  @override
  String get detailsSubtitle => 'أخبرنا عن سيارتك';

  @override
  String get fuelTypeLabel => 'نوع الوقود';

  @override
  String get fuelTypeHelper => 'يحدد جدول الصيانة الخاص بك.';

  @override
  String get fuelPetrol => 'بنزين';

  @override
  String get fuelDiesel => 'ديزل';

  @override
  String get fuelHybrid => 'هايبرد';

  @override
  String get fuelEv => 'كهربائية';

  @override
  String get odometerLabel => 'عداد المسافة الحالي';

  @override
  String get odometerHelper => 'تحقق من لوحة العدادات.';

  @override
  String get odometerMissing => 'أدخل المسافة الحالية';

  @override
  String get odometerNotNumber => 'أدخل أرقامًا فقط';

  @override
  String get odometerTooHigh => 'الرقم يبدو كبيرًا جدًا. تحقق منه.';

  @override
  String get appearanceTitle => 'المظهر';

  @override
  String get paintColorLabel => 'لون الطلاء';

  @override
  String get paintObsidianBlack => 'أسود';

  @override
  String get paintPolarWhite => 'أبيض لؤلؤي';

  @override
  String get paintSilver => 'فضي';

  @override
  String get paintGunmetalGrey => 'رمادي معدني';

  @override
  String get paintDesertSand => 'رملي';

  @override
  String get paintChampagne => 'شامبين';

  @override
  String get paintMidnightBlue => 'أزرق داكن';

  @override
  String get paintSkyBlue => 'أزرق سماوي';

  @override
  String get paintRacingRed => 'أحمر';

  @override
  String get paintSunsetOrange => 'برتقالي';

  @override
  String get paintForestGreen => 'أخضر داكن';

  @override
  String get paintBronze => 'برونزي';

  @override
  String get moreDetailsTitle =>
      'أضف اسمًا مستعارًا والسنة ورقم الهيكل والمزيد';

  @override
  String get moreDetailsOptional => 'اختياري';

  @override
  String get nicknameLabel => 'اسم مستعار';

  @override
  String get yearLabel => 'سنة الصنع';

  @override
  String get plateLabel => 'رقم اللوحة';

  @override
  String get vinLabel => 'رقم الهيكل (VIN)';

  @override
  String get purchaseDateLabel => 'تاريخ الشراء';

  @override
  String get vinLengthWarning =>
      'رقم الهيكل عادةً 17 خانة. احتفظ به إذا كانت سيارتك أقدم من عام 1981.';

  @override
  String get vinInvalid => 'لا يحتوي رقم الهيكل على الحروف I أو O أو Q.';

  @override
  String get duplicateVinTitle => 'لديك سيارة بنفس رقم الهيكل';

  @override
  String duplicateVinBody(String name) {
    return '$name لها رقم الهيكل نفسه. هل تريد الإضافة على أي حال؟';
  }

  @override
  String get duplicateVinAdd => 'الإضافة على أي حال';

  @override
  String get duplicateVinChange => 'تغيير رقم الهيكل';

  @override
  String get dateToday => 'اليوم';

  @override
  String get dateClear => 'مسح';

  @override
  String get dateDone => 'تم';

  @override
  String get detailsNeedModelTitle => 'اختر الطراز أولًا';

  @override
  String get detailsNeedModelBody => 'لم نجد طراز هذه السيارة.';

  @override
  String get duplicateVinUnnamed => 'سيارة أخرى في كراجك';

  @override
  String get baselineTitle => 'متى تمت هذه آخر مرة؟';

  @override
  String get baselineSubtitle =>
      'هذا يجعل مؤشر حالة سيارتك دقيقًا. تخطَّ ما لا تعرفه.';

  @override
  String get newCarTitle => 'سيارتي جديدة';

  @override
  String get newCarSubtitle => 'استلمتها مؤخرًا؟ سنبدأ كل شيء من جديد.';

  @override
  String get deliveryDateLabel => 'تاريخ الاستلام';

  @override
  String get startingMileageLabel => 'المسافة عند الاستلام';

  @override
  String get newCarNote =>
      'تبدأ جميع البنود من تاريخ الاستلام. يبدأ مؤشرك من 100.';

  @override
  String get baselineOilService => 'تغيير الزيت أو الصيانة';

  @override
  String get baselineBrakes => 'الفرامل';

  @override
  String get baselineTires => 'الإطارات';

  @override
  String get baselineBattery => 'البطارية';

  @override
  String get baselineDateLabel => 'التاريخ';

  @override
  String get baselineMileageLabel => 'المسافة';

  @override
  String get baselineDontKnow => 'لا أعرف';

  @override
  String get baselineUnknownBadge => 'غير معروف';

  @override
  String get baselineFooter =>
      'تبدأ البنود الأخرى مثل الفلاتر وسائل التبريد كغير معروفة. يمكنك تحديدها لاحقًا في جدول الصيانة.';

  @override
  String get actionSaveVehicle => 'حفظ السيارة';

  @override
  String baselineKmAboveOdometer(String mileage) {
    return 'لا يمكن أن تكون أكثر من المسافة الحالية ($mileage).';
  }

  @override
  String baselineCardSemantic(String item) {
    return '$item، آخر مرة';
  }

  @override
  String baselineUnknownAnnounce(String item) {
    return 'تم تحديد $item كغير معروف';
  }

  @override
  String baselineKnownAnnounce(String item) {
    return 'يمكن إدخال $item مرة أخرى';
  }

  @override
  String get deliveryOldTitle => 'قد تكون بعض البنود مستحقة بالفعل';

  @override
  String deliveryOldBody(String age) {
    return 'تاريخ الاستلام $age. ستظهر البنود ذات الفترات الأقصر كمستحقة أو متأخرة.';
  }

  @override
  String get deliveryOldBodyDistance =>
      'قُطعت مسافة تتجاوز بعض الفترات منذ الاستلام. ستظهر هذه البنود كمستحقة أو متأخرة.';

  @override
  String deliveryAgeYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count سنة',
      few: 'قبل $count سنوات',
      two: 'قبل سنتين',
      one: 'قبل سنة',
    );
    return '$_temp0';
  }

  @override
  String deliveryAgeMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count شهرًا',
      few: 'قبل $count أشهر',
      two: 'قبل شهرين',
      one: 'قبل شهر',
    );
    return '$_temp0';
  }

  @override
  String get deliveryKeep => 'الإبقاء على التاريخ';

  @override
  String get deliveryChange => 'تغيير التاريخ';

  @override
  String get deliveryDateMissing => 'اختر تاريخ الاستلام';

  @override
  String get baselineNeedDetailsTitle => 'أضف تفاصيل سيارتك أولًا';

  @override
  String get baselineNeedDetailsBody => 'لم نجد تفاصيل هذه السيارة.';

  @override
  String get primerTitle => 'لا تفوّت أي صيانة';

  @override
  String get primerBody =>
      'سنذكّرك قبل موعد أي بند بـ 30 و7 أيام ويوم واحد، الساعة 9:00. يمكنك إيقاف ذلك في أي وقت.';

  @override
  String get primerDeniedHint =>
      'الإشعارات متوقفة لتطبيق TDC Garage. فعّلها من الإعدادات.';

  @override
  String get primerTurnOn => 'تفعيل التذكيرات';

  @override
  String get primerOpenSettings => 'فتح الإعدادات';

  @override
  String get primerNotNow => 'ليس الآن';

  @override
  String get primerPreviewApp => 'TDC Garage';

  @override
  String get primerPreviewTime => 'الآن';

  @override
  String primerPreviewText(String vehicle, String item) {
    return '$vehicle · موعد $item بعد 7 أيام';
  }

  @override
  String primerPreviewSemantic(String text) {
    return 'مثال على إشعار: $text';
  }

  @override
  String get primerPillExample => 'مستحق بعد 7 أيام';

  @override
  String get remindersOnToast => 'التذكيرات مفعّلة';

  @override
  String get primerPreviewFallbackItem => 'تغيير الزيت';

  @override
  String get navGarage => 'الكراج';

  @override
  String get navHistory => 'السجل';

  @override
  String get navAdd => 'إضافة';

  @override
  String get navProfile => 'الحساب';

  @override
  String dashboardSwitchVehicle(String name) {
    return '$name، تبديل السيارة';
  }

  @override
  String dashboardModelYear(String model, String year) {
    return '$model · $year';
  }

  @override
  String dashboardVehicleDots(int index, int count) {
    return 'السيارة $index من $count';
  }

  @override
  String get actionMoreOptions => 'خيارات أخرى';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionDelete => 'حذف';

  @override
  String get menuSchedule => 'جدول الصيانة';

  @override
  String get menuMileageHistory => 'سجل المسافة';

  @override
  String get menuEditVehicle => 'تعديل السيارة';

  @override
  String get menuDeleteVehicle => 'حذف السيارة';

  @override
  String deleteVehicleTitle(String name) {
    return 'حذف $name؟';
  }

  @override
  String get deleteVehicleBody =>
      'سيتم حذف جدول الصيانة وسجل الخدمات والتذكيرات الخاصة بها. لا يمكن التراجع عن ذلك.';

  @override
  String deleteVehicleDone(String name) {
    return 'تم حذف $name';
  }

  @override
  String get bandExcellent => 'ممتازة';

  @override
  String get bandGood => 'جيدة';

  @override
  String get bandNeedsAttention => 'تحتاج انتباهًا';

  @override
  String get bandUrgent => 'عاجلة';

  @override
  String healthBasedOnTypical(int count) {
    return 'وفق الفترات المعتادة · $count غير معروف';
  }

  @override
  String healthSemantic(int score, String band) {
    return 'مؤشر الحالة $score بالمئة، $band';
  }

  @override
  String statUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حُدّثت قبل $count يومًا',
      few: 'حُدّثت قبل $count أيام',
      two: 'حُدّثت قبل يومين',
      one: 'حُدّثت أمس',
      zero: 'حُدّثت اليوم',
    );
    return '$_temp0';
  }

  @override
  String get statDaysAway => 'يوم متبقٍ';

  @override
  String get statDue => 'مستحقة';

  @override
  String get statToday => 'اليوم';

  @override
  String get statDaysOverdue => 'يوم تأخير';

  @override
  String get statSetUpSchedule => 'أعدّ جدول الصيانة';

  @override
  String statDistanceToGo(String unit) {
    return '$unit متبقية';
  }

  @override
  String statItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بندًا',
      few: '$count بنود',
      two: 'بندان',
      one: 'بند واحد',
    );
    return '$_temp0';
  }

  @override
  String statDateItems(String date, String items) {
    return '$date · $items';
  }

  @override
  String get statSpent => 'المصروف';

  @override
  String statServices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خدمة',
      few: '$count خدمات',
      two: 'خدمتان',
      one: 'خدمة واحدة',
      zero: 'لا تكاليف بعد',
    );
    return '$_temp0';
  }

  @override
  String get statSomeNotIncluded => 'بعض السجلات غير مشمولة';

  @override
  String statCardSemantic(
    String label,
    String value,
    String sublabel,
    String footer,
  ) {
    return '$label، $value $sublabel، $footer';
  }

  @override
  String get statCarouselLabel => 'بطاقات الإحصاءات';

  @override
  String get statCarouselHint => 'اسحب لأعلى أو لأسفل للتغيير';

  @override
  String get unitKmWord => 'كيلومتر';

  @override
  String get unitMiWord => 'ميل';

  @override
  String alertOverdueOne(String item) {
    return '$item متأخر';
  }

  @override
  String alertOverdueMany(int count) {
    return '$count بنود متأخرة';
  }

  @override
  String alertDueSoon(String item) {
    return '$item مستحق قريبًا';
  }

  @override
  String alertUnknown(int count) {
    return 'أكمل جدول الصيانة · $count غير معروف';
  }

  @override
  String alertStaleMileage(int count) {
    return 'حدّث المسافة · $count يومًا';
  }

  @override
  String get alertAllGood => 'كل شيء على ما يرام';

  @override
  String get upcomingTitle => 'القادم';

  @override
  String upcomingInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بعد $count يومًا',
      few: 'بعد $count أيام',
      two: 'بعد يومين',
      one: 'بعد يوم',
      zero: 'مستحق اليوم',
    );
    return '$_temp0';
  }

  @override
  String upcomingOverdueDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'متأخر $count يومًا',
      few: 'متأخر $count أيام',
      two: 'متأخر يومين',
      one: 'متأخر يومًا',
      zero: 'متأخر',
    );
    return '$_temp0';
  }

  @override
  String upcomingInDistance(String distance) {
    return 'بعد $distance';
  }

  @override
  String get statusOverdue => 'متأخر';

  @override
  String get statusDueSoon => 'مستحق قريبًا';

  @override
  String get statusOk => 'جيد';

  @override
  String get switcherTitle => 'كراجك';

  @override
  String switcherCount(int count, int max) {
    return '$count من $max سيارة';
  }

  @override
  String get switcherAddVehicle => 'إضافة سيارة';

  @override
  String get switcherLimitReached => 'وصلت إلى الحد الأقصى. تواصل مع الدعم.';

  @override
  String get switcherManage => 'إدارة السيارات';

  @override
  String switcherOverdue(int count) {
    return '$count متأخر';
  }

  @override
  String get switcherNotSetUp => 'غير مُعدّة';

  @override
  String get switcherCurrent => 'السيارة الحالية';

  @override
  String switcherRowSemantic(String name, String subline, String status) {
    return '$name، $subline، $status';
  }

  @override
  String healthSummaryOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بندًا متأخرًا',
      few: '$count بنود متأخرة',
      two: 'بندان متأخران',
      one: 'بند واحد متأخر',
    );
    return '$_temp0';
  }

  @override
  String healthSummarySoon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بندًا مستحقًا خلال 30 يومًا',
      few: '$count بنود مستحقة خلال 30 يومًا',
      two: 'بندان مستحقان خلال 30 يومًا',
      one: 'بند واحد مستحق خلال 30 يومًا',
    );
    return '$_temp0';
  }

  @override
  String healthSummaryJoin(String first, String second) {
    return '$first و$second.';
  }

  @override
  String healthSummarySentence(String text) {
    return '$text.';
  }

  @override
  String get healthNothingLowering => 'لا شيء يخفض مؤشرك';

  @override
  String get healthSectionLowering => 'ما يخفض مؤشرك';

  @override
  String healthReasonOverdueKm(String distance) {
    return 'متأخر بمسافة $distance';
  }

  @override
  String healthReasonDueInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مستحق بعد $count يومًا',
      few: 'مستحق بعد $count أيام',
      two: 'مستحق بعد يومين',
      one: 'مستحق بعد يوم',
      zero: 'مستحق اليوم',
    );
    return '$_temp0';
  }

  @override
  String healthReasonDueInKm(String distance) {
    return 'مستحق بعد نحو $distance';
  }

  @override
  String get healthDoubleBadge => '×2';

  @override
  String healthRowSemantic(String item, String reason, int points) {
    return '$item، $reason، ناقص $points نقاط';
  }

  @override
  String get healthCountsDouble => 'يُحتسب مضاعفًا';

  @override
  String get healthSectionNotCounted => 'غير محتسب';

  @override
  String get healthUnknownSetLastDone => 'غير معروف: حدّد آخر مرة';

  @override
  String healthSnoozedUntil(String date) {
    return 'مؤجّل حتى $date';
  }

  @override
  String get healthHowTitle => 'كيف يُحسب المؤشر';

  @override
  String get healthHowBody =>
      'يبدأ مؤشرك من 100. تخسر البنود المتأخرة من 5 إلى 15 نقطة حسب أهميتها، وتخسر البنود المستحقة خلال 30 يومًا نقطتين. البنود المتأخرة أكثر من 30 يومًا أو 1,000 كم تُحتسب مضاعفة.';

  @override
  String healthTemplateLine(String fuel, int version) {
    return 'الفترات المعتادة لـ$fuel · القالب v$version';
  }

  @override
  String get healthSeeSchedule => 'عرض جدول الصيانة';

  @override
  String get mileageTitle => 'تحديث المسافة';

  @override
  String mileageLast(String reading, String date) {
    return 'آخر قراءة: $reading · $date';
  }

  @override
  String mileageFieldLabel(String unit) {
    return 'قراءة العداد الجديدة بـ$unit';
  }

  @override
  String get mileageChooseVehicle => 'اختر السيارة';

  @override
  String get actionSave => 'حفظ';

  @override
  String get actionEdit => 'تعديل';

  @override
  String get mileageViewHistory => 'عرض السجل';

  @override
  String get mileageLowerTitle => 'هذه القراءة أقل من آخر قراءة';

  @override
  String mileageLowerBody(String last, String date, String value) {
    return 'كانت آخر قراءة $last في $date. هل تحفظ $value كتصحيح؟';
  }

  @override
  String get mileageSaveCorrection => 'حفظ كتصحيح';

  @override
  String get mileageJumpTitle => 'هل هذا صحيح؟';

  @override
  String mileageJumpBody(String distance, String period) {
    return 'هذا $distance خلال $period.';
  }

  @override
  String mileageDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يومًا',
      few: '$count أيام',
      two: 'يومين',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get mileageJumpConfirm => 'نعم، احفظ';

  @override
  String get mileageUpdatedToast => 'تم تحديث المسافة';

  @override
  String get mileageAverageLabel => 'المتوسط';

  @override
  String mileageAveragePerMonth(String distance) {
    return '$distance / شهريًا';
  }

  @override
  String get mileageAverageBasis => 'بناءً على آخر 180 يومًا';

  @override
  String mileageAverageNeedMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أضف قراءة أخرى بعد $count يومًا لرؤية متوسطك.',
      few: 'أضف قراءة أخرى بعد $count أيام لرؤية متوسطك.',
      two: 'أضف قراءة أخرى بعد يومين لرؤية متوسطك.',
      one: 'أضف قراءة أخرى غدًا لرؤية متوسطك.',
      zero: 'أضف قراءة أخرى لرؤية متوسطك.',
    );
    return '$_temp0';
  }

  @override
  String get mileageSourceManual => 'يدوي';

  @override
  String get mileageSourceService => 'من الخدمة';

  @override
  String get mileageSourceSetup => 'القراءة الأولى';

  @override
  String get mileageSourceFuel => 'من التعبئة';

  @override
  String get mileageCorrection => 'تصحيح';

  @override
  String get mileageDeleteTitle => 'حذف هذه القراءة؟';

  @override
  String mileageDeleteBody(String reading, String date) {
    return 'ستُحذف قراءة $reading بتاريخ $date.';
  }

  @override
  String get mileageDeleted => 'تم حذف القراءة';

  @override
  String get mileageServiceHint => 'احذف سجل الخدمة لإزالة هذه القراءة';

  @override
  String get mileageEmptyTitle => 'لا توجد سوى قراءتك الأولى حتى الآن';

  @override
  String mileageRowSemantic(String reading, String date, String source) {
    return '$reading، $date، $source';
  }

  @override
  String get scheduleTitle => 'جدول الصيانة';

  @override
  String get scheduleFilterAll => 'الكل';

  @override
  String scheduleFilterCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get scheduleUpcoming => 'القادم';

  @override
  String get scheduleNotApplicable => 'لا ينطبق';

  @override
  String get scheduleSnoozed => 'مؤجّل';

  @override
  String get scheduleCritical => 'حرج';

  @override
  String scheduleDueDateOrKm(String date, String distance) {
    return 'مستحق في $date أو عند $distance';
  }

  @override
  String scheduleDueDate(String date) {
    return 'مستحق في $date';
  }

  @override
  String scheduleDueKm(String distance) {
    return 'مستحق عند $distance';
  }

  @override
  String get scheduleAddCustom => 'إضافة بند مخصص';

  @override
  String get scheduleTemplateTitle => 'الفترات المعتادة';

  @override
  String get scheduleTemplateBody =>
      'هذه فترات معتادة راجعها ميكانيكي مؤهل. قد يختلف جدول الشركة المصنّعة. عدّل أي بند ليطابقه.';

  @override
  String get scheduleAllGood => 'كل شيء على ما يرام. جميع البنود في موعدها.';

  @override
  String get scheduleNothingHere => 'لا شيء هنا';

  @override
  String scheduleRowSemantic(String item, String due, String status) {
    return '$item، $due، $status';
  }

  @override
  String scheduleSectionSemantic(String section, int count) {
    return '$section، $count بنود';
  }

  @override
  String get scheduleSelectItem => 'اختر بندًا لعرض تفاصيله';

  @override
  String get itemResetToTypical => 'إعادة إلى المعتاد';

  @override
  String get itemDelete => 'حذف البند';

  @override
  String itemDeleteTitle(String name) {
    return 'حذف $name؟';
  }

  @override
  String get itemDeleteBody => 'سيُزال من جدول الصيانة.';

  @override
  String get itemFactInterval => 'الفترة';

  @override
  String get itemFactLastDone => 'آخر مرة';

  @override
  String get itemFactNextDue => 'الموعد القادم';

  @override
  String get itemFactPredicted => 'المتوقع';

  @override
  String get itemFactScore => 'التأثير على المؤشر';

  @override
  String itemEvery(String interval) {
    return 'كل $interval';
  }

  @override
  String itemMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شهرًا',
      few: '$count أشهر',
      two: 'شهرين',
      one: 'شهر',
    );
    return '$_temp0';
  }

  @override
  String itemOr(String first, String second) {
    return '$first أو $second';
  }

  @override
  String get itemEdited => 'معدّل';

  @override
  String itemDateKm(String date, String distance) {
    return '$date · $distance';
  }

  @override
  String get itemSourceBaseline => 'القراءة الأولى';

  @override
  String get itemSourceNewCar => 'الاستلام';

  @override
  String get itemSourceService => 'من خدمتك';

  @override
  String get itemSourceManual => 'أدخلته أنت';

  @override
  String itemPredictedValue(String date) {
    return 'نحو $date حسب استخدامك المعتاد';
  }

  @override
  String itemPoints(String points) {
    return '$points نقاط';
  }

  @override
  String get itemNone => 'لا شيء';

  @override
  String get itemNotYet => 'ليس بعد';

  @override
  String get itemMarkDone => 'تحديد كمنجز';

  @override
  String get itemSnooze => 'تأجيل';

  @override
  String get itemReschedule => 'تغيير الموعد';

  @override
  String get itemSnoozeTitle => 'تأجيل التذكيرات';

  @override
  String itemSnoozeDays(int count) {
    return '$count يومًا';
  }

  @override
  String get itemSnoozeOverdueNote =>
      'تتوقف التذكيرات، لكن المؤشر يظل يحتسب هذا البند متأخرًا.';

  @override
  String get itemRescheduleNote =>
      'لهذه المرة فقط. التذكيرات اللاحقة تتبع الفترة المعتادة.';

  @override
  String itemRescheduledToast(String date) {
    return 'نُقل الموعد إلى $date';
  }

  @override
  String get itemEditInterval => 'تعديل الفترة';

  @override
  String get itemNotApplicableToggle => 'لا ينطبق على سيارتي';

  @override
  String get itemNotApplicableHint => 'يُخفى من المؤشر والتذكيرات';

  @override
  String get itemSetLastDone => 'تحديد آخر مرة';

  @override
  String get itemLastDoneSaved => 'تم حفظ آخر مرة';

  @override
  String get itemLastDoneNeedOne => 'أدخل تاريخًا أو مسافة';

  @override
  String get itemHistoryTitle => 'سجل الخدمات';

  @override
  String get itemHistoryEmpty => 'لم تُسجَّل خدمات لهذا البند بعد.';

  @override
  String get actionUndo => 'تراجع';

  @override
  String get itemNotFound => 'هذا البند لم يعد موجودًا';

  @override
  String get intervalEditTitle => 'تعديل الفترة';

  @override
  String get customNameLabel => 'الاسم';

  @override
  String get customNameRequired => 'أدخل اسمًا';

  @override
  String get intervalMonthsLabel => 'كل … شهر';

  @override
  String intervalDistanceLabel(String unit) {
    return 'كل … $unit';
  }

  @override
  String get intervalMonthsUnit => 'شهر';

  @override
  String get intervalNote =>
      'أيهما يأتي أولًا. اترك أحدهما فارغًا لاستخدام الآخر فقط.';

  @override
  String get intervalNeedOne => 'حدّد فترة واحدة على الأقل.';

  @override
  String get intervalAboveZero => 'يجب أن يكون أكبر من 0';

  @override
  String get importanceLabel => 'الأهمية';

  @override
  String get severityCritical => 'حرج';

  @override
  String get severityMajor => 'رئيسي';

  @override
  String get severityMinor => 'ثانوي';

  @override
  String importanceHelper(String points) {
    return 'عند التأخر: $points';
  }

  @override
  String get customLastDoneTitle => 'آخر مرة (اختياري)';

  @override
  String intervalTypical(String interval) {
    return 'المعتاد: $interval';
  }

  @override
  String get intervalUpdated => 'تم تحديث الفترة';

  @override
  String customItemAdded(String name) {
    return 'تمت إضافة $name';
  }

  @override
  String get discardChangesTitle => 'تجاهل التغييرات؟';

  @override
  String get templateUpdateBanner => 'تم تحديث الفترات المعتادة';

  @override
  String get templateUpdateReview => 'مراجعة';

  @override
  String get templateUpdateTitle => 'تم تحديث الفترات المعتادة';

  @override
  String get templateUpdateDefaultSummary => 'تغيّرت بعض الفترات المعتادة.';

  @override
  String templateUpdateMonths(int from, int to) {
    String _temp0 = intl.Intl.pluralLogic(
      to,
      locale: localeName,
      other: 'شهرًا',
      few: 'أشهر',
      two: 'شهرين',
      one: 'شهر',
    );
    return 'كل $from ← $to $_temp0';
  }

  @override
  String templateUpdateDistance(String from, String to) {
    return '$from ← $to';
  }

  @override
  String templateUpdateSeverity(String from, String to) {
    return 'الأهمية: $from ← $to';
  }

  @override
  String templateUpdateNewItem(String interval) {
    return 'بند جديد · $interval';
  }

  @override
  String get templateUpdateKept => 'محفوظ: عدّلته بنفسك';

  @override
  String templateUpdateNote(int version) {
    return 'راجعها ميكانيكي مؤهل · النسخة $version';
  }

  @override
  String get templateUpdateApply => 'تطبيق';

  @override
  String get templateUpdateKeep => 'الإبقاء على الحالي';

  @override
  String get templateUpdateApplied => 'تم تحديث الجدول';

  @override
  String get templateUpdateMenu => 'مراجعة الفترات المحدّثة';

  @override
  String get templateUpdateBadge => 'فترات محدّثة';

  @override
  String get templateUpdateNothingToApply =>
      'عدّلت كل البنود التي تغيّرت، لذلك لن يتغيّر شيء.';

  @override
  String nextServiceOverdueDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'متأخر $count يومًا',
      few: 'متأخر $count أيام',
      two: 'متأخر يومين',
      one: 'متأخر يومًا واحدًا',
    );
    return '$_temp0';
  }

  @override
  String nextServiceInDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بعد $count يومًا',
      few: 'بعد $count أيام',
      two: 'بعد يومين',
      one: 'غدًا',
      zero: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String nextServiceInKm(String distance) {
    return 'بعد نحو $distance';
  }

  @override
  String get nextServiceKmNote =>
      'حدّث قراءة العداد من حين لآخر ليظهر لك موعد الصيانة.';

  @override
  String get nextServiceDueAround => 'مستحق في الفترة نفسها';

  @override
  String get nextServiceDoNow => 'للإنجاز الآن';

  @override
  String get nextServiceLog => 'تسجيل صيانة';

  @override
  String get nextServiceSeeSchedule => 'عرض الجدول كاملًا';

  @override
  String get nextServiceNothing =>
      'لا شيء مستحق بعد. حدّد متى أُنجزت البنود آخر مرة لترى موعد صيانتك القادمة.';

  @override
  String nextServiceSemantic(String title, String value, String detail) {
    return '$title: $value، $detail';
  }

  @override
  String get spendTitle => 'المصروفات';

  @override
  String get spendPreviousYear => 'السنة السابقة';

  @override
  String get spendNextYear => 'السنة التالية';

  @override
  String spendServicesInYear(int count, String year) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صيانة في $year',
      few: '$count صيانات في $year',
      two: 'صيانتان في $year',
      one: 'صيانة واحدة في $year',
      zero: 'لا صيانات في $year',
    );
    return '$_temp0';
  }

  @override
  String get spendOtherCurrencies => 'السجلات بعملات أخرى غير مشمولة.';

  @override
  String get spendChangeCurrency => 'تغيير العملة';

  @override
  String get spendRecords => 'السجلات';

  @override
  String get spendNotInTotal => 'خارج الإجمالي';

  @override
  String spendEmpty(String year) {
    return 'لا تكاليف مسجلة في $year';
  }

  @override
  String spendTotalSemantic(String year, String amount, String count) {
    return 'إجمالي $year: $amount، $count';
  }

  @override
  String get actionLogService => 'تسجيل صيانة';

  @override
  String get serviceTypeMaintenance => 'صيانة دورية';

  @override
  String get serviceTypeRepair => 'إصلاح';

  @override
  String get serviceTypeInspection => 'فحص';

  @override
  String get serviceTypeOther => 'أخرى';

  @override
  String serviceRecordSemantic(
    String date,
    String title,
    String detail,
    String cost,
  ) {
    return '$date، $title، $detail، $cost';
  }

  @override
  String get historyTitle => 'السجل';

  @override
  String historyYearChip(String year) {
    return 'السنة: $year';
  }

  @override
  String get historyAllYears => 'كل السنوات';

  @override
  String historyTypeChip(String type) {
    return 'النوع: $type';
  }

  @override
  String get historyAllTypes => 'الكل';

  @override
  String get historyClear => 'مسح';

  @override
  String get historyChooseYear => 'السنة';

  @override
  String get historyChooseType => 'النوع';

  @override
  String historyVehicleChip(String name) {
    return 'المركبة: $name. تغيير المركبة';
  }

  @override
  String get historyEmptyTitle => 'لا صيانات بعد';

  @override
  String get historyEmptyBody => 'سجّل أول صيانة لتبدأ سجل سيارتك.';

  @override
  String get historyNoMatch => 'لا صيانات تطابق عوامل التصفية';

  @override
  String get historyClearFilters => 'مسح عوامل التصفية';

  @override
  String get historySelectRecord => 'اختر سجلًا لعرضه هنا.';

  @override
  String get historyLoading => 'جارٍ تحميل السجل';

  @override
  String get recordFactOdometer => 'العداد';

  @override
  String get recordFactCost => 'التكلفة';

  @override
  String get recordFactShop => 'الورشة';

  @override
  String get recordItemsTitle => 'البنود المشمولة';

  @override
  String get recordNoItems => 'لا بنود من الجدول. لم تتم إعادة ضبط أي شيء.';

  @override
  String get recordNotesTitle => 'ملاحظات';

  @override
  String get recordNoNotes => 'لا ملاحظات';

  @override
  String recordAdded(String dateTime) {
    return 'أُضيفت $dateTime';
  }

  @override
  String get recordDeleteTitle => 'حذف هذه الصيانة؟';

  @override
  String recordDeleteBodyItems(String items) {
    return 'ستعود $items إلى تواريخها السابقة.';
  }

  @override
  String get recordDeleteBodyNone => 'ستُحذف من السجل والمصروفات.';

  @override
  String get recordDeleted => 'تم حذف الصيانة';

  @override
  String get recordGone => 'تم حذف هذه الصيانة.';

  @override
  String recordItemSemantic(String name) {
    return '$name. فتح البند';
  }

  @override
  String listAnd(String first, String last) {
    return '$first و$last';
  }

  @override
  String get logTitle => 'تسجيل صيانة';

  @override
  String get logEditTitle => 'تعديل الصيانة';

  @override
  String logFor(String name) {
    return 'للمركبة: $name';
  }

  @override
  String get logChooseVehicle => 'اختر المركبة';

  @override
  String get logDate => 'التاريخ';

  @override
  String get logOdometer => 'العداد';

  @override
  String logOdometerCurrent(String value) {
    return 'الحالي: $value';
  }

  @override
  String get logOdometerRequired => 'أدخل قراءة العداد.';

  @override
  String get logWhatDone => 'ما الذي تم إنجازه؟';

  @override
  String get logAddCustom => 'إضافة بند مخصص';

  @override
  String logChipSemantic(String name, String status) {
    return '$name، $status';
  }

  @override
  String get logType => 'النوع';

  @override
  String get logCost => 'التكلفة (اختياري)';

  @override
  String get logCostInvalid => 'أدخل مبلغًا مثل 120 أو 120.50.';

  @override
  String get logCostNegative => 'لا يمكن أن تكون التكلفة سالبة.';

  @override
  String logCostDecimals(String currency, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تستخدم $currency $count خانات عشرية.',
      two: 'تستخدم $currency خانتين عشريتين.',
      one: 'تستخدم $currency خانة عشرية واحدة.',
      zero: 'لا تستخدم $currency كسورًا عشرية.',
    );
    return '$_temp0';
  }

  @override
  String get logCurrency => 'العملة';

  @override
  String logCurrencyButton(String code) {
    return 'العملة: $code. تغيير';
  }

  @override
  String get logShop => 'الورشة (اختياري)';

  @override
  String get logNotes => 'ملاحظات (اختياري)';

  @override
  String get logSave => 'حفظ الصيانة';

  @override
  String get logDiscardTitle => 'تجاهل هذه الصيانة؟';

  @override
  String logSaved(int score) {
    return 'تم حفظ الصيانة · التقييم الآن $score';
  }

  @override
  String logSavedKept(int count, String items) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم الحفظ في السجل. تحتفظ $items بتواريخها الأحدث.',
      one: 'تم الحفظ في السجل. يحتفظ $items بتاريخه الأحدث.',
    );
    return '$_temp0';
  }

  @override
  String get addLogServiceSub => 'سجّل الأعمال التي أُنجزت على سيارتك';

  @override
  String get addAddVehicleSub => 'أضف سيارة أخرى إلى الكراج';

  @override
  String get profileTitle => 'الحساب';

  @override
  String get profileGuestTitle => 'كراجك موجود على هذا الهاتف فقط';

  @override
  String get profileGuestBody =>
      'إذا حذفت التطبيق أو فقدت هاتفك، ستضيع بياناتك.';

  @override
  String get profileBackUp => 'احفظ نسخة من كراجك';

  @override
  String get profileSignIn => 'تسجيل الدخول';

  @override
  String profileSyncedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت المزامنة قبل $count دقيقة',
      few: 'تمت المزامنة قبل $count دقائق',
      two: 'تمت المزامنة قبل دقيقتين',
      one: 'تمت المزامنة قبل دقيقة',
      zero: 'تمت المزامنة الآن',
    );
    return '$_temp0';
  }

  @override
  String profileSyncedAt(String date) {
    return 'تمت المزامنة $date';
  }

  @override
  String profileWaitingSync(int count) {
    return 'بانتظار المزامنة ($count)';
  }

  @override
  String get profileOffline => 'غير متصل';

  @override
  String get profileVerifyEmail =>
      'أكّد بريدك الإلكتروني لإكمال النسخ الاحتياطي';

  @override
  String get profileResendEmail => 'إعادة إرسال الرسالة';

  @override
  String get profileVerificationSent => 'تم إرسال رسالة التأكيد';

  @override
  String profileAccountSemantic(String name, String email, String sync) {
    return '$name، $email، $sync. تفاصيل الحساب';
  }

  @override
  String get profileEnableReminders => 'تفعيل التذكيرات';

  @override
  String get profileEnableRemindersBody => 'احصل على تذكير قبل موعد الاستحقاق.';

  @override
  String get profileGarage => 'الكراج';

  @override
  String get profileVehicles => 'المركبات';

  @override
  String get profilePreferences => 'التفضيلات';

  @override
  String get profileCountry => 'الدولة';

  @override
  String get profileNotSet => 'غير محددة';

  @override
  String get profileDistanceUnit => 'وحدة المسافة';

  @override
  String get profileKilometres => 'كيلومتر';

  @override
  String get profileMiles => 'ميل';

  @override
  String get profileCurrency => 'العملة';

  @override
  String get profileLanguage => 'اللغة';

  @override
  String get profileDigits => 'الأرقام';

  @override
  String get profileDigitsWestern => 'غربية 0-9';

  @override
  String get profileDigitsArabic => 'هندية ٠-٩';

  @override
  String get profileNotifications => 'الإشعارات';

  @override
  String get profileReminders => 'التذكيرات';

  @override
  String get profileOn => 'مفعّلة';

  @override
  String get profileOff => 'متوقفة';

  @override
  String get profilePrivacy => 'الخصوصية';

  @override
  String get profileAnalytics => 'تحليلات الاستخدام';

  @override
  String get profileAnalyticsSub => 'مجهولة الهوية. بلا إعلانات.';

  @override
  String get profilePrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get profileTerms => 'شروط الاستخدام';

  @override
  String get profileHelp => 'المساعدة';

  @override
  String get profileFaq => 'الأسئلة الشائعة';

  @override
  String get profileContact => 'التواصل مع الدعم';

  @override
  String get profileSupportPromise =>
      'نرد خلال يومي عمل (من الأحد إلى الخميس، بتوقيت القاهرة)';

  @override
  String get profileAccountActions => 'الحساب';

  @override
  String get profileSignOut => 'تسجيل الخروج';

  @override
  String get profileDeleteAccount => 'حذف الحساب';

  @override
  String get profileEraseData => 'مسح كل البيانات';

  @override
  String get profileSignOutTitle => 'تسجيل الخروج؟';

  @override
  String get profileSignOutBody =>
      'يبقى كراجك في حسابك. سجّل الدخول مجددًا في أي وقت لاستعادته.';

  @override
  String get profileUnsyncedTitle => 'بعض التغييرات لم تتم مزامنتها';

  @override
  String profileUnsyncedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تغييرًا على هذا الهاتف لم تصل إلى حسابك بعد.',
      few: '$count تغييرات على هذا الهاتف لم تصل إلى حسابك بعد.',
      two: 'تغييران على هذا الهاتف لم يصلا إلى حسابك بعد.',
      one: 'تغيير واحد على هذا الهاتف لم يصل إلى حسابك بعد.',
    );
    return '$_temp0';
  }

  @override
  String get profileSyncNow => 'المزامنة الآن';

  @override
  String get profileDiscardSignOut => 'تجاهلها وتسجيل الخروج';

  @override
  String get profileSignedOut => 'تم تسجيل الخروج';

  @override
  String profileVersion(String name, String version, String build) {
    return '$name $version ($build)';
  }

  @override
  String get profileSelectSetting => 'اختر إعدادًا لعرضه هنا.';

  @override
  String profileValueSemantic(String title, String value) {
    return '$title، $value';
  }

  @override
  String get regionSwitchBothTitle => 'تغيير العملة والوحدات أيضًا؟';

  @override
  String get regionSwitchCurrencyTitle => 'تغيير العملة أيضًا؟';

  @override
  String get regionSwitchUnitTitle => 'تغيير الوحدات أيضًا؟';

  @override
  String regionSwitchBoth(String currency, String unit) {
    return 'تغيير العملة إلى $currency والمسافة إلى $unit؟';
  }

  @override
  String regionSwitchCurrency(String currency) {
    return 'تغيير العملة إلى $currency؟';
  }

  @override
  String regionSwitchUnit(String unit) {
    return 'تغيير المسافة إلى $unit؟';
  }

  @override
  String get regionSwitch => 'تغيير';

  @override
  String get regionKeep => 'الإبقاء على الحالي';

  @override
  String regionPopularUpdated(String country) {
    return 'تم تحديث العلامات الشائعة لـ$country';
  }

  @override
  String get regionPopularDefault =>
      'تم تعيين العلامات الشائعة إلى القائمة الافتراضية';

  @override
  String get unitKmOption => 'كيلومتر (كم)';

  @override
  String get unitMiOption => 'ميل';

  @override
  String get unitCaption => 'تُحوَّل قراءاتك بدقة. لا يضيع شيء عند التبديل.';

  @override
  String get currencyCaption =>
      'تستخدم السجلات الجديدة هذه العملة. وتحتفظ السجلات الحالية بعملتها.';

  @override
  String get currencySuggested => 'مقترحة';

  @override
  String get currencyAll => 'كل العملات';

  @override
  String get currencySearchHint => 'ابحث عن عملة';

  @override
  String currencyNoResults(String query) {
    return 'لا توجد عملات تطابق \"$query\"';
  }

  @override
  String get languageTitle => 'اللغة والأرقام';

  @override
  String languageDevice(String language) {
    return 'مثل الجهاز ($language)';
  }

  @override
  String get digitsWesternOption => 'غربية (0 1 2 3)';

  @override
  String digitsArabicOption(String digits) {
    return 'هندية ($digits)';
  }

  @override
  String get digitsCaption =>
      'أرقام الهيكل واللوحات والعداد تظهر دائمًا بالأرقام الغربية.';

  @override
  String get notifOffInSettings => 'الإشعارات متوقفة في إعدادات هاتفك.';

  @override
  String get notifOpenSettings => 'فتح الإعدادات';

  @override
  String get notifNotAsked => 'اسمح بالإشعارات لتصلك التذكيرات.';

  @override
  String get notifAllow => 'السماح';

  @override
  String get notifServiceReminders => 'تذكيرات الصيانة';

  @override
  String get notifServiceRemindersSub =>
      'تذكيرات الاستحقاق والتأخير وقراءة العداد';

  @override
  String get notifSchedule =>
      'تصل التذكيرات الساعة 9:00، قبل الاستحقاق بـ30 و7 أيام ويوم واحد. وتتبعها تذكيرات التأخير في الأيام 1 و3 و7 و14، ثم شهريًا للفرامل والإطارات وزيت الفرامل.';

  @override
  String get authBackupTitle => 'احفظ كراجك وزامنه';

  @override
  String get authWelcomeTitle => 'مرحبًا بعودتك';

  @override
  String get authBody => 'استخدم حسابك على أي جهاز. تبقى بياناتك خاصة.';

  @override
  String get authApple => 'المتابعة باستخدام Apple';

  @override
  String get authGoogle => 'المتابعة باستخدام Google';

  @override
  String get authEmail => 'المتابعة بالبريد الإلكتروني';

  @override
  String get authTerms => 'الشروط';

  @override
  String get authPrivacy => 'سياسة الخصوصية';

  @override
  String get authEmailTitle => 'بريدك الإلكتروني';

  @override
  String get authEmailLabel => 'البريد الإلكتروني';

  @override
  String get authEmailInvalid => 'أدخل بريدًا إلكترونيًا صحيحًا.';

  @override
  String get authCreatePasswordTitle => 'أنشئ كلمة مرور';

  @override
  String get authEnterPasswordTitle => 'أدخل كلمة المرور';

  @override
  String get authPasswordLabel => 'كلمة المرور';

  @override
  String get authShowPassword => 'إظهار كلمة المرور';

  @override
  String get authHidePassword => 'إخفاء كلمة المرور';

  @override
  String get authPasswordHint => '8 أحرف على الأقل';

  @override
  String get authCreateAccount => 'إنشاء الحساب';

  @override
  String get authSignIn => 'تسجيل الدخول';

  @override
  String get authForgot => 'نسيت كلمة المرور؟';

  @override
  String get authWrongPassword => 'كلمة المرور غير صحيحة.';

  @override
  String get authTooMany => 'محاولات كثيرة. حاول مجددًا بعد 5 دقائق.';

  @override
  String get authOffline => 'تحتاج إلى اتصال لتسجيل الدخول.';

  @override
  String get authResetTitle => 'إعادة تعيين كلمة المرور';

  @override
  String authResetBody(String email) {
    return 'سنرسل رابط إعادة التعيين إلى $email.';
  }

  @override
  String get authSendLink => 'إرسال الرابط';

  @override
  String get authResetSentTitle => 'تفقّد بريدك';

  @override
  String get authResetSentBody =>
      'افتح الرابط في الرسالة لاختيار كلمة مرور جديدة.';

  @override
  String get authVerifyTitle => 'تفقّد بريدك لتأكيد حسابك.';

  @override
  String authVerifyBody(String email) {
    return 'أرسلنا رابطًا إلى $email. يبقى كراجك على هذا الهاتف حتى تؤكد بريدك.';
  }

  @override
  String get authResend => 'إعادة الإرسال';

  @override
  String authResendIn(int seconds) {
    return 'إعادة الإرسال بعد $seconds ث';
  }

  @override
  String get authOpenMail => 'فتح تطبيق البريد';

  @override
  String get authVerificationSent => 'تم إرسال رسالة التأكيد';

  @override
  String get authSignedIn => 'تم تسجيل الدخول';

  @override
  String get authLegal => 'بالمتابعة، أنت توافق على الشروط وسياسة الخصوصية.';

  @override
  String get backupBenefitHistory => 'احتفظ بسجلّك إذا فقدت هاتفك';

  @override
  String get backupBenefitDevices => 'استخدمه على الآيباد أيضًا';

  @override
  String get backupBenefitPrivate => 'خاص بك. بلا إعلانات.';

  @override
  String get backupWarning => 'بياناتك الآن موجودة على هذا الهاتف فقط.';

  @override
  String get backupNow => 'احفظ نسخة الآن';

  @override
  String get backupNotNow => 'ليس الآن';

  @override
  String backupVehicles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مركبة',
      few: '$count مركبات',
      two: 'مركبتين',
      one: 'مركبة واحدة',
    );
    return '$_temp0';
  }

  @override
  String backupRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سجلًا',
      few: '$count سجلات',
      two: 'سجلين',
      one: 'سجل واحد',
    );
    return '$_temp0';
  }

  @override
  String backupProgress(String vehicles, String records) {
    return 'جارٍ حفظ $vehicles و$records…';
  }

  @override
  String backupPercent(String percent) {
    return '$percent٪';
  }

  @override
  String get backupWaiting => 'بانتظار الاتصال… بياناتك آمنة على هذا الهاتف.';

  @override
  String get backupFailedTitle => 'لم يكتمل النسخ الاحتياطي';

  @override
  String get backupFailedBody => 'ما زالت بياناتك آمنة على هذا الهاتف.';

  @override
  String get backupDoneTitle => 'تم حفظ نسخة من كراجك';

  @override
  String get backupDone => 'تم';

  @override
  String get mergeTitle => 'هذا الحساب لديه كراج بالفعل';

  @override
  String get mergeOption => 'دمج في هذا الحساب';

  @override
  String mergeOptionBody(String device, String account) {
    return 'يضيف $device من هذا الهاتف إلى $account في حسابك.';
  }

  @override
  String get mergeRecommended => 'مقترح';

  @override
  String get discardOption => 'تجاهل بيانات هذا الهاتف';

  @override
  String discardOptionBody(String device) {
    return 'يحذف $device من هذا الهاتف ويحمّل حسابك.';
  }

  @override
  String get discardDialogTitle => 'تجاهل بيانات هذا الهاتف؟';

  @override
  String discardDialogBody(String word) {
    return 'لا يمكن التراجع عن هذا. اكتب $word للتأكيد.';
  }

  @override
  String get discardWord => 'تجاهل';

  @override
  String get discardConfirm => 'تجاهل';

  @override
  String get discardDone => 'يعرض هذا الهاتف الآن كراج حسابك';

  @override
  String get limitTitle => 'اختر ما تريد نقله';

  @override
  String get limitBody =>
      'يتسع الحساب لـ25 مركبة. المركبات التي لا تنقلها تُحذف من هذا الهاتف.';

  @override
  String limitCounter(int allowed, int total) {
    return 'يمكنك نقل $allowed من $total';
  }

  @override
  String get dupTitle => 'تبدو هذه السيارة نفسها';

  @override
  String get dupBody => 'يتم الاحتفاظ بالاثنتين. احذف إحداهما إن كانت مكررة.';

  @override
  String get dupRemove => 'حذف نسخة هذا الهاتف';

  @override
  String get dupOnPhone => 'على هذا الهاتف';

  @override
  String get dupInAccount => 'في حسابك';

  @override
  String get eraseDeleteTitle => 'حذف الحساب';

  @override
  String get eraseEraseTitle => 'مسح كل البيانات';

  @override
  String get eraseOwnerDevices =>
      'تُحذف مركباتك وسجلّك وإعداداتك من كل الأجهزة.';

  @override
  String get eraseOwnerBackups => 'تُمسح النسخ الاحتياطية خلال 30 يومًا.';

  @override
  String get eraseOwnerFinal => 'لا يمكن التراجع عن هذا.';

  @override
  String get eraseGuest => 'يُمسح كل ما على هذا الهاتف فورًا.';

  @override
  String eraseTypeToConfirm(String word) {
    return 'اكتب $word للتأكيد';
  }

  @override
  String get eraseDeleteWord => 'حذف';

  @override
  String get eraseEraseWord => 'مسح';

  @override
  String get eraseOffline => 'تحتاج إلى اتصال لحذف حسابك.';

  @override
  String get reauthTitle => 'أكّد هويتك';

  @override
  String get reauthBody => 'لحمايتك، سجّل الدخول مرة أخرى قبل حذف حسابك.';

  @override
  String reauthAccount(String email) {
    return 'مسجّل الدخول باسم $email';
  }

  @override
  String get reauthOr => 'أو استخدم كلمة المرور';

  @override
  String get reauthConfirm => 'تأكيد';

  @override
  String get helpTitle => 'المساعدة';

  @override
  String get helpSearch => 'ابحث في المساعدة';

  @override
  String get helpTopics => 'المواضيع';

  @override
  String get helpCatGettingStarted => 'البدء';

  @override
  String get helpCatHealthScore => 'نقاط الصحة';

  @override
  String get helpCatReminders => 'التذكيرات';

  @override
  String get helpCatBackup => 'النسخ الاحتياطي والمزامنة';

  @override
  String get helpCatPrivacy => 'الخصوصية';

  @override
  String helpQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سؤالًا',
      few: '$count أسئلة',
      two: 'سؤالان',
      one: 'سؤال واحد',
    );
    return '$_temp0';
  }

  @override
  String get helpOffline =>
      'نعرض الإجابات المحفوظة. اتصل بالإنترنت لمركز المساعدة الكامل.';

  @override
  String helpResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إجابة',
      few: '$count إجابات',
      two: 'إجابتان',
      one: 'إجابة واحدة',
    );
    return '$_temp0';
  }

  @override
  String helpNoResults(String query) {
    return 'لا توجد إجابات عن «$query»';
  }

  @override
  String get helpNoResultsHint => 'جرّب كلمات أخرى، أو راسلنا أدناه.';

  @override
  String get helpContactTitle => 'تواصل معنا';

  @override
  String get helpContactLanguage => 'نرد باللغة التي تكتب بها.';

  @override
  String get helpEmailSubject => 'دعم TDC-mena Garage';

  @override
  String get helpEmailCopied => 'تم نسخ البريد الإلكتروني';

  @override
  String get helpEmailHint => 'يفتح تطبيق البريد';

  @override
  String get helpLegal => 'الشؤون القانونية';

  @override
  String get helpStillNeed => 'ما زلت تحتاج إلى مساعدة؟';

  @override
  String legalLoadsFrom(String address) {
    return 'تُحمَّل هذه الصفحة من $address في المتصفح داخل التطبيق.';
  }

  @override
  String get editVehicleTitle => 'تعديل المركبة';

  @override
  String get editBrand => 'العلامة التجارية';

  @override
  String get editModel => 'الطراز';

  @override
  String get editSaved => 'تم حفظ التغييرات';

  @override
  String get editDeleteVehicle => 'حذف المركبة';

  @override
  String editOdometerLower(String mileage) {
    return 'لا يمكن أن يكون أقل من آخر قراءة ($mileage). صحّحها من سجل العداد.';
  }

  @override
  String fuelChangeTitle(String fuel) {
    return 'تحديث جدول الصيانة لـ$fuel؟';
  }

  @override
  String get fuelChangeBody =>
      'سنستبدل البنود المعتادة. تبقى بنودك المخصصة وسجلّك.';

  @override
  String get fuelChangeUpdate => 'تحديث الجدول';

  @override
  String get fuelChangeKeep => 'الإبقاء على الجدول الحالي';

  @override
  String get fuelChangeKeepIntervals => 'الإبقاء على الفترات التي عدّلتها';

  @override
  String deleteVehicleBodyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'سيتم حذف جدول الصيانة الخاص بها و$count سجل خدمة. لا يمكن التراجع عن ذلك.',
      few:
          'سيتم حذف جدول الصيانة الخاص بها و$count سجلات خدمة. لا يمكن التراجع عن ذلك.',
      two: 'سيتم حذف جدول الصيانة الخاص بها وسجلَي خدمة. لا يمكن التراجع عن ذلك.',
      one: 'سيتم حذف جدول الصيانة الخاص بها وسجل خدمة واحد. لا يمكن التراجع عن ذلك.',
      zero: 'سيتم حذف جدول الصيانة الخاص بها. لا يمكن التراجع عن ذلك.',
    );
    return '$_temp0';
  }

  @override
  String get alertMileageReview => 'تحقق من قراءة العداد';

  @override
  String get reviewTitle => 'تحقق من هذه القراءة';

  @override
  String get reviewBody => 'قراءة من جهازك الآخر أقل من قراءة سابقة.';

  @override
  String get reviewNeedsReview => 'بحاجة إلى مراجعة';

  @override
  String get reviewThisDevice => 'هذا الجهاز';

  @override
  String reviewUseCorrection(String value) {
    return 'استخدام $value كتصحيح';
  }

  @override
  String reviewDelete(String value) {
    return 'حذف $value';
  }

  @override
  String get reviewCorrected => 'تم الحفظ كتصحيح';

  @override
  String reviewCardSemantic(String value, String date, String device) {
    return '$value، $date، $device';
  }

  @override
  String get offlineTitle => 'أنت غير متصل';

  @override
  String get errorGeneric => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get actionRetryShort => 'إعادة المحاولة';

  @override
  String get loading => 'جارٍ التحميل';

  @override
  String get syncSyncing => 'جارٍ المزامنة';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تغييرًا بانتظار المزامنة',
      few: '$count تغييرات بانتظار المزامنة',
      two: 'تغييران بانتظار المزامنة',
      one: 'تغيير واحد بانتظار المزامنة',
    );
    return '$_temp0';
  }

  @override
  String get syncOffline => 'غير متصل. ستتم مزامنة التغييرات عند عودة الاتصال.';

  @override
  String get syncNeedsReview => 'قراءة عداد بحاجة إلى مراجعة';

  @override
  String get updateTitle => 'التحديث مطلوب';

  @override
  String get updateBody => 'هذا الإصدار لم يعد مدعومًا.';

  @override
  String get updateSafe => 'بياناتك على هذا الهاتف آمنة.';

  @override
  String get updateAction => 'تحديث';

  @override
  String notifDays(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n يومًا',
      few: '$n أيام',
      two: 'يومين',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String notifDueIn(String item, String days) {
    return '$item مستحق خلال $days';
  }

  @override
  String notifDueTomorrow(String item) {
    return '$item مستحق غدًا';
  }

  @override
  String notifOverdue(String item, String days) {
    return '$item متأخر $days';
  }

  @override
  String notifBundle(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n عنصرًا تحتاج انتباهك',
      few: '$n عناصر تحتاج انتباهك',
      two: 'عنصران يحتاجان انتباهك',
    );
    return '$_temp0';
  }

  @override
  String get notifMileageTitle => 'حدّث قراءة العداد';

  @override
  String notifMileageBody(String days, String seconds) {
    return 'مرّ $days. يستغرق التحديث $seconds ثوانٍ.';
  }
}
