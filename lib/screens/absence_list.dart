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
  
  // Add pagination variables
  int currentPage = 1;
  final int itemsPerPage = 10;

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

  // Add method to get current page items
  List<dynamic> get _currentPageItems {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    if (startIndex >= absencesList.length) return [];
    return absencesList.sublist(
      startIndex,
      endIndex > absencesList.length ? absencesList.length : endIndex,
    );
  }

  // Add method to calculate total pages
  int get _totalPages => (absencesList.length / itemsPerPage).ceil();

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
                        Expanded(
                          child: ListView.builder(
                            itemCount: _currentPageItems.length,
                            itemBuilder: (context, index) {
                              final absence = _currentPageItems[index];
                              final memberName = memberNames[absence['userId']] ?? 'Unknown';
                              
                              return ListTile(
                                title: Text(memberName),
                                subtitle: Text(
                                  '${absence['type']?.toUpperCase() ?? 'Unknown'} - ${absence['startDate']} to ${absence['endDate']}',
                                ),
                                trailing: Text(
                                  absence['confirmedAt'] != null ? 'Approved' : 'Pending',     
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