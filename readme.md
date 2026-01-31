# Master Implementation Plan: Dual N-Back Pro
**Version 1.0**
**Objective:** A "copy-paste" level guide to building a scientifically accurate Dual N-Back training app in Flutter.


---


## 1. Project Setup & Architecture


### 1.1 Initialization
Run the following commands in your terminal:
```bash
flutter create --org com.yourcompany nback_pro
cd nback_pro
```


### 1.2 Dependencies (`pubspec.yaml`)
Add these specific versions to your `pubspec.yaml` to ensure compatibility.
```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
 
  # Navigation
  go_router: ^13.0.1
 
  # Local Storage (Settings, Stats, Streak)
  hive: ^2.2.3
  hive_flutter: ^1.1.0
 
  # Authentication
  firebase_auth: ^4.16.0
  google_sign_in: ^6.1.6
  # (Add apple_sign_in later if Mac build required)
 
  # Utilities
  intl: ^0.19.0 # For date formatting
  url_launcher: ^6.2.4 # For "Give Feedback" / "Privacy Policy"
  shared_preferences: ^2.2.2 # Lightweight flags if needed
 
  # Audio
  audioplayers: ^5.2.1 # For playing the letter sounds
 
  # UI/Animations
  lottie: ^3.0.0 # For the N=1 / N=2 animations
  fl_chart: ^0.66.0 # For the Stats graph


dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.3.9
  build_runner: ^2.4.7
  hive_generator: ^2.0.1
```

**Optional / additional dependencies** for the full implementation: `firebase_core`, `flutter_local_notifications`, `timezone`, `flutter_secure_storage`, `wakelock_plus`. Add as needed for notifications, secure storage, and keeping screen on during the game.

### 1.3 Android build (optional)
If using `flutter_local_notifications`, enable core library desugaring in `android/app/build.gradle.kts`: in `compileOptions` set `isCoreLibraryDesugaringEnabled = true`, and add dependency `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`.

### 1.4 Folder Structure
Create this exact structure in `lib/`:
```text
lib/
├── main.dart
├── src/
│   ├── app.dart                  # Main App Widget (Router + Theme wrapper)
│   ├── core/
│   │   ├── constants/            # AppStrings, AssetPaths
│   │   ├── theme/                # Theme definitions (6 themes)
│   │   └── utils/                # Date helpers, Audio helpers
│   ├── data/
│   │   ├── models/               # Hive Models (UserSettings, SessionResult, UserStreak)
│   │   ├── repositories/         # StatsRepository, SettingsRepository
│   │   └── services/             # AudioService, AuthService
│   ├── logic/
│   │   ├── game_engine/          # The N-Back algorithm (Generation, Scoring)
│   │   └── providers/            # Riverpod providers
│   └── presentation/
│       ├── common_widgets/       # Reusable buttons, cards
│       ├── screens/
│       │   ├── onboarding/       # Screens 1, 2 (Theme, Login)
│       │   ├── home/             # Screen 3 (Home + Daily Challenge)
│       │   ├── tutorial/         # Screens 4, 5, 6 (Rules)
│       │   ├── game/             # The active Training Screen
│       │   └── settings/         # Settings Screen
│       └── statistics/           # Stats Screen
```


---


## 2. Core Logic (The Brain)


### 2.1 The N-Back Algorithm
**File:** `lib/src/logic/game_engine/nback_engine.dart`


**Scientific Standards & Rules:**
1.  **Block Length:** 20 + N trials per session.
2.  **Target Ratio:** 30% of trials must be matches.
3.  **Base Timing (Scientific Rule):**
    *   **Total Trial Duration:** 3000ms (3 seconds).
    *   **Stimulus Duration:** 500ms.
    *   **Inter-Stimulus Interval:** 2500ms.
4.  **Speed Modifiers:**
    *   Users can apply a multiplier: `0.5x, 0.75x, 1x (Default), 1.5x, 2x, 2.5x, 3x`.
    *   *Calculation:* `Trial Duration = 3000ms / multiplier`.
    *   **Warning:** If multiplier < 1.0 (slower), show warning: *"This speed is below scientific standards. You can increase it when comfortable."*
5.  **Stimuli:**
    *   **Visual:** Grid Index (0-8).
    *   **Audio:** Letters (C, H, K, L, Q, R, S, T) - *Non-rhyming set*.


**Generation Logic (Pseudo-code):**
```dart
class Trial {
  final int position; // 0-8
  final String letter;
  final bool isVisualMatch;
  final bool isAudioMatch;
}


List<Trial> generateSession(int n, int totalTrials) {
  List<Trial> trials = [];
  // ... fill list ensuring ~30% matches
  // Matches occur at index [i] == index [i - n]
}
```


### 2.2 Auto-N Algorithm (Adaptive Difficulty)
**File:** `lib/src/logic/providers/game_provider.dart`


**Logic:**
Triggered at the **End of Session**.
```dart
void adjustNLevel(double accuracy, bool isAutoNEnabled) {
  if (!isAutoNEnabled) return;


  // Requirements: "Accuracy below 75% -> Decrease"
  if (accuracy >= 0.85) { // 85%+ = Too easy
    currentN++;
  } else if (accuracy < 0.75) { // <75% = Too hard
    currentN = (currentN > 1) ? currentN - 1 : 1;
  }
  // 75% - 84% = Maintain Zone (Optimal Flow)
}
```


