//
//  Pin+Extensions.swift
//  VirtualTourist
//
//  Created by Shirley on 3/25/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import CoreData

extension Pin {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
