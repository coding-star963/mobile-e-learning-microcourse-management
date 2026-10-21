import 'package:flutter/material.dart';

import '../../core/media_url.dart';
import '../../core/theme.dart';
import '../../models/learning_resource.dart';
import 'lesson_media_player.dart';

class LearningResourceCard extends StatelessWidget {
  const LearningResourceCard({
    super.key,
    required this.resource,
    required this.onOpen,
  });

  final LearningResource resource;
  final VoidCallback onOpen;

  Widget _image({bool expanded = false}) => Image.network(
    resource.fileUrl!,
    headers: MediaUrl.headersFor(resource.fileUrl!),
    fit: expanded ? BoxFit.contain : BoxFit.cover,
    height: expanded ? null : 200,
    width: double.infinity,
    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
    loadingBuilder: (context, child, progress) => progress == null
        ? child
        : const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
    errorBuilder: (context, error, stack) => SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'Could not load this image. Check your connection.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted),
        ),
      ),
    ),
  );

  void _viewImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(resource.name)),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: _image(expanded: true),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = resource.fileUrl?.isNotEmpty ?? false;
    final icon = resource.isImage
        ? Icons.image_outlined
        : resource.isVideo
        ? Icons.movie_outlined
        : resource.isAudio
        ? Icons.audiotrack
        : resource.fileType.contains('pdf')
        ? Icons.picture_as_pdf
        : Icons.insert_drive_file_outlined;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.goldPrimary, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.name,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${resource.fileType.toUpperCase()} • ${resource.formattedSize}',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (resource.isImage && hasUrl)
                  IconButton(
                    icon: const Icon(
                      Icons.fullscreen,
                      color: AppTheme.goldPrimary,
                    ),
                    tooltip: 'View image',
                    onPressed: () => _viewImage(context),
                  ),
                if (!resource.isImage && !resource.isVideo && !resource.isAudio)
                  IconButton(
                    icon: const Icon(
                      Icons.download_rounded,
                      color: AppTheme.goldPrimary,
                    ),
                    tooltip: 'Open or download resource',
                    onPressed: hasUrl ? onOpen : null,
                  ),
              ],
            ),
          ),
          if (hasUrl && resource.isImage)
            Semantics(
              button: true,
              label: 'View image ${resource.name}',
              child: InkWell(onTap: () => _viewImage(context), child: _image()),
            ),
          if (hasUrl && (resource.isVideo || resource.isAudio))
            LessonMediaPlayer(
              key: ValueKey(resource.fileUrl),
              url: resource.fileUrl!,
              isAudio: resource.isAudio && !resource.isVideo,
            ),
          if (!hasUrl)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('This file is unavailable.'),
            ),
        ],
      ),
    );
  }
}
