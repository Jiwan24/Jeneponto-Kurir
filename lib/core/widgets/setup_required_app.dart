import 'package:flutter/material.dart';

/// Layar informasi ketika konfigurasi Firebase belum diisi.
class SetupRequiredApp extends StatelessWidget {
  const SetupRequiredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.rocket_launch_outlined, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Konfigurasi Firebase diperlukan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aplikasi ini belum terhubung ke Firebase. '
                  'Isi konfigurasi terlebih dahulu:',
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Buat project di Firebase Console\n'
                  '2. Jalankan: flutterfire configure\n'
                  '3. Aktifkan Email/Password di Authentication\n'
                  '4. Buat database Firestore (production mode)\n'
                  '5. Jalankan ulang: flutter run',
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ikuti langkah di atas di terminal.'),
                      ),
                    );
                  },
                  child: const Text('Saya sudah konfigurasi (restart app)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
