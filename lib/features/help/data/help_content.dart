import '../domain/help_article.dart';

/// The FAQ until the help centre is live (NFR-SUP-07). Articles marked
/// `bundled` are the short copy that ships with the app (BR-SET-03).
const helpArticles = <HelpArticle>[
  // Getting started.
  HelpArticle(
    id: 'add-vehicle',
    category: HelpCategory.gettingStarted,
    bundled: true,
    questionEn: 'How do I add another vehicle?',
    questionAr: 'كيف أضيف مركبة أخرى؟',
    answerEn:
        'Tap Add in the navigation bar, then Add vehicle. Choose the brand and model, then enter the fuel type and '
        'mileage.\n\nFinally, set when each main item was last done, or choose "My car is new". You can keep up to 25 '
        'vehicles.',
    answerAr:
        'اضغط إضافة في شريط التنقل، ثم إضافة مركبة. اختر العلامة التجارية والطراز، ثم أدخل نوع الوقود والعداد.\n\n'
        'أخيرًا، حدّد متى تمت آخر صيانة لكل بند رئيسي، أو اختر «سيارتي جديدة». يمكنك الاحتفاظ بما يصل إلى 25 مركبة.',
  ),
  HelpArticle(
    id: 'not-sure',
    category: HelpCategory.gettingStarted,
    bundled: true,
    questionEn: "What if I don't know when something was last done?",
    questionAr: 'ماذا لو لم أعرف متى تمت آخر صيانة لبند ما؟',
    answerEn:
        'Choose "I don\'t know". The item shows as Unknown and doesn\'t lower the health score.\n\nWhen you find out, open '
        'the item and set the date.',
    answerAr: 'اختر «لا أعرف». يظهر البند كغير معروف ولا يخفض نقاط الصحة.\n\nعندما تعرف التاريخ، افتح البند وحدّده.',
  ),
  HelpArticle(
    id: 'units',
    category: HelpCategory.gettingStarted,
    questionEn: 'Can I use miles or another currency?',
    questionAr: 'هل يمكنني استخدام الأميال أو عملة أخرى؟',
    answerEn:
        'Yes. In Profile, choose Distance unit or Currency.\n\nChanging the unit changes how distances are shown; '
        'your records stay the same. Each cost keeps the currency it was logged in.',
    answerAr:
        'نعم. من الحساب، اختر وحدة المسافة أو العملة.\n\nتغيير الوحدة يغيّر طريقة عرض المسافات فقط، وتبقى سجلاتك كما هي. '
        'وتحتفظ كل تكلفة بالعملة التي سُجّلت بها.',
  ),

  // Health score.
  HelpArticle(
    id: 'score',
    category: HelpCategory.healthScore,
    bundled: true,
    questionEn: 'How is the health score worked out?',
    questionAr: 'كيف تُحسب نقاط الصحة؟',
    answerEn:
        'It starts at 100. Each overdue item takes points off, more for safety items such as brakes and tires. Items '
        'due soon take off a little.\n\nTap the score on the Garage screen to see every deduction.',
    answerAr:
        'تبدأ من 100. كل بند متأخر يخصم نقاطًا، وأكثر لبنود السلامة مثل المكابح والإطارات. والبنود المستحقة قريبًا تخصم '
        'قليلًا.\n\nاضغط على النقاط في شاشة الكراج لترى كل خصم.',
  ),
  HelpArticle(
    id: 'raise-score',
    category: HelpCategory.healthScore,
    bundled: true,
    questionEn: 'How do I raise my score?',
    questionAr: 'كيف أرفع نقاطي؟',
    answerEn:
        "Log the services you've had done. Logging a service resets the items it covered, and the score updates "
        'straight away.',
    answerAr: 'سجّل الصيانات التي أجريتها. تسجيل الصيانة يعيد ضبط البنود التي شملتها، وتتحدث النقاط فورًا.',
  ),
  HelpArticle(
    id: 'unknown-items',
    category: HelpCategory.healthScore,
    questionEn: "Why don't unknown items count?",
    questionAr: 'لماذا لا تُحتسب البنود غير المعروفة؟',
    answerEn: 'We only score what we know. Set the last service date and the item joins the score.',
    answerAr: 'نحتسب فقط ما نعرفه. حدّد تاريخ آخر صيانة وسيدخل البند في النقاط.',
  ),

  // Reminders.
  HelpArticle(
    id: 'no-reminders',
    category: HelpCategory.reminders,
    bundled: true,
    questionEn: "I'm not getting reminders",
    questionAr: 'لا تصلني التذكيرات',
    answerEn:
        "Check two switches: Reminders in Profile, and notifications for TDC-mena Garage in your phone's Settings. "
        'Both must be on.',
    answerAr:
        'تحقق من مفتاحين: التذكيرات في الحساب، والإشعارات لتطبيق TDC-mena Garage في إعدادات هاتفك. يجب تشغيل الاثنين.',
  ),
  HelpArticle(
    id: 'reminder-timing',
    category: HelpCategory.reminders,
    questionEn: 'When do reminders arrive?',
    questionAr: 'متى تصل التذكيرات؟',
    answerEn:
        "Before an item is due, on the day it's due, and then less often while it stays overdue.\n\nYou can turn "
        'reminders off at any time in Profile, then Reminders.',
    answerAr:
        'قبل موعد البند، وفي يوم استحقاقه، ثم على فترات أطول ما دام متأخرًا.\n\nيمكنك إيقاف التذكيرات في أي وقت من الحساب، '
        'ثم التذكيرات.',
  ),

  // Backup & sync.
  HelpArticle(
    id: 'need-account',
    category: HelpCategory.backupSync,
    bundled: true,
    questionEn: 'Do I need an account?',
    questionAr: 'هل أحتاج إلى حساب؟',
    answerEn:
        'No. Everything works without one, but your garage is then only on this phone.\n\nAn account backs it up and '
        'lets you use it on your iPad too.',
    answerAr: 'لا. كل شيء يعمل من دونه، لكن كراجك يبقى على هذا الهاتف فقط.\n\nالحساب يحفظ نسخة منه ويتيح لك استخدامه على الآيباد أيضًا.',
  ),
  HelpArticle(
    id: 'new-phone',
    category: HelpCategory.backupSync,
    bundled: true,
    questionEn: 'How do I move to a new phone?',
    questionAr: 'كيف أنتقل إلى هاتف جديد؟',
    answerEn:
        'Sign in with the same account on the new phone and your garage downloads. Without an account, the data '
        "can't be moved, so back up first.",
    answerAr: 'سجّل الدخول بالحساب نفسه على الهاتف الجديد وسيُحمَّل كراجك. من دون حساب لا يمكن نقل البيانات، لذا احفظ نسخة أولًا.',
  ),
  HelpArticle(
    id: 'merge',
    category: HelpCategory.backupSync,
    questionEn: "What happens to this phone's data when I sign in?",
    questionAr: 'ماذا يحدث لبيانات هذا الهاتف عند تسجيل الدخول؟',
    answerEn:
        "If the account is new, this phone's garage is uploaded to it. If the account already has a garage, you "
        "choose: merge the two, or replace this phone's data with the account's.",
    answerAr: 'إذا كان الحساب جديدًا، يُرفع إليه كراج هذا الهاتف. وإذا كان للحساب كراج بالفعل، تختار: دمج الاثنين، أو استبدال بيانات هذا الهاتف ببيانات الحساب.',
  ),

  // Privacy.
  HelpArticle(
    id: 'data-collected',
    category: HelpCategory.privacy,
    bundled: true,
    questionEn: 'What data do you collect?',
    questionAr: 'ما البيانات التي تجمعونها؟',
    answerEn:
        'Your vehicles, services and settings, to run the app. With your permission, anonymous usage analytics.\n\n'
        'We never sell your data or show advertising.',
    answerAr: 'مركباتك وصياناتك وإعداداتك، لتشغيل التطبيق. وبإذنك، تحليلات استخدام مجهولة الهوية.\n\nلا نبيع بياناتك أبدًا ولا نعرض إعلانات.',
  ),
  HelpArticle(
    id: 'delete-data',
    category: HelpCategory.privacy,
    bundled: true,
    questionEn: 'How do I delete my data?',
    questionAr: 'كيف أحذف بياناتي؟',
    answerEn:
        'Go to Profile. Without an account, choose Erase all data. With one, choose Delete account: it is removed '
        'from all devices, and backups are cleared within 30 days.',
    answerAr: 'اذهب إلى الحساب. من دون حساب، اختر مسح كل البيانات. ومع حساب، اختر حذف الحساب: يُحذف من كل الأجهزة، وتُمسح النسخ الاحتياطية خلال 30 يومًا.',
  ),
];
