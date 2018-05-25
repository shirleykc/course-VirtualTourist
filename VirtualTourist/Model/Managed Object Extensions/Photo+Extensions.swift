//
//  Photo+Extensions.swift
//  VirtualTourist
//
//  Created by Shirley on 4/28/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import CoreData

extension Photo {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
