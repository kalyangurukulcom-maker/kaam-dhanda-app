// ============================================================
// Feature #124: Location Filter (State → City Cascading)
// File: lib/widgets/location_filter_widget.dart
// Kaam Dhanda App — Flutter
//
// Includes:
//   1. LocationFilterWidget  — inline widget (search bars mein)
//   2. LocationFilterSheet   — bottom sheet version
//   3. LocationFilterScreen  — full standalone page
//   4. LocationData          — cities/states data class
// ============================================================

import 'package:flutter/material.dart';

// ============================================================
// Location Data
// ============================================================
class LocationData {
  static const Map<String, List<String>> citiesByState = {
    'Jharkhand': [
      'रांची', 'धनबाद', 'जमशेदपुर', 'बोकारो', 'हजारीबाग',
      'गिरिडीह', 'देवघर', 'दुमका', 'चाईबासा', 'रामगढ़',
      'कोडरमा', 'लातेहार', 'पलामू', 'गुमला', 'सिमडेगा',
    ],
    'Maharashtra': [
      'पुणे', 'मुंबई', 'नागपुर', 'नाशिक', 'औरंगाबाद',
      'सोलापुर', 'कोल्हापुर', 'ठाणे', 'नवी मुंबई',
    ],
    'Karnataka': [
      'बेंगलुरु', 'मैसूर', 'हुबली', 'मंगलुरु', 'बेलगाम',
      'गुलबर्गा', 'शिमोगा', 'दावणगेरे',
    ],
    'Delhi': [
      'दिल्ली', 'गुड़गाँव', 'नोएडा', 'फरीदाबाद', 'गाजियाबाद',
      'ग्रेटर नोएडा',
    ],
    'Gujarat': [
      'सूरत', 'अहमदाबाद', 'वड़ोदरा', 'राजकोट', 'भावनगर',
      'जामनगर', 'गांधीनगर',
    ],
    'Telangana': [
      'हैदराबाद', 'वारंगल', 'करीमनगर', 'निज़ामाबाद', 'खम्मम',
    ],
    'Tamil Nadu': [
      'चेन्नई', 'कोयम्बटूर', 'मदुरई', 'तिरुचि', 'सेलम',
      'इरोड', 'वेल्लोर',
    ],
    'West Bengal': [
      'कोलकाता', 'हावड़ा', 'दुर्गापुर', 'आसनसोल', 'सिलीगुड़ी',
    ],
    'Uttar Pradesh': [
      'लखनऊ', 'कानपुर', 'आगरा', 'वाराणसी', 'इलाहाबाद',
      'मेरठ', 'नोएडा', 'गाजियाबाद',
    ],
    'Rajasthan': [
      'जयपुर', 'जोधपुर', 'उदयपुर', 'कोटा', 'अजमेर', 'बीकानेर',
    ],
  };

  static const Map<String, String> stateEmojis = {
    'Jharkhand': '🏔️',
    'Maharashtra': '🌆',
    'Karnataka': '🌴',
    'Delhi': '🏛️',
    'Gujarat': '🏭',
    'Telangana': '🌿',
    'Tamil Nadu': '🏝️',
    'West Bengal': '🐯',
    'Uttar Pradesh': '🕌',
    'Rajasthan': '🏜️',
  };

  static List<String> get states => citiesByState.keys.toList();

  static List<String> citiesFor(String? state) {
    if (state == null || state.isEmpty) return [];
    return citiesByState[state] ?? [];
  }
}

// ============================================================
// 1. Inline Location Filter Widget
// ============================================================
class LocationFilterWidget extends StatefulWidget {
  final String? initialState;
  final String? initialCity;
  final void Function(String? state, String? city) onChanged;
  final bool compact; // true = horizontal row, false = vertical stacked

  const LocationFilterWidget({
    Key? key,
    this.initialState,
    this.initialCity,
    required this.onChanged,
    this.compact = false,
  }) : super(key: key);

  @override
  State<LocationFilterWidget> createState() =>
      _LocationFilterWidgetState();
}