### 2.3 Scoring System
*   **Audio Score:** (Correct Hits + Correct Rejections) / Total Audio Trials
*   **Visual Score:** (Correct Hits + Correct Rejections) / Total Visual Trials
*   **Total Accuracy:** Average of Audio & Visual Score.


---


## 3. Data Layer (Hive Schemas)


### 3.1 UserSettings
**File:** `lib/src/data/models/user_settings.dart`
```dart
@HiveType(typeId: 0)
class UserSettings {
  @HiveField(0) int selectedThemeId; // 0-5
  @HiveField(1) bool isAutoN;        // Default: true
  @HiveField(2) int manualN;         // Default: 2
  @HiveField(3) bool continuousFeedback; // Default: false (Scientific)
  @HiveField(4) bool focusMusicEnabled;  // Default: false
  @HiveField(5) String? reminderTime;    // ISO string
  @HiveField(6) double speedMultiplier;  // Default: 1.0
}
```


**IMPORTANT:** When `continuousFeedback` is toggled ON, show Dialog: *"Immediate feedback is not scientifically standard. You can disable it later."*


### 3.2 SessionResult (For Stats)
**File:** `lib/src/data/models/session_result.dart`
```dart
@HiveType(typeId: 1)
class SessionResult {
  @HiveField(0) DateTime date;
  @HiveField(1) int nLevel;
  @HiveField(2) double accuracy; // 0.0 to 1.0
}
```


### 3.3 DailyChallenge (Streak)
**File:** `lib/src/data/models/user_streak.dart`
```dart
@HiveType(typeId: 2)
class UserStreak {
  @HiveField(0) int currentStreak;
  @HiveField(1) DateTime? lastCompletedDate;
}
```
**Logic:**
*   `isChallengeCompleteToday`: `lastCompletedDate.day == DateTime.now().day`
*   `incrementStreak`: If `lastCompletedDate` was yesterday, `streak++`. If older, `streak = 1`.


---


## 4. Aesthetics (Theming)


### 4.1 Theme Definitions
**File:** `lib/src/core/theme/app_theme.dart`


**Requirement:** 3 Light, 3 Dark. Low cognitive load.


| Theme ID | Name | Background | Surface/Card | Primary Accent | Text Primary |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **0 (Default)** | **Dark BW** | `#121212` | `#1E1E1E` | `#FFFFFF` | `#E0E0E0` |
| **1** | **Dark Navy** | `#0A1929` | `#132F4C` | `#90CAF9` | `#E3F2FD` |
| **2** | **Dark Forest**| `#1B261B` | `#2C3E2C` | `#A5D6A7` | `#E8F5E9` |
| **3** | **Light Paper** | `#F5F5F5` | `#FFFFFF` | `#616161` | `#212121` |
| **4** | **Light Sand** | `#FDFCF0` | `#FFFBE6` | `#795548` | `#3E2723` |
| **5** | **Light Sage** | `#EFF5E9` | `#FFFFFF` | `#558B2F` | `#1B5E20` |


---


## 5. Screen-by-Screen Implementation Guide


### Screen 1: Theme Selection (Onboarding Step 1)
*   **UI:** A GridView of 6 cards. Each card previews the theme colors. Optionally add a "Next" or "Continue" button so users can proceed without relying on card-tap navigation.
*   **Action:** Tapping a card updates `ref.read(settingsProvider)` and saves to Hive.
*   **Next:** Navigate to Login (on card tap or via explicit button).


### Screen 2: Login (Onboarding Step 2)
*   **UI:**
    1.  Logo (Top)
    2.  "Sign in with Google" Button (`OutlineButton` with Icon)
    3.  "Sign in with Apple" Button (iOS only check: `Platform.isIOS`)
    4.  "Continue as Guest" (TextButton)
*   **Logic:**
    *   Guest tap -> Show Dialog: "Progress will not be saved. Continue?" -> `Yes` -> Navigate to Screen 3.
    *   Auth tap -> Trigger Firebase Auth -> On Success -> Navigate to Screen 3.


### Screen 3: Home / Dashboard
*   **Header:** "Good Morning, [User/Guest]"
*   **Daily Challenge Card (Prominent):**
    *   **State:** Green Checkmark if done today. "Start" button if not.
    *   **Text:** "Maintain your [X] day streak!"
    *   **Action:** Starts Game Session with `n = auto_n_level`.
*   **Quick Actions:**
    *   "Training Tutorial" -> Navigates to Screen 4.
    *   "Stats" -> Navigates to Stats Screen.
    *   "Settings" -> Navigates to Screen 8.
*   **Footer:** "Current Level: N-Back [X]"


### Screen 4: Rules N=1 (Animation)
*   **Content:**
    *   Text: "Press Match when the current stimuli matches the one just shown."
    *   **Animation:** Use a Lottie file (`assets/animations/n1_demo.json`) showing a square moving 1 step back and matching.
*   **Next Button:** Go to Screen 5.


### Screen 5: Rules N=2 (Animation)
*   **Content:**
    *   Text: "Press Match when the current stimuli matches the one shown **2 steps ago**."
    *   **Animation:** Lottie file (`assets/animations/n2_demo.json`).
*   **Next Button:** Go to Screen 6.


### Screen 6: Progression Info
*   **Content:** Static text explanation of Auto-N ("We increase difficulty when you master the current level...").
*   **Action:** "Start Training" Button -> Returns to Home (Screen 3).


