import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staj/core/theme/app_colors.dart';
import 'package:staj/features/badges/data/models/memory_item.dart';
import 'package:staj/features/badges/shared/providers/badges_provider.dart';
import 'package:staj/features/badges/ui/widgets/add_memory_sheet.dart';

class TimeCapsuleScreen extends ConsumerStatefulWidget {
  final String cityId;
  final String cityName;
  final String date;

  const TimeCapsuleScreen({
    super.key,
    required this.cityId,
    required this.cityName,
    required this.date,
  });

  @override
  ConsumerState<TimeCapsuleScreen> createState() => _TimeCapsuleScreenState();
}

class _TimeCapsuleScreenState extends ConsumerState<TimeCapsuleScreen> {

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
  String _formatDateString(DateTime date) {
    const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }
  void _confirmDelete(MemoryItem memory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.background,
        title: const Text('Anıyı Sil', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Bu anıyı zaman kapsülünden kalıcı olarak silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
            onPressed: () async {
              await memory.delete();
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Anı başarıyla silindi. 🗑️')),
              );
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgesState = ref.watch(badgesProvider);
    final city = badgesState.cities.firstWhere((c) => c.id == widget.cityId);
    final allMemories = city.memories?.toList() ?? [];

    final filteredMemories = allMemories.where((m) => _formatDateString(m.date) == widget.date).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.cityName,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              widget.date,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
      body: filteredMemories.isEmpty
          ? const Center(child: Text('Burası henüz boş. Yeni bir anı ekle!', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        itemCount: filteredMemories.length,
        itemBuilder: (context, index) {
          final isLast = index == filteredMemories.length - 1;
          return _buildTimelineItem(filteredMemories[index], isLast);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddMemorySheet(cityId: widget.cityId),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildTimelineItem(MemoryItem memory, bool isLast) {
    final iconData = IconData(int.parse(memory.categoryIcon), fontFamily: 'MaterialIcons');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(
                  _formatTime(memory.date),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Icon(iconData, color: Colors.white, size: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: GestureDetector(
                onLongPress: () => _confirmDelete(memory),
                child: _buildPolaroidCard(memory),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolaroidCard(MemoryItem memory) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(2, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (memory.imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(memory.imagePath!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],

          Text(
            memory.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            memory.note,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}