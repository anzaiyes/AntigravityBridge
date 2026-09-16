# 更新日志

本项目遵循语义化版本的版本号形式，并在此记录面向用户的重要变更。

## [Unreleased]

### 新增

- 同时生成 ZIP 与可拖拽安装的 DMG 分发包。

## [2.2.0] - 2026-09-16

### 新增

- 自动发现 macOS 系统代理、Clash/Mihomo 配置和 Surge Profile。
- 对候选代理进行协议验证、目标端点验证和可解释评分。
- 支持 HTTP/Mixed、SOCKS5、手动配置、重新配置和诊断模式。
- 自动迁移旧版 Antigravity Proxy 配置。
- 可复现的 App 构建、测试、ZIP 打包和 SHA-256 校验流程。
- GitHub Actions 持续集成和标签发布流程。

### 安全与分发说明

- v2.2.0 二进制使用 ad-hoc 签名，尚未经过 Apple Developer ID 签名或 Apple 公证。
