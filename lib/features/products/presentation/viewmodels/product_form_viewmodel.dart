import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/enums/product_form_enums.dart';
import 'package:locaydo_app/core/network/firebase_collections.dart';
import 'package:locaydo_app/core/utils/cloudinary_uploader.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/core/utils/product_helper.dart';
import 'package:locaydo_app/core/utils/validators.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/features/products/data/models/seller_product_model.dart';
import 'package:locaydo_app/features/products/data/repositories/product_repository_impl.dart';

class SaveProductResult {
  final bool success;
  final String message;
  final ProductModel? product;

  const SaveProductResult({
    required this.success,
    required this.message,
    this.product,
  });
}

class ProductFormViewModel extends ChangeNotifier {
  final ProductFormMode mode;
  final Logger _logger;
  final ProductRepositoryImpl _productRepository;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();

  ProductCondition condition = ProductCondition.new_;
  ProductCategory category = ProductCategory.electronics;
  Location location = Location.northGaza;
  List<PaymentMethod> selectedPayments = [];

  final List<PaymentMethod> defaultPayments = ProductHelper.getDefaultPayments();
  List<String> _imagePaths = [];
  final Map<ProductField, String?> errors = {};

  bool _isSaving = false;
  String? _saveErrorMessage;
  double _uploadProgress = 0.0;
  int _currentUploadingImage = 0;
  int _totalImagesToUpload = 0;

  bool get hasImages => _imagePaths.isNotEmpty;
  bool get isDonation => ProductHelper.isDonation(category);
  bool get isEditMode => mode == ProductFormMode.edit;
  bool get isValid => errors.values.every((e) => e == null);
  bool get isSaving => _isSaving;
  String? get saveErrorMessage => _saveErrorMessage;
  double get uploadProgress => _uploadProgress;
  String get uploadStatus {
    if (_totalImagesToUpload == 0) return '';
    return 'جاري رفع الصورة $_currentUploadingImage من $_totalImagesToUpload';
  }

  List<String> get imagePaths => _imagePaths;

  ProductFormViewModel({
    required this.mode,
    Map<String, dynamic>? initialData,
    ProductRepositoryImpl? productRepository,
    Logger? logger,
  })  : _productRepository = productRepository ??
            ProductRepositoryImpl(logger: logger ?? DebugLogger()),
        _logger = logger ?? DebugLogger() {
    priceController.text = '0.00';
    if (isEditMode && initialData != null) {
      _loadInitialData(initialData);
    } else {
      selectedPayments = List.from(defaultPayments);
    }
    nameController.addListener(() => errors.containsKey(ProductField.name)
        ? clearFieldError(ProductField.name)
        : null);
    descriptionController.addListener(() =>
        errors.containsKey(ProductField.description)
            ? clearFieldError(ProductField.description)
            : null);
    priceController.addListener(() => errors.containsKey(ProductField.price) && !isDonation
        ? clearFieldError(ProductField.price)
        : null);
  }

  void _loadInitialData(Map<String, dynamic> d) {
    _logger.log('📝 Loading initial data for editing...');
    
    nameController.text = d['name'] as String? ?? '';
    descriptionController.text = d['description'] as String? ?? '';
    priceController.text = d['price']?.toString() ?? '0.00';
    condition = d['condition'] as ProductCondition? ?? ProductCondition.new_;
    category = d['category'] as ProductCategory? ?? ProductCategory.electronics;
    location = d['location'] as Location? ?? Location.northGaza;
    selectedPayments = List.from(d['payments'] ?? [PaymentMethod.cash]);
    
    // ✅ ✅ ✅ قراءة الصور من initialData
    _imagePaths = List<String>.from(d['imagePaths'] ?? []);
    
    _logger.log('📸 Loaded ${_imagePaths.length} images for editing');
    if (_imagePaths.isNotEmpty) {
      _logger.log('📸 First image: ${_imagePaths.first}');
      _logger.log('📸 All images: $_imagePaths');
    }
  }

  void validateForm() {
    errors[ProductField.name] = AppValidators.validateProductName(nameController.text);
    errors[ProductField.description] =
        AppValidators.validateProductDescription(descriptionController.text);
    errors[ProductField.payment] =
        ProductHelper.validatePaymentMethodsByCategory(selectedPayments, category);
    errors[ProductField.image] = AppValidators.validateProductImage(hasImages);
    errors[ProductField.category] = AppValidators.validateCategory(category.label);
    errors[ProductField.location] = AppValidators.validateLocation(location.label);
    errors[ProductField.condition] = AppValidators.validateCondition(condition.label);
    errors[ProductField.price] = ProductHelper.validatePriceByCategory(priceController.text, category);
    notifyListeners();
  }

  void onCategoryChanged(ProductCategory newCategory) {
    final result = ProductHelper.handleCategoryChange(
      newCategory: newCategory,
      currentPrice: priceController.text,
      currentPayments: selectedPayments,
      defaultPayments: defaultPayments,
    );
    category = result.category;
    priceController.text = result.priceText;
    selectedPayments = result.payments;
    errors.remove(ProductField.category);
    if (ProductHelper.isDonation(newCategory)) {
      errors.remove(ProductField.price);
      errors.remove(ProductField.payment);
    }
    notifyListeners();
  }

