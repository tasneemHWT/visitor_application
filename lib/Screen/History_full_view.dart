import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Database/db_helper.dart';

// PURPLE THEME COLORS
const kPrimaryColor = Color(0xff856EE1);
const kPrimaryColorLight = Color(0xFFC655EE);
const kBackgroundColor = Color(0xffF5F3FA);
const kBlack = Color(0xFF000000);
const kBlackLight = Color(0xFF6F6F6F);
const kWhite = Color(0xFFFFFFFF);

class VisitorDetailHistoryPage extends StatelessWidget {
  final Map<String, dynamic> visitor;

  const VisitorDetailHistoryPage({super.key, required this.visitor});

  // DELETE VISITOR
  Future<void> _deleteVisitor(BuildContext context) async {
    final id = visitor['id'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Visitor'),
        content: const Text('Are you sure you want to delete this visitor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: kBlackLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.instance.deleteVisitor(id);
      if (!context.mounted) return;
      Navigator.pop(context, true); // Return true to refresh history list
    }
  }

  Map<String, String> getTiming(Map<String, dynamic> visitor) {
    final inDateStr = visitor['in_date'] ?? '';
    final inTimeStr = visitor['in_time'] ?? '';
    final outDateStr = visitor['out_date'] ?? '';
    final outTimeStr = visitor['out_time'] ?? '';

    String inDisplay = 'Not available';
    String outDisplay = 'Not exited';

    if (inDateStr.isNotEmpty && inTimeStr.isNotEmpty) {
      try {
        final inDateTime = DateTime.parse('$inDateStr ${inTimeStr.padLeft(5, '0')}');
        inDisplay = DateFormat('d/M/yyyy hh:mm a').format(inDateTime);
      } catch (_) {
        inDisplay = '$inDateStr $inTimeStr';
      }
    }

    if (outDateStr.isNotEmpty && outTimeStr.isNotEmpty) {
      try {
        final outDateTime = DateTime.parse('$outDateStr ${outTimeStr.padLeft(5, '0')}');
        outDisplay = DateFormat('d/M/yyyy hh:mm a').format(outDateTime);
      } catch (_) {
        outDisplay = '$outDateStr $outTimeStr';
      }
    }

    return {'in': inDisplay, 'out': outDisplay};
  }




  @override
  Widget build(BuildContext context) {
    final timing = getTiming(visitor);

    // Split ID photos into list
    final String idPhotoString = visitor['id_photo_path']?.toString() ?? '';
    final List<String> idPhotos = idPhotoString
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Visitor Details'),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.delete),
        //     onPressed: () => _deleteVisitor(context),
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visitor photo
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: kPrimaryColorLight.withOpacity(0.3),
                backgroundImage: visitor['visitor_photo_path'] != null
                    ? FileImage(File(visitor['visitor_photo_path']))
                    : null,
                child: visitor['visitor_photo_path'] == null
                    ? const Icon(Icons.person, size: 60, color: kWhite)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // Personal Info
            _infoCard(
              title: 'Personal Information',
              children: [
                _infoRow('Name', visitor['name']),
                _infoRow('Mobile', visitor['mobile']),
                _infoRow('Email', visitor['email']),
                _infoRow('Address', visitor['address']),
              ],
            ),

            // Visit Info
            _infoCard(
              title: 'Visit Information',
              children: [
                _infoRow('Company', visitor['company']),
                _infoRow('Meeting Person', visitor['meeting_person']),
                _infoRow('Purpose', visitor['purpose']),
                _infoRow('Vehicle', visitor['vehicle']),
              ],
            ),

            // Timing
            _infoCard(
              title: 'Timing',
              children: [
                _infoRow('In Time', timing['in']),
                _infoRow('Out Time', timing['out']),
              ],
            ),

            // ID Proof
            _infoCard(
              title: 'ID Proof',
              children: [
                _infoRow('ID Type', visitor['id_proof']),
                _infoRow('ID Number', visitor['id_number']),
                if (idPhotos.isNotEmpty) const SizedBox(height: 10),
                if (idPhotos.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: idPhotos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final path = idPhotos[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(path),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Card widget
  Widget _infoCard({required String title, required List<Widget> children}) {
    return Card(
      color: kWhite,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlack)),
            const Divider(thickness: 1.2, color: kPrimaryColorLight),
            ...children,
          ],
        ),
      ),
    );
  }

  // Info row widget
  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBlack),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: const TextStyle(fontSize: 16, color: kBlackLight),
            ),
          ),
        ],
      ),
    );
  }
}
