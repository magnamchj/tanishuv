// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Tanishuv';

  @override
  String get settings => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get inviteFriends => 'Invite Friends';

  @override
  String get inviteFriendsDesc => 'Get bonus coins for referrals';

  @override
  String get language => 'Language';

  @override
  String get aboutApp => 'About Tanishuv';

  @override
  String get logout => 'Logout';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get close => 'Close';

  @override
  String get yourInviteCode => 'Your Invite Code:';

  @override
  String get yourCoins => 'Your Coins:';

  @override
  String get inviteMessage =>
      'Share this code! When friends use it to register, you earn 100 bonus coins!';
}
