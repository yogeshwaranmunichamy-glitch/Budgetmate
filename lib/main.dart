import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app_state.dart';
import 'ad_service.dart';
import 'theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loads the AdMob SDK. Uses Google's official TEST ad unit IDs until you
  // swap in your own from admob.google.com — see lib/ad_service.dart.
  await MobileAds.instance.initialize();
  AdService.instance.preload();
  runApp(const BudgetMateApp());
}

class BudgetMateApp extends StatelessWidget {
  const BudgetMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: 'BudgetMate',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(state.darkMode),
            home: state.loading
                ? const Scaffold(body: Center(child: CircularProgressIndicator()))
                : (state.currentUser == null ? const AuthScreen() : const HomeShell()),
          );
        },
      ),
    );
  }
}
