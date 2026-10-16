import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/data/models/app_user.dart';
import 'package:food_app/feaetures/location_picker_screen.dart';
import 'package:food_app/provider/auth_provider.dart';
import 'package:food_app/provider/location_provider.dart';
import 'package:provider/provider.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _repo = AppServices.instance.userRepository;
  List<UserAddress> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _addresses = await _repo.getAddresses();
    } catch (_) {
      _addresses = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _setDefault(UserAddress address) async {
    await _repo.setDefaultAddress(address.id);
    await context.read<AuthProvider>().refreshProfile();
    final user = context.read<AuthProvider>().user;
    final def = user?.defaultAddress;
    if (def?.latitude != null && def?.longitude != null) {
      await context.read<LocationProvider>().saveLocation(
            def!.latitude!,
            def.longitude!,
            def.addressLine,
          );
    }
    await _load();
  }

  Future<void> _delete(UserAddress address) async {
    await _repo.deleteAddress(address.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('addresses.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const LocationPickerScreen(fromHome: false, fromCart: false),
                ),
              );
              await _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Text('addresses.empty'.tr(), style: context.bodyMedium),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final address = _addresses[index];
                    return Card(
                      child: ListTile(
                        title: Text(address.label, style: context.headingSmall),
                        subtitle: Text(address.addressLine, style: context.bodyMedium),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'default') _setDefault(address);
                            if (value == 'delete') _delete(address);
                          },
                          itemBuilder: (_) => [
                            if (!address.isDefault)
                              PopupMenuItem(
                                value: 'default',
                                child: Text('addresses.setDefault'.tr()),
                              ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('addresses.delete'.tr()),
                            ),
                          ],
                        ),
                        leading: address.isDefault
                            ? const Icon(Icons.star, color: AppColors.starColor)
                            : const Icon(Icons.location_on_outlined),
                      ),
                    );
                  },
                ),
    );
  }
}
