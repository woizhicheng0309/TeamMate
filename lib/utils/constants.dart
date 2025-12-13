class Constants {
  // App Info
  static const String appName = 'TeamMate';
  static const String appVersion = '1.0.0';

  // API Endpoints (Replace with your actual backend URL)
  static const String apiBaseUrl = 'https://your-api.com/api';

  // Supabase Configuration (Replace with your actual Supabase credentials)
  static const String supabaseUrl = 'https://mnmljxygcvpgkvnshchx.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ubWxqeHlnY3ZwZ2t2bnNoY2h4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1OTk4OTYsImV4cCI6MjA4MTE3NTg5Nn0.45Z8fP3dhOrVOX3AbEOQ7riywooXqY4OudnVJGj5CiY';

  // OneSignal Configuration (Replace with your actual OneSignal App ID)
  static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';

  // Location
  static const double defaultLatitude = 25.0330;
  static const double defaultLongitude = 121.5654;
  static const double defaultSearchRadius = 10.0; // km

  // Activity Types
  static const List<String> activityTypes = [
    'basketball',
    'badminton',
    'running',
    'cycling',
    'swimming',
    'hiking',
    'tennis',
    'football',
  ];

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
}
