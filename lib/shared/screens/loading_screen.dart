import 'package:flutter/material.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';

class LoadingScreen extends StatelessWidget {
  final String message;

  const LoadingScreen({
    super.key,
    this.message = 'جاري فتح المنتج...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ لوجو متحرك
          
            const SizedBox(height: 32),
            
            // ✅ مؤشر تحميل
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary1),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            
            // ✅ نص التحميل
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            
            // ✅ نص صغير متحرك
            const _AnimatedDots(),
          ],
        ),
      ),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> {
  String dots = '';

  @override
  void initState() {
    super.initState();
    // ✅ تغيير النقاط كل نص ثانية
    int count = 0;
    Future.delayed(Duration.zero, () {
      setState(() {
        dots = '.';
      });
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return false;
      setState(() {
        count = (count + 1) % 4;
        dots = '.' * count;
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$dots',
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textPlaceholder,
      ),
    );
  }
}