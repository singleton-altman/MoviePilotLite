# API 一致性审计（对照 api.movie-pilot.org Swagger）

> 审计日期：2026-10-15。规范来源：https://api.movie-pilot.org/openapi.json（FastAPI OpenAPI，共 337 个路径：GET 253 / POST 94 / PUT 10 / DELETE 29，含 /api/v3/* 段、MCP、LLM 等当前主线端点）。
> 审计范围：lib/ 下全部 Dart 代码（third_party/lanplayer_player 直连 Emby/Jellyfin 媒体服务器，不走 MoviePilot API，未纳入）。
> 方法：静态提取所有（HTTP 方法, 路径）调用与路径字面量，与规范做模板匹配（路径参数通配）；对内联 query 参数字面量做参数名比对；对规范必填参数做反向漏传检查。

## 一、初判疑点与实机更正

初轮仅对照 Swagger 得出 5 个疑点；经 v2 分支与 v3.1.5 tag 源码实机复核后更正如下（详见第五节版本矩阵）：

1. ~~GET /api/v1/media/source 探测端点不存在~~ → **更正：v3.1.5 实机存在（media.py），Swagger 漏收录**。原探测设计正确，未改动（曾误改为 discover/source 并已回滚——该接口 v2 也存在，会造成 V2 误判）。
2. GET /api/v1/system/llm-models → **确认：v2/v3.1.5/Swagger 三方均无此路径**。已改为主路径 /api/v1/llm/models + 404 回退旧路径。
3. ~~POST /api/v1/storage/manage 不存在~~ → **更正：v3.1.5 实机存在且已取代 usage**，Swagger 漏收录。原 isV3 双分支设计正确，保留（曾误统一到 usage 并已回滚——那会让 v3.1.5 存储卡片消失）。
4. POST /api/v1/mediaserver/seasoninfo → 确认不存在于任何版本；调用方为零（死代码），已删除。
5. 健康检查兜底的五个路径（system/health 及变体）→ 确认任何版本均无；已替换为 ping/versions。

## 二、已核实合规（曾疑似、经查无误）

- DELETE /api/v1/subscribe/history/{id}：与 GET .../{mtype} 为同模板双语义，规范两者皆存在，合规。
- 人物详情 /api/v1/{source}/person/{person_id} 与 credits：source ∈ douban/tmdb/bangumi/anilist，四个均在规范中。
- TMDB 季详情 GET /api/v1/tmdb/{tmdbid}/{season}：存在，合规。
- 动态表单保存 PUT /api/v1/plugin/{plugin_id}：规范恰好定义为 PUT（无 POST），本地用 put，合规。
- 发现页端点映射 tmdb_tvs / tmdb_movies / douban_tvs / douban_movies / bangumi 与 /api/v1/anilist/discover：全部存在。
- 整理历史删除 DELETE /api/v1/history/transfer：路径、query（deletesrc/deletedest）、requestBody（TransferHistory）均与规范一致。
- 图片代理 /api/v1/system/img/{proxy}、/api/v1/system/cache/image：合规。
- runscheduler 的 jobid、mediaserver library/latest/playing 的 server 必填参数：以 URL 查询串形式传参，未漏传。
- 内联 query 参数名比对：20 处可静态核对的调用，参数名全部在规范定义内，无瞎编参数。
- 连接探活 /{base}/api/v1/system/ping：规范存在 /api/v1/system/ping，合规。

## 三、覆盖率（方向性统计）

