class TextPreferenceExtractor {
  static Map<String, dynamic> extract(String text) {
    final lower = text.toLowerCase();

    // ---- Price extraction ----
    int? minBudget;
    int? maxBudget;

    int? parseAmount(String raw) {
      String cleaned = raw.replaceAll(',', '').trim();
      bool isK = cleaned.endsWith('k');
      if (isK) cleaned = cleaned.substring(0, cleaned.length - 1);
      final value = int.tryParse(cleaned);
      if (value == null) return null;
      return isK ? value * 1000 : value;
    }

    // Pattern: "between X and Y" / "from X to Y" / "X - Y" / "X to Y"
    final rangeMatch = RegExp(
      r'(\d[\d,]*\s*k?)\s*(?:-|to|and)\s*(\d[\d,]*\s*k?)',
      caseSensitive: false,
    ).firstMatch(lower);

    if (rangeMatch != null) {
      minBudget = parseAmount(rangeMatch.group(1)!);
      maxBudget = parseAmount(rangeMatch.group(2)!);
    } else {
      // Pattern: "under X" / "below X" / "less than X"
      final maxMatch = RegExp(
        r'(?:under|below|less than)\s*(\d[\d,]*\s*k?)',
        caseSensitive: false,
      ).firstMatch(lower);

      if (maxMatch != null) {
        maxBudget = parseAmount(maxMatch.group(1)!);
      } else {
        // Pattern: "above X" / "over X" / "more than X"
        final minMatch = RegExp(
          r'(?:above|over|more than)\s*(\d[\d,]*\s*k?)',
          caseSensitive: false,
        ).firstMatch(lower);

        if (minMatch != null) {
          minBudget = parseAmount(minMatch.group(1)!);
        } else {
          // Fallback: just one lone number mentioned, treat as max budget
          final singleMatch = RegExp(
            r'(\d[\d,]*\s*k)',
            caseSensitive: false,
          ).firstMatch(lower);

          if (singleMatch != null) {
            maxBudget = parseAmount(singleMatch.group(1)!);
          }
        }
      }
    }

    // ---- Room type ----
    String? roomType;
    if (lower.contains('single')) {
      roomType = 'Single';
    } else if (lower.contains('double')) {
      roomType = 'Double';
    }

    // ---- Hostel type ----
    String preferredType = '';
    if (lower.contains('girls')) {
      preferredType = 'girls';
    } else if (lower.contains('boys')) {
      preferredType = 'boys';
    } else if (lower.contains('mixed')) {
      preferredType = 'mixed';
    }

    // ---- Location ----
    String preferredLocation = '';
    if (lower.contains('kikoni')) {
      preferredLocation = 'Kikoni';
    } else if (lower.contains('kikumi')) {
      preferredLocation = 'Kikumi';
    } else if (lower.contains('main gate')) {
      preferredLocation = 'Near Main Gate';
    }

    // ---- Distance from university ----
    // Recognised phrases map to the same value tokens used by the guided search.
    //
    // Buckets:
    //   under_1km  – "within 1km", "under 1 km", "close to campus/university",
    //                "very close", "next to campus", "walking distance"
    //   1_2km      – "1-2 km", "1 to 2 km", "about 1 km", "around 1 km"
    //   2_5km      – "2-5 km", "2 to 5 km", "about 3 km", "a few km", "few kilometers"
    //   5km_plus   – "5 km away", "far from campus", "over 5 km", "more than 5"
    String distanceRange = '';

    // under_1km — explicit sub-1 km mentions or proximity phrases
    if (RegExp(
      r'within\s*(?:0[\.,]?\d*|1)\s*k(?:m|ilomete)',
      caseSensitive: false,
    ).hasMatch(lower) ||
        RegExp(
          r'under\s*1\s*k(?:m|ilomete)',
          caseSensitive: false,
        ).hasMatch(lower) ||
        RegExp(
          r'less\s+than\s*1\s*k(?:m|ilomete)',
          caseSensitive: false,
        ).hasMatch(lower) ||
        RegExp(
          r'\b(?:very\s+close|next\s+to\s+(?:campus|university|uni)|walking\s+distance|close\s+to\s+(?:campus|university|uni))\b',
          caseSensitive: false,
        ).hasMatch(lower)) {
      distanceRange = 'under_1km';

    // 1–2 km
    } else if (RegExp(
      r'1\s*[-–to]+\s*2\s*k(?:m|ilomete)',
      caseSensitive: false,
    ).hasMatch(lower) ||
        RegExp(
          r'(?:about|around|approximately)\s*1\s*k(?:m|ilomete)',
          caseSensitive: false,
        ).hasMatch(lower)) {
      distanceRange = '1_2km';

    // 2–5 km
    } else if (RegExp(
      r'2\s*[-–to]+\s*5\s*k(?:m|ilomete)',
      caseSensitive: false,
    ).hasMatch(lower) ||
        RegExp(
          r'(?:about|around|approximately)\s*[234]\s*k(?:m|ilomete)',
          caseSensitive: false,
        ).hasMatch(lower) ||
        RegExp(
          r'(?:a\s+few|few)\s+k(?:m|ilomete)',
          caseSensitive: false,
        ).hasMatch(lower)) {
      distanceRange = '2_5km';

    // 5 km +
    } else if (RegExp(
      r'(?:over|above|more\s+than|greater\s+than)\s*5\s*k(?:m|ilomete)',
      caseSensitive: false,
    ).hasMatch(lower) ||
        RegExp(
          r'5\s*k(?:m|ilomete)\s+(?:away|from)',
          caseSensitive: false,
        ).hasMatch(lower) ||
        RegExp(
          r'\bfar\s+(?:from\s+(?:campus|university|uni)|away)\b',
          caseSensitive: false,
        ).hasMatch(lower)) {
      distanceRange = '5km_plus';
    }

    // ---- Facilities ----
    final facilityKeywords = {
      'wifi': 'WiFi',
      'wi-fi': 'WiFi',
      'internet': 'WiFi',
      'kitchen': 'Kitchen',
      'dstv': 'DSTV',
      'tv': 'DSTV',
      'laundry': 'Laundry',
      'reading room': 'Reading Room',
      'swimming pool': 'Swimming Pool',
      'pool table': 'Pool Table',
      'shuttle': 'Shuttle',
      'security': 'Security',
    };

    final facilities = <String>{};
    facilityKeywords.forEach((keyword, value) {
      if (lower.contains(keyword)) {
        facilities.add(value);
      }
    });

    return {
      "preferredLocation": preferredLocation,
      "distanceRange": distanceRange,
      "preferredType": preferredType,
      "roomType": roomType,
      "minBudget": minBudget,
      "maxBudgetValue": maxBudget,
      "facilities": facilities.toList(),
    };
  }
}