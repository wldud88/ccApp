import 'package:flutter/material.dart';

/// 모든 화면에서 동일하게 쓰는 상단바.
/// - 좌측: 로고 (assets/images/cc_logo.png)
/// - 우측: 메시지/알림 아이콘 (콜백 없으면 동작 X)
/// - 자동 back 아이콘 비활성화로 로고 위치 고정
class CommonHeader extends StatelessWidget implements PreferredSizeWidget {
  const CommonHeader({
    super.key,
    this.onMessageTap,
    this.onBellTap,
  });

  final VoidCallback? onMessageTap;
  final VoidCallback? onBellTap;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 56,
      centerTitle: false,
      titleSpacing: 16,

      // ✅ 뒤로가기 자동 삽입 방지 → 로고 위치 고정
      automaticallyImplyLeading: false,
      leadingWidth: 0,
      leading: const SizedBox.shrink(),

      title: Row(
        children: [
          Image.asset(
            'assets/images/cc_logo.png',
            height: 24,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.circle, size: 20, color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: onMessageTap, // 채팅/알림 없는 화면에서는 null이면 동작 X
          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black87),
          tooltip: '메시지',
        ),
        IconButton(
          onPressed: onBellTap,
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
          tooltip: '알림',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
