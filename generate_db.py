import json

words = [
    {"en": "Hello", "ar": "مَرْحَبًا", "tiles": ["مَر", "حَ", "بًا"]},
    {"en": "Peace", "ar": "سَلَام", "tiles": ["سَ", "لَا", "م"]},
    {"en": "House", "ar": "بَيْت", "tiles": ["بَ", "يْ", "ت"]},
    {"en": "Door", "ar": "بَاب", "tiles": ["بَا", "ب"]},
    {"en": "Book", "ar": "كِتَاب", "tiles": ["كِ", "تَا", "ب"]},
    {"en": "Pen", "ar": "قَلَم", "tiles": ["قَ", "لَ", "م"]},
    {"en": "Sun", "ar": "شَمْس", "tiles": ["شَمْ", "س"]},
    {"en": "Moon", "ar": "قَمَر", "tiles": ["قَ", "مَ", "ر"]},
    {"en": "Sky", "ar": "سَمَاء", "tiles": ["سَ", "مَا", "ء"]},
    {"en": "Earth", "ar": "أَرْض", "tiles": ["أَرْ", "ض"]},
    {"en": "Water", "ar": "مَاء", "tiles": ["مَا", "ء"]},
    {"en": "Fire", "ar": "نَار", "tiles": ["نَا", "ر"]},
    {"en": "Tree", "ar": "شَجَرَة", "tiles": ["شَ", "جَ", "رَة"]},
    {"en": "Flower", "ar": "زَهْرَة", "tiles": ["زَهْ", "رَة"]},
    {"en": "Car", "ar": "سَيَّارَة", "tiles": ["سَ", "يَّا", "رَة"]},
    {"en": "Man", "ar": "رَجُل", "tiles": ["رَ", "جُ", "ل"]},
    {"en": "Woman", "ar": "اِمْرَأَة", "tiles": ["اِمْ", "رَ", "أَة"]},
    {"en": "Boy", "ar": "وَلَد", "tiles": ["وَ", "لَ", "د"]},
    {"en": "Girl", "ar": "بِنْت", "tiles": ["بِنْ", "ت"]},
    {"en": "Bread", "ar": "خُبْز", "tiles": ["خُبْ", "ز"]},
    {"en": "Milk", "ar": "حَلِيب", "tiles": ["حَ", "لِي", "ب"]},
    {"en": "Meat", "ar": "لَحْم", "tiles": ["لَحْ", "م"]},
    {"en": "Fish", "ar": "سَمَك", "tiles": ["سَ", "مَ", "ك"]},
    {"en": "Dog", "ar": "كَلْب", "tiles": ["كَلْ", "ب"]},
    {"en": "Cat", "ar": "قِطَّة", "tiles": ["قِ", "طَّة"]},
    {"en": "Horse", "ar": "حِصَان", "tiles": ["حِ", "صَا", "ن"]},
    {"en": "Eye", "ar": "عَيْن", "tiles": ["عَيْ", "ن"]},
    {"en": "Hand", "ar": "يَد", "tiles": ["يَ", "د"]},
    {"en": "Heart", "ar": "قَلْب", "tiles": ["قَلْ", "ب"]},
    {"en": "Head", "ar": "رَأْس", "tiles": ["رَأْ", "س"]},
    {"en": "Big", "ar": "كَبِير", "tiles": ["كَ", "بِي", "ر"]},
    {"en": "Small", "ar": "صَغِير", "tiles": ["صَ", "غِي", "ر"]},
    {"en": "Beautiful", "ar": "جَمِيل", "tiles": ["جَ", "مِي", "ل"]},
    {"en": "Good", "ar": "جَيِّد", "tiles": ["جَ", "يِّ", "د"]},
    {"en": "Bad", "ar": "سَيِّء", "tiles": ["سَ", "يِّ", "ء"]},
    {"en": "Happy", "ar": "سَعِيد", "tiles": ["سَ", "عِي", "د"]},
    {"en": "Sad", "ar": "حَزِين", "tiles": ["حَ", "زِي", "ن"]},
    {"en": "New", "ar": "جَدِيد", "tiles": ["جَ", "دِي", "د"]},
    {"en": "Old", "ar": "قَدِيم", "tiles": ["قَ", "دِي", "م"]},
    {"en": "Hot", "ar": "حَارّ", "tiles": ["حَا", "رّ"]},
    {"en": "Cold", "ar": "بَارِد", "tiles": ["بَا", "رِ", "د"]},
    {"en": "Red", "ar": "أَحْمَر", "tiles": ["أَحْ", "مَ", "ر"]},
    {"en": "Blue", "ar": "أَزْرَق", "tiles": ["أَزْ", "رَ", "ق"]},
    {"en": "Green", "ar": "أَخْضَر", "tiles": ["أَخْ", "ضَ", "ر"]},
    {"en": "Yellow", "ar": "أَصْفَر", "tiles": ["أَصْ", "فَ", "ر"]},
    {"en": "White", "ar": "أَبْيَض", "tiles": ["أَبْ", "يَ", "ض"]},
    {"en": "Black", "ar": "أَسْوَد", "tiles": ["أَسْ", "وَ", "د"]},
    {"en": "Day", "ar": "يَوْم", "tiles": ["يَوْ", "م"]},
    {"en": "Night", "ar": "لَيْل", "tiles": ["لَيْ", "ل"]},
    {"en": "Time", "ar": "وَقْت", "tiles": ["وَقْ", "ت"]}
]

db_data = {"level_1": {}}

for i, w in enumerate(words):
    word_id = f"word_{i+1:03d}"
    db_data["level_1"][word_id] = {
        "arabic_text": w["ar"],
        "english_text": w["en"],
        "write_tiles": w["tiles"],
        "audio_url": f"https://cdn.jsdelivr.net/gh/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME@main/words/audio/level_1/{word_id}.mp3",
        "image_url": f"https://cdn.jsdelivr.net/gh/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME@main/words/images/level_1/{word_id}.jpg"
    }

with open("demo_db.json", "w", encoding="utf-8") as f:
    json.dump(db_data, f, ensure_ascii=False, indent=2)

print("demo_db.json successfully generated!")
