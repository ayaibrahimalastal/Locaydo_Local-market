// lib/core/enums/product_form_enums.dart
// ✅ المصدر الوحيد لـ ProductField — لا تعرّفه في أي مكان آخر

enum ProductField {
  name,
  description,
  price,
  payment,
  image,
  category,
  location,
  condition,
}

enum ProductFormMode {
  add,
  edit,
}

extension ProductFormModeExtension on ProductFormMode {
  String get title {
    switch (this) {
      case ProductFormMode.add:  return 'إضافة منتج';
      case ProductFormMode.edit: return 'تعديل المنتج';
    }
  }

  String get buttonText {
    switch (this) {
      case ProductFormMode.add:  return 'نشر المنتج';
      case ProductFormMode.edit: return 'تحديث المنتج';
    }
  }

  String get successMessage {
    switch (this) {
      case ProductFormMode.add:  return 'تم نشر المنتج بنجاح';
      case ProductFormMode.edit: return 'تم تحديث المنتج بنجاح';
    }
  }

  String get donationSuccessMessage {
    switch (this) {
      case ProductFormMode.add:  return 'تم نشر المنتج كتبرع بنجاح';
      case ProductFormMode.edit: return 'تم تحديث المنتج كتبرع بنجاح';
    }
  }
}