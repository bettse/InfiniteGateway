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

    var fileList : [Token] {
        get {
            var tokens : [Token] = [Token]()
            let fileManager = NSFileManager()
            let files = fileManager.enumeratorAtURL(toyboxDirectory, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, errorHandler: nil)
            while let file = files?.nextObject() as? NSURL {
                if file.absoluteString.hasSuffix("bin") { // checks the extension
                    if let image = NSData(contentsOfURL: file) {
                        if (image.length == MifareMini.tokenSize) {
                            let et : EncryptedToken = EncryptedToken(image: image)
                            tokens.append(et.decryptedToken)
                        }
                    }
                }
            }
            return tokens
        }
    }
    
    var applicationDirectory : NSURL {
        get {
            let bundleId = NSBundle.mainBundle().bundleIdentifier
            let fileManager = NSFileManager.defaultManager()
            var dirPath : NSURL
            let applicationSupportDir = fileManager.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
            if applicationSupportDir.count > 0 {
                dirPath = applicationSupportDir[0].URLByAppendingPathComponent(bundleId!)
                do {
                    try fileManager.createDirectoryAtURL(dirPath, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    NSLog("\(error.localizedDescription)")
                }
                return dirPath
            }
            return NSURL()
        }
    }
    
    var toyboxDirectory : NSURL {
        get {
            let toyboxName = "Toybox"
            let fileManager = NSFileManager.defaultManager()
            let dirPath : NSURL = applicationDirectory.URLByAppendingPathComponent(toyboxName)
            do {
                try fileManager.createDirectoryAtURL(dirPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                NSLog("\(error.localizedDescription)")
            }
            return dirPath
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.libraryTable?.doubleAction = "tableViewDoubleAction"
        self.libraryTable?.target = self
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

    func tableViewDoubleAction() {
        self.performSegueWithIdentifier("TokenDetail", sender: self)
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



// MARK: - NSTableViewDataSource
extension LibraryTabViewController: NSTableViewDataSource {
    func tableView(tableView: NSTableView, viewForTableColumn: NSTableColumn?, row: Int) -> NSView? {
        let token : Token = fileList[row]
        if let cell = tableView.makeViewWithIdentifier(viewForTableColumn!.identifier, owner: self) as? NSTableCellView {
            cell.textField!.stringValue = token.shortDisplay
            return cell
        }
        return nil
    }
}

extension LibraryTabViewController: NSTableViewDelegate {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return fileList.count
    }
    
    //https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSTableViewDelegate_Protocol/#//apple_ref/occ/intfm/NSTableViewDelegate/tableView:rowActionsForRow:edge:
    @available(OSX 10.11, *)
    func tableView(tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableRowActionEdge) -> [NSTableViewRowAction] {
        return []
    }
}
