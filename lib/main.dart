import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI style (dark status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set Firebase cache to 10 MB to save device storage
  FirebaseFirestore.instance.settings = const Settings(
    cacheSizeBytes: 10485760, // 10 MB
  );

  // Set Firebase Auth persistence to LOCAL (Best practice for persisting secure sessions)
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (e) {
    debugPrint("Persistence setup error (safe to ignore on some platforms): $e");
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Pre-load audio pools for smooth fast-paced playback
  await SettingsNotifier.initAudio();

  runApp(
    // Riverpod provider scope wraps the entire app
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FortAlKalimApp(),
    ),
  );
}
