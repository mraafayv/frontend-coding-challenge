import 'package:flutter/material.dart';
import '../api/api.dart'; // Import the API file

class AbsenceList extends StatefulWidget {
  const AbsenceList({super.key});

  @override
  _AbsenceListState createState() => _AbsenceListState();
}

class _AbsenceListState extends State<AbsenceList> {
  List<dynamic> absencesList = [];
  Map<int, String> memberNames = {}; // Map userId to member name
  bool isLoading = true;
  String? errorMessage;

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
                  : ListView.builder(
                      itemCount: absencesList.length,
                      itemBuilder: (context, index) {
                        final absence = absencesList[index];
                        
                        // Filter out entries with only userId
                        if (absence['id'] == null) {
                          return const SizedBox.shrink();
                        }
                        
                        // Get the member name from the map
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
    );
  }
}