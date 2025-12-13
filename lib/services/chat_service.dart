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
        .order('last_message_time', ascending: false)
        .map((data) {
          return data
              .where((chatData) =>
                  chatData['user1_id'] == userId ||
                  chatData['user2_id'] == userId)
              .map((chatData) => Chat.fromJson(chatData))
              .toList();
        });
  }

  // Get or create a chat between two users
  Future<Chat> getOrCreateChat(String user1Id, String user2Id) async {
    try {
      // Check if chat already exists
      final response = await _supabase
          .from('chats')
          .select()
          .or('user1_id.eq.$user1Id,user2_id.eq.$user1Id')
          .or('user1_id.eq.$user2Id,user2_id.eq.$user2Id')
          .maybeSingle();

      if (response != null) {
        return Chat.fromJson(response);
      }

      // Create new chat
      final newChat = await _supabase
          .from('chats')
          .insert({
            'user1_id': user1Id,
            'user2_id': user2Id,
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

  // Get messages for a chat
  Stream<List<Message>> getChatMessages(String chatId) {
    return _supabase
        .from('messages')
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
      await _supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': senderId,
        'sender_name': senderName,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update chat's last message
      await _supabase.from('chats').update({
        'last_message': content,
        'last_message_time': DateTime.now().toIso8601String(),
      }).eq('id', chatId);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _supabase
          .from('messages')
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
          .from('messages')
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