  void clearFieldError(ProductField field) {
    errors.remove(field);
    notifyListeners();
  }

  void addImage(String path) {
    _imagePaths.add(path);
    errors.remove(ProductField.image);
    notifyListeners();
  }

  void removeImage(int index) {
    _imagePaths.removeAt(index);
    if (_imagePaths.isEmpty) {
      errors[ProductField.image] = 'يجب إضافة صورة واحدة على الأقل';
    }
    notifyListeners();
  }

  void setSaving(bool value, {String? errorMessage}) {
    _isSaving = value;
    _saveErrorMessage = errorMessage;
    if (!value) {
      _resetUploadProgress();
    }
    notifyListeners();
  }

  void _resetUploadProgress() {
    _uploadProgress = 0.0;
    _currentUploadingImage = 0;
    _totalImagesToUpload = 0;
  }

  void _updateUploadProgress(int current, int total) {
    _currentUploadingImage = current;
    _totalImagesToUpload = total;
    _uploadProgress = current / total;
    notifyListeners();
  }

  double? get price {
    if (isDonation) return 0.0;
    return AppValidators.parsePrice(priceController.text);
  }

  String get successMessage {
    if (isDonation) return mode.donationSuccessMessage;
    final priceText = AppValidators.formatPriceForDisplay(priceController.text);
    return '${mode.successMessage} بسعر $priceText ₪';
  }