### Screen 7: The Game (Training)
*   **Layout:**
    *   **Top Bar:** Progress Bar (1 to 20+N). Pause Button.
    *   **Center:** 3x3 Grid. Active square highlights with `Theme.primary`.
    *   **Bottom:** Two Large Buttons.
        *   Left: "Audio Match"
        *   Right: "Visual Match"
    *   **Feedback:**
        *   **Default (Scientific):** No immediate visual change on tap (subtle ripple only).
        *   **If Feedback ON:** Button border flashes Light Green (Correct) or Light Red (Wrong).
*   **Logic:**
    *   **Timer:** `Duration = 3000ms / speedMultiplier`.
    *   **Cycle:**
        1.  Show Stimulus (Audio+Visual) for `500ms`.
        2.  Hide Stimulus (Blank Grid) for `Duration - 500ms`.
    *   Listen to Button Taps throughout the full cycle.
    *   End of Session -> Calculate Score -> Update Hive -> Show "Session Summary" Dialog.


### Screen 8: Settings
*   **ListTiles:**
    1.  **Daily Reminder:** `TimePicker`.
    2.  **Auto N:** `Switch`.
    3.  **My N:** `Slider` (1-5). Disabled if Auto N is True.
    4.  **Speed:** `Slider` (0.5x, 0.75x, 1x, 1.5x, 2x, 3x).
        *   *OnChange:* If < 1.0, show "Not Scientific" Toast/Popup.
    5.  **Continuous Feedback:** `Switch`.
        *   *OnChange:* If ON, show "Not Scientific" Toast/Popup.
    6.  **Focus Music:** `Switch`.
    7.  **Theme:** Re-opens Screen 1 widget.
    8.  **Give Feedback:** `launchUrl('mailto:...')`.
    9.  **Privacy/Terms:** `launchUrl('https://...')`.


### Screen 9: Stats / Analytics
*   **Header:** "Your Progress"
*   **Key Metrics:**
    1.  **Average N Level:** Display average N across all sessions
    2.  **Current N Level:** Highest N achieved
    3.  **Total Sessions:** Count of completed sessions
    4.  **Current Streak:** Days in a row
*   **Chart:** Line graph (using `fl_chart`) showing N-level progression over time (last 30 days)
*   **Session History:** Scrollable list of recent sessions with date, N-level, and accuracy


---


## 6. Assets & Resources Required


### 6.1 Audio Files
**Location:** `assets/audio/`


Create or source 8 audio files for the letters:
- `c.mp3` - Letter "C" pronunciation
- `h.mp3` - Letter "H" pronunciation
- `k.mp3` - Letter "K" pronunciation
- `l.mp3` - Letter "L" pronunciation
- `q.mp3` - Letter "Q" pronunciation
- `r.mp3` - Letter "R" pronunciation
- `s.mp3` - Letter "S" pronunciation
- `t.mp3` - Letter "T" pronunciation


**Requirements:**
- Clear, neutral voice
- Duration: ~300-400ms each
- Format: MP3, 44.1kHz
- Volume normalized


### 6.2 Lottie Animations
**Location:** `assets/animations/`


**n1_demo.json:**
- Shows a 3x3 grid
- Square lights up at position (e.g., top-left)
- Next trial: square lights up at same position
- Visual indicator shows "MATCH!"
- Duration: ~5 seconds, loops


**n2_demo.json:**
- Shows a 3x3 grid
- Square lights up at position A
- Next trial: square at position B
- Next trial: square at position A again
- Visual indicator shows "MATCH!" (2-back)
- Duration: ~8 seconds, loops


### 6.3 Focus Music (Optional)
**Location:** `assets/music/`
- `focus_ambient.mp3` - Calm, non-distracting background music
- Duration: 3-5 minutes, loopable
- Low volume, binaural beats or ambient sounds


### 6.4 App Icon & Splash
- App icon (1024x1024) with brain/memory theme
- Splash screen with app logo


---


## 7. Detailed Implementation Specifications


### 7.1 N-Back Trial Generation Algorithm
**File:** `lib/src/logic/game_engine/nback_engine.dart`


```dart
class NBackEngine {
  final Random _random = Random();
  final List<String> _letters = ['C', 'H', 'K', 'L', 'Q', 'R', 'S', 'T'];
 
  List<Trial> generateSession(int n, int totalTrials) {
    List<Trial> trials = [];
   
    // Calculate target matches (30% of total)
    int targetMatches = (totalTrials * 0.3).round();
    int audioMatches = 0;
    int visualMatches = 0;
   
    for (int i = 0; i < totalTrials; i++) {
      bool shouldAudioMatch = false;
      bool shouldVisualMatch = false;
     
      // After N trials, we can create matches
      if (i >= n) {
        // Randomly decide if this should be a match (targeting 30%)
        if (audioMatches < targetMatches / 2 && _random.nextDouble() < 0.3) {
          shouldAudioMatch = true;
          audioMatches++;
        }
        if (visualMatches < targetMatches / 2 && _random.nextDouble() < 0.3) {
          shouldVisualMatch = true;
          visualMatches++;
        }
      }
     
      // Generate trial
      String letter;
      int position;
     
      if (shouldAudioMatch && i >= n) {
        letter = trials[i - n].letter;
      } else {
        letter = _letters[_random.nextInt(_letters.length)];
      }
     
      if (shouldVisualMatch && i >= n) {
        position = trials[i - n].position;
      } else {
        position = _random.nextInt(9);
      }
     
      trials.add(Trial(
        position: position,
        letter: letter,
        isVisualMatch: shouldVisualMatch,
        isAudioMatch: shouldAudioMatch,
      ));
    }
   
    return trials;
  }
}
```


