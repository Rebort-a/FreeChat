import 'package:flutter/material.dart';

import '../foundation/base_type.dart';
import '../foundation/multicast_service.dart';
import '../foundation/socket_manager.dart';
import 'chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _multicast = MulticastService();

  final List<RoomInfo> _yourRooms = [];
  final List<RoomInfo> _otherRooms = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDiscovery();
    });
  }

  void _startDiscovery() {
    _multicast.addListener(_handldBroadcastMessage);
    _multicast.startReceiveBoardcast();
  }

  void _handldBroadcastMessage(String address, String message) {
    // Parse the message to extract room name and port
    // Example message format: "RoomName,1234"
    final parts = message.split(',');
    if (parts.length == 2) {
      if (parts[1] == 'stop') {
        setState(() {
          _otherRooms.removeWhere(
              (room) => room.name == parts[0] && room.address == address);
        });
      } else {
        int port = int.parse(parts[1]);
        RoomInfo newRoom =
            RoomInfo(name: parts[0], address: address, port: port);
        bool isYourRoom = _yourRooms.any(
            (room) => room.name == newRoom.name && room.port == newRoom.port);

        bool isOtherRoom = _otherRooms.any((room) =>
            room.name == newRoom.name &&
            room.address == newRoom.address &&
            room.port == newRoom.port);

        if ((!isYourRoom) && (!isOtherRoom)) {
          setState(() {
            _otherRooms.add(newRoom);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _multicast.stopReceiveBoardcast();
    clearAllYourRooms();
    super.dispose();
  }

  void clearAllYourRooms() {
    for (var room in _yourRooms) {
      room.server!.stop(room.name);
    }
    setState(() {
      _yourRooms.clear();
    });
  }

  void _clearYourRoom(RoomInfo room) {
    room.server!.stop(room.name);
    setState(() {
      _yourRooms.remove(room);
    });
  }

  Future<void> _createRoom(String roomName) async {
    SocketManager server = SocketManager();

    await server.start(roomName);

    setState(() {
      _yourRooms.add(RoomInfo(
        name: roomName,
        address: 'localhost',
        port: server.server.port,
        server: server,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildAppBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Chat Rooms'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            _showCreateRoomDialog();
          },
        ),
      ],
    );
  }

  Widget _buildAppBody() {
    return ListView(
      children: [
        _buildYourRoomTitle(),
        _buildYourRooms(),
        _buildOtherRoomTitle(),
        _buildOtherRooms(),
      ],
    );
  }

  Widget _buildYourRoomTitle() {
    return _yourRooms.isEmpty
        ? const SizedBox.shrink()
        : ListTile(
            leading: const Icon(Icons.chevron_right),
            title: Text(
              'The rooms you created',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            trailing: TextButton(
              onPressed: clearAllYourRooms,
              child: const Text('STOP ALL'),
            ),
          );
  }

  Widget _buildYourRooms() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _yourRooms.length,
      itemBuilder: (context, index) {
        final room = _yourRooms[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.wifi),
            title: Text(room.name),
            subtitle: Text('${room.address}:${room.port}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextButton(
                  onPressed: () => _joinRoom(room),
                  child: const Text('JOIN'),
                ),
                TextButton(
                  onPressed: () => _clearYourRoom(room),
                  child: const Text('STOP'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtherRoomTitle() {
    return _otherRooms.isEmpty
        ? const SizedBox.shrink()
        : ListTile(
            leading: const Icon(Icons.chevron_right),
            title: Text(
              'The other rooms',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
  }

  Widget _buildOtherRooms() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _otherRooms.length,
      itemBuilder: (context, index) {
        final room = _otherRooms[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.wifi),
            title: Text(room.name),
            subtitle: Text('${room.address}:${room.port}'),
            trailing: TextButton(
              onPressed: () => _joinRoom(room),
              child: const Text('JOIN'),
            ),
          ),
        );
      },
    );
  }

  void _showCreateRoomDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String roomName = 'Default Room';
        return _buildCreateRoomAlertDialog(roomName, context);
      },
    );
  }

  AlertDialog _buildCreateRoomAlertDialog(
      String roomName, BuildContext context) {
    return AlertDialog(
      title: const Center(child: Text('Create room')),
      content: TextField(
        onChanged: (value) {
          roomName = value;
        },
        decoration: const InputDecoration(hintText: 'Enter room name'),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Create'),
          onPressed: () {
            _createRoom(roomName);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void _joinRoom(RoomInfo room) {
    _showJoinRoomDialog(room);
  }

  void _showJoinRoomDialog(RoomInfo room) {
    String userName = 'default';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildJoinRoomAlertDialog(room, context, userName);
      },
    );
  }

  AlertDialog _buildJoinRoomAlertDialog(
      RoomInfo room, BuildContext context, String userName) {
    return AlertDialog(
      title: const Center(child: Text('Join room')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Enter your name:'),
          TextField(
            onChanged: (value) {
              userName = value;
            },
            decoration: const InputDecoration(hintText: 'Your Name'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Join'),
          onPressed: () {
            _handleJoinButtonPress(room, userName, context);
          },
        ),
      ],
    );
  }

  void _handleJoinButtonPress(
      RoomInfo room, String userName, BuildContext context) {
    if (userName.isNotEmpty) {
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ChatPage(roomInfo: room, userName: userName),
      ));
    }
  }
}
