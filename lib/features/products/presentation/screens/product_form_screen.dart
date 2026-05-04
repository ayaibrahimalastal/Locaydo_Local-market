// lib/features/products/presentation/screens/product_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/enums/product_form_enums.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';
import 'package:locaydo_app/core/utils/bottom_sheet_helper.dart';
import 'package:locaydo_app/core/utils/helpers.dart';
import 'package:locaydo_app/core/utils/image_picker_helper.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:locaydo_app/features/products/presentation/viewmodels/product_form_viewmodel.dart';
import 'package:locaydo_app/shared/widgets/common/button.dart';
import 'package:locaydo_app/shared/widgets/form/dropdown_builder.dart';
import 'package:locaydo_app/shared/widgets/form/input.dart';
import 'package:locaydo_app/shared/widgets/form/multi_image_uploader_widget.dart';
import 'package:locaydo_app/shared/widgets/form/payment_methods_section.dart';
import 'package:provider/provider.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductFormMode        mode;
  final Map<String, dynamic>?  initialData;

  const ProductFormScreen.add({super.key})
      : mode        = ProductFormMode.add,
        initialData = null;

  const ProductFormScreen.edit({super.key, required this.initialData})
      : mode = ProductFormMode.edit,
        assert(initialData != null, 'initialData مطلوب في وضع التعديل');

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _scrollController = ScrollController();
  final Map<ProductField, FocusNode> _focusNodes = {
    ProductField.name:        FocusNode(),
    ProductField.description: FocusNode(),
    ProductField.price:       FocusNode(),
  };

  final _logger = DebugLogger();
  String? _editingProductId;

  @override
  void dispose() {
    _scrollController.dispose();
    for (final n in _focusNodes.values) n.dispose();
    super.dispose();
  }

  void _scrollToTop() => _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

  void _handleImageTap(ProductFormViewModel vm) {
    BottomSheetHelper.showImagePickerOptions(
      context: context,
      onGalleryTap: () async {
        final path = await ImagePickerHelper.pickFromGallery();
        if (path != null && mounted) vm.addImage(path);
      },
      onCameraTap: () async {
        final path = await ImagePickerHelper.takePhoto();
        if (path != null && mounted) vm.addImage(path);
      },
    );
  }

  void _submitForm(ProductFormViewModel vm) {
    FocusScope.of(context).unfocus();
    vm.validateForm();

    if (!vm.isValid) { 
      _scrollToTop(); 
      return; 
    }

    final Future<SaveProductResult> saveFuture =
        widget.mode == ProductFormMode.edit && _editingProductId != null
            ? vm.updateProductInFirebase(_editingProductId!)
            : vm.saveProductToFirebase();

    saveFuture.then((result) {
      if (!mounted) return;

      if (result.success) {
        Helpers.showSnackBar(context, result.message);

        if (result.product != null) {
          final homeVm = context.read<HomeViewModel>();
          if (widget.mode == ProductFormMode.edit) {
            homeVm.removeProduct(result.product!.id);
            homeVm.addNewProduct(result.product!);
          } else {
            if (homeVm.getProductById(result.product!.id) == null) {
              homeVm.addNewProduct(result.product!);
            }
          }
        }
        if (mounted) Navigator.pop(context, true);
      } else {
        Helpers.showSnackBar(context, result.message);
      }
    }).catchError((error) {
      if (mounted) {
        Helpers.showSnackBar(context, 'حدث خطأ غير متوقع: $error');
        _logger.error('Unexpected error in _submitForm', error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == ProductFormMode.edit && widget.initialData != null) {
      _editingProductId = widget.initialData!['id'] as String?;
    }

    return ChangeNotifierProvider(
      create: (_) => ProductFormViewModel(
        mode:        widget.mode,
        initialData: widget.initialData,
      ),
      child: Consumer<ProductFormViewModel>(
        builder: (context, vm, _) => Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: Text(widget.mode.title,
                  style: AppTextStyles.displaySmall(context)
                      .copyWith(fontWeight: FontWeight.bold)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary),
                onPressed: () {
                  if (vm.isSaving) {
                    Helpers.showSnackBar(context,
                        'يرجى الانتظار حتى يتم حفظ المنتج');
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            body: SafeArea(
              child: Center(
                child: SizedBox(
                  width: context.contentWidth,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // شريط التقدم وحالة الحفظ
                        if (vm.isSaving) _buildSavingIndicator(vm),
                        
                        IgnorePointer(
                          ignoring: vm.isSaving,
                          child: Column(
                            children: [
                              Input(
                                label:           AppStrings.productNameLabel,
                                hintText:        AppStrings.productNameHint,
                                controller:      vm.nameController,
                                focusNode:       _focusNodes[ProductField.name],
                                errorText:       vm.errors[ProductField.name],
                                textInputAction: TextInputAction.next,
                                onChanged:       (_) => vm.clearFieldError(ProductField.name),
                                onSubmitted:     (_) => _focusNodes[ProductField.description]?.requestFocus(),
                              ),
                              const SizedBox(height: 16),
                              Input(
                                label:           AppStrings.productDescriptionLabel,
                                hintText:        AppStrings.productDescriptionHint,
                                controller:      vm.descriptionController,
                                focusNode:       _focusNodes[ProductField.description],
                                errorText:       vm.errors[ProductField.description],
                                minLines:        4,
                                maxLines:        6,
                                textInputAction: TextInputAction.next,
                                onChanged:       (_) => vm.clearFieldError(ProductField.description),
                                onSubmitted:     (_) => _focusNodes[ProductField.price]?.requestFocus(),
                              ),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Input(
                                    label:           AppStrings.productPriceLabel,
                                    hintText:        AppStrings.productPriceHint,
                                    controller:      vm.priceController,
                                    focusNode:       _focusNodes[ProductField.price],
                                    errorText:       vm.errors[ProductField.price],
                                    keyboardType:    const TextInputType.numberWithOptions(decimal: true),
                                    textInputAction: TextInputAction.done,
                                    onChanged:       vm.isDonation ? null : (_) => vm.clearFieldError(ProductField.price),
                                    onSubmitted:     (_) => _submitForm(vm),
                                    enabled:         !vm.isDonation && !vm.isSaving,
                                  ),
                                  if (vm.isDonation)
                                    const _DonationNote(),
                                ],
                              ),
                              const SizedBox(height: 16),
                              DropdownBuilder<ProductCondition>(
                                label:     AppStrings.productConditionLabel,
                                value:     vm.condition,
                                onChanged: (v) {
                                  if (vm.isSaving || v == null) return;
                                  vm.condition = v;
                                  vm.clearFieldError(ProductField.condition);
                                },
                                items:     ProductCondition.values,
                                getLabel:  (i) => i.label,
                                errorText: vm.errors[ProductField.condition],
                              ),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  PaymentMethodsSection(
                                    label:            AppStrings.paymentMethodsLabel,
                                    selectedPayments: vm.selectedPayments,
                                    paymentError:     vm.errors[ProductField.payment],
                                    onAdd:  (m) {
                                      if (vm.isSaving) return;
                                      vm.selectedPayments.add(m);
                                      vm.clearFieldError(ProductField.payment);
                                    },
                                    onRemove: (m) {
                                      if (vm.isSaving) return;
                                      vm.selectedPayments.remove(m);
                                      vm.clearFieldError(ProductField.payment);
                                    },
                                    allMethods: PaymentMethod.values,
                                    isEnabled: !vm.isDonation && !vm.isSaving,
                                  ),
                                  if (vm.isDonation)
                                    const _DonationNote(),
                                ],
                              ),
                              const SizedBox(height: 16),
                              DropdownBuilder<ProductCategory>(
                                label:     AppStrings.categoryLabel,
                                value:     vm.category,
                                onChanged: (v) {
                                  if (vm.isSaving || v == null) return;
                                  vm.onCategoryChanged(v);
                                },
                                items: ProductCategory.values
                                    .where((c) => c != ProductCategory.all)
                                    .toList(),
                                getLabel:  (i) => i.label,
                                errorText: vm.errors[ProductField.category],
                              ),
                              const SizedBox(height: 16),
                              DropdownBuilder<Location>(
                                label:     AppStrings.locationLabel,
                                value:     vm.location,
                                onChanged: (v) {
                                  if (vm.isSaving || v == null) return;
                                  vm.location = v;
                                  vm.clearFieldError(ProductField.location);
                                },
                                items:     Location.values,
                                getLabel:  (i) => i.label,
                                errorText: vm.errors[ProductField.location],
                              ),
                              const SizedBox(height: 16),
                              MultiImageUploaderWidget(
                                imagePaths:    vm.imagePaths,
                                onAddImage:    (p) {
                                  if (vm.isSaving) return;
                                  vm.addImage(p);
                                },
                                onRemoveImage: (i) {
                                  if (vm.isSaving) return;
                                  vm.removeImage(i);
                                },
                                errorText: vm.errors[ProductField.image],
                                label:     'صور المنتج',
                                hintText:  'اضغط لإضافة صورة',
                                maxImages: 6,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        // زر الحفظ أو مؤشر التحميل
                        if (vm.isSaving)
                          _buildLoadingButton()
                        else
                          Button(
                            text:        widget.mode.buttonText,
                            onPressed:   () => _submitForm(vm),
                            variant:     ButtonVariant.primary,
                            size:        ButtonSize.large,
                            isFullWidth: true,
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavingIndicator(ProductFormViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.mode == ProductFormMode.add
                    ? 'جاري إضافة المنتج...'
                    : 'جاري تحديث المنتج...',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (vm.uploadProgress > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: vm.uploadProgress,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
              vm.uploadStatus,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (vm.saveErrorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              vm.saveErrorMessage!,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: Colors.red,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingButton() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _DonationNote extends StatelessWidget {
  const _DonationNote();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.primaryDark,
              size: FigmaDesignSystem.getResponsiveFontSize(context, 14),
            ),
            const SizedBox(width: 4),
            Text(
              AppStrings.donationMessage,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}