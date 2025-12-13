import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize intl locale for date formatting
  Intl.defaultLocale = 'zh_TW';
  await initializeDateFormatting('zh_TW', null);

  // Initialize Supabase
  // TODO: Update Constants.dart with your Supabase credentials before uncommenting
  await Supabase.initialize(
    url: Constants.supabaseUrl,
    anonKey: Constants.supabaseAnonKey,
  );

  // Initialize OneSignal push notifications
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Constants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if Firebase is configured
    final bool isConfigured = Constants.supabaseUrl != 'YOUR_SUPABASE_URL';

    if (!isConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('配置需求')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.settings, size: 64, color: Colors.orange),
                const SizedBox(height: 24),
                const Text(
                  '需要完成配置',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  '請按照以下步驟完成設置：',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '1. 配置 Supabase',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text('   創建專案於 supabase.com'),
                        const Text('   啟用 Google OAuth Provider'),
                        const SizedBox(height: 12),
                        const Text(
                          '2. 更新 Constants',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text('   編輯 lib/utils/constants.dart'),
                        const SizedBox(height: 12),
                        const Text(
                          '3. 取消註解 main.dart',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text('   取消 Supabase.initialize()'),
                        const SizedBox(height: 12),
                        const Text(
                          '4. 重新啟動應用程式',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '詳細說明請查看 QUICKSTART.md',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final authService = AuthService();
    final notificationService = NotificationService();

    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show login screen if not authenticated
        if (snapshot.data?.event == AuthChangeEvent.signedOut ||
            snapshot.data?.session == null) {
          return const LoginScreen();
        }

        // 如果用戶已認證，設置 OneSignal 用戶 ID
        final userId = authService.userId;
        if (userId != null) {
          // 異步調用，不阻止 UI 構建
          Future.delayed(Duration.zero, () {
            notificationService.setUserId(userId);
          });
        }

        // Show home screen if authenticated
        return const HomeScreen();
      },
    );
  }
}
