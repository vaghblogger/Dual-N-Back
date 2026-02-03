/// Application string constants for Dual N-Back Pro.
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Dual N-Back Pro';
  static const String appTitle = 'Dual N-Back';

  // Onboarding
  static const String selectTheme = 'Choose your theme';
  static const String signInWithGoogle = 'Sign in with Google';
  static const String signInWithApple = 'Sign in with Apple';
  static const String continueAsGuest = 'Continue as Guest';
  static const String guestModeWarningTitle = 'Continue as Guest?';
  static const String guestModeWarningMessage =
      'Progress is saved on this device. Sign in later to sync across devices.';
  static const String login = 'Login';
  static const String account = 'Account';
  static const String notLoggedIn = 'Guest';
  static const String signedInAsGuest = 'Signed in as guest';
  static const String loginToSaveProgress = 'Log in to Save your progress across devices.';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String signInCancelledOrUnavailable =
      'Sign-in cancelled or unavailable. Check that Firebase is configured.';
  static const String signInFailedWebClientId =
      'Google Sign-In failed: need Web client ID. Add a Web app in Firebase, re-download google-services.json for Android, or run with: flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID';
  static const String signOut = 'Sign out';

  // Home
  static const String goodMorning = 'Good Morning';
  static const String goodAfternoon = 'Good Afternoon';
  static const String goodEvening = 'Good Evening';
  static const String guest = 'Guest';
  static const String dailyChallenge = 'Daily Challenge';
  static const String dailyChallengeLevel = 'N-Back level';
  static const String maintainYourStreak = 'Maintain your streak!';
  static const String todayYouWillTrainOnN = 'Today you will train on N=%d';
  static const String dailyChallengeChooseLevelUpTo =
      'Choose level 1 to %d (your current max). You cannot advance to the next level from here.';
  static const String dailyChallengeCompleted = "You've completed today's challenge.";
  static const String dailyChallengeComeBackTomorrow = 'Come back tomorrow for your next challenge.';
  static const String trainYourBrain = 'Pro Training';
  static const String trainYourBrainSubtitle =
      'Control difficulty, speed, and look. Your brain, your rules.';
  static const String go = 'Go';
  static const String start = 'Start';
  static const String maintainStreak = 'Maintain your %d day streak!';
  static const String weeklyStreak = 'Weekly Streak';
  static const String daysThisWeek = '%d days this week';
  static const String weeklyStreakSubtitle = 'Sessions in the last 7 days.';
  static const String trainingTutorial = 'Training Tutorial';
  static const String stats = 'Stats';
  static const String settings = 'Settings';
  static const String currentLevel = 'Current Level: N-Back %d';
  static const String playingAt = 'Playing at: N-Back %d';
  static const String trainCurrentLevelIndicator = 'Current Level = N-Back %d';

  // Tutorial / Help
  static const String helpHubTitle = 'How to play';
  static const String n1RulesTitle = 'N=1: One step back';
  static const String n1RulesDescription =
      'Press Match when the current stimuli matches the one just shown.';
  static const String n1Step1 =
      'Each turn you see a **position** (one of 9 squares) and hear a **letter** (C, H, K, …).';
  static const String n1Step2 =
      'For **N=1**, a match means: same as the **previous** turn (1 step back).';
  static const String n1Step3 =
      'Tap **Visual Match** if the position is the same as last turn; tap **Audio Match** if the letter is the same.';
  static const String n1Step4 =
      'You can tap both if both match. Don\'t tap if neither matches.';
  static const String n2RulesTitle = 'N=2: Two steps back';
  static const String n2RulesDescription =
      'Press Match when the current stimuli matches the one shown 2 steps ago.';
  static const String n2Step1 =
      'Same as N=1: each turn = one **position** + one **letter**.';
  static const String n2Step2 =
      'For **N=2**, a match means: same as **2 turns ago** (not the last turn).';
  static const String n2Step3 =
      'Tap **Visual Match** if the position matches 2 turns ago; **Audio Match** if the letter matches 2 turns ago.';
  static const String n2Step4 =
      'Tap both if both match; don\'t tap if neither matches.';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String aboutAutoN = 'About Auto-N progression';
  static const String progressionTitle = 'Auto-N Progression';
  static const String progressionDescription =
      'We increase difficulty when you master the current level, and decrease when it\'s too hard. Stay in the flow!';
  static const String startTraining = 'Start Training';

  // Tutorial flow (10 screens)
  static const String tutorialIntroTitle = 'How Dual N-Back works';
  static const String tutorialIntroBody =
      'Each turn you see a position (one of 9 squares) and hear a letter.\n\n'
      'A match means: same as N steps back (N=1: last turn; N=2: 2 turns ago).\n\n'
      'Tap Position when the square matches; tap Audio when the letter matches. You can tap both if both match.';
  static const String tutorialN2TransitionTitle = 'Now N=2';
  static const String tutorialN2TransitionBody =
      'Same idea, but the match is 2 steps back — not the last turn.';
  static const String tutorialHigherNTitle = 'Higher N levels';
  static const String tutorialHigherNBody =
      'At N=3 you match 3 steps back, and so on. The higher the N, the harder the game. You can train at any N from 1 to 15.';
  static const String tutorialReadyTitle = 'Ready??';
  static const String tutorialGo = 'Go';
  static const String tutorialSkip = 'I know how N-Back works';
  static const String tutorialPrevious = 'Previous';
  static const String tutorialNext = 'Next';

  // Tutorial step titles (demo screens)
  static const String tutorialStepTitleN1Position = 'N=1: Position match';
  static const String tutorialStepTitleN1Audio = 'N=1: Audio match';
  static const String tutorialStepTitleN1Mixed = 'N=1: Position + Audio';
  static const String tutorialStepTitleN2Position = 'N=2: Position match';
  static const String tutorialStepTitleN2Audio = 'N=2: Audio match';
  static const String tutorialStepTitleN2Mixed = 'N=2: Position + Audio';

  // Guided demo messages (N=1)
  static const String tutorialMessagePositionSameN1 =
      'Current position is the same as last position.';
  static const String tutorialMessageAudioSameN1 =
      'Same letter as last turn.';
  static const String tutorialMessageBothSameN1 =
      'Same position and same letter.';
  // N=2
  static const String tutorialMessagePositionSameN2 =
      'Current position is the same as 2 steps back.';
  static const String tutorialMessageAudioSameN2 =
      'Same letter as 2 steps back.';
  static const String tutorialMessageBothSameN2 =
      'Same position and same letter as 2 steps back.';

  // Tutorial feedback (correct tap)
  static const List<String> tutorialFeedbackCorrect = [
    'Great!',
    'Wonderful!',
    "You're a fast learner!",
    'Nice!',
    'Perfect!',
    'Well done!',
  ];
  static const String tutorialWrongTitle = 'Wrong';
  static const String tutorialWrongRetryMessage =
      'Want to try again? We\'ll play the sequence again.';
  static const String tutorialRetry = 'Retry';

  // Game
  static const String audioMatch = 'AUDIO';
  static const String visualMatch = 'POSITION';
  static const String pause = 'Pause';
  static const String resume = 'Resume';
  static const String quit = 'Quit';
  static const String sessionComplete = 'Session Complete!';
  static const String sessionResults = 'Session results';
  static const String nLevel = 'N-Level: %d';
  static const String audioAccuracy = 'Audio Accuracy: %d%';
  static const String visualAccuracy = 'Visual Accuracy: %d%';
  static const String overallAccuracy = 'Overall Accuracy: %d%';
  static const String nLevelIncreased = 'Your N-level has been increased';
  static const String nLevelDecreased = 'Your N-level has been decreased';
  static const String nLevelMaintained = 'Your N-level has been maintained';
  static const String viewStats = 'View Stats';
  static const String playAgain = 'Play Again';
  static const String home = 'Home';
  static const String resumeSessionTitle = 'Resume session?';
  static const String resumeSessionMessage =
      'You have an incomplete session. Resume or start new?';
  static const String resumeSession = 'Resume';
  static const String startNew = 'Start New';

  // Settings
  static const String dailyReminder = 'Daily Reminder';
  static const String autoN = 'Auto N';
  static const String myN = 'My N';
  static const String myNSubtitle = 'Choose your own N level';
  static const String speed = 'Speed';
  static const String continuousFeedback = 'Continuous Feedback';
  static const String focusMusic = 'Focus Music';
  static const String showGrid = 'Show grid';
  static const String showGridSubtitle =
      'Hide grid lines for harder focus and maximum cognitive training.';
  static const String theme = 'Theme';
  static const String giveFeedback = 'Give Feedback';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsOfUse = 'Terms of Use';
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfUseUrl = 'https://example.com/terms';
  static const String feedbackEmail = 'feedback@example.com';
  static const String speedWarningTitle = 'Below scientific standards';
  static const String speedWarningMessage =
      'This speed is below scientific standards. You can increase it when comfortable.';
  static const String speedDefaultMessage =
      'Default 1.0 is the science-backed pace. Slower = more time; faster = push your limits.';
  static const String speedBelowOneNudge =
      'Not scientific pace, but you\'re good until you find yours.';
  static const String feedbackWarningTitle = 'Not scientifically standard';
  static const String feedbackWarningMessage =
      'Immediate feedback is not scientifically standard. You can disable it later.';
  static const String paywallNoAds =
      'No ads. We support the app through Pro — so you get a focused experience.';
  static const String settingsAdFree =
      'This app is ad-free. Pro subscriptions support development and unlock advanced features.';
  static const String paywallAfterTutorialMessage =
      "We don't use ads. Pro helps us keep the app ad-free and add new features.";
  static const String willDoItLater = 'Will do it Later';
  static const String paywallBenefitsTitle = 'What you get with Pro';
  static const String paywallBenefitNoAds = 'Ad-free experience';
  static const String paywallBenefitLevels = 'Train at N = 4–15 (higher levels)';
  static const String paywallBenefitUnlimited = 'Unlimited sessions per day';
  static const String paywallBenefitInsights =
      'Brain Insights: trends, heatmap, audio vs visual';
  static const String paywallBenefitThemes = 'Select from range of themes';
  static const String paywallBenefitControl = 'Speed & grid control';

  // Stats
  static const String yourProgress = 'Your Progress';
  static const String brainInsights = 'Brain Insights';
  static const String overview = 'Overview';
  static const String highestNLevel = 'Highest N';
  static const String averageNLevel = 'Average N Level';
  static const String currentNLevel = 'Current N Level';
  static const String totalSessions = 'Total Sessions';
  static const String currentStreak = 'Current Streak';
  static const String longestStreak = 'Longest Streak';
  static const String nLevelTrend = 'N-Level trend (last 30 days)';
  static const String sessionHistory = 'Session History';
  static const String last7Days = 'Last 7 days';
  static const String proInsightsTitle = 'Pro insights';
  static const String proInsightsDescription =
      'Weekly & monthly trends, audio vs visual breakdown, performance heatmap — Unlock Pro.';
  static const String unlockPro = 'Unlock Pro';
  static const String goPro = 'Go Pro';
  static const String notNow = 'Not now';
  static const String adFree = 'Ad-free';
  static const String sessionsToday = 'You completed %d session(s) today.';
  static const String lastSessionSummary = 'Last session: N=%d · %d%%';
  static const String totalSessionsCount = '%d sessions total';
  static const String dualChannelBreakdown = 'Audio vs Visual accuracy';
  static const String dualChannelSubtitle =
      'Are you stronger in visual or auditory working memory?';
  static const String performanceHeatmap = 'Performance heatmap';
  static const String performanceHeatmapSubtitle = 'When do you perform best?';
  static const String exportCsv = 'Export CSV';
  static const String shareProgressStory = 'Share progress story';
  static const String trend7d = '7d';
  static const String trend30d = '30d';
  static const String trend90d = '90d';

  // Notifications
  static const String dailyChallengeReminder = 'Daily N-Back Challenge';
  static const String streakReminder = 'Keep your %d day streak alive!';

  // Session summary motivational messages (shown randomly)
  static const List<String> motivationalMessages = [
    'Great focus! Every session strengthens your working memory.',
    'Well done! Consistency is key to cognitive gains.',
    'You are building a sharper mind. Keep it up!',
    'Strong work! Your brain thanks you.',
    'Another step forward. Stay curious!',
    'Progress happens one session at a time. You are doing it.',
    'Your dedication shows. Keep training!',
    'Nice session! Rest when needed, then come back.',
    'You showed up. That is what matters most.',
    'Small steps, big gains. Keep going!',
  ];

  // Errors
  static const String authFailed = 'Authentication failed. Try again or continue as guest.';
  static const String audioUnavailable = 'Audio unavailable. Visual-only mode.';
}
