/// Centralised colour and style constants used by the Excel export pipeline.
///
/// Every hex colour that was previously a magic string inside [ExportService]
/// is now a named constant here.  This makes it trivial to update the
/// colour palette in one place and keeps the export code free of visual
/// noise.
///
/// ## Naming convention
/// * `k` prefix = constant
/// * Semantic name describing *where* the colour is used, not *what* colour
///   it is (e.g. `kSummaryFontColor` rather than `kDarkBlue`).
///
/// ## Usage
/// ```dart
/// cell.cellStyle.fontColor = ExcelStyleConstants.kSummaryFontColor;
/// ```
class ExcelStyleConstants {
  // Prevent instantiation — all members are static constants.
  const ExcelStyleConstants._();

  // ---------------------------------------------------------------------------
  // Generic / shared
  // ---------------------------------------------------------------------------

  /// Black — used for default text and borders.
  static const String kBlack = '#000000';

  /// White — used for default cell backgrounds.
  static const String kWhite = '#FFFFFF';

  // ---------------------------------------------------------------------------
  // Header rows (rows 1–7)
  // ---------------------------------------------------------------------------

  /// Light blue — row 1 "MIDTERM GRADE" / "FINAL GRADE" banner.
  static const String kHeaderBlueBg = '#99CCFF';

  /// Orange — row 2 "LECTURE 100%" banner and Midterm/Final Grade columns.
  static const String kHeaderOrangeBg = '#FFC000';

  /// Yellow — row 3/6 category headers (Class Standing, Quiz, PIT, etc.).
  static const String kCategoryYellowBg = '#FCF305';

  /// Very light blue — student-list export title row background.
  static const String kTitleBlueBg = '#E3F2FD';

  /// Off-white / very light grey — grade-sheet column header row background.
  static const String kColumnHeaderBg = '#F8FAFB';

  /// Light green — midterm section header row background.
  static const String kMidtermHeaderGreenBg = '#66BB6A';

  // ---------------------------------------------------------------------------
  // Computed-grade section
  // ---------------------------------------------------------------------------

  /// Soft green — background for Mid Lec / Fin Lec Grade Point columns.
  static const String kComputedGreenBg = '#C6E0B4';

  // ---------------------------------------------------------------------------
  // Summary / aggregated-value font colour
  // ---------------------------------------------------------------------------

  /// Dark indigo — font colour for summary values:
  /// Total Score (SRC/SRQ), CPA, QA, M, PIT%, MGA, FGA.
  static const String kSummaryFontColor = '#333399';

  // ---------------------------------------------------------------------------
  // Conditional pass / fail colours
  // ---------------------------------------------------------------------------

  /// Green — font colour for passing grades (≤ 3.00).
  static const String kPassingGreen = '#34A853';

  /// Red — font colour for failing grades (> 3.00) and "Failed" labels.
  static const String kFailingRed = '#E53935';

  // ---------------------------------------------------------------------------
  // Column-width defaults
  // ---------------------------------------------------------------------------

  /// Default column width for item-score columns (narrow).
  static const double kDefaultColumnWidth = 8.0;

  /// Column width for the "No." column.
  static const double kNumberColumnWidth = 5.0;

  /// Column width for the "ID Number" column.
  static const double kIdColumnWidth = 14.0;

  /// Column width for the "Names" column.
  static const double kNameColumnWidth = 28.0;

  /// Column width for summary/total columns (SRC, CPA, etc.).
  static const double kSummaryColumnWidth = 12.0;

  /// Column width for computed-grade columns (MGA, Grade Point, etc.).
  static const double kComputedColumnWidth = 10.0;

  /// Fixed row height for the detailed header row (row 7) to clip long text.
  static const double kHeaderRowHeight = 80.0;
}
