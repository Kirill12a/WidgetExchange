//
//  Item.swift
//  Widget
//
//  Created by Kirill Drozdov on 09.11.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