class _LocationFilterWidgetState extends State<LocationFilterWidget> {
  String? _selectedState;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _selectedState = widget.initialState;
    _selectedCity = widget.initialCity;
  }

  void _onStateChanged(String? state) {
    setState(() {
      _selectedState = state;
      _selectedCity = null; // city reset
    });
    widget.onChanged(_selectedState, null);
  }

  void _onCityChanged(String? city) {
    setState(() => _selectedCity = city);
    widget.onChanged(_selectedState, city);
  }

  void _reset() {
    setState(() {
      _selectedState = null;
      _selectedCity = null;
    });
    widget.onChanged(null, null);
  }

  bool get _hasFilter =>
      _selectedState != null || _selectedCity != null;

  @override
  Widget build(BuildContext context) {
    final cities = LocationData.citiesFor(_selectedState);

    if (widget.compact) {
      return _buildCompact(cities);
    }
    return _buildStacked(cities);
  }

  Widget _buildCompact(List<String> cities) {
    return Row(
      children: [
        Expanded(child: _stateDropdown()),
        const SizedBox(width: 8),
        Expanded(
          child: _selectedState != null
              ? _cityDropdown(cities)
              : _disabledCityDrop(),
        ),
        if (_hasFilter) ...[
          const SizedBox(width: 8),
          _resetBtn(),
        ],
      ],
    );
  }

  Widget _buildStacked(List<String> cities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stateDropdown(),
        const SizedBox(height: 10),
        _selectedState != null
            ? _cityDropdown(cities)
            : _disabledCityDrop(),
        if (_hasFilter) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.clear, size: 14),
              label: const Text('Filter हटाएं',
                  style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600),
            ),
          ),
        ],
      ],
    );
  }

  Widget _stateDropdown() {
    return _StyledDropdown<String>(
      value: _selectedState,
      hint: '🗺️ राज्य चुनें',
      items: LocationData.states.map((s) {
        final emoji = LocationData.stateEmojis[s] ?? '📍';
        return DropdownMenuItem(
          value: s,
          child: Text('$emoji $s',
              style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      onChanged: _onStateChanged,
    );
  }

  Widget _cityDropdown(List<String> cities) {
    return _StyledDropdown<String>(
      value: _selectedCity,
      hint: '🏙️ शहर चुनें',
      items: cities
          .map((c) => DropdownMenuItem(
                value: c,
                child:
                    Text(c, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: _onCityChanged,
    );
  }

  Widget _disabledCityDrop() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Text('🏙️ ', style: TextStyle(fontSize: 13)),
          Text('शहर चुनें',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade400)),
          const Spacer(),
          Icon(Icons.keyboard_arrow_down,
              color: Colors.grey.shade300, size: 18),
        ],
      ),
    );
  }

  Widget _resetBtn() {
    return GestureDetector(
      onTap: _reset,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Text('✕',
            style:
                TextStyle(color: Colors.red, fontSize: 14)),
      ),
    );
  }
}

// ============================================================
// 2. Location Filter Bottom Sheet
// ============================================================
class LocationFilterSheet extends StatefulWidget {
  final String? initialState;
  final String? initialCity;
  final void Function(String? state, String? city) onApply;

  const LocationFilterSheet({
    Key? key,
    this.initialState,
    this.initialCity,
    required this.onApply,
  }) : super(key: key);

  /// Show this sheet
  static Future<void> show(
    BuildContext context, {
    String? initialState,
    String? initialCity,
    required void Function(String? state, String? city) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LocationFilterSheet(
        initialState: initialState,
        initialCity: initialCity,
        onApply: onApply,
      ),
    );
  }

  @override
  State<LocationFilterSheet> createState() =>
      _LocationFilterSheetState();
}

