/// Represents the search criteria entered by the student during a single
/// search session (Guided Search or Describe-Your-Hostel).
///
/// Only fields explicitly provided by the student are non-null.
/// A null field means "the student did not specify this criterion" and it
/// must contribute 0% to the match score — no defaults, no assumptions.
class SearchCriteria {
  /// Preferred location area, e.g. "Kikoni", "Near Main Gate", "Kikumi".
  /// Null or empty means the student did not pick a location.
  final String? location;

  /// Distance range token: "under_1km" | "1_2km" | "2_5km" | "5km_plus".
  /// Null or empty means the student did not specify a distance range.
  final String? distanceRange;

  /// Hostel type: "boys" | "girls" | "mixed" (lower-case).
  /// Null or empty means any type is acceptable.
  final String? hostelType;

  /// Room type: "Single" | "Double".
  /// Null means the student did not specify a room type.
  final String? roomType;

  /// Minimum budget in UGX.  Null means no lower bound specified.
  final int? minBudget;

  /// Maximum budget in UGX.  Null means no upper bound specified.
  final int? maxBudget;

  /// Facilities the student explicitly requested, e.g. ["WiFi", "Laundry"].
  /// Empty list means no facility preference was given.
  final List<String> facilities;

  const SearchCriteria({
    this.location,
    this.distanceRange,
    this.hostelType,
    this.roomType,
    this.minBudget,
    this.maxBudget,
    this.facilities = const [],
  });

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'location': location,
        'distanceRange': distanceRange,
        'hostelType': hostelType,
        'roomType': roomType,
        'minBudget': minBudget,
        'maxBudget': maxBudget,
        'facilities': facilities,
      };

  factory SearchCriteria.fromMap(Map<String, dynamic> map) => SearchCriteria(
        location: map['location'] as String?,
        distanceRange: map['distanceRange'] as String?,
        hostelType: map['hostelType'] as String?,
        roomType: map['roomType'] as String?,
        minBudget: (map['minBudget'] as num?)?.toInt(),
        maxBudget: (map['maxBudget'] as num?)?.toInt(),
        facilities: List<String>.from(map['facilities'] ?? []),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// True when at least one criterion was provided.
  bool get hasAnyCriteria =>
      _hasLocation ||
      _hasDistance ||
      _hasHostelType ||
      _hasRoomType ||
      _hasBudget ||
      _hasFacilities;

  bool get _hasLocation =>
      location != null && location!.isNotEmpty && !location!.toLowerCase().contains('any');

  bool get _hasDistance =>
      distanceRange != null && distanceRange!.isNotEmpty;

  bool get _hasHostelType =>
      hostelType != null && hostelType!.isNotEmpty;

  bool get _hasRoomType =>
      roomType != null && roomType!.isNotEmpty;

  bool get _hasBudget => minBudget != null || maxBudget != null;

  bool get _hasFacilities => facilities.isNotEmpty;

  @override
  String toString() => 'SearchCriteria('
      'location: $location, '
      'distanceRange: $distanceRange, '
      'hostelType: $hostelType, '
      'roomType: $roomType, '
      'minBudget: $minBudget, '
      'maxBudget: $maxBudget, '
      'facilities: $facilities)';
}
