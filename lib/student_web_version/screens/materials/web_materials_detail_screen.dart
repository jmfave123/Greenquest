import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';
import '../../widgets/layout/web_sidebar.dart';
import '../../widgets/submissions/web_attachment_item_widget.dart';

class WebMaterialsDetailScreen extends StatefulWidget {
  final Map<String, dynamic> material;

  const WebMaterialsDetailScreen({super.key, required this.material});

  @override
  State<WebMaterialsDetailScreen> createState() =>
      _WebMaterialsDetailScreenState();
}

class _WebMaterialsDetailScreenState extends State<WebMaterialsDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Expose material from widget for the helper methods below
  Map<String, dynamic> get material => widget.material;

  @override
  Widget build(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: WebAppBar(
        title: 'Material Details',
        onMenuPressed:
            isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer:
          !isDesktop
              ? Drawer(child: WebSidebar(currentRoute: WebRoutes.materials))
              : null,
      body: Row(
        children: [
          if (isDesktop) const WebSidebar(currentRoute: WebRoutes.materials),
          Expanded(
            child: Container(
              color: WebTheme.backgroundLight,
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: SingleChildScrollView(
          padding: WebResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Back button
              TextButton.icon(
                onPressed: () => Get.toNamed(WebRoutes.materials),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text('Back to Materials'),
                style: TextButton.styleFrom(
                  foregroundColor: WebTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildMainInfo()),
                    const SizedBox(width: 32),
                    Expanded(flex: 1, child: _buildResourcePanel(context)),
                  ],
                )
              else
                Column(
                  children: [
                    _buildMainInfo(),
                    const SizedBox(height: 24),
                    _buildResourcePanel(context),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfo() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 48),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: WebTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            material['description'] ?? 'No description provided.',
            style: WebTheme.bodyLarge.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: WebTheme.hoverGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (material['type'] ?? 'Material').toUpperCase(),
                style: const TextStyle(
                  color: WebTheme.primaryGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Spacer(),
            if (material['period'] != null &&
                material['period'].toString().isNotEmpty)
              _buildPeriodBadge(material['period'].toString()),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          material['title'] ?? 'Untitled Material',
          style: WebTheme.headingMedium.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildInfoChip(
              Icons.person_outline,
              material['instructorName'] ?? 'Instructor',
            ),
            const SizedBox(width: 20),
            _buildInfoChip(
              Icons.calendar_today_outlined,
              material['createdAt'] ?? 'Date',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: WebTheme.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: WebTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildPeriodBadge(String period) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Text(
        period,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildResourcePanel(BuildContext context) {
    final List<dynamic> attachments = material['attachments'] ?? [];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resources',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (attachments.isEmpty)
            const Text(
              'No attachments available for this material.',
              style: TextStyle(color: WebTheme.textSecondary, fontSize: 14),
            )
          else
            ...attachments.map((file) {
              // Firestore returns Map<Object?, Object?> — use toString() for safe access.
              // Materials store full {name, url, type} Maps; old data may be URL strings.
              String fileName;
              String fileUrl;
              String fileType;

              if (file is Map) {
                fileName = file['name']?.toString() ?? '';
                fileUrl = file['url']?.toString() ?? '';
                fileType = file['type']?.toString() ?? 'unknown';
                // Fallback for Maps where name was not stored
                if (fileName.isEmpty) {
                  final seg =
                      Uri.tryParse(fileUrl)?.pathSegments.lastOrNull ?? '';
                  fileName =
                      Uri.decodeComponent(seg).isNotEmpty
                          ? Uri.decodeComponent(seg)
                          : 'Attachment';
                }
              } else {
                // Old format: plain URL string — extract what we can
                fileUrl = file.toString();
                final uri = Uri.tryParse(fileUrl);
                final seg = uri?.pathSegments.lastOrNull ?? '';
                final decoded = Uri.decodeComponent(seg);
                final dotIdx = decoded.lastIndexOf('.');
                fileType =
                    dotIdx != -1 ? decoded.substring(dotIdx + 1) : 'file';
                fileName = decoded.isNotEmpty ? decoded : 'Attachment';
              }

              return WebAttachmentItemWidget(
                fileName: fileName,
                fileUrl: fileUrl,
                fileType: fileType,
              );
            }),
        ],
      ),
    );
  }
}
