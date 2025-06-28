
// A function that returns the translation based on the language
String translate(String text, {required bool isEnglish}) {
  if (isEnglish) {
    return text;
  } else {
    return languageMap[text] ?? text;
  }
}



// the translations:
final Map languageMap = {

  "Camera access denied. Please grant permission in settings.":
   "تم رفض الوصول إلى الكاميرا. يُرجى منح الإذن من الإعدادات.",

  "No cameras found or camera initialization failed.":
   "لم يتم العثور على كاميرات أو فشل تهيئة الكاميرا.",

  "Camera error: ":
   "خطأ في الكاميرا: ",

  "Camera error occurred.":
   "حدث خطأ في الكاميرا.",

  "Flashlight turned on":
   "تم تشغيل الفلاش",

  "Flashlight turned off":
   "تم إيقاف تشغيل الفلاش",

  "Failed to toggle flashlight":
   "فشل في تشغيل/إيقاف الفلاش",

  "Error processing image. Please try again.":
   "خطأ في فحص الصورة. يرجى المحاولة مرة أخرى.",

  "Video file is too large. Please record a shorter video.":
   "ملف الفيديو كبير جداً. يُرجى تسجيل فيديو أقصر.",

  "Error processing video. Please try again.":
   "حدث خطأ أثناء فحص الفيديو. يرجى المحاولة مرة أخرى.",

  "I had trouble understanding your request. Please try again.":
   "واجهت صعوبة في فهم طلبك. يُرجى المحاولة مرة أخرى.",

  "Sorry, I encountered an error. Please try again.":
   "عذرًا، حدث خطأ. يُرجى المحاولة مرة أخرى.",

  "Error connecting to the assistant service.":
   "خطأ في الاتصال بخدمة المساعد.",

  "Picture taken successfully. Processing the image. Please wait.":
   "تم التقاط الصورة بنجاح. جاري فحص الصورة. يُرجى الانتظار.",

  "You are an assistive AI for blind users. Please describe the contents of this image in detail, including objects, people, text, and any relevant context. Be concise, clear, and helpful.":
   "أنت ذكاء اصطناعي مساعد للمستخدمين المكفوفين. يرجى وصف محتويات هذه الصورة بالتفصيل، بما في ذلك الأشياء والأشخاص والنصوص وأي سياق ذي صلة. كن موجزًا وواضحًا ومفيدًا.",

  "Only Give me all the text in this picture and do not rephrase anything.":
  "فقط أعطني كل النص الموجود في هذه الصورة ولا تعيد صياغة أي شيء.",

  '"If the paper is green, return “1 Qatari Riyal”; if purple or violet, return “5 Qatari Riyals”; if blue, return “10 Qatari Riyals”; if orange, return “50 Qatari Riyals”; if brown, return “200 Qatari Riyals”; if teal or blue-green, return “100 Qatari Riyals”; if red, return “500 Qatari Riyals”."':
   "إذا كانت الورقة خضراء، أعد ”1 ريال قطري“؛ إذا كانت أرجوانية أو بنفسجية، أعد ”5 ريالات قطرية“؛ إذا كانت زرقاء، أعد ”10 ريالات قطرية“؛ إذا كانت برتقالية، أعد ”50 ريالاً قطرياً“؛ إذا كانت بنية، أعد ”200 ريال قطري“؛ إذا كانت خضراء مائلة إلى الأزرق أو الأزرق المائل إلى الأخضر، أعد ”100 ريال قطري“؛ إذا كانت حمراء، أعد ”500 ريال قطري“.",

  "Describe this outfit in terms of color, style, and use. Is it formal, casual, or something else? reply in only 1 sentence":
   "صف هذا الزي من حيث اللون والأسلوب والاستخدام. هل هو رسمي أم كاجوال أم شيء آخر؟ أجب في جملة واحدة فقط",

  "You are a strict visual OCR tool. Your only job is to extract the most prominent brand name from a medicine box image.\nYou must:\n- ONLY return the brand name (e.g., Panadol, Dermadep)\n- NEVER explain, rephrase, or add commentary\n- NEVER output anything except the name itself\n- NEVER return full sentences or parentheses\nIf the image is blurry or unclear, return exactly:\nUnable to identify medicine name. Please try again by placing the front of the box clearly in front of the camera.\nIf more than one box is shown, return exactly:\nMultiple medicine boxes detected. Please show only one medicine at a time.\nIf the brand name contains symbols like ®️ or ™️, include them as-is.\n❗IMPORTANT: Return the name exactly as shown, with no commentary. Do NOT say “Note: ...”, do NOT talk like a chatbot.":
   "أنت أداة OCR مرئية صارمة. مهمتك الوحيدة هي استخراج اسم العلامة التجارية الأكثر بروزًا من صورة علبة دواء.\nيجب عليك:\n- إرجاع اسم العلامة التجارية فقط (على سبيل المثال، Panadol، Dermadep)\n- عدم الشرح أو إعادة الصياغة أو إضافة تعليق أبدًا\n- عدم إخراج أي شيء باستثناء الاسم نفسه أبدًا\n- عدم إرجاع جمل كاملة أو أقواس أبدًا\nإذا كانت الصورة ضبابية أو غير واضحة، فأرجع بالضبط:\nتعذر تحديد اسم الدواء. يُرجى المحاولة مرة أخرى بوضع مقدمة العلبة بوضوح أمام الكاميرا.\nإذا تم عرض أكثر من علبة واحدة، فأرجع بالضبط:\nتم الكشف عن علب أدوية متعددة. يُرجى إظهار دواء واحد فقط في كل مرة.\nإذا كان اسم العلامة التجارية يحتوي على رموز مثل ®️ أو ™️، فقم بتضمينها كما هي.\n❗ هام: أرجع الاسم تمامًا كما هو موضح، بدون أي تعليق. لا تقل “ملاحظة: ...”، لا تتحدث كبرنامج دردشة آلي.",

  "Failed to take picture. Please try again.":
   "فشل التقاط الصورة. يُرجى المحاولة مرة أخرى.",

  "Video recording started.":
   "بدأ تسجيل الفيديو.",

  "Error starting video recording.":
   "خطأ في بدء تسجيل الفيديو.",

  "Video recorded. Please ask your question.":
   "تم تسجيل الفيديو. يُرجى طرح سؤالك.",

  "You are a voice assistant for the blind. Describe the video briefly and clearly in English. Avoid phrases like 'in the video'. Focus on useful details only.":
   "أنت مساعد صوتي للمكفوفين. صف الفيديو باختصار ووضوح باللغتين العربية أو الإنجليزية. تجنب العبارات مثل 'في الفيديو'. ركز على التفاصيل المفيدة فقط.",

  "Error recording video.":
   "خطأ في تسجيل الفيديو.",

  "No barcode detected.":
   "لم يتم اكتشاف أي باركود.",

  "Product not found.":
   "المنتج غير موجود.",

  "An error occurred while scanning the barcode.":
   "حدث خطأ أثناء مسح الرمز الباركود.",

  "Open settings":
   "فتح الإعدادات",

  "Settings opened":
   "تم فتح الإعدادات",

  "Instructions":
   "التعليمات",

  "Instructions opened. Please scroll through every instructions given.":
  "تم فتح التعليمات. يرجى التمرير خلال كل تعليمات مقدمة.",

  "Camera loading":
   "جارٍ تحميل الكاميرا",

  "Live camera preview":
   "عرض مباشر للكاميرا",

  "Camera error":
   "خطأ في الكاميرا",

  "Error: ":
   "خطأ: ",

  "Camera not available":
   "الكاميرا غير متاحة",

  "Retry":
   "إعادة المحاولة",

  "Camera controls":
   "عناصر التحكم في الكاميرا",

  "Voice chat":
   "المحادثة الصوتية",

  "Double tap to activate voice chat":
   "اضغط مرتين لتفعيل المحادثة الصوتية",

  "Stop video recording":
   "إيقاف تسجيل الفيديو",

  "Start video recording":
   "بدء تسجيل الفيديو",

  "Take picture":
   "التقاط صورة",

  "Double tap to stop video recording":
   "اضغط مرتين لإيقاف تسجيل الفيديو",

  "Double tap to start video recording":
   "اضغط مرتين لبدء تسجيل الفيديو",

  "Double tap to capture an image":
   "اضغط مرتين لتصوير صورة",

  "Change camera":
   "تغيير الكاميرا",

  "Double tap to switch between front and back camera":
   "اضغط مرتين للتبديل بين الكاميرا الأمامية والخلفية",

  "Currently using the back camera":
   "تستخدم الكاميرا الخلفية حالياً",

  "Now facing the selfie camera":
     "الآن تظهر الكاميرا الأمامية",

  " mode activated":
   "تم تفعيل ",

  "Mode selection controls":
   "عناصر التحكم في اختيار الوضع",

  "Currently selected":
   "محدد حاليًا",

  "Double tap to activate ":
   "اضغط مرتين للتفعيل",

  " mode":
   "الوضع",

  "Voice chat started. Please speak your question.":
   "بدأت المحادثة الصوتية. الرجاء التحدث بسؤالك",

  "No voice input detected. Please try again.":
   "لم يتم الكشف عن إدخال صوتي. يُرجى المحاولة مرة أخرى.",

  "Voice recognition error. Please try again.":
   "خطأ في التعرف على الصوت. يُرجى المحاولة مرة أخرى.",

  "Speech recognition not available.":
   "التعرف على الكلام غير متاح.",

  "You are an assistive AI designed to help blind users. Always answer clearly, concisely. When responding, act as a guide for someone who cannot see the screen. Use simple and accessible language. If any previous questions or context are available, use them to enhance the accuracy and relevance of your response.\nUser question: ":
  "أنت مساعد ذكي مصمم لمساعدة المستخدمين المكفوفين. أجب دائمًا بطريقة واضحة ومختصرة، وتجنب أي إشارات بصرية. إذا كان السؤال غير واضح، فاطلب توضيحًا. تحدث وكأنك ترشد شخصًا لا يمكنه رؤية الشاشة. استخدم لغة بسيطة وسهلة الفهم. إذا كانت هناك أسئلة أو سياق سابق، فاعتمد عليه لتحسين دقة وفائدة الإجابة.\n\nسؤال المستخدم:",
  
  "Main screen with camera preview, controls, and mode selection":
   "الشاشة الرئيسية مع عرض الكاميرا، وعناصر التحكم، واختيار الوضع",

  "Tab bar for mode categories":
   "قائمة الأوضاع",

  "Describe":
   "وصف",

  "Picture Describe tab":
   "وضع وصف الصورة",

  "Read tab":
  "وضع القراءة",

  "Other Modes tab":
   "الأوضاع الأخرى",

  " selected":
   " تم تحديد",

  "picture describe":
   "وصف الصورة",

  "document reader":
   "قارئ المستندات",

  "video":
   "فيديو",

  "barcode":
   "قارئ الباركود",

  "medication identifier":
   "مُعرف الأدوية",

  "currency":
    "قارئ العملات",

  "clothing identifier":
   "مُعرِّف الملابس",

   "Read":
    "قراءة",

   "More":
    "أكثر",

   "Failed to detect the medicine":
    "فشل في اكتشاف الدواء",

  "Explain this medicine in clear, simple spoken language: what it's for, how to use it, and any important warnings. Avoid medical jargon. Do not include phrases like 'here’s a simple explanation' or references to the user being blind. JSON:":
    "اشرح هذا الدواء بلغة عربية مبسطة وواضحة: ما استخدامه، وكيفية استعماله، والتحذيرات المهمة. تجنب المصطلحات الطبية المعقدة. لا تذكر عبارات مثل 'شرح لمستخدم كفيف' أو أي إشارات إلى المستخدم. JSON: ",

  "Return only the product name from the following JSON with no extra words or explanation:":
    "قم بإرجاع اسم المنتج فقط من ملف JSON التالي بدون كلمات أو شرح إضافي",

  "Now facing the default rear camera":
    "الآن في اتجاه الكاميرا الخلفية",

  "Only strictly answer what the user asked , do not include extra commments or explanations, user question:":
    "فقط أجب بدقة على ما طلبه المستخدم، لا تدرج تعليقات أو تفسيرات إضافية، سؤال المستخدم:",

  "Instructions dialog": 
   "حوار التعليمات",

  "Welcome to AYN" :
   "مرحبًا بك في عين",

  "Instructions content" :
   "محتوى التعليمات",

  "App introduction" :
   "مقدمة التطبيق",

  "This app helps blind or visually impaired users understand their surroundings using the phone’s camera. It supports both English and Arabic. It can describe scenes, objects, people, read text, identify barcodes, medications, currency, and clothing, and responds to voice commands." :
    "يساعد هذا التطبيق المستخدمين المكفوفين أو ضعاف البصر على فهم محيطهم باستخدام كاميرا الهاتف. يدعم التطبيق اللغتين الإنجليزية والعربية. يمكنه وصف المشاهد والأشياء والأشخاص، قراءة النصوص، تحديد الرموز الباركود، الأدوية، العملات والملابس، ويستجيب للأوامر الصوتية.",

  "Navigation overview" :
   "نظرة عامة على التنقل",

  "Navigating is simple. Top-left has Settings. Top-right has Help. Double-tap either to access them." :
   "التنقل بسيط. في الزاوية العلوية اليسرى توجد الإعدادات. في الزاوية العلوية اليمنى توجد المساعدة. اضغط مرتين على أي منهما للوصول إليهما.",

  "Tab descriptions" :
   "وصف الأوضاع",

  "At the bottom, swipe between three tabs: Describe (scene descriptions), Read (text reader), and More (special modes)." :
   "في الأسفل، اسحب بين ثلاثة أوضاع: وصف (وصف المشاهد)، قراءة (قارئ النصوص)، وأكثر (أوضاع الاخره).",

  "Camera button usage" :
   "استخدام زر الكاميرا",

  "In Describe or Read mode, double-tap the center button to capture. In Video mode, it starts or stops recording." :
   "في وضع الوصف أو القراءة، اضغط مرتين على الزر الوسط لالتقاط الصورة. في وضع الفيديو، يبدأ أو يوقف التسجيل.",

  "Microphone and camera switch" :
   "زر الميكروفون وتبديل الكاميرا",

  "On the left is the Microphone button for voice commands. On the right is the Camera Switch to toggle front/rear camera." :
    "على اليسار يوجد زر الميكروفون للأوامر الصوتية. على اليمين يوجد زر تبديل الكاميرا للتبديل بين الكاميرا الأمامية والخلفية.",

  "Modes list" :
   "قائمة الأوضاع",

  "Modes include: Picture Describe, Document Reader, Video Mode, Barcode Scanner, Medication ID, Currency ID, Outfit ID, and Voice Mode." :
   "تشمل الأوضاع: وصف الصورة، قارئ المستندات، وضع الفيديو، قارء الباركود، مُعرف الأدوية، مُعرف العملات، مُعرف الملابس، ووضع الصوت.",

  "Voice mode behavior" :
   "سلوك وضع الصوت",

  "Voice mode answers only based on previous images. It does not access the live camera. Use Describe mode for real-time feedback." :
   "وضع الصوت يجيب فقط بناءً على الصور السابقة. لا يصل إلى الكاميرا الحية. استخدم وضع الوصف للحصول على ردود فعل في الوقت الحقيقي.",

  "Voice examples" :
   "أمثلة على الأوامر الصوتية",

  "After capturing, ask: “What did you see earlier?”, “Read the text again”, or “What was the medication name?" :
   "بعد الالتقاط، اسأل: “ماذا رأيت سابقًا؟”، “اقرأ النص مرة أخرى”، أو “ما اسم الدواء؟”",

  "Tips and reminders" :
   "نصائح وتذكيرات",

  "Tips: The flash turns on for currency. Show medicine packaging clearly. Hold steady when reading." :
   "نصائح: يتم تشغيل الفلاش للعملات. عرض عبوة الدواء بوضوح. امسك الهاتف بثبات عند القراءة.",

  "Error messages" :
   "رسائل الخطأ",

  "Errors include: “Camera error”, “No barcode found”, or “Unable to identify”. Try again if that happens." :
   "تشمل الأخطاء: “خطأ في الكاميرا”، “لم يتم العثور على باركود”، أو “تعذر التعرف”. حاول مرة أخرى إذا حدث ذلك.",

  "Language support" :
   "دعم اللغات",

  "AYN supports English and Arabic. Change the language in Settings." :
   "يدعم عين اللغتين الإنجليزية والعربية. يمكنك تغيير اللغة من الإعدادات.",

  "Help reminder" :
   "تذكير المساعدة",

  "Need help? Double-tap Help or ask your question with voice." :
   "تحتاج إلى مساعدة؟ اضغط مرتين على المساعدة أو اسأل سؤالك باستخدام الصوت.",

  "Encouragement" :
   "تشجيعات",

  "Enjoy using Visual Assistant AYN to explore the world more independently and confidently." :
   "استمتع باستخدام مساعد الرؤية عين لاستكشاف العالم بشكل أكثر استقلالية وثقة.",

  "Close instructions" :
   "إغلاق التعليمات",

  "Double tap to close instructions dialog" :
   "اضغط مرتين لإغلاق حوار التعليمات",

  "Close" :
   "إغلاق",
};