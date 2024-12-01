import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fileShare/src/common/Global.dart';
import 'package:fileShare/src/init.dart';
import 'package:fileShare/src/multicast.dart';
import 'package:fileShare/src/service/HttpServer.dart';
import 'package:fileShare/src/utils/NetworkUtil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:http/http.dart' as http;

import 'src/home.dart';

Future<void> main() async {

  final ReceivePort mainReceivePort = ReceivePort();
  //启动http服务 接受文件
  Isolate.spawn((mainSendPort) async {
    shelf_io
        .serve(HttpService().route.call, InternetAddress.anyIPv4, 8080)
        .then((completeServe) {
      print(
          "服务启动完成地址: http://${completeServe.address.host}:${completeServe.port}");
      //向外发送 ip和端口
      mainSendPort.send(HttpServerInfo(
          completeServe.address.host, completeServe.port.toString()));
      mainSendPort.send({"commonFile": Global.localCommonFile});
      final ReceivePort httpReceivePort = ReceivePort();
      mainSendPort.send(httpReceivePort.sendPort);
      httpReceivePort.listen((message) {
        if (message is Map) {
          Global.localCommonFile = RxList.of(message['commonFile']);
        }
      });
    });

    ever(Global.homeCommonFileListRow, (data) {
      mainSendPort.send({"homeCommonFileListRow": data});
    });

    ever(Global.myIp, (data) {
      mainSendPort.send({"myIp": data});
    });

  }, mainReceivePort.sendPort);

  //监听其他线程向main线程发送消息
  mainReceivePort.listen((message) {
    //接收到服务器启动完成消息,启动广播发送http服务的ip:port
    if (message is HttpServerInfo) {
      Multicast().startSendBoardcast([(jsonEncode(message.paramMap))]);
    }
    if (message is Map && message['commonFile'] != null) {
      Global.localCommonFile = message['commonFile'];
      commonFilePageInit();
      //渲染页面
      runApp(_FileShare());
      getStoragePermission();
    }

    if (message is SendPort) {
      //监听本地共享文件
      ever(Global.localCommonFile, (mainCommonFile) {
        //通知UI线程,更新UI
        message.send({"commonFile": mainCommonFile});
        //通知局域网其他设备
        for (var v in Global.otherDevice) {
          uploadCommonFileName(v);
        }
      });
    }
    if (message is Map && message['homeCommonFileListRow'] != null) {
      Global.homeCommonFileListRow.clear();
      commonFilePageInit();
      Global.homeCommonFileListRow.addAll(message['homeCommonFileListRow']);
    }

    if (message is Map && message['myIp'] != null) {
      Global.myIp.value = message['myIp'];
    }
  });

  //添加接受局域网广播消息监听器
  Multicast().addListener((String data, String address) {
    NetworkUtil().localIpv4Address.then((localAddress) {
      var httpServiceInfo = HttpServerInfo.forMap(jsonDecode(data));
      var ipAddress = Uri.http("$address:${httpServiceInfo.port}", '/ipAddress', {"ip": "$address:${httpServiceInfo.port}"});
      http.post(ipAddress);
      if (localAddress.contains(address) || Global.otherDevice.contains("$address:${httpServiceInfo.port}")) {
        return;
      }
      Global.otherDevice.add("$address:${httpServiceInfo.port}");
    });
  });
  // requestStoragePermission();

}

Future<void> uploadCommonFileName(v) async {
  if (Global.myIp.value.isNotEmpty) {
    var uri = Uri.http(v, "/uploadCommonFileName");
    http.post(uri, body: json.encode({"commonFileNameList": json.encode(Global.localCommonFileName), "ip": Global.myIp.value}))
        .then((res) => print("result: ${res.body}"));
  }
}

class _FileShare extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appName = '文件共享';
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomePage(title: appName),
    );
  }
}

Future<void> requestStoragePermission() async {
  var permissionStatus = await Permission.storage.request();
  if (permissionStatus.isGranted) {
    // 权限被授予
  } else {
    // 权限被拒绝或永久拒绝
  }
}

/// 获取存储权限
Future<bool> getStoragePermission() async {
  late PermissionStatus myPermission;

  /// 读取系统权限
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    myPermission = await Permission.photosAddOnly.request();
  } else {
    myPermission = await Permission.storage.request();
  }
  if (myPermission != PermissionStatus.granted) {
    return false;
  } else {
    return true;
  }
}

void checkPermission() async {
  // 请求存储权限
  final permissionState = await getStoragePermission();
  if (permissionState) {
    // 权限被授予
    print("123");
  } else {
    // 权限被拒绝 打开手机上该App的权限设置页面
    openAppSettings();
  }
}