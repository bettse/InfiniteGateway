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

typealias tokenLoad = (Message.LedPlatform, Int, Token) -> Void
typealias tokenLeft = (Message.LedPlatform, Int) -> Void
class PortalDriver : NSObject {
    
    static let magic : Data = "(c) Disney 2013".data(using: String.Encoding.ascii)!
    static let secret : Data = Data(bytes: UnsafePointer<UInt8>([0xAF, 0x62, 0xD2, 0xEC, 0x04, 0x91, 0x96, 0x8C, 0xC5, 0x2A, 0x1A, 0x71, 0x65, 0xF8, 0x65, 0xFE] as [UInt8]), count: 0x10)
    static let singleton = PortalDriver()
    var portalThread : Thread?
    var portal : Portal = Portal.singleton

    var presence = Dictionary<Message.LedPlatform, [UInt8]>()
    var encryptedTokens : [UInt8:EncryptedToken] = [:]
    
    var loadTokenCallbacks : [tokenLoad] = []
    var leftTokenCallbacks : [tokenLeft] = []
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(PortalDriver.deviceConnected(_:)), name: NSNotification.Name(rawValue: "deviceConnected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PortalDriver.incomingMessage(_:)), name: NSNotification.Name(rawValue: "incomingMessage"), object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceDisconnected:", name: "deviceDisconnected", object: nil)
        
        portalThread = Thread(target: self.portal, selector:#selector(Portal.initUsb), object: nil)
        if let thread = portalThread {
            thread.start()
        }
    }
    
    func registerTokenLoaded(_ callback: @escaping tokenLoad) {
        loadTokenCallbacks.append(callback)
    }
    func registerTokenLeft(_ callback: @escaping tokenLeft) {
        leftTokenCallbacks.append(callback)
    }

    func deviceConnected(_ notification: Notification) {
        portal.outputCommand(ActivateCommand())
    }
    
    func incomingUpdate(_ update: Update) {
        var updateColor : NSColor = NSColor()
        if (update.direction == Update.Direction.arriving) {
            updateColor = NSColor.white
            updatePresence(update.ledPlatform, nfcIndex: update.nfcIndex)
            portal.outputCommand(TagIdCommand(nfcIndex: update.nfcIndex))
        } else if (update.direction == Update.Direction.departing) {
            updateColor = NSColor.black
            removePresence(update.ledPlatform, nfcIndex: update.nfcIndex)
            DispatchQueue.main.async(execute: {
                for callback in self.leftTokenCallbacks {
                    callback(update.ledPlatform, Int(update.nfcIndex))
                }
            })
        }        
        portal.outputCommand(LightOnCommand(ledPlatform: update.ledPlatform, color: updateColor))
    }
    
    func incomingResponse(_ response: Response) {
        if let _ = response as? ActivateResponse {
            portal.outputCommand(LightOnCommand(ledPlatform: .all, color: NSColor.black))
        } else if let response = response as? PresenceResponse {
            for (ledPlatform, nfcIndicies) in response.details {
                let temp = presence[ledPlatform] ?? [UInt8]() //Define if not already defined
                presence[ledPlatform] = temp + nfcIndicies
                for nfcIndex in nfcIndicies { //Get data for existing tokens
                    portal.outputCommand(TagIdCommand(nfcIndex: nfcIndex))
                }
            }
        } else if let response = response as? TagIdResponse {
            encryptedTokens[response.nfcIndex] = EncryptedToken(tagId: response.tagId)
            let report = Report(cmd: ReadCommand(nfcIndex: response.nfcIndex, block: 0))
            portal.output(report)
        } else if let response = response as? ReadResponse {
            tokenRead(response)
        } else if let response = response as? WriteResponse {
            print(response)
        } else if let _ = response as? LightOnResponse {
        } else if let _ = response as? LightFadeResponse {
        } else if let _ = response as? LightFlashResponse {
        } else {
            print("Received \(response) for command \(response.command)", terminator: "\n")
        }
        
    }

    func ledPlatformOfNfcIndex(_ nfcIndex: UInt8) -> Message.LedPlatform {
        var led = Message.LedPlatform.none
        for (ledPlatform, nfcIndices) in presence {
            if (nfcIndices.contains(nfcIndex)) {
                led = ledPlatform
            }
        }
        return led
    }
    
    func updatePresence(_ ledPlatform: Message.LedPlatform, nfcIndex: UInt8) {
        presence[ledPlatform] = presence[ledPlatform] ?? [UInt8]() //Define if not already defined
        if var nfcIndicies = presence[ledPlatform] {
            nfcIndicies.append(nfcIndex)
        }
    }
    
    func removePresence(_ ledPlatform: Message.LedPlatform, nfcIndex: UInt8) {
        presence[ledPlatform] = presence[ledPlatform] ?? [UInt8]() //Define if not already defined
        if var nfcIndicies = presence[ledPlatform] {
            if let nfcFound = nfcIndicies.index(of: nfcIndex) {
                nfcIndicies.remove(at: nfcFound)
            }
        }
        
    }
    
    func tokenRead(_ response: ReadResponse) {
        if let token = encryptedTokens[response.nfcIndex] {
            token.load(response.blockNumber, blockData: response.blockData)
            if (token.complete()) {
                let ledPlatform = ledPlatformOfNfcIndex(response.nfcIndex)
                portal.outputCommand(LightOnCommand(ledPlatform: ledPlatform, color: NSColor.green))
                DispatchQueue.main.async(execute: {
                    for callback in self.loadTokenCallbacks {
                        callback(ledPlatform, Int(response.nfcIndex), token.decryptedToken)
                    }
                })
                encryptedTokens.removeValue(forKey: response.nfcIndex)
            } else {
                let nextBlock = token.nextBlock()
                portal.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, block: nextBlock))
            }
        } //end if token
    }
    
    func incomingMessage(_ notification: Notification) {
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
