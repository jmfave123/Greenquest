/// Helper class for generating column names for the class record table
class ColumnNameHelpers {
  /// Get student info column names (No., ID Number, Name)
  static List<String> getStudentInfoColumnNames() {
    return ['no', 'idNumber', 'name'];
  }

  /// Get class standing column names
  static List<String> getClassStandingColumnNames(
    List<Map<String, dynamic>> classStandingItems,
  ) {
    List<String> columns = [];
    for (var item in classStandingItems) {
      columns.add('cs_${item['id']}');
    }
    columns.addAll(['cs_total', 'cs_percentage']);
    return columns;
  }

  /// Get quiz/prelim column names
  static List<String> getQuizPrelimColumnNames(
    List<Map<String, dynamic>> quizPrelimItems,
  ) {
    List<String> columns = [];
    for (var item in quizPrelimItems) {
      columns.add('qp_${item['id']}');
    }
    columns.addAll(['qp_total', 'qp_percentage']);
    return columns;
  }

  /// Get midterm exam column names
  static List<String> getMidtermExamColumnNames(
    List<Map<String, dynamic>> midtermExamItems,
  ) {
    List<String> columns = [];
    for (var item in midtermExamItems) {
      columns.add('me_${item['id']}');
    }
    columns.add('me_percentage');
    return columns;
  }

  /// Get PIT (Performance Innovation Task) column names
  static List<String> getPitColumnNames(List<Map<String, dynamic>> pitItems) {
    List<String> columns = [];
    for (var item in pitItems) {
      columns.add('pit_${item['id']}');
    }
    columns.addAll(['pit_total', 'pit_percentage']);
    return columns;
  }

  /// Get lecture column names for midterm
  static List<String> getLectureColumnNames() {
    return ['mga', 'mid_lec_grade_point', 'mid_grade_point', 'midterm_grade'];
  }

  /// Get all graded items column names for midterm
  static List<String> getGradedItemsColumnNames(
    List<Map<String, dynamic>> classStandingItems,
    List<Map<String, dynamic>> quizPrelimItems,
    List<Map<String, dynamic>> midtermExamItems,
    List<Map<String, dynamic>> pitItems,
  ) {
    List<String> columns = [];

    // Class Standing columns
    for (var item in classStandingItems) {
      columns.add('cs_${item['id']}');
    }
    columns.addAll(['cs_total', 'cs_percentage']);

    // Quiz/Prelim columns
    for (var item in quizPrelimItems) {
      columns.add('qp_${item['id']}');
    }
    columns.addAll(['qp_total', 'qp_percentage']);

    // Midterm Exam columns
    for (var item in midtermExamItems) {
      columns.add('me_${item['id']}');
    }
    columns.add('me_percentage');

    // PIT columns
    for (var item in pitItems) {
      columns.add('pit_${item['id']}');
    }
    columns.addAll(['pit_total', 'pit_percentage']);

    // Lecture columns
    columns.addAll([
      'mga',
      'mid_lec_grade_point',
      'mid_grade_point',
      'midterm_grade',
    ]);

    return columns;
  }

  /// Get final class standing column names
  static List<String> getFinalClassStandingColumnNames(
    List<Map<String, dynamic>> finalClassStandingItems,
  ) {
    List<String> columns = [];
    for (var item in finalClassStandingItems) {
      columns.add('fcs_${item['id']}');
    }
    columns.addAll(['fcs_total', 'fcs_percentage']);
    return columns;
  }

  /// Get final quiz column names
  static List<String> getFinalQuizColumnNames(
    List<Map<String, dynamic>> finalQuizItems,
  ) {
    List<String> columns = [];
    for (var item in finalQuizItems) {
      columns.add('fq_${item['id']}');
    }
    columns.addAll(['fq_total', 'fq_percentage']);
    return columns;
  }

  /// Get final exam column names
  static List<String> getFinalExamColumnNames(
    List<Map<String, dynamic>> finalExamItems,
  ) {
    List<String> columns = [];
    for (var item in finalExamItems) {
      columns.add('fe_${item['id']}');
    }
    columns.add('fe_percentage');
    return columns;
  }

  /// Get final PIT column names
  static List<String> getFinalPitColumnNames(
    List<Map<String, dynamic>> finalPitItems,
  ) {
    List<String> columns = [];
    for (var item in finalPitItems) {
      columns.add('fpit_${item['id']}');
    }
    columns.addAll(['fpit_total', 'fpit_percentage']);
    return columns;
  }

  /// Get final lecture column names
  static List<String> getFinalLectureColumnNames() {
    return ['fga', 'final_lec_grade_point', 'final_grade_point', 'final_grade'];
  }

  /// Get all final graded items column names
  static List<String> getFinalGradedItemsColumnNames(
    List<Map<String, dynamic>> finalClassStandingItems,
    List<Map<String, dynamic>> finalQuizItems,
    List<Map<String, dynamic>> finalExamItems,
    List<Map<String, dynamic>> finalPitItems,
  ) {
    List<String> columns = [];

    // Final Class Standing columns
    for (var item in finalClassStandingItems) {
      columns.add('fcs_${item['id']}');
    }
    columns.addAll(['fcs_total', 'fcs_percentage']);

    // Final Quiz columns
    for (var item in finalQuizItems) {
      columns.add('fq_${item['id']}');
    }
    columns.addAll(['fq_total', 'fq_percentage']);

    // Final Exam columns
    for (var item in finalExamItems) {
      columns.add('fe_${item['id']}');
    }
    columns.add('fe_percentage');

    // Final PIT columns
    for (var item in finalPitItems) {
      columns.add('fpit_${item['id']}');
    }
    columns.addAll(['fpit_total', 'fpit_percentage']);

    // Final Lecture columns
    columns.addAll([
      'fga',
      'final_lec_grade_point',
      'final_grade_point',
      'final_grade',
    ]);

    return columns;
  }

  /// Get computed final grade column names
  static List<String> getComputedFinalGradeColumnNames() {
    return [
      'comp_half_mtg_ftg',
      'comp_12_mtg_ftg_removal',
      'comp_12_mtg_ftg_after',
      'comp_12_desc',
      'comp_13_mtg_ftg',
      'comp_13_mtg_ftg_removal',
      'comp_13_mtg_ftg_after',
      'comp_13_desc',
    ];
  }
}
