import 'package:flutter/material.dart';

import '../foundation/models.dart';
import '../middleware/chat_mannger.dart';

class ChatPage extends StatelessWidget {
  late final ChatManager _chatManager;
  final RoomInfo roomInfo;
  final String userName;

  ChatPage({super.key, required this.roomInfo, required this.userName}) {
    _chatManager = ChatManager(roomInfo, userName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(roomInfo.name),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.exit_to_app),
        onPressed: _chatManager.leaveRoom,
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildDialog(),
        Expanded(
          child: _buildMessageList(),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildDialog() {
    return ValueListenableBuilder<void Function(BuildContext)>(
      valueListenable: _chatManager.showPage,
      builder: (context, value, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          value(context);
        });
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageList() {
    return ValueListenableBuilder<String>(
      valueListenable: _chatManager.messageRecords,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: SingleChildScrollView(
            reverse: true,
            child: Text(value, style: Theme.of(context).textTheme.titleLarge),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _chatManager.textController,
              decoration:
                  const InputDecoration.collapsed(hintText: 'Type a message'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _chatManager.sendMessage,
          ),
        ],
      ),
    );
  }
}
