/// Calculator class for all grade-related computations
class GradeCalculator {
  final List<Map<String, dynamic>> classStandingItems;
  final List<Map<String, dynamic>> quizPrelimItems;
  final List<Map<String, dynamic>> midtermExamItems;
  final List<Map<String, dynamic>> pitItems;
  final List<Map<String, dynamic>> finalClassStandingItems;
  final List<Map<String, dynamic>> finalQuizItems;
  final List<Map<String, dynamic>> finalExamItems;
  final List<Map<String, dynamic>> finalPitItems;

  GradeCalculator({
    required this.classStandingItems,
    required this.quizPrelimItems,
    required this.midtermExamItems,
    required this.pitItems,
    required this.finalClassStandingItems,
    required this.finalQuizItems,
    required this.finalExamItems,
    required this.finalPitItems,
  });

  // Grade intervals for conversion
  static const List<List<double>> _midtermGradeIntervals = [
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

  // ============================================================================
  // MIDTERM CALCULATIONS
  // ============================================================================

  String calculateClassStandingTotal(Map<String, dynamic> student) {
    int total = 0;
    for (var item in classStandingItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    return total.toString();
  }

  String calculateClassStandingPercentage(Map<String, dynamic> student) {
    int total = int.tryParse(calculateClassStandingTotal(student)) ?? 0;
    int maxTotal = classStandingItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  String calculateQuizPrelimTotal(Map<String, dynamic> student) {
    int total = 0;
    for (var item in quizPrelimItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    return total.toString();
  }

  String calculateQuizPrelimPercentage(Map<String, dynamic> student) {
    int total = int.tryParse(calculateQuizPrelimTotal(student)) ?? 0;
    int maxTotal = quizPrelimItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  String calculatePitTotal(Map<String, dynamic> student) {
    int total = 0;
    for (var item in pitItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    return total.toString();
  }

  String calculatePitPercentage(Map<String, dynamic> student) {
    int total = int.tryParse(calculatePitTotal(student)) ?? 0;
    int maxTotal = pitItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  String calculateMidtermExamPercentage(Map<String, dynamic> student) {
    int total = 0;
    for (var item in midtermExamItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    int maxTotal = midtermExamItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  // Helper methods to get category score as fraction (not formatted/rounded)
  double _classStandingFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in classStandingItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = classStandingItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  double _quizPrelimFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in quizPrelimItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = quizPrelimItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  double _midtermExamFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in midtermExamItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = midtermExamItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  double _pitFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in pitItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = pitItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  // Calculate MGA using raw fractions
  double _calculateRawMGA(Map<String, dynamic> student) {
    double cpa = _classStandingFraction(student);
    double qa = _quizPrelimFraction(student);
    double m = _midtermExamFraction(student);
    double pit = _pitFraction(student);
    return 0.10 * cpa + 0.40 * qa + 0.30 * m + 0.20 * pit;
  }

  // Display MGA as whole percent
  String calculateMGA(Map<String, dynamic> student) {
    double mga = _calculateRawMGA(student);
    return '${(mga * 100).round()}%';
  }

  String calculateMidLecGradePoint(Map<String, dynamic> student) {
    double mgaValue = _calculateRawMGA(student);
    double maxMgaValue = 1.0;
    double ratio = (maxMgaValue == 0) ? 0 : mgaValue / maxMgaValue;
    double gradePoint;
    if (ratio >= 0.7) {
      gradePoint = (23.0 / 3.0) - (20.0 / 3.0) * ratio;
    } else {
      gradePoint = 5.0 - (20.0 / 7.0) * ratio;
    }
    return gradePoint.toStringAsFixed(3);
  }

  // Mid Grade Point always equals Mid Lec Grade Point
  String calculateMidGradePoint(Map<String, dynamic> student) {
    return calculateMidLecGradePoint(student);
  }

  String _getMidtermGradeEquivalent(double gradePoint) {
    for (var range in _midtermGradeIntervals) {
      if (gradePoint >= range[0] && gradePoint < range[1]) {
        return range[2].toStringAsFixed(2);
      }
    }
    return '5.00';
  }

  String calculateMidtermGrade(Map<String, dynamic> student) {
    double gradePoint = double.tryParse(calculateMidGradePoint(student)) ?? 0.0;
    gradePoint = double.parse(gradePoint.toStringAsFixed(3));
    return _getMidtermGradeEquivalent(gradePoint);
  }

  // ============================================================================
  // FINAL GRADE CALCULATIONS
  // ============================================================================

  String calculateFinalClassStandingTotal(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalClassStandingItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    return total.toString();
  }

  String calculateFinalClassStandingPercentage(Map<String, dynamic> student) {
    int total = int.tryParse(calculateFinalClassStandingTotal(student)) ?? 0;
    int maxTotal = finalClassStandingItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  String calculateFinalQuizTotal(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalQuizItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    return total.toString();
  }

  String calculateFinalQuizPercentage(Map<String, dynamic> student) {
    int total = int.tryParse(calculateFinalQuizTotal(student)) ?? 0;
    int maxTotal = finalQuizItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  String calculateFinalExamPercentage(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalExamItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    int maxTotal = finalExamItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  String calculateFinalPitTotal(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalPitItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) {
        total += score;
      }
    }
    return total.toString();
  }

  String calculateFinalPitPercentage(Map<String, dynamic> student) {
    int total = int.tryParse(calculateFinalPitTotal(student)) ?? 0;
    int maxTotal = finalPitItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return '0%';
    double percentage = (total / maxTotal) * 100;
    return '${percentage.round()}%';
  }

  // Helper methods to get Final Grade category score as fraction
  double _finalClassStandingFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalClassStandingItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = finalClassStandingItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  double _finalQuizFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalQuizItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = finalQuizItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  double _finalExamFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalExamItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = finalExamItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  double _finalPitFraction(Map<String, dynamic> student) {
    int total = 0;
    for (var item in finalPitItems) {
      String key =
          '${item['title'].toString().toLowerCase().replaceAll(' ', '')}_${item['id']}';
      int? score = int.tryParse(student[key]?.toString() ?? '0');
      if (score != null) total += score;
    }
    int maxTotal = finalPitItems.fold(
      0,
      (sum, item) => sum + (item['points'] as int? ?? 0),
    );
    if (maxTotal == 0) return 0.0;
    return total / maxTotal;
  }

  // Calculate Final MGA using raw fractions
  double _calculateFinalRawMGA(Map<String, dynamic> student) {
    double cpa = _finalClassStandingFraction(student);
    double qa = _finalQuizFraction(student);
    double f = _finalExamFraction(student);
    double pit = _finalPitFraction(student);
    return 0.10 * cpa + 0.40 * qa + 0.30 * f + 0.20 * pit;
  }

  // Display Final MGA as whole percent
  String calculateFinalMGA(Map<String, dynamic> student) {
    double mga = _calculateFinalRawMGA(student);
    return '${(mga * 100).round()}%';
  }

  String calculateFinalLecGradePoint(Map<String, dynamic> student) {
    double mgaValue = _calculateFinalRawMGA(student);
    double maxMgaValue = 1.0;
    double ratio = (maxMgaValue == 0) ? 0 : mgaValue / maxMgaValue;
    double gradePoint;
    if (ratio >= 0.7) {
      gradePoint = (23.0 / 3.0) - (20.0 / 3.0) * ratio;
    } else {
      gradePoint = 5.0 - (20.0 / 7.0) * ratio;
    }
    return gradePoint.toStringAsFixed(3);
  }

  // Final Grade Point always equals Final Lec Grade Point
  String calculateFinalGradePoint(Map<String, dynamic> student) {
    return calculateFinalLecGradePoint(student);
  }

  String calculateFinalGrade(Map<String, dynamic> student) {
    double gradePoint =
        double.tryParse(calculateFinalGradePoint(student)) ?? 0.0;
    gradePoint = double.parse(gradePoint.toStringAsFixed(3));
    return _getMidtermGradeEquivalent(gradePoint);
  }

  // ============================================================================
  // COMPUTED FINAL GRADE CALCULATIONS
  // ============================================================================

  String calculateHalfMtgFtg(Map<String, dynamic> student) {
    double mtg = double.tryParse(calculateMidtermGrade(student)) ?? 0.0;
    double ftg = double.tryParse(calculateFinalGrade(student)) ?? 0.0;
    double combined = 0.5 * mtg + 0.5 * ftg;
    return combined.toStringAsFixed(2);
  }

  String calculateComp12MTGFTG(Map<String, dynamic> student) {
    double mtg = double.tryParse(calculateMidtermGrade(student)) ?? 5.00;
    double ftg = double.tryParse(calculateFinalGrade(student)) ?? 5.00;
    double result = (0.5 * mtg) + (0.5 * ftg);
    return result.toStringAsFixed(2);
  }

  String calculateComp12MTGFTGRemoval(Map<String, dynamic> student) {
    double result = double.tryParse(calculateComp12MTGFTG(student)) ?? 5.00;
    if (result <= 4.50) {
      return '5.00';
    }
    return result.toStringAsFixed(2);
  }

  String calculateComp12MTGFTGAfter(Map<String, dynamic> student) {
    return calculateComp12MTGFTGRemoval(student);
  }

  String calculateComp12Desc(Map<String, dynamic> student) {
    double result = double.tryParse(calculateComp12MTGFTG(student)) ?? 5.00;
    if (result <= 1.00) return 'Excellent';
    if (result <= 2.99) return 'Passed';
    return 'Failed';
  }

  String calculateComp13MTGFTG(Map<String, dynamic> student) {
    double mtg = double.tryParse(calculateMidtermGrade(student)) ?? 5.00;
    double ftg = double.tryParse(calculateFinalGrade(student)) ?? 5.00;
    double result = (1.0 / 3.0 * mtg) + (2.0 / 3.0 * ftg);
    return result.toStringAsFixed(2);
  }

  String calculateComp13MTGFTGRemoval(Map<String, dynamic> student) {
    double result = double.tryParse(calculateComp13MTGFTG(student)) ?? 5.00;
    if (result <= 4.50) {
      return '5.00';
    }
    return result.toStringAsFixed(2);
  }

  String calculateComp13MTGFTGAfter(Map<String, dynamic> student) {
    return calculateComp13MTGFTGRemoval(student);
  }

  String calculateComp13Desc(Map<String, dynamic> student) {
    double result = double.tryParse(calculateComp13MTGFTG(student)) ?? 5.00;
    if (result <= 1.00) return 'Excellent';
    if (result <= 2.99) return 'Passed';
    return 'Failed';
  }

  String calculateComp12MTGFTGForRemoval(Map<String, dynamic> student) {
    double avg = double.tryParse(calculateComp12MTGFTG(student)) ?? 5.00;
    String mapped = _getMidtermGradeEquivalent(
      double.parse(avg.toStringAsFixed(3)),
    );
    double mappedNum = double.tryParse(mapped) ?? 5.00;
    if (mappedNum > 3.50) {
      return '5.00';
    }
    return mapped;
  }

  String calculateComp12MTGFTGAfterRemoval(Map<String, dynamic> student) {
    return calculateComp12MTGFTGForRemoval(student);
  }

  String calculateComp13MTGFTGForRemoval(Map<String, dynamic> student) {
    double avg = double.tryParse(calculateComp13MTGFTG(student)) ?? 5.00;
    String mapped = _getMidtermGradeEquivalent(
      double.parse(avg.toStringAsFixed(3)),
    );
    double mappedNum = double.tryParse(mapped) ?? 5.00;
    if (mappedNum > 3.50) {
      return '5.00';
    }
    return mapped;
  }

  String calculateComp13MTGFTGAfterRemoval(Map<String, dynamic> student) {
    return calculateComp13MTGFTGForRemoval(student);
  }
}
