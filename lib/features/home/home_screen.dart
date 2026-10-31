import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/countries.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/weshape_palette.dart';
import '../../core/widgets/language_menu.dart';
import '../../core/widgets/theme_switch.dart';
import '../../core/widgets/weshape_logo.dart';
import '../profile/profile_controller.dart';
import 'map/resource_map.dart';

/// The signed-in home: the header, and under it the resource map.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile!;
    final phone = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(profile: profile, phone: phone),
            Expanded(child: ResourceMap(countryCode: profile.country)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.phone});

  final UserProfile profile;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.t;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: phone ? 12 : 20, vertical: 10),
      color: p.surface,
      child: Row(
        children: [
          if (phone) const WeShapeMark(size: 36) else const WeShapeLogo(height: 40, withSlogan: false),
          const Spacer(),
          LanguageMenu(style: phone ? LanguageMenuStyle.flagOnly : LanguageMenuStyle.compact),
          const SizedBox(width: 8),
          const ThemeSwitch(),
          const SizedBox(width: 8),
          if (phone)
            IconButton(
              tooltip: t.signOut,
              onPressed: () => context.read<AuthController>().signOut(),
              icon: Icon(Icons.logout_rounded, size: 20, color: p.text),
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 12)),
              onPressed: () => context.read<AuthController>().signOut(),
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: Text(t.signOut, style: const TextStyle(fontSize: 13)),
            ),
          const SizedBox(width: 10),
          _AccountButton(profile: profile),
        ],
      ),
    );
  }
}

/// Initials with a green "online" dot; opens a card with the person's details.
class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: profile.displayName,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showDialog<void>(context: context, builder: (_) => _AccountDialog(profile: profile)),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: p.primaryGradient),
                alignment: Alignment.center,
                child: Text(
                  profile.initials,
                  style: TextStyle(color: p.onPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: p.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountDialog extends StatelessWidget {
  const _AccountDialog({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.t;
    final language = Localizations.localeOf(context).languageCode;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.displayName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: p.text)),
              const SizedBox(height: 2),
              Text(profile.email, style: TextStyle(fontSize: 13, color: p.muted)),
              if (profile.country != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${Country(profile.country!, '').flag}  ${Countries.nameOf(profile.country!, language)}',
                  style: TextStyle(fontSize: 14, color: p.text),
                ),
              ],
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  final auth = context.read<AuthController>();
                  Navigator.of(context).pop();
                  auth.signOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: Text(t.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
