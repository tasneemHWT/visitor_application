import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:visitor_application/Screen/mail_configuration.dart';
import '../Database/db_helper.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:visitor_application/notifiers.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

class SendMailPage extends StatefulWidget {
  const SendMailPage({super.key});

  @override
  State<SendMailPage> createState() => _SendMailPageState();
}

class _SendMailPageState extends State<SendMailPage> {
  List<Map<String, dynamic>> visitors = [];
  bool isLoading = true;

  // TODO: Replace with your SMTP credentials
  final String smtpEmail = globalMailConfig.fromMail;//'test.hwspl@gmail.com';
  final String smtpAppPassword = globalMailConfig.appPassword;//'vbgr wlih qkrr fcvw'; // 16-char app password

  @override
  void initState() {
    super.initState();
    fetchVisitors();
  }

  Future<void> fetchVisitors() async {
    try {
      final data = await DBHelper.instance.getFullListOfVisitor();
      setState(() {
        visitors = data;
        isLoading = false;
      });
    } catch (e) {
      await _showAlert('Failed to fetch visitors: $e');
    }
  }


  // Future<File?> compressImage(String path) async {
  //   final dir = await getTemporaryDirectory();
  //   final fileName = path.split('/').last;
  //   final timestamp = DateTime.now().millisecondsSinceEpoch;
  //   final targetPath = '${dir.path}/${timestamp}_$fileName'; // unique temp path
  //
  //   final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
  //     path,
  //     targetPath,
  //     quality: 60,
  //     format: CompressFormat.png, // keep original format
  //   );
  //
  //   if (compressedXFile == null) return null;
  //   return File(compressedXFile.path);
  // }
  //
  // Future<String> createPhotosZip() async {
  //
  //   final dir = await getApplicationDocumentsDirectory();
  //   final zipPath =
  //       '${dir.path}/visitor_photos_${DateTime.now().millisecondsSinceEpoch}.zip';
  //
  //   final encoder = ZipFileEncoder();
  //
  //   // 🔥 IMPORTANT: level 0 = fastest (no recompression)
  //   encoder.create(zipPath, level: 0);
  //
  //   for (var visitor in visitors) {
  //     // -------- Visitor Photo --------
  //     final visitorPhotoPath = visitor['visitor_photo_path'];
  //     if (visitorPhotoPath != null &&
  //         visitorPhotoPath.isNotEmpty &&
  //         visitorPhotoPath != 'null') {
  //
  //       final originalFile = File(visitorPhotoPath.trim());
  //
  //       if (await originalFile.exists()) {
  //         final compressedFile =
  //         await compressImage(originalFile.path);
  //
  //         if (compressedFile != null &&
  //             await compressedFile.exists()) {
  //
  //           encoder.addFile(compressedFile);
  //           print('Added compressed visitor photo');
  //         }
  //       }
  //     }
  //
  //     // -------- ID Photos --------
  //     final idPhotoPaths = visitor['id_photo_path'];
  //
  //     print('id_photo_path type: ${visitor['id_photo_path'].runtimeType}');
  //     print('id_photo_path value: ${visitor['id_photo_path']}');
  //
  //     if (idPhotoPaths != null &&
  //         idPhotoPaths.isNotEmpty &&
  //         idPhotoPaths != 'null') {
  //
  //       final paths = idPhotoPaths.contains(',')
  //           ? idPhotoPaths.split(',').map((e) => e.trim()).toList()
  //           : [idPhotoPaths.trim()];
  //
  //       for (var path in paths) {
  //         if (path.isEmpty) continue;
  //
  //         final originalFile = File(path);
  //
  //         if (await originalFile.exists()) {
  //           final compressedFile =
  //           await compressImage(originalFile.path);
  //
  //           if (compressedFile != null &&
  //               await compressedFile.exists()) {
  //
  //             encoder.addFile(compressedFile);
  //             print('Added compressed ID photo');
  //           }
  //         }
  //       }
  //     }
  //   }
  //
  //   encoder.close();
  //
  //   final zipFile = File(zipPath);
  //   print('Zip file size: ${await zipFile.length()} bytes');
  //
  //   return zipPath;
  // }


