import 'package:flutter/material.dart';
import 'models.dart';
import 'package:uuid/uuid.dart';

class CourseStore extends ChangeNotifier {
  final _list = <Course>[];
  List<Course> get courses => List.unmodifiable(_list);

  void add(Course c) {
    _list.add(c);
    notifyListeners();
  }

  void update(Course c) {
    final i = _list.indexWhere((e) => e.id == c.id);
    if (i != -1) {
      _list[i] = c;
      notifyListeners();
    }
  }

  void remove(String id) {
    _list.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ---------- 겹침 검사 ----------
  bool _overlap(TimeOfDay s1, TimeOfDay e1, TimeOfDay s2, TimeOfDay e2) {
    int m(TimeOfDay t) => t.hour * 60 + t.minute;
    return m(s1) < m(e2) && m(s2) < m(e1);
  }

  /// 같은 요일 내에 시간이 겹치면 true
  bool hasOverlap({
    required int weekday,
    required TimeOfDay start,
    required TimeOfDay end,
    String? exceptId, // 수정 시 자기 자신은 제외
  }) {
    for (final c in _list) {
      if (c.weekday != weekday) continue;
      if (exceptId != null && c.id == exceptId) continue;
      if (_overlap(start, end, c.start, c.end)) return true;
    }
    return false;
  }
  // ------------------------------

  // 샘플 데이터
  void seed() {
    if (_list.isNotEmpty) return;
    final uid = const Uuid();
    add(Course(
      id: uid.v4(), name: '컴퓨터구조', professor: '서호관', room: '101호',
      weekday: 1,
      start: const TimeOfDay(hour: 9, minute: 0),
      end: const TimeOfDay(hour: 10, minute: 10),
      color: CourseColor.yellow,
    ));
    add(Course(
      id: uid.v4(), name: '자료구조', professor: '김한울', room: '302호',
      weekday: 3,
      start: const TimeOfDay(hour: 13, minute: 30),
      end: const TimeOfDay(hour: 14, minute: 20),
      color: CourseColor.green,
    ));
    add(Course(
      id: uid.v4(), name: '운영체제', professor: '홍길동', room: '202호',
      weekday: 5,
      start: const TimeOfDay(hour: 10, minute: 30),
      end: const TimeOfDay(hour: 12, minute: 0),
      color: CourseColor.blue,
    ));
  }
}
