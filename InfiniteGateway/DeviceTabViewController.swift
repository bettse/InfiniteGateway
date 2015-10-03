//
//  DeviceTabViewController.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 9/24/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//


import Cocoa

class DeviceTabViewController: NSViewController {
    @IBOutlet weak var status: NSTextField?
    @IBOutlet weak var nfcTable: NSTableView?
    
    var nfcMap : [Int:Token] = [:]
    
    var portalDriver : PortalDriver = PortalDriver.singleton
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nfcTable!.registerNib(NSNib(nibNamed: "TokenCellView", bundle: nil), forIdentifier: "TokenCellView")

        // Do any additional setup after loading the view.
        status?.stringValue = "Portal Disconnected"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceConnected:", name: "deviceConnected", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceDisconnected:", name: "deviceDisconnected", object: nil)
        
        portalDriver.registerTokenLoaded(self.tokenLoaded)
        portalDriver.registerTokenLeft(self.tokenLeft)
        
        self.nfcTable?.doubleAction = "tableViewDoubleAction"
        self.nfcTable?.target = self
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    func tokenLoaded(ledPlatform: Message.LedPlatform, nfcIndex: Int, token: Token) {
        if (nfcIndex == -1) { //token from disk image
            self.performSegueWithIdentifier("TokenDetail", sender: token)
        } else {
            nfcMap[Int(nfcIndex)] = token
        }
        if let table = nfcTable {
            table.reloadData()
        }
    }
    
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "TokenDetail") {
            if let tokenDetailViewController = segue.destinationController as? TokenDetailViewController {
                if let table = nfcTable {
                    if let token = nfcMap[table.selectedRow] {
                        tokenDetailViewController.representedObject = token
                    }
                }
            }
        }
    }
    
    
    func tableViewDoubleAction() {
        self.performSegueWithIdentifier("TokenDetail", sender: self)
    }
    
    
    func deviceDisconnected(notification: NSNotification) {
        status?.stringValue = "Portal Disconnected"
    }
    
    func deviceConnected(notification: NSNotification) {
        status?.stringValue = "Portal Connected"
    }
    
    func tokenLeft(ledPlatform: Message.LedPlatform, nfcIndex: Int) {
        if (nfcMap.keys.contains(nfcIndex)) {
            nfcMap.removeValueForKey(nfcIndex)
        }

        if let table = nfcTable {
            table.reloadData()
        }
    }

}


// MARK: - NSTableViewDataSource
extension DeviceTabViewController: NSTableViewDataSource {
    func tableView(tableView: NSTableView, viewForTableColumn: NSTableColumn?, row: Int) -> NSView? {
        let tokens : [Token] = Array(nfcMap.values)
        let token = tokens[row]
        if let cell = tableView.makeViewWithIdentifier("TokenCellView", owner: self) as? TokenCellView {
            cell.representedObject = token
            cell.nfcLabel.stringValue = "NFC Index #\(row)"
            return cell
        }
        return nil
    }
}

extension DeviceTabViewController: NSTableViewDelegate {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return nfcMap.values.count
    }
    
    //https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSTableViewDelegate_Protocol/#//apple_ref/occ/intfm/NSTableViewDelegate/tableView:rowActionsForRow:edge:
    @available(OSX 10.11, *)
    func tableView(tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableRowActionEdge) -> [NSTableViewRowAction] {
        return []
    }
}
