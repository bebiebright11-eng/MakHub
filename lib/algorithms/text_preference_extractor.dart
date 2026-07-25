class TextPreferenceExtractor {
  static Map<String, dynamic> extract(String text) {
    final lower = text.toLowerCase();

    // ---- Price extraction ----
    int? minBudget;
    int? maxBudget;

    int? _parseAmount(String raw) {
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
      minBudget = _parseAmount(rangeMatch.group(1)!);
      maxBudget = _parseAmount(rangeMatch.group(2)!);
    } else {
      // Pattern: "under X" / "below X" / "less than X"
      final maxMatch = RegExp(
        r'(?:under|below|less than)\s*(\d[\d,]*\s*k?)',
        caseSensitive: false,
      ).firstMatch(lower);

      if (maxMatch != null) {
        maxBudget = _parseAmount(maxMatch.group(1)!);
      } else {
        // Pattern: "above X" / "over X" / "more than X"
        final minMatch = RegExp(
          r'(?:above|over|more than)\s*(\d[\d,]*\s*k?)',
          caseSensitive: false,
        ).firstMatch(lower);

        if (minMatch != null) {
          minBudget = _parseAmount(minMatch.group(1)!);
        } else {
          // Fallback: just one lone number mentioned, treat as max budget
          final singleMatch = RegExp(
            r'(\d[\d,]*\s*k)',
            caseSensitive: false,
          ).firstMatch(lower);

          if (singleMatch != null) {
            maxBudget = _parseAmount(singleMatch.group(1)!);
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
      "preferredType": preferredType,
      "roomType": roomType,
      "minBudget": minBudget,
      "maxBudgetValue": maxBudget,
      "facilities": facilities.toList(),
    };
  }
}