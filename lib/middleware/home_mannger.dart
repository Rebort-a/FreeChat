import 'package:flutter/material.dart';

import '../foundation/discovery.dart';
import '../foundation/models.dart';
import '../foundation/socket_service.dart';
import '../upper/chat_page.dart';
import '../upper/dialog.dart';

class CreatedRoomInfo extends RoomInfo {
  final SocketService server;

  CreatedRoomInfo(
      {required super.name,
      required super.address,
      required super.port,
      required this.server});
}

class HomeMannger {
  final _discovery = Discovery();

  final AlwaysValueNotifier<void Function(BuildContext)> showPage =
      AlwaysValueNotifier((BuildContext context) {});

  final List<CreatedRoomInfo> createdRooms = [];
  final List<RoomInfo> othersRooms = [];

  final ValueNotifier<int> createdRoomsCount = ValueNotifier(0);
  final ValueNotifier<int> othersRoomsCount = ValueNotifier(0);

  HomeMannger() {
    _discovery.startReceive(_handleReceivedMessage);
  }

  void stop() {
    _discovery.stopReceive();
    stopAllCreatedRooms();
    othersRooms.clear();
    othersRoomsCount.value = othersRooms.length;
  }

  void _handleReceivedMessage(String address, String message) {
    // Parse the message to extract room name and port
    // Example message format: "RoomName,stop" "RoomName,1234"
    final parts = message.split(',');
    if (parts.length == 2) {
      if (parts[1] == 'stop') {
        othersRooms.removeWhere(
            (room) => room.name == parts[0] && room.address == address);
        othersRoomsCount.value = othersRooms.length;
      } else {
        int port = int.parse(parts[1]);
        RoomInfo newRoom =
            RoomInfo(name: parts[0], address: address, port: port);
        bool isMyRoom = createdRooms.any(
            (room) => room.name == newRoom.name && room.port == newRoom.port);

        bool isOtherRoom = othersRooms.any((room) =>
            room.name == newRoom.name &&
            room.address == newRoom.address &&
            room.port == newRoom.port);

        if ((!isMyRoom) && (!isOtherRoom)) {
          othersRooms.add(newRoom);
          othersRoomsCount.value = othersRooms.length;
        }
      }
    }
  }

  void stopAllCreatedRooms() {
    for (var room in createdRooms) {
      room.server.stop();
    }
    createdRooms.clear();
    createdRoomsCount.value = createdRooms.length;
  }

  void stopCreatedRoom(int index) {
    var room = createdRooms[index];
    room.server.stop();
    createdRooms.removeAt(index);
    createdRoomsCount.value = createdRooms.length;
  }

  Future<void> _createRoom(String roomName) async {
    SocketService server = SocketService(roomName);

    await server.start();

    createdRooms.add(CreatedRoomInfo(
        name: roomName,
        address: 'localhost',
        port: server.port,
        server: server));

    createdRoomsCount.value = createdRooms.length;
  }

  void showCreateRoomDialog() {
    showPage.value = (BuildContext context) {
      DialogCollection.showCreateRoomDialog(
          context: context, onConfirm: _createRoom);
    };
  }

  void _joinRoom(RoomInfo room, String userName, BuildContext context) {
    if (userName.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ChatPage(roomInfo: room, userName: userName),
      ));
    }
  }

  void showJoinRoomDialog(RoomInfo room) {
    showPage.value = (BuildContext context) {
      DialogCollection.showJoinRoomDialog(
          context: context, room: room, onConfirm: _joinRoom);
    };
  }
}
