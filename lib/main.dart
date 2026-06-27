import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'services/advanced_download_manager.dart';
import 'services/media_conversion_service.dart';
import 'services/app_lock_service.dart';
import 'services/audio_effects_service.dart';
import 'services/haptic_service.dart';
import 'services/clipboard_watcher.dart';
import 'services/network_intelligence.dart';
import 'services/storage_manager.dart';
import 'services/unity_ads_service.dart';
import 'models/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(VideoInfoEntityAdapter());
  Hive.registerAdapter(DownloadTaskEntityAdapter());
  Hive.registerAdapter(ConversionTaskEntityAdapter());
  Hive.registerAdapter(UserSettingsEntityAdapter());
  Hive.registerAdapter(BrowserBookmarkEntityAdapter());

  // Initialize core services
  final audioService = AudioEffectsService();
  final hapticService = HapticService();
  final appLockService = AppLockService();
  await appLockService.init();

  // Initialize new intelligent services
  final networkIntelligence = NetworkIntelligence();
  final storageManager = StorageManager();
  final clipboardWatcher = ClipboardWatcher();

  final downloadManager = AdvancedDownloadManager(
    audioService: audioService,
    hapticService: hapticService,
    networkIntelligence: networkIntelligence,
    storageManager: storageManager,
  );
  await downloadManager.init();

  // ═══ تهيئة Unity Ads ═══
  UnityAdsService.initialize();

  final conversionService = MediaConversionService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider.value(value: downloadManager),
        ChangeNotifierProvider.value(value: conversionService),
        ChangeNotifierProvider.value(value: appLockService),
        ChangeNotifierProvider.value(value: clipboardWatcher),
        ChangeNotifierProvider.value(value: networkIntelligence),
        ChangeNotifierProvider.value(value: storageManager),
      ],
      child: const VidGrabApp(),
    ),
  );
}

class VidGrabApp extends StatelessWidget {
  const VidGrabApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final appLock = Provider.of<AppLockService>(context);
    final downloadManager = Provider.of<AdvancedDownloadManager>(context);

    // Check if app lock is enabled
    final shouldLock = appLock.isLocked && (downloadManager.settings?.appLockEnabled ?? false);

    return MaterialApp(
      title: 'VidGrab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      initialRoute: shouldLock ? AppRoutes.lock : AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}