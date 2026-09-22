import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'auth_provider.dart';

class ManageCashierScreen extends StatefulWidget {
  const ManageCashierScreen({super.key});

  @override
  State<ManageCashierScreen> createState() => _ManageCashierScreenState();
}

class _ManageCashierScreenState extends State<ManageCashierScreen> {
  void _showAddCashierDialog() {
    final nameController = TextEditingController();
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Colors.brown),
              SizedBox(width: 8),
              Text('Tambah Akun Kasir Baru'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kasir / Username',
                  hintText: 'Contoh: Kasir C',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN Login (6 Digit Angka)',
                  hintText: 'Misal: 333333',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final pin = pinController.text.trim();
                if (name.isNotEmpty && pin.length == 6) {
                  await context.read<AuthProvider>().addCashier(name, pin);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Akun Kasir "$name" berhasil ditambahkan')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mohon isi nama dan PIN 6 digit dengan benar')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showResetPinDialog(UserModel cashier) {
    final newPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reset PIN "${cashier.username}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan 6 digit PIN baru untuk akun kasir ini:'),
              const SizedBox(height: 14),
              TextField(
                controller: newPinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'PIN Baru (6 Digit)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newPin = newPinController.text.trim();
                if (newPin.length == 6) {
                  await context.read<AuthProvider>().resetUserPin(cashier.id, newPin);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PIN kasir "${cashier.username}" berhasil direset')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN harus 6 digit angka')),
                  );
                }
              },
              child: const Text('Simpan PIN'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCashier(UserModel cashier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hapus Akun "${cashier.username}"?'),
          content: Text('Akun kasir ini akan dihapus secara permanen dari database.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await context.read<AuthProvider>().deleteUser(cashier.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Akun kasir "${cashier.username}" dihapus')),
                  );
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final cashiers = authProvider.cashiers;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Manajemen Akun Kasir',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddCashierDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Kasir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: cashiers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        const Text('Belum ada akun kasir terdaftar.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: cashiers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final cashier = cashiers[index];
                      final isAktif = cashier.status == UserStatus.aktif;

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: LayoutBuilder(
                            builder: (context, cardBox) {
                              final isCardNarrow = cardBox.maxWidth < 460;
                              if (isCardNarrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: isAktif ? Colors.green : Colors.red,
                                          child: const Icon(Icons.person, color: Colors.white, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(cashier.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                              Text(
                                                'ID: ${cashier.id} • Status: ${cashier.status.name.toUpperCase()}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isAktif ? Colors.green[800] : Colors.red[800],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(height: 1),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          icon: Icon(isAktif ? Icons.block : Icons.check_circle, size: 16),
                                          label: Text(
                                            isAktif ? 'Non-aktifkan' : 'Aktifkan',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isAktif ? Colors.red[700] : Colors.green[700],
                                            ),
                                          ),
                                          onPressed: () => authProvider.toggleUserStatus(cashier.id),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.vpn_key, size: 18, color: Colors.brown),
                                          onPressed: () => _showResetPinDialog(cashier),
                                          tooltip: 'Reset PIN',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          onPressed: () => _confirmDeleteCashier(cashier),
                                          tooltip: 'Hapus Kasir',
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              } else {
                                return Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isAktif ? Colors.green : Colors.red,
                                      child: const Icon(Icons.person, color: Colors.white, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(cashier.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text(
                                            'ID: ${cashier.id} • Status: ${cashier.status.name.toUpperCase()}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isAktif ? Colors.green[800] : Colors.red[800],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton.icon(
                                      icon: Icon(isAktif ? Icons.block : Icons.check_circle, size: 16),
                                      label: Text(
                                        isAktif ? 'Non-aktifkan' : 'Aktifkan',
                                        style: TextStyle(
                                          color: isAktif ? Colors.red[700] : Colors.green[700],
                                        ),
                                      ),
                                      onPressed: () => authProvider.toggleUserStatus(cashier.id),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.vpn_key, color: Colors.brown),
                                      onPressed: () => _showResetPinDialog(cashier),
                                      tooltip: 'Reset PIN',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _confirmDeleteCashier(cashier),
                                      tooltip: 'Hapus Kasir',
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}