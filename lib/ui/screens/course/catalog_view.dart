import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/course_provider.dart';
import '../../widgets/course_card.dart';

/// 2.1–2.5 Luxury Course Catalog View.
/// Features high-end search, category filtering, and obsidian course cards.
class CatalogView extends StatefulWidget {
  const CatalogView({super.key});

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CourseProvider>().loadCatalog();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final user = context.watch<AuthProvider>().user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Luxury Welcome Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user?.fullName.split(' ').first ?? 'Scholar'}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Explore elite micro-courses & executive masterclasses',
                style: TextStyle(
                  color: AppTheme.goldLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // 2.2 Search Courses Field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: AppTheme.textPrimary),
            onSubmitted: (query) =>
                context.read<CourseProvider>().search(query),
            decoration: InputDecoration(
              hintText: 'Search courses by title or keyword',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppTheme.goldPrimary),
              suffixIcon: courseProvider.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        context.read<CourseProvider>().search('');
                      },
                    ),
            ),
          ),
        ),

        // 2.3 Browse by Category Filter Chips
        SizedBox(
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _categoryChip(
                context,
                label: 'All',
                isSelected: courseProvider.selectedCategoryId == null,
                onTap: () =>
                    context.read<CourseProvider>().filterByCategory(null),
              ),
              ...courseProvider.categories.map(
                (category) => _categoryChip(
                  context,
                  label: category.name,
                  isSelected:
                      courseProvider.selectedCategoryId == category.id,
                  onTap: () => context
                      .read<CourseProvider>()
                      .filterByCategory(category.id),
                ),
              ),
            ],
          ),
        ),

        // 2.1 Course List
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.goldPrimary,
            backgroundColor: AppTheme.bgCard,
            onRefresh: () => context.read<CourseProvider>().loadCatalog(),
            child: _buildCourseList(context, courseProvider),
          ),
        ),
      ],
    );
  }

  Widget _categoryChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        selectedColor: AppTheme.goldPrimary,
        backgroundColor: AppTheme.bgCard,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? AppTheme.goldPrimary : AppTheme.borderLight,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildCourseList(BuildContext context, CourseProvider provider) {
    if (provider.isLoading && provider.courses.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldPrimary),
      );
    }

    if (provider.error != null && provider.courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 52, color: AppTheme.accentRuby),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => provider.loadCatalog(),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_outlined,
                  size: 52, color: AppTheme.goldLight),
              const SizedBox(height: 16),
              Text(
                provider.searchQuery.isNotEmpty
                    ? 'No courses match your search.'
                    : 'No courses found',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try selecting another category or clear your search query.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  provider.search('');
                  provider.filterByCategory(null);
                },
                child: const Text('RESET FILTERS'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: provider.courses.length,
      itemBuilder: (context, index) {
        final course = provider.courses[index];
        final category = provider.categoryById(course.categoryId);
        return CourseCard(
          course: course,
          categoryName: category?.name ?? 'General',
          onTap: () {
            Navigator.of(context).pushNamed(
              '/course-detail',
              arguments: course.id,
            );
          },
        );
      },
    );
  }
}
