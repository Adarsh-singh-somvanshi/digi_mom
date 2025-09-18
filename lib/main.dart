import 'package:flutter/material.dart';
import 'task_list_screen.dart';
import 'task_form_screen.dart';
import 'notification_service.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Reminder App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: const VideoWallpaperTaskList(),
      routes: {
        TaskFormScreen.routeName: (_) => TaskFormScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class VideoWallpaperTaskList extends StatefulWidget {
  const VideoWallpaperTaskList({super.key});

  @override
  State<VideoWallpaperTaskList> createState() => _VideoWallpaperTaskListState();
}

class _VideoWallpaperTaskListState extends State<VideoWallpaperTaskList> {
  late final VideoPlayerController _videoPlayerController;
  late final ChewieController _chewieController;

  @override
  void initState() {
    super.initState();

    _videoPlayerController = VideoPlayerController.asset('assets/videos/background.mp4');
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      looping: true,
      autoPlay: true,
      showControls: false,
      allowFullScreen: false,
      allowMuting: false,
    );
  }

  @override
  void dispose() {
    _chewieController.dispose();
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Chewie(controller: _chewieController)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.3))),
          Positioned.fill(child: TaskListScreen()),
        ],
      ),
    );
  }
}
