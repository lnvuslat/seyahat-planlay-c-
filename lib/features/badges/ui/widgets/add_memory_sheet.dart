import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:staj/core/theme/app_colors.dart';
import 'package:staj/features/badges/data/models/memory_item.dart';
import 'package:staj/features/badges/shared/providers/badges_provider.dart';

class AddMemorySheet extends ConsumerStatefulWidget {
  final String cityId;

  const AddMemorySheet({super.key, required this.cityId});

  @override
  ConsumerState<AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends ConsumerState<AddMemorySheet> {
  IconData _selectedSticker = Icons.camera_rounded;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final List<IconData> _stickers = [
    Icons.radio_button_unchecked,
    Icons.camera_rounded,
    Icons.restaurant_rounded,
    Icons.local_cafe_rounded,
    Icons.mosque_rounded,
    Icons.museum_rounded,
    Icons.park_rounded,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf seçilirken bir hata oluştu.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: bottomInset > 0 ? bottomInset + 16 : 32,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.withAlpha(100), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Yeni Anı Ekle',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            const Text('Kategori Sticker\'ı', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _stickers.map((icon) {
                  final isSelected = _selectedSticker == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSticker = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 8, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 24),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Anı Başlığı (Örn: Muhteşem Manzara)',
                hintStyle: TextStyle(color: Colors.grey.withAlpha(150), fontStyle: FontStyle.italic),
                filled: true, fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Bu ana dair hislerini yaz...',
                hintStyle: TextStyle(color: Colors.grey.withAlpha(150), fontStyle: FontStyle.italic),
                filled: true, fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 20),

            //foto ekleme
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withAlpha(80), width: 1.5, style: BorderStyle.solid),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_rounded, size: 32, color: AppColors.primary.withAlpha(200)),
                    const SizedBox(height: 8),
                    const Text('Polaroid Fotoğraf Ekle', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  if (_titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir başlık girin.')));
                    return;
                  }
                  final newMemory = MemoryItem(
                    id: const Uuid().v4(),
                    date: DateTime.now(),
                    title: _titleController.text,
                    note: _noteController.text,
                    categoryIcon: _selectedSticker.codePoint.toString(),
                    imagePath: _selectedImage?.path,
                  );
                  ref.read(badgesProvider.notifier).addMemoryToCity(widget.cityId, newMemory);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Anı başarıyla zaman kapsülüne eklendi! 🎉'), backgroundColor: Colors.green),
                  );
                },
                child: const Text('Zaman Kapsülüne Ekle', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}