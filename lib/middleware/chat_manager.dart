import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/models.dart';

class ChatManager {
  late final Socket _socket;

  final AlwaysNotifier<void Function(BuildContext)> showPage =
      AlwaysNotifier((BuildContext context) {});

  final ListNotifier<ChatMessage> messageList = ListNotifier([]);

  final textController = TextEditingController();
  final scrollController = ScrollController();

  final RoomInfo roomInfo;
  final String userName;

  ChatManager(this.roomInfo, this.userName) {
    _connectToServer();
    _startKeyboard();
    messageList.addCallBack(_scrollToBottom);
  }

  void _connectToServer() async {
    try {
      // 连接到服务器
      _socket = await Socket.connect(roomInfo.address, roomInfo.port);
      // 监听服务器发来的消息
      _socket.listen(
        (data) {
          // 收到消息
          messageList.add(ChatMessage.fromSocket(data));
        },
        onDone: () {
          // 连接关闭
          _stopConnection();
        },
        onError: (error) {
          // 处理错误
          messageList.add(ChatMessage(
              timestamp: DateTime.now().toIso8601String(),
              source: 'system',
              type: MessageType.notify,
              content: 'Socket connect error: $error'));
        },
      );

      // 连接服务器后，发送第一条消息
      ChatMessage message = ChatMessage(
        timestamp: DateTime.now().toIso8601String(),
        source: userName,
        type: MessageType.notify,
        content: 'join in room',
      );

      _socket.add(utf8.encode(jsonEncode(message.toJson())));
    } catch (e) {
      messageList.add(ChatMessage(
          timestamp: DateTime.now().toIso8601String(),
          source: 'system',
          type: MessageType.notify,
          content: 'Failed to connect: $e'));
    }
  }

  void sendMessage() {
    final text = textController.text;
    if (text.isEmpty) {
      return;
    }

    ChatMessage message = ChatMessage(
      timestamp: DateTime.now().toIso8601String(),
      source: userName,
      type: MessageType.text,
      content: text,
    );

    _socket.add(utf8.encode(jsonEncode(message.toJson())));

    textController.clear();
  }

  void leaveRoom() {
    ChatMessage message = ChatMessage(
      timestamp: DateTime.now().toIso8601String(),
      source: userName,
      type: MessageType.notify,
      content: 'leave room',
    );

    _socket.add(utf8.encode(jsonEncode(message.toJson())));

    _stopConnection();
  }

  void _stopConnection() {
    _stopKeyboard();
    _socket.destroy();
    showPage.value = (BuildContext context) {
      Navigator.of(context).pop();
    };
  }

  void _startKeyboard() {
    // 添加键盘事件处理器
    HardwareKeyboard.instance.addHandler(_handleHardwareKeyboardEvent);
  }

  void _stopKeyboard() {
    // 移除键盘事件处理器
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyboardEvent);
  }

  bool _handleHardwareKeyboardEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        sendMessage();
        return true;
      }
    }
    return false;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
