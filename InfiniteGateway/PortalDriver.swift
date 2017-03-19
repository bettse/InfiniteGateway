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

typealias tokenEvent = (Message.LedPlatform, Int, Token?) -> Void
typealias deviceEvent = (Void) -> Void

class PortalDriver : NSObject {
    static let magic : Data = "(c) Disney 2013".data(using: String.Encoding.ascii)!
    static let secret : Data = Data(bytes: [0xAF, 0x62, 0xD2, 0xEC, 0x04, 0x91, 0x96, 0x8C, 0xC5, 0x2A, 0x1A, 0x71, 0x65, 0xF8, 0x65, 0xFE])
    static let singleton = PortalDriver()
    var portalThread : Thread?
    var portal : Portal = Portal.singleton
    
    var presence : [UInt8:Detail] = [:]
    var encryptedTokens : [UInt8:EncryptedToken] = [:]
    
    var tokenCallbacks : [String:[tokenEvent]] = [:]
    var deviceCallbacks : [String:[deviceEvent]] = [:]
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(PortalDriver.deviceConnected(_:)), name: NSNotification.Name(rawValue: "deviceConnected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PortalDriver.deviceDisconnected(_:)), name: NSNotification.Name(rawValue: "deviceDiscnnected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PortalDriver.incomingMessage(_:)), name: NSNotification.Name(rawValue: "incomingMessage"), object: nil)        
        
        self.registerDeviceCallback("connected", callback: self.activatePortal)
        
        portalThread = Thread(target: self.portal, selector:#selector(Portal.initUsb), object: nil)
        if let thread = portalThread {
            thread.start()
        }
    }
    
    func registerTokenCallback(_ event: String, callback: @escaping tokenEvent) {
        tokenCallbacks[event] = tokenCallbacks[event] ?? []
        tokenCallbacks[event]?.append(callback)
    }

    func fireTokenCallbacks(event: String, detail: Detail, token: Token?) {
        DispatchQueue.main.async(execute: {
            for callback in self.tokenCallbacks[event] ?? [] {
                callback(detail.platform, Int(detail.nfcIndex), token)
            }
        })
    }
    
    func registerDeviceCallback(_ event: String, callback: @escaping deviceEvent) {
        deviceCallbacks[event] = deviceCallbacks[event] ?? []
        deviceCallbacks[event]?.append(callback)
    }
    
    
    func fireDeviceCallbacks(event: String) {
        DispatchQueue.main.async(execute: {
            for callback in self.deviceCallbacks[event] ?? [] {
                callback()
            }
        })
    }
    
    func deviceConnected(_ notification: Notification) {
        fireDeviceCallbacks(event: "connected")
    }

    func deviceDisconnected(_ notification: Notification) {
        fireDeviceCallbacks(event: "disconnected")
    }
    
    
    // Start of "Business logic" //
    
    func activatePortal() {
        portal.outputCommand(ActivateCommand())
    }
    
    func incomingUpdate(_ update: Update) {
        log.debug(update)
        var updateColor : NSColor = NSColor()
        if (update.direction == Update.Direction.arriving) {
            updateColor = NSColor.white
            let detail = Detail(nfcIndex: update.nfcIndex, platform: update.ledPlatform, sak: update.sak)
            presence[update.nfcIndex] = detail
            portal.outputCommand(TagIdCommand(nfcIndex: update.nfcIndex))
            fireTokenCallbacks(event: "loaded", detail: detail, token: nil)
        } else if (update.direction == Update.Direction.departing) {
            updateColor = NSColor.black
            if let detail = presence[update.nfcIndex] {
                fireTokenCallbacks(event: "left", detail: detail, token: nil)
                presence.removeValue(forKey: update.nfcIndex)
            }
        }        
        portal.outputCommand(LightSetCommand(ledPlatform: update.ledPlatform, color: updateColor))
    }
    
    func incomingResponse(_ response: Response) {
        if let response = response as? AckResponse {
            log.debug(response)
        } else if let _ = response as? ActivateResponse {
            log.debug(response)
            portal.outputCommand(PresenceCommand())
        } else if let response = response as? PresenceResponse {
            log.debug(response)
            portal.outputCommand(LightSetCommand(ledPlatform: .all, color: NSColor.black))
            for detail in response.details {
                presence[detail.nfcIndex] = detail
                portal.outputCommand(TagIdCommand(nfcIndex: detail.nfcIndex))
            }
        } else if let response = response as? TagIdResponse {
            log.debug(response)
            let detail = presence[response.nfcIndex]
            encryptedTokens[response.nfcIndex] = EncryptedToken(tagId: response.tagId)
            if (detail?.sak == .mifareMini) {
                portal.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, sectorNumber: 0, blockNumber: 0))
            }
        } else if let response = response as? ReadResponse {
            log.debug(response)
            if (response.status == .success) {
                tokenRead(response)
            }
        } else if let response = response as? A4Response {
            log.debug(response)
            portal.outputCommand(ReadCommand(command: response.command as! BlockCommand))
        } else if let response = response as? B8Response {
            log.debug(response)            
        } else if let response = response as? B9Response {
            log.debug(response)
        } else if let response = response as? StatusResponse { //StatuResponse must be last becuase it is a parent class of other classes
            log.debug(response)
            // Handle status responses by detecting their command type and acting on it
            incomingStatus(response)
        } else {
            log.debug("Received \(response) for command \(response.command)")
        }
    }
    
    func incomingStatus(_ response: StatusResponse) {
        if let command = response.command as? A5Command {
            portal.outputCommand(A4Command(command: command))
        } else if let _ = response.command as? C1Command {
            self.portal.outputCommand(C0Command())
        }
    }

    func tokenRead(_ response: ReadResponse) {
        if let token = encryptedTokens[response.nfcIndex] {
            token.load(response.blockNumber, blockData: response.blockData)
            if (token.complete()) {
                let ledPlatform = presence[response.nfcIndex]?.platform ?? .none
                if (token.decryptedToken != nil) {
                    portal.outputCommand(LightSetCommand(ledPlatform: ledPlatform, color: NSColor.green))
                    DispatchQueue.main.async(execute: {
                        for callback in self.tokenCallbacks["complete"] ?? [] {
                            callback(ledPlatform, Int(response.nfcIndex), token.decryptedToken!)
                        }
                    })
                } else {
                    portal.outputCommand(LightSetCommand(ledPlatform: ledPlatform, color: NSColor.red))
                }

                encryptedTokens.removeValue(forKey: response.nfcIndex)
            } else {
                let nextBlock = token.nextBlock()
                portal.outputCommand(ReadCommand(nfcIndex: response.nfcIndex, sectorNumber: 0, blockNumber: nextBlock))
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

    func experiment() {
        //self.portal.outputCommand(BeCommand(value: test))
        //self.portal.outputCommand(C1Command(value: test))
        //self.portal.outputCommand(C0Command())
        //var test : UInt8 = 0
        
        /*
        if #available(OSX 10.12, *) {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
                self.portal.outputCommand(B1Command(value1: 0x00, value2: test))
                if test > 0x10 {
                    timer.invalidate()
                }
                test = test + 1
            })
        }
        */
    }
}
