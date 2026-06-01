import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const FingateApp());
}

/// Render 백엔드 주소
const String baseUrl = 'https://fingate-app-server.onrender.com';

class FingateApp extends StatelessWidget {
  const FingateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fingate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.text,
        ),
      ),
      home: const MainShell(),
    );
  }
}

class AppColors {
  static const navy = Color(0xFF061A3A);
  static const navy2 = Color(0xFF092451);
  static const navy3 = Color(0xFF0B2F6B);
  static const blue = Color(0xFF155DFC);
  static const blue2 = Color(0xFF0B4BDD);
  static const sky = Color(0xFF56A7FF);
  static const mint = Color(0xFF28D6A3);
  static const amber = Color(0xFFFFB84D);
  static const red = Color(0xFFFF5B6E);
  static const purple = Color(0xFF7C3AED);
  static const background = Color(0xFFF4F7FC);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF8FAFF);
  static const lightBlue = Color(0xFFEAF2FF);
  static const chipBg = Color(0xFFF0F5FF);
  static const text = Color(0xFF101827);
  static const subText = Color(0xFF667085);
  static const muted = Color(0xFF98A2B3);
  static const border = Color(0xFFE2EAF7);
}

class NewsItem {
  final int id;
  final String source;
  final String title;
  final String url;
  final String summary;
  final String context;
  final int importance;
  final List<String> tags;
  final DateTime? publishedAt;

  const NewsItem({
    required this.id,
    required this.source,
    required this.title,
    required this.url,
    required this.summary,
    required this.context,
    required this.importance,
    required this.tags,
    required this.publishedAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final List<String> tags;

    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (rawTags is String) {
      tags = rawTags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else {
      tags = [];
    }

    return NewsItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      source: json['source']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      context: json['context']?.toString() ?? '',
      importance: json['importance'] is int ? json['importance'] : int.tryParse('${json['importance']}') ?? 3,
      tags: tags,
      publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? ''),
    );
  }
}

