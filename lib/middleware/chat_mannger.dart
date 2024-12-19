import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/models.dart';

class ChatManager {
  late final Socket _socket;

  final AlwaysValueNotifier<void Function(BuildContext)> showPage =
      AlwaysValueNotifier((BuildContext context) {});

  final ValueNotifier<String> messageRecords =
      ValueNotifier<String>(' '.padRight(1000));

  final textController = TextEditingController();

  final RoomInfo roomInfo;
  final String userName;

  ChatManager(this.roomInfo, this.userName) {
    messageRecords.value += '\n';
    _connectToServer();
    _startKeyboard();
  }

  void _connectToServer() async {
    try {
      // 连接到服务器
      _socket = await Socket.connect(roomInfo.address, roomInfo.port);
      // 监听服务器发来的消息
      _socket.listen(
        (data) {
          // 收到消息
          messageRecords.value += utf8.decode(data);
        },
        onDone: () {
          // 连接关闭
          _stopConnection();
        },
        onError: (error) {
          // 处理错误
          messageRecords.value += 'Socket connect error: $error\n';
        },
      );

      // 连接服务器后，发送第一条消息
      _socket.add(utf8.encode('${' '.padRight(64)}$userName join in room\n'));
    } catch (e) {
      messageRecords.value += 'Failed to connect: $e\n';
    }
  }

  void sendMessage() {
    final text = textController.text;
    if (text.isEmpty) {
      return;
    }
    final message = '${' '.padRight(4)}$userName: $text\n';
    _socket.add(utf8.encode(message));
    textController.clear();
  }

  void leaveRoom() {
    _socket.add(utf8.encode('${' '.padRight(64)}$userName left the room\n'));
    _stopConnection();
  }

  void _stopConnection() {
    _stopKeyboard();
    textController.dispose();
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
}
