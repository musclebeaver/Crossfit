import '../../core/api/api_client.dart';
import '../models/wod_model.dart';

class WodRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<WodModel>> getWods(String date, {int? boxId}) async {
    final response = await _apiClient.dio.get('/wods', queryParameters: {
      'date': date,
      if (boxId != null) 'boxId': boxId,
    });

    if (response.data['success'] == true) {
      final List data = response.data['data'];
      return data.map((json) => WodModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load WODs');
  }
}
