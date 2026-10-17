import 'package:flutter/foundation.dart';

import '../data/repositories/course_repository.dart';
import '../models/course.dart';
import '../models/course_category.dart';

/// State holder for Module 2 — Course Discovery & Browsing.
/// Exposes the catalog (2.1), search (2.2), category filter (2.3), and course
/// detail (2.4) with loading/error state for screens (AGENT.md §4.4, §7).
class CourseProvider extends ChangeNotifier {
  CourseProvider({required CourseRepository repo})
      : _courseRepository = repo;

  final CourseRepository _courseRepository;

  List<Course> courses = [];
  List<CourseCategory> categories = [];

  /// Currently selected category id, or null for "All".
  String? selectedCategoryId;

  /// Current search query (empty string = no search active).
  String searchQuery = '';

  bool isLoading = false;
  String? error;

  /// 2.4 detail cache keyed by course id.
  final Map<String, Course> _courseDetails = {};

  /// Loads categories + published courses for the catalog (2.1, 2.3).
  Future<void> loadCatalog() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _courseRepository.getCategories(),
        _courseRepository.getPublishedCourses(),
      ]);
      categories = results[0] as List<CourseCategory>;
      courses = results[1] as List<Course>;
    } on Exception catch (e) {
      error = 'Could not load courses. Please try again.';
      debugPrint('CourseProvider.loadCatalog failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Background refresh of the catalog that keeps the current search or
  /// category filter; the current list stays on screen if the request fails.
  Future<void> refresh() async {
    try {
      final results = await Future.wait([
        _courseRepository.getCategories(),
        searchQuery.isNotEmpty
            ? _courseRepository.searchCourses(searchQuery)
            : selectedCategoryId != null
                ? _courseRepository.getCoursesByCategory(selectedCategoryId!)
                : _courseRepository.getPublishedCourses(),
      ]);
      categories = results[0] as List<CourseCategory>;
      courses = results[1] as List<Course>;
      error = null;
      notifyListeners();
    } on Exception catch (e) {
      debugPrint('CourseProvider.refresh failed: $e');
    }
  }

  /// 2.2 Search Courses — updates the query and refilters the catalog.
  Future<void> search(String query) async {
    searchQuery = query;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      courses = await _courseRepository.searchCourses(query);
    } on Exception catch (e) {
      error = 'Search failed. Please try again.';
      debugPrint('CourseProvider.search failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 2.3 Browse by Category — sets the filter and refetches.
  Future<void> selectCategory(String? categoryId) async {
    if (selectedCategoryId == categoryId) return;
    selectedCategoryId = categoryId;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      courses = categoryId == null
          ? await _courseRepository.getPublishedCourses()
          : await _courseRepository.getCoursesByCategory(categoryId);
      // A category change invalidates the previous search results.
      searchQuery = '';
    } on Exception catch (e) {
      error = 'Could not load courses. Please try again.';
      debugPrint('CourseProvider.selectCategory failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 2.4 View Course Details — fetches (and caches) one course.
  Future<Course> loadCourseDetails(String courseId) async {
    try {
      final course = await _courseRepository.getCourseDetails(courseId);
      _courseDetails[courseId] = course;
      return course;
    } on CourseNotFoundException {
      rethrow; // Screen shows a "not found" state.
    }
  }

  /// Synchronous accessor for already-loaded details (e.g. rebuilding).
  Course? cachedCourseDetails(String courseId) => _courseDetails[courseId];

  /// Looks up a course from the loaded catalog first, then the detail cache.
  /// Returns null when neither has been loaded yet.
  Course? courseById(String courseId) {
    for (final course in courses) {
      if (course.id == courseId) return course;
    }
    return _courseDetails[courseId];
  }

  /// Display name for a category id; courses without one (e.g. after an
  /// administrator deleted their category) are "Uncategorized", as on the web.
  String categoryNameOf(String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return uncategorized;
  }

  static const String uncategorized = 'Uncategorized';

  /// Categories that have at least one published course, for the catalog
  /// filter chips (an empty category would only lead to an empty list).
  List<CourseCategory> get browsableCategories => categories
      .where((c) => c.courseCount == null || c.courseCount! > 0 || c.id == selectedCategoryId)
      .toList();

  CourseCategory? categoryById(String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  Future<void> filterByCategory(String? categoryId) => selectCategory(categoryId);
}
