import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'login_screen.dart';
import 'cashier_pos_screen.dart';
import 'shift_provider.dart';
import 'kitchen_screen.dart';
import 'kitchen_provider.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final TextEditingController _modalController = TextEditingController(text: '100000');

  @override
  void dispose() {
    _modalController.dispose();
    super.dispose();
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _startShift() {
    final nominal = _modalController.text.trim();
    if (nominal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah modal awal shift!')),
      );
      return;
    }
    final capital = double.tryParse(nominal) ?? 100000;
    final cashierName = context.read<AuthProvider>().currentUser?.username ?? 'Kasir';
    context.read<ShiftProvider>().openShift(capital, cashierName: cashierName);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Shift Berhasil Dibuka'),
          ],
        ),
        content: Text('Shift berhasil dibuka dengan modal Rp $nominal oleh $cashierName.\nSiap melayani transaksi penjualan.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CashierPOSScreen()),
              );
            },
            child: const Text('Buka Kasir POS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final shift = context.watch<ShiftProvider>();
    final user = auth.currentUser;
    final isShiftActive = shift.isShiftOpened;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Coffee Shop - Kasir'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          Consumer<KitchenProvider>(
            builder: (context, kitchen, _) {
              final count = kitchen.pendingOrders.length;
              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  backgroundColor: Colors.deepOrange,
                  child: const Icon(Icons.soup_kitchen),
                ),
                tooltip: 'Layar Dapur (KDS)',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KitchenScreen()),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      backgroundColor: Colors.brown[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.brown[100],
                        child: const Icon(Icons.coffee, size: 40, color: Colors.brown),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Selamat Datang, ${user?.username ?? "Kasir"}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID Kasir: ${user?.id ?? "-"} • Role: ${user?.role.name.toUpperCase() ?? "-"}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const Divider(height: 32),
                      if (!isShiftActive) ...[
                        const Text(
                          'Input Modal Awal Shift',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masukkan saldo kas laci awal sebelum memulai transaksi penjualan.',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _modalController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Modal Awal (Rp)',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.lock_open),
                            label: const Text('Buka Shift'),
                            onPressed: _startShift,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Shift Aktif (Modal Awal: Rp ${shift.initialCapital.toStringAsFixed(0)})',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Siap melayani pesanan kopi dan transaksi.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.point_of_sale),
                            label: const Text('Masuk ke Kasir POS'),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const CashierPOSScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
