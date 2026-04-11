import 'package:flutter/material.dart';
import 'package:kyc/app/router.dart';
import 'package:kyc/core/theme/app_theme.dart';
import 'package:kyc/device_intelligence/model/network_security_model.dart';

class MyApp extends StatelessWidget {
  final NetworkSecurityModel networkCheck;
  const MyApp({super.key, required this.networkCheck});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KYC App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: buildRouter(networkCheck), // pass check to router
    );
  }
}
