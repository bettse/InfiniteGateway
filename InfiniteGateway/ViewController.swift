//
//  ViewController.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 9/17/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSComboBoxDataSource {

    @IBOutlet weak var status: NSTextField?
    @IBOutlet weak var nfcTable: NSTableView?
    @IBOutlet weak var modelSelection: NSComboBox?
    
    var nfcMap : [Int:Token] = [:]
    
    var portal : Portal {
        get {
            return Portal.singleton
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        status?.stringValue = "Portal Disconnected"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceConnected:", name: "deviceConnected", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceDisconnected:", name: "deviceDisconnected", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "tokenLoaded:", name: "tokenLoaded", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "tokenLeft:", name: "tokenLeft", object: nil)
        
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func buildBlank(sender: AnyObject?) {
        if let comboBox = modelSelection {
            let index = comboBox.indexOfSelectedItem
            let model = ThePoster.models[index]
            let t = Token(modelId: model.id)
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
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "TokenDetail") {
            if let tokenDetailViewController = segue.destinationController as? TokenDetailViewController {
                if let token = sender as? Token {
                    tokenDetailViewController.representedObject = token
                } else {
                    if let table = nfcTable {
                        if let token = nfcMap[table.selectedRow] {
                            tokenDetailViewController.representedObject = token
                        }
                    }
                }
            }
        }
    }
    

    func deviceDisconnected(notification: NSNotification) {
        status?.stringValue = "Portal Disconnected"
    }
    
    func deviceConnected(notification: NSNotification) {
        status?.stringValue = "Portal Connected"
    }
    
    func tokenLoaded(notificaiton: NSNotification) {
        if let userInfo = notificaiton.userInfo {
            if let token = userInfo["token"] as? Token {
                if let nfcIndex = userInfo["nfcIndex"] as? Int {
                    if (nfcIndex == -1) { //token from disk image
                        self.performSegueWithIdentifier("TokenDetail", sender: token)
                    } else {
                        nfcMap[nfcIndex] = token
                    }
                }
            }
        }
        if let table = nfcTable {
            table.reloadData()
        }
    }
    
    func tokenLeft(notificaiton: NSNotification) {
        if let userInfo = notificaiton.userInfo {
            if let nfcIndex = userInfo["nfcIndex"] as? Int {
                nfcMap.removeValueForKey(nfcIndex)
            }
        }
        if let table = nfcTable {
            table.reloadData()
        }
    }
    
    // MARK: - NSTable stuff
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return nfcMap.values.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn: NSTableColumn?, row: Int) -> NSView? {
        let tokens : [Token] = Array(nfcMap.values)
        let token = tokens[row]
        if let cell = tableView.makeViewWithIdentifier(viewForTableColumn!.identifier, owner: self) as? NSTableCellView {
            cell.textField!.stringValue = "\(token.name): Level \(token.level) [\(token.experience)]"
            return cell
        }
        return nil
    }
 
    
    // MARK: - NSComboBoxDataSource
    
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        return ThePoster.models.count
    }
    
    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
        return ThePoster.models[index].name
    }

}

