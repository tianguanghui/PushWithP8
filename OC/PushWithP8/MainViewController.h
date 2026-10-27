#import <Cocoa/Cocoa.h>
@interface MainViewController : NSViewController
@property (weak) IBOutlet NSTextField *teamIDTextField;
@property (weak) IBOutlet NSTextField *keyIDTextField;
@property (weak) IBOutlet NSTextField *p8KeyTextField;
@property (weak) IBOutlet NSTextField *bundleIDTextField;
@property (weak) IBOutlet NSTextField *deviceTokenTextField;
@property (weak) IBOutlet NSTextField *payLoadTextField;
@property (weak) IBOutlet NSTextField *envTextField;
@property (weak) IBOutlet NSSwitch *envSwitch;
@property (weak) IBOutlet NSTextField *resultLabel;
@property (weak) IBOutlet NSButton *sendButton;
- (IBAction)switchEnvAction:(NSSwitch *)sender;
- (IBAction)setToDefaultAction:(id)sender;
- (IBAction)clearAction:(id)sender;
- (IBAction)sendAction:(NSButton *)sender;
@end
// Local subclass keeps standard macOS editing shortcuts available in the fields.
@interface ShortcutTextField : NSTextField
@end
