import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'colors.dart';
import 'models.dart';
import 'store.dart';
import 'course_form.dart';

import '../widgets/common_header.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../chat/chat_list_page.dart';

const startHour = 9;
const endHour = 18;
const hourHeight = 64.0;
const dayCount = 6;

const double timeRailWidth = 32.0;
const double dayGutter = 0.0;

// ───── 요일별 고정 팔레트 (월=1 … 토=6) ─────
Color _dayBg(int weekday) => switch (weekday) {
  1 => const Color(0xFFFEF9C3), // 월: Yellow-100
  2 => const Color(0xFFDCFCE7), // 화: Green-100
  3 => const Color(0xFFDBEAFE), // 수: Blue-100
  4 => const Color(0xFFEDE9FE), // 목: Purple-100
  5 => const Color(0xFFFCE7F3), // 금: Pink-100
  6 => const Color(0xFFCFFAFE), // 토: Cyan-100
  _ => const Color(0xFFE5E7EB),
};

Color _dayFg(int weekday) => switch (weekday) {
  1 => const Color(0xFF854D0E), // Yellow-800
  2 => const Color(0xFF065F46), // Green-800
  3 => const Color(0xFF1E3A8A), // Blue-800
  4 => const Color(0xFF5B21B6), // Purple-800
  5 => const Color(0xFF9D174D), // Pink-800
  6 => const Color(0xFF155E75), // Cyan-800
  _ => const Color(0xFF374151),
};

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  bool _deleteMode = false;

  void _setDeleteMode(bool v) {
    if (_deleteMode != v) setState(() => _deleteMode = v);
  }

  void _openForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CourseForm(),
    );
  }

  void _onFabTap() {
    if (_deleteMode) {
      _setDeleteMode(false);
    } else {
      _openForm();
    }
  }

  void _onDropCourse(Course c) {
    context.read<CourseStore>().remove(c.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('삭제되었습니다.')),
    );
    _setDeleteMode(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: CommonHeader(
        onMessageTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChatListPage()),
          );
        },
      ),
      body: Column(
        children: const [
          SizedBox(height: 4),
          _TimetableChip(),   // ← 텍스트 자동(YYYY-학기) + 그림자 제거
          SizedBox(height: 2),
          _DayHeader(),
          // 상단 Divider 제거(요청사항)
          _GridWrapper(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 16),
        child: SizedBox(
          width: 56,
          height: 56,
          child: _SoftFab(
            deleteMode: _deleteMode,
            onTap: _onFabTap,
            onDrop: _onDropCourse,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3,              // ← 달력 아이콘만 파란색(현재 페이지)
  onTap: (i) {
    if (i == 3) {
      // 이미 시간표 페이지 → 아무 것도 안 함
      return;
    }
    // 필요 시 다른 탭 라우팅 추가
    // ex) if (i == 0) Navigator.push(...);
  },
  onCenterTap: () {
    // 가운데 버튼 동작(예시 비워둠)
  },
),
      
    );
  }
}

class _TimetableChip extends StatelessWidget {
  const _TimetableChip();