### 7.2 Session Summary Dialog
**Shown after game completion**


**Content:**
- "Session Complete!"
- N-Level: [X]
- Audio Accuracy: [XX]%
- Visual Accuracy: [XX]%
- Overall Accuracy: [XX]%
- [If Auto-N] "Your N-level has been [increased/decreased/maintained]"
- Buttons: "View Stats" | "Play Again" | "Home"


### 7.3 Daily Reminder Implementation
**File:** `lib/src/data/services/notification_service.dart`


Use `flutter_local_notifications` package (add to pubspec.yaml):
```yaml
flutter_local_notifications: ^16.3.0
```


**Logic:**
- User selects time in Settings
- Schedule daily notification at that time
- Notification title: "Daily N-Back Challenge"
- Notification body: "Keep your [X] day streak alive!"
- Tap notification -> Opens app to Home screen


### 7.4 Focus Music Implementation
**File:** `lib/src/data/services/audio_service.dart`


```dart
class AudioService {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
 
  Future<void> playLetter(String letter) async {
    await _sfxPlayer.play(AssetSource('assets/audio/${letter.toLowerCase()}.mp3'));
  }
 
  Future<void> startFocusMusic() async {
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(0.3); // Low volume
    await _musicPlayer.play(AssetSource('assets/music/focus_ambient.mp3'));
  }
 
  Future<void> stopFocusMusic() async {
    await _musicPlayer.stop();
  }
}
```


### 7.5 Error Handling & Edge Cases


**Mid-Session App Close:**
- Save current trial index to Hive
- On app resume, show dialog: "Resume session?" or "Start new session"
- If resume, continue from saved trial


**Timezone Changes:**
- Store `lastCompletedDate` in UTC
- Compare dates in user's current timezone
- Streak logic handles timezone shifts gracefully


**Firebase Auth Failure / Not Configured:**
- If Firebase is not initialized (e.g. missing `google-services.json` / `GoogleService-Info.plist`), the app should still run: treat as guest-only (no sign-in), and avoid accessing `FirebaseAuth.instance` until `Firebase.initializeApp()` has succeeded.
- On auth failure: Show error toast: "Authentication failed. Try again or continue as guest." Log error to console. Allow retry or guest mode.


**Maximum N Level:**
- Cap at N=10 (scientifically, beyond 5-6 is extremely difficult)
- Show achievement dialog when reaching N=5+


**Audio Playback Failure:**
- Catch exceptions in AudioService
- Show warning: "Audio unavailable. Visual-only mode."
- Continue session with visual stimuli only


---


## 8. Security & Privacy Compliance


### 8.1 Data Protection Requirements
**MANDATORY for App Store & Play Store approval**


#### Privacy Policy (Required)
Create a comprehensive Privacy Policy document covering:
- **Data Collection:** What data is collected (email, progress, settings)
- **Data Usage:** How data is used (authentication, progress tracking)
- **Data Storage:** Where data is stored (local Hive, Firebase)
- **Data Sharing:** Third parties with access (Google/Apple for auth, Firebase)
- **User Rights:** Access, deletion, export requests
- **Children's Privacy:** COPPA compliance if targeting users under 13
- **Contact Information:** Email for privacy inquiries


**Host at:** `https://yourwebsite.com/privacy-policy`


#### Terms of Use (Required)
Create Terms of Use covering:
- Acceptable use policy
- Intellectual property rights
- Disclaimer of warranties
- Limitation of liability
- Governing law


**Host at:** `https://yourwebsite.com/terms-of-use`


### 8.2 GDPR/CCPA Compliance Checklist
- [ ] Implement "Delete My Data" feature in Settings
- [ ] Implement "Export My Data" feature (JSON format)
- [ ] Add consent dialog on first launch (EU users)
- [ ] Provide opt-out for analytics tracking
- [ ] Store user consent preferences in Hive
- [ ] Implement data retention policy (delete after 2 years of inactivity)


### 8.3 Secure Data Handling
**File:** `lib/src/core/security/encryption_service.dart`


```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class EncryptionService {
  final _secureStorage = FlutterSecureStorage();
 
  // Store sensitive data (auth tokens)
  Future<void> storeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
 
  // Retrieve sensitive data
  Future<String?> retrieveSecure(String key) async {
    return await _secureStorage.read(key: key);
  }
 
  // Delete sensitive data
  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }
}
```


Add to `pubspec.yaml`:
```yaml
flutter_secure_storage: ^9.0.0
```


---


## 9. Accessibility Features


### 9.1 Screen Reader Support
**File:** `lib/src/presentation/common_widgets/accessible_button.dart`


```dart
Widget buildAccessibleButton({
  required String label,
  required VoidCallback onPressed,
  String? semanticHint,
}) {
  return Semantics(
    label: label,
    hint: semanticHint,
    button: true,
    enabled: true,
    child: ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}
```


### 9.2 Accessibility Checklist
- [ ] Add `Semantics` widgets to all interactive elements
- [ ] Provide text alternatives for audio cues (visual indicators)
- [ ] Ensure minimum touch target size (48x48 dp)
- [ ] Support dynamic font scaling (respect system font size)
- [ ] Test with TalkBack (Android) and VoiceOver (iOS)
- [ ] Add high contrast mode toggle in Settings
- [ ] Provide haptic feedback option for button presses


