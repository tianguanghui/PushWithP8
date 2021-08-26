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
    @IBOutlet weak var envSwitch: NSSwitch!
    @IBOutlet weak var resultLabel: NSTextField!
    @IBOutlet weak var sendButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        envSwitch.state = NSControl.StateValue.off
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
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
            {"aps":{"alert":"这是推送标题","body":"这是推送内容，这里的文字长度是有限制的","sound":"default","badge":1}}
            """
        envSwitch.state = NSControl.StateValue.off
    }
    
    @IBAction func clearAction(_ sender: Any) {
        teamIDTextField.stringValue = ""
        keyIDTextField.stringValue = ""
        p8KeyTextField.stringValue = ""
        bundleIDTextField.stringValue = ""
        deviceTokenTextField.stringValue = ""
        payLoadTextField.stringValue = ""
        envSwitch.state = NSControl.StateValue.off
    }
    
    @IBAction func sendAction(_ sender: NSButton) {
        
        let TEAM_ID = teamIDTextField.stringValue
        let KEY_ID = keyIDTextField.stringValue
        let P8 = p8KeyTextField.stringValue
        let BUNDLE_ID = bundleIDTextField.stringValue
        let DEVICE_TOKEN = deviceTokenTextField.stringValue
        let PAYLOAD = payLoadTextField.stringValue
        
        let url = (envSwitch.state == NSControl.StateValue.off) ? "https://api.development.push.apple.com/3/device/" : "https://api.push.apple.com/3/device/"
        
        guard !(TEAM_ID.isEmpty) else {
            resultLabel.stringValue = "Team ID 不能为空";
            return
        }
        
        guard !(KEY_ID.isEmpty) else {
            resultLabel.stringValue = "Key ID 不能为空";
            return
        }
        
        guard !(P8.isEmpty) else {
            resultLabel.stringValue = "P8证书 不能为空";
            return
        }
        
        guard !(BUNDLE_ID.isEmpty) else {
            resultLabel.stringValue = "Bundle ID 不能为空";
            return
        }
        
        guard !(DEVICE_TOKEN.isEmpty) else {
            resultLabel.stringValue = "DeviceToken 不能为空";
            return
        }
        
        guard !(PAYLOAD.isEmpty) else {
            resultLabel.stringValue = "Payload 不能为空";
            return
        }
        
        DispatchQueue.main.async {
            self.resultLabel.stringValue = ""
        }
        
        let jwt = JWT(keyID: KEY_ID, teamID: TEAM_ID, issueDate: Date(), expireDuration: 60 * 60)
        do {
            let token = try jwt.sign(with: P8)
            var request = URLRequest(url: URL(string: url + DEVICE_TOKEN)!)
            request.httpMethod = "POST"
            request.addValue("bearer \(token)", forHTTPHeaderField: "authorization")
            request.addValue(BUNDLE_ID, forHTTPHeaderField: "apns-topic")
            request.httpBody = PAYLOAD.data(using: .utf8)

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

