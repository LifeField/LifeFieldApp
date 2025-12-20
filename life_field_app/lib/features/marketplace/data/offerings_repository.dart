import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:riverpod/riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/entities/offering.dart';
import 'offerings_cache.dart';

final offeringsCacheProvider = Provider<OfferingsCache>((_) => OfferingsCache());

final offeringsRepositoryProvider = Provider<OfferingsRepository>((ref) {
  return OfferingsRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(offeringsCacheProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

class OfferingsRepository {
  OfferingsRepository({
    required this.dio,
    required this.cache,
    required this.logger,
  });

  final Dio dio;
  final OfferingsCache cache;
  final Logger logger;

  Future<List<Offering>> fetchOfferings({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await cache.read();
      if (cached.isNotEmpty) {
        return cached;
      }
    }
    try {
      final response = await dio.get<List<dynamic>>('/offerings');
      final payload = response.data ?? [];
      final offerings = payload.whereType<Map<String, dynamic>>().map(Offering.fromJson).toList();
      await cache.save(offerings);
      return offerings;
    } on DioException catch (e) {
      logger.w('Error fetching offerings: ${e.message}');
      throw mapDioError(e);
    } catch (e) {
      throw AppError(type: AppErrorType.unknown, message: e.toString());
    }
  }
}
