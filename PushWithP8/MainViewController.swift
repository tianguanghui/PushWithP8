//
//  MainViewController.swift
//  PushWithP8
//
//  Created by GreyWolf on 2021/8/26.
//

import Cocoa

class MainViewController: NSViewController {
    
    @IBOutlet weak var teamIDTextField: NSTextField!
    @IBOutlet weak var keyIDTextField: NSTextField!
    @IBOutlet weak var p8KeyTextField: NSTextField!
    @IBOutlet weak var bundleIDTextField: NSTextField!
    @IBOutlet weak var deviceTokenTextField: NSTextField!
    @IBOutlet weak var payLoadTextField: NSTextField!
    @IBOutlet weak var envTextField: NSTextField!
    @IBOutlet weak var envSwitch: NSSwitch!
    @IBOutlet weak var resultLabel: NSTextField!
    @IBOutlet weak var sendButton: NSButton!
    
    let envDevelop = "https://api.development.push.apple.com/3/device/"
    let envProduction = "https://api.push.apple.com/3/device/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        teamIDTextField.placeholderString = "请填写开发者的Team ID"
        keyIDTextField.placeholderString = "请填写开发者的Key ID"
        p8KeyTextField.placeholderString = """
            -----BEGIN PRIVATE KEY-----
            MIGTBgEBMBMGByqGSM49BgEGCCqGSM49BwEHBHkwdwIBBPPgb0jNPbqLE4Ex/XLe
            nmBHTPvZWX9sKWV3Ero7JBRwPxugCgYIKoZIzj0DBPehRBNCBBPaeMGciIZxbKoN
            07HH24GPdoPvBN25FiX5PJI9GaiSDaqmIU5jjf0VYe7oYc6xFNj+72pGVIhHWox4
            2SnJ9Oi5
            -----END PRIVATE KEY-----
            """
        bundleIDTextField.placeholderString = "请填写应用的Bundle ID"
        deviceTokenTextField.placeholderString = "请填写接收推送的设备的Device Token"
        payLoadTextField.placeholderString = """
            {"aps":{"alert":{"title":"这是推送标题","subtitle":"这是推送内容，这里的文字长度是有限制的"},"sound":"default","badge":1}}
            """
        envTextField.placeholderString = envDevelop
        
        teamIDTextField.stringValue = ""
        keyIDTextField.stringValue = ""
        p8KeyTextField.stringValue = ""
        bundleIDTextField.stringValue = ""
        deviceTokenTextField.stringValue = ""
        payLoadTextField.stringValue = ""
        envTextField.stringValue = ""
        envSwitch.state = NSControl.StateValue.off
        resultLabel.stringValue = ""
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func switchEnvAction(_ sender: NSSwitch) {
        if sender == envSwitch {
            if envSwitch.state == NSControl.StateValue.off {
                envTextField.stringValue = ""
                envTextField.placeholderString = envDevelop
            } else if envSwitch.state == NSControl.StateValue.on {
                envTextField.stringValue = ""
                envTextField.placeholderString = envProduction
            }
        }
    }
    
    @IBAction func setToDefaultAction(_ sender: Any) {
        teamIDTextField.stringValue = "SQYY7F42U5"
        keyIDTextField.stringValue = "DMR5B9WQAT"
        p8KeyTextField.stringValue = """
            -----BEGIN PRIVATE KEY-----
            MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgb0jNPbqLE4Ex/XLe
            nmBHTPvZWX9sKWV3Ero7JBRwQxugCgYIKoZIzj0DAQehRANCAAQaeMGciIZxbKoN
            07HH24GQdoQvBN25FiX5PJI9GaiSDaqmIU5jjf0VYe7oYc6xFNj+72pGVIhHWox4
            2SnJ9Oi5
            -----END PRIVATE KEY-----
            """
        bundleIDTextField.stringValue = "com.11bee.xbinsurance"
        deviceTokenTextField.stringValue = "5a61641b72ada490789850c75abb11b62a6b63db5841a0bea52d3ebb69b47d27"
        payLoadTextField.stringValue = """
            {"aps":{"alert":{"title":"这是推送标题","subtitle":"这是推送内容，这里的文字长度是有限制的"},"sound":"default","badge":1}}
            """
        envTextField.stringValue = ""
        envTextField.placeholderString = envDevelop
        envSwitch.state = NSControl.StateValue.off
        resultLabel.stringValue = ""
    }
    
