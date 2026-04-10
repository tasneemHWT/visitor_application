import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../Database/db_helper.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:csv/csv.dart';

const kPrimaryColor = Color(0xff856EE1);

class SendMailPage extends StatefulWidget {
  const SendMailPage({super.key});

  @override
  State<SendMailPage> createState() => _SendMailPageState();
}

class _SendMailPageState extends State<SendMailPage> {
  List<Map<String, dynamic>> visitors = [];
  bool isLoading = false;
  bool hasSearched = false;

  DateTime? _fromDate;
  DateTime? _toDate;

  final DateFormat _formatter = DateFormat('yyyy-MM-dd');


  int progress = 0;
  int total = 0;


  @override
  void initState() {
    super.initState();
    _fromDate = DateTime.now().subtract(const Duration(days: 7));
    _toDate = DateTime.now();
  }


  Future<Uint8List?> compressImage(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      final resized = img.copyResize(image, width: 400);

      return Uint8List.fromList(
        img.encodeJpg(resized, quality: 60),
      );
    } catch (e) {
      return null;
    }
  }


  Future<pw.Widget?> buildImage(String path) async {
    final bytes = await compressImage(path);
    if (bytes == null) return null;

    return pw.Image(
      pw.MemoryImage(bytes),
      width: 90,
      height: 90,
    );
  }



  // ✅ FETCH DATA
  // Future<void> fetchVisitors() async {
  //   final data = await DBHelper.instance.getFullListOfVisitor();
  //
  //   List<Map<String, dynamic>> filtered = data.where((visitor) {
  //     final dateStr = visitor['in_date'] ?? '';
  //     try {
  //       final parts = dateStr.split('/');
  //       final visitorDate = DateTime(
  //         int.parse(parts[2]),
  //         int.parse(parts[1]),
  //         int.parse(parts[0]),
  //       );
  //
  //       return visitorDate.isAfter(_fromDate!.subtract(const Duration(days: 1))) &&
  //           visitorDate.isBefore(_toDate!.add(const Duration(days: 1)));
  //     } catch (_) {
  //       return false;
  //     }
  //   }).toList();
  //
  //   setState(() {
  //     visitors = filtered;
  //     isLoading = false;
  //   });
  // }

  // ✅ DATE PICKERS

  Future<void> fetchVisitors() async {
    final data = await DBHelper.instance.getFullListOfVisitor();

    List<Map<String, dynamic>> filtered = data.where((visitor) {
      final dateStr = visitor['in_date'] ?? '';

      try {
        final parts = dateStr.split('/');

        final visitorDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );

        return visitorDate.isAfter(
          _fromDate!.subtract(const Duration(days: 1)),
        ) &&
            visitorDate.isBefore(
              _toDate!.add(const Duration(days: 1)),
            );
      } catch (_) {
        return false;
      }
    }).toList();

    // 🔥 ADD THIS SORT (CRITICAL FIX)
    filtered.sort((a, b) {
      final da = _parseDate(a);
      final db = _parseDate(b);
      return db.compareTo(da); // latest first
    });

    setState(() {
      visitors = filtered;
      isLoading = false;
    });
  }

  DateTime _parseDate(Map<String, dynamic> v) {
    final dateStr = v['in_date'] ?? '';
    final timeStr = v['in_time'] ?? '';

    try {
      final parts = dateStr.replaceAll(' ', '').split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      int hour = 0;
      int minute = 0;

      if (timeStr.isNotEmpty) {
        final t = timeStr.replaceAll(' ', '');
        final isPM = t.toUpperCase().contains('PM');
        final clean = t.replaceAll(RegExp(r'[APMapm]'), '');
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


  Future<void> _pickFromDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fromDate!,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _fromDate = date);
  }

  Future<void> _pickToDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _toDate!,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _toDate = date);
  }

  // ✅ BUTTON LOGIC
  // Future<void> handleMainButton() async {
  //   if (!hasSearched || visitors.isEmpty) {
  //     setState(() {
  //       isLoading = true;
  //       hasSearched = true;
  //     });
  //
  //     await fetchVisitors();
  //
  //     if (visitors.isEmpty) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('No data found')),
  //       );
  //     }
  //   } else {
  //     await generateAndShare();
  //   }
  // }

  // ✅ SAFE DIRECTORY (IMPORTANT FIX)

  // Future<void> handleMainButton({bool? includeImages}) async {
  //   if (!hasSearched || visitors.isEmpty) {
  //     setState(() {
  //       isLoading = true;
  //       hasSearched = true;
  //     });
  //
  //     await fetchVisitors();
  //
  //     setState(() => isLoading = false);
  //
  //     if (visitors.isEmpty) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('No data found')),
  //       );
  //       return;
  //     }
  //   } else {
  //     // Only called when sharing buttons are pressed
  //     if (includeImages != null) {
  //       setState(() => isLoading = true);
  //       final pdfPath = await createPDF(includeImages: includeImages);
  //       setState(() => isLoading = false);
  //
  //       if (pdfPath != null) {
  //         await Share.shareXFiles(
  //           [XFile(pdfPath, mimeType: 'application/pdf')],
  //           text: 'Visitor Report',
  //         );
  //       }
  //     }
  //   }
  // }

  // Future<void> handleMainButton({bool? withImages}) async {
  //   // 🔍 First time → SEARCH
  //   if (!hasSearched) {
  //     setState(() {
  //       isLoading = true;
  //       hasSearched = true;
  //     });
  //
  //     await fetchVisitors();
  //
  //     setState(() => isLoading = false);
  //
  //     if (visitors.isEmpty) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('No data found')),
  //       );
  //     }
  //     return;
  //   }
  //
  //   // 📤 After search → SHARE
  //   if (withImages == null) return; // safety
  //
  //   setState(() => isLoading = true);
  //
  //   String? filePath;
  //
  //   if (withImages) {
  //     // ✅ SHARE WITH IMAGES → PDF
  //     filePath = await createPDF(includeImages: true);
  //   } else {
  //     // ✅ SHARE WITHOUT IMAGES → CSV
  //     filePath = await createCSV();
  //   }
  //
  //   setState(() => isLoading = false);
  //
  //   if (filePath != null) {
  //     await Share.shareXFiles([
  //       XFile(filePath),
  //     ]);
  //   }
  // }

  Future<void> handleMainButton({bool? withImages}) async {
    // 🔍 ALWAYS SEARCH when button pressed without parameter
    if (withImages == null) {
      setState(() {
        isLoading = true;
        hasSearched = true;
      });

      await fetchVisitors();

      setState(() => isLoading = false);

      if (visitors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data found')),
        );
      }
      return;
    }

    // 📤 SHARE LOGIC
    setState(() => isLoading = true);

    String? filePath;

    if (withImages) {
      filePath = await createPDF(includeImages: true);
    } else {
      filePath = await createCSV();
    }

    setState(() => isLoading = false);

    if (filePath != null) {
      await Share.shareXFiles([XFile(filePath)]);
    }
  }

  Future<Directory?> getReportsDirectory() async {
    final dir = await getTemporaryDirectory();
    final reportsDir = Directory('${dir.path}/Reports');

    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    return reportsDir;
  }


  Future<String?> createCSV() async {
    final dir = await getReportsDirectory();
    if (dir == null) return null;

    progress = 0;
    total = visitors.length;

    List<List<dynamic>> rows = [];

    rows.add([
      'Sr No',
      'Name',
      'Mobile',
      'Email',
      'Address',
      'Company',
      'Meeting Person',
      'ID Proof',
      'ID Number',
      'In Date',
      'Out Date',
      'In Time',
      'Out Time',
      'Vehicle',
      'Purpose',
    ]);

    for (int i = 0; i < visitors.length; i++) {
      final v = visitors[i];

      rows.add([
        i + 1,
        v['name'] ?? '',
        v['mobile'] ?? '',
        v['email'] ?? '',
        v['address'] ?? '',
        v['company'] ?? '',
        v['meeting_person'] ?? '',
        v['id_proof'] ?? '',
        v['id_number'] ?? '',
        v['in_date'] ?? '',
        v['out_date'] ?? '',
        v['in_time'] ?? '',
        v['out_time'] ?? '',
        v['vehicle'] ?? '',
        v['purpose'] ?? '',
      ]);

      progress++;
      setState(() {});
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final path = '${dir.path}/visitor_report.csv';
    await File(path).writeAsString(csvData);

    return path;
  }


  // Future<String?> createPDF() async {
  //   final dir = await getReportsDirectory();
  //   if (dir == null) return null;
  //
  //   final pdf = pw.Document();
  //
  //   progress = 0;
  //   total = visitors.length;
  //
  //   List<pw.Widget> allWidgets = [];
  //
  //   // 🔹 Title (only once)
  //   allWidgets.add(
  //     pw.Text(
  //       'Visitor Report',
  //       style: pw.TextStyle(
  //         fontSize: 20,
  //         fontWeight: pw.FontWeight.bold,
  //       ),
  //     ),
  //   );
  //   allWidgets.add(pw.SizedBox(height: 12));
  //
  //   // 🔹 Compact visitor card row
  //   for (int i = 0; i < visitors.length; i++) {
  //     final v = visitors[i];
  //
  //     await Future.delayed(const Duration(milliseconds: 5));
  //
  //     // 🔹 Images
  //     final visitorImage = await buildImage(v['visitor_photo_path'] ?? '');
  //
  //     List<pw.Widget> idImages = [];
  //     final idPhotos = v['id_photo_path'];
  //     if (idPhotos != null && idPhotos != 'null') {
  //       final paths = idPhotos.contains(',')
  //           ? idPhotos.split(',').map((e) => e.trim()).toList()
  //           : [idPhotos.trim()];
  //
  //       for (var path in paths) {
  //         if (path.isEmpty) continue;
  //         final imgWidget = await buildImage(path);
  //         if (imgWidget != null) idImages.add(imgWidget);
  //       }
  //     }
  //
  //     // 🔹 Visitor card layout
  //     final visitorCard = pw.Container(
  //       margin: const pw.EdgeInsets.only(bottom: 6),
  //       padding: const pw.EdgeInsets.all(6),
  //       decoration: pw.BoxDecoration(
  //         border: pw.Border.all(width: 0.3),
  //       ),
  //       child: pw.Row(
  //         crossAxisAlignment: pw.CrossAxisAlignment.start,
  //         children: [
  //           // Visitor photo
  //           if (visitorImage != null)
  //             pw.Container(
  //               margin: const pw.EdgeInsets.only(right: 6),
  //               child: visitorImage,
  //             ),
  //
  //           // Details column
  //           pw.Expanded(
  //             child: pw.Column(
  //               crossAxisAlignment: pw.CrossAxisAlignment.start,
  //               children: [
  //                 pw.Text(v['name'] ?? '',
  //                     style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
  //                 pw.Text('Mobile: ${v['mobile'] ?? ''}'),
  //                 pw.Text('Email: ${v['email'] ?? ''}'),
  //                 pw.Text('Address: ${v['address'] ?? ''}'),
  //                 pw.Text('Company: ${v['company'] ?? ''}'),
  //                 pw.Text('Meeting Person: ${v['meeting_person'] ?? ''}'),
  //                 pw.Text('ID Proof: ${v['id_proof'] ?? ''}'),
  //                 pw.Text('ID Number: ${v['id_number'] ?? ''}'),
  //                 pw.Text('In Date: ${v['in_date'] ?? ''}'),
  //                 pw.Text('Out Date: ${v['out_date'] ?? ''}'),
  //                 pw.Text('In Time: ${v['in_time'] ?? ''}'),
  //                 pw.Text('Out Time: ${v['out_time'] ?? ''}'),
  //                 pw.Text('Vehicle: ${v['vehicle'] ?? ''}'),
  //                 pw.Text('Purpose: ${v['purpose'] ?? ''}'),
  //
  //                 if (idImages.isNotEmpty) pw.SizedBox(height: 4),
  //                 if (idImages.isNotEmpty)
  //                   pw.Wrap(
  //                     spacing: 4,
  //                     runSpacing: 4,
  //                     children: idImages,
  //                   ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //
  //     allWidgets.add(visitorCard);
  //
  //     // Progress update
  //     progress++;
  //     setState(() {});
  //   }
  //
  //   pdf.addPage(
  //     pw.MultiPage(
  //       build: (context) => allWidgets,
  //       pageFormat: PdfPageFormat.a4,
  //       margin: const pw.EdgeInsets.all(12),
  //     ),
  //   );
  //
  //   final path = '${dir.path}/visitor_report.pdf';
  //   await File(path).writeAsBytes(await pdf.save());
  //
  //   return path;
  // }

  Future<String?> createPDF({bool includeImages = true}) async {
    final dir = await getReportsDirectory();
    if (dir == null) return null;

    final pdf = pw.Document();
    progress = 0;
    total = visitors.length;

    List<pw.Widget> allWidgets = [];

    // Title
    allWidgets.add(
      pw.Text(
        'Visitor Report',
        style: pw.TextStyle(
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
    allWidgets.add(pw.SizedBox(height: 12));

    if (includeImages) {
      // 🔹 Original layout with images
      for (int i = 0; i < visitors.length; i++) {
        final v = visitors[i];
        await Future.delayed(const Duration(milliseconds: 5));

        final visitorImage = await buildImage(v['visitor_photo_path'] ?? '');
        List<pw.Widget> idImages = [];
        final idPhotos = v['id_photo_path'];
        if (idPhotos != null && idPhotos != 'null') {
          final paths = idPhotos.contains(',')
              ? idPhotos.split(',').map((e) => e.trim()).toList()
              : [idPhotos.trim()];
          for (var path in paths) {
            if (path.isEmpty) continue;
            final imgWidget = await buildImage(path);
            if (imgWidget != null) idImages.add(imgWidget);
          }
        }

        final visitorCard = pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.3),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (visitorImage != null)
                pw.Container(
                  margin: const pw.EdgeInsets.only(right: 6),
                  child: visitorImage,
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(v['name'] ?? '',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Mobile: ${v['mobile'] ?? ''}'),
                    pw.Text('Email: ${v['email'] ?? ''}'),
                    pw.Text('Address: ${v['address'] ?? ''}'),
                    pw.Text('Company: ${v['company'] ?? ''}'),
                    pw.Text('Meeting Person: ${v['meeting_person'] ?? ''}'),
                    pw.Text('ID Proof: ${v['id_proof'] ?? ''}'),
                    pw.Text('ID Number: ${v['id_number'] ?? ''}'),
                    pw.Text('In Date: ${v['in_date'] ?? ''}'),
                    pw.Text('Out Date: ${v['out_date'] ?? ''}'),
                    pw.Text('In Time: ${v['in_time'] ?? ''}'),
                    pw.Text('Out Time: ${v['out_time'] ?? ''}'),
                    pw.Text('Vehicle: ${v['vehicle'] ?? ''}'),
                    pw.Text('Purpose: ${v['purpose'] ?? ''}'),
                    if (idImages.isNotEmpty) pw.SizedBox(height: 4),
                    if (idImages.isNotEmpty)
                      pw.Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: idImages,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

        allWidgets.add(visitorCard);

        progress++;
        setState(() {});
      }
    } else {
      // ❌ Without images → table format
      final headers = [
        'Sr No',
        'Name',
        'Mobile',
        'Email',
        'Address',
        'Company',
        'Meeting Person',
        'ID Proof',
        'ID Number',
        'In Date',
        'Out Date',
        'In Time',
        'Out Time',
        'Vehicle',
        'Purpose',
      ];

      final dataRows = <List<String>>[];

      for (int i = 0; i < visitors.length; i++) {
        final v = visitors[i];
        dataRows.add([
          (i + 1).toString(),
          v['name'] ?? '',
          v['mobile'] ?? '',
          v['email'] ?? '',
          v['address'] ?? '',
          v['company'] ?? '',
          v['meeting_person'] ?? '',
          v['id_proof'] ?? '',
          v['id_number'] ?? '',
          v['in_date'] ?? '',
          v['out_date'] ?? '',
          v['in_time'] ?? '',
          v['out_time'] ?? '',
          v['vehicle'] ?? '',
          v['purpose'] ?? '',
        ]);

        progress++;
        setState(() {});
      }

      allWidgets.add(
        pw.Table.fromTextArray(
          headers: headers,
          data: dataRows,
          border: pw.TableBorder.all(width: 0.5),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(color: PdfColors.blue300),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          columnWidths: {
            0: const pw.FixedColumnWidth(30), // Sr No
            1: const pw.FixedColumnWidth(80), // Name
            // Rest can auto
          },
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        build: (context) => allWidgets,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(12),
      ),
    );

    final path = '${dir.path}/visitor_report.pdf';
    await File(path).writeAsBytes(await pdf.save());

    return path;
  }

  Future<void> generateAndShare() async {
    setState(() => isLoading = true);

    final pdf = await createPDF();

    setState(() => isLoading = false);

    if (pdf != null) {
      await Share.shareXFiles(
        [
          XFile(pdf, mimeType: 'application/pdf'),
        ],
        text: 'Visitor Report',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReadyToShare = hasSearched && visitors.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Reports'),
        centerTitle: true,
        backgroundColor: kPrimaryColor,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // DATE PICKERS
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickFromDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'From Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_formatter.format(_fromDate!)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickToDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'To Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_formatter.format(_toDate!)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   child: hasSearched && visitors.isNotEmpty
              //       ? Row(
              //     children: [
              //       Expanded(
              //         child: ElevatedButton(
              //           style: ElevatedButton.styleFrom(
              //             backgroundColor: kPrimaryColor,
              //             padding: const EdgeInsets.symmetric(vertical: 14),
              //             shape: RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(10),
              //             ),
              //           ),
              //           onPressed: () => handleMainButton(withImages: true), // ✅ FIX
              //           child: const Text(
              //             'Share With Images',
              //             style: TextStyle(color: Colors.white),
              //           ),
              //         ),
              //       ),
              //       const SizedBox(width: 12),
              //       Expanded(
              //         child: ElevatedButton(
              //           style: ElevatedButton.styleFrom(
              //             backgroundColor: kPrimaryColor,
              //             padding: const EdgeInsets.symmetric(vertical: 14),
              //             shape: RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(10),
              //             ),
              //           ),
              //           onPressed: () => handleMainButton(withImages: false), // ✅ FIX
              //           child: const Text(
              //             'Share Without Images',
              //             style: TextStyle(color: Colors.white),
              //           ),
              //         ),
              //       ),
              //     ],
              //   )
              //       : SizedBox(
              //     width: double.infinity,
              //     child: ElevatedButton(
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: kPrimaryColor,
              //         padding: const EdgeInsets.symmetric(vertical: 14),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(10),
              //         ),
              //       ),
              //       onPressed: () => handleMainButton(), // ✅ FIX (no param)
              //       child: const Text(
              //         'Search',
              //         style: TextStyle(color: Colors.white),
              //       ),
              //     ),
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // ✅ ALWAYS VISIBLE SEARCH BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => handleMainButton(), // search
                        child: const Text(
                          'Search',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ✅ SHOW SHARE BUTTONS ONLY AFTER SEARCH
                    if (hasSearched && visitors.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => handleMainButton(withImages: true),
                              child: const Text(
                                'Share With Images',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => handleMainButton(withImages: false),
                              child: const Text(
                                'Share Without Images',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // LIST
              Expanded(
                child: !hasSearched
                    ? const Center(child: Text('Select date and press Search'))
                    : visitors.isEmpty
                    ? const Center(child: Text('No data found'))
                    : ListView.builder(
                  itemCount: visitors.length,
                  itemBuilder: (_, index) {
                    final item = visitors[index];
                    final imagePath = item['visitor_photo_path'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: imagePath.isNotEmpty && File(imagePath).existsSync()
                            ? Image.file(File(imagePath), width: 50, fit: BoxFit.cover)
                            : const Icon(Icons.person),
                        title: Text(item['name'] ?? ''),
                        subtitle: Text(
                          '${item['company'] ?? 'No Company'}\nResident: ${item['meeting_person']}\nMobile Number: ${item['mobile'] ?? 'N/A'}\nPurpose: ${item['purpose'] ?? 'N/A'}'
                              '\nDate: ${item['in_date'] ?? 'N/A'} In Time: ${item['in_time'] ?? ''} '
                              '\nOut Time: ${item['out_time']}',
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // if (isLoading)
          //   Container(
          //     color: Colors.black26,
          //     child: const Center(child: CircularProgressIndicator()),
          //   ),

          if (isLoading)
            Container(
              color: Colors.black26,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      total == 0
                          ? 'Preparing...'
                          : 'Generating $progress / $total',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}