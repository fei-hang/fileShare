import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'common/Global.dart';
import 'commonFile.dart';

void commonFilePageInit() {
  Widget commonFilePage = Flexible(
      flex: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 100),
        child: Row(children: [
          //选择文件按钮
          Flexible(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                _FileFunc().openFile();
              },
              child: const Text('选择'),
            ),
          ),

          Flexible(
            flex: 9,
            child: DottedBorder(
              child: CommonFilePage(Global.localCommonFile),
            ),
          ),
        ]),
      ));

  Global.homeCommonFileListRow["local"] = commonFilePage;
}

class _FileFunc {
  Future<void> openFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      Global.localCommonFileName.add({"path": result.files.single.path!, "name": result.files.single.name});
      Global.localCommonFile.add(Column(
        children: [
          const Expanded(flex: 2, child: Icon(Icons.image_aspect_ratio)),
          Flexible(
              flex: 1,
              child: Text(
                result.files.single.name,
                overflow: TextOverflow.ellipsis,
              )),
        ],
      ));
    } else {
      print("ERROR: not get File");
    }
  }
}