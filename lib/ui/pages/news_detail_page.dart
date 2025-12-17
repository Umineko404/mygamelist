import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../managers/theme_manager.dart';
import '../../models/news_article.dart';

class NewsDetailPage extends StatefulWidget {
  final NewsArticle article;

  const NewsDetailPage({super.key, required this.article});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  Future<void> _launchUrl() async {
    if (widget.article.link.isNotEmpty) {
      final uri = Uri.parse(widget.article.link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Widget _buildFallbackImage(BuildContext context) {
    IconData icon;
    Color color;

    switch (widget.article.source) {
      case 'PlayStation':
        icon = Icons.gamepad;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.article;
        color = Colors.grey;
    }

    return Container(
      color: color.withAlpha(30),
      child: Center(child: Icon(icon, color: color.withAlpha(150), size: 64)),
    );
  }

  void _showFullscreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 5.0,
            panEnabled: true,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 80, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 40,
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Consumer<ThemeManager>(
                  builder: (context, themeManager, _) {
                    final isDark = themeManager.themeMode == ThemeMode.dark;
                    return IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        themeManager.setThemeMode(
                          isDark ? ThemeMode.light : ThemeMode.dark,
                        );
                      },
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        size: 24,
                      ),
                      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // News Image
            if (widget.article.imageUrl != null && widget.article.imageUrl!.isNotEmpty)
              GestureDetector(
                onTap: () => _showFullscreenImage(context, widget.article.imageUrl!),
                child: Image.network(
                  widget.article.imageUrl!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => SizedBox(
                    height: 250,
                    child: _buildFallbackImage(context),
                  ),
                ),
              )
            else
              SizedBox(
                height: 250,
                child: _buildFallbackImage(context),
              ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Source Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.article.source == 'PlayStation'
                            ? Colors.indigo[600]
                            : Colors.grey[700],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.article.source,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.article.formattedDate,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  widget.article.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Content (HTML)
                HtmlWidget(
                  widget.article.htmlContent ??
                      widget.article.content ??
                      widget.article.summary ??
                      'No content available.',
                  textStyle: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.6),
                  onTapUrl: (url) async {
                    // Check if URL is an image
                    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
                    final isImage = imageExtensions.any((ext) => url.toLowerCase().endsWith(ext));
                    
                    if (isImage) {
                      // Show image in fullscreen zoom
                      _showFullscreenImage(context, url);
                      return true;
                    }
                    
                    // For non-image URLs, open in browser
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                    return true;
                  },
                ),
                const SizedBox(height: 40),

                // Read Full Article Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _launchUrl,
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Read Full Article on Blog'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
