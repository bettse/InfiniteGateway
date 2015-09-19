//
//  ViewController.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 9/17/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var status: NSTextField?
    @IBOutlet weak var nfcTable: NSTableView?
    var nfcMap : [UInt8:Token] = [:]
    
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
                    nfcMap[UInt8(nfcIndex)] = token
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
                nfcMap.removeValueForKey(UInt8(nfcIndex))
            }
        }
        if let table = nfcTable {
            table.reloadData()
        }
    }
    
    // MARK: - NSTable stuff
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return nfcMap.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let token = nfcMap[UInt8(row)] {
            if let cell = tableView.makeViewWithIdentifier("tableCell", owner: self) as? NSTableCellView {
                cell.textField!.stringValue = token.description
                return cell
            }
        }
        return nil
    }
 
    
    // MARK: - Portal interaction methods
    
    


}

