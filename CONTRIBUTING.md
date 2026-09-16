# 贡献指南

感谢你改进 Antigravity Bridge。

## 开发环境

- macOS 12 或更高版本。
- 系统自带 Bash 3.2。
- 建议安装 ShellCheck。

## 开发流程

1. Fork 仓库并从 `main` 创建主题分支。
2. 保持改动单一、清晰，不要提交 `dist/` 或 macOS Finder 元数据。
3. 修改行为时，同时添加或更新 `tests/run-tests.sh` 中的测试。
4. 运行：

   ```bash
   ./tests/run-tests.sh
   ```

5. 提交 Pull Request，说明问题、解决方式、测试结果及用户可见影响。

## 代码约定

- 保持兼容 macOS 自带的 Bash 3.2。
- 优先使用 macOS 自带命令，并为命令使用明确路径。
- 所有变量都应正确引用，临时文件应安全创建并清理。
- 不要加入遥测、凭据采集或修改系统代理/路由的行为。
- 不要提交证书、密码、Token、Apple 公证凭据或真实用户配置。

提交贡献即表示你有权按照项目的 MIT License 授权这些内容，并同意遵守 [行为准则](CODE_OF_CONDUCT.md)。
