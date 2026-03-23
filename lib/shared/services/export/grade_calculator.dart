/// Pure grade-calculation logic extracted from [ExportService].
///
/// This class is stateless and contains **no** Flutter, Excel, or Firebase
/// dependencies.  Every method is deterministic and side-effect-free, which
/// makes the entire class trivially unit-testable.
///
/// ## Responsibilities
/// - Student name formatting ("First Middle Last" → "LAST, FIRST M.")
/// - Item-key generation for score look-ups
/// - Group totals, percentages, and weighted averages (MGA / FGA)
/// - Grade-point conversion (ratio → 5-point scale)
/// - Grade equivalence mapping (grade-point → grade ladder)
/// - Descriptive labels ("Excellent" / "Passed" / "Failed")
///
/// ## Usage
/// ```dart
/// const calc = GradeCalculator();
/// final total = calc.calculateGroupTotal(student, items);
/// ```
class GradeCalculator {
  const GradeCalculator();

  // ---------------------------------------------------------------------------
  // Grade intervals (5-point scale)
  // ---------------------------------------------------------------------------

  /// Interval table used by [mapGradePointToEquivalent] and [gradeLadder].
  ///
  /// Each entry is `[lowerBound, upperBound, mappedGrade]`.
  /// The range is **inclusive** on the lower bound and **exclusive** on the
  /// upper bound:  `lowerBound <= gp < upperBound`.
  static const List<List<double>> gradeIntervals = [
    [1.000, 1.125, 1.00],
    [1.125, 1.375, 1.25],
    [1.375, 1.625, 1.50],
    [1.625, 1.875, 1.75],
    [1.875, 2.125, 2.00],
    [2.125, 2.375, 2.25],
    [2.375, 2.625, 2.50],
    [2.625, 2.875, 2.75],
    [2.875, 3.125, 3.00],
    [3.125, 3.375, 3.25],
    [3.375, 3.625, 3.50],
    [3.625, 3.875, 3.75],
    [3.875, 4.125, 4.00],
    [4.125, 4.375, 4.25],
    [4.375, 4.625, 4.50],
    [4.625, 4.875, 4.75],
    [4.875, 5.125, 5.00],
  ];

  // ---------------------------------------------------------------------------
  // Category weight constants
  // ---------------------------------------------------------------------------

  /// Weight applied to class-standing performance percentage in the MGA / FGA
  /// formula.
  static const double classStandingWeight = 0.10;

  /// Weight applied to quiz / prelim performance percentage.
  static const double quizPrelimWeight = 0.40;

  /// Weight applied to exam performance percentage.
  static const double examWeight = 0.30;

  /// Weight applied to PIT (Per-Inno-Task) performance percentage.
  static const double pitWeight = 0.20;

  // ---------------------------------------------------------------------------
  // Name formatting
  // ---------------------------------------------------------------------------

  /// Formats a student's full name into **"LAST, FIRST M."** format.
  ///
  /// Handles the following cases:
  /// * Single word        → returned as-is, uppercased.
  /// * "First Last"       → "LAST, FIRST"
  /// * "First Middle Last"→ "LAST, FIRST M."
  String formatStudentName(String name) {
    if (name.isEmpty) return '';

    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length < 2) {
      return name.toUpperCase();
    }

    final lastName = parts.last;

    if (parts.length == 2) {
      return '${lastName.toUpperCase()}, ${parts[0].toUpperCase()}';
    }

