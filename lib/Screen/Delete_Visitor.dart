import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Database/db_helper.dart';
import 'dart:io';
import 'package:visitor_application/notifiers.dart';

const kPrimaryColor = Color(0xff856EE1);
const kBackgroundColor = Color(0xffF5F3FA);
const kBlackLight = Color(0xFF6F6F6F);
const kWhite = Color(0xFFFFFFFF);
const kBlack = Color(0xFF000000);
const kWhiteDarker = Color(0xFFE5E5E5);
const kPrimaryColorLight = Color(0xFFC655EE);
const kTransparent = Color(0x00FFFFFF);
const kInputBorder = Color(0xFFC4C4C4);
const kBlueSelected = Color(0xFFA0E2FF);

class DeleteDataPage extends StatefulWidget {
  const DeleteDataPage({super.key});

  @override
  State<DeleteDataPage> createState() => _DeleteDataPageState();
}

class _DeleteDataPageState extends State<DeleteDataPage> {
  DateTime? _fromDate;
  DateTime? _toDate;

  List<Map<String, dynamic>> _allData = []; // dummy data
  List<Map<String, dynamic>> _filteredData = [];

  final DateFormat _formatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _fromDate = DateTime.now().subtract(const Duration(days: 7)); // optional default
    _toDate = DateTime.now();
  }

  Future<void> _pickFromDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _fromDate = date);
  }

  Future<void> _pickToDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _toDate = date);
  }

  void _searchData() async {
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both dates')),
      );
      return;
    }

    final allVisitors = await DBHelper.instance.getFullListOfVisitor(); // get all
    final filtered = allVisitors.where((visitor) {
      final dateStr = visitor['in_date'] ?? '';
      try {
        final parts = dateStr.split('/');
        if (parts.length != 3) return false;
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final visitorDate = DateTime(year, month, day);

        return visitorDate.isAfter(_fromDate!.subtract(const Duration(days:1))) &&
            visitorDate.isBefore(_toDate!.add(const Duration(days:1)));
      } catch (_) {
        return false;
      }
    }).toList();

    // 🔥 ADD THIS SORT (IMPORTANT FIX)
    filtered.sort((a, b) {
      final da = _parseDate(a);
      final db = _parseDate(b);
      return db.compareTo(da); // latest first
    });

    setState(() {
      _filteredData = filtered;
    });

    if (_filteredData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data found for selected dates')),
      );
    }
  }

  DateTime _parseDate(Map<String, dynamic> v) {
    try {
      final dateStr = (v['in_date'] ?? '').replaceAll(' ', '');
      final timeStr = (v['in_time'] ?? '').replaceAll(' ', '');

      final parts = dateStr.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      int hour = 0;
      int minute = 0;

      if (timeStr.isNotEmpty) {
        final isPM = timeStr.toUpperCase().contains('PM');
        final clean = timeStr.replaceAll(RegExp(r'[APMapm]'), '');
        final hm = clean.split(':');

        hour = int.parse(hm[0]);
        minute = int.parse(hm[1]);

        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
      }

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return DateTime(1900);
    }
  }

  void _deleteData() async {
    if (_fromDate == null || _toDate == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete all records between the selected dates?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK',style: TextStyle(color: Colors.white),)),
        ],
      ),
    );

    if (confirm != true) return;

    final allVisitors = await DBHelper.instance.getFullListOfVisitor();
    int deletedCount = 0;

    for (var visitor in allVisitors) {
      final dateStr = visitor['in_date'] ?? '';
      try {
        final parts = dateStr.split('/');
        if (parts.length != 3) continue;
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final visitorDate = DateTime(year, month, day);

        if (visitorDate.isAfter(_fromDate!.subtract(const Duration(days:1))) &&
            visitorDate.isBefore(_toDate!.add(const Duration(days:1)))) {
          await DBHelper.instance.deleteVisitor(visitor['id'] as int);
          deletedCount++;
        }
      } catch (_) {
        continue;
      }
    }

    setState(() => _filteredData.clear());

    visitorsUpdated.value = !visitorsUpdated.value;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$deletedCount record(s) deleted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Data'),
        centerTitle: true,
        backgroundColor: kPrimaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== DATE PICKERS =====
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickFromDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'From Date',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _fromDate != null ? _formatter.format(_fromDate!) : '',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickToDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'To Date',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _toDate != null ? _formatter.format(_toDate!) : '',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ===== SEARCH / DELETE BUTTON =====
            // SizedBox(
            //   width: double.infinity,
            //   child: _filteredData.isEmpty
            //       ? ElevatedButton(
            //     onPressed: _searchData,
            //     child: const Text('Search',style: TextStyle(color: Colors.white, fontSize: 16),),
            //   )
            //       : ElevatedButton(
            //     style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            //     onPressed: _deleteData,
            //     child: const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 16),),
            //   ),
            // ),

            // ===== SEARCH / DELETE BUTTON =====
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _searchData,
                    child: const Text(
                      'Search',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  if (_filteredData.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: _deleteData,
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== DATA LIST =====
            Expanded(
              child: _filteredData.isEmpty
                  ? const Center(child: Text('No data'))
                  : ListView.builder(
                itemCount: _filteredData.length,
                itemBuilder: (context, index) {
                  final visitor = _filteredData[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: kWhite, // White card background
                    elevation: 3,
                    child: ListTile(
                      leading: visitor['visitor_photo_path'] != null
                          ? CircleAvatar(
                        backgroundImage:
                        FileImage(File(visitor['visitor_photo_path'])),
                        radius: 25,
                      )
                          : const CircleAvatar(
                        backgroundColor: kPrimaryColorLight,
                        child: Icon(Icons.person, color: kWhite),
                        radius: 25,
                      ),
                      title: Text(
                        visitor['name'] ?? 'No Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kBlack,
                        ),
                      ),
                      subtitle: Text(
                        '${visitor['company'] ?? 'No Company'}\nResident: ${visitor['meeting_person']}\nMobile Number: ${visitor['mobile'] ?? 'N/A'}\nPurpose: ${visitor['purpose'] ?? 'N/A'}'
                            '\nDate: ${visitor['in_date'] ?? 'N/A'} Time: ${visitor['in_time'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              )
            )
          ],
        ),
      ),
    );
  }
}