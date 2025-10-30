import 'package:flutter/material.dart';
import '../api/api.dart';

class AbsenceList extends StatefulWidget {
  const AbsenceList({super.key});

  @override
  _AbsenceListState createState() => _AbsenceListState();
}

class _AbsenceListState extends State<AbsenceList> {
  List<dynamic> absencesList = [];
  Map<int, String> memberNames = {};
  bool isLoading = true;
  String? errorMessage;

  int currentPage = 1;
  final int itemsPerPage = 10;

  // Temporary filter variables for modal
  String? tempSelectedType;
  DateTime? tempStartDate;
  DateTime? tempEndDate;

  // Active filter variables
  String? selectedType;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load both absences and members
      final absencesData = await absences();
      final membersData = await members();

      // Create a map of userId to member name
      Map<int, String> nameMap = {};
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

  List<dynamic> get _filteredAbsences {
    return absencesList.where((absence) {
      if (selectedType != null &&
          absence['type']?.toLowerCase() != selectedType?.toLowerCase()) {
        return false;
      }

      if (selectedStartDate != null || selectedEndDate != null) {
        final startDate = DateTime.tryParse(absence['startDate'] ?? '');
        final endDate = DateTime.tryParse(absence['endDate'] ?? '');
        if (startDate != null && endDate != null) {
          if (selectedStartDate != null && selectedEndDate != null) {
            // Check if absence falls within selected range
            if (endDate.isBefore(selectedStartDate!) ||
                startDate.isAfter(selectedEndDate!)) {
              return false;
            }
          } else if (selectedStartDate != null) {
            if (endDate.isBefore(selectedStartDate!)) {
              return false;
            }
          } else if (selectedEndDate != null) {
            if (startDate.isAfter(selectedEndDate!)) {
              return false;
            }
          }
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

  int get _totalPages => (_filteredAbsences.length / itemsPerPage).ceil();

  List<String> get _uniqueTypes {
    final types = absencesList
        .map((absence) => absence['type'] as String?)
        .where((type) => type != null)
        .cast<String>()
        .toSet()
        .toList();
    return types;
  }

  void _showFilterModal() {
    tempSelectedType = selectedType;
    tempStartDate = selectedStartDate;
    tempEndDate = selectedEndDate;

    showModalBottomSheet(
      context: context,
      builder: (context) {
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
                  
                  // Type filter
                  const Text('Type:'),
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select Type'),
                    value: tempSelectedType,
                    items: _uniqueTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        tempSelectedType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Date range filter
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
                              setModalState(() {
                                tempStartDate = picked;
                              });
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
                              setModalState(() {
                                tempEndDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedType = tempSelectedType;
                            selectedStartDate = tempStartDate;
                            selectedEndDate = tempEndDate;
                            currentPage = 1;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                      if (selectedType != null || selectedStartDate != null || selectedEndDate != null)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedType = null;
                              selectedStartDate = null;
                              selectedEndDate = null;
                              tempSelectedType = null;
                              tempStartDate = null;
                              tempEndDate = null;
                              currentPage = 1;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absences List')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : absencesList.isEmpty
                  ? const Center(child: Text('No absences found'))
                  : Column(
                      children: [
                        // Filter button
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.filter_list),
                            label: const Text('Filter'),
                            onPressed: _showFilterModal,
                          ),
                        ),
                        
                        // Total absences
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(
                            'Total Absences: ${_filteredAbsences.length}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        
                        Expanded(
                          child: ListView.builder(
                            itemCount: _currentPageItems.length,
                            itemBuilder: (context, index) {
                              final absence = _currentPageItems[index];
                              final memberName =
                                  memberNames[absence['userId']] ?? 'Unknown';

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        memberName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        'Type: ${absence['type']?.toUpperCase() ?? 'Unknown'}',
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        'Period: ${absence['startDate']} to ${absence['endDate']}',
                                      ),
                                      const SizedBox(height: 8.0),
                                      if (absence['memberNote'] != null &&
                                          absence['memberNote'].isNotEmpty)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Member Note: ${absence['memberNote']}',
                                            ),
                                            const SizedBox(height: 8.0),
                                          ],
                                        ),
                                      if (absence['admitterNote'] != null &&
                                          absence['admitterNote'].isNotEmpty)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Admitter Note: ${absence['admitterNote']}',
                                            ),
                                            const SizedBox(height: 8.0),
                                          ],
                                        ),
                                      Row(
                                        children: [
                                          const Text('Status: '),
                                          Text(
                                            absence['confirmedAt'] != null
                                                ? 'Confirmed'
                                                : absence['rejectedAt'] != null
                                                ? 'Rejected'
                                                : 'Requested',
                                            style: TextStyle(
                                              color: absence['confirmedAt'] != null
                                                  ? Colors.green
                                                  : absence['rejectedAt'] != null
                                                  ? Colors.red
                                                  : Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: currentPage > 1
                                    ? () => setState(() => currentPage--)
                                    : null,
                              ),
                              Text('Page $currentPage of $_totalPages'),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: currentPage < _totalPages
                                    ? () => setState(() => currentPage++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
