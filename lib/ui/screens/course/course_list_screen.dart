import 'package:flutter/material.dart';

import 'catalog_view.dart';

/// 2.1 View Available Courses — standalone catalog route (also embedded in the
/// home shell). Wraps the shared [CatalogView].
class CourseListScreen extends StatelessWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Catalog')),
      body: const CatalogView(),
    );
  }
}
