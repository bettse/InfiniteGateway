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
        uidLabel?.stringValue = token.tagId.hexadecimalString as String
        skillLabel?.stringValue = String(token.skillTree, radix: BINARY)
        
        experience!.target = self
        experience!.action = "experienceUpdate"
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
            //let token = representedObject as! Token
            //print("represented object is \(token)")
        }
    }
    
    var token : Token {
        get {
            return representedObject as! Token
        }
    }

    
    @IBAction func saveToken(sender: AnyObject?) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let token = representedObject as! Token
        token.experience = UInt16((experience?.integerValue)!)
        let encryptedToken = EncryptedToken(from: token)
        encryptedToken.dump(appDelegate.toyboxDirectory)
    }
    
    func experienceUpdate() {
        experienceLabel?.integerValue = (experience?.integerValue)!        
    }
}