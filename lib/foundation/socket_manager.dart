import 'dart:io';
import 'dart:async';

import 'multicast_service.dart';

class SocketManager {
  final _multicast = MulticastService();
  final Set<Socket> _clients = <Socket>{};
  late final ServerSocket _server;

  ServerSocket get server => _server;

  Future<void> start(String roomName) async {
    // 等待服务器绑定到一个随机端口
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);

    // 监听新的连接
    _server.listen((Socket clientSocket) {
      // 当新的Socket连接时，将其添加到客户端列表中
      _clients.add(clientSocket);

      // 监听来自客户端的消息
      clientSocket.listen(
        (data) {
          // 广播消息给所有已连接的客户端
          _broadcastMessage(data);
        },
        onError: (error) {
          // print('Socket error: $error');
        },
        onDone: () {
          // 当Socket关闭时，从列表中移除
          _clients.remove(clientSocket);
          clientSocket.destroy();
        },
        cancelOnError: true,
      );
    });

    // 开始广播房间信息
    _multicast.startSendingMessage(
      '$roomName,${_server.port}',
      const Duration(seconds: 1),
    );
  }

  void _broadcastMessage(List<int> data) {
    // 遍历所有已连接的客户端
    for (var client in _clients) {
      // 发送消息给客户端
      client.add(data);
    }
  }

  void stop(String roomName) {
    _multicast.stopSendingMessages();

    // 发送停止信息
    _multicast.sendMessage('$roomName,stop');

    _server.close();
  }
}
