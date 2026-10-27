# PushWithP8
用P8证书发送Push

首先非常感谢 @pwlkania 和他的项目 https://github.com/pwlkania/APN-P8 

本仓库代码是在APN-P8仓库上，添加了Mac界面的支持，同时对代码进行了格式化整理，核心的推送逻辑还是用的APN-P8这个仓库的代码，非常感谢。

因为找了很久没有合适的带界面的通过P8证书推送的小工具，所以自己站在大神的肩膀上撸了一下，感谢开源社区，仅提供给需要的开发者测试使用。

## Xcode 27

原 Swift 工程已适配 Xcode 27，最低系统版本为 macOS 12.0。使用 Xcode 打开根目录的 `PushWithP8.xcodeproj`，选择 `PushWithP8` scheme。

无需开发者签名的本地编译：

```sh
xcodebuild -project PushWithP8.xcodeproj -scheme PushWithP8 -configuration Debug -derivedDataPath /tmp/PushWithP8-Swift CODE_SIGNING_ALLOWED=NO build
```

本机 Xcode 27.1 已验证 Debug / Release 编译通过。原先 macOS 10.15 的部署目标不在该 Xcode 的支持范围内。

## Objective-C 版本

独立 OC 工程位于 [`OC/PushWithP8.xcodeproj`](OC/PushWithP8.xcodeproj)，保留原界面和推送流程。编译、使用和离线测试见 [`OC/README.md`](OC/README.md)。Swift 工程仍位于仓库根目录，两版可分别打开。

## 1.0.4 发布包

[GitHub Releases](https://github.com/tianguanghui/PushWithP8/releases) 提供 Swift / OC 两个 Universal ZIP，均支持 Apple Silicon 和 Intel，要求 macOS 12 或更新版本。建议优先使用 OC 版，推送错误反馈和无效输入处理更完善。两个 ZIP 内均为 `PushWithP8.app`，请分别解压到不同目录。

安装包使用 ad-hoc 签名，未经 Apple 公证，macOS 可能阻止打开；也可用 Xcode 从源码编译运行。发布页附带 `SHA256SUMS` 校验文件。真实 APNs 推送需要自行提供有效的开发者凭据和设备 Token。

从仓库根目录重建发布包（Xcode 27，需 macOS 图形会话）：

```sh
bash scripts/package-release.sh
```

输出位于 `dist/1.0.4/`，包含两版安装包、SHA256 校验和与构建日志。脚本验证 Universal 架构、版本号、ad-hoc 签名，并执行 OC 离线/界面测试；不自动上传。更新版本时需同时修改 `VERSION` 和两个 Xcode 工程的版本号。
