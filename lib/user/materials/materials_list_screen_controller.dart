import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MaterialsListScreenController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  var isLoading = true.obs;
  var materials = <Map<String, dynamic>>[].obs;
  var errorMessage = ''.obs;
  var currentInstructorUid = ''.obs;
  var currentInstructorName = ''.obs;
  var userSectionCode = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCurrentInstructorMaterials();
  }

  /// Load materials for the current logged-in instructor
  Future<void> loadCurrentInstructorMaterials() async {
    try {
      print('🔍 Loading current instructor materials...');

      final user = _auth.currentUser;
      print('👤 Current user: ${user?.uid}');

      if (user == null) {
        print('⚠️ No user logged in, loading all materials');
        await loadMaterials();
        return;
      }

      // Single Firestore read — extract both instructor selection and section code
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      String? instructorId;
      String? instructorName;
      String? sectionCode;

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final selectionComplete = userData['selectionComplete'] ?? false;
        final rawInstructorId = userData['selectedInstructorId']?.toString();

        if (selectionComplete &&
            rawInstructorId != null &&
            rawInstructorId.isNotEmpty) {
          instructorId = rawInstructorId;
          instructorName =
              userData['selectedInstructorName']?.toString() ??
              'Unknown Instructor';
        }

        sectionCode = userData['selectedSectionCode']?.toString();
      }

      userSectionCode.value = sectionCode ?? '';

      if (instructorId != null) {
        print(
          '✅ User has selected instructor: $instructorName (ID: $instructorId)',
        );
        currentInstructorUid.value = instructorId;
        currentInstructorName.value = instructorName ?? 'Unknown Instructor';
        await loadMaterialsByInstructorUidWithSectionFilter(
          instructorId,
          sectionCode,
        );
      } else {
        print('⚠️ No instructor selected, loading all materials');
        currentInstructorUid.value = '';
        currentInstructorName.value = '';
        await loadMaterialsWithSectionFilter(sectionCode);
      }
    } catch (e) {
      print('❌ Error loading current instructor materials: $e');
      currentInstructorUid.value = '';
      currentInstructorName.value = '';
      await loadMaterials();
    } finally {
      isLoading.value = false;
    }
  }

  /// Load materials for a specific instructor by UID
  Future<void> loadMaterialsByInstructorUid(String instructorUid) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔍 Loading materials for instructor UID: $instructorUid');

      // Get instructor document first
      final instructorDoc =
          await _firestore.collection('instructors').doc(instructorUid).get();

      if (!instructorDoc.exists) {
        print('❌ Instructor document not found for UID: $instructorUid');
        errorMessage.value = 'Instructor not found';
        materials.value = [];
        return;
      }

      final instructorData = instructorDoc.data()!;
      final instructorName =
          instructorData['name']?.toString() ?? 'Unknown Instructor';

      print('✅ Instructor found: $instructorName');
      print('📋 Instructor data keys: ${instructorData.keys.toList()}');

      // Update instructor name
      currentInstructorName.value = instructorName;

      // Get materials from the instructor's materials subcollection
      print(
        '📚 Querying materials subcollection for instructor: $instructorUid',
      );

      final materialsQuery =
          await _firestore
              .collection('instructors')
              .doc(instructorUid)
              .collection('materials')
              .orderBy('createdAt', descending: true)
              .get();

      print(
        '📚 Materials query result: ${materialsQuery.docs.length} documents',
      );

      List<Map<String, dynamic>> instructorMaterials = [];

      if (materialsQuery.docs.isNotEmpty) {
        print(
          '📖 Processing ${materialsQuery.docs.length} materials from subcollection...',
        );

        for (int i = 0; i < materialsQuery.docs.length; i++) {
          var materialDoc = materialsQuery.docs[i];
          var materialData = materialDoc.data();

          print(
            '📄 Material $i (${materialDoc.id}): ${materialData.runtimeType}',
          );
          print('📄 Material $i data: ${materialData.keys.toList()}');

          // Skip if materialData is null or empty
          if (materialData.isEmpty) {
            print('⚠️ Skipping empty material at index $i');
            continue;
          }

          // Create material map with proper validation and UI-ready data
          final materialMap = <String, dynamic>{
            'id': materialDoc.id,
            'title': materialData['title']?.toString() ?? 'No Title',
            'description':
                materialData['description']?.toString() ??
                'No description available',
            'instructorName':
                instructorName, // Use instructor name from instructor document
            'instructorId': instructorUid,
            'selectedClasses': materialData['selectedClasses'] ?? [],
            'attachments': materialData['attachments'] ?? [],
            'createdAt': _formatDate(materialData['createdAt']),
            'updatedAt': _formatDate(materialData['updatedAt']),
            'status': materialData['status']?.toString() ?? 'active',
            'type': materialData['type']?.toString() ?? 'Material',
            'period': materialData['period']?.toString() ?? '',
          };

          print('📄 Processed material: ${materialMap['title']}');
          print('📄 Instructor name: ${materialMap['instructorName']}');
          print('📄 Material status: ${materialMap['status']}');
          print('📄 Created date: ${materialMap['createdAt']}');

          // Only add if material has valid data for UI display
          if (materialMap['title'] != null &&
              materialMap['title'] != 'No Title') {
            instructorMaterials.add(materialMap);
            print('✅ Added material: ${materialMap['title']}');
          } else {
            print('❌ Skipped material due to missing or invalid title');
          }
        }
      } else {
        print('⚠️ No materials found in instructor subcollection');
        errorMessage.value = 'No materials found for this instructor';
      }

      // Sort by creation date (newest first)
      instructorMaterials.sort((a, b) {
        final dateA = a['createdAt'] ?? '';
        final dateB = b['createdAt'] ?? '';
        return dateB.compareTo(dateA);
      });

      // Filter out any invalid materials before setting
      final validMaterials =
          instructorMaterials
              .where(
                (material) =>
                    material.isNotEmpty &&
                    material['title'] != null &&
                    material['title'] != 'No Title',
              )
              .toList();

      materials.value = validMaterials;
      print(
        '📊 Loaded ${validMaterials.length} materials from instructor $instructorUid',
      );

      if (validMaterials.isEmpty) {
        print('⚠️ No valid materials found after processing');
        errorMessage.value = 'No materials available for this instructor';
      } else {
        errorMessage.value = ''; // Clear any previous errors
      }
    } catch (e) {
      errorMessage.value = 'Error loading materials: $e';
      print('❌ Error loading materials: $e');
      materials.value = [];

      Get.snackbar(
        'Error',
        'Failed to load materials: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load all materials from all instructors
  Future<void> loadMaterials() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Get all instructors
      final instructorsQuery = await _firestore.collection('instructors').get();

      List<Map<String, dynamic>> allMaterials = [];

      // Iterate through each instructor
      for (var instructorDoc in instructorsQuery.docs) {
        final instructorId = instructorDoc.id;
        final instructorData = instructorDoc.data();
        final instructorName =
            instructorData['name']?.toString() ?? 'Unknown Instructor';

        // Get materials from the instructor's materials subcollection
        try {
          final materialsQuery =
              await _firestore
                  .collection('instructors')
                  .doc(instructorId)
                  .collection('materials')
                  .orderBy('createdAt', descending: true)
                  .get();

          for (var materialDoc in materialsQuery.docs) {
            final materialData = materialDoc.data();

            // Skip if materialData is null or empty
            if (materialData.isEmpty) continue;

            // Create material map with proper validation and UI-ready data
            final materialMap = <String, dynamic>{
              'id': materialDoc.id,
              'title': materialData['title']?.toString() ?? 'No Title',
              'description':
                  materialData['description']?.toString() ??
                  'No description available',
              'instructorName':
                  instructorName, // Use instructor name from instructor document
              'instructorId': instructorId,
              'selectedClasses': materialData['selectedClasses'] ?? [],
              'attachments': materialData['attachments'] ?? [],
              'createdAt': _formatDate(materialData['createdAt']),
              'updatedAt': _formatDate(materialData['updatedAt']),
              'status': materialData['status']?.toString() ?? 'active',
              'type': materialData['type']?.toString() ?? 'Material',
              'period': materialData['period']?.toString() ?? '',
            };

            // Only add if material has valid data for UI display
            if (materialMap['title'] != null &&
                materialMap['title'] != 'No Title' &&
                materialMap['title'] != 'No Title') {
              allMaterials.add(materialMap);
            }
          }
        } catch (e) {
          print('Error loading materials from instructor $instructorId: $e');
        }
      }

      // Sort by creation date (newest first)
      allMaterials.sort((a, b) {
        final dateA = a['createdAt'] ?? '';
        final dateB = b['createdAt'] ?? '';
        return dateB.compareTo(dateA);
      });

      // Filter out any invalid materials before setting
      final validMaterials =
          allMaterials
              .where(
                (material) =>
                    material.isNotEmpty &&
                    material['title'] != null &&
                    material['title'] != 'No Title',
              )
              .toList();

      materials.value = validMaterials;
      print(
        '📊 Loaded ${validMaterials.length} materials from all instructors',
      );
    } catch (e) {
      errorMessage.value = 'Error loading materials: $e';
      print('Error loading materials: $e');
      Get.snackbar(
        'Error',
        'Failed to load materials: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load materials for a specific instructor
  Future<void> loadMaterialsByInstructor(String instructorId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Get instructor document
      final instructorDoc =
          await _firestore.collection('instructors').doc(instructorId).get();

      if (!instructorDoc.exists) {
        throw Exception('Instructor not found');
      }

      final instructorData = instructorDoc.data()!;
      final instructorName =
          instructorData['name']?.toString() ?? 'Unknown Instructor';

      // Get materials from the instructor's materials subcollection
      final materialsQuery =
          await _firestore
              .collection('instructors')
              .doc(instructorId)
              .collection('materials')
              .orderBy('createdAt', descending: true)
              .get();

      List<Map<String, dynamic>> instructorMaterials = [];

      for (var materialDoc in materialsQuery.docs) {
        final materialData = materialDoc.data();

        // Skip if materialData is null or empty
        if (materialData.isEmpty) continue;

        // Create material map with proper validation and UI-ready data
        final materialMap = <String, dynamic>{
          'id': materialDoc.id,
          'title': materialData['title']?.toString() ?? 'No Title',
          'description':
              materialData['description']?.toString() ??
              'No description available',
          'instructorName':
              instructorName, // Use instructor name from instructor document
          'instructorId': instructorId,
          'selectedClasses': materialData['selectedClasses'] ?? [],
          'attachments': materialData['attachments'] ?? [],
          'createdAt': _formatDate(materialData['createdAt']),
          'updatedAt': _formatDate(materialData['updatedAt']),
          'status': materialData['status']?.toString() ?? 'active',
          'type': materialData['type']?.toString() ?? 'Material',
          'period': materialData['period']?.toString() ?? '',
        };

        // Only add if material has valid data for UI display
        if (materialMap['title'] != null &&
            materialMap['title'] != 'No Title') {
          instructorMaterials.add(materialMap);
        }
      }

      // Sort by creation date (newest first)
      instructorMaterials.sort((a, b) {
        final dateA = a['createdAt'] ?? '';
        final dateB = b['createdAt'] ?? '';
        return dateB.compareTo(dateA);
      });

      // Filter out any invalid materials before setting
      final validMaterials =
          instructorMaterials
              .where(
                (material) =>
                    material.isNotEmpty &&
                    material['title'] != null &&
                    material['title'] != 'No Title',
              )
              .toList();

      materials.value = validMaterials;
      print(
        '📊 Loaded ${validMaterials.length} materials from instructor $instructorId',
      );
    } catch (e) {
      errorMessage.value = 'Error loading materials: $e';
      print('Error loading materials: $e');
      Get.snackbar(
        'Error',
        'Failed to load materials: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get materials by instructor
  List<Map<String, dynamic>> getMaterialsByInstructor(String instructorId) {
    return materials
        .where((material) => material['instructorId'] == instructorId)
        .toList();
  }

  /// Search materials by title or description
  List<Map<String, dynamic>> searchMaterials(String query) {
    if (query.isEmpty) return materials;

    return materials
        .where(
          (material) =>
              (material['title']?.toString() ?? '').toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              (material['description']?.toString() ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
  }

  /// Get unique instructors
  List<Map<String, String>> getUniqueInstructors() {
    Map<String, String> instructors = {};
    for (var material in materials) {
      final instructorId = material['instructorId']?.toString();
      final instructorName = material['instructorName']?.toString();
      if (instructorId != null && instructorName != null) {
        instructors[instructorId] = instructorName;
      }
    }
    return instructors.entries
        .map((e) => {'id': e.key, 'name': e.value})
        .toList();
  }

  /// Helper method to format Firestore Timestamp to date string
  String? _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';

    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Unknown Date';
      }

      // Format as "January 1, 2025" to match the UI design
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      final month = months[date.month - 1];
      return '$month ${date.day}, ${date.year}';
    } catch (e) {
      print('Error formatting date: $e');
      return 'Unknown Date';
    }
  }

  /// Refresh materials for current instructor
  Future<void> refreshMaterials() async {
    try {
      // Always reload from the selected instructor
      await loadCurrentInstructorMaterials();
    } catch (e) {
      print('Error refreshing materials: $e');
      // Fallback to loading all materials
      await loadMaterials();
    }
  }

  /// Load materials for a specific instructor (public method)
  Future<void> loadMaterialsForInstructor(String instructorUid) async {
    currentInstructorUid.value = instructorUid;
    await _loadInstructorName(instructorUid);
    await loadMaterialsByInstructorUid(instructorUid);
  }

  /// Load materials for a specific instructor by UID (alternative method)
  Future<void> loadMaterialsForInstructorByUid(String instructorUid) async {
    print('🎯 Loading materials for instructor: $instructorUid');
    currentInstructorUid.value = instructorUid;
    await loadMaterialsByInstructorUid(instructorUid);
  }

  /// Load instructor name by UID
  Future<void> _loadInstructorName(String instructorUid) async {
    try {
      print('🔍 Loading instructor name for UID: $instructorUid');
      final instructorDoc =
          await _firestore.collection('instructors').doc(instructorUid).get();

      if (instructorDoc.exists) {
        final instructorData = instructorDoc.data()!;
        final instructorName =
            instructorData['name']?.toString() ?? 'Unknown Instructor';
        currentInstructorName.value = instructorName;
        print('✅ Instructor name loaded: $instructorName');
      } else {
        print('❌ Instructor document not found for UID: $instructorUid');
        currentInstructorName.value = 'Unknown Instructor';
      }
    } catch (e) {
      print('❌ Error loading instructor name: $e');
      currentInstructorName.value = 'Unknown Instructor';
    }
  }

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  /// Test method to load materials for a specific instructor (for debugging)
  Future<void> testLoadMaterialsForInstructor(String instructorUid) async {
    print('🧪 Testing materials load for instructor: $instructorUid');
    await loadMaterialsByInstructorUid(instructorUid);
  }

  /// Debug method to list all available instructors
  Future<void> listAllInstructors() async {
    try {
      print('🔍 Listing all available instructors...');
      final instructorsQuery = await _firestore.collection('instructors').get();

      print('📋 Found ${instructorsQuery.docs.length} instructors:');
      for (var doc in instructorsQuery.docs) {
        final data = doc.data();
        final name = data['name']?.toString() ?? 'Unknown';
        final email = data['email']?.toString() ?? 'No email';
        print('  - ID: ${doc.id}');
        print('    Name: $name');
        print('    Email: $email');
        print('    Status: ${data['status']?.toString() ?? 'Unknown'}');
        print('    ---');
      }
    } catch (e) {
      print('❌ Error listing instructors: $e');
    }
  }

  /// Load materials from specific instructor with section filtering
  Future<void> loadMaterialsByInstructorUidWithSectionFilter(
    String instructorUid,
    String? userSectionCode,
  ) async {
    try {
      print(
        '🔍 Loading materials from instructor $instructorUid with section filter: $userSectionCode',
      );

      final materialsQuery =
          await _firestore
              .collection('instructors')
              .doc(instructorUid)
              .collection('materials')
              .orderBy('createdAt', descending: true)
              .get();

      final filteredMaterials = <Map<String, dynamic>>[];

      for (var materialDoc in materialsQuery.docs) {
        final materialData = materialDoc.data();
        final selectedClasses = List<String>.from(
          materialData['selectedClasses'] ?? [],
        );

        // Apply section filtering if user has a section code
        bool shouldInclude = true;
        if (userSectionCode != null && userSectionCode.isNotEmpty) {
          shouldInclude = selectedClasses.contains(userSectionCode);
          print(
            '📚 Material "${materialData['title']}" - Classes: $selectedClasses, User Section: $userSectionCode, Include: $shouldInclude',
          );
        }

        if (shouldInclude) {
          final materialMap = <String, dynamic>{
            'id': materialDoc.id,
            'title': materialData['title']?.toString() ?? 'No Title',
            'description':
                materialData['description']?.toString() ??
                'No description available',
            'selectedClasses': selectedClasses,
            'attachments': materialData['attachments'] ?? [],
            'instructorId': instructorUid,
            'instructorName': currentInstructorName.value,
            'createdAt': _formatDate(materialData['createdAt']),
            'updatedAt': _formatDate(materialData['updatedAt']),
            'status': materialData['status']?.toString() ?? 'active',
            'type': materialData['type']?.toString() ?? 'Material',
            'period': materialData['period']?.toString() ?? '',
          };

          if (materialMap['title'] != null &&
              materialMap['title'] != 'No Title') {
            filteredMaterials.add(materialMap);
          }
        }
      }

      materials.value = filteredMaterials;
      print(
        '📊 Loaded ${filteredMaterials.length} materials from instructor $instructorUid (filtered by section: $userSectionCode)',
      );
    } catch (e) {
      errorMessage.value = 'Error loading materials: $e';
      print('❌ Error loading materials from instructor: $e');
    }
  }

  /// Load all materials with section filtering
  Future<void> loadMaterialsWithSectionFilter(String? userSectionCode) async {
    try {
      print('🔍 Loading all materials with section filter: $userSectionCode');

      final instructorsQuery = await _firestore.collection('instructors').get();
      final allMaterials = <Map<String, dynamic>>[];

      for (var instructorDoc in instructorsQuery.docs) {
        final instructorId = instructorDoc.id;
        final instructorData = instructorDoc.data();
        final instructorName =
            instructorData['name']?.toString() ?? 'Unknown Instructor';

        try {
          final materialsQuery =
              await _firestore
                  .collection('instructors')
                  .doc(instructorId)
                  .collection('materials')
                  .orderBy('createdAt', descending: true)
                  .get();

          for (var materialDoc in materialsQuery.docs) {
            final materialData = materialDoc.data();
            final selectedClasses = List<String>.from(
              materialData['selectedClasses'] ?? [],
            );

            // Apply section filtering if user has a section code
            bool shouldInclude = true;
            if (userSectionCode != null && userSectionCode.isNotEmpty) {
              shouldInclude = selectedClasses.contains(userSectionCode);
            }

            if (shouldInclude) {
              final materialMap = <String, dynamic>{
                'id': materialDoc.id,
                'title': materialData['title']?.toString() ?? 'No Title',
                'description':
                    materialData['description']?.toString() ??
                    'No description available',
                'selectedClasses': selectedClasses,
                'attachments': materialData['attachments'] ?? [],
                'instructorId': instructorId,
                'instructorName': instructorName,
                'createdAt': _formatDate(materialData['createdAt']),
                'updatedAt': _formatDate(materialData['updatedAt']),
                'status': materialData['status']?.toString() ?? 'active',
                'type': materialData['type']?.toString() ?? 'Material',
                'period': materialData['period']?.toString() ?? '',
              };

              if (materialMap['title'] != null &&
                  materialMap['title'] != 'No Title') {
                allMaterials.add(materialMap);
              }
            }
          }
        } catch (e) {
          print('Error loading materials from instructor $instructorId: $e');
        }
      }

      // Sort by creation date (newest first)
      allMaterials.sort((a, b) {
        final dateA = a['createdAt'] ?? '';
        final dateB = b['createdAt'] ?? '';
        return dateB.compareTo(dateA);
      });

      materials.value = allMaterials;
      print(
        '📊 Loaded ${allMaterials.length} materials from all instructors (filtered by section: $userSectionCode)',
      );
    } catch (e) {
      errorMessage.value = 'Error loading materials: $e';
      print('❌ Error loading all materials: $e');
    }
  }

  /// Get real-time stream of materials for current instructor
  Stream<List<Map<String, dynamic>>> getMaterialsStream() {
    try {
      if (currentInstructorUid.value.isNotEmpty) {
        // Stream materials for specific instructor
        return _firestore
            .collection('instructors')
            .doc(currentInstructorUid.value)
            .collection('materials')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .asyncMap((snapshot) async {
              final instructorName = currentInstructorName.value;
              final sectionCode = userSectionCode.value;

              final filteredMaterials = <Map<String, dynamic>>[];

              for (var materialDoc in snapshot.docs) {
                final materialData = materialDoc.data();
                final selectedClasses = List<String>.from(
                  materialData['selectedClasses'] ?? [],
                );

                // Apply section filtering if user has a section code
                bool shouldInclude = true;
                if (sectionCode.isNotEmpty) {
                  shouldInclude = selectedClasses.contains(sectionCode);
                }

                if (shouldInclude) {
                  final materialMap = <String, dynamic>{
                    'id': materialDoc.id,
                    'title': materialData['title']?.toString() ?? 'No Title',
                    'description':
                        materialData['description']?.toString() ??
                        'No description available',
                    'selectedClasses': selectedClasses,
                    'attachments': materialData['attachments'] ?? [],
                    'instructorId': currentInstructorUid.value,
                    'instructorName': instructorName,
                    'createdAt': _formatDate(materialData['createdAt']),
                    'updatedAt': _formatDate(materialData['updatedAt']),
                    'status': materialData['status']?.toString() ?? 'active',
                    'type': materialData['type']?.toString() ?? 'Material',
                    'period': materialData['period']?.toString() ?? '',
                  };

                  if (materialMap['title'] != null &&
                      materialMap['title'] != 'No Title') {
                    filteredMaterials.add(materialMap);
                  }
                }
              }

              return filteredMaterials;
            });
      } else {
        // Stream all materials from all instructors
        return _firestore
            .collectionGroup('materials')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .asyncMap((snapshot) async {
              final sectionCode = userSectionCode.value;
              final allMaterials = <Map<String, dynamic>>[];

              for (var materialDoc in snapshot.docs) {
                final materialData = materialDoc.data();
                final selectedClasses = List<String>.from(
                  materialData['selectedClasses'] ?? [],
                );

                // Get instructor ID from path
                final pathParts = materialDoc.reference.path.split('/');
                final instructorId = pathParts.length > 1 ? pathParts[1] : '';

                // Get instructor name
                String instructorName = 'Unknown Instructor';
                if (instructorId.isNotEmpty) {
                  try {
                    final instructorDoc =
                        await _firestore
                            .collection('instructors')
                            .doc(instructorId)
                            .get();
                    if (instructorDoc.exists) {
                      final instructorData = instructorDoc.data() ?? {};
                      instructorName =
                          instructorData['name']?.toString() ??
                          'Unknown Instructor';
                    }
                  } catch (e) {
                    print('Error loading instructor name: $e');
                  }
                }

                // Apply section filtering if user has a section code
                bool shouldInclude = true;
                if (sectionCode.isNotEmpty) {
                  shouldInclude = selectedClasses.contains(sectionCode);
                }

                if (shouldInclude) {
                  final materialMap = <String, dynamic>{
                    'id': materialDoc.id,
                    'title': materialData['title']?.toString() ?? 'No Title',
                    'description':
                        materialData['description']?.toString() ??
                        'No description available',
                    'selectedClasses': selectedClasses,
                    'attachments': materialData['attachments'] ?? [],
                    'instructorId': instructorId,
                    'instructorName': instructorName,
                    'createdAt': _formatDate(materialData['createdAt']),
                    'updatedAt': _formatDate(materialData['updatedAt']),
                    'status': materialData['status']?.toString() ?? 'active',
                    'type': materialData['type']?.toString() ?? 'Material',
                    'period': materialData['period']?.toString() ?? '',
                  };

                  if (materialMap['title'] != null &&
                      materialMap['title'] != 'No Title') {
                    allMaterials.add(materialMap);
                  }
                }
              }

              return allMaterials;
            });
      }
    } catch (e) {
      print('❌ Error creating materials stream: $e');
      return Stream.value([]);
    }
  }
}
