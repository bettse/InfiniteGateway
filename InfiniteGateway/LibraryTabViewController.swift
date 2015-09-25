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

    var _fileList : [Token]?
    var fileList : [Token] {
        get {
            //Simplistic memoization
            if (_fileList != nil) {
                return _fileList!
            }            
            _fileList = [Token]()
            let fileManager = NSFileManager()
            let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate

            let files = fileManager.enumeratorAtURL(appDelegate.toyboxDirectory, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, errorHandler: nil)
            while let file = files?.nextObject() as? NSURL {
                if file.absoluteString.hasSuffix("bin") { // checks the extension
                    if let image = NSData(contentsOfURL: file) {
                        if (image.length == MifareMini.tokenSize) {
                            let et : EncryptedToken = EncryptedToken(image: image)
                            _fileList!.append(et.decryptedToken)
                        }
                    }
                }
            }
            return _fileList!.sort({ $0.model.description < $1.model.description })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        libraryTable!.registerNib(NSNib(nibNamed: "TokenCellView", bundle: nil), forIdentifier: "TokenCellView")

        self.libraryTable?.target = self
        self.libraryTable?.doubleAction = "tableViewDoubleAction"
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "bustFileList:", name: "tokenSaved", object: nil)
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func bustFileList(notification: NSNotification) {
        self._fileList = nil
        self.libraryTable?.reloadData()
    }

    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "TokenDetail") {
            if let tokenDetailViewController = segue.destinationController as? TokenDetailViewController {
                if let table = libraryTable {
                    let token = fileList[table.selectedRow]
                    tokenDetailViewController.representedObject = token
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
            let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
            et.dump(appDelegate.toyboxDirectory)
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
        if let cell = tableView.makeViewWithIdentifier("TokenCellView", owner: self) as? TokenCellView {
            cell.representedObject = token
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
