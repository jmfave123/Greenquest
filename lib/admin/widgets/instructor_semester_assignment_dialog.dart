import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:greenquest/admin/services/semester_assignment_service.dart';

/// Dialog that allows an admin to assign / unassign periods for a single
/// instructor directly from the Manage Instructors screen.
///
/// Queries the `periods` collection (fields: semesterName, type, isActive)
/// which is the same collection shown in the admin Firestore console.
/// Write logic is centralised in [SemesterAssignmentService.updateInstructorPeriods].
class InstructorSemesterAssignmentDialog extends StatefulWidget {
  final String instructorId;
  final String instructorName;

  const InstructorSemesterAssignmentDialog({
    super.key,
    required this.instructorId,
    required this.instructorName,
  });

  @override
  State<InstructorSemesterAssignmentDialog> createState() =>
      _InstructorSemesterAssignmentDialogState();
}

class _InstructorSemesterAssignmentDialogState
    extends State<InstructorSemesterAssignmentDialog> {
  // ─── Services ────────────────────────────────────────────────────────────
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final SemesterAssignmentService _assignmentService;

  // ─── State ───────────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  /// All documents from the `periods` collection
  List<Map<String, dynamic>> _allPeriods = [];

  /// Period document IDs currently selected (mutable whilst user edits)
  final Set<String> _selectedPeriodIds = {};

  @override
  void initState() {
    super.initState();
    _assignmentService = SemesterAssignmentService(_firestore);
    _loadData();
  }

  // ─── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      // Run both fetches in parallel for performance
      final results = await Future.wait([
        _loadAllPeriods(),
        _loadInstructorAssignedPeriodIds(),
      ]);

      final periods = results[0] as List<Map<String, dynamic>>;
      final assignedIds = results[1] as Set<String>;

      if (mounted) {
        setState(() {
          _allPeriods = periods;
          _selectedPeriodIds
            ..clear()
            ..addAll(assignedIds);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load periods. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  /// Loads all documents from the `periods` collection.
  Future<List<Map<String, dynamic>>> _loadAllPeriods() async {
    final snapshot =
        await _firestore
            .collection('periods')
            .orderBy('createdAt', descending: false)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'semesterName': data['semesterName']?.toString() ?? '',
        'type': data['type']?.toString() ?? '',
        'isActive': data['isActive'] as bool? ?? false,
      };
    }).toList();
  }

  /// Returns the set of period IDs currently assigned to this instructor.
  Future<Set<String>> _loadInstructorAssignedPeriodIds() async {
    final doc =
        await _firestore
            .collection('instructors')
            .doc(widget.instructorId)
            .get();

    if (!doc.exists) return {};

    final data = doc.data() as Map<String, dynamic>;
    final assignedPeriods = (data['assignedPeriods'] as List<dynamic>?) ?? [];

    return assignedPeriods
        .map((p) => (p as Map<String, dynamic>)['periodId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  // ─── Save ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      await _assignmentService.updateInstructorPeriods(
        instructorId: widget.instructorId,
        newPeriodIds: _selectedPeriodIds.toList(),
        allPeriods: _allPeriods,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // Error snackbar is already shown by the service layer.
      // Re-enable the Save button so the user can retry.
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(child: _buildBody()),
            const SizedBox(height: 20),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF34A853).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.calendar_today_outlined,
            color: Color(0xFF34A853),
            size: 26,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assign to Semester',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.instructorName,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF34A853)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF34A853),
                side: const BorderSide(color: Color(0xFF34A853)),
              ),
            ),
          ],
        ),
      );
    }

    if (_allPeriods.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.black38, size: 48),
            SizedBox(height: 12),
            Text(
              'No periods have been created yet.\nCreate a period first from the Period Management screen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select the periods this instructor belongs to:',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _allPeriods.length,
            separatorBuilder:
                (_, __) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
            itemBuilder: (context, index) {
              final period = _allPeriods[index];
              final id = period['id']?.toString() ?? '';
              final semesterName = period['semesterName']?.toString() ?? '';
              final type = period['type']?.toString() ?? '';
              final label =
                  type.isNotEmpty ? '$semesterName — $type' : semesterName;
              final isActive = period['isActive'] as bool? ?? false;
              final isSelected = _selectedPeriodIds.contains(id);

              return CheckboxListTile(
                activeColor: const Color(0xFF34A853),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                value: isSelected,
                onChanged:
                    _isSaving
                        ? null
                        : (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedPeriodIds.add(id);
                            } else {
                              _selectedPeriodIds.remove(id);
                            }
                          });
                        },
                title: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                subtitle:
                    isActive
                        ? const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF34A853),
                            fontWeight: FontWeight.w500,
                          ),
                        )
                        : const Text(
                          'Inactive',
                          style: TextStyle(fontSize: 12, color: Colors.black38),
                        ),
                secondary:
                    isSelected
                        ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF34A853),
                          size: 22,
                        )
                        : const Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.black26,
                          size: 22,
                        ),
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
            side: const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed:
              (!_isLoading && !_isSaving && _errorMessage == null)
                  ? _save
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF34A853),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child:
              _isSaving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
        ),
      ],
    );
  }
}
