/// Thrown when safety actions require GPS but it is unavailable.
class LocationRequiredException implements Exception {
  const LocationRequiredException({
    this.message = 'Location is required for this safety action',
    this.permanentlyDenied = false,
  });

  final String message;
  final bool permanentlyDenied;

  @override
  String toString() => message;
}
