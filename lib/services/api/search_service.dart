import '../../core/constants/app_constants.dart';
import '../../core/models/search_results.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/extensions.dart';

/// `GET /api/search`
class SearchService {
  SearchService(this._client);

  final ApiClient _client;

  Future<SearchResults> search({
    required String query,
    SearchType type = SearchType.all,
    int limit = AppConstants.defaultSearchLimit,
    int offset = 0,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return SearchResults.empty;

    final data = await _client.getJson(
      ApiEndpoints.search,
      query: {
        'q': trimmed,
        'type': type.value,
        'limit': limit,
        'offset': offset,
      },
    );
    return SearchResults.fromJson(Json.mapOf(data), query: trimmed);
  }
}