    @IBAction func clearAction(_ sender: Any) {
        teamIDTextField.stringValue = ""
        keyIDTextField.stringValue = ""
        p8KeyTextField.stringValue = ""
        bundleIDTextField.stringValue = ""
        deviceTokenTextField.stringValue = ""
        payLoadTextField.stringValue = ""
        envTextField.stringValue = ""
        envTextField.placeholderString = envDevelop
        envSwitch.state = NSControl.StateValue.off
        resultLabel.stringValue = ""
    }
    
    @IBAction func sendAction(_ sender: NSButton) {
        
        let kTEAM_ID = teamIDTextField.stringValue
        let kKEY_ID = keyIDTextField.stringValue
        let kP8 = p8KeyTextField.stringValue
        let kBUNDLE_ID = bundleIDTextField.stringValue
        let kDEVICE_TOKEN = deviceTokenTextField.stringValue
        let kPAYLOAD = payLoadTextField.stringValue
        let kURL = !(envTextField.stringValue.isEmpty) ? envTextField.stringValue : ((envSwitch.state == NSControl.StateValue.off) ? envDevelop : envProduction)
        
        guard !(kTEAM_ID.isEmpty) else {
            resultLabel.stringValue = "Team ID 不能为空";
            return
        }
        
        guard !(kKEY_ID.isEmpty) else {
            resultLabel.stringValue = "Key ID 不能为空";
            return
        }
        
        guard !(kP8.isEmpty) else {
            resultLabel.stringValue = "P8证书 不能为空";
            return
        }
        
        guard !(kBUNDLE_ID.isEmpty) else {
            resultLabel.stringValue = "Bundle ID 不能为空";
            return
        }
        
        guard !(kDEVICE_TOKEN.isEmpty) else {
            resultLabel.stringValue = "DeviceToken 不能为空";
            return
        }
        
        guard !(kPAYLOAD.isEmpty) else {
            resultLabel.stringValue = "Payload 不能为空";
            return
        }
        
        DispatchQueue.main.async {
            self.resultLabel.stringValue = ""
        }
        
        let jwt = JWT(keyID: kKEY_ID, teamID: kTEAM_ID, issueDate: Date(), expireDuration: 60 * 60)
        do {
            let token = try jwt.sign(with: kP8)
            var request = URLRequest(url: URL(string: kURL + kDEVICE_TOKEN)!)
            request.httpMethod = "POST"
            request.addValue("bearer \(token)", forHTTPHeaderField: "authorization")
            request.addValue(kBUNDLE_ID, forHTTPHeaderField: "apns-topic")
            request.httpBody = kPAYLOAD.data(using: .utf8)

            URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard error == nil else {
                    DispatchQueue.main.async {
                        self.resultLabel.stringValue = error!.localizedDescription
                    }
                    return
                }
                guard data != nil else {
                    DispatchQueue.main.async {
                        self.resultLabel.stringValue = "未知错误"
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.resultLabel.stringValue = "发送成功"
                }
            }.resume()
        } catch {
            DispatchQueue.main.async {
                self.resultLabel.stringValue = "生成JWT Token失败"
            }
        }
    }
    
}

extension NSTextField {
    open override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.isDisjoint(with: .command) {
            return super.performKeyEquivalent(with: event)
        }
        
        switch event.charactersIgnoringModifiers {
        case "a":
            return NSApp.sendAction(#selector(NSText.selectAll(_:)), to: self.window?.firstResponder, from: self)
        case "c":
            return NSApp.sendAction(#selector(NSText.copy(_:)), to: self.window?.firstResponder, from: self)
        case "v":
            return NSApp.sendAction(#selector(NSText.paste(_:)), to: self.window?.firstResponder, from: self)
        case "x":
            return NSApp.sendAction(#selector(NSText.cut(_:)), to: self.window?.firstResponder, from: self)
        default:
            return super.performKeyEquivalent(with: event)
        }
    }
}
