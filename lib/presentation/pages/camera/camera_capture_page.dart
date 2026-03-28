import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../data/models/job/local_photo.dart';

@RoutePage()
class CameraCapturePage extends StatelessWidget {
  const CameraCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CameraAwesomeBuilder.awesome(
        saveConfig: SaveConfig.photo(
          pathBuilder: (sensors) async {
            final extDir = await getTemporaryDirectory();
            final testDir = await Directory('${extDir.path}/camerawesome').create(recursive: true);
            final String filePath = '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
            return SingleCaptureRequest(filePath, sensors.first);
          },
        ),
        onMediaCaptureEvent: (event) {
          if (event.status == MediaCaptureStatus.success) {
            event.captureRequest.when(
              single: (single) {
                if (single.file != null) {
                  final photo = LocalPhoto(
                    file: File(single.file!.path),
                    capturedAt: DateTime.now(),
                  );
                  // Pop the route and return the captured photo
                  context.router.pop(photo);
                }
              },
              multiple: (multiple) {},
            );
          }
        },
      ),
    );
  }
}
