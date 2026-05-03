import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/db_service.dart';
import 'services/match_service.dart';
import 'services/chat_service.dart';
// import 'services/payment_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/root_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<MatchService>(create: (_) => MatchService()),
        Provider<ChatService>(create: (_) => ChatService()),
        // Provider<PaymentService>(create: (_) => PaymentService()),
        Provider<NotificationService>(create: (_) => notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    return MaterialApp(
      title: 'Tanishuv',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      home: const RootScreen(),
    );
  }
}
