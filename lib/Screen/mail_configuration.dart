import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ================= COLORS =================
const kPrimaryColor = Color(0xff856EE1);
const kBackgroundColor = Color(0xffF5F3FA);
const kBlackLight = Color(0xFF6F6F6F);
const kWhite = Color(0xFFFFFFFF);
const kBlack = Color(0xFF000000);
const kPrimaryColorLight = Color(0xFFC655EE);
const kInputBorder = Color(0xFFC4C4C4);

// ================= GLOBAL CONFIG =================
class MailConfig {
  String fromMail = '';
  String appPassword = '';
  String toMail = '';
}

MailConfig globalMailConfig = MailConfig();

// ================= MAIL CONFIGURATION PAGE =================
class MailConfiguration extends StatefulWidget {
  const MailConfiguration({super.key});

  @override
  State<MailConfiguration> createState() => _MailConfigurationState();
}

class _MailConfigurationState extends State<MailConfiguration> {
  final TextEditingController _fromMail = TextEditingController();
  final TextEditingController _appPassword = TextEditingController();
  final TextEditingController _toMail = TextEditingController();

  bool _showPassword = false;

  @override
  void initState() {
    loadMailConfig();
    super.initState();
  }


  Future<void> loadMailConfig() async {
    final prefs = await SharedPreferences.getInstance();
    globalMailConfig.fromMail = prefs.getString('fromMail') ?? '';
    globalMailConfig.appPassword = prefs.getString('appPassword') ?? '';
    globalMailConfig.toMail = prefs.getString('toMail') ?? '';
  }


  Future<void> saveMailConfig(String from, String password, String to) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fromMail', from);
    await prefs.setString('appPassword', password);
    await prefs.setString('toMail', to);
  }

  // void addConfiguration() {
  //   // Save to global configuration
  //   globalMailConfig.fromMail = _fromMail.text.trim();
  //   globalMailConfig.appPassword = _appPassword.text.trim();
  //   globalMailConfig.toMail = _toMail.text.trim();
  //
  //   // Notify the user
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text("Success"),
  //       content: const Text("Configuration saved successfully!"),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context); // Close the dialog
  //           },
  //           child: const Text("OK"),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   // Clear the text fields
  //   _fromMail.clear();
  //   _appPassword.clear();
  //   _toMail.clear();
  // }

  void addConfiguration() async {
    // Trim the values
    final fromMail = _fromMail.text.trim();
    final appPassword = _appPassword.text.trim();
    final toMail = _toMail.text.trim();

    // Validation
    if (fromMail.isEmpty || appPassword.isEmpty || toMail.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: const Text(
              "Mail configuration is incomplete. Please check all fields."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return; // Stop execution
    }

    // Save to global configuration
    globalMailConfig.fromMail = fromMail;
    globalMailConfig.appPassword = appPassword;
    globalMailConfig.toMail = toMail;

    await saveMailConfig(fromMail, appPassword, toMail);

    // Notify the user
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Configuration saved successfully!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    // Clear the text fields
    _fromMail.clear();
    _appPassword.clear();
    _toMail.clear();
  }


  void showInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "SMTP Setup – Step by Step Guide",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              // ================= WHAT IS THIS =================
              Text(
                "What is this configuration?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                "This screen configures email (SMTP) so the app can send emails automatically.",
              ),
              SizedBox(height: 12),

              // ================= FIELD EXPLANATION =================
              Text(
                "Field Explanation:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text("• From Mail: The email address that will SEND"),
              Text("  the mail."),
              Text("• App Password: Special password generated"),
              Text("  from your email for secure access."),
              Text("• To Mail: The email address that will RECEIVE"),
              Text("  the mail."),
              SizedBox(height: 12),

              // ================= GMAIL GUIDE =================
              Text(
                "Gmail – How to Generate App Password:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text("1️⃣ Open Google Account:",style: TextStyle(fontWeight: FontWeight.bold)),
              Text("   • Go to https://myaccount.google.com"),
              Text("   • Sign in with your Gmail account"),
              SizedBox(height: 4),
              Text("2️⃣ Enable 2-Step Verification:",style: TextStyle(fontWeight: FontWeight.bold)),
              Text("   • Go to Security → Turn ON 2-Step"),
              Text("     Verification"),
              Text("   • Required to generate app password"),
              SizedBox(height: 4),
              Text("3️⃣ Generate App Password:",style: TextStyle(fontWeight: FontWeight.bold)),
              Text("   • Go to Security → App passwords"),
              Text("   • Select App: Mail"),
              Text("   • Select Device: Other (Custom)"),
              Text("   • Enter a name (example: Visitor App)"),
              Text("   • Click Generate"),
              SizedBox(height: 4),
              Text("4️⃣ Copy the Password:",style: TextStyle(fontWeight: FontWeight.bold),),
              Text("   • Google will show a 16-character password"),
              Text("   • Paste it into the App Password field here"),
              Text("   • DO NOT use your normal Gmail password"),
              SizedBox(height: 12),

              // ================= IMPORTANT NOTES =================
              Text(
                "Important Notes:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text("• App passwords are safer than normal"),
              Text("  passwords"),
              Text("• Never share your app password"),
              Text("• If mail fails, recheck email, password, and"),
              Text("  internet"),
              Text("• Gmail is the most reliable option"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "Got it",
              style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }


  // Widget buildTextField({
  //   required String hint,
  //   required TextEditingController controller,
  //   required String info,
  //   bool obscure = false,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  //         decoration: BoxDecoration(
  //           color: kWhite,
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(color: kPrimaryColor),
  //         ),
  //         child: TextField(
  //           controller: controller,
  //           obscureText: obscure,
  //           decoration: InputDecoration(
  //             hintText: hint,
  //             border: InputBorder.none,
  //           ),
  //         ),
  //       ),
  //       const SizedBox(height: 4),
  //       Text(
  //         info,
  //         style: const TextStyle(fontSize: 12, color: kBlackLight),
  //       ),
  //       const SizedBox(height: 10),
  //     ],
  //   );
  // }

  Widget buildTextField({
    required String hint,
    required TextEditingController controller,
    required String info,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimaryColor),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure ? !_showPassword : false,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              suffixIcon: obscure // only show for password fields
                  ? IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: kBlackLight,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          info,
          style: const TextStyle(fontSize: 12, color: kBlackLight),
        ),
        const SizedBox(height: 10),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text(
          "Mail Configuration",
          style: TextStyle(color: kWhite, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: showInfoDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildTextField(
              hint: "Enter your email (From Mail)",
              controller: _fromMail,
              info: "This email will send the mails via SMTP.",
            ),
            buildTextField(
              hint: "Enter app password",
              controller: _appPassword,
              info: "Use an app-specific password for your email account.",
              obscure: true,
            ),
            buildTextField(
              hint: "Enter receiver's email (To Mail)",
              controller: _toMail,
              info: "This is the email where the mail will be sent.",
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 60, // Fixed height
              child: ElevatedButton.icon(
                onPressed: addConfiguration,
                icon: const Icon(
                  Icons.save,
                  color: Colors.white,
                  size: 26,
                ),
                label: const Text(
                  "Save Configuration",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: kPrimaryColor.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