class NewsApi {
  static Future<List<NewsItem>> fetchTodayNews({
    int limit = 30,
    int hours = 36,
  }) async {
    final uri = Uri.parse('$baseUrl/news/today?hours=$hours&limit=$limit');

    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('뉴스를 불러오지 못했습니다. status=${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is Map<String, dynamic> && decoded['items'] is List) {
      return (decoded['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(NewsItem.fromJson)
          .toList();
    }

    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(NewsItem.fromJson)
          .toList();
    }

    return [];
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;
  final List<NewsItem> savedItems = [];

  void toggleSave(NewsItem item) {
    setState(() {
      final exists = savedItems.any((e) => e.id == item.id);
      if (exists) {
        savedItems.removeWhere((e) => e.id == item.id);
      } else {
        savedItems.add(item);
      }
    });
  }

  bool isSaved(NewsItem item) {
    return savedItems.any((e) => e.id == item.id);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onToggleSave: toggleSave, isSaved: isSaved),
      BriefingScreen(onToggleSave: toggleSave, isSaved: isSaved),
      SavedScreen(savedItems: savedItems, onToggleSave: toggleSave),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: NavigationBar(
            height: 70,
            selectedIndex: currentIndex,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            indicatorColor: AppColors.lightBlue,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) => setState(() => currentIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.wb_sunny_outlined),
                selectedIcon: Icon(Icons.wb_sunny_rounded),
                label: '브리핑',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_border_rounded),
                selectedIcon: Icon(Icons.bookmark_rounded),
                label: '저장',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: '설정',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final void Function(NewsItem item) onToggleSave;
  final bool Function(NewsItem item) isSaved;

  const HomeScreen({
    super.key,
    required this.onToggleSave,
    required this.isSaved,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<NewsItem>> futureNews;
  String selectedCategory = '전체';

  final categories = const ['전체', '증시', '반도체', '환율', '금리', '기업', '정책'];

  @override
  void initState() {
    super.initState();
    futureNews = NewsApi.fetchTodayNews(limit: 30, hours: 36);
  }

  Future<void> refresh() async {
    setState(() {
      futureNews = NewsApi.fetchTodayNews(limit: 30, hours: 36);
    });
    await futureNews;
  }

  List<NewsItem> filtered(List<NewsItem> items) {
    if (selectedCategory == '전체') return items;

    return items.where((item) {
      final text = '${item.title} ${item.summary} ${item.context} ${item.tags.join(" ")}';
      return text.contains(selectedCategory);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsItem>>(
      future: futureNews,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final news = snapshot.data ?? [];
        final visibleNews = filtered(news);

        return RefreshIndicator(
          onRefresh: refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: PremiumHeader(
                  categories: categories,
                  selectedCategory: selectedCategory,
                  totalCount: news.length,
                  onCategorySelected: (value) => setState(() => selectedCategory = value),
                ),
              ),
              if (isLoading)
                const SliverFillRemaining(
                  child: PremiumLoadingState(),
                )
              else if (hasError)
                SliverFillRemaining(
                  child: ErrorState(
                    title: '뉴스를 불러오지 못했습니다',
                    message: 'Render 서버가 잠들어 있으면 첫 요청이 느릴 수 있어요.\n잠시 후 다시 시도해주세요.',
                    onRetry: refresh,
                  ),
                )
              else if (news.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    title: '표시할 뉴스가 없어요',
                    message: 'Render에서 /admin/fetch를 실행하면\n오늘의 뉴스가 표시됩니다.',
                    onRetry: refresh,
                  ),
                )
              else if (visibleNews.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    title: '해당 카테고리 뉴스가 없어요',
                    message: '다른 카테고리를 선택하거나 새로고침해보세요.',
                    onRetry: refresh,
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: TopStoryCard(
                      item: visibleNews.first,
                      isSaved: widget.isSaved(visibleNews.first),
                      onToggleSave: () => widget.onToggleSave(visibleNews.first),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: MarketPulsePanel(items: news),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
                    child: SectionHeader(
                      title: 'AI 요약 뉴스',
                      subtitle: '중요도와 시장 영향 기준으로 정렬했어요',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = visibleNews[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PremiumNewsCard(
                            item: item,
                            index: index,
                            isSaved: widget.isSaved(item),
                            onToggleSave: () => widget.onToggleSave(item),
                          ),
                        );
                      },
                      childCount: visibleNews.length,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class PremiumHeader extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final int totalCount;
  final void Function(String value) onCategorySelected;

  const PremiumHeader({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.totalCount,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final date = formattedToday();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.navy2, AppColors.navy3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: _GlowCircle(size: 210, color: AppColors.blue.withOpacity(0.22)),
          ),
          Positioned(
            bottom: 40,
            left: -90,
            child: _GlowCircle(size: 180, color: AppColors.sky.withOpacity(0.13)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeaderTopRow(),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '오늘의 금융 뉴스',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.98),
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: AppColors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '$totalCount개',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  '$date 업데이트 · AI가 핵심 이슈만 골라 정리했어요',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                const HeroBriefCard(),
                const SizedBox(height: 18),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final selected = selectedCategory == category;

                      return GestureDetector(
                        onTap: () => onCategorySelected(category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : Colors.white.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected ? Colors.white : Colors.white.withOpacity(0.13),
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: selected ? AppColors.navy : Colors.white,
                              fontSize: 14,
                              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HeaderTopRow extends StatelessWidget {
  const _HeaderTopRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.blue, AppColors.sky],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.show_chart_rounded, color: Colors.white),
        ),
        const SizedBox(width: 10),
        const Text(
          'Fingate',
          style: TextStyle(
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const Spacer(),
        DarkIconButton(icon: Icons.search_rounded, onTap: () {}),
        const SizedBox(width: 8),
        DarkIconButton(icon: Icons.notifications_none_rounded, showDot: true, onTap: () {}),
      ],
    );
  }
}

class DarkIconButton extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  final VoidCallback onTap;

  const DarkIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        if (showDot)
          Positioned(
            top: 8,
            right: 9,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class HeroBriefCard extends StatelessWidget {
  const HeroBriefCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.17),
            Colors.white.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI 시장 브리핑',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(width: 8),
                    _GlassBadge(text: 'LIVE'),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '흩어진 금융 뉴스를 한 화면에서 빠르게 읽을 수 있게 요약했어요.',
                  style: TextStyle(color: Color(0xFFDCE9FF), height: 1.45, fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final String text;

  const _GlassBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mint.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.mint.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.mint, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class MarketPulsePanel extends StatelessWidget {
  final List<NewsItem> items;

  const MarketPulsePanel({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final keywords = topKeywords(items).take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.insights_rounded, color: AppColors.blue),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘 많이 언급된 키워드',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: keywords.isEmpty
                      ? const [SmallTag(text: '금융뉴스')]
                      : keywords.map((e) => SmallTag(text: e)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TopStoryCard extends StatelessWidget {
  final NewsItem item;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const TopStoryCard({
    super.key,
    required this.item,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NewsDetailScreen(
                item: item,
                isSaved: isSaved,
                onToggleSave: onToggleSave,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                gradient: LinearGradient(
                  colors: [AppColors.blue2, AppColors.navy3],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -22,
                    top: -26,
                    child: Icon(
                      Icons.bubble_chart_rounded,
                      color: Colors.white.withOpacity(0.10),
                      size: 110,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _GlassBadge(text: 'TOP STORY'),
                          const Spacer(),
                          IconButton(
                            onPressed: onToggleSave,
                            icon: Icon(
                              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          height: 1.25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SourcePill(source: item.source, dark: true),
                          const SizedBox(width: 8),
                          Text(
                            timeAgo(item.publishedAt),
                            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (item.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  item.summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 14.5,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PremiumNewsCard extends StatelessWidget {
  final NewsItem item;
  final int index;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const PremiumNewsCard({
    super.key,
    required this.item,
    required this.index,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NewsDetailScreen(
                item: item,
                isSaved: isSaved,
                onToggleSave: onToggleSave,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NewsMetaRow(
                item: item,
                isSaved: isSaved,
                onToggleSave: onToggleSave,
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17.5,
                  height: 1.28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.45,
                ),
              ),
              if (item.summary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border.withOpacity(0.8)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AiMiniIcon(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.summary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.subText,
                            fontSize: 13.5,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.tags.take(4).map((tag) => SmallTag(text: tag)).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NewsMetaRow extends StatelessWidget {
  final NewsItem item;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const NewsMetaRow({
    super.key,
    required this.item,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SourceLogo(source: item.source),
        const SizedBox(width: 8),
        Expanded(child: SourcePill(source: item.source)),
        const SizedBox(width: 8),
        ImportanceBadge(importance: item.importance),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onToggleSave,
          icon: Icon(
            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: isSaved ? AppColors.blue : AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.055),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class SourceLogo extends StatelessWidget {
  final String source;

  const SourceLogo({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final label = sourceLabel(source);
    final first = label.isNotEmpty ? label.substring(0, 1) : 'F';

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            sourceColor(source),
            sourceColor(source).withOpacity(0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: sourceColor(source).withOpacity(0.24),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          first,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class SourcePill extends StatelessWidget {
  final String source;
  final bool dark;

  const SourcePill({
    super.key,
    required this.source,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      sourceLabel(source),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: dark ? Colors.white.withOpacity(0.92) : AppColors.text,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class ImportanceBadge extends StatelessWidget {
  final int importance;

  const ImportanceBadge({
    super.key,
    required this.importance,
  });

  @override
  Widget build(BuildContext context) {
    final style = importanceStyle(importance);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(style.icon, size: 13, color: style.color),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class ImportanceStyle {
  final String label;
  final Color color;
  final IconData icon;

  const ImportanceStyle({
    required this.label,
    required this.color,
    required this.icon,
  });
}

ImportanceStyle importanceStyle(int importance) {
  if (importance >= 5) {
    return const ImportanceStyle(label: '핵심', color: AppColors.red, icon: Icons.local_fire_department_rounded);
  }
  if (importance == 4) {
    return const ImportanceStyle(label: '주목', color: AppColors.blue, icon: Icons.bolt_rounded);
  }
  if (importance == 3) {
    return const ImportanceStyle(label: '참고', color: AppColors.purple, icon: Icons.trending_up_rounded);
  }
  return const ImportanceStyle(label: '일반', color: AppColors.muted, icon: Icons.circle_rounded);
}

class AiMiniIcon extends StatelessWidget {
  const AiMiniIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 29,
      height: 29,
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.auto_awesome_rounded, color: AppColors.blue, size: 17),
    );
  }
}

class SmallTag extends StatelessWidget {
  final String text;

  const SmallTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final clean = text.startsWith('#') ? text : '#$text';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1EAFF)),
      ),
      child: Text(
        clean,
        style: const TextStyle(
          color: Color(0xFF3763B8),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.subText, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class NewsDetailScreen extends StatelessWidget {
  final NewsItem item;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const NewsDetailScreen({
    super.key,
    required this.item,
    required this.isSaved,
    required this.onToggleSave,
  });

  Future<void> openOriginal(BuildContext context) async {
    final uri = Uri.tryParse(item.url);

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('원문 링크가 올바르지 않습니다.')),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('원문을 열 수 없습니다: ${item.url}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DetailHero(
              item: item,
              isSaved: isSaved,
              onToggleSave: onToggleSave,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  DetailInsightCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'AI 요약',
                    body: item.summary.isEmpty ? '요약 정보가 없습니다.' : item.summary,
                    highlight: true,
                  ),
                  const SizedBox(height: 12),
                  DetailInsightCard(
                    icon: Icons.lightbulb_outline_rounded,
                    title: '왜 중요한가',
                    body: item.context.isEmpty ? '해설 정보가 없습니다.' : item.context,
                  ),
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    PremiumCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '관련 태그',
                              style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: item.tags.map((tag) => SmallTag(text: tag)).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () => openOriginal(context),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text(
                        '원문 보기',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'AI 요약은 자동 생성된 정보로, 투자 판단의 참고 자료로만 활용해주세요. 본 서비스는 특정 금융상품의 매수·매도 추천을 제공하지 않습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.subText, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailHero extends StatelessWidget {
  final NewsItem item;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const DetailHero({
    super.key,
    required this.item,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.navy2, AppColors.navy3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            bottom: -80,
            child: _GlowCircle(size: 210, color: AppColors.blue.withOpacity(0.18)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DetailCircleButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                  const Spacer(),
                  DetailCircleButton(
                    icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    onTap: onToggleSave,
                  ),
                  const SizedBox(width: 8),
                  DetailCircleButton(icon: Icons.ios_share_rounded, onTap: () {}),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  SourceLogo(source: item.source),
                  const SizedBox(width: 9),
                  SourcePill(source: item.source, dark: true),
                  const SizedBox(width: 8),
                  Text(
                    timeAgo(item.publishedAt),
                    style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                  letterSpacing: -0.85,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ImportanceBadge(importance: item.importance),
                  const SizedBox(width: 8),
                  if (item.tags.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.11),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '#${item.tags.first}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DetailCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const DetailCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class DetailInsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool highlight;

  const DetailInsightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: highlight ? AppColors.lightBlue.withOpacity(0.45) : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.blue, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15.5,
                height: 1.65,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BriefingScreen extends StatefulWidget {
  final void Function(NewsItem item) onToggleSave;
  final bool Function(NewsItem item) isSaved;

  const BriefingScreen({
    super.key,
    required this.onToggleSave,
    required this.isSaved,
  });

  @override
  State<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends State<BriefingScreen> {
  late Future<List<NewsItem>> futureNews;

  @override
  void initState() {
    super.initState();
    futureNews = NewsApi.fetchTodayNews(limit: 15, hours: 36);
  }

  Future<void> refresh() async {
    setState(() {
      futureNews = NewsApi.fetchTodayNews(limit: 15, hours: 36);
    });
    await futureNews;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsItem>>(
      future: futureNews,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final keywords = topKeywords(items).take(5).toList();

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 110),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '아침 브리핑',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  LightIconButton(icon: Icons.notifications_none_rounded, onTap: () {}),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '오늘 시장을 움직일 핵심 흐름을 빠르게 확인하세요.',
                style: TextStyle(color: AppColors.subText, fontSize: 14),
              ),
              const SizedBox(height: 22),
              PremiumCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.blue, AppColors.sky],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.coffee_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          items.isEmpty
                              ? '오늘 브리핑을 불러오는 중이거나 아직 생성된 뉴스가 없습니다.'
                              : items.first.summary.isNotEmpty
                                  ? items.first.summary
                                  : items.first.title,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14.5,
                            height: 1.55,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeader(title: '관심 키워드', subtitle: '자주 등장하는 이슈를 모았어요'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: keywords.isEmpty
                    ? const [
                        InterestChip(label: '반도체', selected: true),
                        InterestChip(label: '환율'),
                        InterestChip(label: '금리'),
                        InterestChip(label: '증시'),
                      ]
                    : keywords.map((e) => InterestChip(label: e)).toList(),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: '맞춤 뉴스', subtitle: '브리핑에 포함된 핵심 기사'),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const PremiumLoadingState()
              else if (items.isEmpty)
                const EmptyMiniCard()
              else
                ...items.take(7).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CompactNewsTile(
                      item: item,
                      isSaved: widget.isSaved(item),
                      onToggleSave: () => widget.onToggleSave(item),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class InterestChip extends StatelessWidget {
  final String label;
  final bool selected;

  const InterestChip({
    super.key,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.blue : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? AppColors.blue : AppColors.border),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.blue.withOpacity(0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.text,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class CompactNewsTile extends StatelessWidget {
  final NewsItem item;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const CompactNewsTile({
    super.key,
    required this.item,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NewsDetailScreen(
                item: item,
                isSaved: isSaved,
                onToggleSave: onToggleSave,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SourceLogo(source: item.source),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sourceLabel(item.source),
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggleSave,
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isSaved ? AppColors.blue : AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavedScreen extends StatelessWidget {
  final List<NewsItem> savedItems;
  final void Function(NewsItem item) onToggleSave;

  const SavedScreen({
    super.key,
    required this.savedItems,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 110),
      children: [
        const Text(
          '저장한 뉴스',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '나중에 다시 볼 뉴스를 저장해둘 수 있어요.',
          style: TextStyle(color: AppColors.subText, fontSize: 14),
        ),
        const SizedBox(height: 24),
        if (savedItems.isEmpty)
          const EmptyState(
            title: '저장한 뉴스가 없어요',
            message: '관심 있는 뉴스의 북마크 버튼을 눌러 저장해보세요.',
          )
        else
          ...savedItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumNewsCard(
                item: item,
                index: 0,
                isSaved: true,
                onToggleSave: () => onToggleSave(item),
              ),
            ),
          ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 110),
      children: const [
        Text(
          '설정',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: 6),
        Text(
          '앱 사용 환경과 안내 사항을 확인하세요.',
          style: TextStyle(color: AppColors.subText, fontSize: 14),
        ),
        SizedBox(height: 24),
        SettingsTile(
          icon: Icons.tune_rounded,
          title: '관심 키워드 설정',
          subtitle: '반도체, 환율, 금리 등 관심 주제를 설정합니다.',
        ),
        SettingsTile(
          icon: Icons.notifications_none_rounded,
          title: '알림 설정',
          subtitle: '아침 브리핑 알림을 받을 시간을 설정합니다.',
        ),
        SettingsTile(
          icon: Icons.description_outlined,
          title: '개인정보처리방침',
          subtitle: '서비스 이용에 필요한 개인정보 안내입니다.',
        ),
        SettingsTile(
          icon: Icons.warning_amber_rounded,
          title: '투자 정보 고지',
          subtitle: '본 서비스는 투자 자문이 아닌 정보 제공 서비스입니다.',
        ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: AppColors.blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.subText, fontSize: 12.5, height: 1.4),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.subText),
          ],
        ),
      ),
    );
  }
}

class LightIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const LightIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.navy),
      ),
    );
  }
}

class PremiumLoadingState extends StatelessWidget {
  const PremiumLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 18),
            Text(
              'AI 요약 뉴스를 불러오는 중입니다',
              style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text(
              'Render 서버가 잠들어 있으면 조금 걸릴 수 있어요.',
              style: TextStyle(color: AppColors.subText, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StateCard(
        icon: Icons.cloud_off_rounded,
        title: title,
        message: message,
        buttonText: '다시 시도',
        onPressed: onRetry,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StateCard(
        icon: Icons.article_outlined,
        title: title,
        message: message,
        buttonText: '새로고침',
        onPressed: onRetry,
      ),
    );
  }
}

class StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final Future<void> Function()? onPressed;

  const StateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.subText),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.subText, fontSize: 14, height: 1.5),
            ),
            if (onPressed != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: () => onPressed!(), child: Text(buttonText)),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyMiniCard extends StatelessWidget {
  const EmptyMiniCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          '표시할 맞춤 뉴스가 없습니다.',
          style: TextStyle(color: AppColors.subText),
        ),
      ),
    );
  }
}

String sourceLabel(String source) {
  if (source.contains('hankyung')) return '한국경제';
  if (source.contains('mk_tv')) return '매일경제TV';
  if (source.contains('mk_')) return '매일경제';
  if (source.contains('chosun')) return '조선일보';
  if (source.contains('yonhapnewstv')) return '연합뉴스TV';
  if (source.contains('yonhap_economytv')) return '연합뉴스경제TV';
  if (source.contains('einfomax')) return '연합인포맥스';
  if (source.contains('fnnews')) return '파이낸셜뉴스';
  if (source.contains('korea')) return '정책브리핑';
  return source;
}

Color sourceColor(String source) {
  if (source.contains('hankyung')) return const Color(0xFF1149B8);
  if (source.contains('mk')) return const Color(0xFFFF7A1A);
  if (source.contains('chosun')) return const Color(0xFF13294B);
  if (source.contains('yonhap')) return const Color(0xFF165DFF);
  if (source.contains('einfomax')) return const Color(0xFF0A7C66);
  if (source.contains('fnnews')) return const Color(0xFF7C3AED);
  return AppColors.blue;
}

String timeAgo(DateTime? dt) {
  if (dt == null) return '';

  final now = DateTime.now();
  final local = dt.toLocal();
  final diff = now.difference(local);

  if (diff.inSeconds < 60) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  return '${diff.inDays}일 전';
}

String formattedToday() {
  final now = DateTime.now();
  return '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
}

List<String> topKeywords(List<NewsItem> items) {
  final Map<String, int> counts = {};

  for (final item in items) {
    for (final tag in item.tags) {
      final clean = tag.replaceAll('#', '').trim();

      if (clean.length < 2) continue;

      counts[clean] = (counts[clean] ?? 0) + 1;
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.map((e) => e.key).toList();
}
