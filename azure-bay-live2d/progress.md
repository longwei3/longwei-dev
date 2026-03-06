Original prompt: 全部继续做（第二角色+切换+偏好礼物、经营系统最小闭环、Unity+Cubism骨架）

- 已完成：`mvp-interaction.html` 升级为互动经营MVP。
- 功能：双角色切换（汐/柠）、偏好礼物加成、触摸互动、日程互动、好感等级、情绪衰减。
- 功能：果园/渔场经营闭环（在线产出、离线补算、收取、升级、资源消耗与增长）。
- 数据：localStorage 持久化，兼容旧v1存档迁移。
- 调试：保留 `window.render_game_to_text` 和 `window.advanceTime(ms)`。
- 发布：已部署到线上 `https://www.longwei.org.cn/azure-bay-live2d/mvp-interaction.html`。

- 已完成：创建 Unity + Cubism 骨架目录 `unity-cubism-skeleton/`。
- 包含：数据模型、存档服务、角色运行时、经营服务、启动器、HUD示例、asmdef、manifest、README。

Next TODO:
1. 将 5 角色数据完整接入（星/帆/月）并补足偏好礼物与台词。
2. 把经营收益曲线迁移到 ScriptableObject 配表，便于热更新。
3. 将 CubismParameterBridge 对接真实参数（ParamEmotion_*、ParamMouthOpenY）。
4. 增加剧情节点与图鉴解锁条件。
