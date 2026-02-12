import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Database/db_helper.dart';
import 'package:visitor_application/constants.dart';

class VisitorDetailPage extends StatefulWidget {
  final Map<String, dynamic> visitor;

  const VisitorDetailPage({super.key, required this.visitor});

  @override
  State<VisitorDetailPage> createState() => _VisitorDetailPageState();
}

class _VisitorDetailPageState extends State<VisitorDetailPage> {
  late DateTime _selectedDate;
  late String _outTime;
  late TimeOfDay _outPickedTime; // Add this

  @override
  void initState() {
    super.initState();

    // Parse date string or use today if null
    final dateStr = widget.visitor['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    _selectedDate = DateTime.tryParse(dateStr) ?? DateTime.now();

    // Parse out_time string ("HH:mm") or use current time
    if (widget.visitor['out_time'] != null && widget.visitor['out_time'].contains(':')) {
      final parts = widget.visitor['out_time'].split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      _outPickedTime = TimeOfDay(hour: hour, minute: minute);
    } else {
      _outPickedTime = TimeOfDay.now();
    }
  }

  String get formattedOutTime {
    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _outPickedTime.hour,
      _outPickedTime.minute,
    );
    return DateFormat('hh:mm a').format(dt);
  }


  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickOutTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _outPickedTime,
    );

    if (picked != null) {
      setState(() {
        _outPickedTime = picked;
      });
    }
  }

  Future<void> _submitExit() async {
    final dateStr = DateFormat('d/M/yyyy').format(_selectedDate);

    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _outPickedTime.hour,
      _outPickedTime.minute,
    );

    final timeStr = DateFormat('h:mm a').format(dt); // 4:08 PM

    await DBHelper.instance.updateOutTime(
      widget.visitor['id'],
      dateStr,
      timeStr,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }



  Future<void> _deleteVisitor() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Visitor'),
        content: const Text('Are you sure you want to delete this visitor?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.instance.deleteVisitor(widget.visitor['id']);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitor = widget.visitor;
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
        //   IconButton(icon: const Icon(Icons.delete), onPressed: _deleteVisitor),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: visitor['visitor_photo_path'] != null
                    ? FileImage(File(visitor['visitor_photo_path']))
                    : null,
                backgroundColor: kPrimaryColorLight,
                child: visitor['visitor_photo_path'] == null
                    ? const Icon(Icons.person, size: 60, color: kWhite)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            _infoCard(
              title: 'Personal Information',
              children: [
                _infoRow('Name', visitor['name']),
                _infoRow('Mobile', visitor['mobile']),
                _infoRow('Email', visitor['email']),
                _infoRow('Address', visitor['address']),
              ],
            ),

            _infoCard(
              title: 'Visit Information',
              children: [
                _infoRow('Company', visitor['company']),
                _infoRow('Meeting Person', visitor['meeting_person']),
                _infoRow('Purpose', visitor['purpose']),
                _infoRow('Vehicle', visitor['vehicle']),
              ],
            ),

            _infoCard(
              title: 'Timing',
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: _infoRow(
                    'Date',
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    editable: true,
                  ),
                ),
                const SizedBox(height: 8),
                _infoRow('In Time', visitor['in_time']),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 130,
                      child: Text(
                        'Out Time:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickOutTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: kPrimaryColorLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kPrimaryColor, width: 1.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formattedOutTime,
                                style: const TextStyle(fontSize: 16, color: kPrimaryColor),
                              ),
                              const Icon(Icons.edit, size: 18, color: kPrimaryColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            _infoCard(
              title: 'ID Proof',
              children: [
                _infoRow('ID Type', visitor['id_proof']),
                _infoRow('ID Number', visitor['id_number']),
                const SizedBox(height: 10),
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

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Submit Exit', style: TextStyle(color: kWhite)),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlack)),
            const Divider(thickness: 1.2),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value, {bool editable = false}) {
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
              style: TextStyle(
                fontSize: 16,
                color: editable ? kPrimaryColor : kBlackLight,
                fontWeight: editable ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
