import 'package:flutter/material.dart';

class RoomInfo {
  final String name;
  final String address;
  final int port;
  RoomInfo({required this.name, required this.address, required this.port});
}

class AlwaysValueNotifier<T> extends ValueNotifier<T> {
  AlwaysValueNotifier(super.value);

  @override
  set value(T newValue) {
    super.value = newValue;
    notifyListeners();
  }
}