### 9.3 High Contrast Theme
Add to `lib/src/core/theme/app_theme.dart`:


```dart
ThemeData getHighContrastTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    cardColor: Color(0xFF1A1A1A),
    primaryColor: Colors.yellow, // High contrast accent
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontSize: 18),
      bodyMedium: TextStyle(color: Colors.white, fontSize: 16),
    ),
  );
}
```


### 9.4 Haptic Feedback
**File:** `lib/src/core/utils/haptic_helper.dart`


```dart
import 'package:flutter/services.dart';


class HapticHelper {
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }
 
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }
 
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }
}
```


Use in game screen:
```dart
// On correct answer
if (settings.continuousFeedback && isCorrect) {
  HapticHelper.lightImpact();
}
```


---


## 10. Testing Strategy


### 10.1 Unit Tests
**File:** `test/logic/game_engine/nback_engine_test.dart`


```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nback_pro/src/logic/game_engine/nback_engine.dart';


void main() {
  group('NBackEngine', () {
    late NBackEngine engine;
   
    setUp(() {
      engine = NBackEngine();
    });
   
    test('generates correct number of trials', () {
      final trials = engine.generateSession(2, 22);
      expect(trials.length, 22);
    });
   
    test('match rate is approximately 30%', () {
      final trials = engine.generateSession(2, 100);
      int audioMatches = trials.where((t) => t.isAudioMatch).length;
      int visualMatches = trials.where((t) => t.isVisualMatch).length;
     
      // Allow ±10% variance (20-40% range)
      expect(audioMatches, inInclusiveRange(20, 40));
      expect(visualMatches, inInclusiveRange(20, 40));
    });
   
    test('no matches occur before N trials', () {
      final trials = engine.generateSession(3, 23);
     
      // First 3 trials should have no matches
      expect(trials[0].isAudioMatch, false);
      expect(trials[0].isVisualMatch, false);
      expect(trials[1].isAudioMatch, false);
      expect(trials[1].isVisualMatch, false);
      expect(trials[2].isAudioMatch, false);
      expect(trials[2].isVisualMatch, false);
    });
  });
}
```


### 10.2 Widget Tests
**File:** `test/presentation/screens/home/home_screen_test.dart`


```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


void main() {
  testWidgets('Home screen displays daily challenge card', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );
   
    expect(find.text('Daily Challenge'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}
```


### 10.3 Integration Tests
**File:** `integration_test/app_test.dart`


```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
 
  testWidgets('Complete game session flow', (tester) async {
    // Launch app (use NBackApp with ProviderScope; may need Hive/Firebase init for full flow)
    await tester.pumpWidget(ProviderScope(child: NBackApp()));
    await tester.pumpAndSettle();
   
    // Skip onboarding (if first launch)
    // Navigate to game
    // Complete a session
    // Verify stats updated
  });
}
```


### 10.4 Test Coverage Goals
- **Unit Tests:** >80% coverage for logic layer
- **Widget Tests:** All critical UI components
- **Integration Tests:** 3-5 key user flows
- **Performance Tests:** Game loop maintains 60fps


Run tests:
```bash
flutter test --coverage
flutter test integration_test/
```


---


## 11. Analytics & Monitoring


### 11.1 Firebase Analytics Setup
Add to `pubspec.yaml`:
```yaml
firebase_analytics: ^10.8.0
firebase_crashlytics: ^3.4.9
```


**File:** `lib/src/data/services/analytics_service.dart`


```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';


class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
 
  // Track session completion
  Future<void> logSessionComplete({
    required int nLevel,
    required double accuracy,
    required int duration,
  }) async {
    await _analytics.logEvent(
      name: 'session_complete',
      parameters: {
        'n_level': nLevel,
        'accuracy': accuracy,
        'duration_seconds': duration,
      },
    );
  }
 
  // Track daily challenge
  Future<void> logDailyChallengeComplete(int streak) async {
    await _analytics.logEvent(
      name: 'daily_challenge_complete',
      parameters: {'streak': streak},
    );
  }
 
  // Track settings changes
  Future<void> logSettingChanged(String setting, dynamic value) async {
    await _analytics.logEvent(
      name: 'setting_changed',
      parameters: {
        'setting_name': setting,
        'value': value.toString(),
      },
    );
  }
}
```


### 11.2 Crash Reporting
Initialize in `main.dart`:


```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  // Initialize Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
 
  runApp(ProviderScope(child: NBackApp()));
}
```


### 11.3 Key Metrics to Track
1. **Engagement:**
   - Daily Active Users (DAU)
   - Session frequency
   - Average session duration
   - Daily challenge completion rate


2. **Performance:**
   - N-level distribution (how many users reach N=3, 4, 5+)
   - Average accuracy per N-level
   - Retention (Day 1, Day 7, Day 30)


3. **Features:**
   - Auto-N vs Manual-N usage
   - Speed multiplier distribution
   - Theme preferences
   - Focus music usage


4. **Technical:**
   - Crash-free rate (target: >99.5%)
   - App startup time
   - Memory usage during sessions


---


## 12. Performance Optimization


### 12.1 Memory Management
**File:** `lib/src/data/services/audio_service.dart`


