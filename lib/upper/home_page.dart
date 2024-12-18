import 'package:flutter/material.dart';

import '../middleware/home_mannger.dart';

class HomePage extends StatelessWidget {
  final _homeManager = HomeMannger();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Chat Rooms'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            _homeManager.showCreateRoomDialog();
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return ListView(
      children: [
        _buildDialog(),
        _buildMyRoomTitle(),
        _buildMyRooms(),
        _buildOtherRoomTitle(),
        _buildOtherRooms(),
      ],
    );
  }

  Widget _buildDialog() {
    return ValueListenableBuilder<void Function(BuildContext)>(
      valueListenable: _homeManager.showPage,
      builder: (context, value, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          value(context);
        });
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMyRoomTitle() {
    return ValueListenableBuilder<int>(
      valueListenable: _homeManager.createdRoomsCount,
      builder: (context, value, child) {
        return value == 0
            ? const SizedBox.shrink()
            : ListTile(
                leading: const Icon(Icons.chevron_right),
                title: Text(
                  'The rooms you created',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                trailing: value > 1
                    ? TextButton(
                        onPressed: _homeManager.stopAllCreatedRooms,
                        child: const Text('STOP ALL'),
                      )
                    : null,
              );
      },
    );
  }

  Widget _buildMyRooms() {
    return ValueListenableBuilder<int>(
      valueListenable: _homeManager.createdRoomsCount,
      builder: (context, value, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: value,
          itemBuilder: (context, index) {
            final room = _homeManager.createdRooms[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.wifi),
                title: Text(room.name),
                subtitle: Text('${room.address}:${room.port}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => _homeManager.showJoinRoomDialog(room),
                      child: const Text('JOIN'),
                    ),
                    TextButton(
                      onPressed: () => _homeManager.stopCreatedRoom(index),
                      child: const Text('STOP'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOtherRoomTitle() {
    return ValueListenableBuilder<int>(
      valueListenable: _homeManager.othersRoomsCount,
      builder: (context, value, child) {
        return value == 0
            ? const SizedBox.shrink()
            : ListTile(
                leading: const Icon(Icons.chevron_right),
                title: Text(
                  'The other rooms',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              );
      },
    );
  }

  Widget _buildOtherRooms() {
    return ValueListenableBuilder<int>(
      valueListenable: _homeManager.othersRoomsCount,
      builder: (context, value, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: value,
          itemBuilder: (context, index) {
            final room = _homeManager.othersRooms[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.wifi),
                title: Text(room.name),
                subtitle: Text('${room.address}:${room.port}'),
                trailing: TextButton(
                  onPressed: () => _homeManager.showJoinRoomDialog(room),
                  child: const Text('JOIN'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
