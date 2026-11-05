import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';
import 'package:moviepilot_mobile/modules/search/models/person_detail.dart';

class PersonDetailController extends GetxController {
  PersonDetailController({required this.personId, required this.source});

  final int personId;
  final String source;
  final _apiClient = Get.find<ApiClient>();

  final isLoading = true.obs;
  final error = RxnString();

  final RxnString name = RxnString();
  final RxnString avatarUrl = RxnString();
  final RxnString biography = RxnString();
  final RxnString sourceLabel = RxnString();
  final RxnInt gender = RxnInt();
  final RxList<String> alsoKnownAs = <String>[].obs;

  final RxList<RecommendApiItem> works = <RecommendApiItem>[].obs;
  final RxBool isLoadingMoreWorks = false.obs;
  final RxBool worksHasMore = false.obs;
  final RxInt worksPage = 1.obs;

  Iterable<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    return const [];
  }

  @override
  void onReady() {
    super.onReady();
    _fetch();
  }

  Future<void> _fetch() async {
    if (personId <= 0) {
      error.value = '演员ID无效';
      isLoading.value = false;
      return;
    }

    try {
      isLoading.value = true;
      error.value = null;

      final detailResp = await _apiClient.get<dynamic>(
        '/api/v1/${source}/person/$personId',
        timeout: 60,
      );
      final detailStatus = detailResp.statusCode ?? 0;
      if (detailStatus >= 400) {
        throw Exception('获取演员详情失败 (HTTP $detailStatus)');
      }

      final detailJson = detailResp.data;
      if (detailJson is! Map<String, dynamic>) {
        throw Exception('演员详情格式错误');
      }

      final detail = PersonDetail.fromJson(detailJson);
      name.value = detail.name;
      biography.value = detail.biography;
      gender.value = detail.gender;
      sourceLabel.value = detail.source;

      final avatar = detail.avatar;
      final profilePath = detail.profilePath;
      final avatarRaw = (avatar != null && avatar.isNotEmpty)
          ? avatar
          : profilePath;
      if (avatarRaw != null && avatarRaw.isNotEmpty) {
        if (avatar != null && avatar.isNotEmpty) {
          avatarUrl.value = ImageUtil.convertCacheImageUrl(avatarRaw);
        } else {
          avatarUrl.value = ImageUtil.convertMediaSeasonImageUrl(
            avatarRaw,
            baseUrl: 'https://image.tmdb.org/t/p/w300/',
          );
        }
      }

      alsoKnownAs.assignAll(detail.alsoKnownAs ?? const []);

      await _fetchWorks(page: 1, append: false);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreWorks() async {
    if (isLoadingMoreWorks.value || !worksHasMore.value) return;
    await _fetchWorks(page: worksPage.value + 1, append: true);
  }

  Future<void> _fetchWorks({required int page, required bool append}) async {
    if (append) isLoadingMoreWorks.value = true;
    try {
      final worksResp = await _apiClient.get<dynamic>(
        '/api/v1/$source/person/credits/$personId',
        timeout: 120,
        queryParameters: {'page': page},
      );
      final worksStatus = worksResp.statusCode ?? 0;
      if (worksStatus >= 400) {
        throw Exception('获取作品列表失败 (HTTP $worksStatus)');
      }

      final rawWorks = worksResp.data;
      final parsedWorks = _extractList(rawWorks)
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => RecommendApiItem.fromJson(normalizeMediaJson(item)),
          )
          .toList();
      if (append) {
        works.addAll(parsedWorks);
      } else {
        works.assignAll(parsedWorks);
      }
      worksPage.value = page;
      worksHasMore.value = parsedWorks.isNotEmpty;
    } finally {
      if (append) isLoadingMoreWorks.value = false;
    }
  }
}
