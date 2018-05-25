//
//  GDCBlackBox.swift
//  VirtualTourist
//
//  Created by Shirley on 4/22/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
