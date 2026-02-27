import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../user/plant_trees/tree_planting_controller.dart';
import '../../../shared/controllers/file_submission_controller.dart';
import '../../config/web_theme.dart';
import '../../config/web_routes.dart';
import '../../utils/web_responsive_utils.dart';
import '../../widgets/layout/web_app_bar.dart';
import '../../widgets/layout/web_sidebar.dart';
import '../../widgets/submissions/web_file_upload_widget.dart';

/// Web Plant Trees screen — mirrors the mobile [PlantTreesScreen] feature
/// but uses the standard web layout ([WebAppBar], [WebSidebar]),
/// [WebTheme] colour tokens, and [WebFileUploadWidget] for photo evidence.
class WebPlantTreesScreen extends StatefulWidget {
  const WebPlantTreesScreen({super.key});

  @override
  State<WebPlantTreesScreen> createState() => _WebPlantTreesScreenState();
}

class _WebPlantTreesScreenState extends State<WebPlantTreesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final TreePlantingController _treeController;
  late final FileSubmissionController _fileController;

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final List<TextEditingController> _treeNameControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );

  DateTime _selectedDate = DateTime.now();

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    try {
      _treeController = Get.find<TreePlantingController>();
    } catch (_) {
      _treeController = Get.put(TreePlantingController());
    }
    // Use a dedicated tag so this screen's file state is isolated from other
    // screens that also use FileSubmissionController without a tag.
    try {
      _fileController = Get.find<FileSubmissionController>(
        tag: 'plant_trees_web',
      );
    } catch (_) {
      _fileController = Get.put(
        FileSubmissionController(),
        tag: 'plant_trees_web',
      );
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _locationController.dispose();
    for (final c in _treeNameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // User interactions
  // -------------------------------------------------------------------------

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: WebTheme.primaryGreen,
                onPrimary: Colors.white,
                onSurface: WebTheme.textPrimary,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Validates the form, uploads photos, then persists the submission.
  ///
  /// This is passed as [WebFileUploadWidget.onUploadComplete] so that
  /// validation happens *before* any Cloudinary request is made.
  Future<void> _handleSubmit() async {
    // --- Form validation ---
    final rawQty = _quantityController.text.trim();
    if (rawQty.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter the number of trees planted.',
        backgroundColor: WebTheme.errorRed,
        colorText: Colors.white,
      );
      return;
    }

    final quantity = int.tryParse(rawQty);
    if (quantity == null || quantity <= 0) {
      Get.snackbar(
        'Validation Error',
        'Please enter a valid number greater than 0.',
        backgroundColor: WebTheme.errorRed,
        colorText: Colors.white,
      );
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter the planting location.',
        backgroundColor: WebTheme.errorRed,
        colorText: Colors.white,
      );
      return;
    }

    if (_fileController.selectedFiles.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please upload at least one photo as evidence.',
        backgroundColor: WebTheme.errorRed,
        colorText: Colors.white,
      );
      return;
    }

    // --- Upload photos to Cloudinary ---
    final uploadSuccess = await _fileController.uploadFiles(
      folder: 'greenquest/tree_planting',
    );

    if (!uploadSuccess || _fileController.uploadedFiles.isEmpty) {
      Get.snackbar(
        'Upload Failed',
        'Failed to upload photos. Please try again.',
        backgroundColor: WebTheme.errorRed,
        colorText: Colors.white,
      );
      return;
    }

    // --- Save submission to Firestore ---
    final success = await _treeController.submitTreePlanting(
      quantity: quantity,
      plantDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      location: _locationController.text.trim(),
      treeNames:
          _treeNameControllers
              .map((c) => c.text.trim())
              .where((name) => name.isNotEmpty)
              .toList(),
      uploadedFiles: _fileController.uploadedFiles,
    );

    if (success) {
      Get.snackbar(
        'Success',
        'Tree planting submitted successfully!',
        backgroundColor: WebTheme.primaryGreen,
        colorText: Colors.white,
      );
      // Reset form
      _quantityController.clear();
      _locationController.clear();
      for (final c in _treeNameControllers) {
        c.clear();
      }
      setState(() => _selectedDate = DateTime.now());
      _fileController.clearFiles();
    } else {
      Get.snackbar(
        'Submission Failed',
        'Failed to submit tree planting. Please try again.',
        backgroundColor: WebTheme.errorRed,
        colorText: Colors.white,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDesktop = WebResponsiveUtils.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: WebAppBar(
        title: 'Plant Trees',
        onMenuPressed:
            isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer:
          !isDesktop
              ? Drawer(child: WebSidebar(currentRoute: WebRoutes.plantTrees))
              : null,
      body: Row(
        children: [
          if (isDesktop) const WebSidebar(currentRoute: WebRoutes.plantTrees),
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
        constraints: const BoxConstraints(maxWidth: 1000),
        child: SingleChildScrollView(
          padding: WebResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildHeaderCard(),
              const SizedBox(height: 28),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildSubmitForm()),
                    const SizedBox(width: 28),
                    Expanded(flex: 2, child: _buildSubmissionsPanel()),
                  ],
                )
              else ...[
                _buildSubmitForm(),
                const SizedBox(height: 28),
                _buildSubmissionsPanel(),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Header card
  // -------------------------------------------------------------------------

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [WebTheme.primaryGreen, Color(0xFF2D8E47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: WebTheme.primaryGreen.withOpacity(0.30),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record Tree Planting',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Submit your tree planting activity with photo evidence',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🌳  ${_treeController.totalTreesPlanted.value} approved tree${_treeController.totalTreesPlanted.value != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Submit form card
  // -------------------------------------------------------------------------

  Widget _buildSubmitForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submit Tree Planting',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: WebTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Fill in the details about your tree planting activity.',
            style: TextStyle(fontSize: 13, color: WebTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // --- Number of Trees ---
          _label('Number of Trees'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(
              hintText: 'e.g. 10',
              prefixIcon: Icons.park_outlined,
            ),
          ),
          const SizedBox(height: 20),

          // --- Planting Date ---
          _label('Planting Date'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectDate,
            child: AbsorbPointer(
              child: TextFormField(
                controller: TextEditingController(
                  text: DateFormat('MMMM dd, yyyy').format(_selectedDate),
                ),
                decoration: _inputDecoration(
                  hintText: 'Select date',
                  prefixIcon: Icons.calendar_today_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Location ---
          _label('Location'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _locationController,
            decoration: _inputDecoration(
              hintText: 'e.g. Barangay San Juan, Rizal',
              prefixIcon: Icons.location_on_outlined,
            ),
          ),
          const SizedBox(height: 20),

          // --- Tree Names ---
          _label('Tree Names (Optional)'),
          const SizedBox(height: 4),
          const Text(
            'Enter the name of each tree species planted (up to 5).',
            style: TextStyle(fontSize: 12, color: WebTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          ...List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _treeNameControllers[index],
                decoration: _inputDecoration(
                  hintText: 'e.g. Narra, Molave',
                  prefixIcon: Icons.park_outlined,
                ).copyWith(labelText: 'Tree ${index + 1}'),
              ),
            );
          }),
          const SizedBox(height: 12),

          // --- Photo Evidence ---
          _label('Photo Evidence'),
          const SizedBox(height: 4),
          const Text(
            'Upload at least one photo as proof of your tree planting.',
            style: TextStyle(fontSize: 12, color: WebTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          WebFileUploadWidget(
            controller: _fileController,
            label: 'Submit Tree Planting',
            isDisabled: false,
            onUploadComplete: _handleSubmit,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // My Submissions panel
  // -------------------------------------------------------------------------

  Widget _buildSubmissionsPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Submissions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: WebTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (_treeController.isLoadingSubmissions.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    color: WebTheme.primaryGreen,
                  ),
                ),
              );
            }
            if (_treeController.myTreeSubmissions.isEmpty) {
              return _buildEmptyState();
            }
            return Column(
              children:
                  _treeController.myTreeSubmissions
                      .map(_buildSubmissionCard)
                      .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.eco_outlined,
              size: 56,
              color: WebTheme.borderLight,
            ),
            const SizedBox(height: 12),
            const Text(
              'No submissions yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: WebTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Submit your first tree planting activity above.',
              style: TextStyle(fontSize: 13, color: WebTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    final status = (submission['status'] as String?) ?? 'submitted';
    final quantity = (submission['quantity'] as int?) ?? 0;
    final location = (submission['location'] as String?) ?? 'Unknown';
    final feedback = submission['feedback'] as String?;

    // Resolve planting date — may be Firestore Timestamp or a legacy String
    String formattedDate = 'Unknown';
    final plantDate = submission['plantDate'];
    if (plantDate is Timestamp) {
      formattedDate = DateFormat('MMM dd, yyyy').format(plantDate.toDate());
    } else if (plantDate is String && plantDate.isNotEmpty) {
      formattedDate = plantDate;
    }

    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WebTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WebTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: tree count + status badge
          Row(
            children: [
              const Icon(Icons.eco, color: WebTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$quantity tree${quantity != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: WebTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.30)),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _metaRow(Icons.location_on_outlined, location),
          const SizedBox(height: 4),
          _metaRow(Icons.calendar_today_outlined, formattedDate),

          // Optional instructor feedback
          if (feedback != null && feedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.feedback_outlined,
                    size: 14,
                    color: WebTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      feedback,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: WebTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Shared helpers
  // -------------------------------------------------------------------------

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: WebTheme.backgroundWhite,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: WebTheme.borderLight),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: WebTheme.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: WebTheme.textHint),
      prefixIcon: Icon(prefixIcon, color: WebTheme.primaryGreen, size: 20),
      filled: true,
      fillColor: WebTheme.backgroundLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: WebTheme.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: WebTheme.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: WebTheme.primaryGreen, width: 2),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: WebTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: WebTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return WebTheme.successGreen;
      case 'rejected':
        return WebTheme.errorRed;
      default:
        return WebTheme.warningOrange; // submitted / pending
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }
}
