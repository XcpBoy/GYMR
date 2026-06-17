class WorkoutCalculator {
  /// Calculates the estimated One Rep Max (1RM) using the Epley formula.
  /// 
  /// Formula: 1RM = Weight * (1 + Reps / 30)
  static double calculateEpley1RM(double weight, double reps) {
    if (reps == 0) return 0.0;
    if (reps == 1) return weight;
    
    return weight * (1 + (reps / 30.0));
  }

  /// Calculates the total volume (tonnage) for a set.
  static double calculateVolume(double weight, double reps) {
    return weight * reps;
  }
}
