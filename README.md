# Antigravity Bridge

Antigravity Bridge 是一个轻量的 macOS 启动器：自动识别本机 HTTP/Mixed 或 SOCKS5 代理，并只为 Antigravity 进程树注入代理环境，无需开启 TUN，也不会修改系统代理。

> [!IMPORTANT]
> 本项目是独立的非官方开源项目，与 Google 没有隶属、赞助或背书关系。Antigravity、Google 及相关名称和标识属于其各自权利人。

## 功能

- 自动读取 macOS 系统代理以及 Clash、Mihomo、Surge 的常见配置。
- 实际验证代理端口和目标端点后给出可解释的推荐。
- 支持手动配置本机 HTTP/Mixed 或 SOCKS5 端口。
- 仅影响由启动器打开的 Antigravity 进程树。
- 不开启 TUN，不修改系统路由、代理客户端或 Antigravity 应用。
- 保存每个 macOS 用户各自的配置，代理失效后自动重新探测。

## 系统要求

- macOS 12 或更高版本。
- 已安装 Bundle ID 为 `com.google.antigravity-ide` 的 Antigravity IDE。
- 本机已有可用的 HTTP/Mixed 或 SOCKS5 代理。

本项目使用 macOS 自带的 Bash 3.2、`curl`、`nc`、`plutil`、`osascript` 和 `open`，运行时不需要安装第三方依赖。

## 安装

1. 从 GitHub Releases 下载 `Antigravity-Bridge-v2.2.0-unsigned.zip` 和 `SHA256SUMS`。
2. 核对下载文件的 SHA-256：

   ```bash
   shasum -a 256 -c SHA256SUMS
   ```

3. 解压后，将 `Antigravity Bridge.app` 拖入 `/Applications`。
4. 确保代理客户端正在运行，并用 `Command-Q` 完全退出已经打开的 Antigravity。
5. 首次启动时右键 App 并选择“打开”。如果 macOS 仍然阻止启动，请前往“系统设置 → 隐私与安全性”，确认打开该 App。

### 关于签名与 Gatekeeper

当前 v2.2.0 发布包采用 ad-hoc 签名，尚未使用 Apple Developer ID 签名，也没有经过 Apple 公证。macOS 因此可能显示“无法验证开发者”等提示。请只从本项目的官方 GitHub Releases 下载，并核对 SHA-256。

不要为了运行本项目而全局关闭 Gatekeeper。

## 使用

首次运行时，启动器会查找 Antigravity、检测可用代理，并显示推荐项。选择后配置保存在：

```text
~/Library/Application Support/Antigravity Bridge/config.plist
```

旧版 `Antigravity Proxy` 配置会在首次升级时复制到新目录，旧配置不会被删除。

主动重新配置：

```bash
"/Applications/Antigravity Bridge.app/Contents/MacOS/antigravity-bridge" --configure
```

查看自动发现结果：

```bash
"/Applications/Antigravity Bridge.app/Contents/MacOS/antigravity-bridge" --diagnose
```

更完整的说明见 [使用说明](docs/使用说明.md)。

## 隐私与网络行为

为了发现本机代理，启动器可能读取：

- macOS 当前系统代理设置。
- Clash、Mihomo 和 Surge 的常见本地配置文件。
- 保存于本机的 Antigravity Bridge 配置。

为了验证代理可用性，启动器会通过候选代理访问：

- `https://www.gstatic.com/generate_204`
- `https://daily-cloudcode-pa.googleapis.com/`

启动器不会读取、保存或转发 Google 登录凭据，也不包含遥测服务。配置文件权限设置为仅当前用户可读写。

## 从源码构建

```bash
./scripts/build.sh
./tests/run-tests.sh
./scripts/package.sh v2.2.0
```

生成产物位于 `dist/`：

```text
dist/Antigravity Bridge.app
dist/Antigravity-Bridge-v2.2.0-unsigned.zip
dist/SHA256SUMS
```

如果本机安装了 ShellCheck，测试脚本也会自动执行静态检查。正式发布流程见 [发布流程](docs/发布流程.md)。

## 项目结构

- `src/antigravity-bridge`：启动器 Bash 源码。
- `packaging/Info.plist`：macOS App Bundle 元数据。
- `resources/`：App 图标资源。
- `scripts/`：构建、打包以及可选签名脚本。
- `tests/`：自动化测试和配置 fixture。
- `docs/`：使用、设计和发布文档。
- `.github/workflows/`：持续集成和标签发布流程。

## 卸载

删除 `/Applications/Antigravity Bridge.app`。如需同时删除本地配置，再删除：

```text
~/Library/Application Support/Antigravity Bridge/
```

卸载不会更改 Antigravity 或代理客户端。

## 参与贡献与安全报告

提交代码前请阅读 [贡献指南](CONTRIBUTING.md)。安全问题请遵循 [安全策略](SECURITY.md)，不要在公开 Issue 中披露漏洞细节。

## 许可证

本项目使用 [MIT License](LICENSE)，版权归安仔所有。品牌说明见 [NOTICE](NOTICE.md)。
