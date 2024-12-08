library multicast;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:file_share/src/utils/NetworkUtil.dart';

//网络多播地址 多播地址：在224.0.0.0～224.0.0.255之间
final InternetAddress _mDnsAddressIPv4 = InternetAddress('224.0.0.251', type: InternetAddressType.IPv4);
//随机端口号
const int _port = 49153;

typedef MessageCall = void Function(String data, String address);

extension Boardcast on RawDatagramSocket {

  Future<void> boardcast(String msg, int port) async {
    List<int> dataList = utf8.encode(msg);
    send(dataList, _mDnsAddressIPv4, port);
    await Future.delayed(const Duration(milliseconds: 10));
    final Set<String> address = await NetworkUtil().localIpv4Address;
    for (final String addr in address) {
      final tmp = addr.split('.');
      tmp.removeLast();
      final String addrPrfix = tmp.join('.');
      final InternetAddress address = InternetAddress(
        '$addrPrfix.255',
      );
      send(
        dataList,
        address,
        port,
      );
    }
  }

}

/// 通过组播+广播的方式，让设备能够相互在局域网被发现
class Multicast {

  Multicast({this.port = _port});

  //发送/接受广播地址端口
  final int port;
  //接受到广播消息后处理方法
  final List<MessageCall> _callback = [];

  bool _isStartSend = false;
  bool _isStartReceive = false;
  final ReceivePort receivePort = ReceivePort();
  Isolate? isolate;

  /// 停止对 udp 发送消息
  void stopSendBoardcast() {
    if (!_isStartSend) {
      return;
    }
    _isStartSend = false;
    isolate?.kill();
  }

  /// 接收udp广播消息
  Future<void> _receiveBoardcast() async {
    RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
      ttl: 255,
    ).then((RawDatagramSocket socket) {
      // 接收组播消息
      socket.joinMulticast(_mDnsAddressIPv4);
      // 开启广播支持
      socket.broadcastEnabled = true;
      socket.readEventsEnabled = true;
      socket.listen((RawSocketEvent rawSocketEvent) async {
        final Datagram? datagram = socket.receive();
        if (datagram == null) {
          return;
        }

        String message = utf8.decode(datagram.data);
        _notifiAll(message, datagram.address.address);
      });
    });
  }

  void _notifiAll(String data, String address) {
    for (MessageCall call in _callback) {
      call(data, address);
    }
  }

  Future<void> startSendBoardcast(
      List<String> messages, {
        Duration duration = const Duration(seconds: 1),
      }) async {
    if (_isStartSend) {
      return;
    }
    _isStartSend = true;
    isolate = await Isolate.spawn(
      multicastIsoate,
      _IsolateArgs(
        receivePort.sendPort,
        port,
        messages,
        duration,
      ),
    );
  }

  void addListener(MessageCall listener) {
    if (!_isStartReceive) {
      _receiveBoardcast();
      _isStartReceive = true;
    }
    _callback.add(listener);
  }

  void removeListener(MessageCall listener) {
    if (_callback.contains(listener)) {
      _callback.remove(listener);
    }
  }
}

void multicastIsoate(_IsolateArgs args) {
  startSendBoardcast(
    args.messages,
    args.port,
    args.duration,
    args.sendPort,
  );
}

Future<void> startSendBoardcast(
    List<String> messages,
    int port,
    Duration duration,
    SendPort sendPort,
    ) async {
  RawDatagramSocket _socket = await RawDatagramSocket.bind(
    InternetAddress.anyIPv4,
    0,
    ttl: 255,
    reuseAddress: true,
  );
  _socket.broadcastEnabled = true;
  _socket.readEventsEnabled = true;
  Timer.periodic(duration, (timer) async {
    for (String data in messages) {
      _socket.boardcast(data, port);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  });
}

class _IsolateArgs<T> {
  _IsolateArgs(
      this.sendPort,
      this.port,
      this.messages,
      this.duration,
      );

  final SendPort sendPort;
  final int port;
  final List<String> messages;
  final Duration duration;
}

