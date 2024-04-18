// ignore_for_file: empty_catches

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_editor_ffmpeg/video_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? video;
  Uint8List? videoThumb;
  VideoPlayerController? videoPlayerController;
  List<OverlayItem> overlays = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Video Editor.",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (videoThumb != null)
                    Row(
                      children: [
                        Image.memory(videoThumb!),
                        IconButton(
                            onPressed: () {
                              video = null;
                              videoThumb = null;
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.close,
                              size: 30,
                              weight: 20,
                              color: Colors.red,
                            ))
                      ],
                    ),
                  if (videoThumb == null)
                    TextButton(
                        onPressed: () async {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles();
                          if (result != null &&
                              result.files.single.path != null) {
                            video = File(result.files.single.path!);
                            videoThumb = await VideoThumbnail.thumbnailData(
                              video: video!.path,
                              imageFormat: ImageFormat.JPEG,
                              maxWidth: 128,
                              quality: 70,
                            );
                            setState(() {});
                          }
                        },
                        child: const Text(
                          "Pick a video",
                        )),
                  const SizedBox(
                    height: 20,
                  ),

                  ///////////////////////////////////Overlays
                  Row(
                    children: [
                      const Text(
                        "Overlays",
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                          onPressed: () async {
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles();
                            if (result != null) {
                              Uint8List? thumb;
                              if (result.files.single.path!.split(".").last ==
                                  "mp4") {
                                thumb = await VideoThumbnail.thumbnailData(
                                  video: result.files.single.path!,
                                  imageFormat: ImageFormat.JPEG,
                                  maxWidth: 128,
                                  quality: 70,
                                );
                              }
                              overlays.add(OverlayItem(
                                file: File(result.files.single.path!),
                                offset: const Offset(128, 10),
                                time: const Offset(0, 30),
                                thumbnail: thumb,
                              ));
                              setState(() {});
                            }
                          },
                          icon: const Icon(
                            Icons.add,
                            size: 30,
                            weight: 20,
                            color: Colors.black,
                          ))
                    ],
                  ),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: overlays.length,
                      itemBuilder: (context, index) {
                        var overlay = overlays[index];
                        return Container(
                          color: Colors.grey.withOpacity(.1),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(
                                          overlay.file.path.split("/").last)),
                                  SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: overlay.file.path.split(".").last ==
                                            "mp4"
                                        ? Image.memory(overlay.thumbnail!)
                                        : Image.file(overlay.file),
                                  ),
                                  IconButton(
                                      onPressed: () {
                                        overlays.removeAt(index);
                                        setState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.close,
                                        size: 30,
                                        weight: 20,
                                        color: Colors.red,
                                      ))
                                ],
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue:
                                          "${overlay.offset.dx.toInt().toString().padLeft(2, "0")}:${overlay.offset.dy.toInt().toString().padLeft(2, "0")}",
                                      onChanged: (value) {
                                        try {
                                          overlay.offset = Offset(
                                              double.parse(
                                                  value.split(":").first),
                                              double.parse(
                                                  value.split(":").last));
                                          setState(() {});
                                        } catch (e) {}
                                      },
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue:
                                          "${overlay.time.dx.toInt().toString().padLeft(2, "0")}:${overlay.time.dy.toInt().toString().padLeft(2, "0")}",
                                      onChanged: (value) {
                                        try {
                                          overlay.time = Offset(
                                              double.parse(
                                                  value.split(":").first),
                                              double.parse(
                                                  value.split(":").last));
                                          setState(() {});
                                        } catch (e) {}
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  /////////////////////////////////////Make overlay
                  const SizedBox(
                    height: 10,
                  ),
                  if (isLoading) const CircularProgressIndicator(),
                  if (video != null &&
                      overlays.isNotEmpty &&
                      !isLoading &&
                      videoPlayerController == null)
                    TextButton(
                        onPressed: () async {
                          isLoading = true;
                          setState(() {});
                          var output = await VideoFFmpegEditor.overlayImages(
                              video: video!, overlay: overlays);
                          _playVideo(output);

                          isLoading = false;
                          setState(() {});
                        },
                        child: const Text("Make overlay")),
                  if (videoPlayerController != null)
                    TextButton(
                        onPressed: () async {
                          videoPlayerController!.dispose();
                          videoPlayerController = null;
                          setState(() {});
                        },
                        child: const Text("Clear")),
                  if (videoPlayerController != null)
                    AspectRatio(
                      aspectRatio: 1.6,
                      child: VideoPlayer(videoPlayerController!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _playVideo(File file) {
    videoPlayerController = VideoPlayerController.file(file)
      ..initialize().then((value) {
        setState(() {});
        videoPlayerController!.play();
      });
  }
}
