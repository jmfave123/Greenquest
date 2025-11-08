import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// A widget that displays text with clickable links.
/// Automatically detects URLs in the text and makes them clickable.
class LinkableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? linkColor;
  final TextDecoration? linkDecoration;

  const LinkableText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.linkColor,
    this.linkDecoration,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Detect URLs in the text - improved pattern for better detection
    // This pattern detects:
    // - Full URLs (http://, https://)
    // - URLs without protocol (www.example.com, google.com)
    // - Google Forms (forms.gle, docs.google.com/forms)
    // - Short URLs and other common patterns
    final urlPattern = RegExp(
      r'(?:(?:https?|ftp):\/\/)?' // Optional protocol (http://, https://, ftp://)
      r'(?:www\.)?' // Optional www
      r'(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+' // Domain with subdomains
      r'[a-zA-Z]{2,}' // TLD (at least 2 letters)
      r'(?::[0-9]{1,5})?' // Optional port
      r'(?:\/[^\s<>"{}|\\^`\[\]]*)?' // Optional path (exclude problematic chars)
      r'|' // OR
      r'forms\.gle\/[a-zA-Z0-9_-]+' // Google Forms short links
      r'|' // OR
      r'docs\.google\.com\/forms\/[a-zA-Z0-9\/_-]+', // Google Forms full URLs
      caseSensitive: false,
    );

    final matches = urlPattern.allMatches(text);

    // If no URLs found, return regular text
    if (matches.isEmpty) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Build TextSpan with clickable links
    final textSpans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      // Add text before the URL
      if (match.start > lastIndex) {
        textSpans.add(
          TextSpan(text: text.substring(lastIndex, match.start), style: style),
        );
      }

      // Extract the matched URL
      String url = match.group(0)!;

      // Ensure URL has a protocol
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      // Add clickable URL
      textSpans.add(
        TextSpan(
          text: match.group(0),
          style: (style ?? const TextStyle()).copyWith(
            color: linkColor ?? Colors.blue,
            decoration: linkDecoration ?? TextDecoration.underline,
          ),
          recognizer:
              TapGestureRecognizer()
                ..onTap = () async {
                  await _launchURL(url, context);
                },
        ),
      );

      lastIndex = match.end;
    }

    // Add remaining text after the last URL
    if (lastIndex < text.length) {
      textSpans.add(TextSpan(text: text.substring(lastIndex), style: style));
    }

    return Text.rich(
      TextSpan(children: textSpans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Launches the URL in an external browser
  Future<void> _launchURL(String url, BuildContext context) async {
    // Clean and validate URL (declare outside try for use in catch block)
    String cleanUrl = url.trim();

    try {
      // Remove any trailing punctuation that might have been included
      cleanUrl = cleanUrl.replaceAll(RegExp(r'[.,;:!?]+$'), '');

      // Ensure URL has a protocol
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final uri = Uri.parse(cleanUrl);

      // Try launching directly - sometimes canLaunchUrl returns false
      // even when the URL can be opened, so we try multiple modes

      // Try external application first (opens in default browser)
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return; // Success!
      } catch (e) {
        print('External application mode failed: $e');
      }

      // Try platform default
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        return; // Success!
      } catch (e) {
        print('Platform default mode failed: $e');
      }

      // Try in-app web view as fallback
      try {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
        return; // Success!
      } catch (e) {
        print('In-app web view mode failed: $e');
      }

      // If all modes fail, check with canLaunchUrl for better error message
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        throw Exception('URL cannot be launched: $cleanUrl');
      }

      // If we get here, something unexpected happened
      throw Exception('All launch modes failed for URL: $cleanUrl');
    } catch (e) {
      // Show error message
      if (context.mounted) {
        // Use the cleaned URL for display and copying
        final displayUrl =
            cleanUrl.length > 50 ? cleanUrl.substring(0, 50) + "..." : cleanUrl;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot open link. Please check the URL: $displayUrl',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Copy URL',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  await Clipboard.setData(ClipboardData(text: cleanUrl));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL copied to clipboard'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (copyError) {
                  print('Failed to copy URL: $copyError');
                }
              },
            ),
          ),
        );
      }
      print('Error opening link: $e');
    }
  }
}
