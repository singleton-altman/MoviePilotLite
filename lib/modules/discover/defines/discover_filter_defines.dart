class DiscoverFilterOption {
  const DiscoverFilterOption({required this.label, required this.value});

  final String label;
  final String value;
}

class DiscoverFilterDefines {
  static const List<DiscoverFilterOption> typeOptions = [
    DiscoverFilterOption(label: '电影', value: '电影'),
    DiscoverFilterOption(label: '电视剧', value: '电视剧'),
  ];

  static const List<DiscoverFilterOption> tmdbMovieSortOptions = [
    DiscoverFilterOption(label: '热度降序', value: 'popularity.desc'),
    DiscoverFilterOption(label: '热度升序', value: 'popularity.asc'),
    DiscoverFilterOption(label: '上映日期降序', value: 'release_date.desc'),
    DiscoverFilterOption(label: '上映日期升序', value: 'release_date.asc'),
    DiscoverFilterOption(label: '评分降序', value: 'vote_average.desc'),
    DiscoverFilterOption(label: '评分升序', value: 'vote_average.asc'),
  ];

  static const List<DiscoverFilterOption> tmdbTvSortOptions = [
    DiscoverFilterOption(label: '热度降序', value: 'popularity.desc'),
    DiscoverFilterOption(label: '热度升序', value: 'popularity.asc'),
    DiscoverFilterOption(label: '首播日期降序', value: 'release_date.desc'),
    DiscoverFilterOption(label: '首播日期升序', value: 'release_date.asc'),
    DiscoverFilterOption(label: '评分降序', value: 'vote_average.desc'),
    DiscoverFilterOption(label: '评分升序', value: 'vote_average.asc'),
  ];

  static const Map<String, String> tmdbMovieSortLabels = {
    'popularity.desc': '热度降序',
    'popularity.asc': '热度升序',
    'release_date.desc': '上映日期降序',
    'release_date.asc': '上映日期升序',
    'vote_average.desc': '评分降序',
    'vote_average.asc': '评分升序',
  };

  static const Map<String, String> tmdbTvSortLabels = {
    'popularity.desc': '热度降序',
    'popularity.asc': '热度升序',
    'release_date.desc': '首播日期降序',
    'release_date.asc': '首播日期升序',
    'vote_average.desc': '评分降序',
    'vote_average.asc': '评分升序',
  };

  static const List<DiscoverFilterOption> tmdbMovieGenreOptions = [
    DiscoverFilterOption(label: '冒险', value: '12'),
    DiscoverFilterOption(label: '奇幻', value: '14'),
    DiscoverFilterOption(label: '动画', value: '16'),
    DiscoverFilterOption(label: '剧情', value: '18'),
    DiscoverFilterOption(label: '恐怖', value: '27'),
    DiscoverFilterOption(label: '动作', value: '28'),
    DiscoverFilterOption(label: '喜剧', value: '35'),
    DiscoverFilterOption(label: '历史', value: '36'),
    DiscoverFilterOption(label: '西部', value: '37'),
    DiscoverFilterOption(label: '惊悚', value: '53'),
    DiscoverFilterOption(label: '犯罪', value: '80'),
    DiscoverFilterOption(label: '纪录片', value: '99'),
    DiscoverFilterOption(label: '科幻', value: '878'),
    DiscoverFilterOption(label: '悬疑', value: '9648'),
    DiscoverFilterOption(label: '音乐', value: '10402'),
    DiscoverFilterOption(label: '爱情', value: '10749'),
    DiscoverFilterOption(label: '家庭', value: '10751'),
    DiscoverFilterOption(label: '战争', value: '10752'),
    DiscoverFilterOption(label: '电视电影', value: '10770'),
  ];

  static const List<DiscoverFilterOption> tmdbTvGenreOptions = [
    DiscoverFilterOption(label: '动画', value: '16'),
    DiscoverFilterOption(label: '剧情', value: '18'),
    DiscoverFilterOption(label: '喜剧', value: '35'),
    DiscoverFilterOption(label: '西部', value: '37'),
    DiscoverFilterOption(label: '犯罪', value: '80'),
    DiscoverFilterOption(label: '纪录片', value: '99'),
    DiscoverFilterOption(label: '悬疑', value: '9648'),
    DiscoverFilterOption(label: '家庭', value: '10751'),
    DiscoverFilterOption(label: '动作冒险', value: '10759'),
    DiscoverFilterOption(label: '儿童', value: '10762'),
    DiscoverFilterOption(label: '新闻', value: '10763'),
    DiscoverFilterOption(label: '真人秀', value: '10764'),
    DiscoverFilterOption(label: '科幻奇幻', value: '10765'),
    DiscoverFilterOption(label: '肥皂剧', value: '10766'),
    DiscoverFilterOption(label: '战争政治', value: '10768'),
  ];

