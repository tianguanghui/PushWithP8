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