class _LocationFilterSheetState extends State<LocationFilterSheet> {
  String? _state;
  String? _city;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _city = widget.initialCity;
  }

  @override
  Widget build(BuildContext context) {
    final cities = LocationData.citiesFor(_state);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            '📍 Location से Filter करें',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 16),

          // State
          const Text('राज्य',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          const SizedBox(height: 6),
          _StyledDropdown<String>(
            value: _state,
            hint: '🗺️ राज्य चुनें',
            items: LocationData.states.map((s) {
              final emoji = LocationData.stateEmojis[s] ?? '📍';
              return DropdownMenuItem(
                value: s,
                child: Text('$emoji $s',
                    style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (v) => setState(() {
              _state = v;
              _city = null;
            }),
          ),

          const SizedBox(height: 14),

          // City
          const Text('शहर',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          const SizedBox(height: 6),

          if (_state != null && cities.isNotEmpty)
            _StyledDropdown<String>(
              value: _city,
              hint: '🏙️ शहर चुनें',
              items: cities
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c,
                            style:
                                const TextStyle(fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _city = v),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _state == null
                    ? 'पहले राज्य चुनें'
                    : 'इस राज्य में कोई शहर नहीं',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade400),
              ),
            ),

          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _state = null;
                      _city = null;
                    });
                    Navigator.pop(context);
                    widget.onApply(null, null);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onApply(_state, _city);
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(
                    _state == null
                        ? 'Apply करें'
                        : _city != null
                            ? '$_city Apply करें'
                            : '$_state Apply करें',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 3. Full Location Filter Screen (standalone)
// ============================================================
class LocationFilterScreen extends StatefulWidget {
  final String? initialState;
  final String? initialCity;

  const LocationFilterScreen(
      {Key? key, this.initialState, this.initialCity})
      : super(key: key);

  @override
  State<LocationFilterScreen> createState() =>
      _LocationFilterScreenState();
}

class _LocationFilterScreenState
    extends State<LocationFilterScreen> {
  String? _state;
  String? _city;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _city = widget.initialCity;
  }

  @override
  Widget build(BuildContext context) {
    final cities = LocationData.citiesFor(_state);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text('📍 Location चुनें',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          if (_state != null || _city != null)
            TextButton(
              onPressed: () =>
                  setState(() { _state = null; _city = null; }),
              child: const Text('Reset',
                  style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected summary card
            if (_state != null || _city != null)
              _buildSummaryCard(),
            if (_state != null || _city != null)
              const SizedBox(height: 16),

            // State grid
            const Text('📍 राज्य चुनें',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0))),
            const SizedBox(height: 10),
            _buildStateGrid(),

            // City list
            if (_state != null && cities.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '🏙️ ${LocationData.stateEmojis[_state] ?? ''} $_state के शहर',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildCityGrid(cities),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: (_state != null)
                  ? const Color(0xFF1565C0)
                  : Colors.grey.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _state == null
                ? null
                : () => Navigator.pop(context, {
                      'state': _state,
                      'city': _city,
                    }),
            icon: const Icon(Icons.search, size: 18),
            label: Text(
              _city != null
                  ? '$_city में ढूंढें'
                  : _state != null
                      ? '$_state में ढूंढें'
                      : 'राज्य चुनें',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF1565C0).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('📍', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _city != null
                  ? '$_city, $_state'
                  : _state ?? '',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() { _state = null; _city = null; }),
            child: const Icon(Icons.close,
                color: Color(0xFF1565C0), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStateGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: LocationData.states.length,
      itemBuilder: (_, i) {
        final state = LocationData.states[i];
        final emoji = LocationData.stateEmojis[state] ?? '📍';
        final active = _state == state;
        return GestureDetector(
          onTap: () => setState(() {
            _state = state;
            _city = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF1565C0)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active
                    ? const Color(0xFF1565C0)
                    : Colors.grey.shade300,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1565C0)
                            .withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Text(emoji,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state,
                    style: TextStyle(
                      fontSize: 13,
                      color: active ? Colors.white : Colors.black87,
                      fontWeight: active
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (active)
                  const Icon(Icons.check,
                      color: Colors.white, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCityGrid(List<String> cities) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cities.map((city) {
        final active = _city == city;
        return GestureDetector(
          onTap: () => setState(() => _city = active ? null : city),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF1565C0)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? const Color(0xFF1565C0)
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              city,
              style: TextStyle(
                fontSize: 13,
                color: active ? Colors.white : Colors.black87,
                fontWeight:
                    active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================
// Shared styled dropdown
// ============================================================
class _StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value != null
              ? const Color(0xFF1565C0).withOpacity(0.4)
              : Colors.grey.shade300,
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500)),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: value != null
                ? const Color(0xFF1565C0)
                : Colors.grey.shade400,
            size: 20,
          ),
          items: items,
          onChanged: onChanged,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
