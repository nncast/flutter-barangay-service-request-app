import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/request_provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/requests/submit_request_screen.dart';
import 'screens/requests/request_detail_screen.dart';

void main() {
  runApp(const BarangayApp());
}

class BarangayApp extends StatelessWidget {
  const BarangayApp({super.key});

  // Color constants
  static const Color white = Color(0xFFFFFFFF);
  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Barangay Service System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: burntOrange,
            foregroundColor: white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: burntOrange,
              foregroundColor: white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/admin': (context) => const AdminHomeScreen(),
          '/submit-request': (context) => const SubmitRequestScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/request-detail') {
            final id = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) => RequestDetailScreen(requestId: id),
            );
          }
          return null;
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Show splash for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    await auth.tryAutoLogin();

    if (!mounted) return;

    // Navigate based on authentication status and role
    if (auth.isLoggedIn) {
      if (auth.isStaff) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Color constants matching LoginScreen
    const Color white = Color(0xFFFFFFFF);
    const Color burntOrange = Color(0xFFBE5633);
    const Color darkBrown = Color(0xFF46291D);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFAD793), // Cream Gold (from LoginScreen)
              burntOrange,
              darkBrown,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // BSR Logo matching LoginScreen style
                Image.asset(
                  'assets/images/BSR_Logo_2.png',
                  height: 200,
                  width: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        size: 80,
                        color: burntOrange,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                // Barangay Name Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Dubinan East',
                    style: TextStyle(
                      color: white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                // Loading Indicator
                const CircularProgressIndicator(
                  color: white,
                  strokeWidth: 2,
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}