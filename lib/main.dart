import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'services/cart_service.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep the app in portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Try loading the environment settings
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (e) {
    debugPrint('Could not load assets/.env: $e');
  }

  // Start up Firebase (Lab Activity 5).
  // Wrapped in try/catch so the app still runs (DummyJSON product loading
  // still works) even if the Firebase configuration is missing.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase could not start: $e');
  }

  runApp(const HusseinAdvMobProg());
}

class HusseinAdvMobProg extends StatelessWidget {
  const HusseinAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Set up the theme and cart services
      providers: [
        ChangeNotifierProvider(
          create: (_) => HusseinAdvmobprogThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => HusseinAdvmobprogCartService(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (buildContext, child) {
          final themeModel =
              buildContext.watch<HusseinAdvmobprogThemeProvider>();

          return MaterialApp(
            title: 'E-Commerce App',
            debugShowCheckedModeBanner: false,

            // Use the selected light or dark theme
            theme: themeModel.lightTheme,
            darkTheme: themeModel.darkTheme,
            themeMode:
                themeModel.isDark ? ThemeMode.dark : ThemeMode.light,

            // Start with the splash screen
            initialRoute: '/',

            // App screen routes
            routes: {
              '/': (context) =>
                  const HusseinAdvmobprogSplashScreen(),
              '/sign': (context) =>
                  const HusseinAdvmobprogSignScreen(),
              '/signup': (context) =>
                  const HusseinAdvmobprogSignupScreen(),
              '/home': (context) =>
                  const HusseinAdvmobprogHomeScreen(),
              '/settings': (context) =>
                  const HusseinAdvmobprogSettingsScreen(),
              '/chat': (context) =>
                  const HusseinAdvmobprogChatScreen(),
            },
          );
        },
      ),
    );
  }
}