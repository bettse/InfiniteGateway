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
        nfcTable!.register(NSNib(nibNamed: "TokenCellView", bundle: nil), forIdentifier: "TokenCellView")

        // Do any additional setup after loading the view.
        status?.stringValue = "Portal Disconnected"
        
        NotificationCenter.default.addObserver(self, selector: #selector(DeviceTabViewController.deviceConnected(_:)), name: NSNotification.Name(rawValue: "deviceConnected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DeviceTabViewController.deviceDisconnected(_:)), name: NSNotification.Name(rawValue: "deviceDisconnected"), object: nil)
        
        portalDriver.registerTokenLoaded(self.tokenLoaded)
        portalDriver.registerTokenLeft(self.tokenLeft)
        
        self.nfcTable?.doubleAction = #selector(DeviceTabViewController.tableViewDoubleAction)
        self.nfcTable?.target = self
    }

    func tokenLoaded(_ ledPlatform: Message.LedPlatform, nfcIndex: Int, token: Token) {
        if (nfcIndex == -1) { //token from disk image
            self.performSegue(withIdentifier: "TokenDetail", sender: token)
        } else {
            nfcMap[Int(nfcIndex)] = token
        }
        if let table = nfcTable {
            table.reloadData()
        }
    }
    
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
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
        self.performSegue(withIdentifier: "TokenDetail", sender: self)
    }
    
    func deviceDisconnected(_ notification: Notification) {
        status?.stringValue = "Portal Disconnected"
    }
    
    func deviceConnected(_ notification: Notification) {
        status?.stringValue = "Portal Connected"
    }
    
    func tokenLeft(_ ledPlatform: Message.LedPlatform, nfcIndex: Int) {
        if (nfcMap.keys.contains(nfcIndex)) {
            nfcMap.removeValue(forKey: nfcIndex)
        }

        if let table = nfcTable {
            table.reloadData()
        }
    }
}


// MARK: - NSTableViewDataSource
extension DeviceTabViewController: NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, viewFor viewForTableColumn: NSTableColumn?, row: Int) -> NSView? {
        let tokens : [Token] = Array(nfcMap.values)
        let token = tokens[row]
        if let cell = tableView.make(withIdentifier: "TokenCellView", owner: self) as? TokenCellView {
            cell.representedObject = token
            cell.nfcLabel.stringValue = "NFC Index #\(row)"
            return cell
        }
        return nil
    }
}

extension DeviceTabViewController: NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return nfcMap.values.count
    }
    
    //https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSTableViewDelegate_Protocol/#//apple_ref/occ/intfm/NSTableViewDelegate/tableView:rowActionsForRow:edge:
    @available(OSX 10.11, *)
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableRowActionEdge) -> [NSTableViewRowAction] {
        return []
    }
}