```dart
class AudioService {
  final Map<String, AudioPlayer> _preloadedPlayers = {};
 
  // Preload audio files on app start
  Future<void> preloadAudio() async {
    final letters = ['c', 'h', 'k', 'l', 'q', 'r', 's', 't'];
   
    for (final letter in letters) {
      final player = AudioPlayer();
      await player.setSource(AssetSource('audio/$letter.mp3'));
      _preloadedPlayers[letter] = player;
    }
  }
 
  // Play preloaded audio (faster)
  Future<void> playLetter(String letter) async {
    final player = _preloadedPlayers[letter.toLowerCase()];
    if (player != null) {
      await player.seek(Duration.zero);
      await player.resume();
    }
  }
 
  // Dispose on app close
  void dispose() {
    for (final player in _preloadedPlayers.values) {
      player.dispose();
    }
  }
}
```


### 12.2 Battery Optimization
- Use `WakelockPlus` only during active game sessions
- Stop all timers when app goes to background
- Reduce animation frame rate when not in focus


Add to `pubspec.yaml`:
```yaml
wakelock_plus: ^1.1.4
```


**Usage in game screen:**
```dart
@override
void initState() {
  super.initState();
  WakelockPlus.enable(); // Keep screen on during game
}


@override
void dispose() {
  WakelockPlus.disable();
  super.dispose();
}
```


### 12.3 Performance Checklist
- [ ] Preload all audio files on app start
- [ ] Use `const` constructors where possible
- [ ] Implement lazy loading for stats history (paginate)
- [ ] Cache theme data to avoid rebuilds
- [ ] Use `RepaintBoundary` for game grid
- [ ] Profile with Flutter DevTools (check for jank)
- [ ] Test on low-end devices (2GB RAM)
- [ ] Optimize image assets (compress, use WebP)
- [ ] Minimize widget rebuilds (use `Consumer` wisely)


### 12.4 App Size Optimization
- Remove unused dependencies
- Use `--split-per-abi` for Android builds
- Compress assets (audio, animations)
- Target app size: <30MB


---


## 13. Implementation Checklist


### Phase 1: Project Foundation (Day 1)
- [ ] **1.1** Run `flutter create --org com.yourcompany nback_pro`
- [ ] **1.2** Open project in VS Code / Android Studio
- [ ] **1.3** Copy complete `pubspec.yaml` from Section 1.2
- [ ] **1.4** Run `flutter pub get` to install dependencies
- [ ] **1.5** Create folder structure exactly as specified in Section 1.4
- [ ] **1.6** Create `lib/src/core/constants/app_strings.dart` with all text constants
- [ ] **1.7** Create `lib/src/core/constants/asset_paths.dart` with asset path constants
- [ ] **1.8** Set up Firebase project (console.firebase.google.com)
- [ ] **1.9** Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- [ ] **1.10** Add Firebase config files: place `google-services.json` in `android/app/`, and `GoogleService-Info.plist` in `ios/Runner/` (and add to Xcode project). If omitted, app runs in guest-only mode.
- [ ] **1.11** Initialize Hive in `main.dart`:
  ```dart
  await Hive.initFlutter();
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(SessionResultAdapter());
  Hive.registerAdapter(UserStreakAdapter());
  ```


### Phase 2: Data Layer (Day 2)
- [ ] **2.1** Create `lib/src/data/models/user_settings.dart` with Hive annotations
- [ ] **2.2** Create `lib/src/data/models/session_result.dart` with Hive annotations
- [ ] **2.3** Create `lib/src/data/models/user_streak.dart` with Hive annotations
- [ ] **2.4** Run `flutter pub run build_runner build` to generate adapters
- [ ] **2.5** Create `lib/src/data/repositories/settings_repository.dart`
  - [ ] Implement `getSettings()` method
  - [ ] Implement `saveSettings(UserSettings)` method
  - [ ] Implement default settings initialization
- [ ] **2.6** Create `lib/src/data/repositories/stats_repository.dart`
  - [ ] Implement `saveSession(SessionResult)` method
  - [ ] Implement `getAllSessions()` method
  - [ ] Implement `getAverageN()` method
  - [ ] Implement `getCurrentStreak()` method
- [ ] **2.7** Create `lib/src/data/services/auth_service.dart`
  - [ ] Implement Google Sign-In
  - [ ] Implement Apple Sign-In (iOS only)
  - [ ] Implement guest mode flag
- [ ] **2.8** Create `lib/src/data/services/audio_service.dart`
  - [ ] Implement `playLetter(String)` method
  - [ ] Implement `startFocusMusic()` method
  - [ ] Implement `stopFocusMusic()` method
  - [ ] Add error handling for missing audio files


### Phase 3: Core Logic & Game Engine (Day 3-4)
- [ ] **3.1** Create `lib/src/logic/game_engine/trial.dart` model class
- [ ] **3.2** Create `lib/src/logic/game_engine/nback_engine.dart`
  - [ ] Implement `generateSession(int n, int totalTrials)` method
  - [ ] Ensure 30% match rate algorithm
  - [ ] Add randomization for positions (0-8)
  - [ ] Add randomization for letters (C,H,K,L,Q,R,S,T)
- [ ] **3.3** Write unit tests for `NBackEngine`:
  - [ ] Test match rate is ~30% (±5%)
  - [ ] Test no matches occur before N trials
  - [ ] Test correct trial count (20+N)
- [ ] **3.4** Create `lib/src/logic/providers/settings_provider.dart` (Riverpod)
  - [ ] Expose `UserSettings` state
  - [ ] Implement `updateTheme(int)` method
  - [ ] Implement `toggleAutoN()` method
  - [ ] Implement `setSpeedMultiplier(double)` method