  // ✅ دالة مساعدة للحصول على اسم البائع و sellerId
  Future<_SellerInfo> _getSellerInfo(User user) async {
    String sellerId = user.uid;
    String sellerName = user.displayName ?? user.email?.split('@').first ?? 'بائع';

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final storedSellerId = data?['sellerId'] as String?;
        if (storedSellerId != null && storedSellerId.isNotEmpty) {
          sellerId = storedSellerId;

          // جلب اسم البائع من sellers collection
          final sellerDoc = await FirebaseFirestore.instance
              .collection(FirebaseCollections.sellers)
              .doc(sellerId)
              .get();

          if (sellerDoc.exists) {
            sellerName = sellerDoc.data()?['name'] as String? ?? sellerName;
          }
        }
      }
    } catch (e) {
      _logger.error('Failed to get seller info', e);
    }

    return _SellerInfo(sellerId: sellerId, sellerName: sellerName);
  }

  // ── Save with Timeout & Progress ──────────────────────
  Future<SaveProductResult> saveProductToFirebase() async {
    setSaving(true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return _fail('يرجى تسجيل الدخول أولاً');
      }

      // ✅ الحصول على معلومات البائع
      final sellerInfo = await _getSellerInfo(user);
      _logger.log('📝 Seller info: id=${sellerInfo.sellerId}, name=${sellerInfo.sellerName}');

      // رفع الصور مع تايم أوت وتحديث التقدم
      final urls = await _uploadImagesWithProgress(_imagePaths);
      if (urls.isEmpty) {
        return _fail('فشل رفع الصور. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى');
      }

      final docRef = FirebaseFirestore.instance
          .collection(FirebaseCollections.products)
          .doc();
      final productId = docRef.id;

      // ✅ حفظ المنتج مع كلاً من userId و sellerId
      await docRef.set({
        'id': productId,
        'title': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': price ?? 0,
        'currency': '₪',
        'location': location.label,
        'imageUrl': urls.first,
        'additionalImages': urls.length > 1 ? urls.sublist(1) : [],
        'category': category.name,
        'condition': condition.name,
        'paymentMethods': selectedPayments.map((e) => e.name).toList(),
        'userId': user.uid,
        'sellerId': sellerInfo.sellerId,
        'sellerName': sellerInfo.sellerName,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw 'انتهت مهلة حفظ المنتج. يرجى التحقق من اتصالك بالإنترنت.',
      );

      final product = ProductModel(
        id: productId,
        title: nameController.text.trim(),
        description: descriptionController.text.trim(),
        price: price ?? 0,
        currency: '₪',
        location: location.label,
        imageUrl: urls.first,
        additionalImages: urls.length > 1 ? urls.sublist(1) : [],
        category: category,
        condition: condition,
        paymentMethods: selectedPayments.toList(),
        sellerId: sellerInfo.sellerId,
        sellerName: sellerInfo.sellerName,
        createdAt: DateTime.now(),
        status: ProductStatus.available,
      );

      _logger.log('✅ Product saved successfully with sellerId: ${product.sellerId}');
      return SaveProductResult(success: true, message: successMessage, product: product);
    } catch (e) {
      _logger.error('Failed to save product', e);
      String errorMessage = 'حدث خطأ أثناء حفظ المنتج';
      if (e.toString().contains('timeout') || e.toString().contains('Timed out')) {
        errorMessage = 'انتهت المهلة. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى';
      } else if (e.toString().contains('Network') || e.toString().contains('Connection')) {
        errorMessage = 'مشكلة في الاتصال بالإنترنت. يرجى التحقق من الشبكة';
      }
      return _fail(errorMessage);
    } finally {
      setSaving(false);
    }
  }

  Future<SaveProductResult> updateProductInFirebase(String productId) async {
    setSaving(true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return _fail('يرجى تسجيل الدخول أولاً');
      }

      // ✅ الحصول على معلومات البائع للتحديث
      final sellerInfo = await _getSellerInfo(user);

      final urls = await _processImagesWithProgress(_imagePaths);
      if (urls.isEmpty) {
        return _fail('فشل رفع الصور. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى');
      }

      await FirebaseFirestore.instance
          .collection(FirebaseCollections.products)
          .doc(productId)
          .update({
        'title': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': price ?? 0,
        'location': location.label,
        'imageUrl': urls.first,
        'additionalImages': urls.length > 1 ? urls.sublist(1) : [],
        'category': category.name,
        'condition': condition.name,
        'paymentMethods': selectedPayments.map((e) => e.name).toList(),
        'sellerId': sellerInfo.sellerId,
        'sellerName': sellerInfo.sellerName,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw 'انتهت مهلة تحديث المنتج',
      );

      final product = ProductModel(
        id: productId,
        title: nameController.text.trim(),
        description: descriptionController.text.trim(),
        price: price ?? 0,
        currency: '₪',
        location: location.label,
        imageUrl: urls.first,
        additionalImages: urls.length > 1 ? urls.sublist(1) : [],
        category: category,
        condition: condition,
        paymentMethods: selectedPayments.toList(),
        sellerId: sellerInfo.sellerId,
        sellerName: sellerInfo.sellerName,
        createdAt: DateTime.now(),
        status: ProductStatus.available,
      );

      _logger.log('✅ Product updated successfully: ${product.title}');
      return SaveProductResult(success: true, message: 'تم تحديث المنتج بنجاح', product: product);
    } catch (e) {
      _logger.error('Failed to update product', e);
      String errorMessage = 'حدث خطأ أثناء تحديث المنتج';
      if (e.toString().contains('timeout')) {
        errorMessage = 'انتهت المهلة. يرجى المحاولة مرة أخرى';
      }
      return _fail(errorMessage);
    } finally {
      setSaving(false);
    }
  }

  // رفع الصور مع تايم أوت وتحسين الأداء
  Future<List<String>> _uploadImagesWithProgress(List<String> paths) async {
    if (paths.isEmpty) return [];

    final urls = <String>[];
    _resetUploadProgress();
    final total = paths.length;

    for (int i = 0; i < total; i++) {
      _updateUploadProgress(i + 1, total);

      final url = await CloudinaryUploader.uploadImage(File(paths[i])).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw 'انتهت مهلة رفع الصورة ${i + 1}',
      );

      if (url != null) {
        urls.add(url);
      } else {
        throw 'فشل رفع الصورة ${i + 1}';
      }
    }

    _resetUploadProgress();
    return urls;
  }

  Future<List<String>> _processImagesWithProgress(List<String> paths) async {
    if (paths.isEmpty) return [];

    final urls = <String>[];
    _resetUploadProgress();

    // فصل الصور المحلية عن الصور المستضافة مسبقاً
    final localImages = <String>[];
    final remoteImages = <String>[];

    for (final path in paths) {
      if (path.startsWith('http')) {
        remoteImages.add(path);
        _logger.log('📸 Remote image (kept as is): $path');
      } else {
        localImages.add(path);
        _logger.log('📸 Local image (will upload): $path');
      }
    }

    // إضافة الصور المستضافة مباشرة
    urls.addAll(remoteImages);

    // رفع الصور الجديدة فقط مع تتبع التقدم
    final total = localImages.length;
    for (int i = 0; i < total; i++) {
      _updateUploadProgress(i + 1, total);

      final url = await CloudinaryUploader.uploadImage(File(localImages[i])).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw 'انتهت مهلة رفع الصورة ${i + 1}',
      );

      if (url != null) {
        urls.add(url);
        _logger.log('✅ Uploaded image ${i + 1}/$total: $url');
      } else {
        throw 'فشل رفع الصورة ${i + 1}';
      }
    }

    _resetUploadProgress();
    _logger.log('📸 Total images after processing: ${urls.length}');
    return urls;
  }

  void reset() {
    nameController.clear();
    descriptionController.clear();
    priceController.text = '0.00';
    condition = ProductCondition.new_;
    category = ProductCategory.electronics;
    location = Location.northGaza;
    selectedPayments = List.from(defaultPayments);
    _imagePaths = [];
    errors.clear();
    _resetUploadProgress();
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  SaveProductResult _fail(String message) {
    setSaving(false, errorMessage: message);
    return SaveProductResult(success: false, message: message);
  }
}

// ✅ كلاس مساعد لتخزين معلومات البائع
class _SellerInfo {
  final String sellerId;
  final String sellerName;

  _SellerInfo({required this.sellerId, required this.sellerName});
}