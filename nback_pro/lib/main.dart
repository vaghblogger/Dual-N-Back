import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/app.dart';
import 'src/core/firebase_init.dart';
import 'src/data/models/session_result.dart';
import 'src/data/models/user_settings.dart';
import 'src/data/models/user_streak.dart';
import 'src/data/services/notification_service.dart';
import 'src/data/services/storage_migration.dart';
import 'src/logic/providers/onboarding_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
    if (FirebaseAuth.instance.currentUser != null) {
      await setGuest(false);
      await setOnboardingComplete(true);
    }
  } catch (_) {
    // Firebase not configured (no google-services.json / GoogleService-Info.plist)
  }
  await Hive.initFlutter();
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(SessionResultAdapter());
  Hive.registerAdapter(UserStreakAdapter());

  await runStorageMigrationIfNeeded();

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    const ProviderScope(
      child: NBackApp(),
    ),
  );
}