  static const List<DiscoverFilterOption> tmdbLanguageOptions = [
    DiscoverFilterOption(label: '中文', value: 'zh'),
    DiscoverFilterOption(label: '英语', value: 'en'),
    DiscoverFilterOption(label: '日语', value: 'ja'),
    DiscoverFilterOption(label: '韩语', value: 'ko'),
    DiscoverFilterOption(label: '法语', value: 'fr'),
    DiscoverFilterOption(label: '德语', value: 'de'),
    DiscoverFilterOption(label: '西班牙语', value: 'es'),
    DiscoverFilterOption(label: '意大利语', value: 'it'),
    DiscoverFilterOption(label: '俄语', value: 'ru'),
    DiscoverFilterOption(label: '葡萄牙语', value: 'pt'),
    DiscoverFilterOption(label: '阿拉伯语', value: 'ar'),
    DiscoverFilterOption(label: '印地语', value: 'hi'),
    DiscoverFilterOption(label: '泰语', value: 'th'),
  ];

  static const List<DiscoverFilterOption> ratingOptions = [
    DiscoverFilterOption(label: '不限评分', value: '0'),
    DiscoverFilterOption(label: '6分+', value: '6'),
    DiscoverFilterOption(label: '7分+', value: '7'),
    DiscoverFilterOption(label: '8分+', value: '8'),
  ];

  static const List<DiscoverFilterOption> doubanSortOptions = [
    DiscoverFilterOption(label: '综合排序', value: 'U'),
    DiscoverFilterOption(label: '首播时间', value: 'R'),
    DiscoverFilterOption(label: '近期热度', value: 'T'),
    DiscoverFilterOption(label: '高分优先', value: 'S'),
  ];

  static const Map<String, String> doubanSortLabels = {
    'U': '综合排序',
    'R': '首播时间',
    'T': '近期热度',
    'S': '高分优先',
    'comprehensive': '综合排序',
    'release_date.desc': '首播时间',
    'popularity.desc': '近期热度',
    'vote_average.desc': '高分优先',
  };

  static const List<DiscoverFilterOption> doubanGenreOptions = [
    DiscoverFilterOption(label: '喜剧', value: '喜剧'),
    DiscoverFilterOption(label: '爱情', value: '爱情'),
    DiscoverFilterOption(label: '动作', value: '动作'),
    DiscoverFilterOption(label: '科幻', value: '科幻'),
    DiscoverFilterOption(label: '动画', value: '动画'),
    DiscoverFilterOption(label: '悬疑', value: '悬疑'),
    DiscoverFilterOption(label: '犯罪', value: '犯罪'),
    DiscoverFilterOption(label: '惊悚', value: '惊悚'),
    DiscoverFilterOption(label: '冒险', value: '冒险'),
    DiscoverFilterOption(label: '音乐', value: '音乐'),
    DiscoverFilterOption(label: '历史', value: '历史'),
    DiscoverFilterOption(label: '奇幻', value: '奇幻'),
    DiscoverFilterOption(label: '恐怖', value: '恐怖'),
    DiscoverFilterOption(label: '战争', value: '战争'),
    DiscoverFilterOption(label: '传记', value: '传记'),
    DiscoverFilterOption(label: '歌舞', value: '歌舞'),
    DiscoverFilterOption(label: '武侠', value: '武侠'),
    DiscoverFilterOption(label: '情色', value: '情色'),
    DiscoverFilterOption(label: '灾难', value: '灾难'),
    DiscoverFilterOption(label: '西部', value: '西部'),
    DiscoverFilterOption(label: '纪录片', value: '纪录片'),
  ];

