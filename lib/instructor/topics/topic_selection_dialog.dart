import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'topic_controller.dart';

class TopicSelectionDialog extends StatefulWidget {
  final String? currentTopicId;
  final String? currentTopicName;

  const TopicSelectionDialog({
    super.key,
    this.currentTopicId,
    this.currentTopicName,
  });

  @override
  State<TopicSelectionDialog> createState() => _TopicSelectionDialogState();
}

class _TopicSelectionDialogState extends State<TopicSelectionDialog> {
  final TopicController _topicController = Get.put(TopicController());
  String? _selectedTopicId;
  String? _selectedTopicName;

  @override
  void initState() {
    super.initState();
    _selectedTopicId = widget.currentTopicId;
    _selectedTopicName = widget.currentTopicName;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.topic, color: Color(0xFF34A853), size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Select Topic',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Topic List
            Obx(() {
              if (_topicController.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: Color(0xFF34A853)),
                  ),
                );
              }

              return Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // No Topic Option
                      _buildTopicOption(
                        topicId: null,
                        topicName: 'No Topic',
                        icon: Icons.not_interested,
                      ),
                      const Divider(height: 24),

                      // Existing Topics
                      if (_topicController.topics.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No topics created yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ..._topicController.topics.map((topic) {
                          return _buildTopicOption(
                            topicId: topic.id,
                            topicName: topic.topic,
                            icon: Icons.bookmark,
                          );
                        }).toList(),

                      const Divider(height: 24),

                      // Create New Topic Button
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34A853).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFF34A853),
                          ),
                        ),
                        title: const Text(
                          'Create New Topic',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF34A853),
                          ),
                        ),
                        subtitle: const Text('Add a new topic for activities'),
                        onTap: () => _showCreateTopicDialog(),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'topicId': _selectedTopicId,
                      'topicName': _selectedTopicName,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34A853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Select Topic'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicOption({
    required String? topicId,
    required String topicName,
    required IconData icon,
  }) {
    final isSelected = _selectedTopicId == topicId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            isSelected
                ? const Color(0xFF34A853).withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isSelected
                  ? const Color(0xFF34A853)
                  : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String?>(
        value: topicId,
        groupValue: _selectedTopicId,
        onChanged: (value) {
          setState(() {
            _selectedTopicId = value;
            _selectedTopicName = topicName;
          });
        },
        activeColor: const Color(0xFF34A853),
        title: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF34A853) : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                topicName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF34A853) : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateTopicDialog() async {
    final TextEditingController topicController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    await showDialog<bool>(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Row(
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: Color(0xFF34A853),
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Create New Topic',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Topic Name Field
                  TextField(
                    controller: topicController,
                    decoration: InputDecoration(
                      labelText: 'Topic Name *',
                      hintText: 'e.g., Introduction to Programming',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.bookmark_border),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Brief description of this topic',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final topicName = topicController.text.trim();
                          if (topicName.isEmpty) {
                            Get.snackbar(
                              'Error',
                              'Please enter a topic name',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          // Check for duplicates
                          if (_topicController.topicExists(topicName)) {
                            Get.snackbar(
                              'Error',
                              'A topic with this name already exists',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          // Create topic
                          final newTopic = await _topicController.createTopic(
                            topicName: topicName,
                          );

                          if (newTopic != null) {
                            Navigator.of(context).pop(true);
                            Get.snackbar(
                              'Success',
                              'Topic "${newTopic.topic}" created successfully',
                              backgroundColor: const Color(0xFF34A853),
                              colorText: Colors.white,
                            );

                            // Auto-select the newly created topic
                            setState(() {
                              _selectedTopicId = newTopic.id;
                              _selectedTopicName = newTopic.topic;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34A853),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Create Topic'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
