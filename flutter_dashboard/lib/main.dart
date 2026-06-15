import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EcoDashboardApp());
}

class EcoDashboardApp extends StatelessWidget {
  const EcoDashboardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Room eCO2',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00E676),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("ruangan_01");

  bool isRoomOccupied = false;
  double savedEnergyWh = 0.0;
  double preventedCo2Mg = 0.0;

  @override
  void initState() {
    super.initState();
    // Listening to Firebase RTDB
    // Jika Firebase belum di setup, data akan tetap 0 / dummy di UI.
    _dbRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          isRoomOccupied = data['status_lampu'] ?? false;
          savedEnergyWh = (data['energi_dihemat_wh'] ?? 0).toDouble();
          preventedCo2Mg = (data['co2_dicegah_mg'] ?? 0).toDouble();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Styling Constants
    final ecoColor = isRoomOccupied ? Colors.orangeAccent : const Color(0xFF00E676);
    final statusText = isRoomOccupied ? "Berpenghuni (Menyala)" : "Kosong (Hemat Energi)";

    return Scaffold(
      appBar: AppBar(
        title: const Text('eCO2 Monitoring', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Real-time Status Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ecoColor.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: ecoColor.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      isRoomOccupied ? Icons.lightbulb : Icons.eco,
                      size: 60,
                      color: ecoColor,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Status Ruangan",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: ecoColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Metrics Row
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: "Energi Diselamatkan",
                        value: "${savedEnergyWh.toStringAsFixed(2)} Wh",
                        icon: Icons.electric_bolt,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildMetricCard(
                        title: "CO2 Dicegah",
                        value: "${preventedCo2Mg.toStringAsFixed(2)} mg",
                        icon: Icons.cloud_done,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
