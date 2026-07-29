import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';
import 'hostel_results_screen.dart';

class GuidedSearchScreen extends StatefulWidget {
  const GuidedSearchScreen({super.key});

  @override
  State<GuidedSearchScreen> createState() => _GuidedSearchScreenState();
}

class _GuidedSearchScreenState extends State<GuidedSearchScreen> {
  // Step indices:
  //  0 – Suggested Locations
  //  1 – Distance from university  (NEW)
  //  2 – Hostel Type
  //  3 – Room Type
  //  4 – Budget
  //  5 – Facilities
  int _currentStep = 0;

  String? _selectedLocation;
  String? _selectedDistance;
  String? _selectedHostelType;
  String? _selectedRoomType;
  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  final Set<String> _selectedFacilities = {};

  final List<String> _locations = [
    "Kikoni",
    "Near Main Gate",
    "Kikumi",
    "Any around Makerere",
  ];

  // Distance-range options (label → stored value)
  static const List<_DistanceOption> _distanceOptions = [
    _DistanceOption(label: "Under 1 km",  value: "under_1km"),
    _DistanceOption(label: "1 – 2 km",    value: "1_2km"),
    _DistanceOption(label: "2 – 5 km",    value: "2_5km"),
    _DistanceOption(label: "5 + km",       value: "5km_plus"),
    _DistanceOption(label: "Any distance", value: ""),
  ];

  final List<String> _hostelTypes = ["Boys", "Girls", "Mixed"];
  final List<String> _roomTypes = ["Single", "Double"];

  final List<String> _facilities = [
    "WiFi",
    "Kitchen",
    "DSTV",
    "Laundry",
    "Reading Room",
    "Swimming Pool",
    "Pool Table",
    "Shuttle",
    "Security",
  ];

  @override
  void dispose() {
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
  }

  void _submitSearch() {
    final preferences = {
      "preferredLocation":
          _selectedLocation == "Any around Makerere" ? "" : _selectedLocation,
      "distanceRange": _selectedDistance ?? "",
      "preferredType": (_selectedHostelType ?? "").toLowerCase(),
      "roomType": _selectedRoomType,
      "minBudget": int.tryParse(_minBudgetController.text.trim()),
      "maxBudgetValue": int.tryParse(_maxBudgetController.text.trim()),
      "facilities": _selectedFacilities.toList(),
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HostelResultsScreen(preferences: preferences),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Guided Search"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationSection(),
            if (_currentStep >= 1) _buildDistanceSection(),
            if (_currentStep >= 2) _buildHostelTypeSection(),
            if (_currentStep >= 3) _buildRoomTypeSection(),
            if (_currentStep >= 4) _buildBudgetSection(),
            if (_currentStep >= 5) _buildFacilitiesSection(),
            if (_currentStep >= 5) ...[
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Search",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionWrapper({
    required String title,
    required String? summary,
    required bool isActive,
    required Widget child,
    required VoidCallback onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (!isActive && summary != null)
                TextButton(
                  onPressed: onEdit,
                  child: const Text("Edit"),
                ),
            ],
          ),
          if (!isActive && summary != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                summary,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          if (isActive) ...[
            const SizedBox(height: 12),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return _sectionWrapper(
      title: "Suggested Locations",
      summary: _selectedLocation,
      isActive: _currentStep == 0,
      onEdit: () => _goToStep(0),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _locations.map((loc) {
          return ChoiceChip(
            label: Text(loc),
            selected: _selectedLocation == loc,
            onSelected: (_) {
              setState(() {
                _selectedLocation = loc;
                _currentStep = 1;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDistanceSection() {
    final summary = _selectedDistance == null
        ? null
        : _distanceOptions
            .firstWhere((o) => o.value == _selectedDistance,
                orElse: () => const _DistanceOption(label: "Any distance", value: ""))
            .label;

    return _sectionWrapper(
      title: "Distance from University",
      summary: summary,
      isActive: _currentStep == 1,
      onEdit: () => _goToStep(1),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _distanceOptions.map((option) {
          return ChoiceChip(
            label: Text(option.label),
            selected: _selectedDistance == option.value,
            onSelected: (_) {
              setState(() {
                _selectedDistance = option.value;
                _currentStep = 2;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHostelTypeSection() {
    return _sectionWrapper(
      title: "Hostel Type",
      summary: _selectedHostelType,
      isActive: _currentStep == 2,
      onEdit: () => _goToStep(2),
      child: Wrap(
        spacing: 10,
        children: _hostelTypes.map((type) {
          return ChoiceChip(
            label: Text(type),
            selected: _selectedHostelType == type,
            onSelected: (_) {
              setState(() {
                _selectedHostelType = type;
                _currentStep = 3;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoomTypeSection() {
    return _sectionWrapper(
      title: "Room Type",
      summary: _selectedRoomType,
      isActive: _currentStep == 3,
      onEdit: () => _goToStep(3),
      child: Wrap(
        spacing: 10,
        children: _roomTypes.map((type) {
          return ChoiceChip(
            label: Text(type),
            selected: _selectedRoomType == type,
            onSelected: (_) {
              setState(() {
                _selectedRoomType = type;
                _currentStep = 4;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBudgetSection() {
    final hasBudget = _minBudgetController.text.isNotEmpty ||
        _maxBudgetController.text.isNotEmpty;

    return _sectionWrapper(
      title: "Budget (UGX)",
      summary: hasBudget
          ? "${_minBudgetController.text} - ${_maxBudgetController.text}"
          : null,
      isActive: _currentStep == 4,
      onEdit: () => _goToStep(4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Min",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Max",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _currentStep = 5);
              },
              child: const Text("Next"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    return _sectionWrapper(
      title: "Facilities",
      summary: _selectedFacilities.isNotEmpty
          ? _selectedFacilities.join(", ")
          : null,
      isActive: true,
      onEdit: () {},
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _facilities.map((facility) {
          final selected = _selectedFacilities.contains(facility);
          return FilterChip(
            label: Text(facility),
            selected: selected,
            onSelected: (isSelected) {
              setState(() {
                if (isSelected) {
                  _selectedFacilities.add(facility);
                } else {
                  _selectedFacilities.remove(facility);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Immutable label/value pair for a distance-range chip.
class _DistanceOption {
  final String label;
  final String value;
  const _DistanceOption({required this.label, required this.value});
}