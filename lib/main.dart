import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kyc/app/app.dart';

void main() async {
  // This line ensures Flutter's engine is ready before we do anything
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase — must happen before runApp()
  await Firebase.initializeApp();
  runApp(const MyApp());
}
