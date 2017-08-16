//
//  ArrayExtensions.swift
//  LocationTargeting
//
//  Created by Malkevych Bohdan on 16.08.17.
//  Copyright © 2017 Malkevych Bohdan. All rights reserved.
//

import Foundation

extension Array {
    var halfCount: Int? {
        guard count != 0 else {
            return nil
        }
        return count / 2
    }
}
