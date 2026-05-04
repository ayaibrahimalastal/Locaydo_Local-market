// lib/features/products/widgets/share_product_overlay.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';
import 'package:locaydo_app/core/utils/helpers.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';

class ShareProductOverlay extends StatefulWidget {
  final ProductModel product;

  const ShareProductOverlay({super.key, required this.product});

  static Future<void> show({
    required BuildContext context,
    required ProductModel product,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ShareProductOverlay(product: product),
        ),
      ),
    );
  }

  @override
  State<ShareProductOverlay> createState() => _ShareProductOverlayState();
}

class _ShareProductOverlayState extends State<ShareProductOverlay> {
  late final List<_ShareOption> _options;

  String get _productLink =>
      'https://locaydo.netlify.app/product/${widget.product.id}';

  String get _shareMessage =>
      '✨ ${widget.product.title}\n'
      '💰 السعر: ${widget.product.price} ${widget.product.currency}\n'
      '📍 الموقع: ${widget.product.location}\n\n'
      '🔗 رابط المنتج:\n$_productLink';

  @override
  void initState() {
    super.initState();
    _options = [
      _ShareOption(
        svgPath: AppAssets.copy,
        name:    'نسخ الرابط',
        color:   AppColors.textPrimary,
        onTap:   _copyLink,
      ),
      _ShareOption(
        svgPath: AppAssets.whatsApp,
        name:    'واتساب',
        color:   const Color(0xFF25D366),
        onTap:   _shareWhatsApp,
      ),
      _ShareOption(
        svgPath: AppAssets.telegram2,
        name:    'تيليجرام',
        color:   const Color(0xFF0088CC),
        onTap:   _shareTelegram,
      ),
      _ShareOption(
        svgPath: AppAssets.instagram,
        name:    'إنستغرام',
        color:   const Color(0xFFE4405F),
        onTap:   _shareInstagram,
      ),
      _ShareOption(
        svgPath: AppAssets.facebook,
        name:    'فيسبوك',
        color:   const Color(0xFF1877F2),
        onTap:   _shareFacebook,
      ),
    ];
  }

  // ── Share actions ─────────────────────────────────────
  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _productLink));
    if (mounted) {
      Helpers.showSnackBar(context, '✅ تم نسخ رابط المنتج',
          );
    }
    _close();
  }

  Future<void> _shareWhatsApp() async {
    final url = 'https://wa.me/?text=${Uri.encodeComponent(_shareMessage)}';
    await _launch(url, 'واتساب');
  }

  Future<void> _shareTelegram() async {
    final url =
        'https://t.me/share/url?url=${Uri.encodeComponent(_productLink)}'
        '&text=${Uri.encodeComponent(_shareMessage)}';
    await _launch(url, 'تيليجرام');
  }

  Future<void> _shareInstagram() async {
    await Clipboard.setData(ClipboardData(text: _productLink));
    if (mounted) {
      Helpers.showSnackBar(
          context, '✅ تم نسخ الرابط، يمكنك لصقه في منشور إنستغرام',
        );
    }
    await _launch('instagram://user', 'إنستغرام');
  }

  Future<void> _shareFacebook() async {
    final encoded = Uri.encodeComponent(_productLink);
    final appUrl = 'fb://facewebmodal/f?href=$encoded';
    final webUrl =
        'https://www.facebook.com/sharer/sharer.php?u=$encoded'
        '&quote=${Uri.encodeComponent(widget.product.title)}';
    if (!await _launch(appUrl, 'فيسبوك', silent: true)) {
      await _launch(webUrl, 'فيسبوك');
    }
  }

  Future<bool> _launch(String url, String appName,
      {bool silent = false}) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _close();
      return true;
    }
    if (!silent && mounted) {
      Helpers.showSnackBar(context,
          '⚠️ لا يمكن فتح $appName. يرجى تثبيت التطبيق أولاً.',
          );
    }
    return false;
  }

  void _close() {
    if (mounted) Navigator.pop(context);
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Center(
                child: Text(
                  'مشاركة المنتج',
                  style: AppTextStyles.displaySmall(context)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: GestureDetector(
                  onTap: _close,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 20, color: AppColors.textPlaceholder),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ProductPreview(product: widget.product),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _options.length,
              itemBuilder: (_, i) =>
                  _ShareOptionTile(option: _options[i]),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Private models & widgets ──────────────────────────────────────────────────

class _ShareOption {
  final String       svgPath;
  final String       name;
  final Color        color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.svgPath,
    required this.name,
    required this.color,
    required this.onTap,
  });
}

class _ProductPreview extends StatelessWidget {
  final ProductModel product;
  const _ProductPreview({required this.product});

  String get _primaryImage {
    if (product.imageUrl.isNotEmpty) return product.imageUrl;
    return product.additionalImages.isNotEmpty
        ? product.additionalImages.first
        : '';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: FigmaDesignSystem.getResponsiveWidth(context) * 0.9,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.stroke.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _Thumbnail(imageUrl: _primaryImage),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: AppTextStyles.bodyLarge(context)
                              .copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${product.price} ${product.currency}',
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: product.paymentMethods.map((m) {
                          final isCash = m == PaymentMethod.cash;
                          final color = isCash
                              ? AppColors.primaryDark
                              : const Color(0xFFB41A75);
                          return Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              m.label,
                              style: AppTextStyles.bodySmall(context)
                                  .copyWith(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                      Row(
                        children: [
                          SvgPicture.asset(AppAssets.location,
                              width: 12,
                              height: 12,
                              colorFilter: const ColorFilter.mode(
                                  AppColors.textPlaceholder,
                                  BlendMode.srcIn)),
                          const SizedBox(width: 2),
                          Text(
                            product.location,
                            style: AppTextStyles.bodySmall(context)
                                .copyWith(
                                    color: AppColors.textPlaceholder,
                                    fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String imageUrl;
  const _Thumbnail({required this.imageUrl});

  Widget _fallback() => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: SvgPicture.asset(AppAssets.vendorCheck,
              width: 40,
              height: 40,
              colorFilter: const ColorFilter.mode(
                  AppColors.textPlaceholder, BlendMode.srcIn)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _fallback();

    if (imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          placeholder: (_, __) => _fallback(),
          errorWidget: (_, __, ___) => _fallback(),
        ),
      );
    }

    if (imageUrl.startsWith('/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(imageUrl),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback()),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final _ShareOption option;
  const _ShareOptionTile({required this.option});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: option.onTap,
      child: SizedBox(
        width: 75,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.stroke.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  option.svgPath,
                  width: 36,
                  height: 36,
                  errorBuilder: (_, __, ___) => Icon(
                    _fallbackIcon(option.name),
                    color: option.color,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              option.name,
              style: AppTextStyles.bodySmall(context)
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _fallbackIcon(String name) => switch (name) {
        'نسخ الرابط' => Icons.link,
        'واتساب'     => Icons.chat,
        'تيليجرام'   => Icons.telegram,
        'إنستغرام'   => Icons.photo_camera,
        'فيسبوك'     => Icons.facebook,
        _            => Icons.share,
      };
}
