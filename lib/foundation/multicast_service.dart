import 'dart:async';
import 'dart:convert';
import 'dart:io';

class MulticastService {
  static const String multicastAddress = '224.0.0.251';
  static const int multicastPort = 4545;
  static const String broadcastNetmask = '255.255.255.0';

  final List<void Function(String address, String message)> _callbacks = [];

  late RawDatagramSocket _receiveSocket;
  late RawDatagramSocket _sendSocket;

  late Timer _sendTimer;

  // 接收udp广播和组播消息，然后调用回调函数
  Future<void> startReceiveBoardcast() async {
    _receiveSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      multicastPort,
      reuseAddress: true,
      ttl: 255,
    );

    // 开启广播支持
    _receiveSocket.broadcastEnabled = true;
    _receiveSocket.readEventsEnabled = true;

    // 接收组播消息
    _receiveSocket.joinMulticast(InternetAddress(multicastAddress));

    _receiveSocket.listen((RawSocketEvent event) async {
      if (event == RawSocketEvent.read) {
        Datagram? dgram = _receiveSocket.receive();
        if (dgram != null) {
          _notifiAll(dgram.address, utf8.decode(dgram.data));
        }
      }
    });
  }

  void _notifiAll(InternetAddress address, String message) {
    for (var callback in _callbacks) {
      callback(address.address, message);
    }
  }

  void addListener(void Function(String address, String message) callback) {
    _callbacks.add(callback);
  }

  void stopReceiveBoardcast() {
    _receiveSocket.close();
  }

  // 定时发送消息到组播和广播地址
  Future<void> startSendingMessage(String message, Duration interval) async {
    _sendTimer = Timer.periodic(interval, (timer) async {
      sendMessage(message);
    });
  }

  void stopSendingMessages() {
    if (_sendTimer.isActive) {
      _sendTimer.cancel();
    }
    _sendSocket.close();
  }

  Future<void> sendMessage(String message) async {
    final messageBuffer = utf8.encode(message);
    _sendSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      multicastPort,
      reuseAddress: true,
      ttl: 255,
    );

    // 开启广播支持
    _sendSocket.broadcastEnabled = true;
    _sendSocket.readEventsEnabled = true;

    // 发送组播信息
    _sendSocket.send(
        messageBuffer, InternetAddress(multicastAddress), multicastPort);

    // 发送广播消息
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    // 遍历网卡接口
    for (var interface in interfaces) {
      // 遍历ip地址
      for (var address in interface.addresses) {
        if (isIPv4(address.address)) {
          final broadcastAddress =
              _getBroadcastAddress(address.address, broadcastNetmask);
          _sendSocket.send(
              messageBuffer, InternetAddress(broadcastAddress), multicastPort);
        }
      }
    }

    _sendSocket.close();
  }

  // 通过哈希值快速判断是否为IPv4地址，来源为getX
  bool isIPv4(String address) {
    return RegExp(r'^(?:(?:^|\.)(?:2(?:5[0-5]|[0-4]\d)|1?\d?\d)){4}$')
        .hasMatch(address);
  }

  // 使用ip地址和子网掩码组合获取广播地址
  String _getBroadcastAddress(String localAddress, String netmask) {
    final localParts = localAddress.split('.');
    final netmaskParts = netmask.split('.');

    final broadcastParts = List.generate(4, (i) {
      final localPart = int.parse(localParts[i]);
      final netmaskPart = int.parse(netmaskParts[i]);
      return '${localPart | (~netmaskPart & 0xFF)}';
    });

    return broadcastParts.join('.');
  }
}
