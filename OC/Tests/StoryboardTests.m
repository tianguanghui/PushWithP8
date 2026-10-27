#import <Cocoa/Cocoa.h>
static int failures;
#define CHECK(condition, message) do { if (!(condition)) { fprintf(stderr,"FAIL: %s\n",message); failures++; } } while (0)
int main(int argc, const char *argv[]) { @autoreleasepool {
    if (!NSClassFromString(@"MainViewController")) { fprintf(stderr,"FAIL: OC view controller has not been implemented\n"); return 1; }
    if (argc != 2) return 1;
    [NSApplication sharedApplication];
    NSBundle *bundle=[NSBundle bundleWithPath:@(argv[1])];
    NSStoryboard *storyboard=[NSStoryboard storyboardWithName:@"Main" bundle:bundle];
    NSWindowController *window=[storyboard instantiateInitialController];
    NSViewController *controller=window.contentViewController; (void)controller.view;
    CHECK([controller.className isEqual:@"MainViewController"],"storyboard must load Objective-C controller");
    NSArray *outlets=@[@"teamIDTextField",@"keyIDTextField",@"p8KeyTextField",@"bundleIDTextField",@"deviceTokenTextField",@"payLoadTextField",@"envTextField",@"envSwitch",@"resultLabel",@"sendButton"];
    for (NSString *name in outlets) CHECK([controller valueForKey:name] != nil,"all storyboard outlets must connect");
    NSButton *send=[controller valueForKey:@"sendButton"];
    CHECK(send.target==controller && send.action==NSSelectorFromString(@"sendAction:"),"send button action must connect");
    [send performClick:nil];
    CHECK([[[controller valueForKey:@"resultLabel"] stringValue] containsString:@"Team ID"],"empty send must report validation error");
    NSSwitch *env=[controller valueForKey:@"envSwitch"]; env.state=NSControlStateValueOn;
    [NSApp sendAction:NSSelectorFromString(@"switchEnvAction:") to:controller from:env];
    CHECK([[[controller valueForKey:@"envTextField"] placeholderString] containsString:@"api.push.apple.com"],"switch must select production");
    [NSApp sendAction:NSSelectorFromString(@"setToDefaultAction:") to:controller from:nil];
    CHECK([[[controller valueForKey:@"payLoadTextField"] stringValue] containsString:@"aps"],"default must fill example payload");
    CHECK([[[controller valueForKey:@"p8KeyTextField"] stringValue] length]==0,"default must not embed credentials");
    [NSApp sendAction:NSSelectorFromString(@"clearAction:") to:controller from:nil];
    for (NSString *name in @[@"teamIDTextField",@"keyIDTextField",@"p8KeyTextField",@"bundleIDTextField",@"deviceTokenTextField",@"payLoadTextField",@"envTextField",@"resultLabel"]) CHECK([[[controller valueForKey:name] stringValue] length]==0,"clear must reset every field");
    CHECK(env.state==NSControlStateValueOff,"clear must reset environment");
    fprintf(stderr,"Storyboard %s (%d failures)\n",failures ? "FAILED" : "PASS",failures); return failures ? 1 : 0;
} }
