import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'models.dart';

class PrinterService {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  // Mendapatkan daftar printer bluetooth yang sudah dipairing di perangkat
  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await bluetooth.getBondedDevices();
  }

  // Menghubungkan aplikasi ke printer pilihan
  Future<void> connect(BluetoothDevice device) async {
    await bluetooth.connect(device);
  }

  // Memutuskan koneksi printer
  Future<void> disconnect() async {
    await bluetooth.disconnect();
  }

  // Logika penyusunan dan pencetakan struk
  Future<void> printReceipt(TransactionModel trx) async {
    bool? isConnected = await bluetooth.isConnected;
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    if (isConnected == true) {
      bluetooth.printNewLine();
      
      // Header Struk (Teks besar dan rata tengah)
      bluetooth.printCustom("COFFEE SHOP POS", 2, 1);
      bluetooth.printCustom("ID: ${trx.id}", 0, 1);
      bluetooth.printCustom("Kasir: ${trx.cashierName}", 0, 1);
      bluetooth.printCustom("Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(trx.date)}", 0, 1);
      bluetooth.printNewLine();

      // Rincian Pesanan
      for (var item in trx.items) {
        // Format Left-Right: "Nama Item" di kiri, "Harga" di kanan
        bluetooth.printLeftRight(
          "${item.quantity}x ${item.product.name}",
          formatCurrency.format(item.totalPrice),
          0,
        );
        // Catatan varian jika ada
        if (item.modifier.isNotEmpty) {
          bluetooth.printCustom("   Varian: ${item.modifier}", 0, 0); 
        }
      }

      bluetooth.printNewLine();
      
      // Footer & Total Pembayaran
      bluetooth.printLeftRight("TOTAL", formatCurrency.format(trx.totalAmount), 1);
      bluetooth.printLeftRight("Bayar (${trx.paymentMethod})", formatCurrency.format(trx.paymentAmount), 0);
      
      if (trx.paymentMethod == 'Tunai') {
        bluetooth.printLeftRight("Kembali", formatCurrency.format(trx.changeAmount), 0);
      }

      bluetooth.printNewLine();
      bluetooth.printCustom("Terima Kasih!", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      
      // Perintah memotong kertas (jika printer mendukung auto-cutter)
      bluetooth.paperCut();
    }
  }
}