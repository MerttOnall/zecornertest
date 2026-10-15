import 'package:flutter/material.dart';
import 'package:zecorner/presentation/screens/profile/profile_notification_screen.dart';

class AdminPanelAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onMenuPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  /// true ise sol ikon menü yerine geri butonu (Icons.arrow_back) gösterilir.
  final bool useBackButton;

  const AdminPanelAppBar({
    super.key,
    required this.title,
    required this.onMenuPressed,
    this.actions,
    this.backgroundColor,
    this.useBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? const Color(0xFFE53935);
    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          useBackButton ? Icons.arrow_back : Icons.menu,
          color: Colors.white,
        ),
        onPressed: onMenuPressed,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileNotificationScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      "2",
                      style: TextStyle(
                        color: Color.fromRGBO(238, 46, 36, 1),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...(actions ?? []),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 