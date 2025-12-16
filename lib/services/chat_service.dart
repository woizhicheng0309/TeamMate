import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all chats for a user
  Stream<List<Chat>> getUserChats(String userId) {
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('last_message_time', ascending: true)
        .map((data) async {
          final filteredChats = data
              .where(
                (chatData) =>
                    (chatData['participants'] as List<dynamic>?)?.contains(
                      userId,
                    ) ??
                    false,
              )
              .toList();

          // 对于私聊，动态获取对方的名字
          final chats = <Chat>[];
          for (final chatData in filteredChats) {
            final chat = Chat.fromJson(chatData);

            // 如果是私聊，获取对方的名字
            if (chat.type == 'private') {
              try {
                // 找出对方的 ID（不是当前用户的）
                final participants = chatData['participants'] as List<dynamic>;
                final otherUserId = participants.firstWhere(
                  (p) => p.toString() != userId,
                  orElse: () => null,
                );

                if (otherUserId != null) {
                  // 获取对方的名字
                  final otherUserResponse = await _supabase
                      .from('users')
                      .select('full_name, email')
                      .eq('id', otherUserId.toString())
                      .maybeSingle();

                  if (otherUserResponse != null) {
                    final otherUserName =
                        (otherUserResponse['full_name'] as String?) ??
                        (otherUserResponse['email'] as String).split('@')[0];

                    // 更新聊天名称为对方的名字
                    chats.add(
                      Chat(
                        id: chat.id,
                        type: chat.type,
                        activityId: chat.activityId,
                        name: otherUserName,
                        avatarUrl: chat.avatarUrl,
                        participants: chat.participants,
                        lastMessage: chat.lastMessage,
                        lastMessageTime: chat.lastMessageTime,
                        unreadCount: chat.unreadCount,
                        createdAt: chat.createdAt,
                        isPinned: chat.isPinned,
                      ),
                    );
                  } else {
                    chats.add(chat);
                  }
                } else {
                  chats.add(chat);
                }
              } catch (e) {
                chats.add(chat);
              }
            } else {
              chats.add(chat);
            }
          }

          return chats;
        })
        .asyncExpand((futureChats) => Stream.fromFuture(futureChats));
  }

  // Get or create a chat between two users
  Future<Chat> getOrCreateChat(String user1Id, String user2Id) async {
    try {
      // Check if chat already exists
      final response = await _supabase
          .from('chats')
          .select()
          .eq('type', 'private')
          .contains('participants', [user1Id, user2Id])
          .maybeSingle();

      if (response != null) {
        // Get other user's info for display
        final otherUserId = (response['participants'] as List).firstWhere(
          (id) => id != user1Id,
        );
        final userResponse = await _supabase
            .from('users')
            .select('full_name, email, avatar_url')
            .eq('id', otherUserId)
            .single();

        final otherUserName =
            (userResponse['full_name'] as String?) ??
            (userResponse['email'] as String).split('@')[0];
        final otherUserAvatar = userResponse['avatar_url'] as String?;

        return Chat.fromJson({
          ...response,
          'name': otherUserName,
          'avatar_url': otherUserAvatar,
        });
      }

      // Create new chat (without fixed name/avatar for private chats)
      final newChat = await _supabase
          .from('chats')
          .insert({
            'type': 'private',
            'activity_id': null,
            'name':
                'Private Chat', // Required by database, will be overridden dynamically
            'avatar_url': null, // Will be populated dynamically
            'participants': [user1Id, user2Id],
            'last_message': null,
            'last_message_time': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Get other user's info for display
      final userResponse = await _supabase
          .from('users')
          .select('full_name, email, avatar_url')
          .eq('id', user2Id)
          .single();

      final otherUserName =
          (userResponse['full_name'] as String?) ??
          (userResponse['email'] as String).split('@')[0];
      final otherUserAvatar = userResponse['avatar_url'] as String?;

      return Chat.fromJson({
        ...newChat,
        'name': otherUserName,
        'avatar_url': otherUserAvatar,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get or create a group chat for an activity
  Future<Chat> getOrCreateGroupChat({
    required String activityId,
    required String groupName,
    required List<String> participantIds,
  }) async {
    try {
      // Check if group chat already exists for this activity
      final response = await _supabase
          .from('chats')
          .select()
          .eq('activity_id', activityId)
          .eq('type', 'group')
          .maybeSingle();

      if (response != null) {
        // Update participants list
        await _supabase
            .from('chats')
            .update({'participants': participantIds})
            .eq('id', response['id']);

        return Chat.fromJson({...response, 'participants': participantIds});
      }

      // Create new group chat
      final newChat = await _supabase
          .from('chats')
          .insert({
            'type': 'group',
            'activity_id': activityId,
            'name': groupName,
            'participants': participantIds,
            'last_message': null,
            'last_message_time': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Chat.fromJson(newChat);
    } catch (e) {
      rethrow;
    }
  }

  // Get messages for a chat
  Stream<List<Message>> getChatMessages(String chatId) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => Message.fromJson(json)).toList());
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    try {
      // 查詢發送者頭像，並一併寫入訊息
      String? senderAvatar;
      try {
        final profile = await _supabase
            .from('users')
            .select('avatar_url')
            .eq('id', senderId)
            .maybeSingle();
        senderAvatar = profile != null
            ? profile['avatar_url'] as String?
            : null;
      } catch (_) {}

      // Insert message（包含 sender_avatar）
      await _supabase.from('chat_messages').insert({
        'chat_id': chatId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_avatar': senderAvatar,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update chat's last message
      await _supabase
          .from('chats')
          .update({
            'last_message': content,
            'last_message_time': DateTime.now().toIso8601String(),
          })
          .eq('id', chatId);

      // 發送推送通知給其他參與者
      _sendPushNotification(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: content,
      );
    } catch (e) {
      rethrow;
    }
  }

  // 發送推送通知（內部方法）
  Future<void> _sendPushNotification({
    required String chatId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    try {
      // 根據發送者的隱私設定決定顯示名稱（暱稱或電子郵件）
      String displaySenderName = senderName;
      try {
        final senderProfile = await _supabase
            .from('users')
            .select('full_name, email, privacy_show_email')
            .eq('id', senderId)
            .maybeSingle();

        if (senderProfile != null) {
          final allowShowEmail =
              senderProfile['privacy_show_email'] as bool? ?? true;
          final fullName = senderProfile['full_name'] as String?;
          final email = senderProfile['email'] as String?;

          if (!allowShowEmail) {
            // 關閉電子郵件顯示時，優先顯示暱稱，無暱稱則顯示 email 的前綴
            displaySenderName = (fullName != null && fullName.isNotEmpty)
                ? fullName
                : (email != null ? (email.split('@').first) : senderName);
          } else {
            // 開啟電子郵件顯示時，使用 email 前綴（保持簡潔）
            displaySenderName = (email != null
                ? (email.split('@').first)
                : (fullName ?? senderName));
          }
        }
      } catch (e) {
        // Silent fail - use original sender name
      }

      // 獲取聊天信息（包括類型和參與者）
      final chatData = await _supabase
          .from('chats')
          .select('type, name, participants')
          .eq('id', chatId)
          .single();

      final chatType = chatData['type'] as String?;
      final chatName = chatData['name'] as String?;
      final participants = (chatData['participants'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();

      // 給除了發送者之外的所有參與者發送通知
      for (final participantId in participants) {
        if (participantId != senderId) {
          try {
            // 檢查用戶的通知設定
            final userSettings = await _supabase
                .from('users')
                .select('notification_chat')
                .eq('id', participantId)
                .maybeSingle();

            final chatNotificationEnabled =
                userSettings?['notification_chat'] as bool? ?? true;

            if (!chatNotificationEnabled) {
              continue;
            }

            // 根據聊天類型設置不同的通知格式
            String notificationTitle;
            String notificationMessage;
            
            if (chatType == 'group') {
              // 群組聊天：標題顯示群組名稱，消息顯示發送者和內容
              notificationTitle = chatName ?? '群組聊天';
              notificationMessage = '$displaySenderName: $message';
            } else {
              // 私聊：標題顯示發送者名稱，消息只顯示內容
              notificationTitle = displaySenderName;
              notificationMessage = message;
            }

            // 調用 Supabase Edge Function 發送通知
            final response = await _supabase.functions.invoke(
              'send-push-notification',
              body: {
                'userId': participantId,
                'title': notificationTitle,
                'message': notificationMessage,
                'type': 'chat',
                'data': {
                  'chat_id': chatId,
                  'sender_id': senderId,
                  'chat_type': chatType ?? 'private',
                },
              },
            );
          } catch (error) {
            // Silent fail - continue sending to other participants
          }
        }
      }
    } catch (e) {
      // Silent fail - message already sent successfully
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _supabase
          .from('chat_messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (e) {
      // Silent fail
    }
  }

  // Get unread message count for a chat
  Future<int> getUnreadCount(String chatId, String userId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('chat_id', chatId)
          .neq('sender_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Update chat pinned status
  Future<void> updateChatPinned(String chatId, bool isPinned) async {
    try {
      await _supabase
          .from('chats')
          .update({'is_pinned': isPinned})
          .eq('id', chatId);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    try {
      await _supabase.from('chats').delete().eq('id', chatId);
    } catch (e) {
      rethrow;
    }
  }
}
