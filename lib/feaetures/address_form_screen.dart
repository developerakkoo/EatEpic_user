import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/data/models/app_user.dart';
import 'package:food_app/provider/auth_provider.dart';
import 'package:food_app/provider/location_provider.dart';
import 'package:provider/provider.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({
    super.key,
    this.existing,
    this.latitude,
    this.longitude,
    this.initialStreet = '',
    this.makeDefault = false,
  });

  final UserAddress? existing;
  final double? latitude;
  final double? longitude;
  final String initialStreet;
  final bool makeDefault;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _flatNo;
  late final TextEditingController _floor;
  late final TextEditingController _areaName;
  late final TextEditingController _address;
  late final TextEditingController _pincode;
  late String _label;
  late bool _isDefault;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _flatNo = TextEditingController(text: existing?.flatNo ?? '');
    _floor = TextEditingController(text: existing?.floor ?? '');
    _areaName = TextEditingController(text: existing?.areaName ?? '');
    _address = TextEditingController(
      text: existing?.addressLine.isNotEmpty == true
          ? existing!.addressLine
          : widget.initialStreet,
    );
    _pincode = TextEditingController(text: existing?.pincode ?? '');
    _label = existing?.label == 'Office' ? 'Office' : 'Home';
    _isDefault = existing?.isDefault ?? widget.makeDefault;
  }

  @override
  void dispose() {
    _flatNo.dispose();
    _floor.dispose();
    _areaName.dispose();
    _address.dispose();
    _pincode.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'addresses.required'.tr();
    }
    return null;
  }

  String? _pincodeValidator(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^\d{6}$').hasMatch(text)) {
      return 'addresses.pincodeInvalid'.tr();
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      final line = _previewLine();
      final lat = widget.existing?.latitude ?? widget.latitude;
      final lng = widget.existing?.longitude ?? widget.longitude;
      if (lat != null && lng != null) {
        await context.read<LocationProvider>().saveLocation(lat, lng, line);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    setState(() => _saving = true);
    final body = {
      'label': _label,
      'flatNo': _flatNo.text.trim(),
      'floor': _floor.text.trim(),
      'areaName': _areaName.text.trim(),
      'fullAddress': _address.text.trim(),
      'pincode': _pincode.text.trim(),
      'latitude': widget.existing?.latitude ?? widget.latitude,
      'longitude': widget.existing?.longitude ?? widget.longitude,
      'isDefault': _isDefault,
    };
    try {
      final saved = _editing
          ? await AppServices.instance.userRepository.updateAddress(widget.existing!.id, body)
          : await AppServices.instance.userRepository.addAddress(body);
      await auth.refreshProfile();
      if (!mounted) return;
      if (saved.isDefault && saved.latitude != null && saved.longitude != null) {
        await context.read<LocationProvider>().saveLocation(
              saved.latitude!,
              saved.longitude!,
              saved.displayLine,
            );
      }
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _previewLine() {
    return UserAddress(
      id: '',
      label: _label,
      flatNo: _flatNo.text.trim(),
      floor: _floor.text.trim(),
      areaName: _areaName.text.trim(),
      addressLine: _address.text.trim(),
      pincode: _pincode.text.trim(),
    ).displayLine;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing ? 'addresses.editTitle'.tr() : 'addresses.addTitle'.tr(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _label,
              decoration: InputDecoration(labelText: 'addresses.label'.tr()),
              items: [
                DropdownMenuItem(value: 'Home', child: Text('addresses.home'.tr())),
                DropdownMenuItem(value: 'Office', child: Text('addresses.office'.tr())),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _label = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _flatNo,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: 'addresses.flatNo'.tr()),
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _floor,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: 'addresses.floor'.tr()),
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _areaName,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: 'addresses.areaName'.tr()),
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _address,
              textInputAction: TextInputAction.next,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(labelText: 'addresses.address'.tr()),
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _pincode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              decoration: InputDecoration(labelText: 'addresses.pincode'.tr()),
              validator: _pincodeValidator,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('addresses.setDefault'.tr()),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('common.save'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<UserAddress?> promptCompleteAddress(BuildContext context, UserAddress address) async {
  if (address.isComplete) return address;
  final saved = await Navigator.push<UserAddress>(
    context,
    MaterialPageRoute(builder: (_) => AddressFormScreen(existing: address)),
  );
  return saved != null && saved.isComplete ? saved : null;
}
