//
//  Region+Extensions.swift
//  VirtualTourist
//
//  Created by Shirley on 5/6/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import CoreData

extension Region {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
