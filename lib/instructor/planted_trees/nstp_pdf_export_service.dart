import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

import '../../core/utils/app_logger.dart';

/// Service responsible for generating and sharing the USTP NSTP
/// Monitoring Form as a PDF document.
///
/// Separation-of-concerns: all PDF logic lives here so that
/// [NstpFormWidget] remains a pure UI widget and [ClassTreesTab]
/// stays free of formatting concerns (agent.md §4 – Architecture).
///
/// Usage:
/// ```dart
/// await NstpPdfExportService.exportToPdf(formData);
/// ```
class NstpPdfExportService {
  NstpPdfExportService._(); // static-only class

  static final _logger = AppLogger('NstpPdfExportService');

  // ── public API ─────────────────────────────────────────────────────────────

  /// Builds the NSTP monitoring form PDF from [data] and triggers
  /// the platform share / download sheet via [Printing.sharePdf].
  ///
  /// Throws on failure — callers should catch and show user-facing errors.
  static Future<void> exportToPdf(Map<String, dynamic> data) async {
    _logger.info('Starting NSTP PDF export');
    try {
      final bytes = await _buildPdfBytes(data);
      final studentName = (data['studentName'] ?? 'student')
          .toString()
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final filename = 'NSTP_Form_$studentName.pdf';

      if (kIsWeb) {
        // On web: create a temporary <a> element and trigger a browser download.
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor =
            html.AnchorElement(href: url)
              ..setAttribute('download', filename)
              ..style.display = 'none';
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        // On mobile / desktop: use the platform share / save sheet.
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }

      _logger.info('PDF export completed', context: {'student': studentName});
    } catch (e, st) {
      _logger.error('PDF export failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── data helpers ────────────────────────────────────────────────────────────

  /// Replaces characters outside the Latin-1 subset — which the built-in
  /// Helvetica/Times PDF fonts cannot render — with ASCII equivalents.
  /// Without this, unsupported glyphs appear as empty boxes in the PDF.
  static String _s(String text) => text
      .replaceAll('\u2013', '-') // en dash  –
      .replaceAll('\u2014', '-') // em dash  —
      .replaceAll('\u2022', '-') // bullet   •
      .replaceAll('\u2018', "'") // left single quote  '
      .replaceAll('\u2019', "'") // right single quote '
      .replaceAll('\u201C', '"') // left double quote  \u201C
      .replaceAll('\u201D', '"') // right double quote \u201D
      .replaceAll('\u00A0', ' '); // non-breaking space

  static String _str(Map<String, dynamic> d, String key) =>
      _s((d[key] ?? '').toString().trim());

  static int _qty(Map<String, dynamic> d) => (d['quantity'] as int?) ?? 0;

  static List<String> _treeNames(Map<String, dynamic> d) {
    final raw = d['treeNames'];
    if (raw is List) return raw.map((e) => _s(e.toString())).toList();
    return [];
  }

  static String _schoolYear(Map<String, dynamic> d) {
    final ts = d['submittedAt'] as Timestamp? ?? d['plantDate'] as Timestamp?;
    if (ts == null) return '';
    final dt = ts.toDate();
    // ASCII hyphen — built-in PDF fonts cannot render the en-dash (U+2013).
    return dt.month >= 8
        ? '${dt.year}-${dt.year + 1}'
        : '${dt.year - 1}-${dt.year}';
  }

  static String _check(bool? v, {required bool yes}) {
    if (v == null) return '';
    // Use ASCII 'X' — the tick mark (U+2713) is outside Latin-1 and
    // renders as a box with built-in PDF fonts.
    return (yes ? v == true : v == false) ? 'X' : '';
  }

  // ── PDF build ───────────────────────────────────────────────────────────────

  static Future<Uint8List> _buildPdfBytes(Map<String, dynamic> data) async {
    // Load logo assets -------------------------------------------------------
    final ustpImg = await _loadAsset('assets/images/USTP-LOGO.png');
    final centuryImg = await _loadAsset(
      'assets/images/ONE CENTURY, ONE VISION PIC.jpg',
    );
    final nstpImg = await _loadAsset('assets/images/NSTP LOGO.jpg');

    // Fonts (built-in Type-1 — no async required) ----------------------------
    final regular = pw.Font.helvetica();
    final bold = pw.Font.helveticaBold();
    final italic = pw.Font.helveticaOblique();
    final boldItalic = pw.Font.helveticaBoldOblique();

    // Shorthand text styles --------------------------------------------------
    pw.TextStyle ts(
      double size, {
      pw.Font? font,
      PdfColor color = PdfColors.black,
      double? height,
      double? letterSpacing,
    }) => pw.TextStyle(
      font: font ?? regular,
      fontSize: size,
      color: color,
      lineSpacing: height != null ? (height - 1) * size : 0,
      letterSpacing: letterSpacing,
    );

    // Data -------------------------------------------------------------------
    final studentName = _str(data, 'studentName');
    final section = _str(data, 'sectionName');
    final nstpComponent = _str(data, 'nstpComponent');
    final quantity = _qty(data);
    final location = _str(data, 'location');
    final treeNames = _treeNames(data);
    final schoolYear = _schoolYear(data);

    final notifiedBarangay = data['notifiedBarangay'] as bool?;
    final signagePlaced = data['signagePlaced'] as bool?;
    final certificationObtained = data['certificationObtained'] as bool?;

    // Page -------------------------------------------------------------------
    final doc = pw.Document(
      title: 'NSTP Monitoring Form',
      author: 'GreenQuest',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 36),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────────
              _pdfHeader(ustpImg, centuryImg, nstpImg, regular, bold, ts),
              pw.SizedBox(height: 10),

              // ── Title paragraph ─────────────────────────────────────────
              pw.Text(
                'MONITORING ON TREE PLANTING ACTIVITY IN COMPLIANCE WITH CHED-10 '
                'MEMORANDUM NO. 190, S. 2022 MANDATING ALL STUDENTS IN HEIS REGION 10, '
                'TAKING NSTP, TO PLANT AND GROW FIVE (5) TREES AS A REQUIREMENT FOR '
                'THE ISSUANCE OF NSTP SERIAL NUMBER',
                textAlign: pw.TextAlign.justify,
                style: ts(9, font: bold, height: 1.5),
              ),
              pw.SizedBox(height: 12),

              // ── Student info table ───────────────────────────────────────
              _pdfInfoTable(
                bold,
                regular,
                ts,
                studentName,
                section,
                nstpComponent,
                schoolYear,
              ),
              pw.SizedBox(height: 10),

              // ── Section 1: Tree requirements ─────────────────────────────
              _pdfRequirementsTable(
                bold,
                regular,
                ts,
                quantity,
                treeNames,
                location,
              ),
              pw.SizedBox(height: 10),

              // ── Section 2: Checklist ──────────────────────────────────────
              _pdfChecklistTable(
                bold,
                regular,
                ts,
                notifiedBarangay,
                signagePlaced,
                certificationObtained,
              ),
              pw.SizedBox(height: 10),

              // ── Reportorial requirements ─────────────────────────────────
              _pdfReportorial(bold, regular, italic, boldItalic, ts),
              pw.Spacer(),

              // ── Footer ───────────────────────────────────────────────────
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(
                      width: 260,
                      child: pw.Divider(color: PdfColors.black, thickness: 0.8),
                    ),
                    pw.Text(
                      'USTP: ADVANCING A SUSTAINABLE FUTURE',
                      style: ts(9, font: bold, letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Page 2: Photo Documentation ──────────────────────────────────────────
    final photoImages = await _fetchPhotoImages(
      data['files'],
      studentName: studentName,
    );

    if (photoImages.isNotEmpty) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 36),
          build:
              (ctx) => _pdfPhotoPage(
                ustpImg,
                centuryImg,
                nstpImg,
                regular,
                bold,
                ts,
                studentName,
                photoImages,
              ),
        ),
      );
    }

    return doc.save();
  }

  // ── section builders ────────────────────────────────────────────────────────

  static pw.Widget _pdfHeader(
    pw.ImageProvider? ustpImg,
    pw.ImageProvider? centuryImg,
    pw.ImageProvider? nstpImg,
    pw.Font regular,
    pw.Font bold,
    pw.TextStyle Function(
      double, {
      pw.Font? font,
      PdfColor color,
      double? height,
      double? letterSpacing,
    })
    ts,
  ) {
    pw.Widget logoOrBox(pw.ImageProvider? img) =>
        img != null
            ? pw.Image(img, width: 52, height: 52, fit: pw.BoxFit.contain)
            : pw.SizedBox(width: 52, height: 52);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            logoOrBox(ustpImg),
            pw.SizedBox(width: 8),
            logoOrBox(centuryImg),
            pw.SizedBox(width: 8),
            logoOrBox(nstpImg),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'UNIVERSITY OF SCIENCE AND TECHNOLOGY OF SOUTHERN PHILIPPINES',
                    style: ts(7, font: bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'NATIONAL SERVICE TRAINING PROGRAM',
                    style: ts(11, font: bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text('OROQUIETA CAMPUS', style: ts(9, font: bold)),
                  pw.SizedBox(height: 6),
                  pw.Divider(color: PdfColors.black, thickness: 0.8),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _pdfInfoTable(
    pw.Font bold,
    pw.Font regular,
    pw.TextStyle Function(
      double, {
      pw.Font? font,
      PdfColor color,
      double? height,
      double? letterSpacing,
    })
    ts,
    String studentName,
    String section,
    String nstpComponent,
    String schoolYear,
  ) {
    pw.TableRow infoRow(String label, String value) => pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(label, style: ts(8.5, font: bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(value, style: ts(8.5)),
        ),
      ],
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
      columnWidths: const {
        0: pw.IntrinsicColumnWidth(),
        1: pw.FlexColumnWidth(),
      },
      children: [
        infoRow('NAME:', studentName),
        infoRow('COURSE, YEAR AND SECTION:', section),
        infoRow('NSTP COMPONENTS:', nstpComponent),
        infoRow('SCHOOL YEAR:', schoolYear),
        infoRow('STUDENT SIGNATURE', ''),
      ],
    );
  }

  static pw.Widget _pdfRequirementsTable(
    pw.Font bold,
    pw.Font regular,
    pw.TextStyle Function(
      double, {
      pw.Font? font,
      PdfColor color,
      double? height,
      double? letterSpacing,
    })
    ts,
    int quantity,
    List<String> treeNames,
    String location,
  ) {
    final grey = PdfColor.fromHex('F5F5F5');

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
      columnWidths: const {0: pw.FlexColumnWidth(), 1: pw.FlexColumnWidth()},
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: grey),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              child: pw.Text(
                '1.   TREE PLANTING REQUIREMENTS',
                style: ts(8.5, font: bold),
              ),
            ),
            pw.SizedBox(),
          ],
        ),
        // 1.1
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: pw.Text('1.1 Number of trees planted', style: ts(8)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: pw.Text(
                quantity > 0 ? quantity.toString() : '',
                style: ts(8),
              ),
            ),
          ],
        ),
        // 1.2
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: pw.Text('1.2 Name of the tree.', style: ts(8)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: List.generate(5, (i) {
                  final name = i < treeNames.length ? treeNames[i] : '';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text('${i + 1}.  $name', style: ts(8)),
                  );
                }),
              ),
            ),
          ],
        ),
        // 1.3
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: pw.Text('1.3 Place where planted.', style: ts(8)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: pw.Text(location, style: ts(8)),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _pdfChecklistTable(
    pw.Font bold,
    pw.Font regular,
    pw.TextStyle Function(
      double, {
      pw.Font? font,
      PdfColor color,
      double? height,
      double? letterSpacing,
    })
    ts,
    bool? notifiedBarangay,
    bool? signagePlaced,
    bool? certificationObtained,
  ) {
    final grey = PdfColor.fromHex('F5F5F5');

    pw.TableRow checkRow(String title, String desc, bool? val) => pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(title, style: ts(7.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(desc, style: ts(7.5, height: 1.4)),
        ),
        pw.Center(
          child: pw.Text(_check(val, yes: true), style: ts(11, font: bold)),
        ),
        pw.Center(
          child: pw.Text(_check(val, yes: false), style: ts(11, font: bold)),
        ),
      ],
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
      columnWidths: const {
        0: pw.FixedColumnWidth(120),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(30),
        3: pw.FixedColumnWidth(30),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: grey),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              child: pw.Text('2.   CHECKLIST', style: ts(8.5, font: bold)),
            ),
            pw.SizedBox(),
            pw.Center(child: pw.Text('YES', style: ts(8.5, font: bold))),
            pw.Center(child: pw.Text('NO', style: ts(8.5, font: bold))),
          ],
        ),
        checkRow(
          '2.1 Notification to Barangay',
          'The student will notify the Barangay/Zone Official through a letter '
              'that they will plant trees as part of their environmental protection '
              'and conservation responsibilities, and in compliance with CHED-10 Memo. '
              '(Refer to the attached sample letter for guidance).',
          notifiedBarangay,
        ),
        checkRow(
          '2.2 Signage shall be placed on the tree guard',
          'A signage shall be placed on the tree guard/stake with the following '
              'information: Name of the tree Date - Place - Planted by: [Name of the Student]',
          signagePlaced,
        ),
        checkRow(
          '2.3 Certification of Compliance',
          'A certification of compliance shall be issued and signed by the Barangay Official',
          certificationObtained,
        ),
      ],
    );
  }

  static pw.Widget _pdfReportorial(
    pw.Font bold,
    pw.Font regular,
    pw.Font italic,
    pw.Font boldItalic,
    pw.TextStyle Function(
      double, {
      pw.Font? font,
      PdfColor color,
      double? height,
      double? letterSpacing,
    })
    ts,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('REPORTORIAL REQUIREMENTS', style: ts(8.5, font: bold)),
        pw.SizedBox(height: 4),
        pw.Text(
          '(All reportorial requirements must be submitted as attachment to this form.)',
          style: ts(8, font: italic),
        ),
        pw.SizedBox(height: 6),
        pw.Text('     A.   Photo Documentation', style: ts(8)),
        pw.SizedBox(height: 3),
        pw.Text('     B.   Certification of Compliance', style: ts(8)),
        pw.SizedBox(height: 8),
        pw.Text(
          'Reminder: Retention of Proof - Students are advised to keep a copy of their '
          'proof of compliance (pictures and certification) for future reference.',
          style: ts(8, font: italic, height: 1.5),
        ),
      ],
    );
  }

  // ── asset loader ────────────────────────────────────────────────────────────

  /// Loads a Flutter asset and returns a [pw.MemoryImage].
  /// Returns `null` (silently) if the asset is not found.
  static Future<pw.ImageProvider?> _loadAsset(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      _logger.warning('Asset not found for PDF: $path');
      return null;
    }
  }

  // ── photo fetcher ────────────────────────────────────────────────────────────

  /// Downloads image files from the submission's [files] list.
  /// Only entries whose [type] starts with "image" (or whose URL ends with a
  /// common image extension) are fetched. Network errors per image are logged
  /// and skipped rather than aborting the whole export.
  static Future<List<pw.ImageProvider>> _fetchPhotoImages(
    dynamic files, {
    required String studentName,
  }) async {
    if (files is! List || files.isEmpty) return [];

    final images = <pw.ImageProvider>[];
    for (final file in files) {
      if (file is! Map) continue;
      final url = (file['url'] ?? '').toString().trim();
      if (url.isEmpty) continue;

      // Determine if this entry is an image.
      final type = (file['type'] ?? '').toString().toLowerCase();
      final isImage =
          type.startsWith('image') ||
          RegExp(
            r'\.(jpg|jpeg|png|gif|webp)(\?.*)?$',
            caseSensitive: false,
          ).hasMatch(url);
      if (!isImage) continue;

      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          images.add(pw.MemoryImage(response.bodyBytes));
        } else {
          _logger.warning(
            'Photo fetch returned ${response.statusCode}',
            context: {'url': url},
          );
        }
      } catch (e) {
        _logger.warning(
          'Failed to fetch photo for PDF',
          context: {'url': url, 'student': studentName},
        );
      }
    }
    return images;
  }

  // ── photo documentation page ─────────────────────────────────────────────────

  static pw.Widget _pdfPhotoPage(
    pw.ImageProvider? ustpImg,
    pw.ImageProvider? centuryImg,
    pw.ImageProvider? nstpImg,
    pw.Font regular,
    pw.Font bold,
    pw.TextStyle Function(
      double, {
      pw.Font? font,
      PdfColor color,
      double? height,
      double? letterSpacing,
    })
    ts,
    String studentName,
    List<pw.ImageProvider> photos,
  ) {
    // 2-column grid with equal width cells.
    const cols = 2;
    final rows = <pw.Widget>[];

    for (var i = 0; i < photos.length; i += cols) {
      final rowChildren = <pw.Widget>[];
      for (var c = 0; c < cols; c++) {
        final idx = i + c;
        rowChildren.add(
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child:
                  idx < photos.length
                      ? pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            height: 200,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                color: PdfColors.grey400,
                                width: 0.5,
                              ),
                            ),
                            child: pw.Image(
                              photos[idx],
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Photo ${idx + 1}',
                            style: ts(7.5, color: PdfColors.grey700),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      )
                      : pw.SizedBox(), // empty filler for odd count
            ),
          ),
        );
      }
      rows.add(pw.Row(children: rowChildren));
      rows.add(pw.SizedBox(height: 8));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Same header as page 1
        _pdfHeader(ustpImg, centuryImg, nstpImg, regular, bold, ts),
        pw.SizedBox(height: 14),

        // Section title
        pw.Text('A.  PHOTO DOCUMENTATION', style: ts(11, font: bold)),
        pw.SizedBox(height: 4),
        pw.Text('Student: $studentName', style: ts(8.5)),
        pw.Divider(color: PdfColors.black, thickness: 0.6),
        pw.SizedBox(height: 10),

        // Photo grid
        ...rows,
      ],
    );
  }
}
