import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../models/resource.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_format.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.resource});

  final Resource resource;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    final Resource resource = widget.resource;
    if (resource.isLink) {
      final Uri? uri = Uri.tryParse(resource.url);
      if (uri == null) {
        setState(() => _error = 'Invalid link.');
        return;
      }
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) setState(() => _error = 'Could not open the link.');
      return;
    }
    if (resource.isImage) return;
    final File file = File(resource.localPath);
    if (resource.localPath.isEmpty || !await file.exists()) {
      if (mounted) setState(() => _error = 'File is missing on this device.');
      return;
    }
    final VideoPlayerController controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() => _controller = controller);
    } catch (error) {
      await controller.dispose();
      if (mounted) {
        setState(() => _error = 'Could not play this file. $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Resource resource = widget.resource;
    final VideoPlayerController? controller = _controller;
    return Scaffold(
      backgroundColor: resource.isImage
          ? AppColors.textPrimary
          : AppColors.textPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          resource.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(child: _body(resource, controller)),
    );
  }

  Widget _body(Resource resource, VideoPlayerController? controller) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, color: Colors.white, size: 36),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    if (resource.isImage) {
      final File file = File(resource.localPath);
      if (!file.existsSync()) {
        return const Center(
          child: Text(
            'Image is missing on this device.',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        );
      }
      return InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
                const Text(
                  'Could not open this image.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
          ),
        ),
      );
    }
    if (resource.isLink) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.open_in_new, color: Colors.white, size: 40),
              const SizedBox(height: 14),
              const Text(
                'Opened in your browser or YouTube app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Back to materials'),
              ),
            ],
          ),
        ),
      );
    }
    if (controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    final bool isAudio = resource.isAudio;
    return Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: isAudio
                ? _audioArt(resource)
                : AspectRatio(
                    aspectRatio: controller.value.aspectRatio <= 0
                        ? 16 / 9
                        : controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            children: <Widget>[
              VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.secondary,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () {
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                    },
                    icon: Icon(
                      controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${AppFormat.clock(controller.value.position.inSeconds)} / ${AppFormat.clock(controller.value.duration.inSeconds)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _audioArt(Resource resource) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(32),
          ),
          child: const Icon(
            Icons.graphic_eq,
            size: 64,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          resource.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          resource.subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12.5),
        ),
      ],
    );
  }
}