  static const List<DiscoverFilterOption> regionOptions = [
    DiscoverFilterOption(label: '华语', value: 'CN,TW,HK'),
    DiscoverFilterOption(label: '欧美', value: 'US,FR,GB,DE,ES,IT,NL,PT,RU,UK'),
    DiscoverFilterOption(label: '韩国', value: 'KR'),
    DiscoverFilterOption(label: '日本', value: 'JP'),
    DiscoverFilterOption(label: '中国大陆', value: 'CN'),
    DiscoverFilterOption(label: '美国', value: 'US'),
    DiscoverFilterOption(label: '中国香港', value: 'HK'),
    DiscoverFilterOption(label: '中国台湾', value: 'TW'),
    DiscoverFilterOption(label: '英国', value: 'GB'),
    DiscoverFilterOption(label: '法国', value: 'FR'),
    DiscoverFilterOption(label: '德国', value: 'DE'),
    DiscoverFilterOption(label: '意大利', value: 'IT'),
    DiscoverFilterOption(label: '西班牙', value: 'ES'),
    DiscoverFilterOption(label: '印度', value: 'IN'),
    DiscoverFilterOption(label: '泰国', value: 'TH'),
    DiscoverFilterOption(label: '俄罗斯', value: 'RU'),
    DiscoverFilterOption(label: '加拿大', value: 'CA'),
    DiscoverFilterOption(label: '澳大利亚', value: 'AU'),
  ];

  static const List<DiscoverFilterOption> decadeOptions = [
    DiscoverFilterOption(label: '2021', value: '2021'),
    DiscoverFilterOption(label: '2022', value: '2022'),
    DiscoverFilterOption(label: '2023', value: '2023'),
    DiscoverFilterOption(label: '2024', value: '2024'),
    DiscoverFilterOption(label: '2025', value: '2025'),
    DiscoverFilterOption(label: '2026', value: '2026'),
    DiscoverFilterOption(label: '2020年代', value: '2020-2029'),
    DiscoverFilterOption(label: '2010年代', value: '2010-2019'),
    DiscoverFilterOption(label: '2000年代', value: '2000-2009'),
    DiscoverFilterOption(label: '90年代', value: '1990-1999'),
    DiscoverFilterOption(label: '80年代', value: '1980-1989'),
    DiscoverFilterOption(label: '70年代', value: '1970-1979'),
    DiscoverFilterOption(label: '60年代', value: '1960-1969'),
  ];

  static const List<DiscoverFilterOption> bangumiCategoryOptions = [
    DiscoverFilterOption(label: '其他', value: '其他'),
    DiscoverFilterOption(label: 'TV', value: 'TV'),
    DiscoverFilterOption(label: 'OVA', value: 'OVA'),
    DiscoverFilterOption(label: 'Movie', value: 'Movie'),
    DiscoverFilterOption(label: 'WEB', value: 'WEB'),
  ];

  static const List<DiscoverFilterOption> bangumiSortOptions = [
    DiscoverFilterOption(label: '排名', value: 'rank'),
    DiscoverFilterOption(label: '日期', value: 'date'),
  ];

  static const Map<String, String> bangumiSortLabels = {
    'rank': '排名',
    'date': '日期',
  };

  static const List<DiscoverFilterOption> bangumiYearOptions = [
    DiscoverFilterOption(label: '2026', value: '2026'),
    DiscoverFilterOption(label: '2025', value: '2025'),
    DiscoverFilterOption(label: '2024', value: '2024'),
    DiscoverFilterOption(label: '2023', value: '2023'),
    DiscoverFilterOption(label: '2022', value: '2022'),
    DiscoverFilterOption(label: '2021', value: '2021'),
    DiscoverFilterOption(label: '2020', value: '2020'),
    DiscoverFilterOption(label: '2019', value: '2019'),
    DiscoverFilterOption(label: '2018', value: '2018'),
    DiscoverFilterOption(label: '2017', value: '2017'),
  ];

  static const List<DiscoverFilterOption> anilistSortOptions = [
    DiscoverFilterOption(label: '热度', value: 'POPULARITY_DESC'),
    DiscoverFilterOption(label: '趋势', value: 'TRENDING_DESC'),
    DiscoverFilterOption(label: '评分', value: 'SCORE_DESC'),
    DiscoverFilterOption(label: '收藏', value: 'FAVOURITES_DESC'),
    DiscoverFilterOption(label: '开播时间', value: 'START_DATE_DESC'),
    DiscoverFilterOption(label: '更新时间', value: 'UPDATED_AT_DESC'),
  ];

