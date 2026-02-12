import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../Database/db_helper.dart';
import 'package:visitor_application/constants.dart';

// PURPLE THEME COLORS


class VisitorForm extends StatefulWidget {
  const VisitorForm({super.key});

  @override
  State<VisitorForm> createState() => _VisitorFormState();
}

class _VisitorFormState extends State<VisitorForm> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  String? _idNumberError;

  List<Map<String, dynamic>> _meetingPersons = [];
  bool _loadingMeetingPersons = true;

  List<String> _companyNames = [];
  bool _loadingCompanies = true;

  // Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _purposeController = TextEditingController();
  final _dateController = TextEditingController();

  // Dropdowns
  String? _selectedCompany;
  Map<String, dynamic>? _selectedMeetingPerson;
  String? _selectedIdProof;

  // Time
  TimeOfDay? _inTime;
  TimeOfDay? _outTime;

  // Photos
  File? _visitorPhoto;
  final List<File> _idPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadMeetingPersons();
    _loadCompanies();
    final now = DateTime.now();
    _dateController.text = "${now.day}/${now.month}/${now.year}";
    _inTime = TimeOfDay.fromDateTime(now);
  }

  Future<void> _loadMeetingPersons() async {
    final data = await DBHelper.instance.getMeetingPersons();
    setState(() {
      _meetingPersons = data;
      _loadingMeetingPersons = false;
    });
  }


  Future<void> _loadCompanies() async {
    final names = await DBHelper.instance.getCompanyNames();
    setState(() {
      _companyNames = names;
      _loadingCompanies = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _idNumberController.dispose();
    _vehicleController.dispose();
    _purposeController.dispose();
    _dateController.dispose();
    super.dispose();
  }


  Future<void> _showAlert(String title, String message) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // IMAGE PICKERS
  // Future<void> _pickVisitorPhoto() async {
  //   final picked = await _picker.pickImage(source: ImageSource.camera);
  //   if (picked != null) {
  //     setState(() => _visitorPhoto = File(picked.path));
  //   }
  // }
  //
  // Future<void> _pickIdPhoto() async {
  //   if (_idPhotos.length == 2) {
  //     await _showAlert('Limit Reached', 'You can upload up to 2 ID photos.');
  //     return;
  //   }
  //   final picked = await _picker.pickImage(source: ImageSource.camera);
  //   if (picked != null) {
  //     setState(() => _idPhotos.add(File(picked.path)));
  //   }
  // }

  // Future<File?> _compressAndSave(File file, String filename) async {
  //   final dir = await getApplicationDocumentsDirectory();
  //   final targetPath = '${dir.path}/$filename';
  //
  //   // Compress the file
  //   final compressedXFile = await FlutterImageCompress.compressAndGetFile(
  //     file.path,
  //     targetPath,
  //     quality: 60,
  //     minWidth: 1024,
  //     minHeight: 1024,
  //     autoCorrectionAngle: true,
  //   );
  //
  //   // If compressAndGetFile returns File? directly, this is fine:
  //   // return compressedXFile;
  //
  //   // If it returns XFile?, convert to File
  //   if (compressedXFile == null) return null;
  //   return File(compressedXFile.path);
  // }
  //
  //
  // Future<void> _pickVisitorPhoto() async {
  //   final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
  //   if (picked != null) {
  //     final file = File(picked.path); // convert XFile to File
  //     final compressed = await _compressAndSave(
  //       file,
  //       'visitor_${DateTime.now().millisecondsSinceEpoch}.jpg',
  //     );
  //     if (compressed != null) setState(() => _visitorPhoto = compressed);
  //   }
  // }
  //
  // Future<void> _pickIdPhoto() async {
  //   if (_idPhotos.length == 2) {
  //     await _showAlert('Limit Reached', 'You can upload up to 2 ID photos.');
  //     return;
  //   }
  //
  //   final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
  //   if (picked != null) {
  //     final file = File(picked.path); // convert XFile to File
  //     final compressed = await _compressAndSave(
  //       file,
  //       'id_${DateTime.now().millisecondsSinceEpoch}.jpg',
  //     );
  //     if (compressed != null) setState(() => _idPhotos.add(compressed));
  //   }
  // }

  /// Compress the image and fix rotation
  Future<File?> _compressAndSave(File file, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final targetPath = path.join(dir.path, filename);

    // compress returns XFile? in your version
    final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 60,
      minWidth: 1024,
      minHeight: 1024,
      autoCorrectionAngle: true, // fixes rotation only
    );

    if (compressedXFile == null) return null;

    // convert XFile to File
    return File(compressedXFile.path);
  }


  /// Pick visitor photo (front camera)
  Future<void> _pickVisitorPhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 1080,
        maxHeight: 1920,
        preferredCameraDevice: CameraDevice.front, // front camera
      );

      if (picked == null) return;

      final File pickedFile = File(picked.path);
      final File? compressed = await _compressAndSave(
        pickedFile,
        'visitor_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (compressed != null) {
        setState(() => _visitorPhoto = compressed);
      }
    } catch (e) {
      print("Error picking visitor photo: $e");
    }
  }

  /// Pick ID photo
  Future<void> _pickIdPhoto() async {
    if (_idPhotos.length == 2) {
      // show alert somewhere in your UI
      print("Limit reached: only 2 ID photos allowed.");
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 1080,
        maxHeight: 1920,
        preferredCameraDevice: CameraDevice.rear, // usually ID photos rear
      );

      if (picked == null) return;

      final File pickedFile = File(picked.path);
      final File? compressed = await _compressAndSave(
        pickedFile,
        'id_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (compressed != null) {
        setState(() => _idPhotos.add(compressed));
      }
    } catch (e) {
      print("Error picking ID photo: $e");
    }
  }

  /// Example widget to display visitor photo with flip
  Widget visitorPhotoWidget() {
    if (_visitorPhoto == null) {
      return const Placeholder(fallbackHeight: 200, fallbackWidth: 200);
    }

    return Image.file(
      _visitorPhoto!,
      fit: BoxFit.cover,
      width: 200,
      height: 200,
      // Flip horizontally for front camera selfies
      alignment: Alignment.center,
      repeat: ImageRepeat.noRepeat,
      // Transform to mirror the image
      // Comment out if already correct
      // transform: Matrix4.rotationY(3.1416),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _pickTime(bool isInTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isInTime ? (_inTime ?? TimeOfDay.now()) : (_outTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isInTime) _inTime = picked;
        else _outTime = picked;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? Function(String)? liveValidator,
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
    bool required = false, // <-- add this
  }) {
    String? errorText;

    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            label: required
                ? RichText(
              text: TextSpan(
                text: label,
                style: TextStyle(color: Colors.grey[700]),
                children: const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            )
                : Text(label),
            prefixIcon: icon != null ? Icon(icon, color: kPrimaryColor) : null,
            filled: true,
            fillColor: kBackgroundColor,
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(color: kInputBorder),
            ),
          ),
          validator: validator,
          onChanged: (value) {
            if (liveValidator != null) {
              final msg = liveValidator(value);
              setState(() {
                errorText = msg;
              });
            }
          },
        );
      },
    );
  }

  Widget _buildIdPhotoRow() {
    return Row(
      children: [
        for (int i = 0; i < 2; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
              height: 130,
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _idPhotos.length > i
                    ? Image.file(
                  _idPhotos[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo, color: Colors.black, size: 40),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: kPrimaryColor),
          ),
          child: InkWell(
            onTap: _pickIdPhoto,
            borderRadius: BorderRadius.circular(25),
            child: Row(
              children: [
                Icon(Icons.camera_alt, color: kBlack),
                const SizedBox(width: 6),
                Text('Upload', style: TextStyle(color: kBlack)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Form', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // VISITOR PHOTO
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: kPrimaryColor,
                    backgroundImage: _visitorPhoto != null ? FileImage(_visitorPhoto!) : null,
                    child: _visitorPhoto == null
                        ? Icon(Icons.person, size: 60, color: Colors.black)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: kPrimaryColor),
                    ),
                    child: InkWell(
                      onTap: _pickVisitorPhoto,
                      borderRadius: BorderRadius.circular(25),
                      child: Row(
                        children: [
                          Icon(Icons.camera_alt, color: kBlack),
                          const SizedBox(width: 6),
                          Text('Upload', style: TextStyle(color: kBlack)),
                        ],
                      ),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 16),

              // PERSONAL DETAILS
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [

                      /// SEARCHABLE MEETING PERSON FIELD - NOW ABOVE NAME
                      _loadingMeetingPersons
                          ? const CircularProgressIndicator()
                          : Autocomplete<Map<String, dynamic>>(
                        displayStringForOption: (option) => '${option['tenant_name']} - ${option['flat_number']}',
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                          final query = textEditingValue.text.toLowerCase();
                          return _meetingPersons.where((person) {
                            final tenant = person['tenant_name'].toString().toLowerCase();
                            final flat = person['flat_number'].toString().toLowerCase();
                            return tenant.contains(query) || flat.contains(query);
                          });
                        },
                        onSelected: (selection) => setState(() => _selectedMeetingPerson = selection),
                        fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: textController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              label: RichText(
                                text: TextSpan(
                                  text: 'Meeting with member',
                                  style: TextStyle(color: Colors.grey[700]),
                                  children: const [
                                    TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                              prefixIcon: Icon(Icons.people, color: kPrimaryColor),
                              filled: true,
                              fillColor: kBackgroundColor,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                              suffixIcon: _selectedMeetingPerson != null
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  textController.clear();
                                  setState(() => _selectedMeetingPerson = null);
                                },
                              )
                                  : null,
                            ),
                            validator: (_) => _selectedMeetingPerson == null ? 'Select person' : null,
                          );
                        },
                      ),


                      const SizedBox(height: 12),

                      /// VISITOR NAME
                      _buildTextField(
                        controller: _nameController,
                        label: 'Visitor name',
                        icon: Icons.person,
                        keyboardType: TextInputType.name,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter name';
                          if (RegExp(r'\d').hasMatch(v)) return 'No numbers allowed in name';
                          return null;
                        },
                        liveValidator: (v) {
                          if (RegExp(r'\d').hasMatch(v)) return 'No numbers allowed in name';
                          return null;
                        },
                        required: true,
                      ),

                      const SizedBox(height: 12),

                      /// MOBILE NUMBER
                      _buildTextField(
                        controller: _mobileController,
                        label: 'Mobile Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.length != 10 ? 'Enter valid number' : null,
                        required: true,
                      ),

                      const SizedBox(height: 12),

                      /// EMAIL
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                      ),

                      const SizedBox(height: 12),

                      /// SEARCHABLE COMPANY FIELD
                      Row(
                        children: [
                          Expanded(
                            child: _loadingCompanies
                                ? const CircularProgressIndicator()
                                : Autocomplete<String>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return const Iterable<String>.empty();
                                }
                                return _companyNames.where((String option) {
                                  return option
                                      .toLowerCase()
                                      .contains(textEditingValue.text.toLowerCase());
                                });
                              },
                              onSelected: (String selection) {
                                setState(() => _selectedCompany = selection);
                              },
                              fieldViewBuilder:
                                  (context, textController, focusNode, onFieldSubmitted) {
                                return TextFormField(
                                  controller: textController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    label: RichText(
                                      text: TextSpan(
                                        text: 'Company',
                                        style: TextStyle(color: Colors.grey[700]),
                                        children: const [
                                          TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                    prefixIcon: Icon(Icons.business, color: kPrimaryColor),
                                    filled: true,
                                    fillColor: kBackgroundColor,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                                    suffixIcon: _selectedCompany != null
                                        ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        textController.clear();
                                        setState(() => _selectedCompany = null);
                                      },
                                    )
                                        : null,
                                  ),
                                  validator: (v) => _selectedCompany == null ? 'Select company' : null,
                                );
                                },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _showAddCompanyDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            child: const Text('Add', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.location_on,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _vehicleController,
                        label: 'Vehicle Number',
                        icon: Icons.directions_car,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _purposeController,
                        label: 'Purpose of Visit',
                        icon: Icons.info,
                        validator: (v) => v!.isEmpty ? 'Enter purpose of visit' : null,
                        required: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ID DETAILS
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 3,
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: const Text('Visitor ID Details'),
                  leading: Icon(Icons.badge, color: kPrimaryColor),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    _buildDropdown(
                      value: _selectedIdProof,
                      label: 'ID Proof',
                      items: ['Pancard', 'Adhar card', 'Company ID', 'Driving License'],
                      onChanged: (v) => setState(() => _selectedIdProof = v),
                      validator: (v) => v == null ? 'Select ID proof' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _idNumberController,
                      label: 'ID Number',
                      inputFormatters: [  LengthLimitingTextInputFormatter(16), ],
                      validator: (value) {
                        if (_selectedIdProof == null) return 'Select ID proof first';
                        if (value == null || value.isEmpty) return 'Enter ID number';

                        switch (_selectedIdProof) {
                          case 'Pancard':
                            if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(value.toUpperCase())) {
                              return 'PAN must be 5 letters, 4 digits, 1 letter (e.g., ABCDE1234F)';
                            }
                            break;
                          case 'Adhar card':
                            if (!RegExp(r'^[0-9]{12}$').hasMatch(value)) {
                              return 'Aadhaar must be 12 digits';
                            }
                            break;
                          case 'Driving License':
                            if (!RegExp(r'^[A-Za-z0-9]{16}$').hasMatch(value)) {
                              return 'Driving License must be 16 characters (letters and numbers)';
                            }
                            break;
                          default:
                            return null;
                        }
                        return null; // valid
                      },
                      liveValidator: (value) {
                        if (_selectedIdProof == null) return 'Select ID proof first';
                        if (value.isEmpty) return 'Enter ID number';

                        switch (_selectedIdProof) {
                          case 'Pancard':
                            if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(value.toUpperCase())) {
                              return 'PAN must be 5 letters, 4 digits, 1 letter (e.g., ABCDE1234F)';
                            }
                            break;
                          case 'Adhar card':
                            if (!RegExp(r'^[0-9]{12}$').hasMatch(value)) {
                              return 'Aadhaar must be 12 digits';
                            }
                            break;
                          case 'Driving License':
                            if (!RegExp(r'^[A-Za-z0-9]{16}$').hasMatch(value)) {
                              return 'Driving License must be 16 characters (letters and numbers)';
                            }
                            break;
                          default:
                            return null;
                        }
                        return null; // valid
                      },
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _buildIdPhotoRow(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // DATE & TIME
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 3,
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: const Text('Date & Time'),
                  leading: Icon(Icons.calendar_today, color: kPrimaryColor),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                              decoration: BoxDecoration(
                                color: kBackgroundColor,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: kInputBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.date_range, color: kPrimaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_dateController.text)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickTime(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                              decoration: BoxDecoration(
                                color: kBackgroundColor,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: kInputBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, color: kPrimaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_inTime != null
                                        ? _inTime!.format(context)
                                        : 'Select Time'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    backgroundColor: kPrimaryColor,
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kWhite),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return DropdownButtonFormField<String>(
      value: _selectedIdProof,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: 'ID Proof',
            style: TextStyle(color: Colors.grey[700]),
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        filled: true,
        fillColor: kBackgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
      ),
      items: ['Pancard', 'Adhar card', 'Company ID', 'Driving License']
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => setState(() => _selectedIdProof = v),
      validator: (v) => v == null ? 'Select ID proof' : null,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_visitorPhoto == null) {
      await _showAlert('Missing Photo', 'Visitor photo is required');
      return;
    }

    if (_idPhotos.isEmpty) {
      await _showAlert('Missing ID Photo', 'At least one ID photo is required');
      return;
    }
    final visitorName = _nameController.text.trim().replaceAll(' ', '_');
    final inDate = _dateController.text.replaceAll('/', '-');

    final visitorPath = await saveImage(
      _visitorPhoto!,
      '${visitorName}_visitor_${inDate}.png',
    );


    final idPaths = <String>[];
    for (int i = 0; i < _idPhotos.length; i++) {
      idPaths.add(await saveImage(
        _idPhotos[i],
        '${visitorName}_id_${inDate}_${i + 1}.png', // start numbering from 1
      ));
    }

    await DBHelper.instance.addVisitor({
      'name': _nameController.text,
      'mobile': _mobileController.text,
      'email': _emailController.text,
      'address': _addressController.text,
      'vehicle': _vehicleController.text,
      'purpose': _purposeController.text,
      'company': _selectedCompany,
      'meeting_person': '${_selectedMeetingPerson!['tenant_name']} - ${_selectedMeetingPerson!['flat_number']}', // correct key
      'id_proof': _selectedIdProof,             // correct key
      'id_number': _idNumberController.text,    // correct key
      'in_date': _dateController.text,
      'out_date': null,
      'in_time': _inTime!.format(context),      // correct key
      'out_time': null, // correct key
      'visitor_photo_path': visitorPath,        // correct key
      'id_photo_path': idPaths.join(','),       // correct key
    });
    print("Selected in date is ${_dateController.text} and in time is ${_inTime}");

    await _showAlert('Success', 'Visitor added successfully');
    Navigator.pop(context,true);
  }

  Future<String> saveImage(File image, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$filename';
    await image.copy(path);
    return path;
  }


  Future<void> _showAddCompanyDialog() async {
    final _companyNameController = TextEditingController();
    final _locationController = TextEditingController();
    String? errorMessage; // <-- to show error

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Company', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _companyNameController,
                  decoration: InputDecoration(
                    labelText: 'Company Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _companyNameController.text.trim();
                final location = _locationController.text.trim();

                if (name.isEmpty || location.isEmpty) {
                  setState(() {
                    errorMessage = 'Both fields are required';
                  });
                  return;
                }

                // Save to DB
                await DBHelper.instance.addCompany(name, location);

                // Reload companies
                await _loadCompanies();

                setState(() => _selectedCompany = name);

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              child: const Text('Add',style: TextStyle(color: Colors.black),),
            ),
          ],
        ),
      ),
    );
  }

}
