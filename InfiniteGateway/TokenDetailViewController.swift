//
//  TokenDetailViewController.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 9/20/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Cocoa

class TokenDetailViewController : NSViewController {
    
    @IBOutlet weak var nameLabel: NSTextField?
    @IBOutlet weak var shapeLabel: NSTextField?
    @IBOutlet weak var generationLabel: NSTextField?
    @IBOutlet weak var experienceLabel: NSTextField?
    @IBOutlet weak var experience: NSSlider?
    @IBOutlet weak var levelLabel: NSTextField?
    @IBOutlet weak var uidLabel: NSTextField?
    @IBOutlet weak var skillLabel: NSTextField?
    
    let BINARY = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        // Do any additional setup after loading the view.
        let token = representedObject as! Token
        nameLabel?.stringValue = token.name
        shapeLabel?.stringValue = "\(token.model.shape)"
        generationLabel?.stringValue = "\(token.generation).0"
        experience?.integerValue = Int(token.experience)
        experienceLabel?.integerValue = Int(token.experience)
        levelLabel?.integerValue = Int(token.level)
        uidLabel?.stringValue = token.tagId.toHexString()
        skillLabel?.stringValue = String(token.skillTree, radix: BINARY)
        
        experience!.target = self
        experience!.action = #selector(TokenDetailViewController.experienceUpdate)
    }
    
    var token : Token {
        get {
            return representedObject as! Token
        }
    }
    
    @IBAction func saveToken(_ sender: AnyObject?) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        token.experience = UInt16(experience?.integerValue ?? 0)
        let encryptedToken = EncryptedToken(from: token)
        encryptedToken.dump(appDelegate.toyboxDirectory)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "tokenSaved"), object: nil, userInfo: nil)
        self.dismissViewController(self)
    }
    
    func experienceUpdate() {
        experienceLabel?.integerValue = (experience?.integerValue)!        
    }
}
