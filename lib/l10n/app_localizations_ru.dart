// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Tanishuv';

  @override
  String get settings => 'Настройки';

  @override
  String get account => 'Аккаунт';

  @override
  String get inviteFriends => 'Пригласить друзей';

  @override
  String get inviteFriendsDesc => 'Получайте бонусные монеты за рефералов';

  @override
  String get language => 'Язык';

  @override
  String get aboutApp => 'О Tanishuv';

  @override
  String get logout => 'Выйти';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get close => 'Закрыть';

  @override
  String get yourInviteCode => 'Ваш код приглашения:';

  @override
  String get yourCoins => 'Ваши монеты:';

  @override
  String get inviteMessage =>
      'Поделитесь этим кодом! Когда друзья регистрируются, вы получаете 100 монет!';
}
