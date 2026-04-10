import 'dart:io';
import 'package:flutter/material.dart';
import '../Database/db_helper.dart';
import 'History_full_view.dart';
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


class VisitorHistoryPage extends StatefulWidget {
  const VisitorHistoryPage({super.key});

  @override
  State<VisitorHistoryPage> createState() => _VisitorHistoryPageState();
}

class _VisitorHistoryPageState extends State<VisitorHistoryPage> {
  List<Map<String, dynamic>> _visitors = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryVisitors();

    // Listen to changes
    visitorsUpdated.addListener(() {
      _loadHistoryVisitors(); // reload visitors whenever notifier changes
    });
  }

  @override
  void dispose() {
    visitorsUpdated.removeListener(() {}); // remove listener to avoid leaks
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadHistoryVisitors();
  }

  // Future<void> _loadHistoryVisitors() async {
  //   final data = await DBHelper.instance.getHistoryVisitors();
  //
  //   if (!mounted) return;
  //   setState(() {
  //     _visitors = data;
  //   });
  // }

  Future<void> _loadHistoryVisitors() async {
    final data = await DBHelper.instance.getHistoryVisitors();

    // ✅ Create a fully mutable copy
    final List<Map<String, dynamic>> sortedData =
    data.map((e) => Map<String, dynamic>.from(e)).toList();

    // ✅ Sort the mutable list
    sortedData.sort((a, b) {
      DateTime dateA = _parseDateTime(a);
      DateTime dateB = _parseDateTime(b);
      return dateB.compareTo(dateA); // latest first
    });

    if (!mounted) return;

    setState(() {
      _visitors = sortedData; // ✅ use sorted list
    });
  }

  DateTime _parseDateTime(Map<String, dynamic> visitor) {
    try {
      final rawDate = visitor['in_date'] ?? '';
      final rawTime = visitor['in_time'] ?? '';

      // ✅ REMOVE ALL SPACES
      final date = rawDate.replaceAll(' ', '');
      final time = rawTime.replaceAll(' ', '');

      final dateParts = date.split('/');
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);

      int hour = 0;
      int minute = 0;

      if (time.isNotEmpty) {
        final isPM = time.toUpperCase().contains('PM');
        final cleanTime = time.replaceAll(RegExp(r'[APMapm]'), '');

        final hm = cleanTime.split(':');
        hour = int.parse(hm[0]);
        minute = int.parse(hm[1]);

        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
      }

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      print("❌ Parse error: ${visitor['in_date']} ${visitor['in_time']}");
      return DateTime(1900);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_visitors.isEmpty) {
      return const Center(
        child: Text(
          'No History Found',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlack),
        ),
      );
    }

    return ListView.builder(
      itemCount: _visitors.length,
      itemBuilder: (context, index) {
        final visitor = _visitors[index];
        return Card(
          color: kWhite,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 3,
          child: ListTile(
            leading: visitor['visitor_photo_path'] != null
                ? CircleAvatar(
              backgroundImage: FileImage(File(visitor['visitor_photo_path'])),
              radius: 25,
            )
                : CircleAvatar(
              backgroundColor: kPrimaryColorLight.withOpacity(0.6),
              child: const Icon(Icons.person, color: kWhite),
              radius: 25,
            ),
            title: Text(
              visitor['name'] ?? 'No Name',
              style: const TextStyle(color: kBlack, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${visitor['company'] ?? 'No Company'}\nResident: ${visitor['meeting_person']}\nMobile Number: ${visitor['mobile'] ?? 'N/A'}\nPurpose: ${visitor['purpose'] ?? 'N/A'}'
                  '\nDate: ${visitor['in_date'] ?? 'N/A'} InTime: ${visitor['in_time'] ?? ''} OutTime: ${visitor['out_time']}',
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: kPrimaryColor),
            onTap: () async {
             final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      VisitorDetailHistoryPage(visitor: visitor),
                ),
              );

              if(result == true){ _loadHistoryVisitors();}
            },
          ),
        );
      },
    );
  }
}
