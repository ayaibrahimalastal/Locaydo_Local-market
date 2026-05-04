// lib/shared/widgets/navigation/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locaydo_app/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:locaydo_app/features/home/presentation/screens/home_screen.dart';
import 'package:locaydo_app/features/products/presentation/screens/product_form_screen.dart';
import 'package:locaydo_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:locaydo_app/features/profile/presentation/screens/vendor_check_screen.dart';
import 'package:locaydo_app/shared/widgets/navigation/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:locaydo_app/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;
  late List<Widget> _screens;

  bool _isSellerProfileCompleted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _checkSellerStatus();
  }

  Future<void> _checkSellerStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _isSellerProfileCompleted = false;
        setState(() => _isLoading = false);
        _buildScreens();
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        _isSellerProfileCompleted = data?['hasCompletedSellerProfile'] ?? false;
      } else {
        _isSellerProfileCompleted = false;
      }
      
      debugPrint('🔍 Seller profile completed: $_isSellerProfileCompleted');
      
    } catch (e) {
      debugPrint('❌ Error checking seller status: $e');
      _isSellerProfileCompleted = false;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _buildScreens();
      }
    }
  }

  void _buildScreens() {
    _screens = [
      const HomeScreen(),
      const SizedBox.shrink(),
      const FavoritesScreen(),
      const ProfileScreen(),
    ];
  }

  Future<void> _openAddProductScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        _showLoginRequiredDialog();
      }
      return;
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري التحقق من ملف البيع...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      bool isCompleted = false;
      if (userDoc.exists) {
        final data = userDoc.data();
        isCompleted = data?['hasCompletedSellerProfile'] ?? false;
        _isSellerProfileCompleted = isCompleted;
      }
      
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      
      if (isCompleted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProductFormScreen.add(),
          ),
        ).then((result) {
          if (result == true && mounted) {
            _refreshHomeScreenIfNeeded();
          }
        });
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VendorCheckScreen(),
          ),
        );
        
        await _checkSellerStatus();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('❌ Error: $e');
      if (mounted) {
        _showErrorDialog();
      }
    }
  }

  void _refreshHomeScreenIfNeeded() {
    try {
      final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
      homeViewModel.refreshProducts();
      debugPrint('✅ HomeScreen refreshed successfully');
    } catch (e) {
      debugPrint('⚠️ Could not refresh HomeScreen: $e');
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الدخول مطلوب'),
        content: const Text('يرجى تسجيل الدخول أولاً لإضافة منتج'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ'),
        content: const Text('حدث خطأ، يرجى المحاولة مرة أخرى'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _handleStoreTap() {
    _openAddProductScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          if (index == 1) {
            _handleStoreTap();
            return;
          }
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}