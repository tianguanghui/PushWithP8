# Xcode 27 适配与 Objective-C 迁移

先适配原 Swift 工程，再迁移 OC，保留原界面、P8/ES256 JWT、APNs 测试推送功能。

## 方案
采用 `OC/PushWithP8.xcodeproj` 独立工程，完整复用 Storyboard 和图片资源，Objective-C 实现 AppDelegate、MainViewController 和签名/请求逻辑。相比混编 target，独立工程方便两版对照；相比重写界面，复用资源可以保留现有交互。

## 约束
- 两版最低 macOS 12.0，使用本机 Xcode 27.1；不引入第三方依赖。
- Swift 阶段只适配最低版本和旧 API，独立提交。
- OC 阶段处理无效 P8/ASN.1、固定 64 字节 ES256 签名、APNs 非 200 错误，避免强制解包或越界。
- OC 示例不复制原项目内嵌的私钥，默认填入示例 payload，凭据由用户填写。
- 编译 Debug/Release；本地生成临时 P-256 密钥测试 JWT 签名和畸形输入，不向 APNs 发送测试请求。
- 验证后本地提交，不 push、不发布。

用户已同意先适配 Swift，再迁移。
