// lib/chat/chat_list_page.dart
import 'package:flutter/material.dart';

import '../widgets/common_header.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../timetable/timetable_page.dart'; // 시간표 이동
import 'chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  OverlayEntry? _toast;

  // 선언과 동시에 초기화(샘플을 복사)
  final List<_ChatItem> _items = List<_ChatItem>.of(_sample);

  // 채팅방 열고 결과 받아 처리(제거 + 토스트)
  Future<void> _openRoom(_ChatItem it) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(name: it.name, initial: it.initial),
      ),
    );

    final act = _parseAction(res); // block/left 파싱
    if (act != null) {
      setState(() {
        _items.removeWhere((e) => e.name == act.name);
      });
      final msg = act.kind == 'block'
          ? '${act.name}님이 차단되었습니다.'
          : '${act.name}님과의 채팅방에서 나갔습니다.';
      _showBottomToast(msg);
    }
  }

  // chat_room_page.dart 결과 방어적 파싱
  _Action? _parseAction(dynamic r) {
    if (r == null) return null;

    // 1) private 클래스 인스턴스 추정(kind/name 프로퍼티)
    try {
      final kindStr = r.kind?.toString();
      final nameStr = r.name?.toString();
      if (kindStr != null && nameStr != null) {
        if (kindStr.contains('block')) return _Action('block', nameStr);
        if (kindStr.contains('left')) return _Action('left', nameStr);
      }
    } catch (_) {}

    // 2) Map
    if (r is Map) {
      final k = r['kind']?.toString();
      final n = r['name']?.toString();
      if (k != null && n != null) {
        if (k == 'block' || k == 'left') return _Action(k, n);
      }
    }

    // 3) "block:이름" 형태 문자열
    if (r is String) {
      final parts = r.split(':');
      if (parts.length == 2) {
        final k = parts[0], n = parts[1];
        if (k == 'block' || k == 'left') return _Action(k, n);
      }
    }
    return null;
  }

  // 아래 중앙 작은 토스트 (하단바 중앙 아이콘 안가리도록 상향)
  Future<void> _showBottomToast(String text) async {
    _toast?.remove();
    _toast = OverlayEntry(
      builder: (ctx) {
        final safeBottom = MediaQuery.of(ctx).padding.bottom;
        final bottomOffset = 108.0 + safeBottom; // 중앙버튼 안가리도록
        return Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Stack(
              children: [
                Positioned(
                  bottom: bottomOffset,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE14040), // 통일 레드
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(context)?.insert(_toast!);
    await Future.delayed(const Duration(seconds: 2));
    _toast?.remove();
    _toast = null;
  }

  @override
  void dispose() {
    _toast?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonHeader(), // 상단바 통일
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목/설명
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '채팅',
                  style: TextStyle(
                    fontSize: 33,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '새로운 인연과 대화를 나눠보세요.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 목록
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              // 라인선 좌우 여백(프로필/리스트와 동일 16)
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEF2F6),
                ),
              ),
              itemBuilder: (context, i) {
                final it = _items[i];
                return _Item(
                  name: it.name,
                  initial: it.initial,
                  preview: it.preview,
                  timeLabel: it.timeLabel,
                  unread: it.unread,
                  onTap: () => _openRoom(it),
                );
              },
            ),
          ),
        ],
      ),

      // 하단바(채팅 화면은 어떤 탭도 활성 X, 달력 탭 시 시간표로 이동)
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: -1,
        onTap: (i) {
          if (i == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TimetablePage()),
            );
          }
        },
        onCenterTap: () {},
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.name,
    required this.initial,
    required this.preview,
    required this.timeLabel,
    required this.unread,
    required this.onTap,
  });

  final String name;
  final String initial;
  final String preview;
  final String timeLabel;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 통일 레드
    const badgeRed = Color(0xFFE14040);

    // 리스트 사이 라인선 여백(16)에 맞춰, 클릭시 모서리만 둥글게
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12), // 눌렀을 때 둥근 모서리
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            // 좌우 여백 확대 → 눌림 영역이 콘텐츠를 더 크게 감쌈
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                // 프로필 + 오른쪽 아래 뱃지 (살짝 크게)
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned.fill(
                        child: CircleAvatar(
                          backgroundColor: Color(0xFFE6EEF5),
                          child: SizedBox(),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20, // 프로필 확대에 맞춰 이니셜도 키움
                              color: Color(0xFF1F2A44),
                            ),
                          ),
                        ),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: badgeRed,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // 가운데: 이름 + 미리보기
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // 오른쪽: 시간
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Action {
  final String kind; // 'block' | 'left'
  final String name;
  const _Action(this.kind, this.name);
}

class _ChatItem {
  final String name;
  final String initial;
  final String preview;
  final String timeLabel;
  final int unread;
  const _ChatItem({
    required this.name,
    required this.initial,
    required this.preview,
    required this.timeLabel,
    required this.unread,
  });
}

// 샘플 데이터
const _sample = <_ChatItem>[
  _ChatItem(
    name: '제니',
    initial: 'J',
    preview: '주말에 뭐해요? 같이 카페 갈래요? ☕️',
    timeLabel: '오후 8:25',
    unread: 2,
  ),
  _ChatItem(
    name: '라이언',
    initial: 'R',
    preview: '네, 그럼 그때 뵐게요!',
    timeLabel: '오후 6:10',
    unread: 0,
  ),
  _ChatItem(
    name: '클로이',
    initial: 'C',
    preview: '사진 보내주셔서 감사해요 :)',
    timeLabel: '오전 11:48',
    unread: 1,
  ),
  _ChatItem(
    name: '데이비드',
    initial: 'D',
    preview: 'ㅋㅋㅋㅋ 진짜 웃기네요',
    timeLabel: '어제',
    unread: 0,
  ),
  _ChatItem(
    name: '에밀리',
    initial: 'E',
    preview: '다음에 또 이야기해요!',
    timeLabel: '2일 전',
    unread: 0,
  ),
  _ChatItem(
    name: '마이클',
    initial: 'M',
    preview: '알겠습니다. 확인해볼게요.',
    timeLabel: '4일 전',
    unread: 3,
  ),
];