  // Compress image and save temporarily
  Future<File?> compressImage(String path, int counter) async {
    final dir = await getTemporaryDirectory();
    final fileName = path.split('/').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetPath = '${dir.path}/${timestamp}_${counter}_$fileName';

    final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
      path,
      targetPath,
      quality: 60,
      format: path.toLowerCase().endsWith('.png') ? CompressFormat.png : CompressFormat.jpeg,
    );

    if (compressedXFile == null) return null;
    return File(compressedXFile.path);
  }

  // Future<String> createVisitorPhotosPDF() async {
  //   final pdf = pw.Document();
  //   final today = DateTime.now();
  //   final formattedDate =
  //       "${today.day}-${today.month.toString().padLeft(2, '0')}-${today.year}";
  //
  //   for (var visitor in visitors) {
  //     pdf.addPage(
  //       pw.Page(
  //         build: (context) {
  //           List<pw.Widget> photoWidgets = [];
  //
  //           // Visitor photo
  //           if (visitor['visitor_photo_path'] != null &&
  //               visitor['visitor_photo_path'] != 'null' &&
  //               File(visitor['visitor_photo_path']).existsSync()) {
  //             final bytes = File(visitor['visitor_photo_path']).readAsBytesSync();
  //             photoWidgets.add(pw.Image(pw.MemoryImage(bytes), width: 150, height: 150));
  //           }
  //
  //           // ID photos
  //           final idPhotoPaths = visitor['id_photo_path'];
  //           if (idPhotoPaths != null && idPhotoPaths != 'null' && idPhotoPaths.isNotEmpty) {
  //             final paths = idPhotoPaths.contains(',')
  //                 ? idPhotoPaths.split(',').map((e) => e.trim()).toList()
  //                 : [idPhotoPaths.trim()];
  //
  //             for (var path in paths) {
  //               if (path.isEmpty) continue;
  //               final file = File(path);
  //               if (file.existsSync()) {
  //                 final bytes = file.readAsBytesSync();
  //                 photoWidgets.add(pw.Image(pw.MemoryImage(bytes), width: 150, height: 150));
  //               }
  //             }
  //           }
  //
  //           return pw.Column(
  //             crossAxisAlignment: pw.CrossAxisAlignment.start,
  //             children: [
  //               pw.Text('Name: ${visitor['name'] ?? ''}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
  //               pw.Text('Company: ${visitor['company'] ?? ''}'),
  //               pw.Text('Mobile: ${visitor['mobile'] ?? ''}'),
  //               pw.Text('Email: ${visitor['email'] ?? ''}'),
  //               pw.Text('Purpose: ${visitor['purpose'] ?? ''}'),
  //               pw.SizedBox(height: 10),
  //               pw.Wrap(
  //                 spacing: 10,
  //                 runSpacing: 10,
  //                 children: photoWidgets,
  //               ),
  //             ],
  //           );
  //         },
  //       ),
  //     );
  //   }
  //
  //   final dir = await getApplicationDocumentsDirectory();
  //   final path = '${dir.path}/visitor_photos_$formattedDate.pdf';
  //   final file = File(path);
  //   await file.writeAsBytes(await pdf.save());
  //   return path;
  // }

  Future<String> createVisitorPhotosPDF() async {
    final pdf = pw.Document();
    final today = DateTime.now();
    final formattedDate =
        "${today.day}-${today.month.toString().padLeft(2, '0')}-${today.year}";

    // Add all visitors in one page flow
    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          List<pw.Widget> visitorWidgets = [];

          for (var visitor in visitors) {
            List<pw.Widget> photoWidgets = [];

            // Visitor photo
            if (visitor['visitor_photo_path'] != null &&
                visitor['visitor_photo_path'] != 'null' &&
                File(visitor['visitor_photo_path']).existsSync()) {
              final bytes = File(visitor['visitor_photo_path']).readAsBytesSync();
              photoWidgets.add(pw.Image(pw.MemoryImage(bytes), width: 150, height: 150));
            }

            // ID photos
            final idPhotoPaths = visitor['id_photo_path'];
            if (idPhotoPaths != null && idPhotoPaths != 'null' && idPhotoPaths.isNotEmpty) {
              final paths = idPhotoPaths.contains(',')
                  ? idPhotoPaths.split(',').map((e) => e.trim()).toList()
                  : [idPhotoPaths.trim()];

              for (var path in paths) {
                if (path.isEmpty) continue;
                final file = File(path);
                if (file.existsSync()) {
                  final bytes = file.readAsBytesSync();
                  photoWidgets.add(pw.Image(pw.MemoryImage(bytes), width: 150, height: 150));
                }
              }
            }

            // Add visitor data + photos
            visitorWidgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Name: ${visitor['name'] ?? ''}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Company: ${visitor['company'] ?? ''}'),
                  pw.Text('Mobile: ${visitor['mobile'] ?? ''}'),
                  pw.Text('Email: ${visitor['email'] ?? ''}'),
                  pw.Text('Purpose: ${visitor['purpose'] ?? ''}'),
                  pw.SizedBox(height: 10),
                  pw.Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: photoWidgets,
                  ),
                  pw.Divider(thickness: 2), // <<< Separator line between visitors
                  pw.SizedBox(height: 10),   // optional spacing
                ],
              ),
            );
          }

          return visitorWidgets;
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/visitor_photos_$formattedDate.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }


  Future<String> exportVisitorsToCSV() async {
    List<List<String>> csvData = [
      [
        'Name',
        'Mobile',
        'Email',
        'Address',
        'Company',
        'Meeting Person',
        'ID Proof',
        'ID Number',
        'In_date',
        'Out_date',
        'In Time',
        'Out Time',
        'Vehicle',
        'Purpose',
        'Visitor Photo Path',
        'ID Photo Path',
      ]
    ];

    for (var visitor in visitors) {
      csvData.add([
        visitor['name'] ?? '',
        visitor['mobile'] ?? '',
        visitor['email'] ?? '',
        visitor['address'] ?? '',
        visitor['company'] ?? '',
        visitor['meeting_person'] ?? '',
        visitor['id_proof'] ?? '',
        visitor['id_number'] ?? '',
        visitor['in_date'] ?? '',
        visitor['out_date'] ?? '',
        visitor['in_time'] ?? '',
        visitor['out_time'] ?? '',
        visitor['vehicle'] ?? '',
        visitor['purpose'] ?? '',
        visitor['visitor_photo_path'] ?? 'null',
        visitor['id_photo_path'] ?? 'null',
      ]);
    }

    String csv = const ListToCsvConverter().convert(csvData);
    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/visitors_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);
    return file.path;
  }


  // Future<void> sendEmail() async {
  //
  //   if (globalMailConfig.fromMail.isEmpty ||
  //       globalMailConfig.toMail.isEmpty ||
  //       globalMailConfig.appPassword.isEmpty) {
  //     await _showAlert(
  //       'Mail is not configured properly. '
  //           'Please check sender email, recipient email, and app password.',
  //     );
  //     return;
  //   }
  //
  //   if (visitors.isEmpty) {
  //     await _showAlert('No visitors to send email.');
  //     return;
  //   }
  //
  //   try {
  //     setState(() {
  //       isLoading = true; // Show the central loader
  //     });
  //
  //     final csvPath = await exportVisitorsToCSV();
  //     final zipPath = await createPhotosZip();
  //
  //     final today = DateTime.now();
  //     final formattedDate =
  //         "${today.day}-${today.month.toString().padLeft(2, '0')}-${today.year}";
  //
  //     final smtpServer = gmail(smtpEmail, smtpAppPassword);
  //
  //     final message = Message()
  //       ..from = Address(smtpEmail, 'Visitor Management System')
  //       ..recipients.add(globalMailConfig.toMail) // TODO: replace with recipient //'hwttech@hwtpl.com'
  //       ..subject = 'Visitor List - $formattedDate'
  //       ..text =
  //           'Hello,\n\nPlease find attached the visitor report for today ($formattedDate).\n\nRegards,\nVisitor Management System'
  //       ..attachments = [
  //         FileAttachment(File(csvPath))..fileName = 'visitors_$formattedDate.csv',
  //         FileAttachment(File(zipPath))..fileName = 'visitor_photos_$formattedDate.zip',
  //       ];
  //
  //     // Send email
  //     await send(message, smtpServer);
  //
  //     // Delete visitors immediately after sending
  //     await DBHelper.instance.deleteAllVisitors();
  //     await fetchVisitors();
  //
  //     // Small delay so loader is visible
  //     await Future.delayed(const Duration(milliseconds: 500));
  //
  //     setState(() {
  //       isLoading = false; // Hide loader before showing alert
  //     });
  //
  //     await _showAlert('Email sent successfully', popPage: true);
  //
  //   } on MailerException catch (e) {
  //     setState(() => isLoading = false);
  //     await _showAlert('Failed to send email: ${e.message}');
  //     for (var p in e.problems) {
  //       print('Problem: ${p.code}: ${p.msg}');
  //     }
  //   } catch (e) {
  //     setState(() => isLoading = false);
  //     await _showAlert('Unexpected error: $e');
  //   }
  // }

  Future<void> sendEmail() async {
    if (globalMailConfig.fromMail.isEmpty ||
        globalMailConfig.toMail.isEmpty ||
        globalMailConfig.appPassword.isEmpty) {
      await _showAlert(
        'Mail is not configured properly. '
            'Please check sender email, recipient email, and app password.',
      );
      return;
    }

    if (visitors.isEmpty) {
      await _showAlert('No visitors to send email.');
      return;
    }

    try {
      setState(() {
        isLoading = true; // show loader
      });

      // 1️⃣ Export CSV
      final csvPath = await exportVisitorsToCSV();

      // 2️⃣ Create zip with all visitor + ID photos
      // final zipPath = await createPhotosZip(); // using your fixed createPhotosZip()

      final pdfPath = await createVisitorPhotosPDF();

      // 3️⃣ Prepare email
      final today = DateTime.now();
      final formattedDate =
          "${today.day}-${today.month.toString().padLeft(2, '0')}-${today.year}";

      final smtpServer = gmail(globalMailConfig.fromMail, globalMailConfig.appPassword);

      final message = Message()
        ..from = Address(globalMailConfig.fromMail, 'Visitor Management System')
        ..recipients.add(globalMailConfig.toMail)
        ..subject = 'Visitor List - $formattedDate'
        ..text =
            'Hello,\n\nPlease find attached the visitor report and photos for today ($formattedDate).\n\nRegards,\nVisitor Management System'
        ..attachments = [
          FileAttachment(File(csvPath))..fileName = 'visitors_$formattedDate.csv',
          // FileAttachment(File(zipPath))..fileName = 'visitor_photos_$formattedDate.zip',
          FileAttachment(File(pdfPath))..fileName = 'visitor_photos_$formattedDate.pdf',
        ];

      // 4️⃣ Send email
      await send(message, smtpServer);

      // 5️⃣ Clean up DB
      await DBHelper.instance.deleteAllVisitors();
      await fetchVisitors();

      // brief delay so loader is visible
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        isLoading = false; // hide loader
      });

      await _showAlert('Email sent successfully', popPage: true);

    } on MailerException catch (e) {
      setState(() => isLoading = false);
      await _showAlert('Failed to send email: ${e.message}');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      await _showAlert('Unexpected error: $e');
      print("Error ${e}");
    }
  }



  Future<void> _showAlert(String message, {bool popPage = false}) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              if (popPage) {
                visitorsUpdated.value = true; // notify history page
                Navigator.pop(context, true); // close page
              } else {
                Navigator.pop(context); // just close dialog
              }
            },
          )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Mail'),
        centerTitle: true,
        backgroundColor: kPrimaryColor,
      ),
      // body: isLoading
      //     ? const Center(child: CircularProgressIndicator())
      //     : Column(
      //   children: [
      //     Padding(
      //       padding: const EdgeInsets.all(16.0),
      //       child: SizedBox(
      //         width: double.infinity,
      //         child: ElevatedButton.icon(
      //           icon: const Icon(Icons.mail),
      //           label: const Text(
      //             'Send Mail',
      //             style: TextStyle(
      //                 fontSize: 18, fontWeight: FontWeight.bold),
      //           ),
      //           onPressed: sendEmail,
      //           style: ElevatedButton.styleFrom(
      //             backgroundColor: kPrimaryColorLight,
      //             foregroundColor: Colors.black,
      //             padding: const EdgeInsets.symmetric(vertical: 16),
      //             shape: RoundedRectangleBorder(
      //               borderRadius: BorderRadius.circular(20),
      //             ),
      //             elevation: 3,
      //           ),
      //         ),
      //       ),
      //     ),
      //     Expanded(
      //       child: visitors.isEmpty
      //           ? const Center(
      //         child: Text(
      //           'No visitors found.',
      //           style: TextStyle(
      //               fontSize: 18,
      //               fontWeight: FontWeight.bold,
      //               color: Colors.black),
      //         ),
      //       )
      //           : ListView.builder(
      //         itemCount: visitors.length,
      //         itemBuilder: (context, index) {
      //           final visitor = visitors[index];
      //           return Card(
      //             margin: const EdgeInsets.symmetric(
      //                 horizontal: 16, vertical: 8),
      //             shape: RoundedRectangleBorder(
      //                 borderRadius: BorderRadius.circular(20)),
      //             elevation: 3,
      //             child: ListTile(
      //               leading: visitor['visitor_photo_path'] != null &&
      //                   visitor['visitor_photo_path'] != 'null'
      //                   ? CircleAvatar(
      //                 backgroundImage: FileImage(
      //                     File(visitor['visitor_photo_path'])),
      //                 radius: 25,
      //               )
      //                   : const CircleAvatar(
      //                 child: Icon(Icons.person),
      //                 radius: 25,
      //               ),
      //               title: Text(visitor['name'] ?? 'No Name'),
      //               subtitle:
      //               Text(visitor['company'] ?? 'No Company'),
      //             ),
      //           );
      //         },
      //       ),
      //     ),
      //   ],
      // ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.mail),
                    label: const Text(
                      'Send Mail',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: sendEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColorLight,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: visitors.isEmpty
                    ? const Center(
                  child: Text(
                    'No visitors found.',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                )
                    : ListView.builder(
                  itemCount: visitors.length,
                  itemBuilder: (context, index) {
                    final visitor = visitors[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 3,
                      child: ListTile(
                        leading: visitor['visitor_photo_path'] != null &&
                            visitor['visitor_photo_path'] != 'null'
                            ? CircleAvatar(
                          backgroundImage:
                          FileImage(File(visitor['visitor_photo_path'])),
                          radius: 25,
                        )
                            : const CircleAvatar(
                          child: Icon(Icons.person),
                          radius: 25,
                        ),
                        title: Text(visitor['name'] ?? 'No Name'),
                        subtitle: Text(visitor['company'] ?? 'No Company'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Centered loader overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(strokeWidth: 6),
              ),
            ),
        ],
      ),
    );
  }
}
