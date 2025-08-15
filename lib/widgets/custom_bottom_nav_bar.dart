// lib/widgets/custom_bottom_nav_bar.dart
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;          // 활성 인덱스(해당 페이지에서만 파란색)
  final ValueChanged<int> onTap;   // 좌/우 아이콘 탭 콜백 (0,1,3,4 중 하나)
  final VoidCallback onCenterTap;  // 가운데 둥근 버튼

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFF6A9BC0); // 파란색
    const double navBarHeight = 56.0;
    const double floatingSize = 72.0;
    const double navIconSize = 26.0;

    final double floatingBottom = navBarHeight / 2 - 2;

    return SafeArea(
      top: false,
      bottom: false,
      child: SizedBox(
        height: navBarHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // 배경
            Positioned.fill(
              child: CustomPaint(
                painter: _NavBarBgPainter(),
              ),
            ),

            // 가운데 플로팅 버튼
            Positioned(
              bottom: floatingBottom,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onCenterTap,
                  child: Container(
                    width: floatingSize,
                    height: floatingSize,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.podcasts, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
            ),

            // 좌/우 아이콘들
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: navBarHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _NavBarIcon(
                      icon: Icons.home_rounded,
                      isActive: currentIndex == 0,
                      accentColor: accentColor,
                      size: navIconSize,
                      onTap: () => onTap(0),
                    ),
                    _NavBarIcon(
                      // 예시 커스텀 아이콘(친구/그룹)
                      custom: Icon(Icons.groups_rounded,
                          size: navIconSize,
                          color: currentIndex == 1
                              ? accentColor
                              : Colors.grey[400]),
                      isActive: currentIndex == 1,
                      accentColor: accentColor,
                      size: navIconSize,
                      onTap: () => onTap(1),
                    ),

                    const Expanded(child: SizedBox()),

                    // ← 달력 아이콘: TimetablePage에서만 파란색
                    _NavBarIcon(
                      icon: Icons.calendar_today_outlined,
                      isActive: currentIndex == 3,
                      accentColor: accentColor,
                      size: navIconSize,
                      onTap: () => onTap(3),
                    ),
                    _NavBarIcon(
                      icon: Icons.person_rounded,
                      isActive: currentIndex == 4,
                      accentColor: accentColor,
                      size: navIconSize,
                      onTap: () => onTap(4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double topCornerR = 20.0;
    const double centerDipRatio = 0.22;
    const double centerDipDepth = 30.0;

    final double w = size.width;
    final double h = size.height;

    final double dipW = w * centerDipRatio;
    final double dipStart = (w - dipW) / 2;
    final double dipEnd = dipStart + dipW;
    final double dipCenter = w / 2;

    final Path body = Path()
      ..moveTo(0, h)
      ..lineTo(0, topCornerR)
      ..quadraticBezierTo(0, 0, topCornerR, 0)
      ..lineTo(dipStart, 0)
      ..cubicTo(dipStart + w * 0.02, 0, dipCenter - w * 0.02, centerDipDepth,
          dipCenter, centerDipDepth)
      ..cubicTo(dipCenter + w * 0.02, centerDipDepth, dipEnd - w * 0.02, 0,
          dipEnd, 0)
      ..lineTo(w - topCornerR, 0)
      ..quadraticBezierTo(w, 0, w, topCornerR)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    // 그림자 + 채움
    canvas.drawShadow(body, Colors.black.withOpacity(0.08), 10, false);
    canvas.drawPath(body, Paint()..color = Colors.white);

    // 상단 경계선
    final Path topEdge = Path()
      ..moveTo(0, topCornerR)
      ..quadraticBezierTo(0, 0, topCornerR, 0)
      ..lineTo(dipStart, 0)
      ..cubicTo(dipStart + w * 0.02, 0, dipCenter - w * 0.02, centerDipDepth,
          dipCenter, centerDipDepth)
      ..cubicTo(dipCenter + w * 0.02, centerDipDepth, dipEnd - w * 0.02, 0,
          dipEnd, 0)
      ..lineTo(w - topCornerR, 0)
      ..quadraticBezierTo(w, 0, w, topCornerR);

    final stroke = Paint()
      ..color = const Color(0xFFE8EDF3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(topEdge, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NavBarIcon extends StatelessWidget {
  final IconData? icon;
  final Widget? custom;
  final bool isActive;
  final Color accentColor;
  final double size;
  final VoidCallback onTap;

  const _NavBarIcon({
    this.icon,
    this.custom,
    required this.isActive,
    required this.accentColor,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? accentColor : Colors.grey[400];
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Center(
          child: custom ?? Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}
