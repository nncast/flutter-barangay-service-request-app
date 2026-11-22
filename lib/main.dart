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

/// Flat look: no shadows or tints, charcoal text,
/// orange for actions and yellow for highlights.
ThemeData _flatTheme() {
  final radius = BorderRadius.circular(16);
  OutlineInputBorder inputBorder([BorderSide side = BorderSide.none]) =>
      OutlineInputBorder(borderRadius: radius, borderSide: side);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kOrange,
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
      primary: kOrange,
      onPrimary: kCharcoal,
      secondary: kYellow,
      onSecondary: kCharcoal,
      error: kRed,
      surface: kWhite,
      onSurface: kCharcoal,
      onSurfaceVariant: kGray,
      outline: kOutline,
      outlineVariant: kLine,
      surfaceContainerLowest: kWhite,
      surfaceContainerLow: kWhite,
      surfaceContainer: kWhite,
      surfaceContainerHigh: kWhite,
      surfaceContainerHighest: kSurface,
    ),
    scaffoldBackgroundColor: kCanvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: kCanvas,
      foregroundColor: kCharcoal,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kCharcoal, letterSpacing: -0.6),
    ),
    // White cards on the warm canvas, no borders or shadows.
    cardTheme: CardThemeData(
      color: kWhite,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    // Icon buttons sit in white circles, e.g. back, refresh, bell.
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(backgroundColor: kWhite)),
    dividerTheme: const DividerThemeData(color: kLine, thickness: 1),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kOrange,
        foregroundColor: kCharcoal,
        disabledBackgroundColor: kLine,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kCharcoal,
        side: const BorderSide(color: kCharcoal, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kCharcoal,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: kWhite,
        foregroundColor: kCharcoal,
        selectedBackgroundColor: kCharcoal,
        selectedForegroundColor: kWhite,
        side: BorderSide.none,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: const StadiumBorder(),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kOrange,
      foregroundColor: kCharcoal,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: StadiumBorder(),
      extendedTextStyle: TextStyle(fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kWhite,
      prefixIconColor: kGray,
      suffixIconColor: kGray,
      labelStyle: const TextStyle(color: kGray),
      floatingLabelStyle: const TextStyle(color: kCharcoal, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: kGray),
      border: inputBorder(),
      enabledBorder: inputBorder(const BorderSide(color: kOutline)),
      disabledBorder: inputBorder(),
      focusedBorder: inputBorder(const BorderSide(color: kCharcoal, width: 1.5)),
      errorBorder: inputBorder(const BorderSide(color: kRed)),
      focusedErrorBorder: inputBorder(const BorderSide(color: kRed, width: 1.5)),
    ),
    // Charcoal pill on the selected tab.
    tabBarTheme: const TabBarThemeData(
      labelColor: kWhite,
      unselectedLabelColor: kGray,
      indicator: ShapeDecoration(color: kCharcoal, shape: StadiumBorder()),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelStyle: TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
    ),
    badgeTheme: const BadgeThemeData(backgroundColor: kOrange, textColor: kCharcoal),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kOrangeDark),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? kWhite : kOutline),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? kCharcoal : kWhite),
      trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? kCharcoal : kOutline),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kCharcoal),
      contentTextStyle: const TextStyle(fontSize: 14, color: kCharcoal, height: 1.4),
    ),
    popupMenuTheme: const PopupMenuThemeData(color: kWhite, surfaceTintColor: Colors.transparent),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kCharcoal,
      contentTextStyle: const TextStyle(color: kWhite),
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
  );
}
