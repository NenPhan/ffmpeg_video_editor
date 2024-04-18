import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class VideoFFmpegEditor {
  static Future<File> overlayImages(
      {required File video, required List<OverlayItem> overlay}) async {
    File output = video;
    for (var overlayImage in overlay) {
      if (overlayImage.file.path.split(".").last == "mp4") {
        output = await _overlayVideo(video: output, overlayVideo: overlayImage);
      } else {
        output = await _overlayImage(video: output, overlayImage: overlayImage);
      }
    }
    return output;
  }

  static Future<File> _overlayImage(
      {required File video, required OverlayItem overlayImage}) async {
    String videoPath = video.path;
    String overlayImagePath = overlayImage.file.path;
    String outputPath =
        "${(await getApplicationCacheDirectory()).path}/output${UniqueKey().hashCode}.mp4";
    String overlayCmd =
        "-i $videoPath -i $overlayImagePath -filter_complex \"[0:v][1:v] overlay=${overlayImage.offset.dx.toInt()}:${overlayImage.offset.dy.toInt()}:enable='between(t,${overlayImage.time.dx.toInt()},${overlayImage.time.dy.toInt()})'\" -pix_fmt yuv420p $outputPath";
    log(overlayCmd);

    await FFmpegKit.execute(overlayCmd).then((session) async {
      final returnCode = await session.getReturnCode();
      if (returnCode?.isValueSuccess() ?? false) {
        log("overlaySession success");
      } else {
        log("overlaySession not success");
      }
    });

    return File(outputPath);
  }

  static Future<File> _overlayVideo(
      {required File video, required OverlayItem overlayVideo}) async {
    File scaledVideo = await _scaleVideo(overlayVideo.file);
    String videoPath = video.path;
    String overlayVideoPath = scaledVideo.path;
    String outputPath =
        "${(await getApplicationCacheDirectory()).path}/output${UniqueKey().hashCode}.mp4";
    String overlayCmd =
        "-i $videoPath -i $overlayVideoPath -filter_complex \"[0:v][1:v] overlay=${overlayVideo.offset.dx.toInt()}:${overlayVideo.offset.dy.toInt()}:enable='between(t,${overlayVideo.time.dx.toInt()},${overlayVideo.time.dy.toInt()})'\" -pix_fmt yuv420p $outputPath";
    log(overlayCmd);

    await FFmpegKit.execute(overlayCmd).then((session) async {
      final returnCode = await session.getReturnCode();
      if (returnCode?.isValueSuccess() ?? false) {
        log("overlaySession success");
      } else {
        log("overlaySession not success");
      }
    });

    return File(outputPath);
  }

  static Future<File> _scaleVideo(File video, {Offset? size}) async {
    size ??= const Offset(400, 400);
    String videoPath = video.path;
    String outputPath =
        "${(await getApplicationCacheDirectory()).path}/output${UniqueKey().hashCode}.mp4";
    String overlayCmd =
        "-i $videoPath -s ${size.dx.toInt()}x${size.dy.toInt()} -c:a copy $outputPath";
    log(overlayCmd);

    await FFmpegKit.execute(overlayCmd).then((session) async {
      final returnCode = await session.getReturnCode();
      if (returnCode?.isValueSuccess() ?? false) {
        log("overlaySession success");
      } else {
        log("overlaySession not success");
      }
    });

    return File(outputPath);
  }
}

class OverlayItem {
  final File file;
  Offset time;
  Offset offset;
  Uint8List? thumbnail;

  OverlayItem(
      {required this.file,
      required this.time,
      required this.offset,
      this.thumbnail});
}
