import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._internal();
  static Database? _database;

  DBHelper._internal();

  factory DBHelper() => instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'visitor_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Company Master
    await db.execute('''
      CREATE TABLE companies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT NOT NULL
      )
    ''');

    // Meeting Person Master
    await db.execute('''
      CREATE TABLE members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      house_owner TEXT NOT NULL,
      flat_number TEXT NOT NULL,
      phone_number TEXT NOT NULL,
      tenant_name TEXT NOT NULL
    )
    ''');


    await db.execute('''
    CREATE TABLE visitors (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      mobile TEXT,
      email TEXT,
      address TEXT,
      company TEXT,
      meeting_person TEXT,
      id_proof TEXT,
      id_number TEXT,
      in_date TEXT,
      out_date TEXT,
      in_time TEXT,
      out_time TEXT,
      vehicle TEXT,
      purpose TEXT,
      visitor_photo_path TEXT,
      id_photo_path TEXT
    )
  ''');

    // Insert default masters
    await db.insert('companies', {'name': 'Company A', 'location': 'City A'});
    await db.insert('companies', {'name': 'Company B', 'location': 'City B'});

    await db.insert('members', {
      'house_owner': 'Owner 1',
      'flat_number': '101',
      'phone_number': '1234567890',
      'tenant_name': 'Tenant 1'
    });

    await db.insert('members', {
      'house_owner': 'Owner 2',
      'flat_number': '102',
      'phone_number': '0987654321',
      'tenant_name': 'Tenant 2'
    });


  }


  Future<List<Map<String, dynamic>>> getCompanies() async {
    final db = await database;
    return await db.query('companies');
  }

  Future<List<String>> getCompanyNames() async {
    final companies = await getCompanies();
    return companies.map((c) => c['name'] as String).toList();
  }

  Future<int> addCompany(String name, String location) async {
    final db = await database;
    return await db.insert(
      'companies',
      {'name': name, 'location': location},
      conflictAlgorithm: ConflictAlgorithm.replace, // optional: replaces if the name exists
    );
  }

  Future<List<Map<String, dynamic>>> getMeetingPersons() async {
    final db = await database;
    return await db.query('members');
  }

  Future<List<String>> getMeetingPersonNames() async {
    final persons = await getMeetingPersons();
    return persons.map((p) => p['tenant_name'] as String).toList();
  }

  Future<int> addMeetingPerson(String name) async {
    final db = await database;
    return await db.insert(
      'meeting_persons',
      {'tenant_name': name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> addVisitor(Map<String, dynamic> visitorData) async {
    final db = await database;
    return await db.insert('visitors', visitorData, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getVisitors() async {
    final db = await database;
    return await db.query(
      'visitors',
      where: 'out_time IS NULL',
      orderBy: 'in_date DESC, in_time DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getHistoryVisitors() async {
    final db = await database;
    return await db.query(
      'visitors',
      where: 'out_time IS NOT NULL',
      orderBy: 'in_date DESC, in_time DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getFullListOfVisitor() async{
    final db = await database;
    return await db.query(
      'visitors',
      orderBy: 'in_date DESC, in_time DESC',
    );
  }

  Future<int> deleteVisitor(int id) async {
    final db = await database;
    return await db.delete(
      'visitors',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  Future<int> updateOutTime(int id, String date, String outTime) async {
    final db = await database;
    return await db.update(
      'visitors',
      {'out_date': date, 'out_time': outTime},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllVisitors() async {
    final db = await database;
    await db.delete(
      'visitors',
      where: 'out_time IS NOT NULL',
    );
  }

  Future<int> addMember(String houseOwner, String flatNumber, String phoneNumber, String tenantName) async {
    final db = await database;

    // Check if the house owner already exists
    final existing = await db.query(
      'members',
      where: 'house_owner = ?',
      whereArgs: [houseOwner],
    );

    if (existing.isNotEmpty) {
      // Update existing house owner record
      return await db.update(
        'members',
        {
          'flat_number': flatNumber,
          'phone_number': phoneNumber,
          'tenant_name': tenantName,
        },
        where: 'house_owner = ?',
        whereArgs: [houseOwner],
      );
    } else {
      // Insert new record
      return await db.insert(
        'members',
        {
          'house_owner': houseOwner,
          'flat_number': flatNumber,
          'phone_number': phoneNumber,
          'tenant_name': tenantName,
        },
      );
    }
  }

  Future<Map<String, dynamic>?> getLatestVisitorByPhone(String phoneNumber) async {
    final db = await database;

    final result = await db.query(
      'visitors',
      where: 'mobile = ?',
      whereArgs: [phoneNumber],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }



  Future<List<Map<String, dynamic>>> getVisitorsBetweenDates(
      DateTime fromDate, DateTime toDate) async {
    final db = await database;

    final String from = DateFormat('yyyy-MM-dd').format(fromDate);
    final String to = DateFormat('yyyy-MM-dd').format(toDate);

    return await db.query(
      'visitors',
      where: '''
      (substr(in_date, 7, 4) || '-' || substr(in_date, 4, 2) || '-' || substr(in_date, 1, 2))
      BETWEEN ? AND ?
    ''',
      whereArgs: [from, to],
      orderBy: 'in_date ASC',
    );
  }


  Future<int> deleteVisitorsBetweenDates(DateTime fromDate, DateTime toDate) async {
    final db = await database;

    // Convert fromDate and toDate to yyyy-MM-dd format for comparison
    final from = DateFormat('yyyy-MM-dd').format(fromDate);
    final to = DateFormat('yyyy-MM-dd').format(toDate);

    // Use SQLite substring to convert stored dd/MM/yyyy -> yyyy-MM-dd for comparison
    final count = await db.delete(
      'visitors',
      where: '''
      (substr(in_date, 7, 4) || '-' || substr(in_date, 4, 2) || '-' || substr(in_date, 1, 2)) 
      BETWEEN ? AND ?
    ''',
      whereArgs: [from, to],
    );

    return count;
  }


}
