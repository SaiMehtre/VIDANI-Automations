import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import '../services/secure_storage_service.dart';
import '../core/session_manager.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // keep only for rememberMe flag



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ================= CONTROLLERS =================
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ================= STATE =================
  bool _isLoading = false;
  bool rememberMe = false;

  String? errorText;

  // ================= LOGIN =================
 Future<void> _login() async {
  setState(() {
    _isLoading = true;
    errorText = null;
  });

  final username = _usernameController.text.trim();
  final password = _passwordController.text.trim();

  if (username.isEmpty || password.isEmpty) {
    setState(() {
      _isLoading = false;
      errorText = 'Username and password are required';
    });
    return;
  }

  final result = await AuthService.login(
    username: username,
    password: password,
  );

  if (!mounted) return;

  if (result.token != null) {
    if (rememberMe) {
      await SecureStorageService.saveToken(result.token!);
      await SecureStorageService.saveUsername(username);
      await SecureStorageService.savePassword(password);
    } else {
      SessionManager.setToken(result.token!);  // 🔥 memory me store
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          username: username,
        ),
      ),
    );
  } else {
    setState(() {
      errorText = result.message ?? "Login failed";
      _isLoading = false;
    });
  }
}

  // ================= Remember me =================
  @override
void initState() {
  super.initState();
  _loadSavedCredentials();
  _checkAutoLogin();
}

Future<void> _checkAutoLogin() async {
  final token = await SecureStorageService.getToken();

  if (token != null) {
    final username = await SecureStorageService.getUsername() ?? "";

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          username: username,
        ),
      ),
    );
  }
}
Future<void> _loadSavedCredentials() async {
  final savedUsername = await SecureStorageService.getUsername();
  final savedPassword = await SecureStorageService.getPassword();

  if (savedUsername != null && savedPassword != null) {
    _usernameController.text = savedUsername;
    _passwordController.text = savedPassword;
    setState(() {
      rememberMe = true;
    });
  }
}
@override
void dispose() {
  _usernameController.dispose();
  _passwordController.dispose();
  super.dispose();
}


  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade400],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxWidth < 600;

                      return Column(
                        children: [
                          // Shield / App Icon
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16), //  radius yaha change karo
                            child: Image.asset(
                              'assets/images/vidani_icon.png',
                              height: isSmallScreen ? 70 : 90,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Main Title
                          Text(
                            'IoT Pump Health Monitoring &\nControl Platform',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            'Industrial Pump Health Management System',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 15,
                              color: Colors.white70,
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      );
                    },
                  ),


                  // ========== LOGIN CARD ==========
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _usernameController,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    rememberMe = value ?? false;
                                  });
                                },
                              ),
                              const Text(
                                "Remember me",
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),

                          
                        if (errorText != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              errorText!,
                              style:
                                  TextStyle(color: Colors.red.shade700),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        const SizedBox(height: 26),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      color:Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxWidth < 600;

                      return Column(
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            '© 2026 Vidani Automations Pvt Ltd. All rights reserved.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
