import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import '../foundation/base_type.dart';

class ChatPage extends StatefulWidget {
  final RoomInfo roomInfo;
  final String userName;

  const ChatPage({super.key, required this.roomInfo, required this.userName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Socket _socket;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <String>[];

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  void _connectToServer() async {
    try {
      // 构建Socket连接的地址
      final address = widget.roomInfo.address;
      final port = widget.roomInfo.port;
      // 连接到服务器
      _socket = await Socket.connect(address, port);
      // 监听服务器发来的消息
      _socket.listen(
        (data) {
          setState(() {
            _addMessage(utf8.decode(data));
          });
        },
        onDone: () {
          // 连接关闭
          _socket.destroy();
        },
        onError: (error) {
          // 处理错误
          setState(() {
            _messages.add('Socket connect error: $error');
          });
        },
      );
      // 发送加入房间的消息
      _sendMessage('${widget.userName} join in room');
    } catch (e) {
      setState(() {
        _messages.add('Failed to connect: $e');
      });
    }
  }

  void _addMessage(String message) {
    setState(() {
      _messages.add(message);
    });
    // 确保在布局更新完成后滚动到最底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String text) {
    final message = '${widget.userName}:$text\n';
    _socket.add(utf8.encode(message));
  }

  void _leaveRoom() {
    _sendMessage('${widget.userName} left the room');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomInfo.name),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: _leaveRoom,
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[index]),
                );
              },
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration.collapsed(
                        hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final text = _messageController.text;
                    _sendMessage(text);
                    _messageController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _socket.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
