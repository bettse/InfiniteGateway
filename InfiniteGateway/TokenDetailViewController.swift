//
//  TokenDetailViewController.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 9/20/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Cocoa

class TokenDetailViewController : NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()        
        // Do any additional setup after loading the view.
        print("\(self.description) loaded")
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
            print("represented object is \(representedObject)")
        }

    }

}