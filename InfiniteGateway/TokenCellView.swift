//
//  TokenCellView.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 9/24/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Cocoa

class TokenCellView : NSTableCellView {
    @IBOutlet weak var uidLabel: NSTextField!
    @IBOutlet weak var modelLabel: NSTextField!
    @IBOutlet weak var generationLabel: NSTextField!
    @IBOutlet weak var levelLabel: NSTextField!
    @IBOutlet weak var shapeLabel: NSTextField!
    @IBOutlet weak var nfcLabel: NSTextField!
    
    weak var representedObject : AnyObject? {
        didSet {
            let token = representedObject as! Token
            self.uidLabel.stringValue = "\(token.uid.hexadecimalString)"
            self.modelLabel.stringValue = "\(token.model.name)"
            self.generationLabel.stringValue = "\(token.model.generation).0"
            self.levelLabel.stringValue = "Level \(token.level)"
            self.shapeLabel.stringValue = "\(token.model.shape.desc())"
        }
    }

}