import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// USTP NSTP Monitoring Form Widget
///
/// Renders the official CHED-10 Memorandum 190, S. 2022 tree-planting
/// monitoring form, populated from a student submission [data] map.
///
/// Expected [data] keys (all optional — blanks gracefully):
///   studentName, sectionName, nstpComponent, quantity,
///   treeNames (List<String>), location, plantDate (Timestamp),
///   submittedAt (Timestamp), notifiedBarangay (bool),
///   signagePlaced (bool), certificationObtained (bool)
class NstpFormWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const NstpFormWidget({super.key, required this.data});

  // ── helpers ────────────────────────────────────────────────────────────────

  String get _studentName => (data['studentName'] ?? '').toString();
  String get _section => (data['sectionName'] ?? '').toString();
  String get _nstpComponent => (data['nstpComponent'] ?? '').toString();
  int get _quantity => (data['quantity'] as int?) ?? 0;
  String get _location => (data['location'] ?? '').toString();

  List<String> get _treeNames {
    final raw = data['treeNames'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  String get _schoolYear {
    final ts =
        data['submittedAt'] as Timestamp? ?? data['plantDate'] as Timestamp?;
    if (ts == null) return '';
    final d = ts.toDate();
    // Aug–Jul academic calendar
    if (d.month >= 8) {
      return '${d.year}–${d.year + 1}';
    } else {
      return '${d.year - 1}–${d.year}';
    }
  }

  bool? _checklist(String key) => data[key] as bool?;

  static const _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
  };

  List<Map<String, dynamic>> get _imageFiles {
    final raw = data['files'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .where((f) {
          final type = (f['type'] ?? '').toString().toLowerCase().trim();
          final url = (f['url'] ?? '').toString();
          // `type` is stored as a file extension (e.g. "jpg"), not a MIME type
          return type.startsWith('image') ||
              _imageExtensions.contains(type) ||
              RegExp(
                r'\.(jpg|jpeg|png|gif|webp)(\?.*)?$',
                caseSensitive: false,
              ).hasMatch(url);
        })
        .map((f) => Map<String, dynamic>.from(f))
        .toList();
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildTitle(),
          const SizedBox(height: 14),
          _buildStudentInfoTable(),
          const SizedBox(height: 16),
          _buildTreeRequirementsSection(),
          const SizedBox(height: 16),
          _buildChecklistSection(),
          const SizedBox(height: 16),
          _buildReportorialSection(),
          const SizedBox(height: 24),
          _buildFooter(),
          const SizedBox(height: 32),
          _buildPhotoSection(),
        ],
      ),
    );
  }

  // ── header: logos + university name ───────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left logo — USTP
        _logo('assets/images/USTP-LOGO.png', 64),
        const SizedBox(width: 10),
        // Center logo — ONE CENTURY
        _logo('assets/images/ONE CENTURY, ONE VISION PIC.jpg', 64),
        const SizedBox(width: 10),
        // Right logo — NSTP
        _logo('assets/images/NSTP LOGO.jpg', 64),
        const SizedBox(width: 16),
        // University text block + underline
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UNIVERSITY OF SCIENCE AND TECHNOLOGY OF SOUTHERN PHILIPPINES',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Palatino Linotype',
                  color: Color.fromARGB(255, 0, 0, 0),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'NATIONAL SERVICE TRAINING PROGRAM',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Palatino Linotype',
                  color: Color.fromARGB(255, 0, 0, 0),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'OROQUIETA CAMPUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Palatino Linotype',
                  color: Color.fromARGB(255, 0, 0, 0),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.black, thickness: 0.8, height: 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logo(String assetPath, double size) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder:
          (_, __, ___) => Container(
            width: size,
            height: size,
            color: Colors.grey[200],
            child: const Icon(Icons.image, color: Colors.grey),
          ),
    );
  }

  // ── title paragraph ────────────────────────────────────────────────────────

  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        'MONITORING ON TREE PLANTING ACTIVITY IN COMPLIANCE WITH CHED-10 MEMORANDUM '
        'NO. 190, S. 2022 MANDATING ALL STUDENTS IN HEIS REGION 10, TAKING NSTP, '
        'TO PLANT AND GROW FIVE (5) TREES AS A REQUIREMENT FOR THE ISSUANCE OF NSTP '
        'SERIAL NUMBER',
        textAlign: TextAlign.justify,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cambria',
          height: 1.5,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  // ── student info table ─────────────────────────────────────────────────────

  Widget _buildStudentInfoTable() {
    return Table(
      border: TableBorder.all(color: Colors.black, width: 0.8),
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        _infoRow('NAME:', _studentName),
        _infoRow('COURSE, YEAR AND SECTION:', _section),
        _infoRow('NSTP COMPONENTS:', _nstpComponent),
        _infoRow('SCHOOL YEAR:', _schoolYear),
        _infoRow('STUDENT SIGNATURE', ''),
      ],
    );
  }

  TableRow _infoRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(value, style: const TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  // ── section 1: tree planting requirements ─────────────────────────────────

  Widget _buildTreeRequirementsSection() {
    final names = _treeNames;

    return Table(
      border: TableBorder.all(color: Colors.black, width: 0.8),
      columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth()},
      children: [
        // Section header (spans visually — 2 columns, second left empty)
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: const Text(
                '1.   TREE PLANTING REQUIREMENTS',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox.shrink(),
          ],
        ),
        // 1.1 Number of trees
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: Text(
                '1.1 Number of trees planted',
                style: const TextStyle(fontSize: 10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: Text(
                _quantity > 0 ? _quantity.toString() : '',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
        // 1.2 Tree names — label left, names 1-5 right
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: const Text(
                '1.2 Name of the tree.',
                style: TextStyle(fontSize: 10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 1; i <= 5; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '$i.  ${i <= names.length ? names[i - 1] : ''}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        // 1.3 Place where planted — inline with location
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: const Text(
                '1.3 Place where planted.',
                style: TextStyle(fontSize: 10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Text(_location, style: const TextStyle(fontSize: 10)),
            ),
          ],
        ),
      ],
    );
  }

  // ── section 2: checklist ───────────────────────────────────────────────────

  Widget _buildChecklistSection() {
    return Table(
      border: TableBorder.all(color: Colors.black, width: 0.8),
      columnWidths: const {
        0: FixedColumnWidth(170),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(44),
        3: FixedColumnWidth(44),
      },
      children: [
        // Header row — 4 columns: title | description | YES | NO
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
          children: [
            _checklistHeader('2.   CHECKLIST', isTitle: true),
            _checklistHeader(''),
            _checklistHeader('YES'),
            _checklistHeader('NO'),
          ],
        ),
        // 2.1 Barangay notification
        _checklistRow(
          title: '2.1 Notification to Barangay',
          description:
              'The student will notify the Barangay/Zone Official through a letter '
              'that they will plant trees as part of their environmental protection '
              'and conservation responsibilities, and in compliance with CHED-10 Memo. '
              '(Refer to the attached sample letter for guidance).',
          value: _checklist('notifiedBarangay'),
        ),
        // 2.2 Signage
        _checklistRow(
          title: '2.2 Signage shall be placed on the tree guard',
          description:
              'A signage shall be placed on the tree guard/stake with the following '
              'information: Name of the tree Date • Place • Planted by: [Name of the Student]',
          value: _checklist('signagePlaced'),
        ),
        // 2.3 Certification
        _checklistRow(
          title: '2.3 Certification of Compliance',
          description:
              'A certification of compliance shall be issued and signed by the Barangay Official',
          value: _checklist('certificationObtained'),
        ),
      ],
    );
  }

  Widget _checklistHeader(String text, {bool isTitle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Text(
        text,
        textAlign: isTitle ? TextAlign.left : TextAlign.center,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  TableRow _checklistRow({
    required String title,
    required String description,
    required bool? value,
  }) {
    final yesCheck = value == true ? '✓' : '';
    final noCheck = value == false ? '✓' : '';

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Text(title, style: const TextStyle(fontSize: 10)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Text(
            description,
            style: const TextStyle(fontSize: 10, height: 1.5),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              yesCheck,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              noCheck,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ── reportorial requirements ───────────────────────────────────────────────

  Widget _buildReportorialSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REPORTORIAL REQUIREMENTS',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            '(All reportorial requirements must be submitted as attachment to this form.)',
            style: TextStyle(fontSize: 9.5, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          const Text(
            '     A.   Photo Documentation',
            style: TextStyle(fontSize: 10),
          ),
          const SizedBox(height: 4),
          const Text(
            '     B.   Certification of Compliance',
            style: TextStyle(fontSize: 10),
          ),
          const SizedBox(height: 12),
          const Text(
            'Reminder: Retention of Proof – Students are advised to keep a copy of their '
            'proof of compliance (pictures and certification) for future reference.',
            style: TextStyle(
              fontSize: 9.5,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── footer ─────────────────────────────────────────────────────────────────

  Widget _buildPhotoSection() {
    final photos = _imageFiles;
    if (photos.isEmpty) return const SizedBox.shrink();

    const cols = 2;
    final rows = <Widget>[];

    for (var i = 0; i < photos.length; i += cols) {
      final cells = List.generate(cols, (c) {
        final idx = i + c;
        if (idx >= photos.length) {
          return const Expanded(child: SizedBox());
        }
        final url = photos[idx]['url'].toString();
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    url,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder:
                        (_, child, progress) =>
                            progress == null
                                ? child
                                : SizedBox(
                                  height: 160,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          progress.expectedTotalBytes != null
                                              ? progress.cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!
                                              : null,
                                      strokeWidth: 2,
                                      color: const Color(0xFF1A237E),
                                    ),
                                  ),
                                ),
                    errorBuilder:
                        (_, __, ___) => Container(
                          height: 160,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Photo ${idx + 1}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      });
      rows.add(Row(children: cells));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.black54, thickness: 0.6),
        const SizedBox(height: 8),
        const Text(
          'A.  PHOTO DOCUMENTATION',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...rows,
      ],
    );
  }

  // ── footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Align(
      alignment: Alignment.centerRight,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(color: Colors.black, thickness: 0.8),
            const SizedBox(height: 4),
            const Text(
              'USTP: ADVANCING A SUSTAINABLE FUTURE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
