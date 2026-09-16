# Antigravity Bridge 开源发布实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 Antigravity Bridge 整理为可测试、可复现构建、可通过 GitHub Actions 发布的开源项目，并发布明确标注为未公证的 v2.2.0 版本。

**Architecture:** 源码仓库只保存 Bash 源码、资源、构建脚本、测试、工作流和文档；`dist/` 由本地脚本或 GitHub Actions 重建。CI 对每次提交进行静态检查和功能测试，标签工作流生成 ad-hoc 签名的未公证 ZIP 与 SHA-256 校验文件。Developer ID 签名与 Apple 公证作为显式、凭据驱动的可选流程保留。

**Tech Stack:** Bash 3.2、macOS `plutil`/`codesign`/`xcrun`、Git、GitHub Actions、ShellCheck。

---

### Task 1: 许可证与品牌声明

**Files:**
- Create: `LICENSE`
- Modify: `README.md`

1. 添加 MIT License，版权主体为“安仔”。
2. 在 README 增加非 Google 官方项目声明。
3. 在 README 说明商标归属和图标素材需由维护者确保拥有分发权。
4. 验证许可证文本和 README 链接。

### Task 2: Git 初始化与仓库清理

**Files:**
- Create: `.gitignore`
- Create: `.gitattributes`

1. 以 `main` 为默认分支初始化 Git。
2. 忽略 `.DS_Store`、AppleDouble 文件和 `dist/`。
3. 统一文本文件换行与 shell 文件属性。
4. 删除仓库中的 Finder 元数据；保留本地 `dist/` 作为可重建产物但不纳入版本控制。
5. 使用 `git status --ignored` 验证边界。

### Task 3: 构建与测试脚本

**Files:**
- Create: `scripts/build.sh`
- Create: `scripts/package.sh`
- Create: `scripts/sign-and-notarize.sh`
- Create: `tests/run-tests.sh`
- Modify: `src/antigravity-bridge`

1. 先为端口、评分、Clash/Surge 解析、代理 URL、配置往返和 Bundle 一致性编写测试。
2. 运行测试并确认尚未抽取的代理 URL 测试失败。
3. 抽取 `build_proxy_urls`，保持启动行为不变。
4. 实现可重复创建 App Bundle 的构建脚本，并默认进行 ad-hoc 签名。
5. 实现干净 ZIP 和 SHA-256 生成脚本，发布文件名明确包含 `unsigned`。
6. 实现需要显式证书身份和公证凭据的可选签名脚本；缺失凭据时立即失败。
7. 运行完整测试并核对 ZIP 不含 `__MACOSX`、`.DS_Store` 或 `._*`。

### Task 4: GitHub Actions

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/release.yml`

1. CI 在 macOS runner 上安装 ShellCheck并运行测试。
2. Release 工作流只响应 `v*` 标签。
3. 校验标签版本与 `Info.plist` 一致。
4. 构建未公证 ZIP、生成 SHA-256，并通过 GitHub CLI 创建 Release。
5. 保持工作流最小权限；CI 只读，Release 仅授予 `contents: write`。

### Task 5: README 与社区文件

**Files:**
- Modify: `README.md`
- Modify: `docs/设计方案.md`
- Create: `CHANGELOG.md`
- Create: `CONTRIBUTING.md`
- Create: `SECURITY.md`
- Create: `CODE_OF_CONDUCT.md`
- Create: `.github/ISSUE_TEMPLATE/bug_report.yml`
- Create: `.github/ISSUE_TEMPLATE/feature_request.yml`
- Create: `.github/ISSUE_TEMPLATE/config.yml`
- Create: `.github/pull_request_template.md`

1. 补充安装、系统要求、工作原理、隐私边界、构建、测试、卸载和 Gatekeeper 说明。
2. 修正设计文档中的旧配置路径。
3. 记录 v2.2.0 变更和未公证状态。
4. 添加贡献、安全报告、行为准则及 Issue/PR 模板。
5. 验证所有相对链接和示例命令。

### Task 6: Developer ID 与公证预留

**Files:**
- Modify: `README.md`
- Create: `docs/发布流程.md`

1. 记录当前版本仅为 ad-hoc 签名且未公证。
2. 记录未来所需的 Developer ID、Hardened Runtime、时间戳、notarytool 和 stapler 流程。
3. 确保没有任何真实证书、密码或 Apple 凭据进入仓库。
4. 运行常见敏感信息模式扫描。

### Task 7: v2.2.0 Release

**Files:**
- Generated: `dist/Antigravity-Bridge-v2.2.0-unsigned.zip`
- Generated: `dist/SHA256SUMS`

1. 运行完整测试和打包。
2. 初始化提交并检查 GitHub CLI 登录与远程仓库状态。
3. 仅在已确认的 GitHub 远程存在时推送 `main`。
4. 创建并推送 `v2.2.0` 标签，由工作流创建未公证 Release。
5. 下载或读取 Release 状态，核对资产名称与校验值。

如果 GitHub 登录、远程仓库或外部发布权限缺失，停在本地已验证状态并明确列出所需的单一下一步。
