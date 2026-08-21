import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'battle_api_service.dart';

class CloudFunctionsBattleService implements BattleApiService {
  final FirebaseFunctions _functions;

  CloudFunctionsBattleService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<BattleResponse> submitBattle(BattleRequest request) async {
    try {
      final callable = _functions.httpsCallable(
        'submitBattle',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 90),
        ),
      );

      final result = await callable.call(request.toJson());
      final data = result.data as Map<String, dynamic>;

      return BattleResponse.fromJson(data);
    } on FirebaseFunctionsException catch (e) {
      // Never fabricate a result. A failed call must surface as a failure so the
      // player retries, rather than being shown an invented victory or defeat
      // that also gets written into their war history.
      debugPrint('Cloud Functions error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}
