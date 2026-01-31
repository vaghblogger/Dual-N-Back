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
      'Progress will not be saved. Continue?';
  static const String yes = 'Yes';
  static const String no = 'No';

  // Home
  static const String goodMorning = 'Good Morning';
  static const String goodAfternoon = 'Good Afternoon';
  static const String goodEvening = 'Good Evening';
  static const String guest = 'Guest';
  static const String dailyChallenge = 'Daily Challenge';
  static const String trainYourBrain = 'Train your brain';
  static const String trainYourBrainSubtitle =
      'Choose N (1–15) and play a session. Does not change your settings.';
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

  // Tutorial
  static const String n1RulesTitle = 'N=1: One step back';
  static const String n1RulesDescription =
      'Press Match when the current stimuli matches the one just shown.';
  static const String n2RulesTitle = 'N=2: Two steps back';
  static const String n2RulesDescription =
      'Press Match when the current stimuli matches the one shown 2 steps ago.';
  static const String next = 'Next';
  static const String progressionTitle = 'Auto-N Progression';
  static const String progressionDescription =
      'We increase difficulty when you master the current level, and decrease when it\'s too hard. Stay in the flow!';
  static const String startTraining = 'Start Training';

  // Game
  static const String audioMatch = 'Audio Match';
  static const String visualMatch = 'Visual Match';
  static const String pause = 'Pause';
  static const String resume = 'Resume';
  static const String quit = 'Quit';
  static const String sessionComplete = 'Session Complete!';
  static const String nLevel = 'N-Level: %d';
  static const String audioAccuracy = 'Audio Accuracy: %d%%';
  static const String visualAccuracy = 'Visual Accuracy: %d%%';
  static const String overallAccuracy = 'Overall Accuracy: %d%%';
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
  static const String speed = 'Speed';
  static const String continuousFeedback = 'Continuous Feedback';
  static const String focusMusic = 'Focus Music';
  static const String theme = 'Theme';
  static const String giveFeedback = 'Give Feedback';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsOfUse = 'Terms of Use';
  static const String speedWarningTitle = 'Below scientific standards';
  static const String speedWarningMessage =
      'This speed is below scientific standards. You can increase it when comfortable.';
  static const String feedbackWarningTitle = 'Not scientifically standard';
  static const String feedbackWarningMessage =
      'Immediate feedback is not scientifically standard. You can disable it later.';

  // Stats
  static const String yourProgress = 'Your Progress';
  static const String averageNLevel = 'Average N Level';
  static const String currentNLevel = 'Current N Level';
  static const String totalSessions = 'Total Sessions';
  static const String currentStreak = 'Current Streak';
  static const String sessionHistory = 'Session History';

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
