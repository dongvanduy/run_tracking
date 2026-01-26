import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../domain/entities/user.dart';
import '../../../l10n/app_localizations.dart';
import '../../common/core/utils/color_utils.dart';
import '../../common/core/utils/user_utils.dart';

class SearchWidget extends HookConsumerWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final Future<List<User>> Function(String) onSearchChanged;

  const SearchWidget({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: ColorUtils.white,
      title: TypeAheadField<User>(
        // 1. Truyền controller trực tiếp vào TypeAheadField
        controller: searchController,

        // 2. Sử dụng 'builder' thay cho 'textFieldConfiguration'
        builder: (context, controller, focusNode) {
          return TextField(
            controller: controller, // Sử dụng controller từ builder (chính là searchController)
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: '${AppLocalizations.of(context)!.search}...',
              border: InputBorder.none,
              suffixIconColor: ColorUtils.main,
              suffixIcon: const Icon(Icons.search),
            ),
          );
        },

        suggestionsCallback: (String query) async {
          if (query.isNotEmpty) {
            return await onSearchChanged(query);
          }
          return [];
        },

        itemBuilder: (BuildContext context, User suggestion) {
          return ListTile(
            title: Text(
              UserUtils.getNameOrUsername(suggestion),
            ),
          );
        },

        // 3. Đổi tên 'onSuggestionSelected' -> 'onSelected'
        onSelected: (User suggestion) => UserUtils.goToProfile(suggestion),

        // 4. Đổi tên 'noItemsFoundBuilder' -> 'emptyBuilder'
        emptyBuilder: (context) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(AppLocalizations.of(context)!.no_data),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}