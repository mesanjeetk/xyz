import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../widgets/feature_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/quick_actions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveBreakpoints.of(context).isMobile;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              AnimationConfiguration.staggeredList(
                position: 0,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildHeader(),
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Stats Cards
              AnimationConfiguration.staggeredList(
                position: 1,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildStatsSection(),
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Quick Actions
              AnimationConfiguration.staggeredList(
                position: 2,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: const QuickActions(),
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Features Grid
              AnimationConfiguration.staggeredList(
                position: 3,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildFeaturesSection(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.flutter_dash,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    'Flutter Developer',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.notifications_outlined,
                size: 24.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          'Continue your Flutter learning journey',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            title: 'Concepts Learned',
            value: '12',
            icon: Icons.school,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: StatsCard(
            title: 'Projects Built',
            value: '3',
            icon: Icons.build,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'title': 'Splash Screen',
        'description': 'Animated app launch experience',
        'icon': Icons.play_circle_outline,
        'color': const Color(0xFF6366F1),
      },
      {
        'title': 'Navigation',
        'description': 'Bottom tabs and routing',
        'icon': Icons.navigation,
        'color': const Color(0xFF14B8A6),
      },
      {
        'title': 'Deep Linking',
        'description': 'Custom URL schemes',
        'icon': Icons.link,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'PDF Viewer',
        'description': 'Document viewing capabilities',
        'icon': Icons.picture_as_pdf,
        'color': const Color(0xFFEF4444),
      },
      {
        'title': 'Responsive Design',
        'description': 'Adaptive layouts',
        'icon': Icons.devices,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'State Management',
        'description': 'Riverpod implementation',
        'icon': Icons.settings,
        'color': const Color(0xFF06B6D4),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning Features',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        AnimationLimiter(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveBreakpoints.of(context).isMobile ? 2 : 3,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 1.2,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 375),
                columnCount: ResponsiveBreakpoints.of(context).isMobile ? 2 : 3,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: FeatureCard(
                      title: feature['title'] as String,
                      description: feature['description'] as String,
                      icon: feature['icon'] as IconData,
                      color: feature['color'] as Color,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}