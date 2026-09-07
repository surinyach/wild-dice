import 'package:flutter/foundation.dart';

class MainMenuIdentityController extends ChangeNotifier {
  factory MainMenuIdentityController({
    String nickname = '',
    String avatarId = 'avatar_01',
  }) => MainMenuIdentityController._(nickname, avatarId);

  MainMenuIdentityController._(this._nickname, this._avatarId);

  String _nickname;
  String _avatarId;

  String get nickname => _nickname.trim();
  String get avatarId => _avatarId;
  bool get isValid => nickname.isNotEmpty && avatarId.isNotEmpty;

  void updateNickname(String value) {
    if (_nickname == value) return;
    _nickname = value;
    notifyListeners();
  }

  void updateAvatar(String value) {
    if (_avatarId == value) return;
    _avatarId = value;
    notifyListeners();
  }
}
