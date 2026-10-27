#import "MainViewController.h"
#import "Utils/P8JWT.h"
#import "Utils/APNsClient.h"
static NSString * const DevelopmentURL=@"https://api.sandbox.push.apple.com/3/device/";
static NSString * const ProductionURL=@"https://api.push.apple.com/3/device/";
static NSString * const ExamplePayload=@"{\"aps\":{\"alert\":{\"title\":\"这是推送标题\",\"subtitle\":\"这是推送内容\"},\"sound\":\"default\",\"badge\":1}}";
@implementation MainViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.teamIDTextField.placeholderString=@"请填写开发者的Team ID";
    self.keyIDTextField.placeholderString=@"请填写开发者的Key ID";
    self.p8KeyTextField.placeholderString=@"请粘贴完整 P8 私钥（含 BEGIN / END PRIVATE KEY）";
    self.bundleIDTextField.placeholderString=@"请填写应用的Bundle ID";
    self.deviceTokenTextField.placeholderString=@"请填写接收推送的设备的Device Token";
    self.payLoadTextField.placeholderString=ExamplePayload;
    [self clearAction:nil];
}
- (IBAction)switchEnvAction:(NSSwitch *)sender {
    if (sender != self.envSwitch) return;
    self.envTextField.stringValue=@"";
    self.envTextField.placeholderString=self.envSwitch.state==NSControlStateValueOn ? ProductionURL : DevelopmentURL;
}
- (IBAction)setToDefaultAction:(id)sender {
    [self clearAction:sender];
    self.payLoadTextField.stringValue=ExamplePayload;
}
- (IBAction)clearAction:(id)sender {
    for (NSTextField *field in @[self.teamIDTextField,self.keyIDTextField,self.p8KeyTextField,self.bundleIDTextField,self.deviceTokenTextField,self.payLoadTextField,self.envTextField,self.resultLabel]) field.stringValue=@"";
    self.envSwitch.state=NSControlStateValueOff;
    self.envTextField.placeholderString=DevelopmentURL;
}
- (IBAction)sendAction:(NSButton *)sender {
    if (!self.sendButton.enabled) return;
    NSArray<NSTextField *> *fields=@[self.teamIDTextField,self.keyIDTextField,self.p8KeyTextField,self.bundleIDTextField,self.deviceTokenTextField,self.payLoadTextField];
    NSArray<NSString *> *names=@[@"Team ID",@"Key ID",@"P8证书",@"Bundle ID",@"DeviceToken",@"Payload"];
    NSMutableArray<NSString *> *values=[NSMutableArray array];
    for (NSUInteger i=0;i<fields.count;i++) {
        NSString *value=[fields[i].stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (!value.length) { self.resultLabel.stringValue=[names[i] stringByAppendingString:@" 不能为空"]; return; }
        [values addObject:value];
    }
    NSError *error=nil;
    NSString *jwt=[P8JWT tokenWithKeyID:values[1] teamID:values[0] privateKey:values[2] date:NSDate.date error:&error];
    if (!jwt) { self.resultLabel.stringValue=[@"生成JWT Token失败：" stringByAppendingString:error.localizedDescription ?: @"未知错误"]; return; }
    NSString *base=[self.envTextField.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!base.length) base=self.envSwitch.state==NSControlStateValueOn ? ProductionURL : DevelopmentURL;
    NSURLRequest *request=[APNsClient requestWithToken:jwt topic:values[3] deviceToken:values[4] payload:values[5] baseURL:base error:&error];
    if (!request) { self.resultLabel.stringValue=error.localizedDescription ?: @"请求无效"; return; }
    self.sendButton.enabled=NO;
    self.resultLabel.stringValue=@"发送中…";
    __weak typeof(self) weakSelf=self;
    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
        NSString *result=[APNsClient resultForResponse:response data:data error:networkError];
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) strongSelf=weakSelf;
            strongSelf.resultLabel.stringValue=result;
            strongSelf.sendButton.enabled=YES;
        });
    }] resume];
}
@end
@implementation ShortcutTextField
- (BOOL)performKeyEquivalent:(NSEvent *)event {
    if ((event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask)==NSEventModifierFlagCommand) {
        NSDictionary<NSString *,NSString *> *selectors=@{@"a":@"selectAll:",@"c":@"copy:",@"v":@"paste:",@"x":@"cut:"};
        NSString *name=selectors[event.charactersIgnoringModifiers ?: @""];
        if (name && [NSApp sendAction:NSSelectorFromString(name) to:self.window.firstResponder from:self]) return YES;
    }
    return [super performKeyEquivalent:event];
}
@end
