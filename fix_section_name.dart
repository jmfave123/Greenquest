import 'lib/shared/services/section_name_fix_runner.dart';

/// Quick fix script for the specific student's section name issue
/// Student: jhon loyd tigtig (KjxFb5MDGwOATaJOEngDzkCLhHj2)
/// Current section: BSIT-B
/// Correct section: BSIT 4D
void main(List<String> args) async {
  // Run the BSIT 4D fix
  await SectionNameFixRunner.main(['fix-bsit4d']);
}
