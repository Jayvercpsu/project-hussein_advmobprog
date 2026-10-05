# hussein_advmobprog

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

# Firebase Setup (required once)

This project uses Firebase Authentication (Lab Activity 5) and Cloud Firestore
(Lab Activity 6). The Firebase config file is personal to each project, so it
is **not** included:

1. In the Firebase console create a project (e.g. `husseinadvmobprog`) and add
   an Android app with the package name `com.example.hussein_advmobprog`.
2. Download `google-services.json` and place it in `android/app/`.
3. Enable **Authentication > Sign-in method > Email/Password**.
4. Create a **Firestore Database** (test mode is enough for the lab).
5. Run `flutter pub get`, then `flutter run`.

Sign in accepts either the email or the username (the username is resolved to
its email through the `Users` collection).

---

# Lab Activity 6: Discussion

Lab Activity 6 (Firebase Part II) adds real-time chat on top of the existing
Firebase Authentication from Lab Activity 5. `FirebaseAuth.instance.currentUser`
is the only source of identity, and Cloud Firestore only stores the profile
documents and the chat messages.

Files used by this activity:

- `lib/services/chat_service.dart` — every Firestore read/write for chat
- `lib/models/message.dart` — the `HusseinAdvmobprogMessage` model
- `lib/screens/chat_screen.dart` — the chat list
- `lib/screens/chat_detailscreen.dart` — the conversation screen
  (`chat_detail_screen.dart` re-exports it so older imports keep working)
- `lib/services/user_service.dart` — Firebase Auth + `Users` profile documents

## User Structure

```
Users
  {firebaseUid}          <- document id = Firebase Authentication UID
    uid        : String
    email      : String
    username   : String
    firstName  : String
    lastName   : String
    image      : String
    age, contactNo, loginType
```

The Firebase Auth UID is the identity of the account and also the document id
of the profile in `Users`, so both are always the same account. Sign-up and
sign-in write the profile with `SetOptions(merge: true)`, so the same document
is refreshed instead of duplicated. Deleting the account also deletes its
`Users` document. The chat list reads `Users` through a real-time `snapshots()`
stream (`getUsersStream()`), and `getUidByEmail(email)` resolves a UID from the
stored `email` field.

## Chat Structure

```
chat_rooms
  {chatRoomId}
    messages
      {autoId}
        senderId, senderEmail, receiverId, message, timestamp
```

`_buildChatRoomId(userId1, userId2)` sorts both UIDs in ascending order and
joins them with an underscore (`abc123_xyz789`). Sorting before joining gives
the same id in both directions, so there is exactly one room per pair of users
and the conversation is never split in half.

## Message Structure

- `senderId` — UID of the signed-in sender
- `senderEmail` — email of the sender at the time of writing
- `receiverId` — UID of the other participant
- `message` — the trimmed message text
- `timestamp` — a Firestore `Timestamp`

`HusseinAdvmobprogMessage.fromMap()` safely handles missing, null, `DateTime`
or epoch values so one broken document cannot crash the conversation. Messages
are read with `orderBy('timestamp', descending: true)` and shown in a reversed
list, so the newest message is at the bottom and both sides update in real time.

## Initiating a Chat

1. The chat FloatingActionButton on the home screen opens `'/chat'`.
2. `HusseinAdvmobprogChatScreen` subscribes once to the `Users` stream,
   excludes the signed-in user, and shows avatar, name and email.
3. The search bar filters the loaded list locally (name, username, email).
4. Tapping a user opens `HusseinAdvmobprogChatDetailScreen`.
5. Sending calls `sendMessage(receiverId, message)`: the text is trimmed, empty
   messages are ignored, the UID/email come from `FirebaseAuth`, and the
   document is written to `chat_rooms/{chatRoomId}/messages`.
6. While Firestore confirms the write, the message shows as a bubble with a
   spinner and **sending...**; the real-time snapshot then replaces it with the
   confirmed message, its time and a single **✓**. No read receipt is faked. If
   the write fails, the bubble is removed and the text is put back in the input
   with an error message.

## Self Chat

A user cannot chat with themselves: the chat list filters out the signed-in
UID, the tap handler ignores an empty or self UID, and `ChatDetailScreen`
checks `_isSelfChat` and shows "You cannot start a chat with yourself." instead
of a conversation, so no `chat_rooms/{uid_uid}` document can be created.
# hussein_advmobprog
# client-proj-hussein_advmobprog