    // Three or more parts: "First Middle ... Last"
    final firstName = parts[0];
    final middleInitial = parts[1][0].toUpperCase();
    return '${lastName.toUpperCase()}, ${firstName.toUpperCase()} $middleInitial.';
  }

  // ---------------------------------------------------------------------------
  // Header-text helper
  // ---------------------------------------------------------------------------

  /// Returns [text] unchanged (placeholder to allow future truncation).
  ///
  /// Previously truncated long header text; now returns the full string so the
  /// text can wrap or clip at a fixed row height in Excel.
  String truncateHeaderText(String text) {
    return text.isEmpty ? '' : text;
  }

  // ---------------------------------------------------------------------------
  // Score helpers
  // ---------------------------------------------------------------------------

  /// Builds a canonical look-up key for an item map.
  ///
  /// The key is `<lowercased-title-no-spaces>_<id>` and matches the convention
  /// used when student score data is stored.
  String makeItemKey(Map<String, dynamic> item) {
    final title = (item['title'] ?? '').toString().toLowerCase().replaceAll(
      ' ',
      '',
    );
    return '${title}_${item['id']}';
  }

  /// Reads a student's score for the given [key], returning an empty string
  /// when the value is absent.
  String readScore(Map<String, dynamic> student, String key) {
    return student[key]?.toString() ?? '';
  }

  /// Sums the `points` field across all [items].
  int maxPoints(List<Map<String, dynamic>> items) {
    return items.fold<int>(
      0,
      (sum, item) => sum + ((item['points'] ?? 0) as num).toInt(),
    );
  }

  // ---------------------------------------------------------------------------
  // Group aggregation
  // ---------------------------------------------------------------------------

  /// Returns the total raw score a [student] earned across [items].
  int calculateGroupTotal(
    Map<String, dynamic> student,
    List<Map<String, dynamic>> items,
  ) {
    int total = 0;
    for (final item in items) {
      final key = makeItemKey(item);
      final value = int.tryParse(student[key]?.toString() ?? '0');
      if (value != null) total += value;
    }
    return total;
  }

  /// Returns the percentage (0–100) a [student] earned across [items].
  double calculateGroupPercent(
    Map<String, dynamic> student,
    List<Map<String, dynamic>> items,
  ) {
    final total = calculateGroupTotal(student, items);
    final max = maxPoints(items);
    if (max == 0) return 0.0;
    return (total / max) * 100.0;
  }

  /// Returns the fraction (0–1) a [student] earned across [items].
  double fraction(
    Map<String, dynamic> student,
    List<Map<String, dynamic>> items,
  ) {
    final max = maxPoints(items);
    if (max == 0) return 0.0;
    return calculateGroupTotal(student, items) / max;
  }

  // ---------------------------------------------------------------------------
  // Weighted grade average (MGA / FGA)
  // ---------------------------------------------------------------------------

  /// Computes the weighted average across four grade categories.
  ///
  /// Formula:
  /// ```
  /// MGA = 0.10·CPA + 0.40·QA + 0.30·Exam + 0.20·PIT
  /// ```
  ///
  /// where each component is the student's fraction (0–1) in that category.
  double calculateRawMGA(
    Map<String, dynamic> student,
    List<Map<String, dynamic>> classStandingItems,
    List<Map<String, dynamic>> quizPrelimItems,
    List<Map<String, dynamic>> examItems,
    List<Map<String, dynamic>> pitItems,
  ) {
    final cpa = fraction(student, classStandingItems);
    final qa = fraction(student, quizPrelimItems);
    final exam = fraction(student, examItems);
    final pit = fraction(student, pitItems);
    return classStandingWeight * cpa +
        quizPrelimWeight * qa +
        examWeight * exam +
        pitWeight * pit;
  }

  // ---------------------------------------------------------------------------
  // Grade-point conversion
  // ---------------------------------------------------------------------------

  /// Converts a ratio (0–1) to a grade-point value on a 1–5 scale.
  ///
  /// * Ratio ≥ 0.70 → linear range yielding approximately 1.00–2.33
  /// * Ratio <  0.70 → linear range yielding approximately 2.14–5.00
  double gradePointFromRatio(double ratio) {
    if (ratio >= 0.7) {
      return (23.0 / 3.0) - (20.0 / 3.0) * ratio;
    }
    return 5.0 - (20.0 / 7.0) * ratio;
  }

  /// Maps a continuous grade-point value to the nearest grade-ladder
  /// equivalent (e.g. 1.00, 1.25, 1.50, …, 5.00) and returns it as a
  /// two-decimal-place string.
  String mapGradePointToEquivalent(double gradePoint) {
    final gp = double.parse(gradePoint.toStringAsFixed(3));
    for (final range in gradeIntervals) {
      if (gp >= range[0] && gp < range[1]) {
        return range[2].toStringAsFixed(2);
      }
    }
    return '5.00';
  }

  /// Same as [mapGradePointToEquivalent] but returns a [double].
  double mapGradePointToEquivalentAsNumber(double gradePoint) {
    return double.tryParse(mapGradePointToEquivalent(gradePoint)) ?? 5.00;
  }

  /// Maps a numeric grade to the nearest ladder step and returns the
  /// numeric value (e.g. 1.00, 1.25, … 5.00).
  double gradeLadder(double numericGrade) {
    final gp = double.parse(numericGrade.toStringAsFixed(3));
    for (final range in gradeIntervals) {
      if (gp >= range[0] && gp < range[1]) {
        return range[2];
      }
    }
    return 5.00;
  }

  /// Returns a human-readable description for a numeric grade.
  ///
  /// * ≤ 1.00 → "Excellent"
  /// * ≤ 2.99 → "Passed"
  /// * > 2.99 → "Failed"
  String descFromNumeric(double numGrade) {
    if (numGrade <= 1.00) return 'Excellent';
    if (numGrade <= 2.99) return 'Passed';
    return 'Failed';
  }

  // ---------------------------------------------------------------------------
  // Pass / Fail colour helpers (for conditional formatting)
  // ---------------------------------------------------------------------------

  /// Returns `true` when [gradePointValue] is a passing grade (≤ 3.00).
  bool isPassing(double gradePointValue) => gradePointValue <= 3.00;

  /// Returns the appropriate colour hex code for a grade:
  /// green (`#34A853`) for passing, red (`#E53935`) for failing.
  String colorForGradePoint(double gradePointValue) {
    return isPassing(gradePointValue) ? '#34A853' : '#E53935';
  }

  /// Returns the appropriate colour hex code for a descriptive label.
  ///
  /// * "failed"    → red
  /// * "excellent" → green
  /// * anything else → black
  String colorForDescription(String description) {
    final lower = description.toLowerCase();
    if (lower == 'failed') return '#E53935';
    if (lower == 'excellent') return '#34A853';
    return '#000000';
  }

  // ---------------------------------------------------------------------------
  // Legacy compatibility helpers (used by _addGradeSheetData)
  // ---------------------------------------------------------------------------

  /// Calculates the Student Raw-score for Class-standing (SRC).
  ///
  /// This mirrors [calculateGroupTotal] but accepts a differently-shaped
  /// scores map (keyed the same way as [makeItemKey]).
  double calculateSRC(
    Map<String, dynamic> scores,
    List<Map<String, dynamic>> items,
  ) {
    double total = 0;
    for (final item in items) {
      final key = makeItemKey(item);
      total += (scores[key] ?? 0).toDouble();
    }
    return total;
  }

  /// Calculates the Class Performance Average (CPA) as a percentage.
  double calculateCPA(double src, List<Map<String, dynamic>> items) {
    double maxTotal = 0;
    for (final item in items) {
      maxTotal += (item['points'] ?? 0).toDouble();
    }
    if (maxTotal == 0) return 0;
    return (src / maxTotal) * 100;
  }

  /// Calculates the Student Raw-score for Quizzes (SRQ).
  double calculateSRQ(
    Map<String, dynamic> scores,
    List<Map<String, dynamic>> items,
  ) {
    double total = 0;
    for (final item in items) {
      final key = makeItemKey(item);
      total += (scores[key] ?? 0).toDouble();
    }
    return total;
  }

  /// Calculates the Quiz Average (QA) as a percentage.
  double calculateQA(double srq, List<Map<String, dynamic>> items) {
    double maxTotal = 0;
    for (final item in items) {
      maxTotal += (item['points'] ?? 0).toDouble();
    }
    if (maxTotal == 0) return 0;
    return (srq / maxTotal) * 100;
  }
}
