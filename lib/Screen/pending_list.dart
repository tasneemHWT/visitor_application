import 'dart:io';
import 'package:flutter/material.dart';
import '../Database/db_helper.dart';
import 'package:visitor_application/Screen/Pending_full_view.dart';
import 'package:visitor_application/constants.dart';


class VisitorList extends StatefulWidget {
  const VisitorList({super.key});

  @override
  State<VisitorList> createState() => _VisitorListState();
}

class _VisitorListState extends State<VisitorList> {
  List<Map<String, dynamic>> _visitors = [];

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    final data = await DBHelper.instance.getVisitors();
    if (!mounted) return;
    setState(() {
      _visitors = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_visitors.isEmpty) {
      return const Center(
        child: Text(
          'No Visitors Found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _visitors.length,
      itemBuilder: (context, index) {
        final visitor = _visitors[index];
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
              '${visitor['company'] ?? 'No Company'}\nDate: ${visitor['in_date'] ?? 'N/A'} Time: ${visitor['in_time'] ?? ''}',
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: kPrimaryColor),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VisitorDetailPage(visitor: visitor),
                ),
              );

              if (result == true) {
                _loadVisitors();
              }
            },
          ),
        );
      },
    );
  }
}
