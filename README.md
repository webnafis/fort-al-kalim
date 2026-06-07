# Fort Al-Kalim (قلعة الكليم)
> *"Words are your only weapons."*

A real-time 1v1 PvP Arabic-English vocabulary battle game for Android.

## Tech Stack
- **Framework**: Flutter + Flame Engine
- **Backend**: Firebase (Auth, Firestore, Realtime DB, Storage, FCM)
- **Social**: Google Play Games Services (GPGS)
- **Local Cache**: SQLite (sqflite)

## Project Structure
```
fort_al_kalim/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── app.dart                   # MaterialApp + routing
│   ├── core/
│   │   ├── constants/             # App-wide constants
│   │   ├── theme/                 # App theme + colors
│   │   └── utils/                 # Helper functions
│   ├── data/
│   │   ├── models/                # Data models (User, Word, Game, etc.)
│   │   ├── repositories/          # Data access layer
│   │   └── services/              # Firebase, GPGS, SQLite services
│   ├── features/
│   │   ├── auth/                  # Login / registration screens
│   │   ├── home/                  # Home screen + navigation
│   │   ├── matchmaking/           # Matchmaking lobby + friend rooms
│   │   ├── game/                  # Core game (reading + combat)
│   │   │   ├── flame/             # Flame game components (forts, missiles)
│   │   │   └── sections/          # Listen, See, Write, Speak sections
│   │   ├── leaderboard/           # Global + level leaderboards
│   │   ├── social/                # Friends tab + activity
│   │   └── profile/               # Player profile + achievements
│   └── shared/
│       ├── widgets/               # Reusable UI components
│       └── extensions/            # Dart extensions
├── assets/
│   ├── audio/                     # Pronunciation audio files
│   ├── images/                    # Word images, fort art, missiles
│   └── fonts/                     # Arabic + Latin fonts
├── game_plan.txt                  # Full game design document
└── firebase.json                  # Firebase config
```

## Game Design
See `game_plan.txt` for the full game design document covering all features,
matchmaking logic, word selection algorithm, attack system, and roadmap.

## Getting Started
1. Install Flutter SDK
2. Run `flutter pub get`
3. Add `google-services.json` from Firebase Console
4. Run `flutter run`
