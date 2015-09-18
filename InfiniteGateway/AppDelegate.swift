//
//  AppDelegate.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 9/17/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Cocoa
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    static let magic : NSData = "(c) Disney 2013".dataUsingEncoding(NSASCIIStringEncoding)!
    static let secret : NSData = NSData(bytes: [0xAF, 0x62, 0xD2, 0xEC, 0x04, 0x91, 0x96, 0x8C, 0xC5, 0x2A, 0x1A, 0x71, 0x65, 0xF8, 0x65, 0xFE] as [UInt8], length: 0x10)
    
    var platform : [UInt8:Token] = [:]
    var presence = Dictionary<Message.LedPlatform, Array<UInt8>>()
    
    var portal : Portal {
        get {
            return Portal.singleton
        }
    }
    var portalThread : NSThread?

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceConnected:", name: "deviceConnected", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "incomingMessage:", name: "incomingMessage", object: nil)
                
        portalThread = NSThread(target: portal, selector:"initUsb", object: self)
        if let thread = portalThread {
            thread.start()
        } else {
            print("Error starting portal thread")
        }
        
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
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
            if let pIndex = presence[update.ledPlatform]?.indexOf(update.nfcIndex) {
                presence[update.ledPlatform]?.removeAtIndex(pIndex)
            }
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
        } else if let response = response as? TagIdResponse {
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


    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "org.ericbetts.InfiniteGateway" in the user's Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        let appSupportURL = urls[urls.count - 1]
        return appSupportURL.URLByAppendingPathComponent("org.ericbetts.InfiniteGateway")
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("InfiniteGateway", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = NSFileManager.defaultManager()
        var failError: NSError? = nil
        var shouldFail = false
        var failureReason = "There was an error creating or loading the application's saved data."

        // Make sure the application files directory is there
        do {
            let properties = try self.applicationDocumentsDirectory.resourceValuesForKeys([NSURLIsDirectoryKey])
            if !properties[NSURLIsDirectoryKey]!.boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } catch  {
            let nserror = error as NSError
            if nserror.code == NSFileReadNoSuchFileError {
                do {
                    try fileManager.createDirectoryAtPath(self.applicationDocumentsDirectory.path!, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    failError = nserror
                }
            } else {
                failError = nserror
            }
        }
        
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = nil
        if failError == nil {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CocoaAppCD.storedata")
            do {
                try coordinator!.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: nil)
            } catch {
                failError = error as NSError
            }
        }
        
        if shouldFail || (failError != nil) {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            if failError != nil {
                dict[NSUnderlyingErrorKey] = failError
            }
            let error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSApplication.sharedApplication().presentError(error)
            abort()
        } else {
            return coordinator!
        }
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(sender: AnyObject!) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing before saving")
        }
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                NSApplication.sharedApplication().presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> NSUndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return managedObjectContext.undoManager
    }

    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing to terminate")
            return .TerminateCancel
        }
        
        if !managedObjectContext.hasChanges {
            return .TerminateNow
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .TerminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButtonWithTitle(quitButton)
            alert.addButtonWithTitle(cancelButton)
            
            let answer = alert.runModal()
            if answer == NSAlertFirstButtonReturn {
                return .TerminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .TerminateNow
    }

}

