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
        .map((data) {
          return data
              .where(
                (chatData) =>
                    (chatData['participants'] as List<dynamic>?)?.contains(
                      userId,
                    ) ??
                    false,
              )
              .map((chatData) => Chat.fromJson(chatData))
              .toList();
        });
  }

  // Get or create a chat between two users
  Future<Chat> getOrCreateChat(String user1Id, String user2Id) async {
    try {
      // Get user names for the chat
      final user1Response = await _supabase
          .from('users')
          .select('full_name, email')
          .eq('id', user2Id)
          .single();

      final user2Name =
          (user1Response['full_name'] as String?) ??
          (user1Response['email'] as String).split('@')[0];

      // Check if chat already exists
      final response = await _supabase
          .from('chats')
          .select()
          .eq('type', 'private')
          .contains('participants', [user1Id, user2Id])
          .maybeSingle();

      if (response != null) {
        return Chat.fromJson(response);
      }

      // Create new chat
      final newChat = await _supabase
          .from('chats')
          .insert({
            'type': 'private',
            'activity_id': null,
            'name': user2Name,
            'participants': [user1Id, user2Id],
            'last_message': null,
            'last_message_time': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Chat.fromJson(newChat);
    } catch (e) {
      print('Error getting or creating chat: $e');
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
      print('Error getting or creating group chat: $e');
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
      // Insert message
      await _supabase.from('chat_messages').insert({
        'chat_id': chatId,
        'sender_id': senderId,
        'sender_name': senderName,
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
      print('Error sending message: $e');
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
      // 獲取聊天參與者
      final chatData = await _supabase
          .from('chats')
          .select('participants')
          .eq('id', chatId)
          .single();

      final participants = (chatData['participants'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();

      // 給除了發送者之外的所有參與者發送通知
      for (final participantId in participants) {
        if (participantId != senderId) {
          // 調用 Supabase Edge Function 發送通知
          _supabase.functions.invoke(
            'send-push-notification',
            body: {
              'userId': participantId,
              'title': '新消息',
              'message': '$senderName: $message',
              'type': 'chat',
              'data': {
                'chat_id': chatId,
                'sender_id': senderId,
              }
            },
          ).then((_) {
            print('✅ 推送通知已發送給用戶: $participantId');
          }).catchError((error) {
            print('⚠️ 發送推送通知失敗: $error');
          });
        }
      }
    } catch (e) {
      print('⚠️ 發送推送通知錯誤: $e');
      // 不拋出錯誤，因為消息已經發送成功
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
      print('Error marking messages as read: $e');
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
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    try {
      await _supabase.from('chats').delete().eq('id', chatId);
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }
}
