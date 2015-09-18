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
    var presence = Dictionary<Message.LedPlatform, Array<UInt8>>()
    
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "incomingMessage:", name: "incomingMessage", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceDisconnected:", name: "deviceDisconnected", object: nil)
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func deviceConnected(notification: NSNotification) {
        //We set the connected status when we get a response
        portal.outputCommand(ActivateCommand())
    }
    func deviceDisconnected(notification: NSNotification) {
        status?.stringValue = "Portal Disconnected"
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
    
    
    /* General flow is such:
    Update (new token) -> request TagId
    get TagId -> create in memory token and request Block 0
    get block 0 -> request block n
    get block n -> request block n+1 if n+1 < Token.tokenSize
    */
    func incomingUpdate(update: Update) {
        var updateColor : NSColor = NSColor()
        if (update.direction == Update.Direction.Arriving) {
            presence[update.ledPlatform]?.append(update.nfcIndex)
            updateColor = NSColor.whiteColor()
            //In order to add tag to platform dictionary, we need its tagid
            portal.outputCommand(TagIdCommand(nfcIndex: update.nfcIndex))
        } else if (update.direction == Update.Direction.Departing) {
            nfcMap.removeValueForKey(update.nfcIndex)
            if let pIndex = presence[update.ledPlatform]?.indexOf(update.nfcIndex) {
                presence[update.ledPlatform]?.removeAtIndex(pIndex)
            }
            updateColor = NSColor.blackColor()
            if let table = nfcTable {
                table.reloadData()
            }
        }
        
        portal.outputCommand(LightOnCommand(ledPlatform: update.ledPlatform, color: updateColor))
    }
    
    func incomingResponse(response: Response) {
        if let _ = response as? ActivateResponse {
            status?.stringValue = "Portal Connected"
            let report = Report(cmd: PresenceCommand())
            portal.output(report)
        } else if let response = response as? PresenceResponse {
            presence = response.details
        } else if let response = response as? TagIdResponse {
            nfcMap[response.nfcIndex] = Token(tagId: response.tagId)
            let report = Report(cmd: ReadCommand(nfcIndex: response.nfcIndex, block: 0))
            portal.output(report)
        } else if let response = response as? ReadResponse {
            tokenRead(response)
        } else if let _ = response as? WriteResponse {
            //Idea: DIMP (business logic) always writes to protal any new token data, then the
            //write response is used to kick off a read of that block, which then updates the in
            //memory token.
            //Counterpoint: DIMP needs to know what the block data would look like; or Token needs to be
            //updated first (setSkill(...)) then have a "getChangedBlocks" and have DIMP loop and send them
        } else if let _ = response as? LightOnResponse {
        } else if let _ = response as? LightFadeResponse {
        } else if let _ = response as? LightFlashResponse {
        } else {
            print("Received \(response) for command \(response.command)", terminator: "\n")
        }
        
    }
    
    func tokenRead(response: ReadResponse) {
        let blockNumber = response.blockNumber
        if let token = nfcMap[response.nfcIndex] {
            token.load(response.blockNumber, blockData: response.blockData)
            let nextBlock : UInt8 = blockNumber + 1
            if (nextBlock < Token.blockCount) {
                portal.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, block: nextBlock))
            } else { //Completed token
                if let table = nfcTable {
                    table.reloadData()
                }
                //token.save(false)
            }
        } //end if token
    }
    
    func incomingMessage(notification: NSNotification) {
        let userInfo = notification.userInfo
        if let message = userInfo?["message"] as? Message {
            if let update = message as? Update {
                incomingUpdate(update)
            } else if let response = message as? Response {
                incomingResponse(response)
            }
        }
    }


}

