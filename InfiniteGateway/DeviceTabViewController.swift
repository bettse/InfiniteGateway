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
        self.nfcTable?.register(NSNib(nibNamed: "TokenCellView", bundle: nil), forIdentifier: "TokenCellView")

        // Do any additional setup after loading the view.
        status?.stringValue = "Portal Disconnected"
        
        portalDriver.registerDeviceCallback("ready") { () in
            self.status?.stringValue = "Portal Ready"
        }
        
        portalDriver.registerDeviceCallback("connected") { () in
            self.status?.stringValue = "Portal Connected"
        }
        
        portalDriver.registerDeviceCallback("disconnected") { () in
            self.status?.stringValue = "Portal Disconnected"
        }
        
        portalDriver.registerTokenCallback("complete", callback: self.tokenComplete)
        portalDriver.registerTokenCallback("left", callback: self.tokenLeft)
        
        self.nfcTable?.doubleAction = #selector(DeviceTabViewController.tableViewDoubleAction)
        self.nfcTable?.target = self
    }
    
    func tokenComplete(_ ledPlatform: Message.LedPlatform, nfcIndex: Int, token: Token?) {
        if let token = token {
            if (nfcIndex == -1) { //token from disk image
                self.performSegue(withIdentifier: "TokenDetail", sender: token)
            } else {
                nfcMap[nfcIndex] = token
            }
            if let table = nfcTable {
                table.reloadData()
            }
        }
    }
    
    func tokenLeft(_ ledPlatform: Message.LedPlatform, nfcIndex: Int, token: Token?) {
        if (nfcMap.keys.contains(nfcIndex)) {
            nfcMap.removeValue(forKey: nfcIndex)
        }
        
        if let table = nfcTable {
            table.reloadData()
        }
    }
    
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch (segue.identifier!) {
            case "TokenDetail":
                guard let table = nfcTable else {
                    log.error("No nfcTable")
                    return
                }
                guard let token = nfcMap[table.selectedRow] else {
                    log.error("No selected token")
                    return
                }
                guard let tokenDetailViewController = segue.destinationController as? TokenDetailViewController  else {
                    log.error("No tokenDetailViewController")
                    return
                }
                tokenDetailViewController.representedObject = token
                break
        default:
            log.error("Unhandled segue: \(segue.identifier)")
        }
    }
    
    func tableViewDoubleAction() {
        self.performSegue(withIdentifier: "TokenDetail", sender: self)
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
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return MyNSTableRowView()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return nfcMap.values.count
    }
    
    //https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSTableViewDelegate_Protocol/#//apple_ref/occ/intfm/NSTableViewDelegate/tableView:rowActionsForRow:edge:
    @available(OSX 10.11, *)
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableRowActionEdge) -> [NSTableViewRowAction] {
        return []
    }
}
