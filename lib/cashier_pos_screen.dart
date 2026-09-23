import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'cart_provider.dart';
import 'auth_provider.dart';
import 'menu_provider.dart';
import 'shift_provider.dart';
import 'transaction_provider.dart';
import 'kitchen_provider.dart';
import 'kitchen_screen.dart';
import 'cashier_screen.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'printer_service.dart';
import 'product_image_widget.dart';

class CashierPOSScreen extends StatefulWidget {
  const CashierPOSScreen({super.key});

  @override
  State<CashierPOSScreen> createState() => _CashierPOSScreenState();
}

class _CashierPOSScreenState extends State<CashierPOSScreen> {
  String _selectedCategoryId = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final PrinterService _printerService = PrinterService();
  BluetoothDevice? _selectedPrinter;
  bool _showSideCartInLandscape = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showModifierDialog(Product product) {
    if (product.modifiers.isEmpty) {
      context.read<CartProvider>().addToCart(product);
      return;
    }

    Map<String, ModifierOption> selectedOptions = {};
    for (var mod in product.modifiers) {
      if (mod.options.isNotEmpty) {
        selectedOptions[mod.id] = mod.options.first;
      }
    }

    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: Color(0xFF43A047)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pilih Varian: ${product.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width < 450 ? double.maxFinite : 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.imagePath.trim().isNotEmpty) ...[
                        Center(
                          child: ProductImageWidget(
                            imagePath: product.imagePath,
                            width: 110,
                            height: 110,
                            isCircularPlate: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      ...product.modifiers.map((mod) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: mod.options.map((opt) {
                                final isSelected = selectedOptions[mod.id] == opt;
                                final priceText = opt.additionalPrice > 0
                                    ? ' (+Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(opt.additionalPrice).trim()})'
                                    : '';
                                return ChoiceChip(
                                  label: Text('${opt.name}$priceText'),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFFE8F5E9),
                                  labelStyle: TextStyle(
                                    color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(() => selectedOptions[mod.id] = opt);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                            const Divider(height: 24),
                          ],
                        );
                      }),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Khusus (Opsional)',
                          hintText: 'Contoh: Jangan terlalu manis / Sambal dipisah',
                          border: OutlineInputBorder(),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    String combinedModifierName = selectedOptions.values.map((e) => e.name).join(', ');
                    double combinedModifierPrice = selectedOptions.values.fold(0, (sum, item) => sum + item.additionalPrice);

                    context.read<CartProvider>().addToCart(
                      product,
                      modifier: combinedModifierName,
                      modPrice: combinedModifierPrice,
                      notes: notesController.text.trim(),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Tambahkan ke Order'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _processPayment() {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    String selectedPaymentMethod = 'Tunai';
    final cashController = TextEditingController(text: cart.grandTotal.toStringAsFixed(0));
    final tableController = TextEditingController();
    double change = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double cashInput = double.tryParse(cashController.text) ?? 0;
            change = selectedPaymentMethod == 'Tunai' ? (cashInput - cart.grandTotal) : 0.0;
            bool isPaymentValid = selectedPaymentMethod != 'Tunai' || cashInput >= cart.grandTotal;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.payment, color: Color(0xFF43A047)),
                  const SizedBox(width: 8),
                  Text('Pembayaran (${cart.orderType})'),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Tagihan
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: Column(
                          children: [
                            const Text('Total yang Harus Dibayar:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              formatCurrency.format(cart.grandTotal),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            Text(
                              '(Subtotal: ${formatCurrency.format(cart.subtotal)} • Pajak: ${formatCurrency.format(cart.taxAmount)})',
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Input Nomor Meja / Nama Pemesan
                      TextField(
                        controller: tableController,
                        decoration: InputDecoration(
                          labelText: cart.orderType == 'Dine In' ? 'Nomor Meja (Wajib Dine In)' : 'Nama Pelanggan (Take Away)',
                          prefixIcon: Icon(cart.orderType == 'Dine In' ? Icons.table_restaurant : Icons.person_outline),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pilihan Metode Pembayaran
                      const Text('Metode Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['Tunai', 'QRIS', 'Debit', 'Transfer'].map((method) {
                          final isSelected = selectedPaymentMethod == method;
                          return ChoiceChip(
                            label: Text(method),
                            selected: isSelected,
                            selectedColor: const Color(0xFF43A047),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  selectedPaymentMethod = method;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Input Uang Tunai
                      if (selectedPaymentMethod == 'Tunai') ...[
                        TextField(
                          controller: cashController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Uang Diterima (Rp)',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) => setDialogState(() {}),
                        ),
                        const SizedBox(height: 8),

                        // Tombol Cepat Nominal Uang
                        Wrap(
                          spacing: 6,
                          children: [
                            OutlinedButton(
                              onPressed: () => setDialogState(() => cashController.text = cart.grandTotal.toStringAsFixed(0)),
                              child: const Text('Uang Pas'),
                            ),
                            OutlinedButton(
                              onPressed: () => setDialogState(() => cashController.text = '50000'),
                              child: const Text('50k'),
                            ),
                            OutlinedButton(
                              onPressed: () => setDialogState(() => cashController.text = '100000'),
                              child: const Text('100k'),
                            ),
                            OutlinedButton(
                              onPressed: () => setDialogState(() => cashController.text = '200000'),
                              child: const Text('200k'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Info Kembalian
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kembalian:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            Text(
                              change >= 0 ? formatCurrency.format(change) : 'Uang Kurang',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: change >= 0 ? const Color(0xFF2E7D32) : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: !isPaymentValid
                      ? null
                      : () {
                          String trxId = 'TRX-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
                          final newTransaction = TransactionModel(
                            id: trxId,
                            date: DateTime.now(),
                            cashierName: auth.currentUser?.username ?? 'Kasir',
                            items: List.from(cart.items),
                            totalAmount: cart.grandTotal,
                            paymentAmount: selectedPaymentMethod == 'Tunai'
                                ? (double.tryParse(cashController.text) ?? cart.grandTotal)
                                : cart.grandTotal,
                            changeAmount: selectedPaymentMethod == 'Tunai' && change > 0 ? change : 0.0,
                            paymentMethod: selectedPaymentMethod,
                            tableNumber: tableController.text.trim().isNotEmpty
                                ? '${cart.orderType} - ${tableController.text.trim()}'
                                : cart.orderType,
                            shiftStartTime: context.read<ShiftProvider>().shiftStartTime,
                          );

                          context.read<TransactionProvider>().addTransaction(newTransaction);
                          context.read<ShiftProvider>().recordTransaction(cart.grandTotal);
                          context.read<KitchenProvider>().addOrder(newTransaction);

                          cart.clearCart();
                          Navigator.pop(context);
                          _showReceiptDialog(newTransaction);
                        },
                  child: const Text('KONFIRMASI BAYAR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReceiptDialog(TransactionModel trx) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Center(
            child: Text('STRUK PEMBAYARAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('COFFEE SHOP & RESTO POS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(trx.id, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('Kasir: ${trx.cashierName}', style: const TextStyle(fontSize: 12)),
                  Text(dateFormat.format(trx.date), style: const TextStyle(fontSize: 12)),
                  if (trx.tableNumber != null)
                    Text('Pesanan: ${trx.tableNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const Divider(thickness: 1, height: 20),
                  ...trx.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.quantity}x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name),
                                if (item.modifier.isNotEmpty)
                                  Text(item.modifier, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Text(formatCurrency.format(item.totalPrice)),
                        ],
                      ),
                    );
                  }),
                  const Divider(thickness: 1, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL AKHIR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(formatCurrency.format(trx.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bayar (${trx.paymentMethod})'),
                      Text(formatCurrency.format(trx.paymentAmount)),
                    ],
                  ),
                  if (trx.paymentMethod == 'Tunai')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembali'),
                        Text(formatCurrency.format(trx.changeAmount)),
                      ],
                    ),
                  const SizedBox(height: 20),
                  const Text('Terima Kasih Atas Kunjungan Anda!', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('Cetak Struk'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  List<BluetoothDevice> devices = await _printerService.getBondedDevices();
                  if (devices.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tidak ada printer bluetooth yang terhubung/dipasangkan.')),
                      );
                    }
                    return;
                  }

                  BluetoothDevice? targetPrinter;
                  if (devices.length == 1) {
                    targetPrinter = devices.first;
                  } else {
                    if (context.mounted) {
                      targetPrinter = await _choosePrinterDialog(context, devices);
                    }
                    if (targetPrinter == null) return;
                  }

                  _selectedPrinter = targetPrinter;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Menghubungkan ke ${_selectedPrinter?.name ?? "Printer"}...')),
                    );
                  }

                  await _printerService.connect(_selectedPrinter!);
                  await _printerService.printReceipt(trx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Berhasil mencetak struk!')),
                    );
                    Navigator.pop(context);
                  }
                  await _printerService.disconnect();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal mencetak: $e. Pastikan printer aktif.')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<BluetoothDevice?> _choosePrinterDialog(BuildContext context, List<BluetoothDevice> devices) async {
    return showDialog<BluetoothDevice>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.print, color: Color(0xFF43A047)),
              SizedBox(width: 8),
              Text('Pilih Printer Bluetooth'),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: devices.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final d = devices[i];
                return ListTile(
                  leading: const Icon(Icons.bluetooth, color: Colors.blue),
                  title: Text(d.name ?? 'Printer Thermal', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(d.address ?? '-'),
                  onTap: () => Navigator.pop(ctx, d),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  void _showHeldOrdersDialog(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer<CartProvider>(
          builder: (context, cart, _) {
            final held = cart.heldOrders;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.bookmark, color: Color(0xFFFFA000)),
                  const SizedBox(width: 8),
                  Text('Daftar Order Tersimpan (${held.length})'),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: held.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30.0),
                        child: Center(child: Text('Tidak ada order yang sedang disimpan/ditahan.')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: held.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, i) {
                          final h = held[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFFFF8E1),
                              child: const Icon(Icons.restaurant, color: Color(0xFFFFA000)),
                            ),
                            title: Text(
                              '${h.orderType} • ${formatCurrency.format(h.totalAmount)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${h.items.length} item • ${DateFormat('HH:mm').format(h.createdAt)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => cart.deleteHeldOrder(h.id),
                                  tooltip: 'Hapus',
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF43A047),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  onPressed: () {
                                    cart.restoreHeldOrder(h.id);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Order berhasil dimuat kembali ke keranjang')),
                                    );
                                  },
                                  child: const Text('Buka'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showHistoryDialog(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer<TransactionProvider>(
          builder: (context, trxProvider, _) {
            final transactions = trxProvider.history;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFF43A047)),
                  const SizedBox(width: 8),
                  Text('Riwayat Transaksi (${transactions.length})'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: transactions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30.0),
                        child: Center(child: Text('Belum ada transaksi di shift ini.')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: transactions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final trx = transactions[index];
                          return ListTile(
                            title: Text(trx.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('${dateFormat.format(trx.date)} • ${trx.items.length} item • ${trx.paymentMethod}'),
                            trailing: Text(
                              formatCurrency.format(trx.totalAmount),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                            ),
                            onTap: () {
                              _showReceiptDialog(trx);
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCloseShiftDialog() {
    final shiftProvider = context.read<ShiftProvider>();
    final auth = context.read<AuthProvider>();
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Tutup Shift Kasir?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kasir: ${auth.currentUser?.username ?? "Kasir"}'),
              const SizedBox(height: 8),
              Text('Modal Awal: ${formatCurrency.format(shiftProvider.initialCapital)}'),
              Text('Total Penjualan: ${formatCurrency.format(shiftProvider.totalSales)}'),
              Text('Total Transaksi: ${shiftProvider.transactionCount} kali'),
              const Divider(height: 16),
              Text(
                'Total Uang Laci Kas: ${formatCurrency.format(shiftProvider.finalCashTotal)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E7D32)),
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
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                shiftProvider.closeShift(cashierName: auth.currentUser?.username ?? 'Kasir');
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CashierScreen()),
                );
              },
              child: const Text('Tutup Shift & Keluar'),
            ),
          ],
        );
      },
    );
  }

  // --- PANEL ORDER / BILLING (KIRI SESUAI FOTO REFERENSI) ---
  Widget _buildLeftOrderPanel(
    BuildContext context,
    CartProvider cart,
    NumberFormat formatCurrency, {
    bool isBottomSheet = false,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Order Panel: Dine In Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dine In Selector Pill
                InkWell(
                  onTap: () {
                    // Toggle Dine In / Take Away
                    final next = cart.orderType == 'Dine In' ? 'Take Away' : 'Dine In';
                    cart.setOrderType(next);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          cart.orderType,
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_right, size: 18, color: Color(0xFF2E7D32)),
                      ],
                    ),
                  ),
                ),
                // Tombol Kosongkan Order
                if (cart.items.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                    tooltip: 'Kosongkan Pesanan',
                    onPressed: () {
                      cart.clearCart();
                    },
                  ),
              ],
            ),
          ),

          // Daftar Item Pesanan
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text(
                          'Belum ada pesanan',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ketuk menu di kanan untuk menambah',
                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kuantitas counter
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => cart.decrementQuantity(index),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.remove, size: 14, color: Colors.black87),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => cart.incrementQuantity(index),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.add, size: 14, color: Color(0xFF2E7D32)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            // Nama Item & Varian
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.modifier.isNotEmpty)
                                    Text(
                                      item.modifier,
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                  if (item.notes.isNotEmpty)
                                    Text(
                                      'Note: ${item.notes}',
                                      style: const TextStyle(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic),
                                    ),
                                ],
                              ),
                            ),
                            // Harga Subtotal
                            Text(
                              formatCurrency.format(item.totalPrice),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Rincian Tagihan (Sesuai Persis Tampilan Referensi)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Sebelum Pajak
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sebelum pajak', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    Text(formatCurrency.format(cart.subtotal), style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                // Pajak (5%)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pajak (5%)', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    Text(formatCurrency.format(cart.taxAmount), style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                // Service Charge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Service charge', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    Text(formatCurrency.format(cart.serviceCharge), style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                  ],
                ),
                const Divider(height: 18),
                // TOTAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      formatCurrency.format(cart.grandTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                if (isBottomSheet) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Simpan Order (Hold)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFA000),
                            side: const BorderSide(color: Color(0xFFFFA000)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          onPressed: cart.items.isEmpty
                              ? null
                              : () {
                                  cart.holdCurrentOrder();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Order berhasil disimpan ke draft')),
                                  );
                                },
                          child: const Text('Simpan Order', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Bayar
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          onPressed: cart.items.isEmpty
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _processPayment();
                                },
                          child: const Text('Bayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileCartBottomSheet(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer<CartProvider>(
          builder: (context, cart, child) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: _buildLeftOrderPanel(
                      context,
                      cart,
                      formatCurrency,
                      isBottomSheet: true,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final auth = context.watch<AuthProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final cart = context.watch<CartProvider>();
    final products = menuProvider.products;
    final categories = menuProvider.categories;

    // Filter Kategori & Pencarian
    final filteredProducts = products.where((p) {
      final matchesCategory = _selectedCategoryId == 'ALL' || p.categoryId == _selectedCategoryId;
      final matchesSearch = _searchQuery.isEmpty || p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isLandscape = screenWidth > screenHeight;
        final isShortScreen = screenHeight < 550;

        // Pada mode layar lebar / tablet POS (seperti di foto), order panel berada di sebelah KIRI
        final canUseLeftPanel = (screenWidth >= 880) || (isLandscape && screenWidth >= 680);
        final isLeftPanelVisible = canUseLeftPanel && (_showSideCartInLandscape || screenWidth >= 880);
        final leftPanelWidth = isShortScreen ? 270.0 : (screenWidth >= 1100 ? 350.0 : 310.0);

        // Hitung kolom grid untuk katalog menu
        final availableCatalogWidth = isLeftPanelVisible ? (screenWidth - leftPanelWidth) : screenWidth;
        int crossAxisCount = 2;
        double childAspectRatio = 0.92;

        if (availableCatalogWidth >= 900) {
          crossAxisCount = 5;
          childAspectRatio = 0.88;
        } else if (availableCatalogWidth >= 680) {
          crossAxisCount = 4;
          childAspectRatio = 0.86;
        } else if (availableCatalogWidth >= 480) {
          crossAxisCount = 3;
          childAspectRatio = 0.85;
        } else {
          crossAxisCount = 2;
          childAspectRatio = 0.82;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7F9), // Latar abu-abu terang modern POS
          appBar: AppBar(
            toolbarHeight: isShortScreen ? 46 : 54,
            elevation: 0,
            backgroundColor: const Color(0xFF43A047), // Hijau Segar POS sesuai gambar
            foregroundColor: Colors.white,
            title: Row(
              children: [
                const Icon(Icons.point_of_sale, size: 22),
                const SizedBox(width: 8),
                Text(
                  'POS - ${auth.currentUser?.username ?? "Kasir"}',
                  style: TextStyle(
                    fontSize: isShortScreen ? 14 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              // Tombol Daftar Order Tersimpan (Held Orders)
              if (cart.heldOrders.isNotEmpty)
                IconButton(
                  icon: Badge(
                    label: Text('${cart.heldOrders.length}'),
                    backgroundColor: const Color(0xFFFFA000),
                    child: const Icon(Icons.bookmark_outline, color: Colors.white),
                  ),
                  tooltip: 'Order Tersimpan',
                  onPressed: () => _showHeldOrdersDialog(context),
                ),
              // Riwayat Transaksi
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                tooltip: 'Riwayat Transaksi',
                onPressed: () => _showHistoryDialog(context),
              ),
              // Layar Dapur (KDS)
              Consumer<KitchenProvider>(
                builder: (context, kitchen, _) {
                  final count = kitchen.pendingOrders.length;
                  return IconButton(
                    icon: Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      backgroundColor: Colors.deepOrange,
                      child: const Icon(Icons.soup_kitchen, color: Colors.white),
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
              // Toggle Panel Kiri di landscape
              if (canUseLeftPanel && screenWidth < 880)
                IconButton(
                  icon: Icon(
                    _showSideCartInLandscape ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                    color: Colors.white,
                  ),
                  tooltip: 'Tampilkan/Sembunyikan Order',
                  onPressed: () {
                    setState(() {
                      _showSideCartInLandscape = !_showSideCartInLandscape;
                    });
                  },
                ),
              // Tutup Shift
              IconButton(
                icon: const Icon(Icons.power_settings_new, color: Colors.white),
                tooltip: 'Tutup Shift',
                onPressed: _showCloseShiftDialog,
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Bottom bar hanya untuk tampilan ponsel portrait
          bottomNavigationBar: (!isLeftPanelVisible)
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, -3)),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Badge Keranjang
                        InkWell(
                          onTap: () => _showMobileCartBottomSheet(context),
                          child: Row(
                            children: [
                              Badge(
                                label: Text('${cart.items.fold(0, (sum, i) => sum + i.quantity)}'),
                                backgroundColor: const Color(0xFF43A047),
                                child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF2E7D32), size: 28),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    cart.orderType,
                                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                                  ),
                                  Text(
                                    formatCurrency.format(cart.grandTotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Tombol Simpan Order
                        if (cart.items.isNotEmpty) ...[
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFFA000),
                              side: const BorderSide(color: Color(0xFFFFA000)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {
                              cart.holdCurrentOrder();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order berhasil disimpan')),
                              );
                            },
                            child: const Text('Simpan'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Tombol Bayar
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          onPressed: cart.items.isEmpty ? () => _showMobileCartBottomSheet(context) : _processPayment,
                          child: const Text('Bayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                )
              : null,

          body: Row(
            children: [
              // ==========================================
              // KIRI: PANEL ORDER / BILLING (SESUAI FOTO)
              // ==========================================
              if (isLeftPanelVisible)
                SizedBox(
                  width: leftPanelWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(right: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: _buildLeftOrderPanel(context, cart, formatCurrency),
                  ),
                ),

              // ==========================================
              // KANAN: KATALOG MENU (GRID MODERN POS)
              // ==========================================
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // BAR ATAS: TAB KATEGORI (HIJAU SEGANG SEPERTI FOTO) & PENCARIAN
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tab Kategori Horizontal
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildCategoryTab(
                                      title: 'Semua',
                                      isSelected: _selectedCategoryId == 'ALL',
                                      onTap: () => setState(() => _selectedCategoryId = 'ALL'),
                                    ),
                                    ...categories.map((cat) {
                                      final isSelected = _selectedCategoryId == cat.id;
                                      return _buildCategoryTab(
                                        title: cat.name,
                                        isSelected: isSelected,
                                        onTap: () => setState(() => _selectedCategoryId = cat.id),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Bar Pencarian: "Cari Produk"
                              Container(
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300, width: 0.8),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Cari Produk...',
                                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 16),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val.trim();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // GRID PRODUK (CARD PUTIH DENGAN PIRING SAJI MELINGKAR)
                        Expanded(
                          child: filteredProducts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'Tidak ditemukan produk "$_searchQuery"'
                                            : 'Belum ada menu di kategori ini.',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 80), // Padding bawah untuk tombol floating
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: childAspectRatio,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = filteredProducts[index];
                                    return _buildModernProductCard(context, product, formatCurrency);
                                  },
                                ),
                        ),
                      ],
                    ),

                    // ==========================================
                    // TOMBOL AKSI MELAYANG DI KANAN BAWAH (SESUAI FOTO)
                    // ==========================================
                    if (isLeftPanelVisible)
                      Positioned(
                        bottom: 16,
                        right: 18,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tombol: "Simpan Order" (Warna Kuning/Amber Pill)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA000), // Amber keemasan
                                foregroundColor: Colors.white,
                                elevation: 4,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              icon: const Icon(Icons.bookmark_border, size: 18),
                              label: const Text(
                                'Simpan Order',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: cart.items.isEmpty
                                  ? null
                                  : () {
                                      cart.holdCurrentOrder();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Order berhasil disimpan ke draft.'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                            ),
                            const SizedBox(width: 10),

                            // Tombol: "Bayar" (Warna Hijau Cerah Pill Menonjol)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF43A047), // Hijau Segar POS
                                foregroundColor: Colors.white,
                                elevation: 4,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text(
                                'Bayar',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              onPressed: cart.items.isEmpty ? null : _processPayment,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget Tab Kategori (Pill Hijau untuk yang dipilih)
  Widget _buildCategoryTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF43A047) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF388E3C) : Colors.grey.shade300,
              width: 0.8,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF374151),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // Widget Card Produk Modern (Persis Foto: Piring Bulat di Atas, Nama & Harga Rapi di Bawah)
  Widget _buildModernProductCard(
    BuildContext context,
    Product product,
    NumberFormat formatCurrency,
  ) {
    return InkWell(
      onTap: product.isAvailable ? () => _showModifierDialog(product) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: product.isAvailable ? Colors.white : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Foto Sajian Piring Bulat (Circular Plate Presentation)
                  Expanded(
                    child: Center(
                      child: ProductImageWidget(
                        imagePath: product.imagePath,
                        width: 95,
                        height: 95,
                        isCircularPlate: true,
                        defaultIcon: Icons.restaurant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Nama Menu (Tebal di Tengah)
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: product.isAvailable ? const Color(0xFF1F2937) : Colors.grey[500],
                      height: 1.15,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Harga Produk
                  Text(
                    formatCurrency.format(product.basePrice),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: product.isAvailable ? const Color(0xFF4B5563) : Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Badge Varian jika ada
            if (product.modifiers.isNotEmpty && product.isAvailable)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFFB74D), width: 0.6),
                  ),
                  child: const Text(
                    '+Varian',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                  ),
                ),
              ),

            // Overlay Habis
            if (!product.isAvailable)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'HABIS',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}