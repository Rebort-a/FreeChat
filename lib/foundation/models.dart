import 'dart:convert';

import 'package:flutter/foundation.dart';

class AlwaysNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  AlwaysNotifier(this._value) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  @override
  T get value => _value;
  T _value;
  set value(T newValue) {
    _value = newValue;
    notifyListeners();
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}

class ListNotifier<T> extends ValueNotifier<List<T>> {
  final List<VoidCallback> _callBacks = [];

  void addCallBack(VoidCallback callBack) {
    _callBacks.add(callBack);
  }

  void removeCallBack(VoidCallback callBack) {
    _callBacks.remove(callBack);
  }

  void notifyAll() {
    for (VoidCallback callBack in _callBacks) {
      callBack();
    }
  }

  ListNotifier(super.value);

  @override
  List<T> get value => List.unmodifiable(super.value);

  void add(T value) {
    super.value.add(value);
    super.notifyListeners();
    notifyAll();
  }

  void remove(T value) {
    super.value.remove(value);
    super.notifyListeners();
    notifyAll();
  }

  void removeAt(int index) {
    super.value.removeAt(index);
    super.notifyListeners();
    notifyAll();
  }

  void removeWhere(bool Function(T) check) {
    super.value.removeWhere(check);
    super.notifyListeners();
    notifyAll();
  }

  void clear() {
    super.value.clear();
    super.notifyListeners();
    notifyAll();
  }
}

class RoomInfo {
  final String name;
  final String address;
  final int port;
  RoomInfo({required this.name, required this.address, required this.port});
}

enum MessageType { notify, text, image, file }

class ChatMessage {
  String timestamp;
  MessageType type;
  String source;
  String content;

  ChatMessage({
    required this.timestamp,
    required this.type,
    required this.source,
    required this.content,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      timestamp: json['timestamp'],
      type: MessageType.values[json['type']],
      source: json['source'],
      content: json['content'],
    );
  }

  factory ChatMessage.fromSocket(List<int> data) {
    String stringData = utf8.decode(data);
    Map<String, dynamic> jsonString = jsonDecode(stringData);

    return ChatMessage(
      timestamp: jsonString['timestamp'],
      type: MessageType.values[jsonString['type']],
      source: jsonString['source'],
      content: jsonString['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'type': type.index,
      'source': source,
      'content': content,
    };
  }

  List<int> toSocketData() {
    String jsonString = jsonEncode(toJson());
    return utf8.encode(jsonString);
  }
}
