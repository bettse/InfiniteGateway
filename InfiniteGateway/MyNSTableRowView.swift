//
//  MyNSTableRowView.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 3/10/17.
//  Copyright © 2017 Eric Betts. All rights reserved.
//

import Foundation
import Cocoa

//http://stackoverflow.com/a/39794774/1112230
class MyNSTableRowView: NSTableRowView {
    
    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .none {
            let selectionRect = NSInsetRect(self.bounds, 2.5, 2.5)
            NSColor(calibratedWhite: 0.65, alpha: 1).setStroke()
            NSColor(calibratedWhite: 0.82, alpha: 1).setFill()
            let selectionPath = NSBezierPath.init(roundedRect: selectionRect, xRadius: 6, yRadius: 6)
            selectionPath.fill()
            selectionPath.stroke()
        }
    }
}
