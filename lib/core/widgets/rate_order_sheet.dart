import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/provider/hotel_provider.dart';
import 'package:provider/provider.dart';

class SubmittedOrderRating {
  const SubmittedOrderRating({
    required this.partnerRating,
    this.deliveryRating,
    required this.review,
  });

  final int partnerRating;
  final int? deliveryRating;
  final String review;
}

Future<SubmittedOrderRating?> showRateOrderSheet(
  BuildContext context, {
  required String orderId,
  required String restaurantName,
  required bool hasDeliveryAgent,
  int? initialPartnerRating,
  int? initialDeliveryRating,
  String initialReview = '',
}) {
  return showModalBottomSheet<SubmittedOrderRating>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _RateOrderSheet(
          orderId: orderId,
          restaurantName: restaurantName,
          hasDeliveryAgent: hasDeliveryAgent,
          initialPartnerRating: initialPartnerRating,
          initialDeliveryRating: initialDeliveryRating,
          initialReview: initialReview,
        ),
      );
    },
  );
}

class _RateOrderSheet extends StatefulWidget {
  const _RateOrderSheet({
    required this.orderId,
    required this.restaurantName,
    required this.hasDeliveryAgent,
    this.initialPartnerRating,
    this.initialDeliveryRating,
    this.initialReview = '',
  });

  final String orderId;
  final String restaurantName;
  final bool hasDeliveryAgent;
  final int? initialPartnerRating;
  final int? initialDeliveryRating;
  final String initialReview;

  @override
  State<_RateOrderSheet> createState() => _RateOrderSheetState();
}

class _RateOrderSheetState extends State<_RateOrderSheet> {
  late int _partnerRating = widget.initialPartnerRating ?? 0;
  late int _deliveryRating = widget.initialDeliveryRating ?? 0;
  late final TextEditingController _comment = TextEditingController(
    text: widget.initialReview,
  );
  bool _submitting = false;

  bool get _editing =>
      widget.initialPartnerRating != null && widget.initialPartnerRating! >= 1;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_partnerRating < 1 || _submitting) return;
    setState(() => _submitting = true);
    final review = _comment.text.trim();
    final deliveryRating =
        widget.hasDeliveryAgent && _deliveryRating >= 1 ? _deliveryRating : null;
    try {
      final result = await AppServices.instance.orderRepository.rateOrder(
        orderId: widget.orderId,
        partnerRating: _partnerRating,
        deliveryRating: deliveryRating,
        review: review,
      );
      if (!mounted) return;
      final kitchenId = result.kitchenId;
      if (kitchenId != null && kitchenId.isNotEmpty && result.totalReviews > 0) {
        context.read<HotelProvider>().applyKitchenRating(
              kitchenId: kitchenId,
              averageRating: result.averageRating,
              totalReviews: result.totalReviews,
            );
      }
      await AppServices.instance.kitchenRepository.invalidateNearbyCache();
      if (!mounted) return;
      Navigator.pop(
        context,
        SubmittedOrderRating(
          partnerRating: _partnerRating,
          deliveryRating: deliveryRating ?? widget.initialDeliveryRating,
          review: review,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('rateOrder.failed'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.restaurantName.trim().isEmpty
        ? 'orders.restaurant'.tr()
        : widget.restaurantName.trim();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _editing
                  ? 'rateOrder.editTitle'.tr()
                  : 'rateOrder.title'.tr(namedArgs: {'name': name}),
              style: context.headingMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'rateOrder.restaurant'.tr(),
              style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            _stars(
              value: _partnerRating,
              onChanged: (value) => setState(() => _partnerRating = value),
            ),
            if (widget.hasDeliveryAgent) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'rateOrder.delivery'.tr(),
                style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              _stars(
                value: _deliveryRating,
                onChanged: (value) => setState(() => _deliveryRating = value),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _comment,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'rateOrder.commentHint'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _partnerRating < 1 || _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(_editing ? 'rateOrder.update'.tr() : 'rateOrder.submit'.tr()),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton(
                onPressed: _submitting ? null : () => Navigator.pop(context),
                child: Text('rateOrder.later'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stars({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: List.generate(5, (index) {
        final filled = index < value;
        return IconButton(
          onPressed: _submitting ? null : () => onChanged(index + 1),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? AppColors.starColor : context.colors.textHint,
          ),
        );
      }),
    );
  }
}
