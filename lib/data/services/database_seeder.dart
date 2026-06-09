import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseSeeder {
  static Future<void> seedLevel1() async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    
    // 100 Beginner Arabic Words for Level 1 with Emojis
    final words = [
      {"en": "Hello", "ar": "مَرْحَبًا", "tiles": ["مَر", "حَ", "بًا"], "emoji": "👋"},
      {"en": "Peace", "ar": "سَلَام", "tiles": ["سَ", "لَا", "م"], "emoji": "🕊️"},
      {"en": "House", "ar": "بَيْت", "tiles": ["بَ", "يْ", "ت"], "emoji": "🏠"},
      {"en": "Door", "ar": "بَاب", "tiles": ["بَا", "ب"], "emoji": "🚪"},
      {"en": "Book", "ar": "كِتَاب", "tiles": ["كِ", "تَا", "ب"], "emoji": "📖"},
      {"en": "Pen", "ar": "قَلَم", "tiles": ["قَ", "لَ", "م"], "emoji": "🖊️"},
      {"en": "Sun", "ar": "شَمْس", "tiles": ["شَمْ", "س"], "emoji": "☀️"},
      {"en": "Moon", "ar": "قَمَر", "tiles": ["قَ", "مَ", "ر"], "emoji": "🌙"},
      {"en": "Sky", "ar": "سَمَاء", "tiles": ["سَ", "مَا", "ء"], "emoji": "☁️"},
      {"en": "Earth", "ar": "أَرْض", "tiles": ["أَرْ", "ض"], "emoji": "🌍"},
      {"en": "Water", "ar": "مَاء", "tiles": ["مَا", "ء"], "emoji": "💧"},
      {"en": "Fire", "ar": "نَار", "tiles": ["نَا", "ر"], "emoji": "🔥"},
      {"en": "Tree", "ar": "شَجَرَة", "tiles": ["شَ", "جَ", "رَة"], "emoji": "🌳"},
      {"en": "Flower", "ar": "زَهْرَة", "tiles": ["زَهْ", "رَة"], "emoji": "🌸"},
      {"en": "Car", "ar": "سَيَّارَة", "tiles": ["سَ", "يَّا", "رَة"], "emoji": "🚗"},
      {"en": "Man", "ar": "رَجُل", "tiles": ["رَ", "جُ", "ل"], "emoji": "👨"},
      {"en": "Woman", "ar": "اِمْرَأَة", "tiles": ["اِمْ", "رَ", "أَة"], "emoji": "👩"},
      {"en": "Boy", "ar": "وَلَد", "tiles": ["وَ", "لَ", "د"], "emoji": "👦"},
      {"en": "Girl", "ar": "بِنْت", "tiles": ["بِنْ", "ت"], "emoji": "👧"},
      {"en": "Bread", "ar": "خُبْز", "tiles": ["خُبْ", "ز"], "emoji": "🍞"},
      {"en": "Milk", "ar": "حَلِيب", "tiles": ["حَ", "لِي", "ب"], "emoji": "🥛"},
      {"en": "Meat", "ar": "لَحْم", "tiles": ["لَحْ", "م"], "emoji": "🥩"},
      {"en": "Fish", "ar": "سَمَك", "tiles": ["سَ", "مَ", "ك"], "emoji": "🐟"},
      {"en": "Dog", "ar": "كَلْب", "tiles": ["كَلْ", "ب"], "emoji": "🐕"},
      {"en": "Cat", "ar": "قِطَّة", "tiles": ["قِ", "طَّة"], "emoji": "🐈"},
      {"en": "Horse", "ar": "حِصَان", "tiles": ["حِ", "صَا", "ن"], "emoji": "🐎"},
      {"en": "Eye", "ar": "عَيْن", "tiles": ["عَيْ", "ن"], "emoji": "👁️"},
      {"en": "Hand", "ar": "يَد", "tiles": ["يَ", "د"], "emoji": "✋"},
      {"en": "Heart", "ar": "قَلْب", "tiles": ["قَلْ", "ب"], "emoji": "❤️"},
      {"en": "Head", "ar": "رَأْس", "tiles": ["رَأْ", "س"], "emoji": "🗣️"},
      {"en": "Big", "ar": "كَبِير", "tiles": ["كَ", "بِي", "ر"], "emoji": "🐘"},
      {"en": "Small", "ar": "صَغِير", "tiles": ["صَ", "غِي", "ر"], "emoji": "🐁"},
      {"en": "Beautiful", "ar": "جَمِيل", "tiles": ["جَ", "مِي", "ل"], "emoji": "✨"},
      {"en": "Good", "ar": "جَيِّد", "tiles": ["جَ", "يِّ", "د"], "emoji": "👍"},
      {"en": "Bad", "ar": "سَيِّء", "tiles": ["سَ", "يِّ", "ء"], "emoji": "👎"},
      {"en": "Happy", "ar": "سَعِيد", "tiles": ["سَ", "عِي", "د"], "emoji": "😊"},
      {"en": "Sad", "ar": "حَزِين", "tiles": ["حَ", "زِي", "ن"], "emoji": "😢"},
      {"en": "New", "ar": "جَدِيد", "tiles": ["جَ", "دِي", "د"], "emoji": "🆕"},
      {"en": "Old", "ar": "قَدِيم", "tiles": ["قَ", "دِي", "م"], "emoji": "🏚️"},
      {"en": "Hot", "ar": "حَارّ", "tiles": ["حَا", "رّ"], "emoji": "🥵"},
      {"en": "Cold", "ar": "بَارِد", "tiles": ["بَا", "رِ", "د"], "emoji": "🥶"},
      {"en": "Red", "ar": "أَحْمَر", "tiles": ["أَحْ", "مَ", "ر"], "emoji": "🔴"},
      {"en": "Blue", "ar": "أَزْرَق", "tiles": ["أَزْ", "رَ", "ق"], "emoji": "🔵"},
      {"en": "Green", "ar": "أَخْضَر", "tiles": ["أَخْ", "ضَ", "ر"], "emoji": "🟢"},
      {"en": "Yellow", "ar": "أَصْفَر", "tiles": ["أَصْ", "فَ", "ر"], "emoji": "🟡"},
      {"en": "White", "ar": "أَبْيَض", "tiles": ["أَبْ", "يَ", "ض"], "emoji": "⚪"},
      {"en": "Black", "ar": "أَسْوَد", "tiles": ["أَسْ", "وَ", "د"], "emoji": "⚫"},
      {"en": "Day", "ar": "يَوْم", "tiles": ["يَوْ", "م"], "emoji": "🌞"},
      {"en": "Night", "ar": "لَيْل", "tiles": ["لَيْ", "ل"], "emoji": "🌃"},
      {"en": "Time", "ar": "وَقْت", "tiles": ["وَقْ", "ت"], "emoji": "⏱️"},
      {"en": "Family", "ar": "عَائِلَة", "tiles": ["عَا", "ئِ", "لَة"], "emoji": "👪"},
      {"en": "Mother", "ar": "أُمّ", "tiles": ["أُ", "مّ"], "emoji": "👩‍👧"},
      {"en": "Father", "ar": "أَب", "tiles": ["أَ", "ب"], "emoji": "👨‍👦"},
      {"en": "Brother", "ar": "أَخ", "tiles": ["أَ", "خ"], "emoji": "👦"},
      {"en": "Sister", "ar": "أُخْت", "tiles": ["أُخْ", "ت"], "emoji": "👧"},
      {"en": "Friend", "ar": "صَدِيق", "tiles": ["صَ", "دِي", "ق"], "emoji": "🤝"},
      {"en": "City", "ar": "مَدِينَة", "tiles": ["مَ", "دِي", "نَة"], "emoji": "🏙️"},
      {"en": "Street", "ar": "شَارِع", "tiles": ["شَا", "رِ", "ع"], "emoji": "🛣️"},
      {"en": "Market", "ar": "سُوق", "tiles": ["سُو", "ق"], "emoji": "🛒"},
      {"en": "Money", "ar": "مَال", "tiles": ["مَا", "ل"], "emoji": "💵"},
      {"en": "School", "ar": "مَدْرَسَة", "tiles": ["مَدْ", "رَ", "سَة"], "emoji": "🏫"},
      {"en": "Student", "ar": "طَالِب", "tiles": ["طَا", "لِ", "ب"], "emoji": "🎒"},
      {"en": "Teacher", "ar": "مُعَلِّم", "tiles": ["مُ", "عَلِّ", "م"], "emoji": "🧑‍🏫"},
      {"en": "Doctor", "ar": "طَبِيب", "tiles": ["طَ", "بِي", "ب"], "emoji": "🩺"},
      {"en": "Hospital", "ar": "مُسْتَشْفَى", "tiles": ["مُسْ", "تَشْ", "فَى"], "emoji": "🏥"},
      {"en": "Food", "ar": "طَعَام", "tiles": ["طَ", "عَا", "م"], "emoji": "🍲"},
      {"en": "Apple", "ar": "تُفَّاحَة", "tiles": ["تُ", "فَّا", "حَة"], "emoji": "🍎"},
      {"en": "Orange", "ar": "بُرْتُقَال", "tiles": ["بُرْ", "تُ", "قَا", "ل"], "emoji": "🍊"},
      {"en": "Banana", "ar": "مَوْز", "tiles": ["مَوْ", "ز"], "emoji": "🍌"},
      {"en": "Grape", "ar": "عِنَب", "tiles": ["عِ", "نَ", "ب"], "emoji": "🍇"},
      {"en": "Coffee", "ar": "قَهْوَة", "tiles": ["قَهْ", "وَة"], "emoji": "☕"},
      {"en": "Tea", "ar": "شَاي", "tiles": ["شَا", "ي"], "emoji": "🍵"},
      {"en": "Chicken", "ar": "دَجَاج", "tiles": ["دَ", "جَا", "ج"], "emoji": "🍗"},
      {"en": "Egg", "ar": "بَيْضَة", "tiles": ["بَيْ", "ضَة"], "emoji": "🥚"},
      {"en": "Salt", "ar": "مِلْح", "tiles": ["مِلْ", "ح"], "emoji": "🧂"},
      {"en": "Sugar", "ar": "سُكَّر", "tiles": ["سُ", "كَّ", "ر"], "emoji": "🍬"},
      {"en": "Table", "ar": "طَاوِلَة", "tiles": ["طَا", "وِ", "لَة"], "emoji": "🪑"},
      {"en": "Chair", "ar": "كُرْسِيّ", "tiles": ["كُرْ", "سِيّ"], "emoji": "🪑"},
      {"en": "Bed", "ar": "سَرِير", "tiles": ["سَ", "رِي", "ر"], "emoji": "🛏️"},
      {"en": "Window", "ar": "نَافِذَة", "tiles": ["نَا", "فِ", "ذَة"], "emoji": "🪟"},
      {"en": "Key", "ar": "مِفْتَاح", "tiles": ["مِفْ", "تَا", "ح"], "emoji": "🔑"},
      {"en": "Phone", "ar": "هَاتِف", "tiles": ["هَا", "تِ", "ف"], "emoji": "📱"},
      {"en": "Computer", "ar": "حَاسُوب", "tiles": ["حَا", "سُو", "ب"], "emoji": "💻"},
      {"en": "Bag", "ar": "حَقِيبَة", "tiles": ["حَ", "قِي", "بَة"], "emoji": "👜"},
      {"en": "Shirt", "ar": "قَمِيص", "tiles": ["قَ", "مِي", "ص"], "emoji": "👕"},
      {"en": "Shoes", "ar": "حِذَاء", "tiles": ["حِ", "ذَا", "ء"], "emoji": "👞"},
      {"en": "Hat", "ar": "قُبَّعَة", "tiles": ["قُ", "بَّ", "عَة"], "emoji": "🎩"},
      {"en": "Glasses", "ar": "نَظَّارَة", "tiles": ["نَ", "ظَّا", "رَة"], "emoji": "👓"},
      {"en": "Clock", "ar": "سَاعَة", "tiles": ["سَا", "عَة"], "emoji": "🕰️"},
      {"en": "Watch", "ar": "سَاعَة", "tiles": ["سَا", "عَة"], "emoji": "⌚"},
      {"en": "Gold", "ar": "ذَهَب", "tiles": ["ذَ", "هَ", "ب"], "emoji": "🥇"},
      {"en": "Silver", "ar": "فِضَّة", "tiles": ["فِ", "ضَّة"], "emoji": "🥈"},
      {"en": "Iron", "ar": "حَدِيد", "tiles": ["حَ", "دِي", "د"], "emoji": "🧲"},
      {"en": "Mountain", "ar": "جَبَل", "tiles": ["جَ", "بَ", "ل"], "emoji": "⛰️"},
      {"en": "River", "ar": "نَهْر", "tiles": ["نَهْ", "ر"], "emoji": "🏞️"},
      {"en": "Sea", "ar": "بَحْر", "tiles": ["بَحْ", "ر"], "emoji": "🌊"},
      {"en": "Wind", "ar": "رِيح", "tiles": ["رِي", "ح"], "emoji": "🌬️"},
      {"en": "Rain", "ar": "مَطَر", "tiles": ["مَ", "طَ", "ر"], "emoji": "🌧️"},
      {"en": "Snow", "ar": "ثَلْج", "tiles": ["ثَلْ", "ج"], "emoji": "❄️"},
      {"en": "Star", "ar": "نَجْم", "tiles": ["نَجْ", "م"], "emoji": "⭐"}
    ];

    for (int i = 0; i < words.length; i++) {
      final wordId = 'word_${(i + 1).toString().padLeft(3, '0')}';
      
      final docRef = firestore
          .collection('levels')
          .doc('level_1')
          .collection('words')
          .doc(wordId);
      
      batch.set(docRef, {
        'english_text': words[i]['en'],
        'arabic_text': words[i]['ar'],
        'write_tiles': words[i]['tiles'],
        'emoji': words[i]['emoji'],
        'audio_url': 'https://cdn.jsdelivr.net/gh/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME@main/words/audio/level_1/$wordId.mp3',
        // image_url is removed! Using emojis for Phase 1.
      });
    }

    await batch.commit();
    
    if (kDebugMode) {
      print("SUCCESS! Uploaded ${words.length} emoji words to Firestore Level 1!");
    }
  }
}
