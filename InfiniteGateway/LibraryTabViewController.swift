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
            let fileManager = FileManager()
            let appDelegate = NSApplication.shared().delegate as! AppDelegate

            let files = fileManager.enumerator(at: appDelegate.toyboxDirectory as URL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles, errorHandler: nil)
            while let file = files?.nextObject() as? URL {
                if file.absoluteString.hasSuffix("bin") { // checks the extension
                    if let image = try? Data(contentsOf: file) {
                        if (image.count == MifareMini.tokenSize) {
                            let et : EncryptedToken = EncryptedToken(image: image)
                            _fileList!.append(et.decryptedToken)
                        }
                    }
                }
            }
            return _fileList!.sorted(by: { $0.model.description < $1.model.description })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        libraryTable!.register(NSNib(nibNamed: "TokenCellView", bundle: nil), forIdentifier: "TokenCellView")

        self.libraryTable?.target = self
        self.libraryTable?.doubleAction = #selector(LibraryTabViewController.tableViewDoubleAction)
        NotificationCenter.default.addObserver(self, selector: #selector(LibraryTabViewController.bustFileList(_:)), name: NSNotification.Name(rawValue: "tokenSaved"), object: nil)
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func bustFileList(_ notification: Notification) {
        self._fileList = nil
        self.libraryTable?.reloadData()
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
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
        self.performSegue(withIdentifier: "TokenDetail", sender: self)
    }
    
    @IBAction func buildBlank(_ sender: AnyObject?) {
        if let comboBox = modelSelection {
            var modelId = 0
            let index = comboBox.indexOfSelectedItem
            if (index == -1) { //Write in
                modelId = comboBox.integerValue
            } else {
                modelId = ThePoster.models[index].id
            }
            if (modelId == 0) {
                print("buildBlank couldn't set modelId")
                return
            }
            let t = Token(modelId: modelId)
            let et = EncryptedToken(from: t)
            let appDelegate = NSApplication.shared().delegate as! AppDelegate
            et.dump(appDelegate.toyboxDirectory)
        }
    }
        
}



// MARK: - NSComboBoxDataSource
extension LibraryTabViewController: NSComboBoxDataSource {
    func numberOfItems(in aComboBox: NSComboBox) -> Int {
        return ThePoster.models.count
    }
    
    func comboBox(_ aComboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return ThePoster.models[index].description
    }
}


// MARK: - NSTableViewDataSource
extension LibraryTabViewController: NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, viewFor viewForTableColumn: NSTableColumn?, row: Int) -> NSView? {
        let token : Token = fileList[row]
        if let cell = tableView.make(withIdentifier: "TokenCellView", owner: self) as? TokenCellView {
            cell.representedObject = token
            return cell
        }
        return nil
    }
}

extension LibraryTabViewController: NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fileList.count
    }
    
    //https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSTableViewDelegate_Protocol/#//apple_ref/occ/intfm/NSTableViewDelegate/tableView:rowActionsForRow:edge:
    @available(OSX 10.11, *)
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableRowActionEdge) -> [NSTableViewRowAction] {
        return []
    }
}
