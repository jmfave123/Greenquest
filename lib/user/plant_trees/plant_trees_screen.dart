import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenquest/shared/login/custom_drawer.dart';
import 'package:greenquest/shared/controllers/file_submission_controller.dart';
import 'tree_planting_controller.dart';

class PlantTreesScreen extends StatefulWidget {
  const PlantTreesScreen({super.key});

  @override
  State<PlantTreesScreen> createState() => _PlantTreesScreenState();
}

class _PlantTreesScreenState extends State<PlantTreesScreen> {
  int selectedDrawerIndex = 5;
  final TreePlantingController _controller = Get.put(TreePlantingController());
  final FileSubmissionController _fileController = Get.put(
    FileSubmissionController(),
  );

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF34A853),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitTreePlanting() async {
    // Validation
    if (_quantityController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter the number of trees planted',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      Get.snackbar(
        'Error',
        'Please enter a valid number of trees (greater than 0)',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter the location',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_fileController.selectedFiles.isEmpty) {
      Get.snackbar(
        'Error',
        'Please upload at least one photo as evidence',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Show loading
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF34A853))),
      barrierDismissible: false,
    );

    try {
      // Upload files to Cloudinary
      final uploadSuccess = await _fileController.uploadFiles(
        folder: 'greenquest/tree_planting',
      );

      if (!uploadSuccess || _fileController.uploadedFiles.isEmpty) {
        Get.back(); // Close loading
        Get.snackbar(
          'Error',
          'Failed to upload photos',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Submit tree planting
      final success = await _controller.submitTreePlanting(
        quantity: quantity,
        plantDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        location: _locationController.text.trim(),
        uploadedFiles: _fileController.uploadedFiles,
      );

      Get.back(); // Close loading

      if (success) {
        Get.snackbar(
          'Success',
          'Tree planting submitted successfully!',
          backgroundColor: const Color(0xFF34A853),
          colorText: Colors.white,
        );

        // Clear form
        _quantityController.clear();
        _locationController.clear();
        _selectedDate = DateTime.now();
        _fileController.clearFiles();
        setState(() {});
      } else {
        Get.snackbar(
          'Error',
          'Failed to submit tree planting',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Close loading
      Get.snackbar(
        'Error',
        'An error occurred: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(
        selectedIndex: selectedDrawerIndex,
        onSelect: (i) {
          setState(() => selectedDrawerIndex = i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: const Text(
          'Plant Trees',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF34A853), Color(0xFF2D8E47)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco, size: 50, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Record Tree Planting',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            'Total Approved: ${_controller.totalTreesPlanted.value} trees',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Section
            const Text(
              'Submit Tree Planting',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Quantity Field
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Number of Trees',
                hintText: 'Enter quantity',
                prefixIcon: const Icon(
                  Icons.format_list_numbered,
                  color: Color(0xFF34A853),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF34A853),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date Field
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Planting Date',
                    hintText: DateFormat('MMMM dd, yyyy').format(_selectedDate),
                    prefixIcon: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF34A853),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF34A853),
                        width: 2,
                      ),
                    ),
                  ),
                  controller: TextEditingController(
                    text: DateFormat('MMMM dd, yyyy').format(_selectedDate),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location Field
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'Enter planting location',
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: Color(0xFF34A853),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF34A853),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Photo Evidence Section
            const Text(
              'Photo Evidence',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () =>
                  _fileController.selectedFiles.isEmpty
                      ? GestureDetector(
                        onTap: () async {
                          await _fileController.pickFiles();
                          setState(() {});
                        },
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to upload photos',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      : Column(
                        children: [
                          ...List.generate(
                            _fileController.selectedFiles.length,
                            (index) {
                              final file = _fileController.selectedFiles[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF34A853,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF34A853,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.image,
                                      color: Color(0xFF34A853),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        file.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        _fileController.removeFile(index);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () async {
                              await _fileController.pickFiles();
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.add,
                              color: Color(0xFF34A853),
                            ),
                            label: const Text(
                              'Add More Photos',
                              style: TextStyle(color: Color(0xFF34A853)),
                            ),
                          ),
                        ],
                      ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitTreePlanting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34A853),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Submit Tree Planting',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // My Submissions Section
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            const Text(
              'My Submissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            Obx(() {
              if (_controller.isLoadingSubmissions.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Color(0xFF34A853)),
                  ),
                );
              }

              if (_controller.myTreeSubmissions.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No submissions yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _controller.myTreeSubmissions.length,
                itemBuilder: (context, index) {
                  final submission = _controller.myTreeSubmissions[index];
                  final status = submission['status'] ?? 'submitted';
                  final quantity = submission['quantity'] ?? 0;
                  final location = submission['location'] ?? 'Unknown';

                  // Format the timestamp
                  String formattedDate = 'Unknown';
                  final plantDate = submission['plantDate'];
                  if (plantDate != null) {
                    if (plantDate is Timestamp) {
                      final dateTime = plantDate.toDate();
                      formattedDate = DateFormat(
                        'MMM dd, yyyy - hh:mm a',
                      ).format(dateTime);
                    } else if (plantDate is String) {
                      // Handle old string format
                      formattedDate = plantDate;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF34A853).withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.eco,
                                    color: Color(0xFF34A853),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '$quantity tree${quantity > 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(
                                    _controller.getStatusBadgeColor(status),
                                  ),
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _controller.getStatusText(status),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(
                                    int.parse(
                                      _controller.getStatusBadgeColor(status),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (submission['feedback'] != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.feedback,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    submission['feedback'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
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
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
