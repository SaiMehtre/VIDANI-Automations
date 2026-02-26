import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/dashboard_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// import 'screens/alert_screen.dart';

///  Global navigator key
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  ///  Firebase init (WEB + ANDROID)
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBhJ2w66BYuolLcmJxRfBxC5R_ZhGoRFhk",
        authDomain: "vidani-automations.firebaseapp.com",
        projectId: "vidani-automations",
        storageBucket: "vidani-automations.firebasestorage.app",
        messagingSenderId: "685588830735",
        appId: "1:685588830735:web:c70759ed21a6373c4da17a",
        measurementId: "G-RTKDWY6GNF",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}


// ======auth check for auto login========

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
  final prefs = await SharedPreferences.getInstance();

  final rememberMe = prefs.getBool('remember_me') ?? false;
  final username = prefs.getString('username');
  final token = prefs.getString('token');

  if (rememberMe && username != null && token != null) {
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          username: username,
        ),
      ),
    );
  } else {
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Vidani Automations',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            height: 1.15,
            letterSpacing: 0.4,
          ),
        ),
      ),
      // home: const LoginScreen(),
      home: const AuthCheck(),
    );
  }
}


