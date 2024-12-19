import 'package:flutter/material.dart';

import '../foundation/models.dart';
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
          onPressed: _homeManager.showCreateRoomDialog,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return ListView(
      children: [
        _buildDialog(),
        _buildSectionTitle('The rooms you created',
            _homeManager.createdRoomsCount, _homeManager.stopAllCreatedRooms),
        _buildRoomList(
            _homeManager.createdRooms,
            _homeManager.createdRoomsCount,
            _homeManager.showJoinRoomDialog,
            _homeManager.stopCreatedRoom),
        _buildSectionTitle(
            'The other rooms', _homeManager.othersRoomsCount, null),
        _buildRoomList(_homeManager.othersRooms, _homeManager.othersRoomsCount,
            _homeManager.showJoinRoomDialog, null),
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

  Widget _buildSectionTitle(String title, ValueNotifier<int> countListenable,
      VoidCallback? onStopAll) {
    return ValueListenableBuilder<int>(
      valueListenable: countListenable,
      builder: (context, value, child) {
        if (value == 0) return const SizedBox.shrink();
        return ListTile(
          leading: const Icon(Icons.chevron_right),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          trailing: onStopAll != null && value > 1
              ? TextButton(
                  onPressed: onStopAll,
                  child: const Text('STOP ALL'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildRoomList(
      List<RoomInfo> rooms,
      ValueNotifier<int> countListenable,
      Function(RoomInfo) onJoin,
      Function(int)? onStop) {
    return ValueListenableBuilder<int>(
      valueListenable: countListenable,
      builder: (context, value, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: value,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return _buildRoomTile(
                room, onJoin, onStop != null ? () => onStop(index) : null);
          },
        );
      },
    );
  }

  Widget _buildRoomTile(
      RoomInfo room, Function(RoomInfo) onJoin, VoidCallback? onStop) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.wifi),
        title: Text(room.name),
        subtitle: Text('${room.address}:${room.port}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextButton(
              onPressed: () => onJoin(room),
              child: const Text('JOIN'),
            ),
            if (onStop != null)
              TextButton(
                onPressed: onStop,
                child: const Text('STOP'),
              ),
          ],
        ),
      ),
    );
  }
}
