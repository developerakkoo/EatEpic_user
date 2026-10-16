import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/widgets/hotel_card.dart';
import 'package:food_app/feaetures/hotel_details_screen.dart';
import 'package:food_app/modal/hotel_modal.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/provider/location_provider.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  bool _searching = false;
  List<HotelModel> _filteredHotels = [];
  final List<String> _recentSearches = [];
  static const int _maxRecentSearches = 6;
  static const List<String> _suggestions = [
    'Burgers',
    'Biryani',
    'North Indian',
    'Fast Food',
    'Mughlai',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _query = _searchController.text.trim();
          _filterHotels();
        });
      }
    });
  }

  Future<void> _filterHotels() async {
    final q = _query.trim();
    if (q.isEmpty) {
      setState(() => _filteredHotels = []);
      return;
    }
    setState(() => _searching = true);
    final loc = context.read<LocationProvider>();
    try {
      final list = await AppServices.instance.kitchenRepository.getNearbyKitchens(
        latitude: loc.lat,
        longitude: loc.lng,
        search: q,
        forceRefresh: true,
      );
      if (mounted) {
        setState(() {
          _filteredHotels = list;
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _filteredHotels = [];
          _searching = false;
        });
      }
    }
  }

  void _runSearch(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    setState(() {
      _query = query;
      _filterHotels();
      if (query.isNotEmpty && !_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > _maxRecentSearches) {
          _recentSearches.removeLast();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('search.title'.tr()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'search.hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _runSearch(''),
                      )
                    : null,
                filled: true,
                fillColor: context.colors.surfaceGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              onSubmitted: (v) => _runSearch(v.trim()),
            ),
          ),
        ),
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) {
      return _buildInitialState();
    }
    if (_filteredHotels.isEmpty) {
      return _buildNoResults();
    }
    return _buildResults();
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_suggestions.isNotEmpty) ...[
            Text(
              'search.suggestions'.tr(),
              style: context.headingSmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _suggestions.map((s) {
                return ActionChip(
                  label: Text(s),
                  onPressed: () => _runSearch(s),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
          if (_recentSearches.isNotEmpty) ...[
            Text(
              'search.recentSearches'.tr(),
              style: context.headingSmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            ..._recentSearches.map((q) => ListTile(
                  leading: const Icon(Icons.history, size: 20),
                  title: Text(q),
                  onTap: () => _runSearch(q),
                  contentPadding: EdgeInsets.zero,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: context.colors.textHint),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'search.noResults'.tr(),
              style: context.headingMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'search.tryDifferent'.tr(),
              style: context.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: _filteredHotels.length,
      itemBuilder: (context, index) {
        final hotel = _filteredHotels[index];
        return HotelCard(
          hotel: hotel,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HotelDetailScreen(hotel: hotel),
            ),
          ),
        );
      },
    );
  }
}
