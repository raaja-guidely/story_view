import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../utils.dart';
import '../controller/story_controller.dart';

class VideoLoader {
  String url;
  String? videoId;
  Map<String, dynamic>? requestHeaders;

  LoadState state = LoadState.loading;

  VideoLoader(this.url, {this.requestHeaders});

  void loadVideo(VoidCallback onComplete) {
    if (this.videoId != null) {
      this.state = LoadState.success;
      onComplete();
    }
    final fileStream = YoutubePlayer.convertUrlToId(url)!;

    this.state = LoadState.success;
    this.videoId = fileStream;
    onComplete();
  }
}

class StoryVideoYoutube extends StatefulWidget {
  final StoryController? storyController;
  final VideoLoader videoLoader;

  StoryVideoYoutube(this.videoLoader, {this.storyController, Key? key})
      : super(key: key ?? UniqueKey());

  static StoryVideoYoutube url(String url,
      {StoryController? controller,
      Map<String, dynamic>? requestHeaders,
      Key? key}) {
    return StoryVideoYoutube(
      VideoLoader(url, requestHeaders: requestHeaders),
      storyController: controller,
      key: key,
    );
  }

  @override
  State<StatefulWidget> createState() {
    return StoryVideoYoutubeState();
  }
}

class StoryVideoYoutubeState extends State<StoryVideoYoutube> {
  Future<void>? playerLoader;

  StreamSubscription? _streamSubscription;

  late YoutubePlayerController playerController;

  @override
  void initState() {
    super.initState();
    widget.storyController!.pause();
    widget.videoLoader.loadVideo(() {
      if (widget.videoLoader.state == LoadState.success) {
        this.playerController =
            YoutubePlayerController(initialVideoId: widget.videoLoader.videoId!)
              ..addListener(() {
                setState(() {});
                this.playerController.play();
                widget.storyController!.play();
              });
        print(playerController.value.isPlaying);
        if (widget.storyController != null) {
          _streamSubscription =
              widget.storyController!.playbackNotifier.listen((playbackState) {
            if (playbackState == PlaybackState.pause) {
              playerController.pause();
            } else {
              playerController.play();
            }
          });
        }
      } else {
        setState(() {});
      }
    });
  }

  @override
  void deactivate() {
    playerController.pause();
    super.deactivate();
  }

  Widget getContentView() {
    if (widget.videoLoader.state == LoadState.success &&
        playerController.value.isPlaying) {
      return Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(controller: playerController),
        ),
      );
    }

    return widget.videoLoader.state == LoadState.loading
        ? Center(
            child: Container(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          )
        : Center(
            child: Text(
            "Media failed to load.",
            style: TextStyle(
              color: Colors.white,
            ),
          ));
  }

  @override
  Widget build(BuildContext context) {
    log((widget.videoLoader.state == LoadState.success).toString());
    return Container(
      color: Colors.black,
      height: double.infinity,
      width: double.infinity,
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(controller: playerController),
        ),
      ),
    );
  }

  @override
  void dispose() {
    playerController.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }
}
