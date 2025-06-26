
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
   "خطأ في معالجة الصورة. يُرجى المحاولة مرة أخرى.",

  "Video file is too large. Please record a shorter video.":
   "ملف الفيديو كبير جداً. يُرجى تسجيل فيديو أقصر.",

  "Error processing video. Please try again.":
   "حدث خطأ أثناء معالجة الفيديو. يرجى المحاولة مرة أخرى.",

  "I had trouble understanding your request. Please try again.":
   "واجهت صعوبة في فهم طلبك. يُرجى المحاولة مرة أخرى.",

  "Sorry, I encountered an error. Please try again.":
   "عذرًا، حدث خطأ. يُرجى المحاولة مرة أخرى.",

  "Error connecting to the assistant service.":
   "خطأ في الاتصال بخدمة المساعد.",

  "Picture taken successfully. Processing the image. Please wait.":
   "تم التقاط الصورة بنجاح. جارٍ معالجة الصورة. يُرجى الانتظار.",

  "You are an assistive AI for blind users. Please describe the contents of this image in detail, including objects, people, text, and any relevant context. Be concise, clear, and helpful.":
   "أنت ذكاء اصطناعي مساعد للمستخدمين المكفوفين. يرجى وصف محتويات هذه الصورة بالتفصيل، بما في ذلك الأشياء والأشخاص والنصوص وأي سياق ذي صلة. كن موجزًا وواضحًا ومفيدًا.",

  "Extract and return the exact text from this document without any modifications, summaries, or added commentary. Preserve original formatting (e.g., line breaks, lists) to ensure screen-reader compatibility. If the document includes images or tables, provide their alt text or describe their structure. Do not alter, abbreviate, or paraphrase any content.":
   "استخرج وأرجع النص الدقيق من هذا المستند دون أي تعديلات أو ملخصات أو تعليقات إضافية. حافظ على التنسيق الأصلي (مثل فواصل الأسطر والقوائم) لضمان التوافق مع قارئ الشاشة. إذا كان المستند يتضمن صورًا أو جداول، فقدم نصًا بديلاً لها أو صف هيكلها. لا تقم بتغيير أو اختصار أو إعادة صياغة أي محتوى.",

  "You are a currency bill detection expert. Analyze the input image and:\n1. **Identify the denomination** (e.g., 1, 5, 10, 20, 50, 100).\n2. **Detect the currency name** in full official English (e.g., \"US Dollars\", \"Qatari Riyals\", \"Euros\").\n3. **Output format**: Strictly use: `<denomination> <currency_name>` \nExample: \"10 US Dollars\" or \"50 Qatari Riyals\"\n**Rules**:\n- If denomination/currency is ambiguous, return \"Unknown\".\n- Never use currency codes (e.g., USD, EUR) or symbols (\$, 8).\n- Prioritize visible text/design over background patterns.\n- Handle partial/obstructed bills by checking security features (holograms, watermarks).":
   "أنت خبير في الكشف عن العملات الورقية. قم بتحليل صورة الإدخال و:\n1. **تحديد الفئة** (على سبيل المثال، 1، 5، 10، 20، 50، 100).\n2. **اكتشاف اسم العملة** باللغة الإنجليزية الرسمية الكاملة (على سبيل المثال، \"US Dollars\"، \"Qatari Riyals\"، \"Euros\").\n3. **تنسيق الإخراج**: استخدم بدقة: `<الفئة> <اسم_العملة>` \nمثال: \"10 US Dollars\" أو \"50 Qatari Riyals\"\n**القواعد**:\n- إذا كانت الفئة/العملة غامضة، فأرجع \"Unknown\".\n- لا تستخدم أبدًا رموز العملات (مثل USD، EUR) أو الرموز (\$, 8).\n- إعطاء الأولوية للنص/التصميم المرئي على الأنماط الخلفية.\n- التعامل مع الأوراق النقدية الجزئية/المعاقة عن طريق فحص ميزات الأمان (الهولوغرامات، العلامات المائية).",

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

  "You are a voice assistant for the blind. Describe the video briefly and clearly in Arabic or English. Avoid phrases like 'in the video'. Focus on useful details only.":
   "أنت مساعد صوتي للمكفوفين. صف الفيديو باختصار ووضوح باللغتين العربية أو الإنجليزية. تجنب العبارات مثل 'في الفيديو'. ركز على التفاصيل المفيدة فقط.",

  "Error recording video.":
   "خطأ في تسجيل الفيديو.",

  "No barcode detected.":
   "لم يتم الكشف عن رمز شريطي.",

  "Product not found.":
   "المنتج غير موجود.",

  "An error occurred while scanning the barcode.":
   "حدث خطأ أثناء مسح الرمز الشريطي.",

  "Open settings":
   "فتح الإعدادات",

  "Settings opened":
   "تم فتح الإعدادات",

  "Instructions":
   "التعليمات",

  "Instructions opened. Please swipe right to hear available modes and controls.":
   "تم فتح التعليمات. يُرجى التمرير لليمين لسماع الأوضاع وعناصر التحكم المتاحة.",

  "Camera loading":
   "جارٍ تحميل الكاميرا",

  "Live camera preview":
   "معاينة الكاميرا الحية",

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
   "الدردشة الصوتية",

  "Double tap to activate voice chat":
   "انقر نقرًا مزدوجًا لتنشيط الدردشة الصوتية",

  "Stop video recording":
   "إيقاف تسجيل الفيديو",

  "Start video recording":
   "بدء تسجيل الفيديو",

  "Take picture":
   "التقاط صورة",

  "Double tap to stop video recording":
   "انقر نقرًا مزدوجًا لإيقاف تسجيل الفيديو",

  "Double tap to start video recording":
   "انقر نقرًا مزدوجًا لبدء تسجيل الفيديو",

  "Double tap to capture an image":
   "انقر نقرًا مزدوجًا لالتقاط صورة",

  "Change camera":
   "تغيير الكاميرا",

  "Double tap to switch between front and back camera":
   "انقر نقرًا مزدوجًا للتبديل بين الكاميرا الأمامية والخلفية",

  "Now facing the default rear camera":
   "أصبحت الكاميرا الخلفية الافتراضية مواجهة الآن",

  "Now facing the selfie camera":
   "أصبحت الكاميرا الأمامية مواجهة الآن",

  " mode activated":
   " تم تنشيط الوضع",

  "Mode selection controls":
   "عناصر التحكم في اختيار الوضع",

  "Currently selected":
   "محدد حاليًا",

  "Double tap to activate ":
   "انقر نقرًا مزدوجًا لتنشيط وضع ",

  " mode":
   " وضع",

  "Voice chat started. Please speak your question.":
   "بدأت الدردشة الصوتية. يُرجى نطق سؤالك.",

  "No voice input detected. Please try again.":
   "لم يتم الكشف عن إدخال صوتي. يُرجى المحاولة مرة أخرى.",

  "Voice recognition error. Please try again.":
   "خطأ في التعرف على الصوت. يُرجى المحاولة مرة أخرى.",

  "Speech recognition not available.":
   "التعرف على الكلام غير متاح.",

  "You are an assistive AI designed to help blind users. Always answer clearly, concisely, and without visual references. If the user's question is unclear, ask for clarification. When responding, act as a guide for someone who cannot see the screen. Use simple and accessible language. If any previous questions or context are available, use them to enhance the accuracy and relevance of your response.\nUser question: ":
  "أنت مساعد ذكي مصمم لمساعدة المستخدمين المكفوفين. أجب دائمًا بطريقة واضحة ومختصرة، وتجنب أي إشارات بصرية. إذا كان السؤال غير واضح، فاطلب توضيحًا. تحدث وكأنك ترشد شخصًا لا يمكنه رؤية الشاشة. استخدم لغة بسيطة وسهلة الفهم. إذا كانت هناك أسئلة أو سياق سابق، فاعتمد عليه لتحسين دقة وفائدة الإجابة.\n\nسؤال المستخدم:",
  
  "Main screen with camera preview, controls, and mode selection":
   "الشاشة الرئيسية مع معاينة الكاميرا وعناصر التحكم واختيار الوضع",

  "Tab bar for mode categories":
   "شريط علامات التبويب لفئات الوضع",

  "Describe":
   "وصف",

  "Picture Describe tab":
   "علامة تبويب وصف الصورة",

  "Read tab":
  "قراءة علامة التبويب",

  "Other Modes tab":
   "علامة تبويب أوضاع أخرى",

  " selected":
   " المحدد",

  "picture describe":
   "وصف الصورة",

  "document reader":
   "قارئ المستندات",

  "video":
   "فيديو",

  "barcode":
   "باركود",

  "medication identifier":
   "معرف الدواء",

  "currency":
   "عملة",

  "outfit identifier":
   "معرف الزي",

   "Read":
   "يقرأ",

   "More":
   "أكثر",

   "Failed to detect the medicine":
   "فشل في اكتشاف الدواء",

   "Explain this medicine in clear, simple spoken language: what it's for, how to use it, and any important warnings. Avoid medical jargon. Do not include phrases like 'here’s a simple explanation' or references to the user being blind. JSON:":
  "اشرح هذا الدواء بلغة عربية مبسطة وواضحة: ما استخدامه، وكيفية استعماله، والتحذيرات المهمة. تجنب المصطلحات الطبية المعقدة. لا تذكر عبارات مثل 'شرح لمستخدم كفيف' أو أي إشارات إلى المستخدم. JSON: ",

};