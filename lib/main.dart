import 'package:flutter/material.dart';
import 'package:visitor_application/Login.dart';
import 'Screen/add_members_page.dart';
import 'Screen/form.dart';
import 'Screen/history_list.dart';
import 'Screen/mail_configuration.dart';
import 'Screen/pending_list.dart';
import 'Screen/send_mail.dart';


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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Visitor Management',
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: kInputBorder),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kPrimaryColorLight,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isAdmin;
  const HomeScreen({super.key, required this.isAdmin});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0; // 0 = Pending, 1 = History
  int pendingReloadKey = 0;

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ================= DRAWER =================
        drawer: Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                ),
                child: Row(
                  children: const [
                    Icon(Icons.people, size: 42, color: kWhite),
                    SizedBox(width: 12),
                    Text(
                      'Visitor Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kWhite,
                      ),
                    ),
                  ],
                ),
              ),

              // Send Email visible to everyone
              ListTile(
                leading: Icon(Icons.mail, color: kPrimaryColor),
                title: const Text('Send Email'),
                onTap: () {
                  Navigator.pop(context); // close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SendMailPage()),
                  );
                },
              ),

              // Admin-only options
              if (widget.isAdmin) ...[
                ListTile(
                  leading: Icon(Icons.person_add, color: kPrimaryColor),
                  title: const Text("Add Member's Name"),
                  onTap: () {
                    Navigator.pop(context); // close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddMemberPage()),
                    );
                  },
                ),

                ListTile(
                  leading: Icon(Icons.settings, color: kPrimaryColor),
                  title: const Text('Mail Configuration'),
                  onTap: () {
                    Navigator.pop(context); // close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MailConfiguration()),
                    );
                  },
                ),
              ],

              const Divider(),
              const SizedBox(height: 40),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: logout,
              ),
            ],
          ),
        ),

      // ================= APP BAR =================
      appBar: AppBar(
        title: const Text(
          'Visitor Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
      ),

      // ================= BODY =================
      body: Column(
        children: [
          // ---------- Tabs ----------
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: kPrimaryColorLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => selectedTab = 0),
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: selectedTab == 0 ? kPrimaryColorLight : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          'Pending List',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selectedTab == 0 ? kBlack : kBlackLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => selectedTab = 1),
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: selectedTab == 1 ? kPrimaryColorLight : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          'History List',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selectedTab == 1 ? kBlack : kBlackLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------- Tab Content ----------
          Expanded(
            child: selectedTab == 0
                ? VisitorList(key: ValueKey(pendingReloadKey))
                : const VisitorHistoryPage(),
          ),
        ],
      ),

      // ================= FAB =================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VisitorForm()),
          );

          if (result == true) {
            setState(() {
              selectedTab = 0;
              pendingReloadKey++;
            });
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}
