import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kyc/app/app.dart';
import 'package:kyc/device_intelligence/repository/device_intelligence_repository.dart';

void main() async {
  // This line ensures Flutter's engine is ready before we do anything
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase — must happen before runApp()
  await Firebase.initializeApp();
  // Run network check early — result passed into app
  final networkCheck = await DeviceIntelligenceRepository().runCheck();
  runApp(MyApp(networkCheck: networkCheck));
}