- 规范 337 个路径，App 模板命中约 100 个（约 30%）。动态拼接与变量传参可能带来少量漏计。
- 未接入的大块（潜在功能空间）：
  - plugin 39 个（评分 rating、市场 remotes、文件夹管理、dashboard 卡片等）
  - recommend 14 个、site 12 个、message 12 个、dashboard 11 个
  - mfa 10 个（两步验证管理）、tmdb 9 个、storage 9 个（网盘文件操作）、llm 8 个（provider-auth 流程）
  - notification 5、mcp 5（/api/v1/mcp、tools、tools/call）
  - 整个 /api/v3/* 段：movie、series、qualityProfile、rootfolder、tag、languageProfile、system/status（Radarr/Sonarr 风格契约）

## 四、审计局限

- query 参数通过变量/map 传递的调用无法静态全查（内联可查的仅 20 处）。
- POST body 字段与 schema 的逐字段比对未做（工作量与收益比低，建议随功能改动逐个核对）。
- 规范版本随服务端演进，建议在 CI 中以本审计脚本做增量核对（脚本思路：提取（方法,路径,参数名）→ 模板匹配 → 报缺失）。

## 五、版本实机矩阵与修复记录

> 重要更正（2026-10-15 复核）：api.movie-pilot.org 的 Swagger 与任一真实 release 均不完全一致——它混合了 v2 表面（storage/usage、llm/models）与 v3 增量（/api/v3/*、mcp 等），且**未收录 v3 实机存在的 media/source 与 storage/manage**。
> 因此以服务端源码实机核对为准：v2 分支（v2 release 线）与 v3.1.5 tag（v3 release 线）。

| 端点 | v2 实机 | v3.1.5 实机 | Swagger | 裁决 |
|---|---|---|---|---|
| GET /api/v1/media/source | 无（404→判 v2 ✓） | 有（返回媒体数据源表） | 未收录 | 原探测端点正确，保留 |
| POST /api/v1/storage/manage | 无 | 有（usage 已被其取代） | 未收录 | 原 isV3 双分支正确，保留 |
| GET /api/v1/storage/usage/{name} | 有 | 无 | 收录 | v2 分支正确，保留 |
| GET /api/v1/llm/models | 有（llm.py） | 无（改为 POST llm/manage） | 收录 | 见修复 1 |
| GET /api/v1/system/llm-models | 无 | 无 | 无 | 原路径在两端都 404 |
| GET /api/v1/system/ping、versions | 有 | 有 | 收录 | 兜底替换安全 |

### 最终修复清单（经 v2/v3.1.5 双向验证后）

1. **保留** LLM 模型列表：主路径 GET /api/v1/llm/models（v2 与 Swagger 一致），404 时回退旧路径 system/llm-models（覆盖过渡期/自定义服务端），均带 skipV3EnvelopeUnwrap 保留信封解析。v3.1.5+ 的 POST llm/manage 统一管理入口暂未适配（动作词汇未公开），列为后续项。
2. **已回滚** 存储用量：恢复 isV3 双分支（v3 → POST storage/manage，v2 → GET storage/usage）。此前误将 Swagger 当唯一事实来源统一到 usage，会导致 v3.1.5 实机存储卡片消失。
3. **已回滚** 能力表探测：恢复 GET /api/v1/media/source（v3.1.5 media.py 实测存在，Swagger 漏收录）。此前误改为 discover/source——那是「探索数据源」接口，v2 也存在，会把 v2 服务器误判为 v3，属于 V2 兼容性回归。
4. **保留** mediaserver/seasoninfo：getSeasonInfo 为零调用死代码，删除不影响任何版本。
5. **保留** 健康检查兜底：五个无效路径替换为 ping/versions（两版实机均存在）。主链路 modulelist/moduletest 不变。

### 经验教训

- Swagger 与实机 release 存在偏差（漏收录 media/source、storage/manage；多收录 v2 已在 v3 删除的 usage）。后续对照 API 时应同时核对 v2 分支与最新 v3 tag 的源码，Swagger 仅作参考基线。
- 涉及版本分支（isV3）的调用，改路径前必须先确认两个版本各自的表面，避免把「未收录」当成「不存在」。

## 六、遗留说明

- 搜索模块的双形态契约（旧式前缀标识 vs 新式数字标识 + media_source）是刻意设计的兼容机制，自带 422 翻转实测记忆（markSearchNeedsMediaSource），不视为违规。
- v3.1.5+ 的 POST /api/v1/llm/manage（LLM 统一管理）与 POST /api/v1/storage/manage 的完整动作词汇未公开，待服务端文档补齐后再评估适配。
- POST 请求体与 schema 的逐字段比对仍未覆盖，建议随功能改动逐个核对。
