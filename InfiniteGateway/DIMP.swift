//
//  DIMP.swift
//  DIMP
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
import AppKit

//Inherits from NSObject so we can use NSNotification center addObserver
class DIMP : NSObject {
    static let magic : NSData = "(c) Disney 2013".dataUsingEncoding(NSASCIIStringEncoding)!
    static let secret : NSData = NSData(bytes: [0xAF, 0x62, 0xD2, 0xEC, 0x04, 0x91, 0x96, 0x8C, 0xC5, 0x2A, 0x1A, 0x71, 0x65, 0xF8, 0x65, 0xFE] as [UInt8], length: 0x10)

    var portal : Portal
    var platform : [UInt8:Token] = [:]
    var presence = Dictionary<Message.LedPlatform, Array<UInt8>>()
    
    override init() {
        portal = Portal.singleton
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceConnected:", name: "deviceConnected", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "incomingMessage:", name: "incomingMessage", object: nil)
    }

    /* General flow is such:
     Update (new token) -> request TagId
     get TagId -> create in memory token and request Block 0
     get block 0 -> request block n
     get block n -> request block n+1 if n+1 < Token.tokenSize
    */
    func incomingUpdate(update: Update) {
        var updateColor : NSColor = NSColor()
        //TODO: Need to figure out how to update presence dictionary wen I get an update
        print(update, terminator: "\n")
        if (update.direction == Update.Direction.Arriving) {
            updateColor = NSColor.whiteColor()
            //In order to add tag to platform dictionary, we need its tagid
            portal.outputCommand(TagIdCommand(nfcIndex: update.nfcIndex))
        } else if (update.direction == Update.Direction.Departing) {
            updateColor = NSColor.blackColor()
            platform[update.nfcIndex] = nil
        }
        
        portal.outputCommand(LightOnCommand(ledPlatform: update.ledPlatform, color: updateColor))
    }
    
    func incomingResponse(response: Response) {        
        if let _ = response as? ActivateResponse {
            let report = Report(cmd: PresenceCommand())
            portal.output(report)
        } else if let response = response as? PresenceResponse {
            presence = response.details
            print(response, terminator: "\n")
        } else if let response = response as? TagIdResponse {
            print(response, terminator: "\n")
            platform[response.nfcIndex] = Token(tagId: response.tagId)
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
        
        if let token = platform[response.nfcIndex] {
            token.load(response.blockNumber, blockData: response.blockData)
            let nextBlock : UInt8 = blockNumber + 1
            
            //Request next block
            if (nextBlock < Token.blockCount) {
                portal.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, block: nextBlock))
            } else { //Completed token
                
                /*
                
                var led = Message.LedPlatform.All
                print("default led: \(led)")
                for (ledPlatform, nfcIndices) in presence {
                    if (nfcIndices.contains(response.nfcIndex)) {
                        led = ledPlatform
                    }
                }
                print("for loop led: \(led)")
                led = presence.reduce(led) { (var acc, pair) in return pair.1.contains(response.nfcIndex) ? pair.0 : acc }
                print("reduce led: \(led)")
                let lightCommand : Command = LightOnCommand(ledPlatform: led, color: NSColor.blackColor())
                
                
                portal.outputCommand(lightCommand)
                */

                print(token, terminator: "\n")
                token.save(false)
            }

        } //end if token
    }
    
    func deviceConnected(notification: NSNotification) {
        print("Device Connected", terminator: "\n")
        portal.outputCommand(ActivateCommand())
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
