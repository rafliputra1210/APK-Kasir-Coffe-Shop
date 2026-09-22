import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'models.dart';
import 'cashier_screen.dart';
import 'admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  void _onNumPress(String number) {
    if (_lockoutUntil != null) {
      if (DateTime.now().isBefore(_lockoutUntil!)) {
        final remaining = _lockoutUntil!.difference(DateTime.now()).inSeconds;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terlalu banyak percobaan salah! Tunggu $remaining detik.'),
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      } else {
        _lockoutUntil = null;
        _failedAttempts = 0;
      }
    }

    if (_pin.length < 6) {
      setState(() {
        _pin += number;
      });
    }

    // Otomatis verifikasi jika sudah 6 digit
    if (_pin.length == 6) {
      _verifyLogin();
    }
  }

  void _onDeletePress() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _verifyLogin() {
    final auth = context.read<AuthProvider>();
    final success = auth.login(_pin);

    if (success) {
      _failedAttempts = 0;
      _lockoutUntil = null;
      final role = auth.currentUser!.role;
      if (role == UserRole.admin) {
        // Arahkan ke Dasbor Admin terpusat
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        // Arahkan Kasir ke fitur input modal awal sebelum buka shift
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CashierScreen()),
        );
      }
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN Salah 5 kali berturut-turut! Login dikunci selama 30 detik untuk keamanan.', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PIN Salah atau Akun Tidak Aktif! (Percobaan $_failedAttempts/5)', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: Center(
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.brown),
              const SizedBox(height: 20),
              const Text('Masukkan PIN Anda', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              // Indikator PIN bulat-bulat
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length ? Colors.brown : Colors.grey[300],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),

              // Keypad angka
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 1; i <= 9; i++) _buildNumButton(i.toString()),
                  const SizedBox(width: 70), // Spasi kosong
                  _buildNumButton('0'),
                  _buildDeleteButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumButton(String number) {
    return InkWell(
      onTap: () => _onNumPress(number),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.brown.shade200),
        ),
        child: Center(
          child: Text(number, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown)),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: _onDeletePress,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
        child: const Center(
          child: Icon(Icons.backspace, size: 30, color: Colors.brown),
        ),
      ),
    );
  }
}