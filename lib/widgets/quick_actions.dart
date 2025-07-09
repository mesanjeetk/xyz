import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'title': 'New Tutorial',
        'icon': Icons.play_arrow,
        'color': const Color(0xFF6366F1),
        'onTap': () {},
      },
      {
        'title': 'Browse Files',
        'icon': Icons.folder,
        'color': const Color(0xFF14B8A6),
        'onTap': () {},
      },
      {
        'title': 'Code Example',
        'icon': Icons.code,
        'color': const Color(0xFFF59E0B),
        'onTap': () {},
      },
      {
        'title': 'Settings',
        'icon': Icons.settings,
        'color': const Color(0xFFEF4444),
        'onTap': () {},
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: actions.map((action) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                child: InkWell(
                  onTap: action['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: (action['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          action['icon'] as IconData,
                          size: 24.sp,
                          color: action['color'] as Color,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          action['title'] as String,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: action['color'] as Color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}