import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/chat_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detailscreen.dart';

// Lists every registered user (except the signed-in one) to start a chat.
class HusseinAdvmobprogChatScreen extends StatefulWidget {
  const HusseinAdvmobprogChatScreen({super.key});

  @override
  State<HusseinAdvmobprogChatScreen> createState() =>
      _HusseinAdvmobprogChatScreenState();
}

class _HusseinAdvmobprogChatScreenState
    extends State<HusseinAdvmobprogChatScreen> {
  final HusseinAdvmobprogChatService _chatService =
      HusseinAdvmobprogChatService();
  final TextEditingController _searchController = TextEditingController();

  // Subscribed once in initState: rebuilding the screen (every search
  // keystroke) must not open another Firestore listener.
  Stream<List<Map<String, dynamic>>>? _usersStream;

  // Same rule for unread totals: one listener for the whole list, never
  // one listener per user row.
  Stream<Map<String, UnreadSummary>>? _unreadStream;

  String? _currentUserId;
  String _query = '';

  // Image urls that failed to decode or load. Their rows fall back to the
  // initials child instead of re-creating a provider that will fail again.
  final Set<String> _brokenImageUrls = {};

  // The unread listener error is reported once, not on every keystroke.
  bool _unreadErrorReported = false;

  @override
  void initState() {
    super.initState();

    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    try {
      _usersStream = _chatService.getUsersStream();
    } catch (_) {
      // Firebase is not configured - handled as an error state below.
      _usersStream = null;
    }

    try {
      _unreadStream = _chatService.getUnreadSummariesStream();
    } catch (_) {
      // Firebase unavailable - badges simply stay hidden.
      _unreadStream = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _displayName(Map<String, dynamic> user) {
    final full =
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    if (full.isNotEmpty) return full;

    final username = user['username']?.toString().trim() ?? '';
    if (username.isNotEmpty) return username;

    final email = user['email']?.toString().trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'Unknown user';
  }

  // Only an absolute http(s) url is safe to hand to NetworkImage. Empty
  // strings and other junk are treated as "no image".
  bool _usableImageUrl(String raw) {
    if (raw.isEmpty) return false;

    final uri = Uri.tryParse(raw);

    if (uri == null || !uri.hasAuthority) return false;

    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  // The uid stored on the document, falling back to the document id so
  // partial profiles still identify the right person.
  String _uidOf(Map<String, dynamic> user) {
    return (user['uid'] ?? user['docId'] ?? '').toString();
  }

  // The signed-in user is never listed in their own chat list, the search
  // filter runs on the already loaded list (no extra Firestore request per
  // keystroke), and rows with unread messages float to the top so the most
  // recent activity is always first.
  List<Map<String, dynamic>> _visibleUsers(
    List<Map<String, dynamic>> allUsers,
    Map<String, UnreadSummary> unread,
  ) {
    final query = _query.trim().toLowerCase();
    final matching = <Map<String, dynamic>>[];

    for (final user in allUsers) {
      final uid = _uidOf(user);

      if (_currentUserId != null && uid == _currentUserId) continue;

      if (query.isNotEmpty) {
        final name = _displayName(user).toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final username = (user['username'] ?? '').toString().toLowerCase();

        final matches = name.contains(query) ||
            email.contains(query) ||
            username.contains(query);

        if (!matches) continue;
      }

      matching.add(user);
    }

    final withUnread = <MapEntry<int, Map<String, dynamic>>>[];
    final rest = <Map<String, dynamic>>[];

    for (var i = 0; i < matching.length; i++) {
      final user = matching[i];

      if (unread.containsKey(_uidOf(user))) {
        withUnread.add(MapEntry(i, user));
      } else {
        rest.add(user);
      }
    }

    // Newest unread activity first; the original index breaks ties so the
    // order stays deterministic.
    withUnread.sort((a, b) {
      final byDate = unread[_uidOf(b.value)]!
          .latestAt
          .compareTo(unread[_uidOf(a.value)]!.latestAt);

      return byDate != 0 ? byDate : a.key.compareTo(b.key);
    });

    return [...withUnread.map((entry) => entry.value), ...rest];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Chat',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search users',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    if (_currentUserId == null) {
      return _emptyState('Sign in with your account to start chatting.');
    }

    final stream = _usersStream;

    if (stream == null) {
      return _emptyState('Chat is unavailable right now. Please try again.');
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (snapshot.hasError) {
          return _emptyState('Could not load users. Please try again.');
        }

        return StreamBuilder<Map<String, UnreadSummary>>(
          stream: _unreadStream,
          builder: (context, unreadSnapshot) {
            // A missing index or a transient listener error must never
            // take the user list down - the badges just stay hidden.
            if (unreadSnapshot.hasError && !_unreadErrorReported) {
              _unreadErrorReported = true;

              // The Firestore error names the collection-group index this
              // query needs (messages: receiverId + isRead); create it in
              // the console and restart to see badges again.
              debugPrint(
                'Chat unread stream unavailable: ${unreadSnapshot.error}',
              );
            }

            final unread = unreadSnapshot.hasError
                ? const <String, UnreadSummary>{}
                : unreadSnapshot.data ?? const <String, UnreadSummary>{};

            final users = _visibleUsers(snapshot.data ?? const [], unread);

            if (users.isEmpty) {
              final search = _query.trim();

              return _emptyState(
                search.isEmpty
                    ? 'No other users registered yet'
                    : 'No users match "$search"',
              );
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = users[index];
                final name = _displayName(user);
                final image = (user['image'] ?? '').toString().trim();
                final showImage = _usableImageUrl(image) &&
                    !_brokenImageUrls.contains(image);
                final uid = _uidOf(user);
                final unreadCount = unread[uid]?.count ?? 0;

                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    backgroundImage:
                        showImage ? NetworkImage(image) : null,
                    // Gated by the same flag: CircleAvatar asserts the error
                    // listener may only be supplied together with an image.
                    onBackgroundImageError: showImage
                        ? (_, __) {
                            // Broken url: fall back to the initials child
                            // instead of breaking the whole list.
                            if (!mounted) return;
                            setState(() => _brokenImageUrls.add(image));
                          }
                        : null,
                    child: showImage
                        ? null
                        : Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    (user['email'] ?? '').toString().trim().isNotEmpty
                        ? (user['email'] ?? '').toString().trim()
                        : 'No email',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (unreadCount > 0)
                        Container(
                          constraints: BoxConstraints(
                            minWidth: 18.w,
                            maxWidth: 36.w,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (unreadCount > 0) SizedBox(width: 6.w),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    // Nothing to chat with when the uid is missing, and the
                    // current user is filtered out long before this point.
                    if (uid.isEmpty || uid == _currentUserId) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HusseinAdvmobprogChatDetailScreen(
                          currentUserEmail:
                              FirebaseAuth.instance.currentUser?.email ?? '',
                          receiverId: uid,
                          receiverName: name,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Text(
          message,
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
