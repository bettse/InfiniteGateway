//
//  PortalDriver.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 9/18/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
import Cocoa

//Handles initial activation, requestion more token data, notification about new tokens

class PortalDriver : NSObject {
    
    static let magic : NSData = "(c) Disney 2013".dataUsingEncoding(NSASCIIStringEncoding)!
    static let secret : NSData = NSData(bytes: [0xAF, 0x62, 0xD2, 0xEC, 0x04, 0x91, 0x96, 0x8C, 0xC5, 0x2A, 0x1A, 0x71, 0x65, 0xF8, 0x65, 0xFE] as [UInt8], length: 0x10)
    
    var portalThread : NSThread?
    
    var portal : Portal {
        get {
            return Portal.singleton
        }
    }

    var presence = Dictionary<Message.LedPlatform, Array<UInt8>>()
    var loadingTokens : [UInt8:Token] = [:]
    
    override init() {
        super.init()
        portalThread = NSThread(target: portal, selector:"initUsb", object: nil)
        if let thread = portalThread {
            thread.start()
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceConnected:", name: "deviceConnected", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "incomingMessage:", name: "incomingMessage", object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceDisconnected:", name: "deviceDisconnected", object: nil)
    }

    func deviceConnected(notification: NSNotification) {
        portal.outputCommand(ActivateCommand())
    }
    
    /* General flow is such:
    Update (new token) -> request TagId
    get TagId -> create in memory token and request Block 0
    get block 0 -> request block n
    get block n -> request block n+1 if n+1 < Token.tokenSize
    */
    func incomingUpdate(update: Update) {
        var updateColor : NSColor = NSColor()
        if (update.direction == Update.Direction.Arriving) {
            updateColor = NSColor.whiteColor()
            presence[update.ledPlatform]?.append(update.nfcIndex)
            portal.outputCommand(TagIdCommand(nfcIndex: update.nfcIndex))
        } else if (update.direction == Update.Direction.Departing) {
            updateColor = NSColor.blackColor()
            if let pIndex = presence[update.ledPlatform]?.indexOf(update.nfcIndex) {
                presence[update.ledPlatform]?.removeAtIndex(pIndex)
            }
            let userInfo : [NSObject : AnyObject] = [
                "nfcIndex": Int(update.nfcIndex),
                "ledPlatform": Int(update.ledPlatform.rawValue)
            ]
            dispatch_async(dispatch_get_main_queue(), {
                NSNotificationCenter.defaultCenter().postNotificationName("tokenLeft", object: nil, userInfo: userInfo)
            })
            
        }
        
        portal.outputCommand(LightOnCommand(ledPlatform: update.ledPlatform, color: updateColor))
    }
    
    func incomingResponse(response: Response) {
        if let _ = response as? ActivateResponse {
            let report = Report(cmd: PresenceCommand())
            portal.output(report)
        } else if let response = response as? PresenceResponse {
            presence = response.details
        } else if let response = response as? TagIdResponse {
            loadingTokens[response.nfcIndex] = Token(tagId: response.tagId)
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

    func ledPlatformOfNfcIndex(nfcIndex: UInt8) -> Message.LedPlatform {
        var led = Message.LedPlatform.All
        for (ledPlatform, nfcIndices) in presence {
            if (nfcIndices.contains(nfcIndex)) {
                led = ledPlatform
            }
        }
        return led
    }
    
    func tokenRead(response: ReadResponse) {
        if let token = loadingTokens[response.nfcIndex] {
            token.load(response.blockNumber, blockData: response.blockData)
            if (token.complete()) {
                let userInfo : [NSObject : AnyObject] = [
                    "nfcIndex": Int(response.nfcIndex),
                    "ledPlatform": Int(ledPlatformOfNfcIndex(response.nfcIndex).rawValue),
                    "token": token
                ]
                dispatch_async(dispatch_get_main_queue(), {
                    NSNotificationCenter.defaultCenter().postNotificationName("tokenLoaded", object: nil, userInfo: userInfo)
                })
                loadingTokens.removeValueForKey(response.nfcIndex)
            } else {
                let nextBlock : UInt8 = token.nextBlock()
                portal.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, block: nextBlock))
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