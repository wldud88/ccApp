// lib/chat/chat_room_page.dart
import 'package:flutter/material.dart';
import '../timetable/colors.dart';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({
    super.key,
    required this.name,
    this.initial,
  });

  final String name;
  final String? initial;

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  // 헤더/메뉴 위치 고정을 위한 키
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _moreKey = GlobalKey();        // ▶ 메뉴 아이콘 위치 측정용
  bool _menuOpen = false;                        // ▶ 열려 있을 때만 동그라미

  final List<_Msg> _messages = <_Msg>[
    _Msg(text: '주말에 뭐해요? 같이 카페 갈래요? ☕️', time: _nowLabel(), isMe: false),
    _Msg(text: '네, 안녕하세요! 반갑습니다. ㅎㅎ', time: _nowLabel(), isMe: false),
    _Msg(text: '안녕하세요! 매칭돼서 연락드렸어요. 😊', time: _nowLabel(), isMe: true),
  ];

  static String _nowLabel() {
    final now = TimeOfDay.now();
    final h12 = (now.hour % 12 == 0) ? 12 : (now.hour % 12);
    final m = now.minute.toString().padLeft(2, '0');
    final ap = now.period == DayPeriod.am ? '오전' : '오후';
    return '$ap $h12:$m';
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: txt, time: _nowLabel(), isMe: true));
    });
    _controller.clear();
    // 스크롤 살짝 내려주기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ───────── 3단 메뉴 (아이콘 + 구분선, 상단 라인과 정렬) ─────────
  Future<void> _openMenu() async {
    // 헤더 하단 Y좌표를 구해 드롭다운의 top으로 고정
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final headerBox =
        _headerKey.currentContext!.findRenderObject() as RenderBox;
    final headerBottom =
        headerBox.localToGlobal(Offset(0, headerBox.size.height)).dy;

    // ▶ 메뉴 아이콘의 오른쪽에 맞춰서 메뉴를 띄우기 위한 위치 계산
    final moreBox =
        _moreKey.currentContext!.findRenderObject() as RenderBox;
    final moreTopLeft = moreBox.localToGlobal(Offset.zero);
    final moreRight = moreTopLeft.dx + moreBox.size.width;
    const double menuWidth = 192.0; // 요구사항 고정 너비
    final double overlayW = overlayBox.size.width;

    // 메뉴의 좌측 X: 아이콘의 오른쪽에 맞춰 메뉴 우측이 정렬되도록 계산
    double left = moreRight - menuWidth;
    // 화면 밖으로 나가지 않도록 클램프
    left = left.clamp(8.0, overlayW - menuWidth - 8.0);
    final double right = overlayW - (left + menuWidth);

    setState(() => _menuOpen = true); // ▶ 열릴 때만 동그라미 표시
    String? selected;
    try {
      selected = await showMenu<String>(
        context: context,
        // 오른쪽 정렬 + 헤더 하단 라인 맞춤
        position: RelativeRect.fromLTRB(left, headerBottom, right, overlayBox.size.height),
        elevation: 6, // 과한 그림자 방지
        color: Colors.white.withOpacity(0.96),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE5E7EB)), // 테두리 통일
        ),
        items: const [
          PopupMenuItem<String>(
            value: 'block',
            height: 40, // 항목 높이 축소
            child: Row(
              children: [
                Icon(Icons.block_outlined, size: 18, color: Color(0xFF374151)),
                SizedBox(width: 8),
                Text('차단하기', style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            enabled: false,
            height: 8,
            padding: EdgeInsets.zero,
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          PopupMenuItem<String>(
            value: 'leave',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                SizedBox(width: 8),
                Text(
                  '채팅방 나가기',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFFEF4444), // 드롭바 텍스트 빨강
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } finally {
      if (mounted) setState(() => _menuOpen = false); // ▶ 닫히면 동그라미 해제
    }

    if (!mounted || selected == null) return;

    if (selected == 'block') {
      final ok = await _confirmDialog(
        title: '사용자 차단하기',
        body: '이 사용자를 정말 차단하시겠습니까?\n더 이상 메시지를 주고받을 수 없습니다.',
        positiveLabel: '차단',
      );
      if (ok == true && mounted) {
        Navigator.pop(context, _ChatResult.block(name: widget.name));
      }
    } else if (selected == 'leave') {
      final ok = await _confirmDialog(
        title: '채팅방 나가기',
        body: '채팅방을 정말 나가시겠습니까?\n대화 내용이 모두 삭제됩니다.',
        positiveLabel: '예',
      );
      if (ok == true && mounted) {
        Navigator.pop(context, _ChatResult.left(name: widget.name));
      }
    }
  }

  // ───────── 확인 팝업 ─────────
  Future<bool?> _confirmDialog({
    required String title,
    required String body,
    required String positiveLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    )),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF111827),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('아니요',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFE14040), // ✅ 팝업 긍정 버튼 빨강
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(positiveLabel,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = (widget.initial != null && widget.initial!.isNotEmpty)
        ? widget.initial!
        : (widget.name.isNotEmpty ? widget.name.substring(0, 1) : '?');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ───── 상단: 뒤로가기 + 상대 이름 + 3단 메뉴(열릴 때만 회색 원) ─────
            Container(
              key: _headerKey,
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: Color(0xFF6B7280)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    key: _moreKey,
                    borderRadius: BorderRadius.circular(18),
                    onTap: _openMenu,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _menuOpen ? const Color(0xFFF1F5F9) : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.menu_rounded,
                          color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),

            // ───── 대화 영역 ─────
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  return _MessageRow(msg: m, peerInitial: initial);
                },
              ),
            ),

            // ───── 입력 바 ─────
            _ComposeBar(controller: _controller, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.msg, required this.peerInitial});
  final _Msg msg;
  final String peerInitial;

  @override
  Widget build(BuildContext context) {
    const peerBubble = Color(0xFFAED6F1); // 상대방 말풍선
    const meBubble = Color(0xFFE5E7EB);   // 내 말풍선(그레이)
    final screenW = MediaQuery.of(context).size.width;
    final maxBubbleW = screenW * 0.80;    // ✅ 양쪽 동일: 화면의 80%

    final text = Text(
      msg.text,
      style: const TextStyle(
        fontSize: 15,
        height: 1.35,
        color: Color(0xFF0F172A),
      ),
    );

    final time = Padding(
      padding: const EdgeInsets.only(top: 2), // 말풍선과 더 가깝게
      child: Text(
        msg.time,
        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
      ),
    );

    if (msg.isMe) {
      // 내 메시지 (오른쪽 정렬) — 아바타 없음
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start, // 말풍선 상단 기준
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleW),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ✅ 왼쪽-아래만 직각(0), 나머지 둥글게(16)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      color: meBubble,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomRight: Radius.zero,// ← 오른쪽 아래 직사각형
                        bottomLeft: Radius.circular(14), 
                      ),
                    ),
                    child: text,
                  ),
                  time,
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 상대 메시지 (왼쪽) — 아바타 + 말풍선 상단 정렬
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 아바타 상단과 말풍선 상단 일직선
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE6EEF5),
            child: Text(
              peerInitial,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2A44),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleW),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ 왼쪽-아래만 직각(0), 나머지 둥글게(16)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: peerBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                      bottomLeft: Radius.zero, // ← 왼쪽 아래 직사각형
                    ),
                  ),
                  child: text,
                ),
                time,
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ComposeBar extends StatelessWidget {
  const _ComposeBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54, // ✅ 입력란 높이(패딩 포함) 48px
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEFF3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: '메시지 보내기…',
                            hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // ✅ 보내기 버튼 40x40
                     Padding(
  padding: const EdgeInsets.fromLTRB(6, 4, 8, 4), // ← 오른쪽 여백만 더 띄움
  child: InkWell(
                          onTap: onSend,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFAED6F1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.north_rounded,
                                size: 22, color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Msg {
  final String text;
  final String time;
  final bool isMe;
  _Msg({required this.text, required this.time, required this.isMe});
}

/// 채팅방에서 나갈 때/차단했을 때 리스트 페이지에 알려주기 위한 결과 타입
class _ChatResult {
  final _Kind kind;
  final String name;
  _ChatResult._(this.kind, this.name);
  factory _ChatResult.block({required String name}) =>
      _ChatResult._(_Kind.block, name);
  factory _ChatResult.left({required String name}) =>
      _ChatResult._(_Kind.left, name);
}

enum _Kind { block, left }
