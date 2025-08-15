import 'package:flutter/material.dart';

enum CourseColor { yellow, green, blue, pink, purple, orange }

class Course {
  String id;
  String name;
  String professor;
  String room;
  int weekday; // 1=월 ... 6=토
  TimeOfDay start;
  TimeOfDay end;
  CourseColor color;

  Course({
    required this.id,
    required this.name,
    required this.professor,
    required this.room,
    required this.weekday,
    required this.start,
    required this.end,
    required this.color,
  });
}

// 배경색
Color bgColor(CourseColor c) => switch (c) {
  CourseColor.yellow => const Color(0xFFFEF9C3),
  CourseColor.green  => const Color(0xFFDCFCE7),
  CourseColor.blue   => const Color(0xFFDBEAFE),
  CourseColor.pink   => const Color(0xFFFCE7F3),
  CourseColor.purple => const Color(0xFFEDE9FE),
  CourseColor.orange => const Color(0xFFFFEDD5),
};

// 글자색
Color fgColor(CourseColor c) => switch (c) {
  CourseColor.yellow => const Color(0xFF854D0E),
  CourseColor.green  => const Color(0xFF065F46),
  CourseColor.blue   => const Color(0xFF1E3A8A),
  CourseColor.pink   => const Color(0xFF9D174D),
  CourseColor.purple => const Color(0xFF5B21B6),
  CourseColor.orange => const Color(0xFF9A3412),
};
