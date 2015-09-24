//
//  LibraryTabViewController.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 9/24/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Cocoa

class LibraryTabViewController: NSViewController {
    @IBOutlet weak var libraryTable: NSTableView?
    @IBOutlet weak var modelSelection: NSComboBox?

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "TokenDetail") {
            if let tokenDetailViewController = segue.destinationController as? TokenDetailViewController {
                if let token = sender as? Token {
                    tokenDetailViewController.representedObject = token
                } else {
                }
            }
        }
    }
    
    @IBAction func buildBlank(sender: AnyObject?) {
        if let comboBox = modelSelection {
            var modelId = 0
            let index = comboBox.indexOfSelectedItem
            if (index == -1) { //Write in
                modelId = comboBox.integerValue
            } else {
                modelId = ThePoster.models[index].id
            }
            let t = Token(modelId: modelId)
            let et = EncryptedToken(from: t)
            et.dump()
        }
    }
    
    
    @IBAction func openFile(sender: AnyObject?) {
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        let response = myFileDialog.runModal()
        if(response == NSModalResponseOK){
            if let image = NSData(contentsOfURL: myFileDialog.URL!) {
                if (image.length == MifareMini.tokenSize) {
                    let token = EncryptedToken(tagId: image.subdataWithRange(NSMakeRange(0, 7)))
                    token.data = image.mutableCopy() as! NSMutableData
                    if (token.complete()) {
                        let userInfo : [String : AnyObject] = [
                            "nfcIndex": -1,
                            "token": token.decryptedToken
                        ]
                        dispatch_async(dispatch_get_main_queue(), {
                            NSNotificationCenter.defaultCenter().postNotificationName("tokenLoaded", object: nil, userInfo: userInfo)
                        })
                    }
                }
            }
        }
    }
}



// MARK: - NSComboBoxDataSource
extension LibraryTabViewController: NSComboBoxDataSource {
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        return ThePoster.models.count
    }
    
    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
        return ThePoster.models[index].description
    }
}
