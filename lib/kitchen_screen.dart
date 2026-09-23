import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'kitchen_provider.dart';

class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    return isMobile
        ? _buildMobileLayout(context)
        : _buildTabletDesktopLayout(context);
  }

  // Tampilan Tablet & Desktop / Layar KDS Dapur (2 Kolom Berdampingan)
  Widget _buildTabletDesktopLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KITCHEN DISPLAY SYSTEM (KDS)', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        actions: [
          _buildClearCompletedAction(context),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- KOLOM KIRI: SEDANG DISIAPKAN (PENDING) ---
          Expanded(
            child: Container(
              color: Colors.orange[50],
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange[200],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sedang Disiapkan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        Consumer<KitchenProvider>(
                          builder: (context, kitchen, child) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${kitchen.pendingOrders.length} Antrean',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Consumer<KitchenProvider>(
                      builder: (context, kitchen, child) {
                        if (kitchen.pendingOrders.isEmpty) {
                          return const Center(child: Text('Belum ada pesanan masuk.', style: TextStyle(fontSize: 16, color: Colors.grey)));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: kitchen.pendingOrders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderTicket(context, kitchen.pendingOrders[index], isActive: true);
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
          
          const VerticalDivider(width: 2, thickness: 2, color: Colors.grey),
          
          // --- KOLOM KANAN: PESANAN SELESAI ---
          Expanded(
            child: Container(
              color: Colors.green[50],
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.green[200],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Selesai (Siap Diambil)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                        Consumer<KitchenProvider>(
                          builder: (context, kitchen, child) => Text(
                            '${kitchen.completedOrders.length} Selesai',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Consumer<KitchenProvider>(
                      builder: (context, kitchen, child) {
                        if (kitchen.completedOrders.isEmpty) {
                          return const Center(child: Text('Belum ada pesanan selesai.', style: TextStyle(fontSize: 16, color: Colors.grey)));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: kitchen.completedOrders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderTicket(context, kitchen.completedOrders[index], isActive: false);
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tampilan Mobile Portrait (Menggunakan Tab agar kartu tidak sempit)
  Widget _buildMobileLayout(BuildContext context) {
    return Consumer<KitchenProvider>(
      builder: (context, kitchen, child) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Layar Dapur (KDS)', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.orange[800],
              foregroundColor: Colors.white,
              actions: [
                _buildClearCompletedAction(context),
              ],
              bottom: TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Antrean'),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${kitchen.pendingOrders.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Selesai'),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${kitchen.completedOrders.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // Tab Antrean
                Container(
                  color: Colors.orange[50],
                  child: kitchen.pendingOrders.isEmpty
                      ? const Center(child: Text('Belum ada pesanan masuk.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: kitchen.pendingOrders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderTicket(context, kitchen.pendingOrders[index], isActive: true);
                          },
                        ),
                ),
                // Tab Selesai
                Container(
                  color: Colors.green[50],
                  child: kitchen.completedOrders.isEmpty
                      ? const Center(child: Text('Belum ada pesanan selesai.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: kitchen.completedOrders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderTicket(context, kitchen.completedOrders[index], isActive: false);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClearCompletedAction(BuildContext context) {
    return Consumer<KitchenProvider>(
      builder: (context, kitchen, _) {
        if (kitchen.completedOrders.isEmpty) return const SizedBox.shrink();
        return IconButton(
          icon: const Icon(Icons.cleaning_services),
          tooltip: 'Bersihkan Pesanan Selesai',
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Bersihkan Pesanan Selesai?'),
                content: const Text('Semua tiket pesanan yang sudah selesai dimasak akan dihapus dari layar dapur.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
                    onPressed: () {
                      kitchen.clearCompletedOrders();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Bersihkan'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget Pembuat Desain Tiket Pesanan (KOT)
  Widget _buildOrderTicket(BuildContext context, KitchenOrder order, {required bool isActive}) {
    final dateFormat = DateFormat('HH:mm');
    
    return Card(
      elevation: isActive ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.orange : Colors.green.withValues(alpha: 0.5),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Tiket: ID Transaksi, Meja, & Waktu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.transaction.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (order.transaction.tableNumber != null && order.transaction.tableNumber!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.brown[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.brown.shade200),
                          ),
                          child: Text(
                            order.transaction.tableNumber!,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.orange[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dateFormat.format(order.transaction.date),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isActive ? Colors.orange[900] : Colors.green[900],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1.5),
            
            // Daftar Item Menu
            ...order.transaction.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          if (item.modifier.isNotEmpty) 
                            Text('Varian: ${item.modifier}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                          if (item.notes.isNotEmpty) 
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                border: Border.all(color: Colors.red.shade200),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Catatan: ${item.notes}',
                                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            // Tombol Aksi (Hanya muncul jika pesanan belum selesai)
            if (isActive) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text('SELESAI DIMASAK', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                onPressed: () {
                  context.read<KitchenProvider>().markAsCompleted(order.transaction.id);
                },
              ),
            ]
          ],
        ),
      ),
    );
  }
}