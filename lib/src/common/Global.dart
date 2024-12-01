import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

abstract class Global {

  static RxList localCommonFile = [].obs;
  static List<Map<String, String>> localCommonFileName = [];

  static const iWantGetYourFileByAbsolutePath = "iWantGetYourFileByAbsolutePath/{fileAbsolutePath}";

  static const giveFile = "giveFile";

  static final filePath = "${Directory.current.path}/commFile/{ip}/{fileName}";

  static RxMap<String, Widget> homeCommonFileListRow = RxMap<String, Widget>();

  static final otherDevice = [];

  static RxString myIp = RxString('');

}