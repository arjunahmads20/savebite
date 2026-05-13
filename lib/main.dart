import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'screens/explore/explore_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/add_good/add_good_screen.dart';
import 'screens/my_good_list/my_good_list_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('id'), Locale('ja')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const SaveBiteApp(),
      ),
    ),
  );
}

class SaveBiteApp extends StatelessWidget {
  const SaveBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaveBite',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          );
        }
        
        if (auth.isAuthenticated) {
          // Start chat polling when authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ChatProvider>().startPolling();
          });
          return const MainNavigationScreen();
        } else {
          // Stop polling when logged out
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ChatProvider>().stopPolling();
          });
          return const LoginScreen();
        }
      },
    );
  }
}

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    ExploreScreen(),
    AddGoodScreen(),
    MyGoodListScreen(),
    ChatListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    return Scaffold(
      body: _screens[nav.currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: nav.currentIndex,
        onTap: (i) => context.read<NavigationProvider>().goToTab(i),
      ),
    );
  }
}
