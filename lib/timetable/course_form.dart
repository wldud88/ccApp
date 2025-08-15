import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'store.dart';
import 'package:uuid/uuid.dart';

class CourseForm extends StatefulWidget {
  final Course? existing;
  const CourseForm({super.key, this.existing});

  @override
  State<CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<CourseForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController name;
  late final TextEditingController prof;
  late final TextEditingController room;

  int weekday = 1; // 1=월 ... 6=토
  TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay end   = const TimeOfDay(hour: 9, minute: 50);
  CourseColor color = CourseColor.yellow;

  late String startStr;
  late String endStr;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.existing?.name ?? '');
    prof = TextEditingController(text: widget.existing?.professor ?? '');
    room = TextEditingController(text: widget.existing?.room ?? '');

    weekday = widget.existing?.weekday ?? 1;
    start   = _snapTo5(widget.existing?.start ?? start);
    end     = _snapTo5(widget.existing?.end   ?? end);
    color   = widget.existing?.color ?? CourseColor.yellow;

    startStr = _formatHHmm(start);
    endStr   = _formatHHmm(end);
  }

  @override
  void dispose() {
    name.dispose();
    prof.dispose();
    room.dispose();
    super.dispose();
  }

  // ---------- helpers ----------
  String _pad2(int n) => n.toString().padLeft(2, '0');
  String _formatHHmm(TimeOfDay t) => '${_pad2(t.hour)}:${_pad2(t.minute)}';

  TimeOfDay _snapTo5(TimeOfDay t) {
    final snapped = (t.minute / 5).round() * 5;
    int m = snapped;
    int h = t.hour;
    if (m == 60) { h = (h + 1) % 24; m = 0; }
    return TimeOfDay(hour: h, minute: m);
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  bool _rangeOverlap(TimeOfDay aStart, TimeOfDay aEnd, TimeOfDay bStart, TimeOfDay bEnd) {
    // [aStart, aEnd) 와 [bStart, bEnd) 교차 여부
    return _toMinutes(aStart) < _toMinutes(bEnd) &&
           _toMinutes(bStart) < _toMinutes(aEnd);
  }

  bool _hasOverlap(Course candidate, CourseStore store) {
    for (final c in store.courses) {
      if (c.weekday != candidate.weekday) continue;
      if (c.id == candidate.id) continue; // 수정 시 자기 자신 제외
      if (_rangeOverlap(candidate.start, candidate.end, c.start, c.end)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _showOverlapDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '등록 불가',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '이미 등록된 시간과 겹칩니다.\n다른 시간으로 선택해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF111827),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('확인', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    const borderColor = Color(0xFFE6EDF3);
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB1BAC5)),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor, width: 1.2),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      );

  Widget _divider() => const Padding(
        padding: EdgeInsets.only(top: 12, bottom: 12),
        child: Divider(height: 1, thickness: 1, color: Color(0xFFEFF3F7)),
      );
  // -----------------------------

  @override
  Widget build(BuildContext context) {
    final store = context.read<CourseStore>();
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  children: [
                    const Text(
                      '과목 정보 입력',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      splashRadius: 20,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                _divider(),

                _label('과목명'),
                TextFormField(
                  controller: name,
                  decoration: _decoration('예: 객체지향프로그래밍'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '과목명을 입력해주세요.' : null,
                ),
                const SizedBox(height: 16),

                _label('교수명'),
                TextFormField(
                  controller: prof,
                  decoration: _decoration('예: 홍길동'),
                ),
                const SizedBox(height: 16),

                _label('강의실'),
                TextFormField(
                  controller: room,
                  decoration: _decoration('예: 우당관 401호'),
                ),
                const SizedBox(height: 16),

                // 요일 : 커스텀 바텀시트(구분선 + 라운드)
                _label('요일'),
                _DayField(
                  value: weekday,
                  decoration: _decoration('요일').copyWith(
                    suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF6B7280)),
                  ),
                  onChanged: (v) => setState(() => weekday = v),
                ),
                const SizedBox(height: 16),

                // 시작/종료 시간 (아이콘 없음, 휠 피커)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('시작 시간'),
                          _TimeField(
                            text: startStr,
                            hint: '예: 09:00',
                            decoration: _decoration('예: 09:00'),
                            onTap: () async {
                              final picked =
                                  await _showCupertinoTimePicker(context, initial: start);
                              if (picked != null) {
                                setState(() {
                                  start = _snapTo5(picked);
                                  startStr = _formatHHmm(start);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('종료 시간'),
                          _TimeField(
                            text: endStr,
                            hint: '예: 09:50',
                            decoration: _decoration('예: 09:50'),
                            onTap: () async {
                              final picked =
                                  await _showCupertinoTimePicker(context, initial: end);
                              if (picked != null) {
                                setState(() {
                                  end = _snapTo5(picked);
                                  endStr = _formatHHmm(end);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                _divider(),

                // 저장 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAED6F1),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      FocusScope.of(context).unfocus();

                      final draft = Course(
                        id: widget.existing?.id ?? const Uuid().v4(),
                        name: name.text.trim(),
                        professor: prof.text.trim(),
                        room: room.text.trim(),
                        weekday: weekday,
                        start: start,
                        end: end,
                        color: color,
                      );

                      // ⭕️ 겹침 검사 — 있으면 팝업 띄우고 저장 중단
                      if (_hasOverlap(draft, store)) {
                        await _showOverlapDialog();
                        return;
                      }

                      widget.existing != null
                          ? store.update(draft)
                          : store.add(draft);

                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text(
                      '저장',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// iOS 스타일 3-휠(오전/오후, 시[01..12], 분[00/05/10..55])
  Future<TimeOfDay?> _showCupertinoTimePicker(BuildContext context,
      {required TimeOfDay initial}) async {
    int initHour12 = initial.hour % 12;
    if (initHour12 == 0) initHour12 = 12;
    final initAm = initial.hour < 12 ? 0 : 1;
    final initMinIndex = (initial.minute / 5).round().clamp(0, 11);

    final ampm = ['오전', '오후'];
    final hours = List.generate(12, (i) => i + 1);   // 1..12
    final minutes = List.generate(12, (i) => i * 5); // 0..55

    final amCtrl = FixedExtentScrollController(initialItem: initAm);
    final hCtrl = FixedExtentScrollController(initialItem: hours.indexOf(initHour12));
    final mCtrl = FixedExtentScrollController(initialItem: initMinIndex);

    int selAm = initAm;
    int selHour12 = initHour12;
    int selMin = minutes[initMinIndex];

    return showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                // 상단 바: 취소 / 완료 (검정 텍스트)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(foregroundColor: Colors.black87),
                        child: const Text('취소',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      TextButton(
                        onPressed: () {
                          int hour24 = selHour12 % 12;
                          if (selAm == 1) hour24 += 12;
                          Navigator.pop(context,
                              TimeOfDay(hour: hour24, minute: selMin));
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.black87),
                        child: const Text('완료',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: amCtrl,
                          itemExtent: 36,
                          onSelectedItemChanged: (i) => selAm = i,
                          children: ampm.map((t) => Center(
                            child: Text(t, style: const TextStyle(fontSize: 18)),
                          )).toList(),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: hCtrl,
                          itemExtent: 36,
                          onSelectedItemChanged: (i) => selHour12 = hours[i],
                          children: hours.map((h) => Center(
                            child: Text(_pad2(h), style: const TextStyle(fontSize: 20)),
                          )).toList(),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: mCtrl,
                          itemExtent: 36,
                          onSelectedItemChanged: (i) => selMin = minutes[i],
                          children: minutes.map((m) => Center(
                            child: Text(_pad2(m), style: const TextStyle(fontSize: 20)),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 요일 선택: 입력창은 읽기전용, 탭하면 라운드 모달 + 구분선 리스트가 뜸
class _DayField extends StatelessWidget {
  final int value; // 1~6
  final InputDecoration decoration;
  final ValueChanged<int> onChanged;
  const _DayField({
    required this.value,
    required this.decoration,
    required this.onChanged,
  });

  static const _days = ['월','화','수','목','금','토'];

  String _labelOf(int v) => _days[v - 1];

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: _labelOf(value));
    return TextFormField(
      controller: controller,
      readOnly: true,
      enableInteractiveSelection: false,
      onTap: () => _openSheet(context),
      decoration: decoration,
      style: const TextStyle(color: Color(0xFF111827)),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // ⭕️ 둥근 모서리
      ),
      builder: (_) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _days.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFEFF3F7)), // ⭕️ 요일 사이 구분선
          itemBuilder: (c, i) {
            final v = i + 1;
            final selected = v == value;
            return ListTile(
              title: Text(
                _days[i],
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check, size: 18, color: Color(0xFF111827))
                  : null,
              onTap: () => Navigator.pop(c, v),
            );
          },
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }
}

/// 시간 표시용 읽기전용 필드 (탭하면 휠 피커)
class _TimeField extends StatelessWidget {
  final String text;
  final String hint;
  final InputDecoration decoration;
  final VoidCallback onTap;

  const _TimeField({
    required this.text,
    required this.hint,
    required this.decoration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: text);
    return TextFormField(
      controller: controller,
      readOnly: true,
      enableInteractiveSelection: false,
      onTap: onTap,
      decoration: decoration.copyWith(hintText: hint, suffixIcon: null),
      style: const TextStyle(color: Color(0xFF111827)),
    );
  }
}
