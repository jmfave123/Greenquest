import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/services/file_download_service.dart';
import '../../../shared/utils/file_type_utils.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';
import '../../widgets/layout/web_sidebar.dart';

class WebMaterialsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> material;

  const WebMaterialsDetailScreen({super.key, required this.material});

  @override
  Widget build(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: WebAppBar(
        title: 'Material Details',
        onMenuPressed:
            isDesktop ? null : () => scaffoldKey.currentState?.openDrawer(),
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
              _buildBackButton(),
              const SizedBox(height: 24),
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

  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: () => Get.back(),
      icon: const Icon(Icons.arrow_back, size: 18),
      label: const Text('Back to Materials'),
      style: TextButton.styleFrom(
        foregroundColor: WebTheme.textSecondary,
        padding: EdgeInsets.zero,
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
            ...attachments.map((file) => _buildFileItem(context, file)),
        ],
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, dynamic file) {
    final fileName = file is Map ? (file['name'] ?? 'File') : 'File';
    final fileUrl = file is Map ? (file['url'] ?? '') : '';
    final fileType = file is Map ? (file['type'] ?? 'unknown') : 'unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WebTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebTheme.borderLight),
      ),
      child: Row(
        children: [
          _getFileIcon(fileType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fileType.toUpperCase(),
                  style: const TextStyle(
                    color: WebTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed:
                () => _handleFileDownload(context, fileUrl, fileName, fileType),
            icon: const Icon(
              Icons.file_download_outlined,
              color: WebTheme.primaryGreen,
            ),
            tooltip: 'Download',
          ),
        ],
      ),
    );
  }

  Widget _getFileIcon(String type) {
    IconData icon;
    Color color;

    final lowerType = type.toLowerCase();
    if (lowerType.contains('pdf')) {
      icon = Icons.picture_as_pdf;
      color = Colors.red.shade400;
    } else if (lowerType.contains('doc') || lowerType.contains('text')) {
      icon = Icons.description;
      color = Colors.blue.shade400;
    } else if (FileTypeUtils.isImageFile(lowerType)) {
      icon = Icons.image;
      color = Colors.purple.shade400;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _handleFileDownload(
    BuildContext context,
    String url,
    String name,
    String type,
  ) {
    if (url.isEmpty) {
      Get.snackbar(
        'Error',
        'Invalid file URL',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    FileDownloadService.handleFileAction(
      fileUrl: url,
      fileName: name,
      fileType: type,
      context: context,
    );
  }
}