- [ ] **3.5** Create `lib/src/logic/providers/game_provider.dart` (Riverpod)
  - [ ] Implement session state management
  - [ ] Implement `startSession(int n)` method
  - [ ] Implement `submitResponse(bool audio, bool visual)` method
  - [ ] Implement `calculateScore()` method
  - [ ] Implement `adjustNLevel(double accuracy)` Auto-N logic
- [ ] **3.6** Create `lib/src/logic/providers/stats_provider.dart` (Riverpod)
  - [ ] Expose session history
  - [ ] Expose average N calculation
  - [ ] Expose streak data


### Phase 4: Theme System (Day 5)
- [ ] **4.1** Create `lib/src/core/theme/app_theme.dart`
- [ ] **4.2** Define Theme 0 (Dark BW) with exact hex codes from Section 4.1
- [ ] **4.3** Define Theme 1 (Dark Navy) with exact hex codes
- [ ] **4.4** Define Theme 2 (Dark Forest) with exact hex codes
- [ ] **4.5** Define Theme 3 (Light Paper) with exact hex codes
- [ ] **4.6** Define Theme 4 (Light Sand) with exact hex codes
- [ ] **4.7** Define Theme 5 (Light Sage) with exact hex codes
- [ ] **4.8** Create `getTheme(int id)` method returning `ThemeData`
- [ ] **4.9** Test theme switching in app


### Phase 5: Navigation & App Shell (Day 6)
- [ ] **5.1** Create `lib/src/app.dart` with MaterialApp wrapper
- [ ] **5.2** Set up GoRouter with routes:
  - [ ] `/` → Theme Selection (first launch only)
  - [ ] `/login` → Login Screen
  - [ ] `/home` → Home Dashboard
  - [ ] `/tutorial` → Tutorial Screens
  - [ ] `/game` → Game Screen
  - [ ] `/settings` → Settings Screen
  - [ ] `/stats` → Stats Screen
- [ ] **5.3** Implement first-launch detection (check if settings exist)
- [ ] **5.4** Add theme provider to app root


### Phase 6: Onboarding Screens (Day 7)
- [ ] **6.1** Create `lib/src/presentation/screens/onboarding/theme_selection_screen.dart`
  - [ ] Build 2x3 GridView of theme cards
  - [ ] Each card shows preview colors
  - [ ] Tap card → save to Hive → navigate to login
- [ ] **6.2** Create `lib/src/presentation/screens/onboarding/login_screen.dart`
  - [ ] Add app logo at top
  - [ ] Add "Sign in with Google" button
  - [ ] Add "Sign in with Apple" button (Platform.isIOS check)
  - [ ] Add "Continue as Guest" button
  - [ ] Show warning dialog for guest mode
  - [ ] Navigate to home on success


### Phase 7: Home Screen (Day 8)
- [ ] **7.1** Create `lib/src/presentation/screens/home/home_screen.dart`
- [ ] **7.2** Add greeting header ("Good Morning, [Name]")
- [ ] **7.3** Create Daily Challenge Card widget:
  - [ ] Check if completed today
  - [ ] Show checkmark if done, "Start" button if not
  - [ ] Display current streak
  - [ ] Tap → start game session
- [ ] **7.4** Add Quick Action buttons:
  - [ ] "Training Tutorial" → navigate to tutorial
  - [ ] "Stats" → navigate to stats
  - [ ] "Settings" → navigate to settings
- [ ] **7.5** Add footer showing current N-level


### Phase 8: Tutorial Screens (Day 9)
- [ ] **8.1** Create `lib/src/presentation/screens/tutorial/n1_rules_screen.dart`
  - [ ] Add explanation text
  - [ ] Add Lottie animation player
  - [ ] Add "Next" button → navigate to N=2 screen
- [ ] **8.2** Create `lib/src/presentation/screens/tutorial/n2_rules_screen.dart`
  - [ ] Add explanation text
  - [ ] Add Lottie animation player
  - [ ] Add "Next" button → navigate to progression screen
- [ ] **8.3** Create `lib/src/presentation/screens/tutorial/progression_info_screen.dart`
  - [ ] Add Auto-N explanation text
  - [ ] Add "Start Training" button → navigate to home


### Phase 9: Game Screen (Day 10-11)
- [ ] **9.1** Create `lib/src/presentation/screens/game/game_screen.dart`
- [ ] **9.2** Build top bar:
  - [ ] Progress indicator (current trial / total trials)
  - [ ] Pause button
- [ ] **9.3** Build 3x3 grid widget:
  - [ ] 9 squares in GridView
  - [ ] Highlight active square with theme primary color
  - [ ] Animate square appearance (fade in)
- [ ] **9.4** Build bottom button row:
  - [ ] "Audio Match" button (left)
  - [ ] "Visual Match" button (right)
  - [ ] Implement tap handlers
  - [ ] Add feedback animation if enabled (border flash)
- [ ] **9.5** Implement game loop:
  - [ ] Timer with `Duration = 3000ms / speedMultiplier`
  - [ ] Show stimulus for 500ms
  - [ ] Hide stimulus for remaining time
  - [ ] Play audio letter on stimulus show
  - [ ] Track user responses
- [ ] **9.6** Create Session Summary Dialog:
  - [ ] Show N-level, accuracy scores
  - [ ] Show Auto-N adjustment message
  - [ ] Add "View Stats", "Play Again", "Home" buttons
