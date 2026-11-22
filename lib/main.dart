import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/session.dart';
import 'core/ui_helpers.dart';
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
        theme: _flatTheme(),
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
          if (settings.name == '/request-detail' && settings.arguments is int) {
            return MaterialPageRoute(
              builder: (context) => RequestDetailScreen(requestId: settings.arguments as int),
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
    final auth = context.read<AuthProvider>();
    // Restore the session while the splash is showing (at least 1.5 s).
    await Future.wait([
      auth.tryAutoLogin(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);

    if (!mounted) return;

    if (auth.isLoggedIn) {
      goToHome(context);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/BSR_Logo_1.png', width: 260),
                const SizedBox(height: 16),
                const Text(
                  'Dubinan East',
                  style: TextStyle(color: kGray, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(minHeight: 3, backgroundColor: kLine),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Flat look: no shadows or tints, thin gray borders, black text,
/// orange for actions and yellow for highlights.
ThemeData _flatTheme() {
  final radius = BorderRadius.circular(12);
  OutlineInputBorder inputBorder([BorderSide side = BorderSide.none]) =>
      OutlineInputBorder(borderRadius: radius, borderSide: side);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kOrange,
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
      primary: kOrange,
      onPrimary: kBlack,
      secondary: kYellow,
      onSecondary: kBlack,
      error: kRed,
      surface: kWhite,
      onSurface: kBlack,
      onSurfaceVariant: kGray,
      outline: kLine,
      outlineVariant: kLine,
      surfaceContainerLowest: kWhite,
      surfaceContainerLow: kWhite,
      surfaceContainer: kWhite,
      surfaceContainerHigh: kWhite,
      surfaceContainerHighest: kSurface,
    ),
    scaffoldBackgroundColor: kWhite,
    appBarTheme: const AppBarTheme(
      backgroundColor: kWhite,
      foregroundColor: kBlack,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kBlack, letterSpacing: -0.4),
      shape: Border(bottom: BorderSide(color: kLine)),
    ),
    cardTheme: CardThemeData(
      color: kWhite,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: kLine)),
    ),
    dividerTheme: const DividerThemeData(color: kLine, thickness: 1),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kOrange,
        foregroundColor: kBlack,
        disabledBackgroundColor: kLine,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kBlack,
        side: const BorderSide(color: kBlack, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kBlack,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: kWhite,
        foregroundColor: kBlack,
        selectedBackgroundColor: kBlack,
        selectedForegroundColor: kWhite,
        side: const BorderSide(color: kLine),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kOrange,
      foregroundColor: kBlack,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      prefixIconColor: kGray,
      suffixIconColor: kGray,
      labelStyle: const TextStyle(color: kGray),
      floatingLabelStyle: const TextStyle(color: kBlack, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: kGray),
      border: inputBorder(),
      enabledBorder: inputBorder(),
      disabledBorder: inputBorder(),
      focusedBorder: inputBorder(const BorderSide(color: kBlack, width: 1.5)),
      errorBorder: inputBorder(const BorderSide(color: kRed)),
      focusedErrorBorder: inputBorder(const BorderSide(color: kRed, width: 1.5)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: kWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: kYellow,
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: kBlack)),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kBlack),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: kBlack,
      unselectedLabelColor: kGray,
      indicatorColor: kOrange,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      labelStyle: TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
    ),
    badgeTheme: const BadgeThemeData(backgroundColor: kOrange, textColor: kBlack),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kOrange),
    dialogTheme: DialogThemeData(
      backgroundColor: kWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kBlack),
      contentTextStyle: const TextStyle(fontSize: 14, color: kBlack, height: 1.4),
    ),
    popupMenuTheme: const PopupMenuThemeData(color: kWhite, surfaceTintColor: Colors.transparent),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kBlack,
      contentTextStyle: const TextStyle(color: kWhite),
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
  );
}
