import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/period_model.dart';

class PeriodManagementDialog extends StatefulWidget {
  const PeriodManagementDialog({super.key});

  @override
  State<PeriodManagementDialog> createState() => _PeriodManagementDialogState();
}

class _PeriodManagementDialogState extends State<PeriodManagementDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Period> _periods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPeriods();
  }

  Future<void> _loadPeriods() async {
    try {
      final snapshot = await _firestore.collection('periods').get();
      setState(() {
        _periods.clear();
        _periods.addAll(
          snapshot.docs.map((doc) => Period.fromMap(doc.data(), doc.id)),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load periods: $e');
    }
  }

  Future<void> _addPeriod() async {
    final semesterNameController = TextEditingController();
    final typeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Period'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: semesterNameController,
                    decoration: const InputDecoration(
                      labelText: 'Semester Name',
                      hintText: 'e.g. 1st Semester 2025-2026',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Type (optional)',
                      hintText: 'e.g. Regular, Summer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result == true && semesterNameController.text.trim().isNotEmpty) {
      try {
        await _firestore.collection('periods').add({
          'semesterName': semesterNameController.text.trim(),
          'type': typeController.text.trim(),
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _loadPeriods();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Period added successfully')),
          );
        }
      } catch (e) {
        _showError('Failed to add period: $e');
      }
    }
  }

  Future<void> _togglePeriodStatus(Period period) async {
    try {
      await _firestore.collection('periods').doc(period.id).update({
        'isActive': !period.isActive,
      });
      await _loadPeriods();
    } catch (e) {
      _showError('Failed to update period status: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage Periods',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _addPeriod,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Period'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _periods.isEmpty
                      ? const Center(
                        child: Text('No periods found. Add a new period.'),
                      )
                      : ListView.builder(
                        itemCount: _periods.length,
                        itemBuilder: (context, index) {
                          final period = _periods[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(period.semesterName),
                              subtitle: Text(
                                period.type.isNotEmpty
                                    ? period.type
                                    : 'No type',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: period.isActive,
                                    onChanged:
                                        (_) => _togglePeriodStatus(period),
                                    activeColor: Colors.green,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text(
                                                'Delete Period',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this period? This action cannot be undone.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                      );

                                      if (confirm == true) {
                                        try {
                                          await _firestore
                                              .collection('periods')
                                              .doc(period.id)
                                              .delete();
                                          await _loadPeriods();
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Period deleted successfully',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          _showError(
                                            'Failed to delete period: $e',
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