  static const Map<String, String> anilistSortLabels = {
    'POPULARITY_DESC': '热度',
    'TRENDING_DESC': '趋势',
    'SCORE_DESC': '评分',
    'FAVOURITES_DESC': '收藏',
    'START_DATE_DESC': '开播时间',
    'UPDATED_AT_DESC': '更新时间',
  };

  static const List<DiscoverFilterOption> anilistFormatOptions = [
    DiscoverFilterOption(label: 'TV', value: 'TV'),
    DiscoverFilterOption(label: 'TV Short', value: 'TV_SHORT'),
    DiscoverFilterOption(label: '剧场版', value: 'MOVIE'),
    DiscoverFilterOption(label: '特别篇', value: 'SPECIAL'),
    DiscoverFilterOption(label: 'OVA', value: 'OVA'),
    DiscoverFilterOption(label: 'ONA', value: 'ONA'),
    DiscoverFilterOption(label: '音乐', value: 'MUSIC'),
  ];

  static const List<DiscoverFilterOption> anilistSeasonOptions = [
    DiscoverFilterOption(label: '冬', value: 'WINTER'),
    DiscoverFilterOption(label: '春', value: 'SPRING'),
    DiscoverFilterOption(label: '夏', value: 'SUMMER'),
    DiscoverFilterOption(label: '秋', value: 'FALL'),
  ];

  static const List<DiscoverFilterOption> anilistStatusOptions = [
    DiscoverFilterOption(label: '已完结', value: 'FINISHED'),
    DiscoverFilterOption(label: '放送中', value: 'RELEASING'),
    DiscoverFilterOption(label: '未放送', value: 'NOT_YET_RELEASED'),
    DiscoverFilterOption(label: '已取消', value: 'CANCELLED'),
    DiscoverFilterOption(label: '休刊', value: 'HIATUS'),
  ];

  static const List<DiscoverFilterOption> anilistCountryOptions = [
    DiscoverFilterOption(label: '日本', value: 'JP'),
    DiscoverFilterOption(label: '中国', value: 'CN'),
    DiscoverFilterOption(label: '韩国', value: 'KR'),
    DiscoverFilterOption(label: '台湾', value: 'TW'),
  ];

  static const List<DiscoverFilterOption> anilistGenreOptions = [
    DiscoverFilterOption(label: '动作', value: 'Action'),
    DiscoverFilterOption(label: '冒险', value: 'Adventure'),
    DiscoverFilterOption(label: '喜剧', value: 'Comedy'),
    DiscoverFilterOption(label: '剧情', value: 'Drama'),
    DiscoverFilterOption(label: 'Ecchi', value: 'Ecchi'),
    DiscoverFilterOption(label: '奇幻', value: 'Fantasy'),
    DiscoverFilterOption(label: '恐怖', value: 'Horror'),
    DiscoverFilterOption(label: '魔法少女', value: 'Mahou Shoujo'),
    DiscoverFilterOption(label: '机甲', value: 'Mecha'),
    DiscoverFilterOption(label: '音乐', value: 'Music'),
    DiscoverFilterOption(label: '悬疑', value: 'Mystery'),
    DiscoverFilterOption(label: '心理', value: 'Psychological'),
    DiscoverFilterOption(label: '恋爱', value: 'Romance'),
    DiscoverFilterOption(label: '科幻', value: 'Sci-Fi'),
    DiscoverFilterOption(label: '日常', value: 'Slice of Life'),
    DiscoverFilterOption(label: '运动', value: 'Sports'),
    DiscoverFilterOption(label: '超自然', value: 'Supernatural'),
    DiscoverFilterOption(label: '惊悚', value: 'Thriller'),
  ];

  static const List<DiscoverFilterOption> anilistSeasonYearOptions = [
    DiscoverFilterOption(label: '2026', value: '2026'),
    DiscoverFilterOption(label: '2025', value: '2025'),
    DiscoverFilterOption(label: '2024', value: '2024'),
    DiscoverFilterOption(label: '2023', value: '2023'),
    DiscoverFilterOption(label: '2022', value: '2022'),
    DiscoverFilterOption(label: '2021', value: '2021'),
    DiscoverFilterOption(label: '2020', value: '2020'),
    DiscoverFilterOption(label: '2019', value: '2019'),
    DiscoverFilterOption(label: '2018', value: '2018'),
  ];
}
