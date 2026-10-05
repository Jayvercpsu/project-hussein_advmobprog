import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

// A message that was typed but not yet confirmed by Firestore.
class _PendingMessage {
  final String localId;
  final String text;
  _PendingMessage(this.localId, this.text);
}

class HusseinAdvmobprogChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final String receiverId;
  final String receiverName;

  const HusseinAdvmobprogChatDetailScreen({
    super.key,
    required this.currentUserEmail,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<HusseinAdvmobprogChatDetailScreen> createState() =>
      _HusseinAdvmobprogChatDetailScreenState();
}

class _HusseinAdvmobprogChatDetailScreenState
    extends State<HusseinAdvmobprogChatDetailScreen> {
  final HusseinAdvmobprogChatService _chatService =
      HusseinAdvmobprogChatService();
  final TextEditingController _controller = TextEditingController();
  final List<_PendingMessage> _pending = [];

  String? _error;
  int _counter = 0;

  // Signed-in Firebase user (null when the session is gone).
  String? _currentUserId;

  // Created once in initState: rebuilding the screen (for example while
  // typing) must never open another Firestore listener.
  Stream<QuerySnapshot<Map<String, dynamic>>>? _messagesStream;

  bool _isSending = false;

  // Keeps at most one "mark as read" commit in flight, no matter how
  // often the message snapshot asks for one.
  bool _markReadInFlight = false;

  String get _myUid => _currentUserId ?? '';

  // Safety net: never open a room with yourself
  bool get _isSelfChat =>
      _currentUserId == null ||
      widget.receiverId.isEmpty ||
      widget.receiverId == _currentUserId;

  @override
  void initState() {
    super.initState();

    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final currentUserId = _currentUserId;

    if (currentUserId == null || widget.receiverId == currentUserId) {
      return;
    }

    try {
      _messagesStream = _chatService.getMessage(
        currentUserId,
        widget.receiverId,
      );
    } catch (_) {
      // Firebase unavailable - the error state below is shown instead.
      _messagesStream = null;
    }

    // Opening the conversation clears the chat list badge right away; the
    // snapshot below repeats the call if another message arrives while
    // this screen stays open.
    _markMessagesRead();
  }

  // Marks the messages this partner sent to me as read. My own outgoing
  // messages are never touched, and a failure is swallowed - the badge
  // simply stays until the next attempt.
  void _markMessagesRead() {
    final other = widget.receiverId;

    if (other.isEmpty || other == _currentUserId || _currentUserId == null) {
      return;
    }

    if (_markReadInFlight) return;

    _markReadInFlight = true;

    _chatService.markMessagesAsRead(other).catchError((_) {}).whenComplete(() {
      _markReadInFlight = false;
    });
  }

  // Schedules a mark-as-read pass after the current frame when the latest
  // snapshot still contains unread messages from the other user, so an
  // incoming message clears its badge without restarting the app.
  void _scheduleMarkRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final hasUnread = docs.any((doc) {
      final data = doc.data();

      return (data['senderId'] ?? '').toString() == widget.receiverId &&
          data['isRead'] == false;
    });

    if (!hasUnread) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _markMessagesRead();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    // Rapid double taps cannot queue the same message twice.
    if (_isSending) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final pending = _PendingMessage('local_${_counter++}', text);

    setState(() {
      _isSending = true;
      _pending.insert(0, pending);
      _error = null;
    });
    _controller.clear();

    try {
      await _chatService.sendMessage(widget.receiverId, text);
      // The snapshot replaces the bubble once Firestore confirms it
      if (mounted) setState(() => _pending.remove(pending));
    } catch (_) {
      if (!mounted) return;

      // Never lose the text: remove the bubble and restore the input
      final typed = _controller.text.trim();

      setState(() {
        _pending.remove(pending);
        _controller.text = typed.isEmpty ? text : '$text $typed';
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
        _error = 'Message not sent. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _time(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
  }

  Widget _bubble({
    required String key,
    required String text,
    required bool mine,
    required String footer,
    bool sending = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    // Keyed by document id so existing messages never re-animate
    return TweenAnimationBuilder<double>(
      key: ValueKey(key),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: child,
        ),
      ),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: 0.75.sw),
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: mine ? Colors.indigo : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: mine ? Colors.white : scheme.onSurface,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (sending)
                    SizedBox(
                      width: 10.w,
                      height: 10.w,
                      child: const CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  if (sending) SizedBox(width: 4.w),
                  Text(
                    footer,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: mine ? Colors.white70 : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSelfChat) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.receiverName)),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              _currentUserId == null
                  ? 'Your session has ended. Please sign in again to chat.'
                  : 'You cannot start a chat with yourself.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          if (_error != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red, fontSize: 12.sp),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  CircleAvatar(
                    backgroundColor:
                        _isSending ? Colors.grey.shade400 : Colors.indigo,
                    child: IconButton(
                      icon: _isSending
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isSending ? null : _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    final stream = _messagesStream;

    if (stream == null) {
      return _statusMessage('Messages are unavailable right now.');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _statusMessage('Could not load messages. Please try again.');
        }

        final docs = snapshot.data?.docs ?? [];

        // Unread messages still sitting in this conversation (a new one
        // arrived while the chat is open) are marked read after the frame.
        _scheduleMarkRead(docs);

        if (!snapshot.hasData && docs.isEmpty && _pending.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Pending bubbles first (newest), then confirmed messages
        final items = <Widget>[
          for (final p in _pending)
            _bubble(
              key: p.localId,
              text: p.text,
              mine: true,
              footer: 'sending...',
              sending: true,
            ),
          for (final doc in docs)
            Builder(builder: (context) {
              final m =
                  HusseinAdvmobprogMessage.fromMap(doc.data());
              final mine = m.senderId == _myUid;
              return _bubble(
                key: doc.id,
                text: m.message,
                mine: mine,
                footer: mine
                    ? '${_time(m.timestamp.toDate())}  \u2713'
                    : _time(m.timestamp.toDate()),
              );
            }),
        ];

        if (items.isEmpty) {
          return _statusMessage('Say hi \u{1F44B}');
        }

        return ListView(
          reverse: true,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          children: items,
        );
      },
    );
  }

  Widget _statusMessage(String text) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
