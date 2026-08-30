import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staj/core/theme/app_colors.dart';
import 'package:staj/features/badges/shared/providers/badges_provider.dart';
import '../widgets/add_memory_sheet.dart';
import 'time_capsule_screen.dart';

class CityVisitsScreen extends ConsumerStatefulWidget {
  final String cityId;
  final String cityName;

  const CityVisitsScreen({
    super.key,
    required this.cityId,
    required this.cityName,
  });

  @override
  ConsumerState<CityVisitsScreen> createState() => _CityVisitsScreenState();
}

class _CityVisitsScreenState extends ConsumerState<CityVisitsScreen> {
  final List<Map<String, dynamic>> _folders = [];
  bool _isSelectionMode = false;
  final Set<String> _selectedDates = {};
  String _formatDate(DateTime date) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  void _createFolder(String folderName) {
    if (_selectedDates.isEmpty) return;

    setState(() {
      _folders.add({
        'title': folderName,
        'dates': _selectedDates.toList(),
      });
      _isSelectionMode = false;
      _selectedDates.clear();
    });
  }

  Future<void> _showCreateFolderDialog() async {
    String folderName = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.background,
          title: const Text('Tatil Klasörü Oluştur', style: TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '...',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
            ),
            onChanged: (value) => folderName = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                if (folderName.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _createFolder(folderName);
                }
              },
              child: const Text('Oluştur', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgesState = ref.watch(badgesProvider);
    final city = badgesState.cities.firstWhere((c) => c.id == widget.cityId);
    final memories = city.memories?.toList() ?? [];
    final Set<String> allDbDates = memories.map((m) => _formatDate(m.date)).toSet();
    final List<String> looseDates = allDbDates.where((date) {
      for (var folder in _folders) {
        if ((folder['dates'] as List).contains(date)) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          '${widget.cityName} Arşivi',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Yeni Anı Ekle',
            icon: const Icon(Icons.add_a_photo_outlined, color: AppColors.textPrimary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddMemorySheet(cityId: widget.cityId),
              );
            },
          ),
          if (looseDates.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isSelectionMode = !_isSelectionMode;
                  _selectedDates.clear();
                });
              },
              icon: Icon(
                _isSelectionMode ? Icons.close_rounded : Icons.checklist_rounded,
                color: AppColors.primary,
              ),
              label: Text(
                _isSelectionMode ? 'İptal' : 'Birleştir',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (_folders.isNotEmpty) ...[
            const Text(
              'Tatil Albümleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ..._folders.map((folder) => _buildFolderCard(folder)),
            const SizedBox(height: 24),
          ],
          if (looseDates.isNotEmpty) ...[
            Text(
              'Bağımsız Ziyaretler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary.withAlpha(200)),
            ),
            const SizedBox(height: 12),
            ...looseDates.map((date) => _buildLooseDateCard(date)),
          ],
          if (_folders.isEmpty && looseDates.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Center(
                child: Text('Henüz bir anı yok.',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
        ],
      ),
      floatingActionButton: _isSelectionMode && _selectedDates.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _showCreateFolderDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.create_new_folder_rounded, color: Colors.white),
        label: Text('${_selectedDates.length} Tarihi Birleştir', style: const TextStyle(color: Colors.white)),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  Widget _buildFolderCard(Map<String, dynamic> folder) {
    List<String> dates = folder['dates'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withAlpha(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withAlpha(70), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ExpansionTile(
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        title: Text(
          folder['title'],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text('${dates.length} Günlük Seyahat', style: const TextStyle(color: Colors.white70)),
        leading: const Icon(Icons.folder_special_rounded, color: Colors.amber, size: 36),
        children: dates.map((date) {
          return ListTile(
            title: Text(date, style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            onTap: () => _goToTimeCapsule(date),
          );
        }).toList(),
      ),
    );
  }
  Widget _buildLooseDateCard(String date) {
    bool isSelected = _selectedDates.contains(date);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            isSelected ? _selectedDates.remove(date) : _selectedDates.add(date);
          });
        } else {
          _goToTimeCapsule(date);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(30) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? AppColors.primary : Colors.grey,
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary),
              ),
            Expanded(
              child: Text(
                date,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (!_isSelectionMode) const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
  void _goToTimeCapsule(String date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimeCapsuleScreen(
          cityName: widget.cityName,
          date: date,
          cityId: widget.cityId,
        ),
      ),
    );
  }
}