import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:get/get.dart' hide Response;
import 'package:fileShare/main.dart';
import 'package:fileShare/src/common/Global.dart';
import 'package:fileShare/src/commonFile.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;

class HttpService {

  Router get route {
    final router = Router();
    router.post('/upload/<fileName>', _uploadFile);
    router.get('/byFile', _getFileByFilePath);
    router.get('/allCommonFile', (Request request) => Response(200, body: "{commonFile: ${Global.localCommonFile.toJson()}}"));
    router.post('/uploadCommonFileName', _uploadCommonFileName);
    router.post('/ipAddress', ipAddress);
    return router;
  }

  ipAddress(Request request) {
    if (Global.myIp.value.isNotEmpty) return Response(200);

    Global.myIp.value = request.requestedUri.queryParameters['ip']!;
    if (Global.localCommonFileName.isNotEmpty) {
      uploadCommonFileName(Global.myIp);
    }
    return Response(200);
  }

  _uploadCommonFileName (Request request) {
    var ip = request.headers["Remote_Addr"];
    request.readAsString(utf8).then((body) {
      Map<String, dynamic> bodyMap = json.decode(body);
      (json.decode(bodyMap['commonFileNameList']) as List<dynamic>)
          .map((item) => json.decode(item)).toList();

      List<Map<String, dynamic>> commonFileNameList = [];
      print("接收到${json.encode(commonFileNameList)}");
      Global.homeCommonFileListRow[ip ?? bodyMap['ip']] = Flexible(
          flex: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 100),
            child: Row(children: [
              Flexible(
                flex: 9,
                child: DottedBorder(
                  child: CommonFilePage(RxList.of(commonFileNameList.map((el) {
                    return Column(
                      children: [
                        Expanded(flex: 2, child: IconButton(onPressed: () {
                          http.get(Uri.http(bodyMap['ip'], '/byFile', {"filePath": el['path']})).then((res) async {
                            var runPath = (await getDownloadsDirectory())!.path;
                            // if (defaultTargetPlatform == TargetPlatform.android) {
                            //   runPath = (await getDownloadsDirectory())!.path;
                            // } else {
                            //   runPath = Directory.current.path;
                            // }
                            var file = File("$runPath/fileShare/${el['name']}");
                            print(file.path);
                            if (!file.existsSync()) {

                              file.createSync(recursive: true);
                            }
                            file.writeAsBytesSync(res.bodyBytes);
                          });
                        }, icon: const Icon(Icons.image_aspect_ratio))),
                        Flexible(
                            flex: 1,
                            child: Text(
                              el['name']!,
                              overflow: TextOverflow.ellipsis,
                            )),
                      ],
                    );
                  }))),
                ),
              ),
            ]),
          ));
    });
    return Response(200);
  }

  _uploadFile(Request request, String fileName) async {
    if (request.headers['content-type'] != 'application/octet-stream') {
      throw new Exception("我需要文件");
    }
    final filePath = Global.filePath.replaceAll("{ip}", request.headers['x-forwarded-for'] ?? "ip").replaceAll("{fileName}", fileName);
    final file = File(filePath);
    if (!file.existsSync()) {
      await file.create(recursive: true);
    }
    await request.read().expand((data) => data).toList().then((dateList) => file.writeAsBytes(dateList, flush: true));
    return Response.ok('yes');
  }

  _getFileByFilePath(Request request) {
    var file = File(request.url.queryParameters['filePath'] as String);
    if (!file.existsSync()) {
      throw Exception("文件不存在");
    }
    return Response(200,
        headers: {
          'Content-Type': 'application/octet-stream',
        },
        body: file.readAsBytesSync());
  }
}

class HttpServerInfo {

  const HttpServerInfo(this.ip, this.port);

  final String ip, port;

  factory HttpServerInfo.forMap(Map<String, dynamic> map) {
    return HttpServerInfo(map['ip']!, map['port']!);
  }

  Map<String, String> get paramMap {
    return {
      'ip': ip,
      'port': port
    };
  }

}