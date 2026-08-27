import 'dart:convert';

import 'package:challenge_app/core/assets/app_assets.dart';
import 'package:challenge_app/features/challenges/domain/challenge.dart';
import 'package:flutter/services.dart';

class LocalChallengeRepository {
  LocalChallengeRepository({AssetBundle? assetBundle})
    : assetBundle = assetBundle ?? rootBundle;

  final AssetBundle assetBundle;

  Future<List<Challenge>> loadChallenges() async {
    final jsonString = await assetBundle.loadString(AppAssets.challenges);
    final jsonValue = jsonDecode(jsonString);

    if (jsonValue is! List<dynamic>) {
      throw const FormatException('Challenge data must be a JSON array.');
    }

    return List.unmodifiable(
      jsonValue.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Each challenge must be a JSON object.');
        }
        return Challenge.fromJson(item);
      }),
    );
  }
}
