import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/department_service.dart';
import '../services/section_service.dart';
import '../services/semester_service.dart';

/// Controller for managing departments, sections, and semesters.
/// Abstracted from the UI to follow Clean Architecture and SOLID principles.
class DepartmentManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Services
  late final DepartmentService _departmentService;
  late final SectionService _sectionService;
  late final SemesterService _semesterService;

  // Reactive State
  final RxList<Map<String, dynamic>> departments = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> semesters = <Map<String, dynamic>>[].obs;

  // Cache for sections per department to avoid redundant queries
  final RxMap<String, RxList<Map<String, dynamic>>> sectionsMap =
      <String, RxList<Map<String, dynamic>>>{}.obs;

  // Loading States
  final RxBool isLoadingDepartments = true.obs;
  final RxBool isLoadingSemesters = true.obs;

  @override
  void onInit() {
    super.onInit();
    _departmentService = DepartmentService(_firestore);
    _sectionService = SectionService(_firestore);
    _semesterService = SemesterService(_firestore);

    // Bind real-time streams for both departments and semesters
    _bindDepartments();
    _bindSemesters();
  }

  // --- Departments ---

  void _bindDepartments() {
    isLoadingDepartments.value = true;
    departments.bindStream(
      _firestore
          .collection('departments')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((query) {
            isLoadingDepartments.value = false;
            return query.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
          }),
    );
  }

  void createDepartment(String name, String code, String description) async {
    await _departmentService.createDepartment(name, code, description);
  }

  void updateDepartment(
    String departmentId,
    String name,
    String code,
    String description,
  ) async {
    await _departmentService.updateDepartment(
      departmentId,
      name,
      code,
      description,
    );
  }

  void deleteDepartment(String departmentId, String departmentName) async {
    await _departmentService.deleteDepartment(departmentId);
  }

  // --- Sections ---

  /// Binds a stream for sections of a specific department.
  /// Uses a cache to ensure we don't create multiple streams for the same department.
  RxList<Map<String, dynamic>> getSectionsForDepartment(String departmentId) {
    if (!sectionsMap.containsKey(departmentId)) {
      final RxList<Map<String, dynamic>> sectionList =
          <Map<String, dynamic>>[].obs;
      sectionsMap[departmentId] = sectionList;

      sectionList.bindStream(
        _firestore
            .collection('sections')
            .where('departmentId', isEqualTo: departmentId)
            // .orderBy('createdAt', descending: false) // Optional sorting
            .snapshots()
            .map(
              (query) =>
                  query.docs.map((doc) {
                    final data = doc.data();
                    data['id'] = doc.id;
                    return data;
                  }).toList(),
            ),
      );
    }
    return sectionsMap[departmentId]!;
  }

  void createSection(
    String departmentId,
    String year,
    String sectionLetter,
    String departmentCode,
    String? subCode,
  ) async {
    await _sectionService.createSection(
      departmentId,
      year,
      sectionLetter,
      departmentCode,
      subCode,
    );
  }

  void updateSection(
    String sectionId,
    String year,
    String sectionLetter,
    String? subCode,
    String departmentCode,
  ) async {
    await _sectionService.updateSection(
      sectionId,
      year,
      sectionLetter,
      subCode,
      departmentCode,
    );
  }

  void deleteSection(String sectionId) async {
    await _sectionService.deleteSection(sectionId);
  }

  // --- Semesters ---

  /// Binds a real-time Firestore stream for semesters.
  /// Any create/update/delete will automatically push an updated list
  /// to [semesters] — no manual reload needed after mutations.
  void _bindSemesters() {
    isLoadingSemesters.value = true;
    semesters.bindStream(
      _semesterService.semestersStream().map((data) {
        isLoadingSemesters.value = false;
        return data;
      }),
    );
  }

  /// Public no-op kept for any external callers.
  /// The stream bound in [_bindSemesters] refreshes automatically.
  Future<void> loadSemesters() async {}

  void createSemester(String year, String semester) async {
    // Stream auto-updates after write — no manual reload needed.
    await _semesterService.createSemester(year, semester);
  }

  void updateSemester(String semesterId, String year, String semester) async {
    // Stream auto-updates after write — no manual reload needed.
    await _semesterService.updateSemester(semesterId, year, semester);
  }

  void deleteSemester(String semesterId) async {
    // Stream auto-updates after write — no manual reload needed.
    await _semesterService.deleteSemester(semesterId);
  }
}