- [ ] **9.7** Implement pause functionality:
  - [ ] Pause timer
  - [ ] Show resume/quit dialog


### Phase 10: Settings Screen (Day 12)
- [ ] **10.1** Create `lib/src/presentation/screens/settings/settings_screen.dart`
- [ ] **10.2** Add Daily Reminder setting with TimePicker
- [ ] **10.3** Add Auto N toggle switch
- [ ] **10.4** Add My N slider (1-5, disabled if Auto N is on)
- [ ] **10.5** Add Speed slider (0.5x to 3x)
  - [ ] Show warning dialog if < 1.0
- [ ] **10.6** Add Continuous Feedback toggle
  - [ ] Show warning dialog if turned ON
- [ ] **10.7** Add Focus Music toggle
- [ ] **10.8** Add Theme selector (reopens theme selection)
- [ ] **10.9** Add "Give Feedback" button (email launcher)
- [ ] **10.10** Add "Privacy Policy" link
- [ ] **10.11** Add "Terms of Use" link


### Phase 11: Stats Screen (Day 13)
- [ ] **11.1** Create `lib/src/presentation/screens/statistics/stats_screen.dart`
- [ ] **11.2** Add header "Your Progress"
- [ ] **11.3** Display key metrics cards:
  - [ ] Average N Level
  - [ ] Current N Level (highest achieved)
  - [ ] Total Sessions
  - [ ] Current Streak
- [ ] **11.4** Add line chart (fl_chart):
  - [ ] X-axis: Last 30 days
  - [ ] Y-axis: N-level
  - [ ] Plot session N-levels
- [ ] **11.5** Add session history list:
  - [ ] Show date, N-level, accuracy for each session
  - [ ] Make scrollable


### Phase 12: Assets Integration (Day 14)
- [ ] **12.1** Create `assets/audio/` folder
- [ ] **12.2** Add 8 letter audio files (c.mp3, h.mp3, k.mp3, l.mp3, q.mp3, r.mp3, s.mp3, t.mp3)
- [ ] **12.3** Create `assets/animations/` folder
- [ ] **12.4** Create or source `n1_demo.json` Lottie animation
- [ ] **12.5** Create or source `n2_demo.json` Lottie animation
- [ ] **12.6** Create `assets/music/` folder (optional)
- [ ] **12.7** Add `focus_ambient.mp3` background music
- [ ] **12.8** Update `pubspec.yaml` assets section:
  ```yaml
  assets:
    - assets/audio/
    - assets/animations/
    - assets/music/
  ```
- [ ] **12.9** Run `flutter pub get`


### Phase 13: Notifications (Day 15)
- [ ] **13.1** Add `flutter_local_notifications` to pubspec.yaml
- [ ] **13.2** Create `lib/src/data/services/notification_service.dart`
- [ ] **13.3** Initialize notification plugin in main.dart
- [ ] **13.4** Request notification permissions (Android 13+)
- [ ] **13.5** Implement `scheduleDailyReminder(TimeOfDay)` method
- [ ] **13.6** Implement notification tap handler (open app to home)
- [ ] **13.7** Test notification on device


### Phase 14: Error Handling & Edge Cases (Day 16)
- [ ] **14.1** Implement mid-session save/resume:
  - [ ] Save current trial index to Hive on app pause
  - [ ] Show resume dialog on app resume
- [ ] **14.2** Handle timezone changes in streak logic
- [ ] **14.3** Add try-catch for Firebase Auth failures
- [ ] **14.4** Implement N-level cap at 10
- [ ] **14.5** Add fallback for audio playback failures
- [ ] **14.6** Add loading states for all async operations
- [ ] **14.7** Add error snackbars/toasts for user feedback


### Phase 15: Testing & Polish (Day 17-18)
- [ ] **15.1** Test on Android emulator:
  - [ ] All screens navigate correctly
  - [ ] Theme switching works
  - [ ] Game loop runs smoothly
  - [ ] Audio plays correctly
  - [ ] Stats calculate correctly
- [ ] **15.2** Test on iOS simulator (if available):
  - [ ] Apple Sign-In works
  - [ ] All features work as on Android
- [ ] **15.3** Test edge cases:
  - [ ] First launch experience
  - [ ] Guest mode limitations
  - [ ] Streak reset after missed day
  - [ ] Auto-N adjustment at boundaries
- [ ] **15.4** Performance testing:
  - [ ] Game runs at 60fps
  - [ ] No memory leaks during long sessions
  - [ ] App size is reasonable (<50MB)
- [ ] **15.5** Add app icon (1024x1024)
- [ ] **15.6** Add splash screen
- [ ] **15.7** Write README.md with setup instructions


### Phase 16: Store Preparation (Day 19-20)
- [ ] **16.1** Create Privacy Policy document
- [ ] **16.2** Create Terms of Use document
- [ ] **16.3** Prepare app store screenshots (5-8 per platform)
- [ ] **16.4** Write app description (short & long)
- [ ] **16.5** Prepare promotional graphics
- [ ] **16.6** Test on real Android device
- [ ] **16.7** Test on real iOS device (if available)
- [ ] **16.8** Build release APK/AAB for Android
- [ ] **16.9** Build release IPA for iOS
- [ ] **16.10** Submit to Google Play Store
- [ ] **16.11** Submit to Apple App Store


**Total Estimated Time: 20 days (assuming 4-6 hours/day)**



