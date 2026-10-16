import 'package:flutter/material.dart';
import 'package:food_app/core/widgets/subscription/subscription_manage_sheet.dart';
import 'package:food_app/data/models/subscription_models.dart';

/// Full-screen wrapper for deep links; hub uses [showSubscriptionManageSheet] directly.
class ManageSubscriptionScreen extends StatelessWidget {
  const ManageSubscriptionScreen({super.key, required this.subscription});

  final UserSubscriptionSummary subscription;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showSubscriptionManageSheet(context, subscription: subscription).then((_) {
        if (context.mounted) Navigator.pop(context);
      });
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
