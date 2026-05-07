import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'ui/styles/app_colors.dart';
import 'ui/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/ad_service.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'dart:io';
// import 'firebase_options.dart'; // 대표님이 직접 생성하셔야 하는 파일입니다.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화 (웹 환경이 아닐 때만 혹은 서비스 키 세팅 후)
  try {
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform, 
    );
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint("Firebase Initialize Error: $e");
  }

  // 광고 SDK 초기화
  await AdService.init();

  // App Tracking Transparency (iOS)
  if (Platform.isIOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  // TODO: 카카오 개발자 센터에서 발급받은 실제 App Key로 교체해야 합니다. (이 키는 샘플입니다)
  KakaoSdk.init(
    nativeAppKey: 'YOUR_NATIVE_APP_KEY', 
    javaScriptAppKey: 'YOUR_JAVASCRIPT_APP_KEY',
  );

  runApp(const CrossfitApp());
}

class CrossfitApp extends StatelessWidget {
  const CrossfitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crossfit Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          background: AppColors.background,
          surface: AppColors.surface,
          primary: AppColors.primary,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppColors.textPrimary),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
