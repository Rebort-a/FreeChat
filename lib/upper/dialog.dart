import 'package:flutter/material.dart';

import '../foundation/models.dart';

class DialogCollection {
  static void showCreateRoomDialog({
    required BuildContext context,
    required Function(String roomName) onConfirm,
  }) {
    String roomName = 'Default Room';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(child: Text('Create')),
          content: TextField(
            onChanged: (value) {
              roomName = value;
            },
            decoration: const InputDecoration(hintText: 'Enter name'),
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
                Navigator.of(context).pop();
                onConfirm(roomName);
              },
            ),
          ],
        );
      },
    );
  }

  static void showJoinRoomDialog({
    required BuildContext context,
    required RoomInfo room,
    required Function(RoomInfo room, String userName, BuildContext context)
        onConfirm,
  }) {
    String userName = 'default';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(child: Text('Join')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Enter your name:'),
              TextField(
                onChanged: (value) {
                  userName = value;
                },
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
                Navigator.of(context).pop();
                onConfirm(room, userName, context);
              },
            ),
          ],
        );
      },
    );
  }
}
