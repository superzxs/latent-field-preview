# latent-field-preview

LATENT FIELD / 潜场 的临时部署仓库。

这个仓库只放**构建产物**和**部署脚本**，源码在私有仓库 `superzxs/latent-field`。

## 服务器一次性安装

全新服务器（装 Nginx + 站点 + 自动更新）：

```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/superzxs/latent-field-preview/main/install.sh | sudo bash
```

站点已经装好，只想打开自动更新（每 5 分钟拉取新版本）：

```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/superzxs/latent-field-preview/main/install-sync.sh | sudo bash
```

## 文件说明

| 文件 | 作用 |
| --- | --- |
| `latest.tar.gz`（`latent-field-preview.tar.gz`） | 当前构建产物（tar.gz，保证路径分隔符正确） |
| `version.txt` | 当前版本号，服务器据此判断是否需要更新 |
| `install.sh` | 全新服务器安装：Nginx + 站点 |
| `install-sync.sh` | 安装自动更新定时任务 |
| `sync.sh` | 服务器上的更新脚本，装成 `/usr/local/bin/latent-field-sync` |

## 发布流程

在本地私有仓库里：

```bash
npm run publish
```

会依次完成：构建 → 打包 → 更新 `version.txt` → push 到本仓库。  
服务器最多 5 分钟后自动切换到新版本，无需登录服务器。

日志：`/var/log/latent-field-sync.log`

## 注意

- 这是**临时预览**部署：站点地址是 IP，`robots.txt` 和页面 meta 都是 `noindex`，等域名和 ICP 下来后再切换到正式部署。
- 这个仓库是公开的。不要往里放源码、`.env`、任何密钥。
- 正式域名上线后可以删除这个仓库和服务器上的定时任务。
