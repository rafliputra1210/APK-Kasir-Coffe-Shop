import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'models.dart';
import 'menu_provider.dart';
import 'product_image_widget.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  List<ProductCategory> get _categories => context.read<MenuProvider>().categories;
  List<Product> get _products => context.read<MenuProvider>().products;

  String _selectedFilterCategoryId = 'ALL';

  // Dialog untuk Kelola Kategori (Tambah, Edit nama, Hapus)
  void _showManageCategoriesDialog() {
    final newCategoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.category, color: Colors.brown),
                  SizedBox(width: 8),
                  Text('Kelola Kategori Menu'),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Input tambah kategori baru
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newCategoryController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Kategori Baru',
                              hintText: 'Contoh: Signature / Tea Series',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah'),
                          onPressed: () {
                            final name = newCategoryController.text.trim();
                            if (name.isNotEmpty) {
                              context.read<MenuProvider>().addCategory(ProductCategory(
                                id: 'C${DateTime.now().millisecondsSinceEpoch}',
                                name: name,
                              ));
                              setDialogState(() {
                                newCategoryController.clear();
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Kategori "$name" berhasil ditambahkan')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Daftar Kategori Saat Ini:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // List kategori
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: _categories.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Belum ada kategori. Silakan tambahkan.'),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _categories.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                final productCount = _products.where((p) => p.categoryId == cat.id).length;

                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('$productCount produk terdaftar'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Edit nama kategori
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                                        tooltip: 'Ubah Nama',
                                        onPressed: () {
                                          _showEditCategoryDialog(cat, () {
                                            setDialogState(() {});
                                          });
                                        },
                                      ),
                                      // Hapus kategori
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        tooltip: 'Hapus Kategori',
                                        onPressed: () {
                                          _confirmDeleteCategory(cat, productCount, () {
                                            setDialogState(() {});
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Edit nama kategori
  void _showEditCategoryDialog(ProductCategory cat, VoidCallback onUpdated) {
    final editController = TextEditingController(text: cat.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Nama Kategori'),
          content: TextField(
            controller: editController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nama Kategori',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
              onPressed: () {
                final newName = editController.text.trim();
                if (newName.isNotEmpty) {
                  context.read<MenuProvider>().updateCategory(cat.id, newName);
                  onUpdated();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kategori diubah menjadi "$newName"')),
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

  // Konfirmasi hapus kategori
  void _confirmDeleteCategory(ProductCategory cat, int productCount, VoidCallback onDeleted) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hapus Kategori "${cat.name}"?'),
          content: Text(
            productCount > 0
                ? 'Peringatan: Ada $productCount produk yang memakai kategori ini. Produk tersebut akan dialihkan ke kategori lain atau tidak memiliki kategori.'
                : 'Kategori ini tidak memiliki produk dan dapat dihapus dengan aman.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                context.read<MenuProvider>().deleteCategory(cat.id);
                setState(() {
                  if (_selectedFilterCategoryId == cat.id) {
                    _selectedFilterCategoryId = 'ALL';
                  }
                });
                onDeleted();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kategori "${cat.name}" dihapus')),
                );
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  // Dialog Quick Add Kategori langsung dari form Tambah/Edit Menu
  void _showQuickAddCategoryDialog(Function(String newCatId) onCreated) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Kategori Baru'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nama Kategori',
              hintText: 'Contoh: Signature / Mocktail',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final newId = 'C${DateTime.now().millisecondsSinceEpoch}';
                  final newCat = ProductCategory(id: newId, name: name);
                  context.read<MenuProvider>().addCategory(newCat);
                  onCreated(newId);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kategori "$name" berhasil dibuat')),
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

  // Dialog untuk Tambah / Edit Grup Varian (Modifier / Add-on)
  void _showAddEditModifierDialog({
    ProductModifier? existingModifier,
    required Function(ProductModifier) onSaved,
  }) {
    final groupNameController = TextEditingController(text: existingModifier?.name ?? '');
    
    // Model lokal untuk kontroler opsi
    List<Map<String, TextEditingController>> optionControllers = [];

    if (existingModifier != null && existingModifier.options.isNotEmpty) {
      for (var opt in existingModifier.options) {
        optionControllers.add({
          'name': TextEditingController(text: opt.name),
          'price': TextEditingController(text: opt.additionalPrice.toStringAsFixed(0)),
        });
      }
    } else {
      // Default baris awal
      optionControllers.add({
        'name': TextEditingController(text: ''),
        'price': TextEditingController(text: '0'),
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModifierState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.playlist_add, color: Colors.brown),
                  const SizedBox(width: 8),
                  Text(existingModifier == null ? 'Tambah Grup Varian / Opsi' : 'Edit Grup Varian'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: groupNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Grup Varian',
                          hintText: 'Contoh: Ukuran, Topping, Jenis Susu, Level Pedas',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Pilihan Cepat / Preset Template
                      const Text(
                        'Pilihan Cepat (Template):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.straighten, size: 14),
                            label: const Text('Ukuran (Small/Big)', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              setModifierState(() {
                                groupNameController.text = 'Ukuran';
                                optionControllers = [
                                  {'name': TextEditingController(text: 'Small'), 'price': TextEditingController(text: '0')},
                                  {'name': TextEditingController(text: 'Big'), 'price': TextEditingController(text: '5000')},
                                ];
                              });
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.egg_outlined, size: 14),
                            label: const Text('Topping (Telor)', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              setModifierState(() {
                                groupNameController.text = 'Topping';
                                optionControllers = [
                                  {'name': TextEditingController(text: 'Tanpa Telor'), 'price': TextEditingController(text: '0')},
                                  {'name': TextEditingController(text: 'Telor'), 'price': TextEditingController(text: '3000')},
                                ];
                              });
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.coffee, size: 14),
                            label: const Text('Jenis Susu (Fresh/Oat)', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              setModifierState(() {
                                groupNameController.text = 'Jenis Susu';
                                optionControllers = [
                                  {'name': TextEditingController(text: 'Fresh Milk'), 'price': TextEditingController(text: '0')},
                                  {'name': TextEditingController(text: 'Oat Milk'), 'price': TextEditingController(text: '8000')},
                                ];
                              });
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.local_fire_department, size: 14),
                            label: const Text('Level Pedas', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              setModifierState(() {
                                groupNameController.text = 'Level Pedas';
                                optionControllers = [
                                  {'name': TextEditingController(text: 'Sedang'), 'price': TextEditingController(text: '0')},
                                  {'name': TextEditingController(text: 'Ekstra Pedas'), 'price': TextEditingController(text: '2000')},
                                ];
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daftar Opsi & Tambahan Harga:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Tambah Opsi'),
                            onPressed: () {
                              setModifierState(() {
                                optionControllers.add({
                                  'name': TextEditingController(text: ''),
                                  'price': TextEditingController(text: '0'),
                                });
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...optionControllers.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var row = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: row['name'],
                                  decoration: InputDecoration(
                                    labelText: 'Nama Opsi #${idx + 1}',
                                    hintText: 'Contoh: Small / Telor',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: row['price'],
                                  decoration: const InputDecoration(
                                    labelText: '+Harga (Rp)',
                                    prefixText: '+Rp ',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              if (optionControllers.length > 1) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  tooltip: 'Hapus Opsi',
                                  onPressed: () {
                                    setModifierState(() {
                                      optionControllers.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
                  onPressed: () {
                    final groupName = groupNameController.text.trim();
                    if (groupName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama grup varian tidak boleh kosong')),
                      );
                      return;
                    }

                    List<ModifierOption> options = [];
                    for (var row in optionControllers) {
                      final optName = row['name']!.text.trim();
                      if (optName.isNotEmpty) {
                        final addPrice = double.tryParse(row['price']!.text.trim()) ?? 0;
                        options.add(ModifierOption(name: optName, additionalPrice: addPrice));
                      }
                    }

                    if (options.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Minimal harus ada 1 opsi varian')),
                      );
                      return;
                    }

                    final modifier = ProductModifier(
                      id: existingModifier?.id ?? 'MOD-${DateTime.now().millisecondsSinceEpoch}',
                      name: groupName,
                      options: options,
                    );

                    onSaved(modifier);
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan Varian'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Komponen Tampilan Daftar Varian pada Form Produk
  Widget _buildModifiersSection({
    required List<ProductModifier> modifiers,
    required StateSetter setDialogState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Varian & Tambahan Harga',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Contoh: Ukuran (Small/Big), Topping (Telor +Rp3.000)',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah Varian', style: TextStyle(fontSize: 12)),
              onPressed: () {
                _showAddEditModifierDialog(
                  onSaved: (newModifier) {
                    setDialogState(() {
                      modifiers.add(newModifier);
                    });
                  },
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (modifiers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.brown.shade50.withAlpha(120),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.brown.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.brown[400]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Belum ada varian. Klik "Tambah Varian" jika menu ini memiliki opsi ukuran, topping berbayar, atau varian rasa.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
          )
        else
          ...modifiers.asMap().entries.map((entry) {
            int modIndex = entry.key;
            ProductModifier mod = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune, size: 16, color: Colors.brown),
                      const SizedBox(width: 6),
                      Text(
                        mod.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16, color: Colors.blueGrey),
                        tooltip: 'Edit Varian',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          _showAddEditModifierDialog(
                            existingModifier: mod,
                            onSaved: (updatedMod) {
                              setDialogState(() {
                                modifiers[modIndex] = updatedMod;
                              });
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        tooltip: 'Hapus Varian',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setDialogState(() {
                            modifiers.removeAt(modIndex);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: mod.options.map((opt) {
                      final priceStr = opt.additionalPrice > 0
                          ? ' (+Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(opt.additionalPrice).trim()})'
                          : ' (Rp 0)';
                      return Chip(
                        label: Text(
                          '${opt.name}$priceStr',
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // Helper untuk mengambil gambar dari Galeri atau Kamera dan menyimpannya secara permanen
  Future<String?> _pickImage(ImageSource source, BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile == null) return null;

      // Baca bytes dan salin ke direktori dokumen aplikasi agar foto bersifat permanen
      final bytes = await pickedFile.readAsBytes();
      final appDir = await getApplicationDocumentsDirectory();
      final originalExt = p.extension(pickedFile.path);
      final ext = originalExt.isNotEmpty ? originalExt : '.jpg';
      final fileName = 'menu_${DateTime.now().millisecondsSinceEpoch}$ext';
      final permanentFile = File('${appDir.path}/$fileName');
      await permanentFile.writeAsBytes(bytes);

      return permanentFile.path;
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Pemberitahuan'),
              ],
            ),
            content: Text(
              'Gagal memuat gambar: $e.\n\n'
              'PENTING: Plugin kamera/galeri baru saja ditambahkan ke aplikasi. '
              'Jika Anda menjalankan aplikasi sebelum plugin ditambahkan, silakan STOP aplikasi dan RUN ULANG ("flutter run") agar kode Android native plugin terpasang.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return null;
    }
  }

  // Dialog untuk memasukkan link / URL foto produk online
  void _showUrlInputDialog(BuildContext context, Function(String) onImageSelected) {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Input URL / Link Gambar'),
          content: TextField(
            controller: urlController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'https://images.unsplash.com/...',
              labelText: 'Tautan Gambar',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
              onPressed: () {
                final url = urlController.text.trim();
                if (url.isNotEmpty) {
                  onImageSelected(url);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Gunakan URL'),
            ),
          ],
        );
      },
    );
  }

  // Modal pemilihan sumber foto (Galeri, Kamera, atau URL)
  void _showImageSourceDialog(BuildContext context, Function(String) onImageSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const Text('Pilih Foto Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.brown[50], borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.photo_library_outlined, color: Colors.brown),
                  ),
                  title: const Text('Buka Galeri Foto', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Pilih foto dari penyimpanan perangkat'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final path = await _pickImage(ImageSource.gallery, context);
                    if (path != null && path.isNotEmpty) onImageSelected(path);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.brown[50], borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.camera_alt_outlined, color: Colors.brown),
                  ),
                  title: const Text('Ambil Foto dengan Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Foto langsung produk menu Anda'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final path = await _pickImage(ImageSource.camera, context);
                    if (path != null && path.isNotEmpty) onImageSelected(path);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.brown[50], borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.link, color: Colors.brown),
                  ),
                  title: const Text('Gunakan Link / URL Gambar', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Tempel tautan gambar online (http/https)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showUrlInputDialog(context, onImageSelected);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget preview & upload box foto produk yang menarik
  Widget _buildImagePickerBox({
    required BuildContext context,
    required String imagePath,
    required Function(String) onImageChanged,
  }) {
    if (imagePath.trim().isNotEmpty) {
      return Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.brown.shade200),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProductImageWidget(
              imagePath: imagePath,
              borderRadius: BorderRadius.circular(10),
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(230),
                      foregroundColor: Colors.brown[800],
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Ganti Foto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _showImageSourceDialog(context, onImageChanged),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withAlpha(220),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Hapus Foto',
                    onPressed: () => onImageChanged(''),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _showImageSourceDialog(context, onImageChanged),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.brown[50]?.withAlpha(120),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.brown.shade300, width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.brown.withAlpha(30), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.add_a_photo_outlined, size: 24, color: Colors.brown),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload Foto Menu Asli',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown),
            ),
            const SizedBox(height: 3),
            Text(
              'Ketuk untuk pilih dari Galeri, Kamera, atau Link URL',
              style: TextStyle(fontSize: 11, color: Colors.brown[700]),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog Tambah Menu Baru
  void _showAddMenuDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String? selectedCategoryId = _categories.isNotEmpty ? _categories.first.id : null;
    bool isAvailable = true;
    String imagePath = '';
    List<ProductModifier> modifiers = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Menu Baru'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width < 550 ? double.maxFinite : 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Upload & Preview Foto Menu Asli
                      _buildImagePickerBox(
                        context: context,
                        imagePath: imagePath,
                        onImageChanged: (newPath) {
                          setDialogState(() {
                            imagePath = newPath;
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk',
                          hintText: 'Contoh: Mie Goreng Spesial / Susu Segar',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Row pilihan kategori + tombol tambah kategori manual
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(selectedCategoryId),
                              initialValue: selectedCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'Kategori',
                                border: OutlineInputBorder(),
                              ),
                              items: _categories.map((cat) {
                                return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                              }).toList(),
                              onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Buat Kategori Baru',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.brown[100],
                              foregroundColor: Colors.brown[800],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              _showQuickAddCategoryDialog((newCatId) {
                                setDialogState(() {
                                  selectedCategoryId = newCatId;
                                });
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Harga Dasar (Rp)',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        title: const Text('Status Stok (Tersedia)'),
                        value: isAvailable,
                        onChanged: (val) => setDialogState(() => isAvailable = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                      // Bagian Input Varian / Modifier Tambahan
                      _buildModifiersSection(
                        modifiers: modifiers,
                        setDialogState: setDialogState,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
                  onPressed: () {
                    if (nameController.text.isNotEmpty && priceController.text.isNotEmpty && selectedCategoryId != null) {
                      context.read<MenuProvider>().addProduct(Product(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        categoryId: selectedCategoryId!,
                        name: nameController.text.trim(),
                        basePrice: double.tryParse(priceController.text) ?? 0,
                        imagePath: imagePath,
                        isAvailable: isAvailable,
                        modifiers: modifiers,
                      ));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu berhasil ditambahkan')));
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog Edit Menu yang sudah ada
  void _showEditMenuDialog(int index) {
    final product = _products[index];
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.basePrice.toStringAsFixed(0));
    String? selectedCategoryId = product.categoryId;
    bool isAvailable = product.isAvailable;
    String imagePath = product.imagePath;
    List<ProductModifier> modifiers = List.from(product.modifiers);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Menu'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width < 550 ? double.maxFinite : 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Upload & Preview Foto Menu Asli
                      _buildImagePickerBox(
                        context: context,
                        imagePath: imagePath,
                        onImageChanged: (newPath) {
                          setDialogState(() {
                            imagePath = newPath;
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(selectedCategoryId),
                              initialValue: selectedCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'Kategori',
                                border: OutlineInputBorder(),
                              ),
                              items: _categories.map((cat) {
                                return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                              }).toList(),
                              onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Buat Kategori Baru',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.brown[100],
                              foregroundColor: Colors.brown[800],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              _showQuickAddCategoryDialog((newCatId) {
                                setDialogState(() {
                                  selectedCategoryId = newCatId;
                                });
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Harga Dasar (Rp)',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        title: const Text('Status Stok (Tersedia)'),
                        value: isAvailable,
                        onChanged: (val) => setDialogState(() => isAvailable = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                      // Bagian Edit Varian / Modifier Tambahan
                      _buildModifiersSection(
                        modifiers: modifiers,
                        setDialogState: setDialogState,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Hapus menu
                    context.read<MenuProvider>().deleteProduct(index);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Menu "${product.name}" telah dihapus')),
                    );
                  },
                  child: const Text('Hapus Menu', style: TextStyle(color: Colors.red)),
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
                  onPressed: () {
                    if (nameController.text.isNotEmpty && priceController.text.isNotEmpty && selectedCategoryId != null) {
                      context.read<MenuProvider>().updateProduct(
                        index,
                        Product(
                          id: product.id,
                          categoryId: selectedCategoryId!,
                          name: nameController.text.trim(),
                          basePrice: double.tryParse(priceController.text) ?? product.basePrice,
                          imagePath: imagePath,
                          isAvailable: isAvailable,
                          modifiers: modifiers,
                        ),
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perubahan menu disimpan')));
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleAvailability(int index) {
    context.read<MenuProvider>().toggleProductAvailability(index);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<MenuProvider>();
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Filter produk berdasarkan kategori yang dipilih
    final filteredProducts = _selectedFilterCategoryId == 'ALL'
        ? _products
        : _products.where((p) => p.categoryId == _selectedFilterCategoryId).toList();

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header halaman & tombol aksi
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Manajemen Menu & Harga',
                style: TextStyle(fontSize: isMobile ? 20 : 26, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol Atur / Kelola Kategori Manual
                  OutlinedButton.icon(
                    onPressed: _showManageCategoriesDialog,
                    icon: const Icon(Icons.tune, size: 16),
                    label: Text('Kategori', style: TextStyle(fontSize: isMobile ? 12 : 14)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.brown[800],
                      side: BorderSide(color: Colors.brown.shade400),
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: isMobile ? 10 : 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Tambah Menu
                  ElevatedButton.icon(
                    onPressed: _showAddMenuDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text('Tambah Menu', style: TextStyle(fontSize: isMobile ? 12 : 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: isMobile ? 10 : 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bar Filter Kategori (Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('Semua (${_products.length})', style: const TextStyle(fontSize: 12)),
                  selected: _selectedFilterCategoryId == 'ALL',
                  selectedColor: Colors.brown[100],
                  visualDensity: VisualDensity.compact,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilterCategoryId = 'ALL');
                    }
                  },
                ),
                const SizedBox(width: 6),
                ..._categories.map((cat) {
                  final count = _products.where((p) => p.categoryId == cat.id).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text('${cat.name} ($count)', style: const TextStyle(fontSize: 12)),
                      selected: _selectedFilterCategoryId == cat.id,
                      selectedColor: Colors.brown[100],
                      visualDensity: VisualDensity.compact,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilterCategoryId = selected ? cat.id : 'ALL';
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Daftar Produk
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.coffee_outlined, size: 54, color: Colors.brown.shade200),
                        const SizedBox(height: 10),
                        Text(
                          _selectedFilterCategoryId == 'ALL'
                              ? 'Belum ada menu yang terdaftar.'
                              : 'Tidak ada produk di kategori ini.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
                          onPressed: _showAddMenuDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Menu Sekarang'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredProducts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final originalIndex = _products.indexOf(product);
                      final category = _categories.firstWhere(
                        (c) => c.id == product.categoryId,
                        orElse: () => ProductCategory(id: '', name: 'Lainnya'),
                      );

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: LayoutBuilder(
                            builder: (context, cardBox) {
                              final isNarrow = cardBox.maxWidth < 460;
                              if (isNarrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ProductImageWidget(
                                          imagePath: product.imagePath,
                                          width: 42,
                                          height: 42,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      product.name,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (!product.isAvailable) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                      decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(4)),
                                                      child: const Text('Habis', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Text(
                                                '${category.name} • ${formatCurrency.format(product.basePrice)}',
                                                style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (product.modifiers.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: product.modifiers.map((m) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.brown[50],
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.brown.shade200, width: 0.8),
                                            ),
                                            child: Text(
                                              '${m.name}: ${m.options.map((o) => o.additionalPrice > 0 ? '${o.name} (+${formatCurrency.format(o.additionalPrice)})' : o.name).join(', ')}',
                                              style: TextStyle(fontSize: 10.5, color: Colors.brown[800]),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    const Divider(height: 1),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                          onPressed: () => _toggleAvailability(originalIndex),
                                          child: Text(
                                            product.isAvailable ? 'Set Habis' : 'Set Tersedia',
                                            style: TextStyle(fontSize: 12, color: product.isAvailable ? Colors.red[700] : Colors.green[700]),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 18),
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _showEditMenuDialog(originalIndex),
                                          tooltip: 'Edit Menu',
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              } else {
                                return Row(
                                  children: [
                                    ProductImageWidget(
                                      imagePath: product.imagePath,
                                      width: 48,
                                      height: 48,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(width: 8),
                                              if (!product.isAvailable)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(4)),
                                                  child: const Text('Habis', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text('${category.name} • ${formatCurrency.format(product.basePrice)}', style: TextStyle(fontSize: 13, color: Colors.grey[800])),
                                          if (product.modifiers.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: product.modifiers.map((m) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.brown[50],
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: Colors.brown.shade200, width: 0.8),
                                                  ),
                                                  child: Text(
                                                    '${m.name}: ${m.options.map((o) => o.additionalPrice > 0 ? '${o.name} (+${formatCurrency.format(o.additionalPrice)})' : o.name).join(', ')}',
                                                    style: TextStyle(fontSize: 11, color: Colors.brown[800]),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _toggleAvailability(originalIndex),
                                      child: Text(product.isAvailable ? 'Set Habis' : 'Set Tersedia'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                      onPressed: () => _showEditMenuDialog(originalIndex),
                                      tooltip: 'Edit Menu',
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