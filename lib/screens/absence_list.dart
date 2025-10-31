import 'package:flutter/material.dart';
import '../api/api.dart';

class AbsenceList extends StatefulWidget {
  const AbsenceList({super.key});

  @override
  State<AbsenceList> createState() => _AbsenceListState();
}

class _AbsenceListState extends State<AbsenceList> {
  // Data
  List<dynamic> absencesList = [];
  Map<int, String> memberNames = {};

  // UI State
  bool isLoading = true;
  String? errorMessage;

  // Pagination
  int currentPage = 1;
  static const int itemsPerPage = 10;

  // Active Filters
  String? selectedType;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  // Temporary Filters (for modal)
  String? tempSelectedType;
  DateTime? tempStartDate;
  DateTime? tempEndDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final absencesData = await absences();
      final membersData = await members();

      final nameMap = <int, String>{};
      for (var member in membersData) {
        nameMap[member['userId']] = member['name'];
      }

      setState(() {
        absencesList = absencesData;
        memberNames = nameMap;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: $e';
        isLoading = false;
      });
    }
  }

  // Getters
  List<dynamic> get _filteredAbsences {
    return absencesList.where((absence) {
      // Filter by type
      if (selectedType != null &&
          absence['type']?.toLowerCase() != selectedType?.toLowerCase()) {
        return false;
      }

      // Filter by date range
      if (selectedStartDate != null || selectedEndDate != null) {
        final startDate = DateTime.tryParse(absence['startDate'] ?? '');
        final endDate = DateTime.tryParse(absence['endDate'] ?? '');

        if (startDate != null && endDate != null) {
          return _isAbsenceInDateRange(startDate, endDate);
        }
      }

      return true;
    }).toList();
  }

  List<dynamic> get _currentPageItems {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;

    if (startIndex >= _filteredAbsences.length) return [];

    return _filteredAbsences.sublist(
      startIndex,
      endIndex > _filteredAbsences.length ? _filteredAbsences.length : endIndex,
    );
  }

  int get _totalPages =>
      (_filteredAbsences.length / itemsPerPage).ceil().toInt();

  List<String> get _uniqueTypes {
    return absencesList
        .map((absence) => absence['type'] as String?)
        .where((type) => type != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  // Helper Methods
  bool _isAbsenceInDateRange(DateTime startDate, DateTime endDate) {
    if (selectedStartDate != null && selectedEndDate != null) {
      return !(endDate.isBefore(selectedStartDate!) ||
          startDate.isAfter(selectedEndDate!));
    } else if (selectedStartDate != null) {
      return !endDate.isBefore(selectedStartDate!);
    } else if (selectedEndDate != null) {
      return !startDate.isAfter(selectedEndDate!);
    }
    return true;
  }

  String _getAbsenceStatus(dynamic absence) {
    if (absence['confirmedAt'] != null) return 'Confirmed';
    if (absence['rejectedAt'] != null) return 'Rejected';
    return 'Requested';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _showFilterModal() {
    tempSelectedType = selectedType;
    tempStartDate = selectedStartDate;
    tempEndDate = selectedEndDate;

    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFilterModal(),
    );
  }

  void _applyFilters() {
    setState(() {
      selectedType = tempSelectedType;
      selectedStartDate = tempStartDate;
      selectedEndDate = tempEndDate;
      currentPage = 1;
    });
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      selectedType = null;
      selectedStartDate = null;
      selectedEndDate = null;
      tempSelectedType = null;
      tempStartDate = null;
      tempEndDate = null;
      currentPage = 1;
    });
    // Navigator.pop(context);
  }

  // Build Methods
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absences List')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredAbsences.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildFilterButton(),
        _buildTotalAbsencesContainer(),
        _buildAbsencesList(),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16.0),
          Text(
            'Loading absences...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48.0, color: Colors.red),
          const SizedBox(height: 16.0),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64.0,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16.0),
          Text(
            'No Absences Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'There are no absences matching your filters.\nTry adjusting your search criteria.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.filter_list),
                label: const Text('Adjust Filters'),
                onPressed: _showFilterModal,
              ),
              const SizedBox(width: 12.0),
              ElevatedButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('Reset Filters'),
                onPressed: _clearFilters,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.filter_list),
        label: const Text('Filter'),
        onPressed: _showFilterModal,
      ),
    );
  }

  Widget _buildTotalAbsencesContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Text(
        'Total Absences: ${_filteredAbsences.length}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildAbsencesList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _currentPageItems.length,
        itemBuilder: (context, index) {
          final absence = _currentPageItems[index];
          return _buildAbsenceCard(absence);
        },
      ),
    );
  }

  Widget _buildAbsenceCard(dynamic absence) {
    final memberName = memberNames[absence['userId']] ?? 'Unknown';
    final status = _getAbsenceStatus(absence);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAbsenceHeader(memberName),
            const SizedBox(height: 8.0),
            _buildAbsenceType(absence),
            const SizedBox(height: 8.0),
            _buildAbsencePeriod(absence),
            if (absence['memberNote'] != null &&
                absence['memberNote'].isNotEmpty) ...[
              const SizedBox(height: 8.0),
              _buildNote('Member Note', absence['memberNote']),
            ],
            if (absence['admitterNote'] != null &&
                absence['admitterNote'].isNotEmpty) ...[
              const SizedBox(height: 8.0),
              _buildNote('Admitter Note', absence['admitterNote']),
            ],
            const SizedBox(height: 8.0),
            _buildStatusRow(status),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenceHeader(String memberName) {
    return Text(
      memberName,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16.0,
      ),
    );
  }

  Widget _buildAbsenceType(dynamic absence) {
    return Text('Type: ${absence['type']?.toUpperCase() ?? 'Unknown'}');
  }

  Widget _buildAbsencePeriod(dynamic absence) {
    return Text(
      'Period: ${absence['startDate']} to ${absence['endDate']}',
    );
  }

  Widget _buildNote(String label, String note) {
    return Text('$label: $note');
  }

  Widget _buildStatusRow(String status) {
    return Row(
      children: [
        const Text('Status: '),
        Text(
          status,
          style: TextStyle(
            color: _getStatusColor(status),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
          ),
          Text('Page $currentPage of $_totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed:
                currentPage < _totalPages ? () => setState(() => currentPage++) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterModal() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              _buildTypeFilter(setModalState),
              const SizedBox(height: 16.0),
              _buildDateRangeFilter(setModalState),
              const SizedBox(height: 24.0),
              _buildFilterModalButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeFilter(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Type:'),
        DropdownButton<String>(
          isExpanded: true,
          hint: const Text('Select Type'),
          value: tempSelectedType,
          items: _uniqueTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            setModalState(() => tempSelectedType = value);
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date Range:'),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  tempStartDate == null
                      ? 'Start Date'
                      : tempStartDate.toString().split(' ')[0],
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: tempStartDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setModalState(() => tempStartDate = picked);
                  }
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  tempEndDate == null
                      ? 'End Date'
                      : tempEndDate.toString().split(' ')[0],
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: tempEndDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setModalState(() => tempEndDate = picked);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterModalButtons() {
    final hasActiveFilters =
        selectedType != null || selectedStartDate != null || selectedEndDate != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _applyFilters,
          child: const Text('Apply'),
        ),
        if (hasActiveFilters)
          ElevatedButton(
            onPressed: _clearFilters,
            child: const Text('Clear'),
          ),
      ],
    );
  }
}
