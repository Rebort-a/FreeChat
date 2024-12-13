import 'socket_manager.dart';

class RoomInfo {
  String name;
  String address;
  int port;
  SocketManager? server;

  RoomInfo({
    required this.name,
    required this.address,
    required this.port,
    this.server,
  });
}
