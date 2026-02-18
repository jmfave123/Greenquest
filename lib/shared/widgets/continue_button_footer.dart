import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContinueButtonFooter extends StatelessWidget {
  final RxString selectedDepartmentId;
  final RxString selectedSectionCode;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final String buttonText;
  final bool isWeb;

  const ContinueButtonFooter({
    super.key,
    required this.selectedDepartmentId,
    required this.selectedSectionCode,
    required this.onContinue,
    this.onBack,
    this.buttonText = 'Continue to COR Upload',
    this.isWeb = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isWeb) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: Row(
          children: [
            if (onBack != null)
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: Color(0xFF34A853)),
                label: const Text(
                  'Back',
                  style: TextStyle(color: Color(0xFF34A853)),
                ),
              ),
            const Spacer(),
            Obx(
              () => ElevatedButton(
                onPressed:
                    selectedSectionCode.value.isNotEmpty ? onContinue : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  backgroundColor: const Color(0xFF43A047),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile version
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: Obx(
          () => ElevatedButton(
            onPressed:
                selectedDepartmentId.value.isNotEmpty &&
                        selectedSectionCode.value.isNotEmpty
                    ? onContinue
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  selectedDepartmentId.value.isNotEmpty &&
                          selectedSectionCode.value.isNotEmpty
                      ? const Color(0xFF43A047)
                      : Colors.grey,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(buttonText),
          ),
        ),
      ),
    );
  }
}
