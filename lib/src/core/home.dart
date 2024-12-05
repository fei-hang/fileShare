//主页
import 'package:file_share/src/common/Global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class HomePage extends StatefulWidget {

  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      //顶部
      appBar: AppBar(title: Text(widget.title),),
      //中间
      body: Obx(() => Column(
        children: Global.homeCommonFileListRow.values.toList(),
      )),
    );
  }
}