import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/chat_provider.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(LucideIcons.house),
          label: 'nav_home'.tr(context: context),
        ),
        BottomNavigationBarItem(
          icon: const Icon(LucideIcons.compass),
          label: 'nav_explore'.tr(context: context),
        ),
        BottomNavigationBarItem(
          icon: const Icon(LucideIcons.plusCircle),
          label: 'nav_add_good'.tr(context: context),
        ),
        BottomNavigationBarItem(
          icon: const Icon(LucideIcons.list),
          label: 'nav_my_goods'.tr(context: context),
        ),
        BottomNavigationBarItem(
          icon: Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.unreadCount > 0) {
                return Badge(
                  label: Text('${chatProvider.unreadCount}'),
                  child: const Icon(LucideIcons.messageCircle),
                );
              }
              return const Icon(LucideIcons.messageCircle);
            },
          ),
          label: 'nav_chat'.tr(context: context),
        ),
      ],
    );
  }
}
