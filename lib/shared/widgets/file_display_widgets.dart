import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../utils/file_type_utils.dart';

/// Widget for displaying images in chat
class ImageDisplayWidget extends StatelessWidget {
  final String imageUrl;
  final double? maxWidth;
  final double? maxHeight;
  final VoidCallback? onTap;

  const ImageDisplayWidget({
    super.key,
    required this.imageUrl,
    this.maxWidth,
    this.maxHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 250,
          maxHeight: maxHeight ?? 300,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
            errorWidget:
                (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 48,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

/// Widget for displaying videos in chat
class VideoDisplayWidget extends StatefulWidget {
  final String videoUrl;
  final double? maxWidth;
  final double? maxHeight;
  final VoidCallback? onTap;

  const VideoDisplayWidget({
    super.key,
    required this.videoUrl,
    this.maxWidth,
    this.maxHeight,
    this.onTap,
  });

  @override
  State<VideoDisplayWidget> createState() => _VideoDisplayWidgetState();
}

class _VideoDisplayWidgetState extends State<VideoDisplayWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller != null) {
      if (_isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? _togglePlayPause,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth ?? 250,
          maxHeight: widget.maxHeight ?? 200,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              _isInitialized
                  ? Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                      if (!_isPlaying)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                    ],
                  )
                  : Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
        ),
      ),
    );
  }
}

/// Widget for displaying file attachments that need to be downloaded
class FileAttachmentWidget extends StatelessWidget {
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const FileAttachmentWidget({
    super.key,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    this.onTap,
    this.backgroundColor,
    this.textColor,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final icon = FileTypeUtils.getFileIcon(fileType);
    final color = FileTypeUtils.getFileColor(fileType);

    // Get screen width and set max width to 75% of screen or 250, whichever is smaller
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = (screenWidth * 0.75).clamp(150.0, 250.0);

    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth, // Limit maximum width to prevent overflow
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor ?? Color(color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(color).withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        color: textColor ?? Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFileSize(fileSize),
                      style: TextStyle(
                        color: textColor?.withOpacity(0.7) ?? Colors.black54,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.download,
                color: textColor?.withOpacity(0.7) ?? Colors.black54,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
