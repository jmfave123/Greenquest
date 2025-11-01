import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenquest/user/profile/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final controller = Get.put(ProfileController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Obx(() {
        RxMap userData = controller.userData;
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              SizedBox(height: 32),
              GestureDetector(
                onTap: () => controller.uploadProfileImage(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Obx(() {
                      final profileImage = controller.userData['profileImage'];
                      return CircleAvatar(
                        radius: 48,
                        backgroundColor:
                            profileImage != null && profileImage.isNotEmpty
                                ? null
                                : const Color(0xFF34A853),
                        backgroundImage:
                            profileImage != null && profileImage.isNotEmpty
                                ? NetworkImage(profileImage)
                                : null,
                        child:
                            profileImage == null || profileImage.isEmpty
                                ? Text(
                                  controller.getInitials(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : null,
                      );
                    }),
                    if (controller.isUploadingImage.value)
                      const CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.black54,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF34A853),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                userData['fullName'] ?? '',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                userData['email'] ?? '',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _ProfileField(
                      label: 'Full Name',
                      value: userData['fullName'] ?? '',
                    ),
                    _ProfileField(
                      label: 'Email',
                      value: userData['email'] ?? '',
                    ),
                    _EditablePhoneField(
                      label: 'Phone Number',
                      value: userData['phoneNumber'] ?? '',
                      onSave:
                          (newPhone) => controller.updatePhoneNumber(newPhone),
                    ),
                    _ProfileField(
                      label: 'ID Number',
                      value: userData['idNumber'] ?? '',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditablePhoneField extends StatefulWidget {
  final String label;
  final String value;
  final Function(String) onSave;

  const _EditablePhoneField({
    required this.label,
    required this.value,
    required this.onSave,
  });

  @override
  State<_EditablePhoneField> createState() => _EditablePhoneFieldState();
}

class _EditablePhoneFieldState extends State<_EditablePhoneField> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validatePhoneNumber(String value) {
    setState(() {
      _hasError = false;
      _errorMessage = '';

      // Remove non-numeric characters
      final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');

      if (_controller.text != cleanValue) {
        // Update controller if we removed non-numeric characters
        _controller.value = TextEditingValue(
          text: cleanValue,
          selection: TextSelection.collapsed(offset: cleanValue.length),
        );
      }

      // Validate length
      if (cleanValue.length > 11) {
        _hasError = true;
        _errorMessage = 'Phone number must be 11 digits';
        return;
      }

      // Validate starts with 09
      if (cleanValue.isNotEmpty && !cleanValue.startsWith('09')) {
        _hasError = true;
        _errorMessage = 'Phone number must start with 09';
        return;
      }

      // Validate complete number
      if (cleanValue.length == 11 && !cleanValue.startsWith('09')) {
        _hasError = true;
        _errorMessage = 'Phone number must start with 09';
        return;
      }
    });
  }

  void _savePhoneNumber() {
    final phoneValue = _controller.text.trim();

    if (phoneValue.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Phone number cannot be empty',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (phoneValue.length != 11) {
      Get.snackbar(
        'Validation Error',
        'Phone number must be exactly 11 digits',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (!phoneValue.startsWith('09')) {
      Get.snackbar(
        'Validation Error',
        'Phone number must start with 09',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(phoneValue)) {
      Get.snackbar(
        'Validation Error',
        'Phone number must contain only numbers',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Save if valid
    widget.onSave(phoneValue);
    setState(() {
      _isEditing = false;
      _hasError = false;
      _errorMessage = '';
    });
  }

  void _cancelEdit() {
    setState(() {
      _controller.text = widget.value;
      _isEditing = false;
      _hasError = false;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.label,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const Spacer(),
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  color: Colors.black54,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (!_isEditing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.value.isEmpty ? 'Not set' : widget.value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: widget.value.isEmpty ? Colors.grey : Colors.black,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '09XXXXXXXXX',
                    helperText: 'Enter 11-digit Philippine mobile number',
                    errorText: _hasError ? _errorMessage : null,
                    filled: true,
                    fillColor:
                        _hasError
                            ? Colors.red.shade50
                            : const Color(0xFFF7F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError ? Colors.red : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError ? Colors.red : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _hasError ? Colors.red : const Color(0xFF34A853),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check,
                            color: Color(0xFF34A853),
                          ),
                          onPressed: _savePhoneNumber,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: _cancelEdit,
                        ),
                      ],
                    ),
                  ),
                  onChanged: _validatePhoneNumber,
                  onSubmitted: (_) => _savePhoneNumber(),
                ),
                if (_hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
