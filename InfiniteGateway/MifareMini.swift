//
//  MifareMini.swift
//  InfiniteGateway
//
//  Created by Eric Betts on 9/20/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation

class MifareMini {
    var tagId : NSData
    
    
    init(tagId: NSData) {
        self.tagId = tagId
    }
}