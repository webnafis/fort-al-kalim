import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/settings_service.dart';
import '../services/dictionary_service.dart';

class LevelDictionaryScreen extends ConsumerStatefulWidget {
  final int level;
  const LevelDictionaryScreen({super.key, required this.level});

  @override
  ConsumerState<LevelDictionaryScreen> createState() => _LevelDictionaryScreenState();
}

class _LevelDictionaryScreenState extends ConsumerState<LevelDictionaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DictionaryWord>? _words;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadWords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    try {
      final user = await ref.read(currentUserModelProvider.future);
      if (user == null) {
        setState(() => _error = "Not logged in");
        return;
      }
      final words = await ref.read(dictionaryServiceProvider).getWordsForLevel(user.uid, widget.level);
      if (mounted) {
        setState(() {
          _words = words;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text('Level ${widget.level} Dictionary', style: const TextStyle(fontFamily: 'Amiri', color: AppTheme.gold)),
        backgroundColor: AppTheme.backgroundDark,
        iconTheme: const IconThemeData(color: AppTheme.gold),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.gold,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.gold,
          tabs: const [
            Tab(icon: Icon(Icons.visibility), text: 'See'),
            Tab(icon: Icon(Icons.headset), text: 'Listen'),
            Tab(icon: Icon(Icons.edit), text: 'Write'),
            Tab(icon: Icon(Icons.mic), text: 'Speak'),
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _words == null || _words!.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                SettingsNotifier.playSfx('click.mp3');
                final tabNames = ['see', 'listen', 'write', 'speak'];
                final type = tabNames[_tabController.index];
                context.push('${Routes.dictionaryPractice}?level=${widget.level}&type=$type');
              },
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.backgroundDark,
              icon: const Icon(Icons.school),
              label: const Text('Practice Current Section', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: AppTheme.redFort)));
    }
    if (_words == null || _words!.isEmpty) {
      return const Center(child: Text('No words found for this level.', style: TextStyle(color: AppTheme.textMuted)));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildWordList((w) => w.seeUsage, 'See'),
        _buildWordList((w) => w.listenUsage, 'Listen'),
        _buildWordList((w) => w.writeUsage, 'Write'),
        _buildWordList((w) => w.speakUsage, 'Speak'),
      ],
    );
  }

  Widget _buildWordList(int Function(DictionaryWord) getUsage, String sectionName) {
    // Sort words by the specific usage count ascending (least used first)
    final sortedWords = List<DictionaryWord>.from(_words!);
    sortedWords.sort((a, b) => getUsage(a).compareTo(getUsage(b)));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80), // bottom padding for FAB
      itemCount: sortedWords.length,
      itemBuilder: (context, index) {
        final w = sortedWords[index];
        final usage = getUsage(w);
        
        return Card(
          color: AppTheme.surfaceDark,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Text(w.emoji ?? '❓', style: const TextStyle(fontSize: 32)),
            title: Text(w.arabicText, style: const TextStyle(color: AppTheme.gold, fontSize: 24, fontFamily: 'Amiri')),
            subtitle: Text(w.englishText, style: const TextStyle(color: AppTheme.textSecondary)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: usage >= 4 ? AppTheme.gold.withOpacity(0.2) : AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: usage >= 4 ? AppTheme.gold : AppTheme.textMuted),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$usage/4', style: TextStyle(color: usage >= 4 ? AppTheme.gold : AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                  Text(sectionName, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
