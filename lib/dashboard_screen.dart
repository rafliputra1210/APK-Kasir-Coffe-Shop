import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'transaction_provider.dart';
import 'models.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
      child: Consumer<TransactionProvider>(
        builder: (context, trxProvider, child) {
          final transactions = trxProvider.history;
          final now = DateTime.now();

          // 1. Perhitungan Analitik Penjualan
          double dailySales = 0;
          double weeklySales = 0;
          double monthlySales = 0;

          // Map untuk menyimpan rangkuman performa per kasir
          Map<String, Map<String, dynamic>> cashierStats = {};

          for (var trx in transactions) {
            // Logika Penjualan Harian
            if (trx.date.year == now.year && trx.date.month == now.month && trx.date.day == now.day) {
              dailySales += trx.totalAmount;
            }
            // Logika Penjualan Mingguan (7 hari terakhir)
            if (now.difference(trx.date).inDays <= 7) {
              weeklySales += trx.totalAmount;
            }
            // Logika Penjualan Bulanan
            if (trx.date.year == now.year && trx.date.month == now.month) {
              monthlySales += trx.totalAmount;
            }

            // Agregasi Data per Kasir dengan Waktu Shift & Transaksi Akurat
            if (!cashierStats.containsKey(trx.cashierName)) {
              cashierStats[trx.cashierName] = {
                'transactions': 0,
                'revenue': 0.0,
                'voids': 0,
                'firstTrx': trx.date,
                'lastTrx': trx.date,
                'shiftStart': trx.shiftStartTime ?? trx.date,
              };
            }
            cashierStats[trx.cashierName]!['transactions'] = (cashierStats[trx.cashierName]!['transactions'] as int) + 1;
            cashierStats[trx.cashierName]!['revenue'] = (cashierStats[trx.cashierName]!['revenue'] as double) + trx.totalAmount;

            final currentFirst = cashierStats[trx.cashierName]!['firstTrx'] as DateTime;
            if (trx.date.isBefore(currentFirst)) {
              cashierStats[trx.cashierName]!['firstTrx'] = trx.date;
            }

            final currentLast = cashierStats[trx.cashierName]!['lastTrx'] as DateTime;
            if (trx.date.isAfter(currentLast)) {
              cashierStats[trx.cashierName]!['lastTrx'] = trx.date;
            }

            if (trx.shiftStartTime != null) {
              final currentShiftStart = cashierStats[trx.cashierName]!['shiftStart'] as DateTime;
              if (trx.shiftStartTime!.isBefore(currentShiftStart)) {
                cashierStats[trx.cashierName]!['shiftStart'] = trx.shiftStartTime;
              }
            }
          }

          // Urutkan transaksi dari yang terbaru
          final sortedTransactions = List<TransactionModel>.from(transactions)
            ..sort((a, b) => b.date.compareTo(a.date));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dasbor Laporan & Analitik',
                style: TextStyle(fontSize: isMobile ? 20 : 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              
              // Kartu Ringkasan Penjualan Responsif
              LayoutBuilder(
                builder: (context, boxConstraints) {
                  final isNarrow = boxConstraints.maxWidth < 650;
                  if (isNarrow) {
                    return Column(
                      children: [
                        _buildSummaryCard('Penjualan Harian', dailySales, formatCurrency, Colors.blue, isCompact: true),
                        const SizedBox(height: 8),
                        _buildSummaryCard('Penjualan Mingguan', weeklySales, formatCurrency, Colors.green, isCompact: true),
                        const SizedBox(height: 8),
                        _buildSummaryCard('Penjualan Bulanan', monthlySales, formatCurrency, Colors.orange, isCompact: true),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        _buildSummaryCard('Penjualan Harian', dailySales, formatCurrency, Colors.blue, isCompact: false),
                        const SizedBox(width: 12),
                        _buildSummaryCard('Penjualan Mingguan', weeklySales, formatCurrency, Colors.green, isCompact: false),
                        const SizedBox(width: 12),
                        _buildSummaryCard('Penjualan Bulanan', monthlySales, formatCurrency, Colors.orange, isCompact: false),
                      ],
                    );
                  }
                },
              ),
              
              const SizedBox(height: 32),
              const Row(
                children: [
                  Icon(Icons.badge_outlined, color: Colors.brown, size: 26),
                  SizedBox(width: 8),
                  Text('Laporan Performa Kasir (Jam Buka - Tutup Shift)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              
              // Tabel Filter Penjualan per Kasir
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: cashierStats.isEmpty 
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('Belum ada data transaksi kasir.', style: TextStyle(color: Colors.grey, fontSize: 16))),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.brown[50]),
                        columns: const [
                          DataColumn(label: Text('Nama Kasir', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Jam Buka Shift / Awal', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Jam Tutup / Terakhir', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Jml Transaksi', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Total Pendapatan', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Void / Retur', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: cashierStats.entries.map((entry) {
                          String cashierName = entry.key;
                          DateTime shiftStart = entry.value['shiftStart'] as DateTime;
                          DateTime lastTrx = entry.value['lastTrx'] as DateTime;
                          int trxCount = entry.value['transactions'] as int;
                          double revenue = entry.value['revenue'] as double;
                          int voids = entry.value['voids'] as int;
                          
                          return DataRow(
                            cells: [
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.brown[100],
                                    child: Text(cashierName.isNotEmpty ? cashierName[0].toUpperCase() : 'K', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(cashierName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              )),
                              DataCell(Text(dateFormat.format(shiftStart), style: const TextStyle(fontSize: 13, color: Colors.black87))),
                              DataCell(Text(dateFormat.format(lastTrx), style: const TextStyle(fontSize: 13, color: Colors.black87))),
                              DataCell(Text('$trxCount transaksi')),
                              DataCell(Text(formatCurrency.format(revenue), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: voids > 0 ? Colors.red[100] : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    voids.toString(), 
                                    style: TextStyle(color: voids > 0 ? Colors.red : Colors.black, fontWeight: voids > 0 ? FontWeight.bold : FontWeight.normal)
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
              ),

              const SizedBox(height: 32),
              const Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.brown, size: 26),
                  SizedBox(width: 8),
                  Text('Rincian Transaksi Akurat (Waktu & Tanggal Lengkap)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),

              // Tabel Rincian Semua Transaksi
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: sortedTransactions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('Belum ada riwayat transaksi.', style: TextStyle(color: Colors.grey, fontSize: 16))),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.brown[50]),
                        columns: const [
                          DataColumn(label: Text('Waktu & Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ID Transaksi', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Kasir', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('No. Meja', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Metode Bayar', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Menu Pesanan', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: sortedTransactions.map((trx) {
                          final itemsSummary = trx.items
                              .map((i) => '${i.quantity}x ${i.product.name}${i.modifier.isNotEmpty ? " (${i.modifier})" : ""}')
                              .join(', ');

                          return DataRow(
                            cells: [
                              DataCell(Text(dateFormat.format(trx.date), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                              DataCell(Text(trx.id, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                              DataCell(Text(trx.cashierName)),
                              DataCell(Text(trx.tableNumber ?? '-', style: TextStyle(fontWeight: trx.tableNumber != null ? FontWeight.bold : FontWeight.normal))),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: trx.paymentMethod == 'Tunai' ? Colors.blue.shade50 : Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: trx.paymentMethod == 'Tunai' ? Colors.blue.shade200 : Colors.purple.shade200),
                                ),
                                child: Text(trx.paymentMethod, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: trx.paymentMethod == 'Tunai' ? Colors.blue.shade800 : Colors.purple.shade800)),
                              )),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(itemsSummary, overflow: TextOverflow.ellipsis, maxLines: 1),
                                ),
                              ),
                              DataCell(Text(formatCurrency.format(trx.totalAmount), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, NumberFormat format, Color color, {bool isCompact = false}) {
    final cardContent = Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: isCompact ? 10.0 : 16.0),
        child: isCompact
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                  Text(
                    format.format(amount),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(
                    format.format(amount),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
      ),
    );

    return isCompact ? cardContent : Expanded(child: cardContent);
  }
}