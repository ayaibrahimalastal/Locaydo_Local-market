// lib/features/categories/presentation/screens/categories_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/categories/data/models/category_model.dart';
import 'package:locaydo_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:locaydo_app/features/categories/presentation/viewmodels/categories_viewmodel.dart';
import 'package:provider/provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoriesViewModel(
        logger: DebugLogger(),
        categoryRepository: CategoryRepositoryImpl(logger: DebugLogger()),
      ),
      child: Consumer<CategoriesViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.categories.isEmpty) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary1,
                ),
              ),
            );
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text('الفئات',
                    style: AppTextStyles.displaySmall(context)
                        .copyWith(fontWeight: FontWeight.bold)),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary),
                  onPressed: () {
                    // ✅ عند الرجوع، نمرر إشارة لإعادة تعيين الفئة إلى "الكل"
                    Navigator.pop(context, true);
                  },
                ),
                centerTitle: true,
              ),
              body: SafeArea(
                child: Center(
                  child: Container(
                    width: context.contentWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: vm.categories.length,
                          itemBuilder: (ctx, i) {
                            final category = vm.categories[i];
                            return _CategoryCard(
                              category: category,
                              onTap: () async {
                                // ✅ عند اختيار فئة، نذهب لصفحة التفاصيل
                                await Navigator.pushNamed(
                                  context,
                                  AppRoutes.categoryDetails,
                                  arguments: {
                                    'categoryId': category.id,
                                    'categoryName': category.name,
                                  },
                                );
                                // ✅ لا نمرر أي شيء عند العودة من تفاصيل الفئة
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary1.withOpacity(0.09),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.stroke.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(
                  category.iconPath,
                  width: 32,
                  height: 32,
                  colorFilter: const ColorFilter.mode(
                      AppColors.iconforeground, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontSize: context.responsiveFontSize(14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}