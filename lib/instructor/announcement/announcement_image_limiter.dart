/// Enforces the maximum number of images allowed per announcement.
///
/// Centralises the cap so it can be changed in one place without
/// touching any controller or UI code.
class AnnouncementImageLimiter {
  // Private constructor – this class is not meant to be instantiated.
  const AnnouncementImageLimiter._();

  static const int _maxImages = 20;

  /// Returns `true` when the instructor is still allowed to add more images.
  static bool canAddMore(int currentCount) => currentCount < _maxImages;

  /// Returns how many additional images can still be added (never negative).
  static int remaining(int currentCount) {
    final r = _maxImages - currentCount;
    return r < 0 ? 0 : r;
  }

  /// Returns `true` when [count] does not exceed the maximum.
  static bool isWithinLimit(int count) => count <= _maxImages;
}
