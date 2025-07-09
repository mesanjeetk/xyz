import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tutorials'),
            Tab(text: 'Examples'),
            Tab(text: 'Resources'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tutorials, examples, and resources...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTutorialsTab(),
                _buildExamplesTab(),
                _buildResourcesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialsTab() {
    final tutorials = [
      {
        'title': 'Getting Started with Flutter',
        'description': 'Learn the basics of Flutter development',
        'difficulty': 'Beginner',
        'duration': '2 hours',
        'icon': Icons.play_circle_outline,
      },
      {
        'title': 'State Management with Riverpod',
        'description': 'Master state management in Flutter',
        'difficulty': 'Intermediate',
        'duration': '3 hours',
        'icon': Icons.settings,
      },
      {
        'title': 'Building Responsive UIs',
        'description': 'Create adaptive layouts for all devices',
        'difficulty': 'Advanced',
        'duration': '4 hours',
        'icon': Icons.devices,
      },
      {
        'title': 'Navigation and Routing',
        'description': 'Implement complex navigation patterns',
        'difficulty': 'Intermediate',
        'duration': '2.5 hours',
        'icon': Icons.navigation,
      },
    ];

    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: tutorials.length,
        itemBuilder: (context, index) {
          final tutorial = tutorials[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildTutorialCard(tutorial),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTutorialCard(Map<String, dynamic> tutorial) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: () {
          // Navigate to tutorial
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  tutorial['icon'] as IconData,
                  size: 30.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tutorial['title'] as String,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      tutorial['description'] as String,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        _buildChip(tutorial['difficulty'] as String, _getDifficultyColor(tutorial['difficulty'] as String)),
                        SizedBox(width: 8.w),
                        _buildChip(tutorial['duration'] as String, Theme.of(context).colorScheme.secondary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _buildExamplesTab() {
    return const Center(
      child: Text('Examples coming soon!'),
    );
  }

  Widget _buildResourcesTab() {
    return const Center(
      child: Text('Resources coming soon!'),
    );
  }
}