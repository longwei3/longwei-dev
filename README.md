# 个人网站

一个科技感十足的个人主页，展示我的技能和项目。

## AI 接手说明

- AI 执行规范：`AGENTS.md`
- 部署与证书手册：`docs/DEPLOYMENT_PLAYBOOK.md`

## 查看方式

直接在浏览器中打开 `index.html` 文件即可预览。

或者可以使用简单的 HTTP 服务器：

```bash
cd ~/longwei-dev
python3 -m http.server 8080
```

然后访问 http://localhost:8080

## 自定义

修改 `index.html` 中的内容：
- 联系邮箱：搜索 `your@email.com`
- 项目内容：修改 `#projects` 部分
- 技能：修改 `#skills` 部分
- 统计数据：修改 `.stats` 部分

## 一键发布到 longwei.org.cn

首次初始化（只需一次）：

```bash
cd ~/longwei-dev
./scripts/setup-site-env.sh
```

填写本机配置文件（仅本机可读）：

- `~/.config/longwei-site/deploy.env`

发布网站：

```bash
cd ~/longwei-dev
./scripts/deploy-site.sh
```

发布前会自动执行安全预检（可单独运行）：

```bash
cd ~/longwei-dev
./scripts/security-preflight.sh --source ~/longwei-dev
```

### 双击发布（macOS App）

生成桌面发布程序（只需一次）：

```bash
cd ~/longwei-dev
./scripts/build-macos-publish-app.sh
```

生成后，桌面会出现：`PublishLongweiSite.app`  
你可以在 Finder 里重命名为 `发布网站.app`。以后双击它即可发布，不需要手动输入命令。

发布完成后：

- `https://www.longwei.org.cn`
- `https://longwei.org.cn`

会自动拉取最新内容（脚本会同步 OSS 并刷新 CDN 缓存）。

## HTTPS 证书自动续期

证书由 `acme.sh` 签发，系统已安装每日自动任务。  
执行下面命令可绑定“续期后自动推送 CDN”钩子：

```bash
cd ~/longwei-dev
./scripts/install-acme-hook.sh
```

手动推送当前证书到 CDN（调试用）：

```bash
cd ~/longwei-dev
./scripts/push-cert-to-cdn.sh
```
