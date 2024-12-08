import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_share/src/common/Global.dart';

class CommonFilePage extends StatefulWidget {

  const CommonFilePage(this.rxList, {super.key});

  final RxList rxList;

  @override
  State<CommonFilePage> createState() => _CommonFilePageState();
}

class _CommonFilePageState extends State<CommonFilePage> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView.builder(
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      itemCount: widget.rxList.length,
      itemBuilder: (context, index) => widget.rxList[index],
      scrollDirection: Axis.horizontal,));
  }
}