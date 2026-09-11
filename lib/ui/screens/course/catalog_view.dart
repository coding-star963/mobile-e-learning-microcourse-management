import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/course_provider.dart';
import '../../widgets/course_card.dart';

/// Reusable catalog content for Module 2: search field (2.2), category chips
/// (2.3), and the published-course list (2.1) with loading/empty/error states.
/// Embedded in [HomeShell]; wrapped by [CourseListScreen] for the route.
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
    // 2.1 load the catalog on first build.
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
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Welcome header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hey ${user?.fullName.split(' ').first ?? 'there'} 👋',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                'Find your next micro-course',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),

        // 2.2 Search Courses
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (query) =>
                context.read<CourseProvider>().search(query),
            decoration: InputDecoration(
              hintText: 'Search courses by title or keyword',
              prefixIcon: const Icon(Icons.search_outlined),
              suffixIcon: courseProvider.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        context.read<CourseProvider>().search('');
                      },
                    ),
            ),
          ),
        ),

        // 2.3 Browse by Category
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              _categoryChip(
                context,
                label: 'All',
                icon: Icons.apps_outlined,
                categoryId: null,
                selected: courseProvider.selectedCategoryId == null,
              ),
              for (final category in courseProvider.categories)
                _categoryChip(
                  context,
                  label: category.name,
                  icon: _categoryIcon(category.id),
                  categoryId: category.id,
                  selected: courseProvider.selectedCategoryId == category.id,
                ),
            ],
          ),
        ),

        if (courseProvider.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              courseProvider.error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),

        Expanded(child: _buildBody(context, courseProvider)),
      ],
    );
  }

  Widget _buildBody(BuildContext context, CourseProvider courseProvider) {
    final theme = Theme.of(context);

    // Loading state (AGENT.md §7).
    if (courseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Empty state — no published courses, no search hits, or empty category.
    if (courseProvider.courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_outlined,
                  size: 44, color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 16),
            Text(
              courseProvider.searchQuery.isNotEmpty
                  ? 'No courses match your search.'
                  : 'No courses available right now.',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              courseProvider.searchQuery.isNotEmpty
                  ? 'Try a different keyword.'
                  : 'Check back soon for new micro-courses.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      );
    }

    // Content state — the published course list (2.1).
    return RefreshIndicator(
      onRefresh: () => courseProvider.loadCatalog(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: courseProvider.courses.length,
        itemBuilder: (context, index) {
          final course = courseProvider.courses[index];
          return CourseCard(
            course: course,
            categoryName: courseProvider.categoryNameOf(course.categoryId),
            // 2.4 open the detail page.
            onTap: () =>
                Navigator.of(context).pushNamed('/course-detail', arguments: course.id),
          );
        },
      ),
    );
  }

  Widget _categoryChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String? categoryId,
    required bool selected,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) =>
            context.read<CourseProvider>().selectCategory(categoryId),
        avatar: Icon(
          icon,
          size: 16,
          color: selected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.outline,
        ),
      ),
    );
  }

  /// Small icon per category id for friendlier scanning (2.3).
  IconData _categoryIcon(String categoryId) => switch (categoryId) {
        'cat-mobile-dev' => Icons.smartphone_outlined,
        'cat-web-dev' => Icons.language_outlined,
        'cat-data' => Icons.bar_chart_outlined,
        'cat-design' => Icons.brush_outlined,
        _ => Icons.category_outlined,
      };
}
