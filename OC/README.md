# PushWithP8 — Objective-C

原 Swift macOS 工具的独立 Objective-C 版本。保留原 AppKit Storyboard、图标、中文输入界面和环境切换，最低支持 macOS 12.0，无第三方依赖。

## 打开和编译

用 Xcode 27 打开本目录下的 `PushWithP8.xcodeproj`，选择 `PushWithP8` scheme，运行到 My Mac。

以下命令从仓库根目录执行：

```sh
xcodebuild -project OC/PushWithP8.xcodeproj -scheme PushWithP8 -configuration Debug -derivedDataPath /tmp/PushWithP8-OC CODE_SIGNING_ALLOWED=NO build
```

把 Debug 替换为 Release 可构建发布配置。无需签名的构建用于本机验证；分发时需自行配置签名和公证。OC 版本使用独立 Bundle ID `com.greywolf.pushWithP8.objc`，可与 Swift 版本并存。

## 使用

填写 Team ID、Key ID、完整 Apple P8 PEM 私钥、应用 Bundle ID、设备 Token 和 JSON Payload。默认使用开发环境，开关切换至生产环境；自定义地址应包含 `/3/device/` 前缀，程序在末尾拼接设备 Token。

“默认”按钮只填充示例 Payload，不再填入旧项目的示例账号和私钥；“清空”会重置全部字段。凭据只在内存中用于当次请求，不写入配置或日志。

## 实现差异

- `Utils/P8JWT`：有边界检查的 DER 解析、P-256 密钥导入、ES256 JWT 签名，以及固定 64 字节的 JOSE 签名编码。接受 Apple P8 使用的、包含公钥的 PKCS#8 EC 私钥。
- `Utils/APNsClient`：构建 APNs 请求，校验 JSON/aps 和 4 KB 限制；添加推送类型，静默推送使用 background/优先级 5，普通通知使用 alert/优先级 10。
- 只有 HTTP 200 显示“发送成功”；其他状态显示 HTTP 状态及 APNs `reason`，网络错误显示实际原因。
- 发送期间禁用发送按钮，网络回调通过主线程更新界面；文本框保留 Command-A/C/V/X。

## 离线验证

从仓库根目录运行（需要 Xcode 命令行工具和系统 OpenSSL）：

```sh
bash OC/Tests/run.sh
# 同时检查实际构建产物的 Storyboard、outlets 和按钮行为：
bash OC/Tests/run.sh /tmp/PushWithP8-OC/Build/Products/Debug/PushWithP8.app
# 用 AddressSanitizer / UndefinedBehaviorSanitizer 检查签名及解析测试：
SANITIZE=1 bash OC/Tests/run.sh
```

测试临时生成 P-256 密钥，用独立公钥验证 JWT；覆盖签名整数补齐、DER 截断和畸形输入、请求构建、APNs 拒绝及网络错误。临时密钥和二进制在测试结束后删除。Storyboard 测试需要已登录的 macOS 图形会话。

已在 Xcode 27.1 验证 Debug / Release 构建和静态分析。不包含真实 APNs 端到端测试；实际推送需要有效的开发者凭据、应用和设备 Token。

## 致谢

本版由仓库的 Swift 实现迁移而来，保留原作者 GreyWolf 的界面与功能。原签名实现参考 [pwlkania/APN-P8](https://github.com/pwlkania/APN-P8)，感谢原作者及开源社区。
