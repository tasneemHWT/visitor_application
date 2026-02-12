import 'package:flutter/material.dart';
import '../Database/db_helper.dart';
import 'package:visitor_application/constants.dart';

class AddMemberPage extends StatefulWidget {
  const AddMemberPage({super.key});

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _tenantController = TextEditingController();
  final TextEditingController _flatNumberController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  List<Map<String, dynamic>> _members = [];
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _tenantController.dispose();
    _flatNumberController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final members = await DBHelper.instance.getMeetingPersons();
    setState(() {
      _members = members;
    });
  }

  bool _validateFields() {
    if (_ownerController.text.trim().isEmpty ||
        _flatNumberController.text.trim().isEmpty ||
        _phoneNumberController.text.trim().isEmpty ||
        _tenantController.text.trim().isEmpty) {
      _showAlert('Please fill all fields.');
      return false;
    }

    if (!RegExp(r'^\d{10}$').hasMatch(_phoneNumberController.text.trim())) {
      _showAlert('Enter a valid 10-digit phone number.');
      return false;
    }

    return true;
  }

  Future<void> _submitMember() async {
    if (!_validateFields()) return;

    try {
      await DBHelper.instance.addMember(
        _ownerController.text.trim(),
        _flatNumberController.text.trim(),
        _phoneNumberController.text.trim(),
        _tenantController.text.trim(),
      );

      _clearForm();
      setState(() => _editingIndex = null);
      _loadMembers();
    } catch (e) {
      _showAlert('Failed to save member: $e');
    }
  }

  void _clearForm() {
    _ownerController.clear();
    _flatNumberController.clear();
    _phoneNumberController.clear();
    _tenantController.clear();
  }

  void _editMember(int index) {
    final member = _members[index];

    setState(() {
      _editingIndex = index;
      _ownerController.text = member['house_owner'];
      _flatNumberController.text = member['flat_number'];
      _phoneNumberController.text = member['phone_number'];
      _tenantController.text = member['tenant_name'];
    });
  }

  Future<void> _showAlert(String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Member'),
        centerTitle: true,
        backgroundColor: kPrimaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            /// FORM
            TextField(
              controller: _ownerController,
              decoration: const InputDecoration(
                labelText: 'Flat Owner Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _flatNumberController,
              decoration: const InputDecoration(
                labelText: 'Flat Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tenantController,
              decoration: const InputDecoration(
                labelText: 'Tenant Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            /// ADD / UPDATE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitMember,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColorLight,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _editingIndex == null ? 'Add Member' : 'Update Member',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'All Members',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            /// MEMBER LIST (COMPACT CARDS)
            Expanded(
              child: ListView.builder(
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      title: Text(
                        member['house_owner'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Flat: ${member['flat_number']}'),
                          Text('Phone: ${member['phone_number']}'),
                          Text('Tenant: ${member['tenant_name']}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editMember(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
