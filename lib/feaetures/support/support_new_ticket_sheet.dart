import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/provider/support_provider.dart';
import 'package:provider/provider.dart';

class SupportNewTicketSheet extends StatefulWidget {
  const SupportNewTicketSheet({super.key});

  @override
  State<SupportNewTicketSheet> createState() => _SupportNewTicketSheetState();
}

class _SupportNewTicketSheetState extends State<SupportNewTicketSheet> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = 'OTHER';
  bool _submitting = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    final ticket = await context.read<SupportProvider>().createTicket(
          subject: _subject.text.trim(),
          category: _category,
          message: _message.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ticket != null) {
      Navigator.pop(context, ticket);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, bottom + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('support.newTicket'.tr(), style: context.headingMedium),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _subject,
            decoration: InputDecoration(labelText: 'support.subject'.tr()),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(labelText: 'support.category'.tr()),
            items: [
              DropdownMenuItem(value: 'ORDER', child: Text('support.catOrder'.tr())),
              DropdownMenuItem(value: 'PAYMENT', child: Text('support.catPayment'.tr())),
              DropdownMenuItem(value: 'DELIVERY', child: Text('support.catDelivery'.tr())),
              DropdownMenuItem(value: 'ACCOUNT', child: Text('support.catAccount'.tr())),
              DropdownMenuItem(value: 'OTHER', child: Text('support.catOther'.tr())),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'OTHER'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _message,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(labelText: 'support.message'.tr()),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('support.submit'.tr()),
          ),
        ],
      ),
    );
  }
}