  String _termText() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    // 3~8월 = 1학기, 나머지(9~2월) = 2학기
    final term = (month >= 3 && month <= 8) ? 1 : 2;
    return '$year-$term 시간표';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          // 🔇 그림자 완전 제거: boxShadow 생략
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            _termText(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: CCColors.toggleActiveText,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          const SizedBox(width: timeRailWidth),
          ...['월', '화', '수', '목', '금', '토'].map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridWrapper extends StatelessWidget {
  const _GridWrapper();

  @override
  Widget build(BuildContext context) {
    final courses = context.select<CourseStore, List<Course>>((s) => s.courses);
    final state = context.findAncestorStateOfType<_TimetablePageState>();
    return Expanded(
      child: _Grid(
        courses: courses,
        onAnyDragStart: state?._setDeleteMode,
        onAnyDragEnd: state?._setDeleteMode,
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<Course> courses;
  final void Function(bool)? onAnyDragStart;
  final void Function(bool)? onAnyDragEnd;

  const _Grid({
    required this.courses,
    this.onAnyDragStart,
    this.onAnyDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final totalHeight = (endHour - startHour) * hourHeight;
    const extraBottomSpace = hourHeight + 24;

    return SingleChildScrollView(
      child: SizedBox(
        height: totalHeight + extraBottomSpace,
        child: Stack(
          children: [
            Positioned.fill(child: _gridBackground(totalHeight: totalHeight)),
            ...courses.map((c) => _block(context, c)),
          ],
        ),
      ),
    );
  }

  Widget _gridBackground({required double totalHeight}) {
    final lines = List.generate(endHour - startHour, (i) {
      final hour = startHour + i;
      return SizedBox(
        height: hourHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(height: 1, color: CCColors.line),
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: timeRailWidth,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4, top: 2),
                      child: Text(
                        '$hour',
                        style: const TextStyle(
                          color: CCColors.infoText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      );
    });

    return Stack(
      children: [
        SizedBox(height: totalHeight, child: Column(children: lines)),
        // 18 위/아래 라인
        Positioned(
          left: 0,
          right: 0,
          top: totalHeight,
          child: Container(height: 1, color: CCColors.line),
        ),
        Positioned(
          left: 0,
          top: totalHeight + 6,
          child: SizedBox(
            width: timeRailWidth,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '$endHour',
                  style: const TextStyle(color: CCColors.infoText, fontSize: 12),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: totalHeight + hourHeight,
          child: Container(height: 1, color: CCColors.line),
        ),
      ],
    );
  }

  Widget _block(BuildContext context, Course c) {
    final dayWidth =
        (MediaQuery.of(context).size.width - timeRailWidth) / dayCount;
    final top = _offset(c.start);
    final height = _offset(c.end) - _offset(c.start);
    final left = timeRailWidth + (c.weekday - 1) * dayWidth + dayGutter;
    final width = dayWidth - (dayGutter * 2);

    return Positioned(
      top: top,
      left: left,
      width: width,
      height: height - 8,
      child: _DraggableCourseBlock(
        course: c,
        onEdit: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => CourseForm(existing: c),
        ),
        onDragStarted: () => onAnyDragStart?.call(true),
        onDragEnded: () => onAnyDragEnd?.call(false),
      ),
    );
  }

  double _offset(TimeOfDay t) {
    final minutes = (t.hour - startHour) * 60 + t.minute;
    return minutes / 60 * hourHeight;
  }
}

class _DraggableCourseBlock extends StatefulWidget {
  final Course course;
  final VoidCallback onEdit;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  const _DraggableCourseBlock({
    required this.course,
    required this.onEdit,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  @override
  State<_DraggableCourseBlock> createState() => _DraggableCourseBlockState();
}

class _DraggableCourseBlockState extends State<_DraggableCourseBlock> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final block = _CourseBlockView(course: widget.course);

    return LongPressDraggable<Course>(
      data: widget.course,
      delay: const Duration(milliseconds: 220),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () {
        setState(() => _dragging = true);
        widget.onDragStarted();
      },
      onDraggableCanceled: (_, __) {
        setState(() => _dragging = false);
        widget.onDragEnded();
      },
      onDragEnd: (_) {
        setState(() => _dragging = false);
        widget.onDragEnded();
      },
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 0.96, child: block),
      ),
      childWhenDragging: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: 0.5,
        child: Transform.scale(scale: 0.96, child: block),
      ),
      child: GestureDetector(
        onTap: widget.onEdit,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _dragging ? 0.96 : 1.0,
          child: block,
        ),
      ),
    );
  }
}

class _CourseBlockView extends StatelessWidget {
  final Course course;
  const _CourseBlockView({required this.course});

  @override
  Widget build(BuildContext context) {
    final bg = _dayBg(course.weekday);
    final fg = _dayFg(course.weekday);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, cons) {
          final compact = cons.maxHeight < 72;
          final nameStyle = TextStyle(
            color: fg,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          );
          final infoStyle = TextStyle(
            color: fg.withOpacity(0.82),
            height: 1.1,
            fontSize: 12,
          );

          final name = Text(
            course.name,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: nameStyle,
          );

          return compact
              ? name
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    name,
                    const SizedBox(height: 4),
                    Text(
                      course.professor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: infoStyle,
                    ),
                    Text(
                      course.room,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: infoStyle,
                    ),
                  ],
                );
        },
      ),
    );
  }
}

/// + (일반) / 휴지통(삭제 모드) FAB + DragTarget (그림자 톤 그대로 유지)
class _SoftFab extends StatelessWidget {
  final bool deleteMode;
  final VoidCallback? onTap;
  final ValueChanged<Course>? onDrop;

  const _SoftFab({
    required this.deleteMode,
    required this.onTap,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Course>(
      onWillAccept: (_) => deleteMode,
      onAccept: (c) => onDrop?.call(c),
      builder: (context, candidates, rejects) {
        final isHover = candidates.isNotEmpty;

        final Color bg = !deleteMode
            ? CCColors.white
            : (isHover ? const Color(0xFFFFE5E5) : const Color(0xFFEF4444));
        final Border? border = !deleteMode
            ? const Border.fromBorderSide(BorderSide(color: Color(0xFFE9EDF4)))
            : (isHover ? Border.all(color: const Color(0xFFFECACA)) : null);
        final Color iconColor =
            !deleteMode ? CCColors.black : (isHover ? Colors.red.shade500 : Colors.white);
        final IconData icon = deleteMode ? Icons.delete_rounded : Icons.add;

        final List<BoxShadow> subtleShadows = !deleteMode
            ? const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 26,
                  offset: Offset(0, 12),
                ),
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: isHover ? const Color(0x33EF4444) : const Color(0x29000000),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ];

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: border,
              boxShadow: subtleShadows,
            ),
            child: Center(
              child: Icon(icon, size: 26, color: iconColor),
            ),
          ),
        );
      },
    );
  }
}
