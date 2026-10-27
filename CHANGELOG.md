# 更新记录

## 1.0.4 — 2026-10-28

- 原 Swift 工程适配 Xcode 27，最低支持 macOS 12，更新废弃的 Data 初始化调用。
- 新增 `OC` 目录中的独立 Objective-C 工程，保留原 AppKit 界面、P8 JWT 签名及 APNs 推送操作。
- OC 版本支持有边界检查的密钥解析、固定 64 字节 ES256 签名、可变长度设备 Token、Payload 校验及正确的 APNs HTTP 错误反馈。
- OC “默认”按钮只填充示例 Payload，不携带旧示例凭据。
- 新增离线签名/请求测试、Storyboard 交互测试和可重复的 Universal Release 打包脚本。

Swift 版保留原业务逻辑；上述推送逻辑改进属于 OC 版。两个 macOS Universal 安装包均支持 arm64 / x86_64，使用 ad-hoc 签名，未经过 Apple 公证。真实 APNs 端到端推送尚未验证。

## 1.0.3

历史版本：环境切换及推送结果展示。
