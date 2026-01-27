import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../common/core/utils/color_utils.dart';
import '../../common/core/utils/form_utils.dart';
import '../../common/core/utils/ui_utils.dart';
import '../view_model/settings_view_model.dart';
import 'edit_password_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  ElevatedButton createButton(String title, IconData icon, ButtonStyle style,
      VoidCallback? onPressedFct,
      {bool isLoading = false}) {
    return ElevatedButton(
      style: style,
      onPressed: isLoading ? null : onPressedFct,
      child: Align(
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(ColorUtils.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: ColorUtils.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: FormUtils.darkTextFormFieldStyle,
                  ),
                ],
              ),
      ),
    );
  }

  void navigateToScreen(BuildContext context, Widget widget) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: widget,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    final provider = ref.watch(settingsViewModelProvider.notifier);

    return Scaffold(
      body: Center(
        child: state.isLoading
            ? Center(child: UIUtils.loader)
            : Column(
                children: [
                  const SizedBox(height: 40),
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: createButton(
                          AppLocalizations.of(context)!.edit_profile,
                          Icons.person,
                          FormUtils.buttonStyle,
                          () =>
                              navigateToScreen(context, EditProfileScreen()))),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: createButton(
                        AppLocalizations.of(context)!.edit_password,
                        Icons.edit,
                        FormUtils.buttonStyle,
                        () => navigateToScreen(context, EditPasswordScreen())),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: createButton(
                        'Manual Backup',
                        Icons.cloud_upload,
                        FormUtils.buttonStyle,
                        () => provider.manualBackup(context),
                        isLoading: state.isBackupLoading,
                      )),
                  const SizedBox(height: 20),
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: createButton(
                        'Restore from Drive',
                        Icons.cloud_download,
                        FormUtils.buttonStyle,
                        () => provider.restoreBackup(context),
                        isLoading: state.isRestoreLoading,
                      )),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: createButton(
                          AppLocalizations.of(context)!.logout,
                          Icons.logout,
                          FormUtils.buttonStyle,
                          () => provider.logoutUser())),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: createButton(
                        AppLocalizations.of(context)!.delete_account,
                        Icons.delete,
                        FormUtils.createButtonStyle(ColorUtils.error),
                        () => provider.showDeleteAccountAlert(
                            context,
                            AppLocalizations.of(context)!.ask_account_removal,
                            AppLocalizations.of(context)!.delete,
                            AppLocalizations.of(context)!.cancel)),
                  ),
                ],
              ),
      ),
    );
  }
}
