import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

//Since the  AppBar pattern
//(back arrow left + title center + X right)
// repeats on almost every screen,
//We make it a reusable widget now
class KycAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool showClose;
  final String? closeRoute; // where X navigates to
  final VoidCallback? onClose;

  const KycAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.showClose = true,
    this.closeRoute,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      leading: showBack
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
              onPressed: () {
                // FIX: Check if there's anything to pop before popping
                // If not, navigate to home (prevents "There is nothing to pop" error)
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed('home');
                }
              },
            )
          : null,
      title: Text(title, style: AppTextStyles.appBarTitle),
      actions: [
        if (showClose)
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 20,
              color: AppColors.textPrimary,
            ),
            onPressed:
                onClose ??
                () {
                  if (closeRoute != null) {
                    context.goNamed(closeRoute!);
                  } else if (context.canPop()) {
                    context.pop();
                  } else {
                    context.goNamed('home');
                  }
                },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
