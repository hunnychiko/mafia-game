import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sound_model.dart';
import '../../data/repositories/sound_repository.dart';
import '../../services/preferences_service.dart';
import '../mix/mix_screen.dart';
import '../player/player_screen.dart';
import 'widgets/category_chip_bar.dart';
import 'widgets/sound_card.dart';
import 'widgets/banner_ad_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedCategory;
  int _currentTab = 0; // 0: All, 1: Favorites, 2: Mix

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lullify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm_outlined),
            onPressed: () => Navigator.pushNamed(context, '/alarms'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          _TabBar(
            currentTab: _currentTab,
            onTabChanged: (i) => setState(() => _currentTab = i),
          ),
          if (_currentTab == 0)
            CategoryChipBar(
              selectedCategory: _selectedCategory,
              onCategorySelected: (cat) =>
                  setState(() => _selectedCategory = cat),
            ),
          Expanded(
            child: switch (_currentTab) {
              0 => _SoundList(category: _selectedCategory),
              1 => const _FavoritesList(),
              _ => const MixTabView(),
            },
          ),
          if (_currentTab != 2) const BannerAdWidget(),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.currentTab, required this.onTabChanged});

  final int currentTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _Tab(label: '전체', isSelected: currentTab == 0, onTap: () => onTabChanged(0)),
          const SizedBox(width: 8),
          _Tab(label: '즐겨찾기', isSelected: currentTab == 1, onTap: () => onTabChanged(1)),
          const SizedBox(width: 8),
          _Tab(label: '믹스', isSelected: currentTab == 2, onTap: () => onTabChanged(2)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.primary : color.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color.onPrimary : color.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _SoundList extends ConsumerWidget {
  const _SoundList({this.category});

  final String? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = category != null
        ? ref.watch(soundRepositoryProvider).watchByCategory(category!)
        : ref.watch(soundRepositoryProvider).watchAll();

    return StreamBuilder<List<SoundModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
        }

        final sounds = snapshot.data ?? [];
        if (sounds.isEmpty) {
          return const Center(
            child: Text('등록된 사운드가 없습니다', style: TextStyle(color: Colors.white54)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: sounds.length,
          itemBuilder: (context, index) {
            final sound = sounds[index];
            return SoundCard(
              sound: sound,
              onTap: () => _openPlayer(context, sound),
            );
          },
        );
      },
    );
  }

  void _openPlayer(BuildContext context, SoundModel sound) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerScreen(sound: sound)),
    );
  }
}

class _FavoritesList extends ConsumerWidget {
  const _FavoritesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(preferencesServiceProvider);

    return prefsAsync.when(
      data: (prefs) {
        final favIds = prefs.getFavorites().toList();
        if (favIds.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border, size: 48, color: Colors.white24),
                SizedBox(height: 12),
                Text('즐겨찾기한 사운드가 없습니다',
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: favIds.length,
          itemBuilder: (context, index) {
            return FutureBuilder<SoundModel?>(
              future: ref.read(soundRepositoryProvider).getById(favIds[index]),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(height: 80);
                }
                final sound = snap.data!;
                return SoundCard(
                  sound: sound,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PlayerScreen(sound: sound)),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}
