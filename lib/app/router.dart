import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const PlaceholderScreen(title: 'Onboarding'),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const PlaceholderScreen(title: 'Home'),
    ),
  ],
);

//Temporary Placeholder class
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title screen - coming soon')),
    );
  }
}
