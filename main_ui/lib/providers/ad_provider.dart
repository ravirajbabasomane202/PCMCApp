import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/models/ad_model.dart';
import 'package:main_ui/services/api_service.dart';

final adProvider = FutureProvider<List<Advertisement>>((ref) async {
  try {
    final ads = await ApiService.fetchAds();
    return ads.where((ad) => ad.isActive).toList();
  } catch (e) {
    print('Error fetching ads: $e');
    return []; // Graceful fallback
  }
});

final adNotifierProvider = StateNotifierProvider<AdNotifier, List<Advertisement>>((ref) {
  return AdNotifier(ref);
});

class AdNotifier extends StateNotifier<List<Advertisement>> {
  final Ref ref;
  AdNotifier(this.ref) : super([]);

  Future<void> fetchAds() async {
    try {
      state = await ref.read(adProvider.future);
    } catch (e) {
      state = [];
    }
  }

  // Add methods for create/update/delete if needed for ManageAdsScreen
}