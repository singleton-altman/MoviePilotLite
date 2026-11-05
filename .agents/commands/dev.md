# 开发任务全流程（/dev）

参数：需求描述（一句话或要点列表，来自 $ARGUMENTS）。未带参数时先向用户确认需求与验收标准，再进入阶段一。

按五个阶段顺序执行。除阶段三的验证工作流在后台运行外，其余都在当前会话完成；用户随时喊停即停。

## 阶段一：需求确认与 issue 创建

- 先判断是否正式开发任务（改代码、修 bug、加功能、重构）。纯问答、配置微调、一次性探查：直接回答，不建 issue，流程到此结束。
- 仓库固定为 singleton-altman/MoviePilotLite，issue 一律走 gh。
- 建 issue：标题概括任务；正文写现象、根因（已知时）、方案要点、验收标准清单（可勾选项）。编号记入会话上下文，后续所有产出引用它。
- 豁免：用户明说「不建 issue」时跳过建单，后续阶段照走，PR 正文不带 Closes。

## 阶段二：实现

- 遵循仓库 AGENTS.md 全部约定（Flutter 页面结构、HTTP 严格按 Swagger、对话回复不展示代码）。
- UI 类改动优先真机/模拟器验证：热重载优先；无调试会话时用 devicectl 独立安装启动，或请用户在自己终端跑 flutter run。
- 实现中发现需求要变更：先更新 issue 正文再继续，保持 issue 与实际一致。

## 阶段三：验证（提交前必过）

- 运行已保存的验证工作流 pre-commit-verify（通过 CreateWorkflow 的 saved 方式）。
- 参数选择：整线 PR（PR 内容等于工作区全部改动，本仓库常态）带 includeApk: true；纯小修用默认参数。
- 判定：全量测试必须绿；analyze 失败时看归因结果——凡有 error 级问题归因为本次改动，回阶段二修复，不得进入阶段四；warning/info 级与既有债务记录进 PR 正文即可。
- 工作区里存在不会进入本 PR 的 WIP 时（罕见，本流程默认整线提交），向用户说明验证覆盖面与 PR 实际内容的差异。

## 阶段四：提交与 PR

- 提交排除项：.claude/、.mimosa/、.v2c/、.video_agent/、ios/.mimosa/ 一律不进库；.zcode/ 被仓库 .gitignore 忽略，保持本地不入库。
- 提交拆分：功能一个提交、纯文档/配置一个提交；message 用 conventional commits 中文风格（feat/fix/chore/test 加模块前缀）。
- 分支惯例：直接在 fix/player-screen-wakelock 上推送、PR 投 dev（仓库现行工作流，dev 应已包含该分支已合并内容；若发现 dev 领先，先合并 dev 再推）。用户指定新分支时从 origin/dev 切新分支。
- PR 正文必须包含：Closes 加 issue 编号（有 issue 时）、内容概览、验证结论（四项门禁逐项列出，analyze 失败要带归因说明）。
- push 与开 PR 是本流程的默认动作，无需逐次询问；PR 建成后立即回评 issue，附 PR 链接与验证结论。

## 阶段五：issue 收尾

- 默认：由 PR 正文的 Closes 随合并自动关闭，不手动干预。
- 用户当次要求立即关闭：gh issue close 附收尾评论（修复去向、验证方式、复现指引），并在评论里注明 PR 链接。
- 合并后发现 issue 因引用笔误未自动关闭：补 gh issue close 并在评论说明。
