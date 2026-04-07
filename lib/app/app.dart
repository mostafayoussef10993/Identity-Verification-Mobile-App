import 'package:flutter/material.dart';
import 'package:kyc/app/router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kyc App',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
